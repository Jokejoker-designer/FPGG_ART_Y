// a7ng_wavefront_mig_top.sv — ddr_wavefront_00 device under test
// Gate: ddr_wavefront_00.  Evidence class: MIG_XSIM (Digilent AXI MIG) or BOARD only.
//
//   DDR (Digilent AXI MIG)
//     -> a7ng_ddr_feed_axi_bridge   (REUSED UNCHANGED — MIG-METRIC-00 measurement law)
//     -> a7ng_cue_wavefront         (NEW: bounded ping/pong cue working set)
//     -> 16-candidate wave
//     -> a7ng_termgen_array         (EXISTING, law a7ng-termgen-v0)
//     -> a7ng_ng02_core             (EXISTING 16-lane a7ng_scorer_array
//                                    + EXISTING true global Top-8 a7ng_topk
//                                    + EXISTING a7ng_frontier_buckets)
//
// Nothing in the scoring, ranking, relation, prune, learning or LM path is modified here.
// The only new logic is delivery of a bounded working set plus per-run measurement.
`timescale 1ns / 1ps

module a7ng_wavefront_mig_top #(
  parameter int unsigned WAVE      = 16,
  parameter int unsigned MAX_OUT   = 8,
  parameter int unsigned MAX_BURST = 16
) (
  input  logic         clk,      // MIG ui_clk
  input  logic         rst_n,    // ~ui_clk_sync_rst && calib
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  input  logic         cons_ready_i,   // scheduler-side consumer pattern (ALWAYS/SPARSE/BURSTY)
  // query context broadcast to all 16 lanes (spec §11 read-only replication)
  input  logic [63:0]  q_query_cue_i,
  input  logic [63:0]  q_intent_cue_i,
  input  logic [63:0]  q_relation_cue_i,
  input  logic [63:0]  q_context_cue_i,
  input  logic [63:0]  q_path_cue_i,
  // wavefront telemetry (per-run)
  output logic         done_o,
  output logic         running_o,
  output logic [31:0]  cycles_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  cand_accepted_o,
  output logic [31:0]  cand_delivered_o,
  output logic [31:0]  cand_queued_o,
  output logic [31:0]  cand_inflight_o,
  output logic [31:0]  cand_pruned_o,
  output logic [31:0]  conserve_err_o,
  output logic [31:0]  data_mismatch_o,
  output logic [31:0]  swap_count_o,
  output logic [31:0]  buffer_empty_stall_o,
  output logic [31:0]  buffer_full_stall_o,
  output logic [31:0]  cons_ready_cycles_o,
  output logic [31:0]  fill_cycles_o,
  output logic [31:0]  fill_episodes_o,
  output logic [15:0]  occ_fill_o,
  output logic [15:0]  occ_drain_o,
  // AXI read telemetry from the reused bridge (per-run deltas)
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  axi_data_mismatch_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  expected_records_o,
  output logic [31:0]  received_records_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o,
  // consumer-side conservation + diagnostics
  output logic [31:0]  batches_accepted_o,
  output logic [31:0]  consumer_loss_o,   // wave reached consumer that could not take it
  output logic [31:0]  topk_batches_o,
  output logic [31:0]  flow_busy_cycles_o,
  output logic [31:0]  frontier_push_o,
  output logic [31:0]  frontier_overflow_o,
  output logic [7:0]   frontier_count_o,
  // wave bus + Top-8 for independent TB scoreboarding
  output logic         wave_valid_o,
  output logic [127:0] wave_rec_o [WAVE],
  output logic [31:0]  wave_base_id_o,
  output logic         topk_valid_o,
  output a7ng_pkg::score_t   topk_score_o [8],
  output a7ng_pkg::node_id_t topk_id_o    [8],
  // Digilent AXI MIG read master
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
  output logic         m_axi_rready
);
  import a7ng_pkg::*;

  logic         ar_valid, ar_ready, r_valid, r_ready, r_last;
  logic [31:0]  ar_addr;
  logic [7:0]   ar_len;
  logic [3:0]   ar_id, r_id;
  logic [127:0] r_data;

  logic         core_batch_ready;
  logic [1:0]   tg_pipe;
  logic         wf_cons_ready;

  // A wave may only be issued when the EXISTING consumer can actually take it two cycles
  // later (TermGen latency = 2). Without this the frozen ng02 input contract would silently
  // ignore lane valids and candidates would vanish — that is the failure mode under test.
  assign wf_cons_ready = cons_ready_i && core_batch_ready && (tg_pipe == 2'b00);

  logic         wave_valid;
  logic [127:0] wave_rec [WAVE];
  logic [31:0]  wave_base_id;

  a7ng_cue_wavefront #(
    .WAVE(WAVE), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_wf (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_i),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_node_i(base_node_i), .total_recs_i(total_recs_i),
    .ar_valid_o(ar_valid), .ar_ready_i(ar_ready),
    .ar_addr_o(ar_addr), .ar_len_o(ar_len), .ar_id_o(ar_id),
    .r_valid_i(r_valid), .r_ready_o(r_ready),
    .r_data_i(r_data), .r_last_i(r_last),
    .cons_ready_i(wf_cons_ready),
    .wave_valid_o(wave_valid), .wave_rec_o(wave_rec), .wave_base_id_o(wave_base_id),
    .running_o(running_o), .done_o(done_o),
    .cycles_o(cycles_o), .waves_o(waves_o),
    .cand_accepted_o(cand_accepted_o), .cand_delivered_o(cand_delivered_o),
    .cand_queued_o(cand_queued_o), .cand_inflight_o(cand_inflight_o),
    .cand_pruned_o(cand_pruned_o), .conserve_err_o(conserve_err_o),
    .data_mismatch_o(data_mismatch_o), .swap_count_o(swap_count_o),
    .buffer_empty_stall_o(buffer_empty_stall_o), .buffer_full_stall_o(buffer_full_stall_o),
    .cons_ready_cycles_o(cons_ready_cycles_o),
    .fill_cycles_o(fill_cycles_o), .fill_episodes_o(fill_episodes_o),
    .fill_bank_o(), .drain_bank_o(),
    .occ_fill_o(occ_fill_o), .occ_drain_o(occ_drain_o)
  );

  assign wave_valid_o   = wave_valid;
  assign wave_base_id_o = wave_base_id;
  always_comb begin
    for (int k = 0; k < int'(WAVE); k++)
      wave_rec_o[k] = wave_rec[k];
  end

  // Reused unmodified: node-id AR -> Digilent AXI byte address + per-run AXI deltas
  a7ng_ddr_feed_axi_bridge u_br (
    .clk(clk), .rst_n(rst_n),
    .metric_clear_i(start_i),
    .ar_valid_i(ar_valid), .ar_ready_o(ar_ready),
    .ar_addr_i(ar_addr), .ar_len_i(ar_len), .ar_id_i(ar_id),
    .r_valid_o(r_valid), .r_ready_i(r_ready),
    .r_data_o(r_data), .r_last_o(r_last), .r_id_o(r_id),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .ddr_rd_bytes_o(), .ddr_rd_count_o(), .ddr_burst_count_o(),
    .axi_read_bytes_o(axi_read_bytes_o),
    .axi_read_bursts_o(axi_read_bursts_o),
    .axi_read_beats_o(axi_read_beats_o),
    .data_mismatch_count_o(axi_data_mismatch_o),
    .rresp_error_count_o(rresp_error_count_o),
    .rlast_error_count_o(rlast_error_count_o),
    .expected_records_o(expected_records_o),
    .received_records_o(received_records_o),
    .rid_observed_o(),
    .rid_order_error_o(rid_order_error_o),
    .r_backpressure_cycles_o(r_backpressure_cycles_o)
  );

  // ---- compact cue -> TermGen cue bag (NodeRecordV1: cue at byte 8, confidence at byte 12) ----
  // Delivery-layer widening only: CUE64 = {cue32, ~cue32}. TermGen law is untouched.
  node_id_t      tg_id_in   [NG_LANES];
  termgen_cues_t tg_cues_in [NG_LANES];
  logic [NG_LANES-1:0] tg_valid_in;

  always_comb begin
    for (int k = 0; k < int'(NG_LANES); k++) begin
      tg_valid_in[k]             = wave_valid;
      tg_id_in[k]                = wave_rec[k][31:0];
      tg_cues_in[k].query_cue    = q_query_cue_i;
      tg_cues_in[k].node_cue     = {wave_rec[k][95:64], ~wave_rec[k][95:64]};
      tg_cues_in[k].relation_cue = q_relation_cue_i;
      tg_cues_in[k].intent_cue   = q_intent_cue_i;
      tg_cues_in[k].context_cue  = q_context_cue_i;
      tg_cues_in[k].path_cue     = q_path_cue_i;
      tg_cues_in[k].learned_prior = term_t'(wave_rec[k][103:96]);
    end
  end

  logic [NG_LANES-1:0] tg_valid_out;
  node_id_t            tg_id_out [NG_LANES];
  score_terms_t        tg_terms  [NG_LANES];

  a7ng_termgen_array u_tg (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tg_valid_in), .cand_id_i(tg_id_in), .cues_i(tg_cues_in),
    .valid_o(tg_valid_out), .cand_id_o(tg_id_out), .terms_o(tg_terms)
  );

  logic core_topk_valid;
  score_t   core_topk_score [8];
  node_id_t core_topk_id    [8];
  logic     fr_pop_valid, fr_overflow, fr_push_fire, fr_push_stall, fr_flow_busy;
  logic [7:0] fr_count;
  score_t   fr_score;
  node_id_t fr_id;
  logic [2:0] fr_push_idx;
  logic [1:0] fr_state;
  logic       fr_beat_valid;
  score_t     fr_beat_score;
  node_id_t   fr_beat_id;

  a7ng_ng02_core u_core (
    .clk(clk), .rst_n(rst_n),
    .lane_valid_i(tg_valid_out),
    .cand_id_i(tg_id_out),
    .terms_i(tg_terms),
    .frontier_pop_i(1'b1),          // drain continuously; frontier law untouched
    .batch_ready_o(core_batch_ready),
    .topk_valid_o(core_topk_valid),
    .topk_score_o(core_topk_score),
    .topk_id_o(core_topk_id),
    .frontier_pop_valid_o(fr_pop_valid),
    .frontier_score_o(fr_score),
    .frontier_id_o(fr_id),
    .frontier_overflow_o(fr_overflow),
    .frontier_count_o(fr_count),
    .flow_busy_o(fr_flow_busy),
    .push_idx_o(fr_push_idx),
    .push_fire_o(fr_push_fire),
    .push_stall_o(fr_push_stall),
    .push_beat_valid_o(fr_beat_valid),
    .push_beat_score_o(fr_beat_score),
    .push_beat_id_o(fr_beat_id),
    .flow_state_o(fr_state)
  );

  assign topk_valid_o     = core_topk_valid;
  assign frontier_count_o = fr_count;
  always_comb begin
    for (int k = 0; k < 8; k++) begin
      topk_score_o[k] = core_topk_score[k];
      topk_id_o[k]    = core_topk_id[k];
    end
  end

  // ---- consumer-side conservation + diagnostics (per-run) ----
  logic [31:0] batches, closs, tkb, busyc, fpush, fovf;
  wire wave_at_cons = &tg_valid_out;

  assign batches_accepted_o  = batches;
  assign consumer_loss_o     = closs;
  assign topk_batches_o      = tkb;
  assign flow_busy_cycles_o  = busyc;
  assign frontier_push_o     = fpush;
  assign frontier_overflow_o = fovf;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tg_pipe <= 2'b00;
      batches <= 32'd0; closs <= 32'd0; tkb <= 32'd0; busyc <= 32'd0;
      fpush <= 32'd0; fovf <= 32'd0;
    end else if (start_i) begin
      tg_pipe <= 2'b00;
      batches <= 32'd0; closs <= 32'd0; tkb <= 32'd0; busyc <= 32'd0;
      fpush <= 32'd0; fovf <= 32'd0;
    end else begin
      tg_pipe <= {tg_pipe[0], wave_valid};
      if (wave_at_cons) begin
        if (core_batch_ready) batches <= batches + 32'd1;
        else                  closs   <= closs + 32'd1;
      end
      if (core_topk_valid) tkb   <= tkb + 32'd1;
      if (fr_flow_busy)    busyc <= busyc + 32'd1;
      if (fr_push_fire)    fpush <= fpush + 32'd1;
      if (fr_overflow)     fovf  <= fovf + 32'd1;
    end
  end
endmodule
