// a7ng_causal_learn_fast.sv — P2-CAUSAL-LEARN-FAST-SERIAL-TOPK-01
// Same G1/G2/four-arm vehicle as FAST-00. Combo 8-sort replaced by sequential
// candidate scan + iterative Top-8 insert (minheap comparator law: higher score,
// then lower id). Extra cycles OK. Do not instantiate full-chip TopK. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_causal_learn_fast #(
  parameter int unsigned TXN_W = 16
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
  output logic [31:0]  ev_subj_o,
  output logic [7:0]   ev_rel_o,
  output logic [31:0]  ev_obj_o,
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
  output logic signed [15:0] c6_delta_o,
  output logic         c6_valid_o,
  output logic         c6_sat_o,
  output logic         c7_ack_valid_o,
  input  logic         c7_ack_ready_i,
  output logic [31:0]  c7_addr_o,
  output logic         c7_err_o
);
  import a7ng_pkg::*;

  localparam logic [7:0] Q_PRE        = 8'd1;
  localparam logic [7:0] Q_HOLD       = 8'd2;
  localparam logic [7:0] Q_UNREL      = 8'd3;
  localparam logic [7:0] Q_PRE_CONTRA = 8'd4;

  localparam logic [2:0] S_IDLE  = 3'd0;
  localparam logic [2:0] S_ISSUE = 3'd1;
  localparam logic [2:0] S_WAIT  = 3'd2;
  localparam logic [2:0] S_INS   = 3'd3;
  localparam logic [2:0] S_SNAP  = 3'd4;
  localparam logic [2:0] S_LATCH = 3'd5;

  logic [2:0] st;
  logic [7:0] qid;
  logic [3:0] feed_i, fill_n, ins_j, sh_k;
  logic       train_q, contra_q, ins_shift;
  node_id_t   new_id;
  score_t     new_s;

  node_id_t sc_id_i, sc_id_o;
  score_terms_t sc_terms;
  logic sc_v_i, sc_v_o;
  score_t sc_s_o;

  logic signed [7:0]  prior   [16];
  logic signed [7:0]  penalty [16];
  logic signed [15:0] edge_w  [16];

  logic        latch_v, latch_rdy;
  logic [31:0] ls, lo;
  logic [7:0]  lr, lc;
  logic [15:0] lqe, lpe;
  logic        lk;
  logic        cons_v, g2_in_rdy, g2_out_v, g2_out_rdy, g2_sat;
  logic signed [3:0] cons_r, g2_rew;
  logic [31:0] cons_s, cons_o, g2_s, g2_o;
  logic [7:0]  cons_rel, cons_c, g2_rel;
  logic [15:0] cons_qe, cons_pe, g2_qe, g2_pe, g2_nconf;
  logic        cons_k, g2_k;
  logic [TXN_W-1:0] cons_txn, g2_txn;
  logic signed [15:0] g2_delta;

  logic signed [8:0]  sum8;
  logic signed [7:0]  dpen;
  logic signed [16:0] sum16;
  logic [3:0]         gix;

  function automatic logic [31:0] g_id(input int unsigned i);
    return 32'h1000 + i;
  endfunction
  function automatic logic [31:0] g_subj(input int unsigned i);
    if ((i == 0) || (i == 1)) return 32'h0000_0010;
    else if (i < 8)           return 32'h0000_0020 + i;
    else                      return 32'h0000_0080 + i;
  endfunction
  function automatic logic [7:0] g_rel(input int unsigned i);
    if ((i == 0) || (i == 1)) return 8'd1;
    else                      return 8'd2 + i[7:0];
  endfunction
  function automatic logic [31:0] g_obj(input int unsigned i);
    return 32'h0000_0200 + i;
  endfunction
  function automatic int unsigned gi_of(input logic [7:0] q, input int unsigned li);
    if (q == Q_UNREL) return 8 + li;
    return li;
  endfunction
  function automatic logic is_train(input logic [7:0] q);
    return (q == Q_PRE) || (q == Q_PRE_CONTRA);
  endfunction
  function automatic logic is_contra(input logic [7:0] q);
    return (q == Q_PRE_CONTRA);
  endfunction
  function automatic term_t t8(input int v);
    return term_t'(v);
  endfunction
  function automatic score_terms_t base_terms(input logic [7:0] q, input int unsigned li);
    score_terms_t t;
    t = '0;
    t.path_confidence = '0;
    if ((q == Q_PRE) || (q == Q_PRE_CONTRA)) begin
      case (li)
        0: begin t.entity_match=t8(10); t.intent_match=t8(10); t.relation_match=t8(10); t.context_match=t8(10); end
        1: begin t.entity_match=t8(9);  t.intent_match=t8(9);  t.relation_match=t8(10); t.context_match=t8(10); end
        2: begin t.entity_match=t8(12); t.intent_match=t8(12); t.relation_match=t8(12); t.context_match=t8(8);  end
        3: begin t.entity_match=t8(11); t.intent_match=t8(11); t.relation_match=t8(11); t.context_match=t8(8);  end
        4: begin t.entity_match=t8(8);  t.intent_match=t8(8);  t.relation_match=t8(8);  t.context_match=t8(8);  end
        5: begin t.entity_match=t8(7);  t.intent_match=t8(7);  t.relation_match=t8(7);  t.context_match=t8(7);  end
        6: begin t.entity_match=t8(6);  t.intent_match=t8(6);  t.relation_match=t8(6);  t.context_match=t8(6);  end
        default: begin t.entity_match=t8(5); t.intent_match=t8(5); t.relation_match=t8(5); t.context_match=t8(5); end
      endcase
    end else if (q == Q_HOLD) begin
      case (li)
        0: begin t.entity_match=t8(9);  t.intent_match=t8(10); t.relation_match=t8(10); t.context_match=t8(10); end
        1: begin t.entity_match=t8(8);  t.intent_match=t8(9);  t.relation_match=t8(10); t.context_match=t8(10); end
        2: begin t.entity_match=t8(12); t.intent_match=t8(12); t.relation_match=t8(11); t.context_match=t8(8);  end
        3: begin t.entity_match=t8(11); t.intent_match=t8(10); t.relation_match=t8(11); t.context_match=t8(8);  end
        4: begin t.entity_match=t8(8);  t.intent_match=t8(7);  t.relation_match=t8(8);  t.context_match=t8(8);  end
        5: begin t.entity_match=t8(7);  t.intent_match=t8(6);  t.relation_match=t8(7);  t.context_match=t8(7);  end
        6: begin t.entity_match=t8(6);  t.intent_match=t8(6);  t.relation_match=t8(5);  t.context_match=t8(6);  end
        default: begin t.entity_match=t8(5); t.intent_match=t8(4); t.relation_match=t8(5); t.context_match=t8(5); end
      endcase
    end else begin
      case (li)
        0: begin t.entity_match=t8(20); t.intent_match=t8(15); t.relation_match=t8(10); t.context_match=t8(5); end
        1: begin t.entity_match=t8(18); t.intent_match=t8(14); t.relation_match=t8(9);  t.context_match=t8(4); end
        2: begin t.entity_match=t8(16); t.intent_match=t8(13); t.relation_match=t8(8);  t.context_match=t8(3); end
        3: begin t.entity_match=t8(14); t.intent_match=t8(12); t.relation_match=t8(7);  t.context_match=t8(2); end
        4: begin t.entity_match=t8(12); t.intent_match=t8(11); t.relation_match=t8(6);  t.context_match=t8(2); end
        5: begin t.entity_match=t8(10); t.intent_match=t8(10); t.relation_match=t8(5);  t.context_match=t8(1); end
        6: begin t.entity_match=t8(8);  t.intent_match=t8(9);  t.relation_match=t8(4);  t.context_match=t8(1); end
        default: begin t.entity_match=t8(6); t.intent_match=t8(8); t.relation_match=t8(3); t.context_match=t8(1); end
      endcase
    end
    return t;
  endfunction
  // Comparator law identical to frozen a7ng_topk / stream minheap (valid always 1 here).
  function automatic logic beats(input score_t sa, input node_id_t ia,
                                 input score_t sb, input node_id_t ib);
    if (sa != sb) return sa > sb;
    return ia < ib;
  endfunction
  function automatic logic signed [7:0] sat8(input logic signed [8:0] x);
    if (x > 9'sd127)  return 8'sd127;
    if (x < -9'sd128) return -8'sd128;
    return x[7:0];
  endfunction
  function automatic logic signed [15:0] sat16w(input logic signed [16:0] x);
    if (x > 17'sd32767)  return 16'sd32767;
    if (x < -17'sd32768) return -16'sd32768;
    return x[15:0];
  endfunction

  a7ng_scorer_lane u_scorer (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_v_i), .cand_id_i(sc_id_i), .terms_i(sc_terms),
    .valid_o(sc_v_o), .cand_id_o(sc_id_o), .score_o(sc_s_o)
  );

  a7ng_feedback_resolver #(.TXN_W(TXN_W)) u_g1 (
    .clk(clk), .rst_n(rst_n), .learn_i(learn_i), .freeze_i(freeze_i),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(ls), .rel_i(lr), .obj_i(lo),
    .q_epoch_i(lqe), .p_epoch_i(lpe), .conf_i(lc), .contradict_i(lk),
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

  assign query_ready_o = (st == S_IDLE);
  assign c5_consume_o  = cons_v && g2_in_rdy;
  assign c6_delta_o    = g2_delta;
  assign c6_valid_o    = g2_out_v;
  assign c6_sat_o      = g2_sat;
  assign c7_err_o      = 1'b0;
  assign g2_out_rdy    = g2_out_v && !c7_ack_valid_o;

  always_comb begin
    sc_v_i   = 1'b0;
    sc_id_i  = '0;
    sc_terms = '0;
    latch_v  = 1'b0;
    ls = 32'h10; lr = 8'd1; lo = 32'h200; lc = 8'd1;
    lqe = 16'd1; lpe = 16'd1; lk = 1'b0;
    if (st == S_ISSUE) begin
      sc_v_i  = 1'b1;
      sc_id_i = g_id(gi_of(qid, int'(feed_i)));
      sc_terms = base_terms(qid, int'(feed_i));
      sc_terms.learned_prior         = prior[gi_of(qid, int'(feed_i))];
      sc_terms.contradiction_penalty = penalty[gi_of(qid, int'(feed_i))];
    end
    if (st == S_LATCH) begin
      latch_v = 1'b1;
      ls = g_subj(0);
      lr = g_rel(0);
      lo = g_obj(0);
      lk = contra_q;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      qid <= '0; feed_i <= '0;
      fill_n <= '0; ins_j <= '0; sh_k <= '0;
      train_q <= 1'b0; contra_q <= 1'b0; ins_shift <= 1'b0;
      new_id <= '0; new_s <= '0;
      snap_valid_o <= 1'b0;
      ev_subj_o <= '0; ev_rel_o <= '0; ev_obj_o <= '0;
      c7_ack_valid_o <= 1'b0; c7_addr_o <= '0;
      for (int pi = 0; pi < 8; pi = pi + 1) begin
        topk_id_o[pi] <= '0; topk_score_o[pi] <= '0;
      end
      for (int pi = 0; pi < 16; pi = pi + 1) begin
        prior[pi] <= 8'sd0; penalty[pi] <= 8'sd0; edge_w[pi] <= 16'sd0;
      end
    end else begin
      if (c7_ack_valid_o && c7_ack_ready_i)
        c7_ack_valid_o <= 1'b0;

      case (st)
        S_IDLE: begin
          if (query_valid_i) begin
            qid <= query_id_i;
            train_q <= is_train(query_id_i);
            contra_q <= is_contra(query_id_i);
            feed_i <= 4'd0; fill_n <= 4'd0;
            snap_valid_o <= 1'b0;
            st <= S_ISSUE;
          end
        end
        S_ISSUE: begin
          st <= S_WAIT;
        end
        S_WAIT: begin
          if (sc_v_o) begin
            new_id <= sc_id_o;
            new_s  <= sc_s_o;
            ins_j <= 4'd0;
            ins_shift <= 1'b0;
            st <= S_INS;
          end
        end
        S_INS: begin
          if (!ins_shift) begin
            if ((ins_j < fill_n) && beats(topk_score_o[ins_j], topk_id_o[ins_j], new_s, new_id))
              ins_j <= ins_j + 4'd1;
            else begin
              ins_shift <= 1'b1;
              sh_k <= fill_n;
            end
          end else if (sh_k > ins_j) begin
            topk_id_o[sh_k]    <= topk_id_o[sh_k-1];
            topk_score_o[sh_k] <= topk_score_o[sh_k-1];
            sh_k <= sh_k - 4'd1;
          end else begin
            topk_id_o[ins_j]    <= new_id;
            topk_score_o[ins_j] <= new_s;
            fill_n <= fill_n + 4'd1;
            ins_shift <= 1'b0;
            ins_j <= 4'd0;
            if (feed_i == 4'd7)
              st <= S_SNAP;
            else begin
              feed_i <= feed_i + 4'd1;
              st <= S_ISSUE;
            end
          end
        end
        S_SNAP: begin
          gix = topk_id_o[0][3:0];
          ev_subj_o <= g_subj(int'(gix));
          ev_rel_o  <= g_rel(int'(gix));
          ev_obj_o  <= g_obj(int'(gix));
          snap_valid_o <= 1'b1;
          if (snap_valid_o && snap_ready_i) begin
            snap_valid_o <= 1'b0;
            if (train_q) st <= S_LATCH;
            else         st <= S_IDLE;
          end
        end
        S_LATCH: begin
          if (latch_v && latch_rdy) st <= S_IDLE;
        end
        default: st <= S_IDLE;
      endcase

      if (g2_out_v && g2_out_rdy) begin
        for (int pi = 0; pi < 16; pi = pi + 1) begin
          if (g_subj(pi) == g2_s) begin
            sum8 = $signed({prior[pi][7], prior[pi]}) + $signed({{5{g2_rew[3]}}, g2_rew});
            prior[pi] <= sat8(sum8);
          end
          if ((g_subj(pi) == g2_s) && (g_rel(pi) == g2_rel) && (g_obj(pi) == g2_o)) begin
            sum16 = $signed({edge_w[pi][15], edge_w[pi]}) + $signed({{1{g2_delta[15]}}, g2_delta});
            edge_w[pi] <= sat16w(sum16);
          end
          if (g2_k) begin
            sum16 = g2_delta[15] ? -$signed({{1{g2_delta[15]}}, g2_delta})
                                 : $signed({{1{g2_delta[15]}}, g2_delta});
            dpen = (sum16 > 17'sd127) ? 8'sd127 : sum16[7:0];
            if ((g_subj(pi) == g2_s) && (g_rel(pi) == g2_rel)) begin
              sum8 = $signed({penalty[pi][7], penalty[pi]}) + $signed({1'b0, dpen});
              penalty[pi] <= sat8(sum8);
            end
          end
        end
        c7_ack_valid_o <= 1'b1;
        c7_addr_o      <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, g2_s[15:0], 4'h0};
      end
    end
  end
endmodule
