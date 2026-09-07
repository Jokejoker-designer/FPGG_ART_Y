// a7ng_unified_retrieval.sv — U6-UNIFIED-RETRIEVAL-00
// ONE candidate owner: a7ng_sparse_dir_axi. learn=0. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_unified_retrieval #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned ID_W     = 20,
  parameter int unsigned K        = 8
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [15:0]  live_epoch_i,
  // extractor
  input  logic         tok_valid_i,
  output logic         tok_ready_o,
  input  logic [7:0]   tok_i,
  input  logic         fire_i,
  input  logic         retire_i,
  output logic         qse_valid_o,
  output logic [7:0]   q_ent_o,
  output logic [7:0]   q_int_o,
  output logic [7:0]   q_rel_o,
  output logic [7:0]   q_ctx_o,
  output logic [15:0]  k0_o, k1_o, k2_o, k3_o,
  output logic         v0_o, v1_o, v2_o, v3_o,
  output logic [15:0]  n_host_or_o,
  // poke override (directed protocol; extractor unused when poke_i=1)
  input  logic         poke_i,
  input  logic         poke_go_i,
  input  logic [15:0]  poke_k0_i, poke_k1_i, poke_k2_i, poke_k3_i,
  input  logic         poke_v0_i, poke_v1_i, poke_v2_i, poke_v3_i,
  input  logic [7:0]   poke_ent_i, poke_int_i, poke_rel_i, poke_ctx_i,
  // AXI (walker only)
  output logic [3:0]   m_axi_arid,
  output logic [27:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [3:0]   m_axi_rid,
  input  logic [127:0] m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready,
  // results
  output logic         done_o,
  output logic         retrieval_overflow_o,
  output logic [15:0]  retrieval_trunc_o,
  output logic [15:0]  n_emit_o,
  output logic [15:0]  n_dup_o,
  output a7ng_pkg::node_id_t topk_id_o [K],
  output a7ng_pkg::score_t   topk_sc_o [K],
  output logic [15:0]  n_scored_o
);
  import a7ng_pkg::*;

  typedef enum logic [3:0] {
    S_IDLE, S_WAITQ, S_WALK, S_MAT, S_SC, S_SCW, S_HP, S_PAD, S_FINLAST, S_DRAIN, S_DONE
  } st_t;
  st_t st;

  logic        w_qv, w_qr, w_cv, w_cr, w_qd, w_ovf;
  logic [ID_W-1:0] w_cid;
  logic [15:0] w_emit, w_dup, w_trunc, w_ndir, w_npost;
  logic [3:0]  w_pmask;
  logic [15:0] wk0, wk1, wk2, wk3;
  logic        wv0, wv1, wv2, wv3;
  logic [7:0]  qe, qi, qr, qx;

  logic        lut_go, lut_hit, lut_ust;
  logic [7:0]  re, rn, rr, rx;
  term_t       te, ti, tr, tc, tp, tpr, tpe;

  logic        sc_vi, sc_vo;
  node_id_t    sc_idi, sc_ido;
  score_terms_t sc_tm;
  score_t      sc_so;

  logic        hp_clr, hp_iv, hp_ir, hp_ilast, hp_ov, hp_or, hp_busy;
  score_t      hp_is, hp_os;
  node_id_t    hp_iid, hp_oid;
  logic [2:0]  hp_idx;
  logic [3:0]  hp_lane;
  logic        hp_vv;

  logic [ID_W-1:0] cid_q;
  logic        w_done_hold;
  logic [3:0]  n_real, n_pad;
  logic [15:0] n_scored;
  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;
  integer      ki;

  a7ng_query_struct_extract u_qse (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_valid_i), .tok_ready_o(tok_ready_o), .tok_i(tok_i),
    .fire_i(fire_i), .retire_i(retire_i),
    .busy_o(), .accepted_o(), .valid_o(qse_valid_o),
    .entity_id_o(q_ent_o), .intent_id_o(q_int_o),
    .relation_id_o(q_rel_o), .context_id_o(q_ctx_o),
    .entity_cue_o(), .intent_cue_o(), .relation_cue_o(), .context_cue_o(),
    .crc16_dbg_o(), .k0_o(k0_o), .k1_o(k1_o), .k2_o(k2_o), .k3_o(k3_o),
    .k0_valid_o(v0_o), .k1_valid_o(v1_o), .k2_valid_o(v2_o), .k3_valid_o(v3_o),
    .n_host_entity_o(h_ent), .n_host_intent_o(h_int), .n_host_hash_o(h_hash),
    .n_host_shard_o(h_sh), .n_host_bucket_o(h_bkt), .n_host_cand_o(h_cand),
    .n_host_winner_o(h_win), .n_host_addr_o(h_addr), .n_host_relpath_o(h_rel),
    .n_host_next_o(h_nxt), .n_host_answer_o(h_ans)
  );

  assign n_host_or_o = h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans;

  a7ng_sparse_dir_axi #(
    .N_TABLES(4), .N_BUCKETS(4096), .CAND_CAP(CAND_CAP),
    .ID_W(ID_W), .INDEX_BASE(NG_DDR_INDEX_BASE)
  ) u_walk (
    .clk(clk), .rst_n(rst_n), .live_epoch_i(live_epoch_i),
    .q_v(w_qv), .q_ready(w_qr),
    .k0_i(wk0), .k1_i(wk1), .k2_i(wk2), .k3_i(wk3),
    .k0_valid_i(wv0), .k1_valid_i(wv1), .k2_valid_i(wv2), .k3_valid_i(wv3),
    .cand_v(w_cv), .cand_ready(w_cr), .cand_id(w_cid),
    .q_done(w_qd), .q_overflow_o(w_ovf),
    .n_emit_o(w_emit), .n_dup_o(w_dup), .n_trunc_o(w_trunc),
    .n_dir_ar_o(w_ndir), .n_post_ar_o(w_npost), .probed_mask_o(w_pmask),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
    .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready)
  );

  a7ng_u6_record_lut #(.N(256)) u_lut (
    .clk(clk), .rst_n(rst_n), .go_i(lut_go), .id_i(cid_q),
    .hit_o(lut_hit), .ent_o(re), .int_o(rn), .rel_o(rr), .ctx_o(rx),
    .use_st_o(lut_ust),
    .te_o(te), .ti_o(ti), .tr_o(tr), .tc_o(tc),
    .tp_o(tp), .tpr_o(tpr), .tpe_o(tpe)
  );

  a7ng_scorer_lane u_sc (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_vi), .cand_id_i(sc_idi), .terms_i(sc_tm),
    .valid_o(sc_vo), .cand_id_o(sc_ido), .score_o(sc_so)
  );

  a7ng_topk_stream_minheap #(.K(K)) u_hp (
    .clk(clk), .rst_n(rst_n),
    .clear_i(hp_clr),
    .in_valid_i(hp_iv), .in_ready_o(hp_ir),
    .in_v_i(hp_vv), .in_s_i(hp_is), .in_id_i(hp_iid), .in_lane_i(hp_lane),
    .in_last_i(hp_ilast),
    .out_valid_o(hp_ov), .out_ready_i(hp_or),
    .out_s_o(hp_os), .out_id_o(hp_oid), .out_idx_o(hp_idx),
    .busy_o(hp_busy), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  assign hp_lane = 4'd0;
  assign hp_or   = 1'b1;
  assign n_scored_o = n_scored;
  assign n_emit_o = w_emit;
  assign n_dup_o  = w_dup;

  always_comb begin
    sc_tm = '0;
    if (lut_ust) begin
      sc_tm.entity_match = te;
      sc_tm.intent_match = ti;
      sc_tm.relation_match = tr;
      sc_tm.context_match = tc;
      sc_tm.path_confidence = tp;
      sc_tm.learned_prior = tpr;
      sc_tm.contradiction_penalty = tpe;
    end else begin
      sc_tm.entity_match   = (qe != 8'd0 && qe == re) ? term_t'(8'sd8) : '0;
      sc_tm.intent_match   = (qi != 8'd0 && qi == rn) ? term_t'(8'sd8) : '0;
      sc_tm.relation_match = (qr != 8'd0 && qr == rr) ? term_t'(8'sd8) : '0;
      sc_tm.context_match  = (qx != 8'd0 && qx == rx) ? term_t'(8'sd8) : '0;
    end
  end

  always_comb begin
    w_qv = 1'b0;
    w_cr = 1'b0;
    lut_go = 1'b0;
    sc_vi = 1'b0;
    sc_idi = 32'(cid_q);
    hp_clr = 1'b0;
    hp_iv = 1'b0;
    hp_ilast = 1'b0;
    hp_vv = 1'b1;
    hp_is = sc_so;
    hp_iid = sc_ido;
    unique case (st)
      S_WAITQ: w_qv = 1'b1;
      S_WALK:  w_cr = w_cv;
      S_MAT:   lut_go = 1'b1;
      S_SC:    sc_vi = 1'b1;
      S_HP: begin
        hp_iv = hp_ir;
        hp_vv = 1'b1;
        hp_is = sc_so;
        hp_iid = sc_ido;
      end
      S_PAD: begin
        hp_iv = hp_ir;
        hp_vv = 1'b0;
        hp_is = '0;
        hp_iid = 32'h00FF_FFF0 + 32'(n_pad);
        hp_ilast = (n_pad + 1'b1 + n_real) >= 4'(K);
      end
      S_FINLAST: begin
        hp_iv = hp_ir;
        hp_vv = 1'b0;
        hp_is = '0;
        hp_iid = 32'h00FF_FFF0;
        hp_ilast = 1'b1;
      end
      S_IDLE: hp_clr = !hp_busy;
      default: ;
    endcase
  end

  logic qse_v_d, qse_rise;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) qse_v_d <= 1'b0;
    else qse_v_d <= qse_valid_o;
  end
  assign qse_rise = qse_valid_o && !qse_v_d;

  st_t nst;
  always_comb begin
    nst = st;
    case (st)
      S_IDLE: if (!hp_busy && ((poke_i && poke_go_i) || (!poke_i && qse_rise)))
                nst = S_WAITQ;
      S_WAITQ: if (!w_qr) nst = S_WALK;
      S_WALK: begin
        if (w_cv) nst = S_MAT;
        else if (w_qd || w_done_hold)
          nst = (n_scored >= 16'(K)) ? S_FINLAST : S_PAD;
      end
      S_MAT: nst = S_SC;
      S_SC:  nst = S_SCW;
      S_SCW: if (sc_vo) nst = S_HP;
      S_HP:  if (hp_ir) nst = S_WALK;
      S_PAD: if (hp_ir && ((n_pad + 4'd1 + n_real) >= 4'(K))) nst = S_DRAIN;
      S_FINLAST: if (hp_ir) nst = S_DRAIN;
      S_DRAIN: if (hp_ov && hp_idx == 3'(K-1)) nst = S_DONE;
      S_DONE: nst = S_IDLE;
      default: nst = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      done_o <= 1'b0;
      retrieval_overflow_o <= 1'b0;
      retrieval_trunc_o <= 16'd0;
      n_real <= 4'd0; n_pad <= 4'd0; n_scored <= 16'd0;
      w_done_hold <= 1'b0;
      cid_q <= '0;
      wk0 <= 0; wk1 <= 0; wk2 <= 0; wk3 <= 0;
      wv0 <= 0; wv1 <= 0; wv2 <= 0; wv3 <= 0;
      qe <= 0; qi <= 0; qr <= 0; qx <= 0;
      for (ki = 0; ki < K; ki = ki + 1) begin
        topk_id_o[ki] <= '0; topk_sc_o[ki] <= '0;
      end
    end else begin
      st <= nst;
      done_o <= (nst == S_DONE);
      if (st == S_IDLE && nst == S_WAITQ) begin
        n_real <= 0; n_pad <= 0; n_scored <= 0;
        w_done_hold <= 1'b0;
        retrieval_overflow_o <= 1'b0;
        retrieval_trunc_o <= 16'd0;
        if (poke_i) begin
          wk0 <= poke_k0_i; wk1 <= poke_k1_i; wk2 <= poke_k2_i; wk3 <= poke_k3_i;
          wv0 <= poke_v0_i; wv1 <= poke_v1_i; wv2 <= poke_v2_i; wv3 <= poke_v3_i;
          qe <= poke_ent_i; qi <= poke_int_i; qr <= poke_rel_i; qx <= poke_ctx_i;
        end else begin
          wk0 <= k0_o; wk1 <= k1_o; wk2 <= k2_o; wk3 <= k3_o;
          wv0 <= v0_o; wv1 <= v1_o; wv2 <= v2_o; wv3 <= v3_o;
          qe <= q_ent_o; qi <= q_int_o; qr <= q_rel_o; qx <= q_ctx_o;
        end
      end
      if (st == S_WALK && w_cv)
        cid_q <= w_cid;
      if (st == S_WALK && (w_qd || w_done_hold) && !w_cv) begin
        retrieval_overflow_o <= w_ovf;
        retrieval_trunc_o <= w_trunc;
        w_done_hold <= 1'b0;
      end
      if (st == S_WALK && w_qd)
        w_done_hold <= 1'b1;
      if (st == S_HP && hp_ir) begin
        n_real <= n_real + 4'd1;
        n_scored <= n_scored + 16'd1;
      end
      if (st == S_PAD && hp_ir && nst == S_PAD)
        n_pad <= n_pad + 4'd1;
      if (st == S_DRAIN && hp_ov) begin
        topk_id_o[hp_idx] <= hp_oid;
        topk_sc_o[hp_idx] <= hp_os;
      end
    end
  end
endmodule
