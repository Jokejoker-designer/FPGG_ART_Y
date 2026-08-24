// a7ng_perfmon.sv — PERFMON-lite (feedback §21 / PLAN B2)
// Law: instrumentation ONLY — does not alter search/learn/dispatch.
// Observer: samples share/frontier/topk taps off the critical grant path.
// UNIT: counter dump per run/seed (not cycles-as-queries).
`timescale 1ns / 1ps

module a7ng_perfmon #(
  parameter int unsigned N_PHYS = 16
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       clear_i,
  input  logic                       enable_i,

  // ---- Share snapshot taps (existing a7ng_multi_agent_share ports) ----
  input  logic [N_PHYS-1:0]          lane_busy_i,
  input  logic [4:0]                 jobs_per_cycle_i,
  input  logic [15:0]                queue_occupancy_i,
  input  logic                       queue_full_i,
  input  logic                       scheduler_idle_i,
  input  logic                       scheduler_conflict_i,
  input  logic [31:0]                starvation_count_i,
  input  logic [31:0]                drop_stale_i,

  // ---- Frontier event taps (from a7ng_frontier_buckets wires) ----
  input  logic                       frontier_push_fire_i,
  input  logic                       frontier_pop_fire_i,
  input  logic                       frontier_full_pulse_i,

  // ---- Top-K event taps (from a7ng_topk) ----
  input  logic                       topk_batch_fire_i,
  input  logic [4:0]                 candidates_in_i,
  input  logic [3:0]                 candidates_out_i,

  // ---- Accumulated dump (read after run / seed) ----
  output logic [31:0]                cycles_total_o,
  output logic [31:0]                lane_busy_accum_o [N_PHYS],
  output logic [31:0]                jobs_accum_o,
  output logic [31:0]                queue_occ_accum_o,
  output logic [31:0]                queue_full_cycles_o,
  output logic [31:0]                scheduler_idle_cycles_o,
  output logic [31:0]                scheduler_conflict_cycles_o,
  output logic [31:0]                scheduler_grants_o,
  output logic [31:0]                starve_sample_o,
  output logic [31:0]                stale_drop_sample_o,
  output logic [31:0]                frontier_push_o,
  output logic [31:0]                frontier_pop_o,
  output logic [31:0]                frontier_full_o,
  output logic [31:0]                topk_batches_o,
  output logic [31:0]                candidates_in_accum_o,
  output logic [31:0]                candidates_out_accum_o
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycles_total_o               <= 32'd0;
      jobs_accum_o                 <= 32'd0;
      queue_occ_accum_o            <= 32'd0;
      queue_full_cycles_o          <= 32'd0;
      scheduler_idle_cycles_o      <= 32'd0;
      scheduler_conflict_cycles_o  <= 32'd0;
      scheduler_grants_o           <= 32'd0;
      starve_sample_o              <= 32'd0;
      stale_drop_sample_o          <= 32'd0;
      frontier_push_o              <= 32'd0;
      frontier_pop_o               <= 32'd0;
      frontier_full_o              <= 32'd0;
      topk_batches_o               <= 32'd0;
      candidates_in_accum_o        <= 32'd0;
      candidates_out_accum_o       <= 32'd0;
      for (int i = 0; i < N_PHYS; i++)
        lane_busy_accum_o[i] <= 32'd0;
    end else if (clear_i) begin
      cycles_total_o               <= 32'd0;
      jobs_accum_o                 <= 32'd0;
      queue_occ_accum_o            <= 32'd0;
      queue_full_cycles_o          <= 32'd0;
      scheduler_idle_cycles_o      <= 32'd0;
      scheduler_conflict_cycles_o  <= 32'd0;
      scheduler_grants_o           <= 32'd0;
      starve_sample_o              <= 32'd0;
      stale_drop_sample_o          <= 32'd0;
      frontier_push_o              <= 32'd0;
      frontier_pop_o               <= 32'd0;
      frontier_full_o              <= 32'd0;
      topk_batches_o               <= 32'd0;
      candidates_in_accum_o        <= 32'd0;
      candidates_out_accum_o       <= 32'd0;
      for (int i = 0; i < N_PHYS; i++)
        lane_busy_accum_o[i] <= 32'd0;
    end else if (enable_i) begin
      cycles_total_o <= cycles_total_o + 32'd1;

      for (int i = 0; i < N_PHYS; i++)
        if (lane_busy_i[i])
          lane_busy_accum_o[i] <= lane_busy_accum_o[i] + 32'd1;

      jobs_accum_o       <= jobs_accum_o + {{(32-5){1'b0}}, jobs_per_cycle_i};
      scheduler_grants_o <= scheduler_grants_o + {{(32-5){1'b0}}, jobs_per_cycle_i};
      queue_occ_accum_o  <= queue_occ_accum_o + {{16{1'b0}}, queue_occupancy_i};

      if (queue_full_i)
        queue_full_cycles_o <= queue_full_cycles_o + 32'd1;
      if (scheduler_idle_i)
        scheduler_idle_cycles_o <= scheduler_idle_cycles_o + 32'd1;
      if (scheduler_conflict_i)
        scheduler_conflict_cycles_o <= scheduler_conflict_cycles_o + 32'd1;

      // Mirror share absolute counters (authoritative; no duplicate law)
      starve_sample_o     <= starvation_count_i;
      stale_drop_sample_o <= drop_stale_i;

      if (frontier_push_fire_i)
        frontier_push_o <= frontier_push_o + 32'd1;
      if (frontier_pop_fire_i)
        frontier_pop_o <= frontier_pop_o + 32'd1;
      if (frontier_full_pulse_i)
        frontier_full_o <= frontier_full_o + 32'd1;

      if (topk_batch_fire_i) begin
        topk_batches_o         <= topk_batches_o + 32'd1;
        candidates_in_accum_o  <= candidates_in_accum_o + {{(32-5){1'b0}}, candidates_in_i};
        candidates_out_accum_o <= candidates_out_accum_o + {{(32-4){1'b0}}, candidates_out_i};
      end
    end
  end
endmodule
