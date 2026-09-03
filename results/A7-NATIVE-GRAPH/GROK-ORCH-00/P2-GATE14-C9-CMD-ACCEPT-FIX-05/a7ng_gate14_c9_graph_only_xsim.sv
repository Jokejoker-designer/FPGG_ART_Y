// a7ng_gate14_c9_graph_only_xsim.sv — P2-GATE14-C9-CMD-ACCEPT-FIX-05
// Glue + learned-prior graph only. No TinyGPT. Fake LM complete so exam C_FIRE
// can return to IDLE. PROGRAM=NO. Bag-local XSim wrapper, not product SoC.
`timescale 1ns / 1ps

module a7ng_gate14_c9_graph_only_xsim (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         cmd_valid_i,
  output logic         cmd_ready_o,
  input  logic [3:0]   cmd_i,
  input  logic [7:0]   tok_i,
  input  logic signed [3:0] reward_i,
  output logic [3:0]   c1_mode_o,
  output logic [63:0]  c2_anch_o,
  output logic [63:0]  c9_topk_o,
  output logic [63:0]  c9_pack_graph_o,
  output logic [127:0] c9_score_o,
  output logic [31:0]  c9_r1s_o,
  output logic [7:0]   c9_r1r_o,
  output logic [31:0]  c9_r1o_o,
  output logic         c10_lmst_o,
  output logic         c10_lmdn_o,
  output logic [9:0]   c10_out_o,
  output logic [15:0]  n_host_cue_o,
  output logic [15:0]  n_host_win_o,
  output logic [15:0]  n_host_addr_o,
  output logic [15:0]  n_host_tok_o,
  output logic [15:0]  n_host_w_o,
  output logic [15:0]  n_host_mode_o,
  output logic [2:0]   last_ack_o,
  output logic         exam_lm_used_o,
  output a7ng_pkg::node_id_t topk_id_o [8],
  output a7ng_pkg::score_t   topk_sc_o [8],
  output logic [15:0]  p_txn_o,
  output logic         c5_cons_o,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  output logic [31:0]  c7_addr_o,
  output logic         c7_v_o,
  output logic [15:0]  c7_commit_seq_o,
  output logic [15:0]  c7_ack_count_o,
  output logic         persist_busy_o,
  output logic         persist_done_o,
  output logic         query_valid_o,
  output logic         query_ready_o,
  output logic [7:0]   query_id_o,
  output logic         snap_valid_o,
  output logic         pending_o,
  output logic [63:0]  c11_adig_o,
  output logic [63:0]  c11_bdig_o,
  output logic         c11_a_for_o,
  output logic         c11_b_vis_o
);
  import a7ng_pkg::*;

  logic p_learn, p_freeze, p_qv, p_qr, p_sv, p_sr;
  logic [7:0] p_qid;
  node_id_t p_id [8];
  score_t   p_sc [8];
  logic [31:0] p_evs, p_evo, p_c7a;
  logic [7:0] p_evr;
  logic p_pend, p_rewv, p_echov, p_rewrdy, p_ackv, p_c5, p_c7v;
  logic [15:0] p_txn, p_echo, c7seq, c7cnt;
  logic signed [3:0] p_rew;
  logic [2:0] p_ack;
  logic p_flush, p_reload, p_kill, p_trst, p_busy, p_done;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, c8d, c3p, c9p;
  logic [31:0] c8g;
  logic [63:0] ddr_mem [0:127];
  logic lm_start, lm_done_d;
  integer di;

  assign topk_id_o = p_id;
  assign topk_sc_o = p_sc;
  assign p_txn_o = p_txn;
  assign c5_cons_o = p_c5;
  assign c8_gen_o = c8g;
  assign c8_sdig_o = c8d;
  assign c7_addr_o = p_c7a;
  assign c7_v_o = p_c7v;
  assign c7_commit_seq_o = c7seq;
  assign c7_ack_count_o = c7cnt;
  assign persist_busy_o = p_busy;
  assign persist_done_o = p_done;
  assign query_valid_o = p_qv;
  assign query_ready_o = p_qr;
  assign query_id_o = p_qid;
  assign snap_valid_o = p_sv;
  assign pending_o = p_pend;
  assign c9_pack_graph_o = c9p;
  assign p_evs = 32'd0;
  assign p_evr = 8'd0;
  assign p_evo = 32'd0;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  initial begin
    for (di = 0; di < 128; di = di + 1)
      ddr_mem[di] = 64'd0;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) lm_done_d <= 1'b0;
    else        lm_done_d <= lm_start;
  end

  a7ng_learned_prior_graph #(.WRAP_LIMIT(32'd6)) u_graph (
    .clk(clk), .rst_n(rst_n), .learn_i(p_learn), .freeze_i(p_freeze),
    .query_valid_i(p_qv), .query_ready_o(p_qr), .query_id_i(p_qid),
    .snap_valid_o(p_sv), .snap_ready_i(p_sr),
    .topk_id_o(p_id), .topk_score_o(p_sc),
    .c3_pack_o(c3p), .c9_pack_o(c9p),
    .pending_o(p_pend), .txn_o(p_txn),
    .reward_valid_i(p_rewv), .reward_i(p_rew),
    .txn_echo_valid_i(p_echov), .txn_echo_i(p_echo),
    .reward_ready_o(p_rewrdy),
    .ack_valid_o(p_ackv), .ack_o(p_ack),
    .c5_consume_o(p_c5),
    .c7_ack_valid_o(p_c7v), .c7_ack_ready_i(1'b1), .c7_addr_o(p_c7a),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .flush_i(p_flush), .reload_i(p_reload), .bram_kill_i(p_kill),
    .train_reset_i(p_trst),
    .persist_busy_o(p_busy), .persist_done_o(p_done),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_gate14_c9_glue u_glue (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(cmd_valid_i), .cmd_ready_o(cmd_ready_o),
    .cmd_i(cmd_i), .tok_i(tok_i), .reward_i(reward_i),
    .host_cue_i(64'd0), .host_winner_i(32'd0), .host_addr_i(32'd0),
    .host_next_i(10'd0), .host_wren_i(1'b0), .host_mode_i(4'd0),
    .p_learn_o(p_learn), .p_freeze_o(p_freeze),
    .p_qvalid_o(p_qv), .p_qready_i(p_qr), .p_qid_o(p_qid),
    .p_snap_v_i(p_sv), .p_snap_r_o(p_sr),
    .p_topk_id_i(p_id), .p_topk_sc_i(p_sc),
    .p_evs_i(p_evs), .p_evr_i(p_evr), .p_evo_i(p_evo),
    .p_pending_i(p_pend), .p_txn_i(p_txn),
    .p_rew_v_o(p_rewv), .p_rew_o(p_rew),
    .p_echo_v_o(p_echov), .p_echo_o(p_echo),
    .p_ack_v_i(p_ackv), .p_ack_i(p_ack), .p_c7_i(p_c7v),
    .p_flush_o(p_flush), .p_reload_o(p_reload),
    .p_kill_o(p_kill), .p_trst_o(p_trst), .p_busy_i(p_busy),
    .lm_start_o(lm_start), .lm_busy_i(1'b0),
    .lm_done_i(lm_done_d), .lm_pred_i(10'd0),
    .c1_mode_o(c1_mode_o), .c2_anch_o(c2_anch_o),
    .c9_topk_o(c9_topk_o), .c9_score_o(c9_score_o),
    .c9_r1s_o(c9_r1s_o), .c9_r1r_o(c9_r1r_o), .c9_r1o_o(c9_r1o_o),
    .c10_lmst_o(c10_lmst_o), .c10_lmdn_o(c10_lmdn_o), .c10_out_o(c10_out_o),
    .n_host_cue_o(n_host_cue_o), .n_host_win_o(n_host_win_o),
    .n_host_addr_o(n_host_addr_o), .n_host_tok_o(n_host_tok_o),
    .n_host_w_o(n_host_w_o), .n_host_mode_o(n_host_mode_o),
    .last_ack_o(last_ack_o), .exam_lm_used_o(exam_lm_used_o)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c11_adig_o <= 64'd0; c11_bdig_o <= 64'd0;
      c11_a_for_o <= 1'b0; c11_b_vis_o <= 1'b0;
    end else if (cmd_valid_i && cmd_ready_o) begin
      if (cmd_i == 4'd7) begin
        if (!c11_b_vis_o && !c11_a_for_o) c11_adig_o <= c8d;
        else begin c11_bdig_o <= c8d; c11_b_vis_o <= 1'b1; end
      end
      if (cmd_i == 4'd8) c11_a_for_o <= 1'b1;
    end
  end
endmodule
