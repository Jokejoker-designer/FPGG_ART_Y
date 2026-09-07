// a7ng_u6_typeclass_retrieval.sv — U6-TYPECLASS-UNIFIED-RETRIEVAL-00
// ONE candidate owner: a7ng_typeclass_scan. CLASS_ID identity.
// No sparse_dir_axi. No u6_record_lut. No learned_prior_graph.
// learn=0. Q-head forbidden. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_u6_typeclass_retrieval #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned K        = 8
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  output logic        qse_valid_o,
  output logic [7:0]  q_ent_o,
  output logic [7:0]  q_int_o,
  output logic [7:0]  q_rel_o,
  output logic [7:0]  q_ctx_o,
  output logic [15:0] n_host_or_o,
  input  logic        poke_i,
  input  logic        poke_go_i,
  input  logic [7:0]  poke_ent_i,
  input  logic [7:0]  poke_int_i,
  input  logic [7:0]  poke_rel_i,
  input  logic [7:0]  poke_ctx_i,
  input  logic        poke_ev_i,
  input  logic        poke_iv_i,
  input  logic        poke_rv_i,
  input  logic        poke_xv_i,
  input  logic        stall_scan_i,
  input  logic        stall_heap_i,
  input  logic        poison_en_i,
  input  logic [15:0] poison_class_id_i,
  input  logic [7:0]  poison_eid_i,
  output logic        done_o,
  output logic        retrieval_overflow_o,
  output logic [15:0] retrieval_trunc_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_scored_o,
  output a7ng_pkg::node_id_t topk_id_o [K],
  output logic [15:0]        topk_class_id_o [K],
  output a7ng_pkg::score_t   topk_sc_o [K],
  output logic [3:0]  dbg_st_o,
  output logic        dbg_scan_v_o,
  output logic [15:0] dbg_scan_id_o,
  output logic        dbg_mat_v_o,
  output logic [15:0] dbg_mat_id_o,
  output logic [7:0]  dbg_mat_eid_o,
  output logic [7:0]  dbg_mat_iid_o,
  output logic [7:0]  dbg_mat_rid_o,
  output logic [7:0]  dbg_mat_xid_o,
  output logic [15:0] dbg_mat_ptr_o,
  output logic [15:0] dbg_mat_cnt_o,
  output logic        dbg_sc_v_o,
  output a7ng_pkg::score_t dbg_sc_o,
  output a7ng_pkg::term_t  dbg_te_o,
  output a7ng_pkg::term_t  dbg_ti_o,
  output a7ng_pkg::term_t  dbg_tr_o,
  output a7ng_pkg::term_t  dbg_tc_o
);
  import a7ng_pkg::*;

  typedef enum logic [3:0] {
    S_IDLE, S_WAITQ, S_WALK, S_MAT, S_SC, S_SCW, S_HP, S_PAD, S_FINLAST, S_DRAIN, S_DONE
  } st_t;
  st_t st;

  logic        scan_ready, scan_go, scan_v, scan_r, scan_done, scan_ovf;
  logic [15:0] scan_id, scan_emit, scan_trunc;
  logic [7:0]  qe, qi, qr, qx;
  logic        ev, iv, rv, xv;

  logic        mat_go, mat_hit;
  logic [15:0] mat_id, mat_ptr, mat_cnt;
  logic [7:0]  re, rn, rr, rx;

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

  logic [15:0] cid_q;
  logic        w_done_hold;
  logic [15:0] n_real, n_pad, n_scored;
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
    .crc16_dbg_o(), .k0_o(), .k1_o(), .k2_o(), .k3_o(),
    .k0_valid_o(), .k1_valid_o(), .k2_valid_o(), .k3_valid_o(),
    .n_host_entity_o(h_ent), .n_host_intent_o(h_int), .n_host_hash_o(h_hash),
    .n_host_shard_o(h_sh), .n_host_bucket_o(h_bkt), .n_host_cand_o(h_cand),
    .n_host_winner_o(h_win), .n_host_addr_o(h_addr), .n_host_relpath_o(h_rel),
    .n_host_next_o(h_nxt), .n_host_answer_o(h_ans)
  );

  assign n_host_or_o = h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans;

  a7ng_typeclass_scan #(.CAND_CAP(CAND_CAP)) u_scan (
    .clk(clk), .rst_n(rst_n),
    .q_go_i(scan_go), .q_ready_o(scan_ready),
    .q_eid_i(qe), .q_iid_i(qi), .q_rid_i(qr), .q_xid_i(qx),
    .q_ev_i(ev), .q_iv_i(iv), .q_rv_i(rv), .q_xv_i(xv),
    .cand_v_o(scan_v), .cand_ready_i(scan_r), .cand_id_o(scan_id),
    .q_done_o(scan_done), .q_overflow_o(scan_ovf),
    .n_emit_o(scan_emit), .n_trunc_o(scan_trunc)
  );

  a7ng_typeclass_materialize u_mat (
    .clk(clk), .rst_n(rst_n),
    .go_i(mat_go), .class_id_i(cid_q),
    .poison_en_i(poison_en_i),
    .poison_class_id_i(poison_class_id_i),
    .poison_eid_i(poison_eid_i),
    .hit_o(mat_hit), .class_id_o(mat_id),
    .eid_o(re), .iid_o(rn), .rid_o(rr), .xid_o(rx),
    .member_ptr_o(mat_ptr), .member_count_o(mat_cnt)
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
  assign n_emit_o   = scan_emit;
  assign dbg_st_o   = 4'(st);
  assign dbg_scan_v_o  = scan_v && scan_r;
  assign dbg_scan_id_o = scan_id;
  assign dbg_mat_v_o   = (st == S_SC);
  assign dbg_mat_id_o  = mat_id;
  assign dbg_mat_eid_o = re;
  assign dbg_mat_iid_o = rn;
  assign dbg_mat_rid_o = rr;
  assign dbg_mat_xid_o = rx;
  assign dbg_mat_ptr_o = mat_ptr;
  assign dbg_mat_cnt_o = mat_cnt;
  assign dbg_sc_v_o    = sc_vo;
  assign dbg_sc_o      = sc_so;
  assign dbg_te_o      = sc_tm.entity_match;
  assign dbg_ti_o      = sc_tm.intent_match;
  assign dbg_tr_o      = sc_tm.relation_match;
  assign dbg_tc_o      = sc_tm.context_match;

  always_comb begin
    sc_tm = '0;
    sc_tm.entity_match   = (qe != 8'd0 && qe == re) ? term_t'(8'sd8) : '0;
    sc_tm.intent_match   = (qi != 8'd0 && qi == rn) ? term_t'(8'sd8) : '0;
    sc_tm.relation_match = (qr != 8'd0 && qr == rr) ? term_t'(8'sd8) : '0;
    sc_tm.context_match  = (qx != 8'd0 && qx == rx) ? term_t'(8'sd8) : '0;
  end

  always_comb begin
    scan_go = 1'b0;
    scan_r  = 1'b0;
    mat_go  = 1'b0;
    sc_vi   = 1'b0;
    sc_idi  = {16'd0, cid_q};
    hp_clr  = 1'b0;
    hp_iv   = 1'b0;
    hp_ilast = 1'b0;
    hp_vv   = 1'b1;
    hp_is   = sc_so;
    hp_iid  = sc_ido;
    unique case (st)
      S_WAITQ: scan_go = scan_ready;
      S_WALK:  scan_r  = scan_v && !stall_scan_i;
      S_MAT:   mat_go  = 1'b1;
      S_SC:    sc_vi   = 1'b1;
      S_HP: begin
        hp_iv  = hp_ir && !stall_heap_i;
        hp_vv  = 1'b1;
        hp_is  = sc_so;
        hp_iid = sc_ido;
      end
      S_PAD: begin
        hp_iv    = hp_ir && !stall_heap_i;
        hp_vv    = 1'b0;
        hp_is    = '0;
        hp_iid   = 32'h00FF_FFF0 + 32'(n_pad);
        hp_ilast = (n_pad + 16'd1 + n_real) >= 16'(K);
      end
      S_FINLAST: begin
        hp_iv    = hp_ir && !stall_heap_i;
        hp_vv    = 1'b0;
        hp_is    = '0;
        hp_iid   = 32'h00FF_FFF0;
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
      S_WAITQ: if (!scan_ready) nst = S_WALK;
      S_WALK: begin
        if (scan_v && !stall_scan_i) nst = S_MAT;
        else if (scan_done || w_done_hold)
          nst = (n_scored >= 16'(K)) ? S_FINLAST : S_PAD;
      end
      S_MAT: nst = S_SC;
      S_SC:  nst = S_SCW;
      S_SCW: if (sc_vo) nst = S_HP;
      S_HP:  if (hp_ir && !stall_heap_i) nst = S_WALK;
      S_PAD: if (hp_ir && !stall_heap_i && ((n_pad + 16'd1 + n_real) >= 16'(K))) nst = S_DRAIN;
      S_FINLAST: if (hp_ir && !stall_heap_i) nst = S_DRAIN;
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
      n_real <= 16'd0; n_pad <= 16'd0; n_scored <= 16'd0;
      w_done_hold <= 1'b0;
      cid_q <= 16'd0;
      qe <= 8'd0; qi <= 8'd0; qr <= 8'd0; qx <= 8'd0;
      ev <= 1'b0; iv <= 1'b0; rv <= 1'b0; xv <= 1'b0;
      for (ki = 0; ki < K; ki = ki + 1) begin
        topk_id_o[ki] <= '0;
        topk_class_id_o[ki] <= 16'd0;
        topk_sc_o[ki] <= '0;
      end
    end else begin
      st <= nst;
      done_o <= (nst == S_DONE);
      if (st == S_IDLE && nst == S_WAITQ) begin
        n_real <= 16'd0; n_pad <= 16'd0; n_scored <= 16'd0;
        w_done_hold <= 1'b0;
        retrieval_overflow_o <= 1'b0;
        retrieval_trunc_o <= 16'd0;
        if (poke_i) begin
          qe <= poke_ent_i; qi <= poke_int_i; qr <= poke_rel_i; qx <= poke_ctx_i;
          ev <= poke_ev_i; iv <= poke_iv_i; rv <= poke_rv_i; xv <= poke_xv_i;
        end else begin
          qe <= q_ent_o; qi <= q_int_o; qr <= q_rel_o; qx <= q_ctx_o;
          ev <= (q_ent_o != 8'd0);
          iv <= (q_int_o != 8'd0);
          rv <= (q_rel_o != 8'd0);
          xv <= (q_ctx_o != 8'd0);
        end
      end
      if (st == S_WALK && scan_v && !stall_scan_i)
        cid_q <= scan_id;
      if (scan_done)
        w_done_hold <= 1'b1;
      if (st == S_WALK && (scan_done || w_done_hold) && !(scan_v && !stall_scan_i)) begin
        retrieval_overflow_o <= scan_ovf;
        retrieval_trunc_o <= scan_trunc;
        w_done_hold <= 1'b0;
      end
      if (st == S_HP && hp_ir && !stall_heap_i) begin
        n_real <= n_real + 16'd1;
        n_scored <= n_scored + 16'd1;
      end
      if (st == S_PAD && hp_ir && !stall_heap_i && nst == S_PAD)
        n_pad <= n_pad + 16'd1;
      if (st == S_DRAIN && hp_ov) begin
        topk_id_o[hp_idx] <= hp_oid;
        topk_class_id_o[hp_idx] <= hp_oid[15:0];
        topk_sc_o[hp_idx] <= hp_os;
      end
    end
  end
endmodule
