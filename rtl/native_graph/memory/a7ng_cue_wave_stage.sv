// a7ng_cue_wave_stage.sv — bounded compact-cue working set → 16-wide candidate wave
// Gate: ddr_wavefront_00 (memory DELIVERY only). Law: a7ng-cue-wave-v0.
// Bounded by declaration: N_LANES banks x ENTRIES_PER_BANK entries, compact entry
// {cue[31:0], node_id[31:0]} = 8 B. Default 16 x 16 = 256 candidates = 2 KiB (SPEC §32 class).
// SPEC §11: deterministic bank map bank = node_id[3:0]; one entry per bank per wave →
// zero bank conflict by construction; 16 candidates leave in ONE cycle (not 1/cycle renamed).
// No silent overwrite: in_ready_o deasserts while any bank is full (HS: explicit backpressure).
// Does not touch 01R / HIT_MAX / TermGen / Top-K / relation / LM-06 / 02M / training law.
`timescale 1ns / 1ps

module a7ng_cue_wave_stage #(
  parameter int unsigned N_LANES          = 16,
  parameter int unsigned ENTRIES_PER_BANK = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,      // per-run clear (metric_clear semantics)
  input  logic [31:0]  total_i,      // candidates expected this query
  input  logic         flush_i,      // allow a partial (tail) wave to leave
  // compact cue in — one NodeRecordV1 beat per cycle from the ping/pong feeder
  input  logic         in_valid_i,
  output logic         in_ready_o,
  input  logic [127:0] in_rec_i,
  // 16-wide wave out — one entry per bank, all in the same cycle
  input  logic         wave_ready_i,
  output logic         wave_valid_o,
  output logic [N_LANES-1:0] wave_mask_o,
  output logic [31:0]  wave_id_o  [N_LANES],
  output logic [31:0]  wave_cue_o [N_LANES],
  output logic [31:0]  wave_index_o,
  // telemetry (per-run deltas; cleared by start_i or rst_n)
  output logic [31:0]  accepted_o,
  output logic [31:0]  dispatched_o,
  output logic [31:0]  resident_o,
  output logic [31:0]  max_resident_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  partial_waves_o,
  output logic [31:0]  emit_cycles_o,
  output logic [31:0]  fill_cycles_o,
  output logic [31:0]  mem_wait_cycles_o,
  output logic [31:0]  sink_wait_cycles_o,
  output logic [31:0]  active_cycles_o,
  output logic [31:0]  bank_full_stall_o,
  output logic [31:0]  struct_mismatch_o,
  output logic [31:0]  bank_map_err_o,
  output logic         active_o,
  output logic         done_o
);
  import a7ng_mem_schema_v1_pkg::*;

  localparam int unsigned LANE_W = $clog2(N_LANES);
  localparam int unsigned IDX_W  = $clog2(ENTRIES_PER_BANK);
  localparam int unsigned CNT_W  = $clog2(ENTRIES_PER_BANK + 1);
  localparam int unsigned ENTRY_W = 64;

  // Compact cue banks (LUTRAM class in this gate; post-route cost NOT measured here)
  (* ram_style = "distributed" *) logic [ENTRY_W-1:0] bank_mem [N_LANES][ENTRIES_PER_BANK];

  logic [CNT_W-1:0] cnt [N_LANES];
  logic [IDX_W-1:0] rdp [N_LANES];
  logic [IDX_W-1:0] wrp [N_LANES];
  logic [31:0]      last_id [N_LANES];
  logic [N_LANES-1:0] last_v;

  logic [31:0] accepted, dispatched, waves, partial_waves, emit_cyc;
  logic [31:0] fill_cyc, mem_wait, sink_wait, active_cyc;
  logic [31:0] bank_full_st, struct_mm, bank_err, max_res, wave_idx;
  logic        active, done;

  // ---- combinational state view ----
  logic [N_LANES-1:0] bank_nonempty, bank_full;
  logic [31:0]        resident_c;

  always_comb begin
    resident_c = 32'd0;
    for (int b = 0; b < N_LANES; b++) begin
      bank_nonempty[b] = (cnt[b] != '0);
      bank_full[b]     = (cnt[b] == CNT_W'(ENTRIES_PER_BANK));
      resident_c       = resident_c + 32'(cnt[b]);
    end
  end

  wire wave_full   = &bank_nonempty;
  wire wave_any    = |bank_nonempty;
  wire any_full    = |bank_full;

  // Bounded: refuse the write instead of overwriting (SPEC §5.2 "no silent overwrite")
  assign in_ready_o = active && !any_full;

  wire do_in = in_valid_i && in_ready_o;
  // node_id[3:0] → bank (deterministic map, SPEC §11)
  wire [LANE_W-1:0] in_bank = in_rec_i[LANE_W-1:0];
  // NodeRecordV1 field offsets come from a7ng_mem_schema_v1_pkg — no local magic strides
  wire [31:0] in_node_id = in_rec_i[(8*A7NG_NODE_OFF_NODE_ID) +: 32];
  wire [31:0] in_cue     = in_rec_i[(8*A7NG_NODE_OFF_CUE)     +: 32];
  wire [ENTRY_W-1:0] in_entry = {in_cue, in_node_id};

  assign wave_valid_o = active && (wave_full || (flush_i && wave_any));
  wire do_emit = wave_valid_o && wave_ready_i;

  logic [31:0] emit_n;
  always_comb begin
    emit_n = 32'd0;
    for (int b = 0; b < N_LANES; b++) begin
      wave_mask_o[b] = wave_valid_o && bank_nonempty[b];
      wave_id_o[b]   = bank_mem[b][rdp[b]][31:0];
      wave_cue_o[b]  = bank_mem[b][rdp[b]][63:32];
      if (wave_valid_o && bank_nonempty[b])
        emit_n = emit_n + 32'd1;
    end
  end

  // Single authority for bank occupancy: write +1, emit -1, both in one cycle = net 0
  logic [CNT_W-1:0] cnt_nxt [N_LANES];
  always_comb begin
    for (int b = 0; b < N_LANES; b++) begin
      cnt_nxt[b] = cnt[b];
      if (do_in && (in_bank == LANE_W'(b)))
        cnt_nxt[b] = cnt_nxt[b] + CNT_W'(1);
      if (do_emit && wave_mask_o[b])
        cnt_nxt[b] = cnt_nxt[b] - CNT_W'(1);
    end
  end

  assign resident_o         = resident_c;
  assign accepted_o         = accepted;
  assign dispatched_o       = dispatched;
  assign max_resident_o     = max_res;
  assign waves_o            = waves;
  assign partial_waves_o    = partial_waves;
  assign emit_cycles_o      = emit_cyc;
  assign fill_cycles_o      = fill_cyc;
  assign mem_wait_cycles_o  = mem_wait;
  assign sink_wait_cycles_o = sink_wait;
  assign active_cycles_o    = active_cyc;
  assign bank_full_stall_o  = bank_full_st;
  assign struct_mismatch_o  = struct_mm;
  assign bank_map_err_o     = bank_err;
  assign active_o           = active;
  assign done_o             = done;
  assign wave_index_o       = wave_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int b = 0; b < N_LANES; b++) begin
        cnt[b]     <= '0;
        rdp[b]     <= '0;
        wrp[b]     <= '0;
        last_id[b] <= 32'd0;
      end
      last_v       <= '0;
      accepted     <= 32'd0;
      dispatched   <= 32'd0;
      waves        <= 32'd0;
      partial_waves<= 32'd0;
      emit_cyc     <= 32'd0;
      fill_cyc     <= 32'd0;
      mem_wait     <= 32'd0;
      sink_wait    <= 32'd0;
      active_cyc   <= 32'd0;
      bank_full_st <= 32'd0;
      struct_mm    <= 32'd0;
      bank_err     <= 32'd0;
      max_res      <= 32'd0;
      wave_idx     <= 32'd0;
      active       <= 1'b0;
      done         <= 1'b0;
    end else if (start_i) begin
      for (int b = 0; b < N_LANES; b++) begin
        cnt[b]     <= '0;
        rdp[b]     <= '0;
        wrp[b]     <= '0;
        last_id[b] <= 32'd0;
      end
      last_v       <= '0;
      accepted     <= 32'd0;
      dispatched   <= 32'd0;
      waves        <= 32'd0;
      partial_waves<= 32'd0;
      emit_cyc     <= 32'd0;
      fill_cyc     <= 32'd0;
      mem_wait     <= 32'd0;
      sink_wait    <= 32'd0;
      active_cyc   <= 32'd0;
      bank_full_st <= 32'd0;
      struct_mm    <= 32'd0;
      bank_err     <= 32'd0;
      max_res      <= 32'd0;
      wave_idx     <= 32'd0;
      active       <= (total_i != 32'd0);
      done         <= 1'b0;
    end else if (active) begin
      active_cyc <= active_cyc + 32'd1;

      if (resident_c > max_res)
        max_res <= resident_c;

      for (int b = 0; b < N_LANES; b++)
        cnt[b] <= cnt_nxt[b];

      if (do_in) begin
        bank_mem[in_bank][wrp[in_bank]] <= in_entry;
        wrp[in_bank] <= wrp[in_bank] + IDX_W'(1);
        accepted     <= accepted + 32'd1;
      end else if (in_valid_i && !in_ready_o) begin
        bank_full_st <= bank_full_st + 32'd1;
      end

      if (do_emit) begin
        emit_cyc   <= emit_cyc + 32'd1;
        waves      <= waves + 32'd1;
        wave_idx   <= wave_idx + 32'd1;
        dispatched <= dispatched + emit_n;
        if (emit_n != 32'(N_LANES))
          partial_waves <= partial_waves + 32'd1;

        for (int b = 0; b < N_LANES; b++) begin
          if (wave_mask_o[b]) begin
            // bank map integrity: the entry leaving bank b must belong to bank b
            if (wave_id_o[b][LANE_W-1:0] != LANE_W'(b))
              bank_err <= bank_err + 32'd1;
            // per-bank FIFO order integrity (strictly increasing node_id per bank)
            if (last_v[b] && (wave_id_o[b] <= last_id[b]))
              struct_mm <= struct_mm + 32'd1;
            last_id[b] <= wave_id_o[b];
            last_v[b]  <= 1'b1;
            rdp[b]     <= rdp[b] + IDX_W'(1);
          end
        end

        if ((dispatched + emit_n) >= total_i) begin
          active <= 1'b0;
          done   <= 1'b1;
        end
      end else if (!wave_full) begin
        // waiting for memory to complete the 16-wide wave
        mem_wait <= mem_wait + 32'd1;
        fill_cyc <= fill_cyc + 32'd1;
      end else begin
        // wave staged but the consumer is not ready — scheduler-local, not a DDR fault
        sink_wait <= sink_wait + 32'd1;
      end
    end
  end
endmodule
