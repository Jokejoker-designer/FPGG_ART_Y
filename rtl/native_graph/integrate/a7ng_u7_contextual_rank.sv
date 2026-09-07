// a7ng_u7_contextual_rank.sv — U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00
// Ranking chain: QSE → scan → materialize → V1 lookup → prior → scorer → heap.
// learned_prior participates BEFORE Top-K insertion. PROGRAM=NO. QHEAD=NO.
// U6 retrieval RTL is not modified. Host does not construct learn keys.
`timescale 1ns / 1ps

module a7ng_u7_contextual_rank #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned K        = 8,
  parameter int unsigned TXN_W    = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        learn_i,
  input  logic        freeze_i,
  input  logic        train_after_i,
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
  input  logic        flush_i,
  input  logic        reload_i,
  input  logic        bram_kill_i,
  input  logic        train_reset_i,
  output logic        rank_done_o,
  output logic        train_done_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_scored_o,
  output logic [15:0] n_learned_o,
  output logic [15:0] n_host_or_o,
  output a7ng_pkg::node_id_t topk_id_o [K],
  output logic [15:0]        topk_class_id_o [K],
  output a7ng_pkg::score_t   topk_sc_o [K],
  output logic        cand_rep_v_o,
  output logic [15:0] cand_rep_cid_o,
  output a7ng_pkg::score_t cand_rep_sc_o,
  output logic signed [7:0] cand_rep_pri_o,
  output logic        cand_rep_hit_o,
  input  logic        reward_valid_i,
  input  logic signed [3:0] reward_i,
  input  logic        txn_echo_valid_i,
  input  logic [TXN_W-1:0] txn_echo_i,
  output logic        reward_ready_o,
  output logic        pending_o,
  output logic [TXN_W-1:0] txn_o,
  output logic        ack_valid_o,
  output logic [2:0]  ack_o,
  output logic [15:0] learn_cid_o,
  output logic [31:0] learn_subj_o,
  output logic [7:0]  learn_rel_o,
  output logic [31:0] learn_obj_o,
  output logic        persist_busy_o,
  output logic        persist_done_o,
  output logic        persist_nak_o,
  output logic        boot_done_o,
  output logic        c7_ack_valid_o,
  output logic [31:0] c7_addr_o,
  output logic [15:0] c7_commit_seq_o,
  output logic [15:0] c7_ack_count_o,
  output logic [4:0]  dbg_st_o,
  output logic        ddr_req_o,
  output logic        ddr_we_o,
  output logic [7:0]  ddr_addr_o,
  output logic [63:0] ddr_wdata_o,
  input  logic [63:0] ddr_rdata_i,
  input  logic        ddr_ack_i
);
  import a7ng_pkg::*;

  typedef enum logic [4:0] {
    S_BOOT, S_IDLE, S_WAITQ, S_WALK, S_MAT, S_LK, S_LKW, S_SC, S_SCW, S_HP,
    S_PAD, S_FINLAST, S_DRAIN, S_TWALK, S_TLATCH, S_TPEND, S_TWAIT
  } st_t;
  st_t st;

  logic [7:0]  qe, qi, qr, qx;
  logic        ev, iv, rv, xv;
  logic        train_en, w_done_hold;
  logic [15:0] cid_q, n_real, n_pad, n_scored, n_learned;
  logic [3:0]  tk;
  integer      ki;

  logic        scan_ready, scan_go, scan_v, scan_r, scan_done, scan_ovf;
  logic [15:0] scan_id, scan_emit, scan_trunc;
  logic        mat_go, mat_hit;
  logic [15:0] mat_id, mat_ptr, mat_cnt;
  logic [7:0]  re, rn, rr, rx;

  logic [31:0] ks, ko, lk_s, lk_o;
  logic [7:0]  kr, lk_r;
  logic        lk_go, lk_busy, lk_done, lk_hit;
  logic signed [7:0] lk_pri, lk_pen, pri_q;
  logic        hit_q;

  logic        sc_vi, sc_vo;
  node_id_t    sc_idi, sc_ido;
  score_terms_t sc_tm;
  score_t      sc_so;

  logic        hp_clr, hp_iv, hp_ir, hp_ilast, hp_ov, hp_busy;
  logic        hp_vv;
  score_t      hp_is, hp_os;
  node_id_t    hp_iid, hp_oid;
  logic [2:0]  hp_idx;
  logic [3:0]  hp_lane;

  logic        latch_v, latch_rdy, cons_v, g2_in_rdy, g2_out_v, g2_out_rdy;
  logic signed [3:0] cons_r, g2_rew;
  logic [31:0] cons_s, cons_o, g2_s, g2_o;
  logic [7:0]  cons_rel, g2_rel;
  logic [15:0] cons_qe, cons_pe;
  logic        cons_k, g2_k;
  logic [TXN_W-1:0] cons_txn, g2_txn;
  logic        pbusy, pdone, pnak, boot_done, saw_done, saw_nak;

  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;
  logic        tok_r_unused;

  function automatic logic cid_ok(input logic [15:0] c, input node_id_t id);
    return (c >= 16'd1) && (c <= 16'd443) && (id[31:16] == 16'd0) && (id[15:0] == c);
  endfunction

  a7ng_query_struct_extract u_qse (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(1'b0), .tok_ready_o(tok_r_unused), .tok_i(8'd0),
    .fire_i(1'b0), .retire_i(1'b0),
    .busy_o(), .accepted_o(), .valid_o(),
    .entity_id_o(), .intent_id_o(), .relation_id_o(), .context_id_o(),
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
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .hit_o(mat_hit), .class_id_o(mat_id),
    .eid_o(re), .iid_o(rn), .rid_o(rr), .xid_o(rx),
    .member_ptr_o(mat_ptr), .member_count_o(mat_cnt)
  );

  a7ng_learn_key_class_context_v1 u_key (
    .class_id_i((st==S_TLATCH || st==S_TPEND || st==S_TWAIT) ? learn_cid_o : cid_q),
    .q_ev_i(ev), .q_iv_i(iv), .q_rv_i(rv), .q_xv_i(xv),
    .q_eid_i(qe), .q_iid_i(qi), .q_rid_i(qr), .q_xid_i(qx),
    .subj_o(ks), .rel_o(kr), .obj_o(ko)
  );

  a7ng_feedback_resolver #(.TXN_W(TXN_W)) u_g1 (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(ks), .rel_i(kr), .obj_i(ko),
    .q_epoch_i(16'd1), .p_epoch_i(16'd1), .conf_i(8'd1), .contradict_i(1'b0),
    .pending_o(pending_o), .txn_o(txn_o),
    .reward_valid_i(reward_valid_i), .reward_i(reward_i),
    .txn_echo_valid_i(txn_echo_valid_i), .txn_echo_i(txn_echo_i),
    .reward_ready_o(reward_ready_o),
    .ack_valid_o(ack_valid_o), .ack_ready_i(1'b1), .ack_o(ack_o),
    .consume_valid_o(cons_v), .consume_ready_i(g2_in_rdy),
    .consume_reward_o(cons_r),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(cons_qe), .consume_p_epoch_o(cons_pe),
    .consume_conf_o(), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
    .n_consume_o(), .n_orphan_o(), .n_range_o(),
    .n_late_o(), .n_drop_o(), .n_dup_o(), .n_mode_o()
  );

  a7ng_context_delta #(.TXN_W(TXN_W)) u_g2 (
    .clk(clk), .rst_n(rst_n),
    .in_valid(cons_v), .in_ready(g2_in_rdy),
    .in_reward(cons_r), .in_native_conf(16'd256),
    .in_subj(cons_s), .in_rel(cons_rel), .in_obj(cons_o),
    .in_q_epoch(cons_qe), .in_p_epoch(cons_pe),
    .in_contradict(cons_k), .in_txn(cons_txn),
    .out_valid(g2_out_v), .out_ready(g2_out_rdy),
    .delta_o(), .sat_flag_o(),
    .out_reward(g2_rew), .out_native_conf(),
    .out_subj(g2_s), .out_rel(g2_rel), .out_obj(g2_o),
    .out_q_epoch(), .out_p_epoch(),
    .out_contradict(g2_k), .out_txn(g2_txn)
  );

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .flush_i(flush_i && (st==S_IDLE)),
    .reload_i(reload_i && (st==S_IDLE)),
    .bram_kill_i(bram_kill_i && (st==S_IDLE)),
    .train_reset_i(train_reset_i && (st==S_IDLE)),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .live_gen_o(), .sdig_o(), .wrap_imminent_o(),
    .upd_valid_i(g2_out_v), .upd_ready_o(g2_out_rdy),
    .upd_subj_i(g2_s), .upd_rel_i(g2_rel), .upd_obj_i(g2_o),
    .upd_rew_i(g2_rew), .upd_contra_i(g2_k),
    .lk_go_i(lk_go), .lk_subj_i(lk_s), .lk_rel_i(lk_r), .lk_obj_i(lk_o),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(c7_ack_valid_o), .c7_ack_ready_i(1'b1),
    .c7_addr_o(c7_addr_o), .c7_commit_seq_o(c7_commit_seq_o),
    .c7_ack_count_o(c7_ack_count_o),
    .ddr_req_o(ddr_req_o), .ddr_we_o(ddr_we_o), .ddr_addr_o(ddr_addr_o),
    .ddr_wdata_o(ddr_wdata_o), .ddr_rdata_i(ddr_rdata_i), .ddr_ack_i(ddr_ack_i)
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
    .out_valid_o(hp_ov), .out_ready_i(1'b1),
    .out_s_o(hp_os), .out_id_o(hp_oid), .out_idx_o(hp_idx),
    .busy_o(hp_busy), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  assign persist_busy_o = pbusy;
  assign persist_done_o = pdone;
  assign persist_nak_o  = pnak;
  assign boot_done_o    = boot_done;
  assign n_emit_o       = scan_emit;
  assign n_scored_o     = n_scored;
  assign n_learned_o    = n_learned;
  assign learn_subj_o   = ks;
  assign learn_rel_o    = kr;
  assign learn_obj_o    = ko;
  assign dbg_st_o       = 5'(st);
  assign hp_lane        = 4'd0;

  always_comb begin
    sc_tm = '0;
    sc_tm.entity_match   = (qe != 8'd0 && qe == re) ? term_t'(8'sd8) : '0;
    sc_tm.intent_match   = (qi != 8'd0 && qi == rn) ? term_t'(8'sd8) : '0;
    sc_tm.relation_match = (qr != 8'd0 && qr == rr) ? term_t'(8'sd8) : '0;
    sc_tm.context_match  = (qx != 8'd0 && qx == rx) ? term_t'(8'sd8) : '0;
    sc_tm.learned_prior  = hit_q ? term_t'(pri_q) : '0;
    sc_idi = {16'd0, cid_q};
  end

  always_comb begin
    scan_go = 1'b0;
    scan_r  = 1'b0;
    mat_go  = 1'b0;
    lk_go   = 1'b0;
    sc_vi   = 1'b0;
    latch_v = 1'b0;
    hp_clr  = 1'b0;
    hp_iv   = 1'b0;
    hp_ilast = 1'b0;
    hp_vv   = 1'b1;
    hp_is   = sc_so;
    hp_iid  = sc_ido;
    lk_s = ks; lk_r = kr; lk_o = ko;
    unique case (st)
      S_IDLE:   hp_clr = !hp_busy;
      S_WAITQ:  scan_go = scan_ready;
      S_WALK:   scan_r  = scan_v;
      S_MAT:    mat_go  = 1'b1;
      S_LK:     if (!pbusy && !lk_busy) lk_go = 1'b1;
      S_SC:     sc_vi   = 1'b1;
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
        hp_ilast = (n_pad + 16'd1 + n_real) >= 16'(K);
      end
      S_FINLAST: begin
        hp_iv = hp_ir;
        hp_vv = 1'b0;
        hp_is = '0;
        hp_iid = 32'h00FF_FFF0;
        hp_ilast = 1'b1;
      end
      S_TLATCH: latch_v = latch_rdy;
      default: ;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_BOOT;
      rank_done_o <= 1'b0; train_done_o <= 1'b0;
      qe <= '0; qi <= '0; qr <= '0; qx <= '0;
      ev <= 0; iv <= 0; rv <= 0; xv <= 0;
      train_en <= 0; w_done_hold <= 0;
      cid_q <= 0; n_real <= 0; n_pad <= 0; n_scored <= 0; n_learned <= 0;
      tk <= 0; pri_q <= 0; hit_q <= 0; saw_done <= 0; saw_nak <= 0;
      learn_cid_o <= 0;
      cand_rep_v_o <= 0; cand_rep_cid_o <= 0; cand_rep_sc_o <= '0;
      cand_rep_pri_o <= 0; cand_rep_hit_o <= 0;
      for (ki = 0; ki < K; ki = ki + 1) begin
        topk_id_o[ki] <= '0; topk_class_id_o[ki] <= 0; topk_sc_o[ki] <= '0;
      end
    end else begin
      rank_done_o <= 1'b0;
      train_done_o <= 1'b0;
      cand_rep_v_o <= 1'b0;
      if (pdone) saw_done <= 1'b1;
      if (pnak)  saw_nak  <= 1'b1;

      unique case (st)
        S_BOOT: if (boot_done && !pbusy) st <= S_IDLE;
        S_IDLE: begin
          if (poke_i && poke_go_i && !hp_busy && boot_done && !pbusy) begin
            qe <= poke_ent_i; qi <= poke_int_i; qr <= poke_rel_i; qx <= poke_ctx_i;
            ev <= poke_ev_i; iv <= poke_iv_i; rv <= poke_rv_i; xv <= poke_xv_i;
            train_en <= train_after_i && learn_i && !freeze_i;
            n_real <= 0; n_pad <= 0; n_scored <= 0; n_learned <= 0;
            w_done_hold <= 0; tk <= 0;
            st <= S_WAITQ;
          end
        end
        S_WAITQ: if (!scan_ready) st <= S_WALK;
        S_WALK: begin
          if (scan_v) begin
            cid_q <= scan_id;
            st <= S_MAT;
          end else if (scan_done || w_done_hold) begin
            w_done_hold <= 1'b0;
            st <= (n_scored >= 16'(K)) ? S_FINLAST : S_PAD;
          end
        end
        S_MAT: st <= S_LK;
        S_LK:  if (!pbusy && !lk_busy && lk_go) st <= S_LKW;
        S_LKW: if (lk_done) begin
          hit_q <= lk_hit;
          pri_q <= lk_hit ? lk_pri : 8'sd0;
          st <= S_SC;
        end
        S_SC: st <= S_SCW;
        S_SCW: if (sc_vo) st <= S_HP;
        S_HP: if (hp_ir) begin
          n_real <= n_real + 16'd1;
          n_scored <= n_scored + 16'd1;
          cand_rep_v_o <= 1'b1;
          cand_rep_cid_o <= cid_q;
          cand_rep_sc_o <= sc_so;
          cand_rep_pri_o <= pri_q;
          cand_rep_hit_o <= hit_q;
          if (scan_done) w_done_hold <= 1'b1;
          st <= S_WALK;
        end
        S_PAD: if (hp_ir) begin
          if ((n_pad + 16'd1 + n_real) >= 16'(K)) st <= S_DRAIN;
          n_pad <= n_pad + 16'd1;
        end
        S_FINLAST: if (hp_ir) st <= S_DRAIN;
        S_DRAIN: if (hp_ov) begin
          topk_id_o[hp_idx] <= hp_oid;
          topk_class_id_o[hp_idx] <= hp_oid[15:0];
          topk_sc_o[hp_idx] <= hp_os;
          if (hp_idx == 3'(K-1)) begin
            rank_done_o <= 1'b1;
            if (train_en) begin tk <= 0; st <= S_TWALK; end
            else st <= S_IDLE;
          end
        end
        S_TWALK: begin
          if (tk >= 4'(K)) begin
            train_done_o <= 1'b1;
            st <= S_IDLE;
          end else if (!cid_ok(topk_class_id_o[tk[2:0]], topk_id_o[tk[2:0]]))
            tk <= tk + 4'd1;
          else begin
            learn_cid_o <= topk_class_id_o[tk[2:0]];
            st <= S_TLATCH;
          end
        end
        S_TLATCH: if (latch_rdy && latch_v) begin
          saw_done <= 1'b0; saw_nak <= 1'b0;
          st <= S_TPEND;
        end
        S_TPEND: if (pending_o) st <= S_TWAIT;
        S_TWAIT: begin
          if (saw_nak) begin
            train_done_o <= 1'b1;
            st <= S_IDLE;
          end else if (saw_done && !pbusy && !pending_o) begin
            n_learned <= n_learned + 16'd1;
            tk <= tk + 4'd1;
            st <= S_TWALK;
          end
        end
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
