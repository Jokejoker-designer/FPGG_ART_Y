// a7ng_teacher_off_soc_xsim.sv — P2-TEACHER-OFF-SOC-XSIM-00
// Same instance: persist G4 + glue + native_ctx_bind + frozen tiny_gpt803k SIM_FULL=1.
// No stub. PROGRAM=NO. Fast/no-MIG.
`timescale 1ns / 1ps

module a7ng_teacher_off_soc_xsim (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         cmd_valid_i,
  output logic         cmd_ready_o,
  input  logic [3:0]   cmd_i,
  input  logic [7:0]   tok_i,
  input  logic signed [3:0] reward_i,
  // INIT-only LM-06 image load (exam: mem_we must stay 0)
  input  logic         mem_we_i,
  input  logic [19:0]  mem_addr_i,
  input  logic signed [7:0] mem_wdata_i,
  output logic signed [7:0] mem_rdata_o,
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
  output a7ng_pkg::node_id_t topk_id_o [8],
  output a7ng_pkg::score_t   topk_sc_o [8],
  output logic [15:0]  p_txn_o,
  output logic         c5_cons_o,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  output logic [31:0]  c7_addr_o,
  output logic         c7_v_o,
  output logic         persist_busy_o,
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
  logic [15:0] p_txn, p_echo;
  logic signed [3:0] p_rew;
  logic [2:0] p_ack;
  logic p_flush, p_reload, p_kill, p_trst, p_wimm, p_busy, p_done;
  logic ddr_req, ddr_we, ddr_ack;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, c8d;
  logic [31:0] c8g;
  logic [7:0] digc;
  logic [63:0] ddr_mem [0:31];

  logic lm_start, lm_busy, lm_done, bind_busy, bind_done;
  logic ctx_we, start_fwd, core_busy, core_done, capture_v;
  logic [6:0] ctx_idx, ctx_n;
  logic [63:0] ctx_pack;
  logic [9:0] core_pred, bind_pred;
  logic [31:0] ctx_beats, st_beats;
  integer di;

  assign topk_id_o = p_id;
  assign topk_sc_o = p_sc;
  assign p_txn_o = p_txn;
  assign c5_cons_o = p_c5;
  assign c8_gen_o = c8g;
  assign c8_sdig_o = c8d;
  assign c7_addr_o = p_c7a;
  assign c7_v_o = p_c7v;
  assign persist_busy_o = p_busy;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  initial begin
    for (di = 0; di < 32; di = di + 1)
      ddr_mem[di] = 64'd0;
  end

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
    .c7_ack_valid_o(p_c7v), .c7_ack_ready_i(1'b1), .c7_addr_o(p_c7a),
    .c8_gen_o(c8g), .c8_sdig_o(c8d), .dig_cyc_o(digc),
    .flush_i(p_flush), .reload_i(p_reload), .bram_kill_i(p_kill),
    .train_reset_i(p_trst), .wrap_imminent_o(p_wimm),
    .persist_busy_o(p_busy), .persist_done_o(p_done),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_teacher_off_glue u_glue (
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
    .lm_start_o(lm_start), .lm_busy_i(bind_busy),
    .lm_done_i(bind_done), .lm_pred_i(bind_pred),
    .c1_mode_o(c1_mode_o), .c2_anch_o(c2_anch_o),
    .c9_topk_o(c9_topk_o), .c9_score_o(c9_score_o),
    .c9_r1s_o(c9_r1s_o), .c9_r1r_o(c9_r1r_o), .c9_r1o_o(c9_r1o_o),
    .c10_lmst_o(c10_lmst_o), .c10_lmdn_o(c10_lmdn_o), .c10_out_o(c10_out_o),
    .n_host_cue_o(n_host_cue_o), .n_host_win_o(n_host_win_o),
    .n_host_addr_o(n_host_addr_o), .n_host_tok_o(n_host_tok_o),
    .n_host_w_o(n_host_w_o), .n_host_mode_o(n_host_mode_o),
    .last_ack_o(last_ack_o), .exam_lm_used_o(exam_lm_used_o)
  );

  a7ng_native_ctx_bind u_bind (
    .clk(clk), .rst_n(rst_n),
    .grant_lm_i(1'b1),
    .start_i(lm_start),
    .do_start_i(1'b1),
    .global_id_i(p_id),
    .core_busy_i(core_busy),
    .core_done_i(core_done),
    .core_pred_i(core_pred),
    .busy_o(bind_busy),
    .done_o(bind_done),
    .ctx_we_o(ctx_we),
    .ctx_idx_o(ctx_idx),
    .ctx_n_in_o(ctx_n),
    .ctx_pack_o(ctx_pack),
    .start_fwd_o(start_fwd),
    .pred_o(bind_pred),
    .ctx_we_beats_o(ctx_beats),
    .start_fwd_beats_o(st_beats),
    .capture_valid_o(capture_v)
  );

  tiny_gpt803k_core #(.SIM_FULL(1'b1)) u_lm06 (
    .clk(clk), .rst_n(rst_n),
    .mem_we(mem_we_i), .mem_addr(mem_addr_i), .mem_wdata(mem_wdata_i),
    .mem_rdata(mem_rdata_o),
    .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n), .ctx_pack(ctx_pack),
    .start_fwd(start_fwd),
    .start_train(1'b0), .start_ce(1'b0), .start_corpus(1'b0),
    .after_mode(1'b0), .do_snap(1'b0), .do_restore(1'b0), .do_fold(1'b0),
    .tgt_in(10'd0), .lr_in(4'd0), .corpus_n(8'd0), .corpus_ep(8'd0),
    .busy(core_busy), .done(core_done), .pred(core_pred),
    .last_loss(), .ce0(), .ce1(), .wr_n(), .xor32(), .add32(),
    .phase(), .w_stall(),
    .clk_dma(1'b0), .rst_dma_n(1'b1),
    .wdma_owner(), .wdma_go(), .wdma_wr(), .wdma_addr(), .wdma_bytes(),
    .wdma_busy(1'b0), .wdma_done(1'b0),
    .wdma_w_valid(), .wdma_w_ready(1'b0), .wdma_w_data(),
    .wdma_r_valid(1'b0), .wdma_r_ready(), .wdma_r_data(128'd0),
    .dbg_tile_bst(), .dbg_tile_dst(), .dbg_tile_rg(),
    .dbg_tile_miss(), .dbg_tile_dirty(), .dbg_tile_req(), .dbg_tile_req_s1()
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
