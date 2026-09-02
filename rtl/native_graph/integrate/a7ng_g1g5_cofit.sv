// a7ng_g1g5_cofit.sv — P2-G1G5-FULLCHIP-COFIT-00
// Instantiates unmodified G1/G2 (inside G4 persist) + G4 persist backend + G5 glue.
// Does NOT instantiate TinyGPT, causal_learn_fast, or a second TopK.
// Graph minheap TopK and one LN-FIX TinyGPT stay in a7ng_native_v1_ab_core.
// Persist DDR is exported to AXI/MIG bridge (no LUTRAM mock). PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_g1g5_cofit (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         graph_topk_valid_i,
  input  a7ng_pkg::node_id_t graph_id_i [8],
  input  a7ng_pkg::score_t   graph_sc_i [8],
  input  logic         graph_bind_done_i,
  input  logic         graph_lm_busy_i,
  input  logic [9:0]   graph_pred_i,
  output logic [3:0]   c1_mode_o,
  output logic [63:0]  c2_anch_o,
  output logic [63:0]  c9_topk_o,
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
  output logic         persist_ddr_req_o,
  output logic         persist_ddr_we_o,
  output logic [4:0]   persist_ddr_addr_o,
  output logic [63:0]  persist_ddr_wdata_o,
  input  logic [63:0]  persist_ddr_rdata_i,
  input  logic         persist_ddr_ack_i,
  output logic         persist_freeze_o,
  output logic         persist_c7_valid_o,
  output logic [31:0]  persist_c7_addr_o,
  input  logic         persist_c7_ready_i,
  output logic         persist_busy_o,
  // Gate14 UART command (optional). When g14_en_i, auto-freeze is off.
  input  logic         g14_en_i,
  input  logic         g14_cmd_v_i,
  output logic         g14_cmd_r_o,
  input  logic [3:0]   g14_cmd_i,
  input  logic [7:0]   g14_tok_i,
  input  logic signed [3:0] g14_rew_i,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  output logic [63:0]  c11_adig_o,
  output logic [63:0]  c11_bdig_o,
  output logic         c11_a_for_o,
  output logic         c11_b_vis_o,
  output logic [15:0]  p_txn_o,
  output logic         c5_cons_o
);
  import a7ng_pkg::*;

  localparam logic [3:0] C_FREEZE = 4'd7;

  logic p_learn, p_freeze, p_qv, p_qr, p_sv, p_sr;
  logic [7:0] p_qid;
  node_id_t p_id [8];
  score_t   p_sc [8];
  logic [31:0] p_evs, p_evo, p_c7a;
  logic [7:0] p_evr;
  logic p_pend, p_rewv, p_echov, p_rewrdy, p_ackv, p_c5, p_c7v;
  logic [15:0] p_txn, p_echo;
  logic signed [3:0] p_rew;
  logic [2:0] p_ack;
  logic p_flush, p_reload, p_kill, p_trst, p_wimm, p_busy, p_done;
  logic ddr_req, ddr_we, ddr_ack;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, c8d;
  logic [31:0] c8g;
  logic [7:0] digc;
  integer ki;

  logic cv, cr;
  logic [3:0] cmd;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic lm_start, g_lmst, g_lmdn;
  logic [9:0] g_out;
  logic [3:0] mode_g;
  logic froze;
  logic [7:0] boot_wait;

  logic [63:0] pack_graph;
  logic [127:0] sc_graph;

  always_comb begin
    pack_graph = 64'd0;
    sc_graph   = 128'd0;
    for (ki = 0; ki < 8; ki = ki + 1) begin
      pack_graph[8*ki +: 8]   = graph_id_i[ki][7:0];
      sc_graph[16*ki +: 16]   = graph_sc_i[ki];
    end
  end

  assign persist_ddr_req_o   = ddr_req;
  assign persist_ddr_we_o    = ddr_we;
  assign persist_ddr_addr_o  = ddr_addr;
  assign persist_ddr_wdata_o = ddr_wdata;
  assign ddr_rdata           = persist_ddr_rdata_i;
  assign ddr_ack             = persist_ddr_ack_i;
  assign persist_freeze_o    = p_freeze;
  assign persist_c7_valid_o  = p_c7v;
  assign persist_c7_addr_o   = p_c7a;
  assign persist_busy_o      = p_busy;
  assign c8_gen_o            = c8g;
  assign c8_sdig_o           = c8d;
  assign p_txn_o             = p_txn;
  assign c5_cons_o           = p_c5;
  assign g14_cmd_r_o         = g14_en_i ? cr : 1'b0;

  a7ng_persist_gen_fast #(.WRAP_LIMIT(32'd6)) u_persist (
    .clk(clk), .rst_n(rst_n), .learn_i(p_learn), .freeze_i(p_freeze),
    .query_valid_i(p_qv), .query_ready_o(p_qr), .query_id_i(p_qid),
    .snap_valid_o(p_sv), .snap_ready_i(p_sr),
    .topk_id_o(p_id), .topk_score_o(p_sc),
    .ev_subj_o(p_evs), .ev_rel_o(p_evr), .ev_obj_o(p_evo),
    .pending_o(p_pend), .txn_o(p_txn),
    .reward_valid_i(p_rewv), .reward_i(p_rew),
    .txn_echo_valid_i(p_echov), .txn_echo_i(p_echo),
    .reward_ready_o(p_rewrdy),
    .ack_valid_o(p_ackv), .ack_o(p_ack),
    .c5_consume_o(p_c5),
    .c7_ack_valid_o(p_c7v), .c7_ack_ready_i(persist_c7_ready_i), .c7_addr_o(p_c7a),
    .c8_gen_o(c8g), .c8_sdig_o(c8d), .dig_cyc_o(digc),
    .flush_i(p_flush), .reload_i(p_reload), .bram_kill_i(p_kill),
    .train_reset_i(p_trst), .wrap_imminent_o(p_wimm),
    .persist_busy_o(p_busy), .persist_done_o(p_done),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_teacher_off_glue u_glue (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(g14_en_i ? g14_cmd_v_i : cv),
    .cmd_ready_o(cr),
    .cmd_i(g14_en_i ? g14_cmd_i : cmd),
    .tok_i(g14_en_i ? g14_tok_i : tok),
    .reward_i(g14_en_i ? g14_rew_i : rew),
    .host_cue_i(64'd0), .host_winner_i(32'd0), .host_addr_i(32'd0),
    .host_next_i(10'd0), .host_wren_i(1'b0), .host_mode_i(4'd0),
    .p_learn_o(p_learn), .p_freeze_o(p_freeze),
    .p_qvalid_o(p_qv), .p_qready_i(p_qr), .p_qid_o(p_qid),
    .p_snap_v_i(p_sv), .p_snap_r_o(p_sr),
    .p_topk_id_i(graph_id_i), .p_topk_sc_i(graph_sc_i),
    .p_evs_i(p_evs), .p_evr_i(p_evr), .p_evo_i(p_evo),
    .p_pending_i(p_pend), .p_txn_i(p_txn),
    .p_rew_v_o(p_rewv), .p_rew_o(p_rew),
    .p_echo_v_o(p_echov), .p_echo_o(p_echo),
    .p_ack_v_i(p_ackv), .p_ack_i(p_ack), .p_c7_i(p_c7v && persist_c7_ready_i),
    .p_flush_o(p_flush), .p_reload_o(p_reload),
    .p_kill_o(p_kill), .p_trst_o(p_trst), .p_busy_i(p_busy),
    .lm_start_o(lm_start), .lm_busy_i(graph_lm_busy_i),
    .lm_done_i(graph_bind_done_i), .lm_pred_i(graph_pred_i),
    .c1_mode_o(mode_g), .c2_anch_o(c2_anch_o),
    .c9_topk_o(), .c9_score_o(),
    .c9_r1s_o(c9_r1s_o), .c9_r1r_o(c9_r1r_o), .c9_r1o_o(c9_r1o_o),
    .c10_lmst_o(g_lmst), .c10_lmdn_o(g_lmdn), .c10_out_o(g_out),
    .n_host_cue_o(n_host_cue_o), .n_host_win_o(n_host_win_o),
    .n_host_addr_o(n_host_addr_o), .n_host_tok_o(n_host_tok_o),
    .n_host_w_o(n_host_w_o), .n_host_mode_o(n_host_mode_o),
    .last_ack_o(last_ack_o), .exam_lm_used_o(exam_lm_used_o)
  );

  // C9 is graph minheap pack, not persist's 16-cand FAST scorer.
  assign c9_topk_o  = pack_graph;
  assign c9_score_o = sc_graph;
  assign c1_mode_o  = mode_g;
  // C10 follows graph bind/pred (one TinyGPT). Glue C10 stays for G5 FIRE path.
  assign c10_lmst_o = graph_topk_valid_i | g_lmst;
  assign c10_lmdn_o = graph_bind_done_i | g_lmdn;
  assign c10_out_o  = graph_bind_done_i ? graph_pred_i : g_out;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cv <= 1'b0; cmd <= 4'd0; tok <= 8'd0; rew <= 4'sd0;
      froze <= 1'b0; boot_wait <= 8'd0;
      c11_adig_o <= 64'd0; c11_bdig_o <= 64'd0;
      c11_a_for_o <= 1'b0; c11_b_vis_o <= 1'b0;
    end else begin
      cv <= 1'b0;
      if (g14_en_i) begin
        if (g14_cmd_v_i && cr && g14_cmd_i == C_FREEZE) begin
          if (!c11_b_vis_o && !c11_a_for_o) c11_adig_o <= c8d;
          else begin c11_bdig_o <= c8d; c11_b_vis_o <= 1'b1; end
        end
        if (g14_cmd_v_i && cr && g14_cmd_i == 4'd8)
          c11_a_for_o <= 1'b1;
      end else if (!froze && cr && !p_busy) begin
        if (boot_wait != 8'hFF)
          boot_wait <= boot_wait + 8'd1;
        if (p_done || (boot_wait == 8'hFE)) begin
          cmd <= C_FREEZE; tok <= 8'd0; rew <= 4'sd0; cv <= 1'b1;
          froze <= 1'b1;
        end
      end
    end
  end
endmodule

