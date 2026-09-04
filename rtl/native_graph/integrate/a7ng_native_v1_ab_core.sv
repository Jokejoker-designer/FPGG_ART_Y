// a7ng_native_v1_ab_core.sv — Project C A+B acceptance candidate
// Live frozen SOA/MIG producer -> 4th global merge -> accepted bind -> TinyGPT
// No oracle constants. Bind GID is not a TB port.
`timescale 1ns / 1ps

module a7ng_native_v1_ab_core #(
  parameter bit SIM_FULL = 1'b1,
  parameter int unsigned WAVE = 16,
  parameter int unsigned MAX_CANDS = 64,
  parameter int unsigned PHYS = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_query_i,
  input  logic         do_lm_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  input  logic         cons_ready_i,
  input  logic [63:0]  q_query_cue_i,
  input  logic [63:0]  q_intent_cue_i,
  input  logic [63:0]  q_relation_cue_i,
  input  logic [63:0]  q_context_cue_i,
  input  logic [63:0]  q_path_cue_i,
  input  logic         poison_i,
  input  a7ng_pkg::node_id_t poison_id_i [8],
  input  logic         mem_we,
  input  logic [19:0]  mem_addr,
  input  logic signed [7:0] mem_wdata,
  output logic signed [7:0] mem_rdata,
  output logic         soa_done_o,
  output logic         soa_running_o,
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  soa_id_beats_o,
  output logic [31:0]  soa_cue_beats_o,
  output logic [31:0]  soa_prior_beats_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  cand_delivered_o,
  output logic [31:0]  topk_batches_o,
  output logic         topk_valid_o,
  output a7ng_pkg::score_t   topk_score_o [8],
  output a7ng_pkg::node_id_t topk_id_o    [8],
  output logic [31:0]  gv_count_o,
  output logic         grant_graph_o,
  output logic         grant_lm_o,
  output logic         dual_owner_err_o,
  output logic         bind_busy_o,
  output logic         bind_done_o,
  output logic         ctx_we_o,
  output logic [63:0]  ctx_pack_o,     // diagnostic 8-bit pack into frozen LM
  output logic [159:0] ctx_pack20_o,   // live >=20-bit LM-context IDs
  output logic         start_fwd_o,
  output logic         capture_valid_o,
  output logic [31:0]  ctx_we_beats_o,
  output logic [31:0]  start_fwd_beats_o,
  output logic         core_busy_o,
  output logic         core_done_o,
  output logic [9:0]   pred_o,
  output logic [7:0]   phase_o,
  output logic         w_stall_o, // F1n probe: tiny_gpt803k tile stall
  output logic         dbg_tile_miss_o, // F1o probe: weight_tile803k miss
  output logic [3:0]   dbg_tile_bst_o,
  output logic [2:0]   dbg_tile_dst_o,
  output logic         dbg_tile_req_s1_o, // F1q: req_s[1] at D_IDLE gate
  output logic         final_accept_o,
  output logic [3:0]   m_axi_arid,
  output logic [27:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [3:0]   m_axi_rid,
  input  logic [127:0] m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready,
  output logic         owner_ready_o,
  output logic         global_topk_busy_o,
  output logic         r_path_idle_o,
  input  logic         clk_dma = 1'b0,
  input  logic         rst_dma_n = 1'b1,
  output logic         wdma_owner,
  output logic         wdma_go,
  output logic         wdma_wr,
  output logic [27:0]  wdma_addr,
  output logic [31:0]  wdma_bytes,
  input  logic         wdma_busy = 1'b0,
  input  logic         wdma_done = 1'b0,
  output logic         wdma_w_valid,
  input  logic         wdma_w_ready = 1'b0,
  output logic [127:0] wdma_w_data,
  input  logic         wdma_r_valid = 1'b0,
  output logic         wdma_r_ready,
  input  logic [127:0] wdma_r_data = 128'd0,
  output logic [3:0]   c1_mode_o,
  output logic [63:0]  c2_anch_o,
  output logic [63:0]  c9_cframe_o,    // diagnostic 8-bit C9 UART
  output logic [159:0] c9_id20_o,      // live >=20-bit C9 observe
  output logic         c10_lmst_o,
  output logic         c10_lmdn_o,
  output logic [9:0]   c10_out_o,
  output logic         persist_ddr_req_o,
  output logic         persist_ddr_we_o,
  output logic [7:0]   persist_ddr_addr_o,
  output logic [63:0]  persist_ddr_wdata_o,
  input  logic [63:0]  persist_ddr_rdata_i = 64'd0,
  input  logic         persist_ddr_ack_i = 1'b0,
  output logic         persist_freeze_o,
  output logic         persist_c7_valid_o,
  output logic [31:0]  persist_c7_addr_o,
  input  logic         persist_c7_ready_i = 1'b1,
  output logic         persist_busy_o,
  input  logic         g14_en_i = 1'b0,
  input  logic         g14_cmd_v_i = 1'b0,
  output logic         g14_cmd_r_o,
  input  logic [3:0]   g14_cmd_i = 4'd0,
  input  logic [7:0]   g14_tok_i = 8'd0,
  input  logic signed [3:0] g14_rew_i = 4'sd0,
  output logic [31:0]  c8_gen_o,
  output logic [63:0]  c8_sdig_o,
  output logic [63:0]  c11_adig_o,
  output logic [63:0]  c11_bdig_o,
  output logic         c11_a_for_o,
  output logic         c11_b_vis_o,
  output logic [15:0]  n_host_cue_o,
  output logic [15:0]  n_host_win_o,
  output logic [15:0]  n_host_addr_o,
  output logic [15:0]  n_host_tok_o,
  output logic [15:0]  n_host_w_o,
  output logic         teacher_active_o,
  output logic         ext_llm_active_o,
  output logic [15:0]  p_txn_o,
  output logic         c5_cons_o,
  output logic [127:0] c9_score_o,
  output logic [31:0]  c9_r1s_o,
  output logic [7:0]   c9_r1r_o,
  output logic [31:0]  c9_r1o_o,
  output logic [2:0]   last_ack_o
);
  import a7ng_pkg::*;

  logic req_graph, req_lm, merge_done;
  a7ng_lm_graph_arb u_arb (
    .clk(clk), .rst_n(rst_n),
    .req_graph_i(req_graph), .req_lm_i(req_lm),
    .grant_graph_o(grant_graph_o), .grant_lm_o(grant_lm_o),
    .owner_is_graph_o(), .owner_is_lm_o(),
    .dual_owner_err_o(dual_owner_err_o)
  );

  a7ng_cue_soa_mig_top #(
    .WAVE(WAVE), .MAX_CANDS(MAX_CANDS), .MAX_OUT(8), .MAX_BURST(16), .PHYS(PHYS)
  ) u_soa (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_query_i), .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_node_i(base_node_i), .total_recs_i(total_recs_i),
    .cons_ready_i(cons_ready_i),
    .q_query_cue_i(q_query_cue_i), .q_intent_cue_i(q_intent_cue_i),
    .q_relation_cue_i(q_relation_cue_i), .q_context_cue_i(q_context_cue_i),
    .q_path_cue_i(q_path_cue_i),
    .done_o(soa_done_o), .running_o(soa_running_o),
    .cycles_o(), .waves_o(waves_o), .cand_delivered_o(cand_delivered_o),
    .data_mismatch_o(), .swap_count_o(),
    .buffer_empty_stall_o(), .buffer_full_stall_o(),
    .soa_id_beats_o(soa_id_beats_o), .soa_cue_beats_o(soa_cue_beats_o),
    .soa_prior_beats_o(soa_prior_beats_o),
    .bytes_id_o(), .bytes_cue_o(), .bytes_prior_o(), .bytes_total_o(),
    .axi_read_bytes_o(axi_read_bytes_o), .axi_read_bursts_o(axi_read_bursts_o),
    .axi_read_beats_o(axi_read_beats_o),
    .expected_records_o(), .received_records_o(),
    .rresp_error_count_o(), .rlast_error_count_o(),
    .rid_order_error_o(), .r_backpressure_cycles_o(),
    .topk_batches_o(topk_batches_o), .topk_valid_o(topk_valid_o),
    .topk_score_o(topk_score_o), .topk_id_o(topk_id_o),
    .merge_done_o(merge_done),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
    .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .owner_ready_o(owner_ready_o),
    .r_path_idle_o(r_path_idle_o),
    .global_topk_busy_o(global_topk_busy_o)
  );

  node_id_t bind_gid [0:7];
  node_id_t g14_persist_id [8];
  node_id_t g14_persist_lat [0:7];
  integer pi;
  logic pending, start_pulse;
  logic [31:0] gv_cnt;
  logic g14_lm_start, g14_lm_hold;
  always_comb begin
    for (pi = 0; pi < 8; pi = pi + 1) begin
      if (poison_i)
        bind_gid[pi] = poison_id_i[pi];
      else if (g14_en_i && (g14_lm_start || g14_lm_hold))
        // Gate14 exam bind = learned graph TopK (C9), not persist FAST IDs
        // and not leftover existence SoA pack.
        bind_gid[pi] = g14_lm_start ? g14_persist_id[pi] : g14_persist_lat[pi];
      else
        bind_gid[pi] = topk_id_o[pi];
    end
  end
  assign gv_count_o     = gv_cnt;
  assign final_accept_o = start_pulse;

  always_comb begin
    // Exam LM must not lose the arbiter to a leftover graph request
    // (graph wins ties). Existence query already finished before UART exam.
    req_graph = (soa_running_o || (!soa_done_o && !pending))
                && !(g14_en_i && (g14_lm_start || g14_lm_hold));
    // Hold LM through the 1-cycle hole: pending clears with start_pulse
    // while bind is still IDLE (busy=0). R3/R4: pack latched, ctx_we never
    // asserted because arb dropped grant before S_CTX.
    req_lm    = pending || start_pulse || bind_busy_o || core_busy_o
                || (g14_en_i && (g14_lm_start || g14_lm_hold));
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending     <= 1'b0;
      start_pulse <= 1'b0;
      gv_cnt      <= 32'd0;
      g14_lm_hold <= 1'b0;
      for (pi = 0; pi < 8; pi = pi + 1)
        g14_persist_lat[pi] <= '0;
    end else begin
      start_pulse <= 1'b0;
      if (start_query_i)
        gv_cnt <= 32'd0;
      else if (merge_done)
        gv_cnt <= gv_cnt + 32'd1;
      if (merge_done && ((gv_cnt + 32'd1) == 32'd4))
        pending <= 1'b1;
      if (pending && grant_lm_o && do_lm_i && !core_busy_o && !bind_busy_o) begin
        start_pulse <= 1'b1;
        pending     <= 1'b0;
      end
      if (g14_en_i && g14_lm_start) begin
        g14_lm_hold <= 1'b1;
        for (pi = 0; pi < 8; pi = pi + 1)
          g14_persist_lat[pi] <= g14_persist_id[pi];
      end else if (bind_busy_o || bind_done_o)
        g14_lm_hold <= 1'b0;
    end
  end

  logic [6:0] ctx_idx, ctx_n;
  logic [9:0] bind_pred;
  logic core_done;

  a7ng_native_ctx_bind u_bind (
    .clk(clk), .rst_n(rst_n),
    .grant_lm_i(grant_lm_o),
    .start_i(start_pulse || (g14_en_i && (g14_lm_start || (g14_lm_hold && grant_lm_o)))),
    .do_start_i(do_lm_i),
    .global_id_i(bind_gid),
    .core_busy_i(core_busy_o),
    .core_done_i(core_done),
    .core_pred_i(pred_o),
    .busy_o(bind_busy_o),
    .done_o(bind_done_o),
    .ctx_we_o(ctx_we_o),
    .ctx_idx_o(ctx_idx),
    .ctx_n_in_o(ctx_n),
    .ctx_pack_o(ctx_pack_o),
    .ctx_pack20_o(ctx_pack20_o),
    .start_fwd_o(start_fwd_o),
    .pred_o(bind_pred),
    .ctx_we_beats_o(ctx_we_beats_o),
    .start_fwd_beats_o(start_fwd_beats_o),
    .capture_valid_o(capture_valid_o)
  );

  tiny_gpt803k_core #(.SIM_FULL(SIM_FULL)) u_core (
    .clk(clk), .rst_n(rst_n),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .ctx_we(ctx_we_o), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n), .ctx_pack(ctx_pack_o),
    .start_fwd(start_fwd_o),
    .start_train(1'b0), .start_ce(1'b0), .start_corpus(1'b0),
    .after_mode(1'b0), .do_snap(1'b0), .do_restore(1'b0), .do_fold(1'b0),
    .tgt_in(10'd0), .lr_in(4'd0), .corpus_n(8'd0), .corpus_ep(8'd0),
    .busy(core_busy_o), .done(core_done), .pred(pred_o),
    .last_loss(), .ce0(), .ce1(), .wr_n(), .xor32(), .add32(),
    .phase(phase_o), .w_stall(w_stall_o),
    .clk_dma(clk_dma), .rst_dma_n(rst_dma_n),
    .wdma_owner(wdma_owner), .wdma_go(wdma_go), .wdma_wr(wdma_wr),
    .wdma_addr(wdma_addr), .wdma_bytes(wdma_bytes),
    .wdma_busy(wdma_busy), .wdma_done(wdma_done),
    .wdma_w_valid(wdma_w_valid), .wdma_w_ready(wdma_w_ready), .wdma_w_data(wdma_w_data),
    .wdma_r_valid(wdma_r_valid), .wdma_r_ready(wdma_r_ready), .wdma_r_data(wdma_r_data),
    .dbg_tile_bst(dbg_tile_bst_o), .dbg_tile_dst(dbg_tile_dst_o), .dbg_tile_rg(),
    .dbg_tile_miss(dbg_tile_miss_o), .dbg_tile_dirty(), .dbg_tile_req(),
    .dbg_tile_req_s1(dbg_tile_req_s1_o)
  );
  assign core_done_o = core_done;

  a7ng_g1g5_cofit u_g1g5 (
    .clk(clk), .rst_n(rst_n),
    .graph_topk_valid_i(topk_valid_o),
    .graph_id_i(topk_id_o),
    .graph_sc_i(topk_score_o),
    .graph_bind_done_i(bind_done_o),
    .graph_lm_busy_i(core_busy_o || bind_busy_o),
    .graph_pred_i(pred_o),
    .c1_mode_o(c1_mode_o),
    .c2_anch_o(c2_anch_o),
    .c9_topk_o(c9_cframe_o),
    .c9_id20_o(c9_id20_o),
    .c10_lmst_o(c10_lmst_o),
    .c10_lmdn_o(c10_lmdn_o),
    .c10_out_o(c10_out_o),
    .n_host_cue_o(n_host_cue_o), .n_host_win_o(n_host_win_o),
    .n_host_addr_o(n_host_addr_o), .n_host_tok_o(n_host_tok_o),
    .n_host_w_o(n_host_w_o), .n_host_mode_o(),
    .teacher_active_o(teacher_active_o), .ext_llm_active_o(ext_llm_active_o),
    .exam_lm_used_o(),
    .persist_ddr_req_o(persist_ddr_req_o),
    .persist_ddr_we_o(persist_ddr_we_o),
    .persist_ddr_addr_o(persist_ddr_addr_o),
    .persist_ddr_wdata_o(persist_ddr_wdata_o),
    .persist_ddr_rdata_i(persist_ddr_rdata_i),
    .persist_ddr_ack_i(persist_ddr_ack_i),
    .persist_freeze_o(persist_freeze_o),
    .persist_c7_valid_o(persist_c7_valid_o),
    .persist_c7_addr_o(persist_c7_addr_o),
    .persist_c7_ready_i(persist_c7_ready_i),
    .persist_busy_o(persist_busy_o),
    .persist_done_o(),
    .c7_commit_seq_o(), .c7_ack_count_o(),
    .query_valid_o(), .query_ready_o(), .query_id_o(), .snap_valid_o(),
    .g14_en_i(g14_en_i),
    .g14_cmd_v_i(g14_cmd_v_i),
    .g14_cmd_r_o(g14_cmd_r_o),
    .g14_cmd_i(g14_cmd_i),
    .g14_tok_i(g14_tok_i),
    .g14_rew_i(g14_rew_i),
    .c8_gen_o(c8_gen_o),
    .c8_sdig_o(c8_sdig_o),
    .c11_adig_o(c11_adig_o),
    .c11_bdig_o(c11_bdig_o),
    .c11_a_for_o(c11_a_for_o),
    .c11_b_vis_o(c11_b_vis_o),
    .p_txn_o(p_txn_o),
    .c5_cons_o(c5_cons_o),
    .g14_lm_start_o(g14_lm_start),
    .g14_persist_id_o(g14_persist_id),
    .c9_score_o(c9_score_o),
    .c9_r1s_o(c9_r1s_o),
    .c9_r1r_o(c9_r1r_o),
    .c9_r1o_o(c9_r1o_o),
    .last_ack_o(last_ack_o)
  );
endmodule

