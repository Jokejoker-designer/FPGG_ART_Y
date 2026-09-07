// a7ng_typeclass_soc_chain.sv — P7 wrapper: prod TYPE_CLASS path + one TinyGPT.
// C02: LM-less path lives in a7ng_prod_tc_lm (shared by ab_core). PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_typeclass_soc_chain #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned K        = 8,
  parameter int unsigned MAX_NTOK = 64,
  parameter bit          SIM_FULL = 1'b1
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  input  logic        mem_we,
  input  logic [19:0] mem_addr,
  input  logic signed [7:0] mem_wdata,
  output logic signed [7:0] mem_rdata,
  output logic        qse_valid_o,
  output logic [7:0]  q_ent_o,
  output logic [7:0]  q_int_o,
  output logic [7:0]  q_rel_o,
  output logic [7:0]  q_ctx_o,
  output logic        retrieval_done_o,
  output logic [15:0] topk_class_id_o [K],
  output a7ng_pkg::node_id_t topk_id_o [K],
  output logic [15:0] n_host_or_o,
  output logic [6:0]  enc_ntok_o,
  output logic [7:0]  enc_tok_o [0:MAX_NTOK-1],
  output logic [3:0]  enc_n_rec_o,
  output logic [3:0]  enc_n_skip_o,
  output logic        ctx_we_o,
  output logic [6:0]  ctx_idx_o,
  output logic [6:0]  ctx_n_in_o,
  output logic [63:0] ctx_pack_o,
  output logic        start_fwd_o,
  output logic        core_busy_o,
  output logic        core_done_o,
  output logic [9:0]  pred_o,
  output logic        chain_busy_o,
  output logic        chain_done_o,
  output logic [31:0] ctx_we_beats_o,
  output logic [31:0] start_fwd_beats_o,
  output logic [2:0]  dbg_st_o
);
  a7ng_prod_tc_lm #(.CAND_CAP(CAND_CAP), .K(K), .MAX_NTOK(MAX_NTOK)) u_tc (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_valid_i), .tok_ready_o(tok_ready_o), .tok_i(tok_i),
    .fire_i(fire_i), .retire_i(retire_i),
    .core_busy_i(core_busy_o), .core_done_i(core_done_o), .core_pred_i(pred_o),
    .qse_valid_o(qse_valid_o),
    .q_ent_o(q_ent_o), .q_int_o(q_int_o), .q_rel_o(q_rel_o), .q_ctx_o(q_ctx_o),
    .retrieval_done_o(retrieval_done_o),
    .topk_class_id_o(topk_class_id_o), .topk_id_o(topk_id_o),
    .n_host_or_o(n_host_or_o),
    .enc_ntok_o(enc_ntok_o), .enc_tok_o(enc_tok_o),
    .enc_n_rec_o(enc_n_rec_o), .enc_n_skip_o(enc_n_skip_o),
    .ctx_we_o(ctx_we_o), .ctx_idx_o(ctx_idx_o), .ctx_n_in_o(ctx_n_in_o),
    .ctx_pack_o(ctx_pack_o), .start_fwd_o(start_fwd_o),
    .path_busy_o(chain_busy_o), .path_done_o(chain_done_o), .pred_o(),
    .ctx_we_beats_o(ctx_we_beats_o), .start_fwd_beats_o(start_fwd_beats_o),
    .dbg_st_o(dbg_st_o)
  );

  tiny_gpt803k_core #(.SIM_FULL(SIM_FULL)) u_lm06 (
    .clk(clk), .rst_n(rst_n),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .ctx_we(ctx_we_o), .ctx_idx(ctx_idx_o), .ctx_n_in(ctx_n_in_o),
    .ctx_pack(ctx_pack_o),
    .start_fwd(start_fwd_o),
    .start_train(1'b0), .start_ce(1'b0), .start_corpus(1'b0),
    .after_mode(1'b0), .do_snap(1'b0), .do_restore(1'b0), .do_fold(1'b0),
    .tgt_in(10'd0), .lr_in(4'd0), .corpus_n(8'd0), .corpus_ep(8'd0),
    .busy(core_busy_o), .done(core_done_o), .pred(pred_o),
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
