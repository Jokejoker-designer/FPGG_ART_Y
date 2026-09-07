// a7ng_u7a_r3b_typeclass_to_learn.sv
// U7A-R3B: TYPE_CLASS Top-K CLASS_ID → LEARN_KEY_CLASS_CONTEXT_V1 → G1 → G2 → store
// → lookup prior → scorer. Host does not construct the learn key.
// U6 retrieval remains learn=0. U7 CLOSED. QHEAD=NO. BIT=NO. PROGRAM=NO.
// C7_ADDR OBSERVE_ONLY. persist_gen_fast not instantiated.
`timescale 1ns / 1ps

module a7ng_u7a_r3b_typeclass_to_learn #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned K        = 8,
  parameter int unsigned TXN_W    = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        learn_i,
  input  logic        freeze_i,
  // QSE poke (query, not learn-target)
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
  output logic        retr_done_o,
  output logic        batch_done_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_learned_o,
  output logic [15:0] topk_class_id_o [K],
  output a7ng_pkg::node_id_t topk_id_o [K],
  output a7ng_pkg::score_t   topk_sc_o [K],
  output logic [15:0] n_host_or_o,
  // teacher scalar only (not identity)
  input  logic        reward_valid_i,
  input  logic signed [3:0] reward_i,
  input  logic        txn_echo_valid_i,
  input  logic [TXN_W-1:0] txn_echo_i,
  output logic        reward_ready_o,
  output logic        pending_o,
  output logic [TXN_W-1:0] txn_o,
  output logic        ack_valid_o,
  output logic [2:0]  ack_o,
  // observe FPGA-built key of current latch
  output logic [15:0] learn_cid_o,
  output logic [31:0] learn_subj_o,
  output logic [7:0]  learn_rel_o,
  output logic [31:0] learn_obj_o,
  // CLASS_ID 58 snaps (FPGA-captured)
  output logic        saw58_chiller_o,
  output logic        saw58_water_o,
  output logic [31:0] k58c_subj_o,
  output logic [7:0]  k58c_rel_o,
  output logic [31:0] k58c_obj_o,
  output logic signed [7:0] pri58_chiller_o,
  output logic [31:0] k58w_subj_o,
  output logic [7:0]  k58w_rel_o,
  output logic [31:0] k58w_obj_o,
  output logic signed [7:0] pri58_water_o,
  output logic [15:0] high_cid_o,
  output logic [31:0] high_subj_o,
  // snap lookup (FPGA keys / internal falsifier). sel: 0=chiller58 1=water58 2=unbound-mask
  input  logic        lk_snap_go_i,
  input  logic [1:0]  lk_snap_sel_i,
  output logic        lk_busy_o,
  output logic        lk_done_o,
  output logic        lk_hit_o,
  output logic signed [7:0] lk_pri_o,
  output logic signed [7:0] lk_pen_o,
  // scorer probe after auto-lookup of the just-written key
  output logic        probe_valid_o,
  output a7ng_pkg::score_t probe_score_o,
  output logic [15:0] probe_cid_o,
  // persist / C7 observe
  output logic        persist_busy_o,
  output logic        persist_done_o,
  output logic        persist_nak_o,
  output logic        boot_done_o,
  output logic        c7_ack_valid_o,
  output logic [31:0] c7_addr_o,
  output logic [15:0] c7_commit_seq_o,
  output logic [15:0] c7_ack_count_o,
  output logic [4:0]  dbg_st_o,
  // TB-modeled DDR
  output logic        ddr_req_o,
  output logic        ddr_we_o,
  output logic [7:0]  ddr_addr_o,
  output logic [63:0] ddr_wdata_o,
  input  logic [63:0] ddr_rdata_i,
  input  logic        ddr_ack_i
);
  import a7ng_pkg::*;

  typedef enum logic [4:0] {
    S_BOOT, S_IDLE, S_RETR, S_WALK, S_LATCH, S_PEND, S_WAIT_ST,
    S_MAT, S_LK, S_LKW, S_SC, S_SCW, S_BATCH
  } st_t;
  st_t st;

  logic        u6_done, u6_ovf;
  logic [15:0] u6_trunc, u6_scored;
  node_id_t    u6_id [K];
  logic [15:0] u6_cid [K];
  score_t      u6_sc [K];

  logic [7:0]  qe, qi, qr, qx;
  logic        ev, iv, rv, xv;

  logic [15:0] cap_cid [K];
  node_id_t    cap_id  [K];
  score_t      cap_sc  [K];
  logic [3:0]  k;
  logic [15:0] n_learned;
  logic [15:0] cur_cid;

  logic [31:0] ks, ko, lk_s, lk_o;
  logic [7:0]  kr, lk_r;

  logic        latch_v, latch_rdy, cons_v, g2_in_rdy, g2_out_v, g2_out_rdy;
  logic signed [3:0] cons_r, g2_rew;
  logic [31:0] cons_s, cons_o, g2_s, g2_o;
  logic [7:0]  cons_rel, g2_rel, cons_c;
  logic [15:0] cons_qe, cons_pe, g2_qe, g2_pe, g2_nconf;
  logic        cons_k, g2_k, g2_sat;
  logic [TXN_W-1:0] cons_txn, g2_txn;
  logic signed [15:0] g2_delta;
  logic        pbusy, pdone, pnak, boot_done;
  logic        lk_go, lk_busy, lk_done, lk_hit;
  logic signed [7:0] lk_pri, lk_pen;
  logic        saw_done, saw_nak;

  logic        mat_go, mat_hit;
  logic [15:0] mat_id, mat_ptr, mat_cnt;
  logic [7:0]  me, mi, mr, mx;

  logic        sc_vi, sc_vo;
  node_id_t    sc_idi, sc_ido;
  score_terms_t sc_tm;
  score_t      sc_so;

  logic        snap_go_q;
  integer      ki;

  function automatic logic cid_ok(input logic [15:0] c, input node_id_t id);
    return (c >= 16'd1) && (c <= 16'd443) && (id[31:16] == 16'd0) && (id[15:0] == c);
  endfunction

  function automatic logic is_chiller_q();
    return ev && !iv && !rv && !xv && (qe == 8'd1) && (qi == 8'd0) && (qr == 8'd0) && (qx == 8'd0);
  endfunction
  function automatic logic is_water_q();
    return ev && !iv && !rv && xv && (qe == 8'd1) && (qi == 8'd0) && (qr == 8'd0) && (qx == 8'd1);
  endfunction

  a7ng_u6_typeclass_retrieval #(.CAND_CAP(CAND_CAP), .K(K)) u_u6 (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(1'b0), .tok_ready_o(), .tok_i(8'd0),
    .fire_i(1'b0), .retire_i(1'b0),
    .qse_valid_o(), .q_ent_o(), .q_int_o(), .q_rel_o(), .q_ctx_o(),
    .n_host_or_o(n_host_or_o),
    .poke_i(poke_i), .poke_go_i(poke_go_i && (st == S_IDLE || st == S_RETR)),
    .poke_ent_i(poke_ent_i), .poke_int_i(poke_int_i),
    .poke_rel_i(poke_rel_i), .poke_ctx_i(poke_ctx_i),
    .poke_ev_i(poke_ev_i), .poke_iv_i(poke_iv_i),
    .poke_rv_i(poke_rv_i), .poke_xv_i(poke_xv_i),
    .stall_scan_i(1'b0), .stall_heap_i(1'b0),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .done_o(u6_done), .retrieval_overflow_o(u6_ovf), .retrieval_trunc_o(u6_trunc),
    .n_emit_o(n_emit_o), .n_scored_o(u6_scored),
    .topk_id_o(u6_id), .topk_class_id_o(u6_cid), .topk_sc_o(u6_sc),
    .dbg_st_o(), .dbg_scan_v_o(), .dbg_scan_id_o(),
    .dbg_mat_v_o(), .dbg_mat_id_o(),
    .dbg_mat_eid_o(), .dbg_mat_iid_o(), .dbg_mat_rid_o(), .dbg_mat_xid_o(),
    .dbg_mat_ptr_o(), .dbg_mat_cnt_o(),
    .dbg_sc_v_o(), .dbg_sc_o(), .dbg_te_o(), .dbg_ti_o(), .dbg_tr_o(), .dbg_tc_o()
  );

  a7ng_learn_key_class_context_v1 u_key (
    .class_id_i(cur_cid),
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
    .consume_conf_o(cons_c), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
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
    .delta_o(g2_delta), .sat_flag_o(g2_sat),
    .out_reward(g2_rew), .out_native_conf(g2_nconf),
    .out_subj(g2_s), .out_rel(g2_rel), .out_obj(g2_o),
    .out_q_epoch(g2_qe), .out_p_epoch(g2_pe),
    .out_contradict(g2_k), .out_txn(g2_txn)
  );

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .flush_i(1'b0), .reload_i(1'b0), .bram_kill_i(1'b0), .train_reset_i(1'b0),
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

  a7ng_typeclass_materialize u_mat (
    .clk(clk), .rst_n(rst_n),
    .go_i(mat_go), .class_id_i(cur_cid),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .hit_o(mat_hit), .class_id_o(mat_id),
    .eid_o(me), .iid_o(mi), .rid_o(mr), .xid_o(mx),
    .member_ptr_o(mat_ptr), .member_count_o(mat_cnt)
  );

  a7ng_scorer_lane u_sc (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_vi), .cand_id_i(sc_idi), .terms_i(sc_tm),
    .valid_o(sc_vo), .cand_id_o(sc_ido), .score_o(sc_so)
  );

  assign persist_busy_o = pbusy;
  assign persist_done_o = pdone;
  assign persist_nak_o  = pnak;
  assign boot_done_o    = boot_done;
  assign lk_busy_o      = lk_busy;
  assign lk_done_o      = lk_done;
  assign lk_hit_o       = lk_hit;
  assign lk_pri_o       = lk_pri;
  assign lk_pen_o       = lk_pen;
  assign n_learned_o    = n_learned;
  assign learn_cid_o    = cur_cid;
  assign learn_subj_o   = ks;
  assign learn_rel_o    = kr;
  assign learn_obj_o    = ko;
  assign dbg_st_o       = 5'(st);

  always_comb begin
    sc_tm = '0;
    sc_tm.entity_match   = (qe != 8'd0 && qe == me) ? term_t'(8'sd8) : '0;
    sc_tm.intent_match   = (qi != 8'd0 && qi == mi) ? term_t'(8'sd8) : '0;
    sc_tm.relation_match = (qr != 8'd0 && qr == mr) ? term_t'(8'sd8) : '0;
    sc_tm.context_match  = (qx != 8'd0 && qx == mx) ? term_t'(8'sd8) : '0;
    sc_tm.learned_prior  = term_t'(lk_pri);
    sc_idi = {16'd0, cur_cid};
  end

  always_comb begin
    latch_v = 1'b0;
    mat_go  = 1'b0;
    lk_go   = 1'b0;
    sc_vi   = 1'b0;
    lk_s = ks; lk_r = kr; lk_o = ko;
    if (st == S_IDLE && lk_snap_go_i) begin
      unique case (lk_snap_sel_i)
        2'd0: begin lk_s = k58c_subj_o; lk_r = k58c_rel_o; lk_o = k58c_obj_o; end
        2'd1: begin lk_s = k58w_subj_o; lk_r = k58w_rel_o; lk_o = k58w_obj_o; end
        default: begin
          lk_s = {16'h5443, 16'd58};
          lk_r = 8'd0;
          lk_o = {8'd1, 8'd0, 8'd0, 8'd0};
        end
      endcase
    end
    unique case (st)
      S_LATCH: latch_v = latch_rdy;
      S_MAT:   mat_go  = 1'b1;
      S_LK:    lk_go   = 1'b1;
      S_SC:    sc_vi   = 1'b1;
      S_IDLE:  if (lk_snap_go_i && boot_done && !pbusy && !lk_busy) lk_go = 1'b1;
      default: ;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_BOOT;
      retr_done_o <= 1'b0;
      batch_done_o <= 1'b0;
      k <= 4'd0;
      n_learned <= 16'd0;
      cur_cid <= 16'd0;
      qe <= 8'd0; qi <= 8'd0; qr <= 8'd0; qx <= 8'd0;
      ev <= 1'b0; iv <= 1'b0; rv <= 1'b0; xv <= 1'b0;
      saw_done <= 1'b0; saw_nak <= 1'b0;
      saw58_chiller_o <= 1'b0; saw58_water_o <= 1'b0;
      k58c_subj_o <= 32'd0; k58c_rel_o <= 8'd0; k58c_obj_o <= 32'd0;
      k58w_subj_o <= 32'd0; k58w_rel_o <= 8'd0; k58w_obj_o <= 32'd0;
      pri58_chiller_o <= 8'sd0; pri58_water_o <= 8'sd0;
      high_cid_o <= 16'd0; high_subj_o <= 32'd0;
      probe_valid_o <= 1'b0; probe_score_o <= '0; probe_cid_o <= 16'd0;
      snap_go_q <= 1'b0;
      for (ki = 0; ki < K; ki = ki + 1) begin
        cap_cid[ki] <= 16'd0; cap_id[ki] <= '0; cap_sc[ki] <= '0;
        topk_class_id_o[ki] <= 16'd0; topk_id_o[ki] <= '0; topk_sc_o[ki] <= '0;
      end
    end else begin
      retr_done_o  <= 1'b0;
      probe_valid_o <= 1'b0;
      snap_go_q <= lk_snap_go_i;
      if (pdone) saw_done <= 1'b1;
      if (pnak)  saw_nak  <= 1'b1;

      unique case (st)
        S_BOOT: if (boot_done && !pbusy) st <= S_IDLE;
        S_IDLE: begin
          if (poke_i && poke_go_i) begin
            batch_done_o <= 1'b0;
            qe <= poke_ent_i; qi <= poke_int_i; qr <= poke_rel_i; qx <= poke_ctx_i;
            ev <= poke_ev_i; iv <= poke_iv_i; rv <= poke_rv_i; xv <= poke_xv_i;
            n_learned <= 16'd0;
            k <= 4'd0;
            st <= S_RETR;
          end
        end
        S_RETR: if (u6_done) begin
          retr_done_o <= 1'b1;
          for (ki = 0; ki < K; ki = ki + 1) begin
            cap_cid[ki] <= u6_cid[ki];
            cap_id[ki]  <= u6_id[ki];
            cap_sc[ki]  <= u6_sc[ki];
            topk_class_id_o[ki] <= u6_cid[ki];
            topk_id_o[ki] <= u6_id[ki];
            topk_sc_o[ki] <= u6_sc[ki];
          end
          k <= 4'd0;
          st <= S_WALK;
        end
        S_WALK: begin
          if (k >= 4'(K))
            st <= S_BATCH;
          else if (!cid_ok(cap_cid[k], cap_id[k]))
            k <= k + 4'd1;
          else begin
            cur_cid <= cap_cid[k];
            st <= S_LATCH;
          end
        end
        S_LATCH: if (latch_rdy && latch_v) begin
          saw_done <= 1'b0; saw_nak <= 1'b0;
          st <= S_PEND;
        end
        S_PEND: if (pending_o) st <= S_WAIT_ST;
        S_WAIT_ST: begin
          if (saw_nak)
            st <= S_BATCH; // unexpected; TB grades nak
          else if (saw_done && !pbusy && !pending_o)
            st <= S_MAT;
        end
        S_MAT: st <= S_LK;
        S_LK:  st <= S_LKW;
        S_LKW: if (lk_done) begin
          n_learned <= n_learned + 16'd1;
          if (cur_cid == 16'd58 && is_chiller_q()) begin
            saw58_chiller_o <= 1'b1;
            k58c_subj_o <= ks; k58c_rel_o <= kr; k58c_obj_o <= ko;
            pri58_chiller_o <= lk_pri;
          end
          if (cur_cid == 16'd58 && is_water_q()) begin
            saw58_water_o <= 1'b1;
            k58w_subj_o <= ks; k58w_rel_o <= kr; k58w_obj_o <= ko;
            pri58_water_o <= lk_pri;
          end
          if (cur_cid > 16'd255) begin
            high_cid_o <= cur_cid;
            high_subj_o <= ks;
          end
          st <= S_SC;
        end
        S_SC: st <= S_SCW;
        S_SCW: if (sc_vo) begin
          probe_valid_o <= 1'b1;
          probe_score_o <= sc_so;
          probe_cid_o   <= cur_cid;
          k <= k + 4'd1;
          st <= S_WALK;
        end
        S_BATCH: begin
          batch_done_o <= 1'b1;
          st <= S_IDLE;
        end
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
