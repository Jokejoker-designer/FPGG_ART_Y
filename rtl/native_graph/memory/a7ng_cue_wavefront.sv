// a7ng_cue_wavefront.sv — bounded ping/pong cue working set → 16-candidate wave
// Gate: ddr_wavefront_00.  Law: a7ng-cue-wavefront-v0 (delivery/working-set layer ONLY).
//
// Path (from AUTHORITY_MEMORY_DOCTRINE.md — given, not invented here):
//   DDR -> sequential/burst compact cue fetch -> ping buffer A/B -> 16-candidate wave
//
// This module owns delivery only. It does not score, rank, prune, learn or answer.
// Scoring stays in a7ng_termgen_array + a7ng_scorer_array; ranking stays in a7ng_topk.
//
// Bounded: 2 banks x WAVE records x 16 B = 512 B at WAVE=16 (LUTRAM/FF; BRAM = 0).
// HS-13: no full-graph scan — exactly total_recs_i candidate records are fetched per query.
// HS-14: every DDR address is generated here from base_node_i (node-id domain), never by a host.
//
// Per-run telemetry only: every counter is cleared by start_i (not just rst_n), so a run
// row can never be a cumulative sum of earlier runs.
`timescale 1ns / 1ps

module a7ng_cue_wavefront #(
  parameter int unsigned WAVE      = 16,  // records delivered per wave == physical lanes
  parameter int unsigned MAX_OUT   = 8,
  parameter int unsigned MAX_BURST = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,        // pulse: begin query run + clear per-run telemetry
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,   // quantized to WAVE (frozen ng02 needs all 16 valids)
  // AR / R in node-id domain (a7ng_ddr_feed_axi_bridge converts to byte addresses)
  output logic         ar_valid_o,
  input  logic         ar_ready_i,
  output logic [31:0]  ar_addr_o,
  output logic [7:0]   ar_len_o,
  output logic [3:0]   ar_id_o,
  input  logic         r_valid_i,
  output logic         r_ready_o,
  input  logic [127:0] r_data_i,
  input  logic         r_last_i,
  // wave interface to the 16 physical lanes
  input  logic         cons_ready_i,   // consumer can take a whole wave this cycle
  output logic         wave_valid_o,   // 1-cycle pulse: all WAVE records valid together
  output logic [127:0] wave_rec_o [WAVE],
  output logic [31:0]  wave_base_id_o,
  // per-run telemetry
  output logic         running_o,
  output logic         done_o,
  output logic [31:0]  cycles_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  cand_accepted_o,   // admitted to the pipeline (AR beats requested)
  output logic [31:0]  cand_delivered_o,  // handed to the lanes
  output logic [31:0]  cand_queued_o,     // held in ping/pong banks
  output logic [31:0]  cand_inflight_o,   // AR issued, beat not yet returned
  output logic [31:0]  cand_pruned_o,     // delivery layer never prunes: must stay 0
  output logic [31:0]  conserve_err_o,    // accepted != delivered+queued+inflight+pruned
  output logic [31:0]  data_mismatch_o,   // checked AT CONSUMPTION vs preloaded pattern
  output logic [31:0]  swap_count_o,
  output logic [31:0]  buffer_empty_stall_o, // consumer ready, no full bank
  output logic [31:0]  buffer_full_stall_o,  // beat offered, no room (RVALID && !RREADY)
  output logic [31:0]  cons_ready_cycles_o,
  output logic [31:0]  fill_cycles_o,     // accumulated first-beat -> bank FULL
  output logic [31:0]  fill_episodes_o,
  output logic         fill_bank_o,
  output logic         drain_bank_o,
  output logic [15:0]  occ_fill_o,
  output logic [15:0]  occ_drain_o
);
  localparam int unsigned IDX_W = $clog2(WAVE);
  localparam int unsigned CNT_W = $clog2(WAVE + 1);

  (* ram_style = "distributed" *) logic [127:0] rec0 [WAVE];
  (* ram_style = "distributed" *) logic [127:0] rec1 [WAVE];

  logic [CNT_W-1:0] cnt0, cnt1;
  logic             fill_sel, drain_sel;
  logic [31:0]      fst0, fst1;      // cycle stamp of first beat of the open fill episode
  logic [31:0]      next_node, issued, returned, delivered, target, base_q, pending;
  logic [3:0]       in_flight, rid_q;
  logic             running;
  logic [31:0]      cyc, waves, mm, cerr, swaps, empty_st, full_st, cr_cyc, fill_acc, fill_eps;

  wire bank_full0 = (cnt0 == CNT_W'(WAVE));
  wire bank_full1 = (cnt1 == CNT_W'(WAVE));
  wire fill_full  = fill_sel  ? bank_full1 : bank_full0;
  wire drain_full = drain_sel ? bank_full1 : bank_full0;

  assign running_o        = running;
  assign done_o           = !running && (delivered >= target) && (target != 32'd0);
  assign cycles_o         = cyc;
  assign waves_o          = waves;
  assign cand_accepted_o  = issued;
  assign cand_delivered_o = delivered;
  assign cand_queued_o    = 32'(cnt0) + 32'(cnt1);
  assign cand_inflight_o  = pending;
  assign cand_pruned_o    = 32'd0;   // structural: this layer has no prune path
  assign conserve_err_o   = cerr;
  assign data_mismatch_o  = mm;
  assign swap_count_o     = swaps;
  assign buffer_empty_stall_o = empty_st;
  assign buffer_full_stall_o  = full_st;
  assign cons_ready_cycles_o  = cr_cyc;
  assign fill_cycles_o    = fill_acc;
  assign fill_episodes_o  = fill_eps;
  assign fill_bank_o      = fill_sel;
  assign drain_bank_o     = drain_sel;
  assign occ_fill_o       = fill_sel  ? 16'(cnt1) : 16'(cnt0);
  assign occ_drain_o      = drain_sel ? 16'(cnt1) : 16'(cnt0);

  // Bounded working set: refuse beats when the fill bank is full (backpressure, never drop)
  assign r_ready_o = running && !fill_full;

  logic [127:0] wave_rec_c [WAVE];
  always_comb begin
    for (int k = 0; k < int'(WAVE); k++) begin
      wave_rec_c[k] = drain_sel ? rec1[k] : rec0[k];
      wave_rec_o[k] = drain_sel ? rec1[k] : rec0[k];
    end
  end
  assign wave_base_id_o = base_q + delivered;

  wire do_wave = running && drain_full && cons_ready_i;
  assign wave_valid_o = do_wave;

  wire [4:0] burst_c = (burst_i == 5'd0) ? 5'd1 :
                       ((burst_i > 5'(MAX_BURST)) ? 5'(MAX_BURST) : burst_i);
  wire [3:0] out_c   = (outstanding_i == 4'd0) ? 4'd1 :
                       ((outstanding_i > 4'(MAX_OUT)) ? 4'(MAX_OUT) : outstanding_i);

  // Narrow remain/room math (candidates per query << 2^16) — keeps ui_clk carry depth low.
  wire [15:0] remain16 = (issued[15:0] < target[15:0]) ? (target[15:0] - issued[15:0]) : 16'd0;
  wire [4:0]  this_burst_c = (remain16 == 16'd0) ? 5'd0 :
                             (remain16 < 16'(burst_c)) ? 5'(remain16[4:0]) : burst_c;
  wire [15:0] held16  = 16'(cnt0) + 16'(cnt1) + pending[15:0];
  wire [15:0] room16  = (held16 < 16'(2 * WAVE)) ? (16'(2 * WAVE) - held16) : 16'd0;
  // Whole-burst admission keeps axi_read_bursts == ceil(total/burst) exactly; a drain always
  // frees WAVE >= MAX_BURST slots, so this cannot deadlock while beats keep landing.
  wire issue_ok_c = running && (this_burst_c != 5'd0) && (in_flight < out_c) &&
                    (room16 >= 16'(this_burst_c));

  // 1-cycle AR pipeline with post-accept refresh (MIG-METRIC-00 fix: remain==burst must not
  // queue one extra burst).
  logic        ar_valid_q;
  logic [31:0] ar_addr_q;
  logic [7:0]  ar_len_q;
  logic [3:0]  ar_id_q;
  logic [4:0]  this_burst_q;

  assign ar_valid_o = ar_valid_q;
  assign ar_addr_o  = ar_addr_q;
  assign ar_len_o   = ar_len_q;
  assign ar_id_o    = ar_id_q;

  wire do_ar = ar_valid_q && ar_ready_i;
  wire do_r  = r_valid_i && r_ready_o;

  // Deterministic preloaded NodeRecordV1 pattern, re-derived here independently of the
  // testbench packer so a shared bug cannot mask a delivery fault.
  function automatic logic [127:0] pat_node(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[47:32]   = 16'd1;
    b[63:48]   = 16'(nid[7:0]);
    b[95:64]   = 32'hDDFE_0000 + nid;
    b[111:96]  = 16'h0100;
    b[119:112] = 8'(nid[7:0]);
    b[127:120] = 8'd1;
    return b;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt0 <= '0; cnt1 <= '0;
      fill_sel <= 1'b0; drain_sel <= 1'b0;
      fst0 <= '0; fst1 <= '0;
      next_node <= '0; issued <= '0; returned <= '0; delivered <= '0;
      target <= '0; base_q <= '0; pending <= '0;
      in_flight <= '0; rid_q <= '0; running <= 1'b0;
      cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
      empty_st <= '0; full_st <= '0; cr_cyc <= '0; fill_acc <= '0; fill_eps <= '0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; ar_id_q <= '0; this_burst_q <= '0;
    end else if (start_i) begin
      cnt0 <= '0; cnt1 <= '0;
      fill_sel <= 1'b0; drain_sel <= 1'b0;
      fst0 <= '0; fst1 <= '0;
      next_node <= base_node_i; base_q <= base_node_i;
      issued <= '0; returned <= '0; delivered <= '0;
      target <= total_recs_i; pending <= '0;
      in_flight <= '0; rid_q <= '0; running <= 1'b1;
      cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
      empty_st <= '0; full_st <= '0; cr_cyc <= '0; fill_acc <= '0; fill_eps <= '0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; ar_id_q <= '0; this_burst_q <= '0;
    end else if (running) begin
      automatic logic [CNT_W-1:0] c0, c1, pre;
      automatic logic             f_sel, d_sel, became_full;
      automatic logic [31:0]      iss, ret, del, pb, mmadd, fstart;
      automatic logic [3:0]       nf;

      c0 = cnt0; c1 = cnt1;
      f_sel = fill_sel; d_sel = drain_sel;
      iss = issued; ret = returned; del = delivered; pb = pending; nf = in_flight;
      mmadd = 32'd0;
      became_full = 1'b0;
      pre = '0;

      cyc <= cyc + 32'd1;
      if (cons_ready_i)
        cr_cyc <= cr_cyc + 32'd1;

      // Conservation identity on registered state: accepted == delivered+queued+inflight+pruned
      if (issued != (delivered + 32'(cnt0) + 32'(cnt1) + pending))
        cerr <= cerr + 32'd1;

      // ---- address generation + AR issue (HS-14: FPGA owns every address) ----
      if (do_ar) begin
        next_node <= next_node + 32'(this_burst_q);
        iss  = iss + 32'(this_burst_q);
        pb   = pb + 32'(this_burst_q);
        nf   = nf + 4'd1;
        rid_q <= rid_q + 4'd1;
        ar_valid_q <= 1'b0;
      end else if (!ar_valid_q) begin
        ar_valid_q   <= issue_ok_c;
        ar_addr_q    <= next_node;
        this_burst_q <= this_burst_c;
        ar_len_q     <= (this_burst_c == 5'd0) ? 8'd0 : 8'(this_burst_c - 5'd1);
        ar_id_q      <= rid_q;
      end

      // ---- compact cue beat -> bounded fill bank ----
      if (do_r) begin
        pre = f_sel ? c1 : c0;
        if (f_sel) begin
          rec1[pre[IDX_W-1:0]] <= r_data_i;
          c1 = pre + 1'b1;
        end else begin
          rec0[pre[IDX_W-1:0]] <= r_data_i;
          c0 = pre + 1'b1;
        end
        ret = ret + 32'd1;
        pb  = pb - 32'd1;
        if (r_last_i)
          nf = nf - 4'd1;

        // first beat into an empty bank opens a fill episode
        if (pre == '0) begin
          if (f_sel) fst1 <= cyc;
          else       fst0 <= cyc;
        end

        became_full = ((f_sel ? c1 : c0) == CNT_W'(WAVE));
        if (became_full) begin
          fstart = (pre == '0) ? cyc : (f_sel ? fst1 : fst0);
          fill_acc <= fill_acc + (cyc - fstart + 32'd1);
          fill_eps <= fill_eps + 32'd1;
          f_sel = ~f_sel;              // ping/pong handoff
          swaps <= swaps + 32'd1;
        end
      end else if (r_valid_i && !r_ready_o) begin
        full_st <= full_st + 32'd1;    // bounded buffer backpressures; beat is NOT dropped
      end

      // ---- atomic 16-candidate wave to the lanes ----
      if (do_wave) begin
        for (int k = 0; k < int'(WAVE); k++) begin
          if (wave_rec_c[k] != pat_node(base_q + del + 32'(k)))
            mmadd = mmadd + 32'd1;
        end
        if (d_sel) c1 = '0;
        else       c0 = '0;
        d_sel = ~d_sel;
        del   = del + 32'(WAVE);
        waves <= waves + 32'd1;
      end else if (cons_ready_i && (delivered < target)) begin
        empty_st <= empty_st + 32'd1;  // memory wait: consumer ready, no full bank
      end

      if (mmadd != 32'd0)
        mm <= mm + mmadd;

      cnt0 <= c0; cnt1 <= c1;
      fill_sel <= f_sel; drain_sel <= d_sel;
      issued <= iss; returned <= ret; delivered <= del; pending <= pb; in_flight <= nf;

      if ((del >= target) && (pb == 32'd0) && (nf == 4'd0) && (c0 == '0) && (c1 == '0)) begin
        running <= 1'b0;
        ar_valid_q <= 1'b0;
      end
    end else begin
      ar_valid_q <= 1'b0;
    end
  end
endmodule
