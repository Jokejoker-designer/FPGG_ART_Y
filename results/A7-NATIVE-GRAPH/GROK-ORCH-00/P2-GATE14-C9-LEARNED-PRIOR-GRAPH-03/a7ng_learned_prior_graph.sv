// a7ng_learned_prior_graph.sv — P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03
// One G1, one G2, one persist store, one scorer_lane, one minheap.
// Learned prior into terms.learned_prior BEFORE heap. C9 = graph TopK.
// Do not pack persist FAST IDs as C9. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_learned_prior_graph #(
  parameter int unsigned TXN_W = 16,
  parameter logic [31:0] WRAP_LIMIT = 32'd6
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         learn_i,
  input  logic         freeze_i,
  input  logic         query_valid_i,
  output logic         query_ready_o,
  input  logic [7:0]   query_id_i,
  output logic         snap_valid_o,
  input  logic         snap_ready_i,
  output a7ng_pkg::node_id_t topk_id_o [8],
  output a7ng_pkg::score_t   topk_score_o [8],
  output logic [63:0]  c3_pack_o,
  output logic [63:0]  c9_pack_o,
  output logic         pending_o,
  output logic [TXN_W-1:0] txn_o,
  input  logic         reward_valid_i,
  input  logic signed [3:0] reward_i,
  input  logic         txn_echo_valid_i,
  input  logic [TXN_W-1:0] txn_echo_i,
  output logic         reward_ready_o,
  output logic         ack_valid_o,
  output logic [2:0]   ack_o,
  output logic         c5_consume_o,
  output logic         c7_ack_valid_o,
  input  logic         c7_ack_ready_i,
  output logic [31:0]  c7_addr_o,
  output logic [15:0]  c7_commit_seq_o,
  output logic [15:0]  c7_ack_count_o,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  input  logic         flush_i,
  input  logic         reload_i,
  input  logic         bram_kill_i,
  input  logic         train_reset_i,
  output logic         persist_busy_o,
  output logic         persist_done_o,
  output logic         ddr_req_o,
  output logic         ddr_we_o,
  output logic [7:0]   ddr_addr_o,
  output logic [63:0]  ddr_wdata_o,
  input  logic [63:0]  ddr_rdata_i,
  input  logic         ddr_ack_i
);
  import a7ng_pkg::*;

  localparam logic [7:0] Q_HOLD_A=8'd2, Q_UNREL=8'd3, Q_CONTRA=8'd4, Q_HOLD_B=8'd6;
  localparam logic [3:0] S_IDLE=0, S_LATCH=1, S_CLR=2, S_LK=3, S_LKW=4,
                         S_SC=5, S_SCW=6, S_GOT=7, S_HP=8, S_DRAIN=9,
                         S_PACK=10, S_SNAP=11;

  logic [3:0] st;
  logic [7:0] qid;
  logic [2:0] cand_i;
  logic       pass_c9, boot_done;
  logic [31:0] live_gen;
  logic [63:0] sdig, c3_pack, c9_pack;
  logic        pbusy, pdone, wrap_im;
  logic        lk_go, lk_busy, lk_done, lk_hit;
  logic signed [7:0] lk_pri, lk_pen;
  logic [31:0] lk_s, lk_o;
  logic [7:0]  lk_r;

  logic latch_v, latch_rdy, cons_v, g2_in_rdy, g2_out_v, g2_out_rdy;
  logic signed [3:0] cons_r, g2_rew;
  logic [31:0] cons_s, cons_o, g2_s, g2_o;
  logic [7:0] cons_rel, g2_rel, cons_c;
  logic [15:0] cons_qe, cons_pe, g2_qe, g2_pe, g2_nconf;
  logic cons_k, g2_k, g2_sat;
  logic [TXN_W-1:0] cons_txn, g2_txn;
  logic signed [15:0] g2_delta;
  logic [31:0] ls, lo;
  logic [7:0]  lr;

  logic sc_v_i, sc_v_o;
  node_id_t sc_id_i, sc_id_o, cap_id;
  score_terms_t sc_terms;
  score_t sc_s_o, cap_s;

  logic hp_clr, hp_in_v, hp_in_rdy, hp_in_last, hp_in_vv;
  logic hp_out_v, hp_busy, hp_clr_ign;
  score_t hp_in_s, hp_out_s;
  node_id_t hp_in_id, hp_out_id;
  logic [3:0] hp_lane;
  logic [2:0] hp_idx;
  logic [31:0] hp_acc, hp_ret, hp_drop;
  logic hp_out_rdy;

  function automatic logic is_pre_a(input logic [7:0] q);
    return (q >= 8'h10) && (q <= 8'h23);
  endfunction
  function automatic logic is_pre_b(input logic [7:0] q);
    return (q >= 8'h30) && (q <= 8'h43);
  endfunction
  function automatic logic is_train(input logic [7:0] q);
    return is_pre_a(q) || is_pre_b(q);
  endfunction
  function automatic logic [4:0] fi_of(input logic [7:0] q);
    if (is_pre_a(q)) return 5'(q - 8'h10);
    if (is_pre_b(q)) return 5'(q - 8'h30);
    return 5'd0;
  endfunction
  function automatic node_id_t nid_a(input int unsigned i);
    return 32'h20 + i;
  endfunction
  function automatic node_id_t nid_b(input int unsigned i);
    return 32'h40 + i;
  endfunction
  function automatic node_id_t nid_u(input int unsigned i);
    return 32'h80 + i;
  endfunction
  function automatic logic [31:0] subj_a(input int unsigned i);
    return 32'hA000 + i;
  endfunction
  function automatic logic [31:0] obj_a(input int unsigned i);
    return 32'hB000 + i;
  endfunction
  function automatic logic [31:0] obj_b(input int unsigned i);
    return 32'hC000 + i;
  endfunction
  function automatic logic [31:0] subj_u(input int unsigned i);
    return 32'hD000 + i;
  endfunction
  function automatic logic [31:0] obj_u(input int unsigned i);
    return 32'hE000 + i;
  endfunction
  function automatic node_id_t cand_nid(input logic [7:0] q, input int unsigned ci);
    if (q == Q_UNREL) return nid_u(ci);
    if (q == Q_HOLD_B) return (ci < 4) ? nid_b(ci) : nid_u(ci-4);
    if (ci < 4) return nid_a(ci);
    return nid_u(ci-4);
  endfunction
  function automatic logic [31:0] cand_s(input logic [7:0] q, input int unsigned ci);
    if (q == Q_UNREL) return subj_u(ci);
    if (q == Q_HOLD_B) return (ci < 4) ? subj_a(ci) : subj_u(ci-4);
    if (ci < 4) return subj_a(ci);
    return subj_u(ci-4);
  endfunction
  function automatic logic [7:0] cand_r(input logic [7:0] q, input int unsigned ci);
    if (q == Q_UNREL) return 8'd3;
    if (q == Q_HOLD_B) return (ci < 4) ? 8'd2 : 8'd3;
    if (q == Q_CONTRA) return (ci < 4) ? 8'd2 : 8'd3;
    if (ci < 4) return 8'd1;
    return 8'd3;
  endfunction
  function automatic logic [31:0] cand_o(input logic [7:0] q, input int unsigned ci);
    if (q == Q_UNREL) return obj_u(ci);
    if (q == Q_HOLD_B) return (ci < 4) ? obj_b(ci) : obj_u(ci-4);
    if (ci < 4) return obj_a(ci);
    return obj_u(ci-4);
  endfunction
  function automatic score_terms_t mix_terms(input logic [7:0] q, input int unsigned ci);
    score_terms_t t;
    t = '0;
    t.intent_match = term_t'(8'sd8);
    t.relation_match = term_t'(8'sd8);
    t.context_match = term_t'(8'sd8);
    if (q == Q_UNREL) begin
      t.entity_match = term_t'(20 - 2*ci);
      t.intent_match = term_t'(15 - ci);
    end else if (ci < 4)
      t.entity_match = term_t'(8 - ci);
    else
      t.entity_match = term_t'(10 - (ci-4));
    return t;
  endfunction
  function automatic logic [63:0] pack_ids(input node_id_t ids [8]);
    logic [63:0] p;
    integer k;
    p = 64'd0;
    for (k = 0; k < 8; k = k + 1)
      p[8*k +: 8] = ids[k][7:0];
    return p;
  endfunction

  a7ng_feedback_resolver #(.TXN_W(TXN_W)) u_g1 (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(ls), .rel_i(lr), .obj_i(lo),
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
  a7ng_learned_prior_store #(.WRAP_LIMIT(WRAP_LIMIT)) u_st (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .flush_i(flush_i), .reload_i(reload_i), .bram_kill_i(bram_kill_i),
    .train_reset_i(train_reset_i),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .boot_done_o(boot_done),
    .live_gen_o(live_gen), .sdig_o(sdig), .wrap_imminent_o(wrap_im),
    .upd_valid_i(g2_out_v), .upd_ready_o(g2_out_rdy),
    .upd_subj_i(g2_s), .upd_rel_i(g2_rel), .upd_obj_i(g2_o),
    .upd_rew_i(g2_rew), .upd_contra_i(g2_k),
    .lk_go_i(lk_go), .lk_subj_i(lk_s), .lk_rel_i(lk_r), .lk_obj_i(lk_o),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(c7_ack_valid_o), .c7_ack_ready_i(c7_ack_ready_i),
    .c7_addr_o(c7_addr_o), .c7_commit_seq_o(c7_commit_seq_o),
    .c7_ack_count_o(c7_ack_count_o),
    .ddr_req_o(ddr_req_o), .ddr_we_o(ddr_we_o), .ddr_addr_o(ddr_addr_o),
    .ddr_wdata_o(ddr_wdata_o), .ddr_rdata_i(ddr_rdata_i), .ddr_ack_i(ddr_ack_i)
  );
  a7ng_scorer_lane u_scorer (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_v_i), .cand_id_i(sc_id_i), .terms_i(sc_terms),
    .valid_o(sc_v_o), .cand_id_o(sc_id_o), .score_o(sc_s_o)
  );
  a7ng_topk_stream_minheap #(.K(8)) u_hp (
    .clk(clk), .rst_n(rst_n),
    .clear_i(hp_clr),
    .in_valid_i(hp_in_v), .in_ready_o(hp_in_rdy),
    .in_v_i(hp_in_vv), .in_s_i(hp_in_s), .in_id_i(hp_in_id), .in_lane_i(hp_lane),
    .in_last_i(hp_in_last),
    .out_valid_o(hp_out_v), .out_ready_i(hp_out_rdy),
    .out_s_o(hp_out_s), .out_id_o(hp_out_id), .out_idx_o(hp_idx),
    .busy_o(hp_busy), .clear_ignored_o(hp_clr_ign),
    .accepted_count_o(hp_acc), .retired_count_o(hp_ret), .drop_count_o(hp_drop)
  );

  assign persist_busy_o = pbusy;
  assign persist_done_o = pdone;
  assign c8_gen_o = live_gen;
  assign c8_sdig_o = sdig;
  assign c3_pack_o = c3_pack;
  assign c9_pack_o = c9_pack;
  assign c5_consume_o = cons_v && g2_in_rdy;
  assign query_ready_o = (st == S_IDLE) && boot_done && !pbusy && !pending_o;
  assign hp_out_rdy = 1'b1;
  assign hp_lane = 4'd0;
  assign hp_in_vv = 1'b1;

  always_comb begin
    latch_v = 1'b0;
    lk_go = 1'b0;
    sc_v_i = 1'b0;
    sc_id_i = cand_nid(qid, int'(cand_i));
    sc_terms = mix_terms(qid, int'(cand_i));
    hp_clr = 1'b0;
    hp_in_v = 1'b0;
    hp_in_last = 1'b0;
    hp_in_s = cap_s;
    hp_in_id = cap_id;
    ls = 32'hA000; lr = 8'd1; lo = 32'hB000;
    lk_s = cand_s(qid, int'(cand_i));
    lk_r = cand_r(qid, int'(cand_i));
    lk_o = cand_o(qid, int'(cand_i));
    if (st == S_LATCH) begin
      latch_v = 1'b1;
      ls = subj_a(int'(fi_of(qid)));
      if (is_pre_b(qid)) begin lr = 8'd2; lo = obj_b(int'(fi_of(qid))); end
      else begin lr = 8'd1; lo = obj_a(int'(fi_of(qid))); end
    end
    if (st == S_CLR)
      hp_clr = !hp_busy;
    if (st == S_LK)
      lk_go = pass_c9; // one-cycle pulse; wait S_LKW
    if (st == S_SC) begin
      sc_v_i = 1'b1;
      if (pass_c9 && lk_hit) begin
        sc_terms.learned_prior = lk_pri;
        sc_terms.contradiction_penalty = lk_pen;
      end
    end
    if (st == S_HP) begin
      hp_in_v = 1'b1;
      hp_in_last = (cand_i == 3'd7);
    end
  end

  integer ki;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; qid <= '0; cand_i <= '0;
      pass_c9 <= 0; snap_valid_o <= 0;
      c3_pack <= '0; c9_pack <= '0; cap_id <= '0; cap_s <= '0;
      for (ki = 0; ki < 8; ki = ki + 1) begin
        topk_id_o[ki] <= '0; topk_score_o[ki] <= '0;
      end
    end else begin
      if (sc_v_o) begin
        cap_id <= sc_id_o;
        cap_s  <= sc_s_o;
      end
      unique case (st)
        S_IDLE: if (query_valid_i && query_ready_o) begin
          qid <= query_id_i;
          cand_i <= 0; pass_c9 <= 0; snap_valid_o <= 0;
          if (is_train(query_id_i)) st <= S_LATCH;
          else st <= S_CLR;
        end
        S_LATCH: if (latch_rdy) st <= S_IDLE;
        S_CLR: if (!hp_busy) st <= S_LK;
        S_LK: begin
          if (!pass_c9) st <= S_SC;
          else st <= S_LKW;
        end
        S_LKW: if (lk_done) st <= S_SC;
        S_SC: st <= S_SCW;
        S_SCW: if (sc_v_o) st <= S_GOT;
        S_GOT: st <= S_HP;
        S_HP: if (hp_in_rdy) begin
          if (cand_i == 3'd7) st <= S_DRAIN;
          else begin cand_i <= cand_i + 3'd1; st <= S_LK; end
        end
        S_DRAIN: if (hp_out_v) begin
          topk_id_o[hp_idx] <= hp_out_id;
          topk_score_o[hp_idx] <= hp_out_s;
          if (hp_idx == 3'd7) st <= S_PACK;
        end
        S_PACK: begin
          if (!pass_c9) begin
            c3_pack <= pack_ids(topk_id_o);
            pass_c9 <= 1'b1; cand_i <= 0; st <= S_CLR;
          end else begin
            c9_pack <= pack_ids(topk_id_o);
            st <= S_SNAP;
          end
        end
        S_SNAP: begin
          snap_valid_o <= 1'b1;
          if (snap_valid_o && snap_ready_i) begin
            snap_valid_o <= 1'b0; st <= S_IDLE;
          end
        end
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
