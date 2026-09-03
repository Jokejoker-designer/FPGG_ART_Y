// a7ng_gate14_c9_soc_cofit_xsim.sv — P2-GATE14-C9-SOC-COFIT-BIT-06
// Integration XSim of SoC cofit (learned graph + c9_glue) + existing bind + TinyGPT.
// C9/bind = learned TopK. No persist FAST-ID. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_gate14_c9_soc_cofit_xsim (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         cmd_valid_i,
  output logic         cmd_ready_o,
  input  logic [3:0]   cmd_i,
  input  logic [7:0]   tok_i,
  input  logic signed [3:0] reward_i,
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
  output logic [15:0]  c7_commit_seq_o,
  output logic [15:0]  c7_ack_count_o,
  output logic         persist_busy_o,
  output logic         persist_done_o,
  output logic         query_valid_o,
  output logic         query_ready_o,
  output logic [7:0]   query_id_o,
  output logic         snap_valid_o,
  output logic         ctx_we_obs_o,
  output logic [6:0]   ctx_idx_obs_o,
  output logic [6:0]   ctx_n_obs_o,
  output logic [63:0]  ctx_pack_obs_o,
  output logic [63:0]  c11_adig_o,
  output logic [63:0]  c11_bdig_o,
  output logic         c11_a_for_o,
  output logic         c11_b_vis_o
);
  import a7ng_pkg::*;

  node_id_t p_id [8];
  node_id_t zero_id [8];
  score_t   zero_sc [8];
  logic [31:0] p_c7a;
  logic p_c7v, p_busy, p_done, p_c5;
  logic [15:0] p_txn, c7seq, c7cnt;
  logic [63:0] c8d, c9p;
  logic [31:0] c8g;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:255];
  logic cr_int;
  logic lm_start, bind_busy, bind_done, ctx_we, start_fwd, core_busy, core_done, capture_v;
  logic [6:0] ctx_idx, ctx_n;
  logic [63:0] ctx_pack;
  logic [9:0] core_pred, bind_pred;
  logic [31:0] ctx_beats, st_beats;
  integer di, zi;

  assign topk_id_o = p_id;
  integer ski;
  always_comb begin
    for (ski = 0; ski < 8; ski = ski + 1)
      topk_sc_o[ski] = c9_score_o[16*ski +: 16];
  end
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
  assign ctx_we_obs_o = ctx_we;
  assign ctx_idx_obs_o = ctx_idx;
  assign ctx_n_obs_o = ctx_n;
  assign ctx_pack_obs_o = ctx_pack;
  assign cmd_ready_o = cr_int;

  always_comb begin
    for (zi = 0; zi < 8; zi = zi + 1) begin
      zero_id[zi] = '0;
      zero_sc[zi] = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  initial begin
    for (di = 0; di < 256; di = di + 1)
      ddr_mem[di] = 64'd0;
  end

  a7ng_g1g5_cofit u_cofit (
    .clk(clk), .rst_n(rst_n),
    .graph_topk_valid_i(1'b0),
    .graph_id_i(zero_id), .graph_sc_i(zero_sc),
    .graph_bind_done_i(bind_done),
    .graph_lm_busy_i(core_busy || bind_busy),
    .graph_pred_i(bind_pred),
    .c1_mode_o(c1_mode_o), .c2_anch_o(c2_anch_o),
    .c9_topk_o(c9_topk_o), .c9_score_o(c9_score_o),
    .c9_r1s_o(c9_r1s_o), .c9_r1r_o(c9_r1r_o), .c9_r1o_o(c9_r1o_o),
    .c10_lmst_o(c10_lmst_o), .c10_lmdn_o(c10_lmdn_o), .c10_out_o(c10_out_o),
    .n_host_cue_o(n_host_cue_o), .n_host_win_o(n_host_win_o),
    .n_host_addr_o(n_host_addr_o), .n_host_tok_o(n_host_tok_o),
    .n_host_w_o(n_host_w_o), .n_host_mode_o(n_host_mode_o),
    .last_ack_o(last_ack_o), .exam_lm_used_o(exam_lm_used_o),
    .persist_ddr_req_o(ddr_req), .persist_ddr_we_o(ddr_we),
    .persist_ddr_addr_o(ddr_addr), .persist_ddr_wdata_o(ddr_wdata),
    .persist_ddr_rdata_i(ddr_rdata), .persist_ddr_ack_i(ddr_ack),
    .persist_freeze_o(),
    .persist_c7_valid_o(p_c7v), .persist_c7_addr_o(p_c7a),
    .persist_c7_ready_i(1'b1),
    .persist_busy_o(p_busy), .persist_done_o(p_done),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .query_valid_o(query_valid_o), .query_ready_o(query_ready_o),
    .query_id_o(query_id_o), .snap_valid_o(snap_valid_o),
    .g14_en_i(1'b1),
    .g14_cmd_v_i(cmd_valid_i), .g14_cmd_r_o(cr_int),
    .g14_cmd_i(cmd_i), .g14_tok_i(tok_i), .g14_rew_i(reward_i),
    .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .c11_adig_o(c11_adig_o), .c11_bdig_o(c11_bdig_o),
    .c11_a_for_o(c11_a_for_o), .c11_b_vis_o(c11_b_vis_o),
    .p_txn_o(p_txn), .c5_cons_o(p_c5),
    .g14_lm_start_o(lm_start),
    .g14_persist_id_o(p_id)
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
endmodule
