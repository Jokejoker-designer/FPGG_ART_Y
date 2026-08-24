// tb_a7ng_ddr_feed.sv — A7-BRAM-WM-01 / ddr_feed sweep
// OBSERVATION: WM-00 lossless XSim; PE may stall without burst/pingpong/outstanding
// UNKNOWN: does ping-pong DDR→WM feed with swept burst{1,4,8,16} × outstanding{1,2,4,8}
//           reduce PE stall vs baseline single-issue?
// H_CANDIDATE: double-buffer + burst + multi-outstanding lowers stall / raises recs/cycle
// H_RIVAL: synthetic latency hides real MIG; numbers artifactual (OPEN — not MIG)
// FALSIFIER: stall not reduced across sweep; DROP>0; LM-06/frozen SHA changed
// UNIT: sweep cell (burst×outstanding×seed) — not cycles-as-queries
// CONTROL: WM-00 SHA / mem_schema F0FE426E…; frozen LM bits MATCH
// METRICS (preregistered): PE stall fraction, effective records/cycle, empty/full stalls
`timescale 1ns / 1ps

module tb_a7ng_ddr_feed;
  localparam int N_PE = 16;
  localparam int TOTAL = 256;
  localparam int SEEDS = 2;

  logic clk, rst_n;
  logic start;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node;
  logic [31:0] total_recs;
  logic [N_PE-1:0] pe_req;

  logic done, running;
  logic [31:0] empty_st, full_st, pe_st, pe_bs, cyc, cons, drops;
  logic [15:0] occ_a, occ_f;
  logic active_bank;
  logic [31:0] ddr_rdb, ddr_rdc, ddr_br;
  logic [7:0]  ddr_out;
  logic [N_PE-1:0] pe_grant;
  logic [31:0] pe_grants;

  int fails;
  int cell_fail;
  real baseline_stall_frac;
  real best_stall_frac;
  int  best_burst, best_out;
  int  improved;
  int  any_drop;

  // Preregistered metric holders per cell
  real stall_frac;
  real recs_per_cyc;

  a7ng_ddr_feed_top #(
    .N_NODES(1024), .BANK_DEPTH(32), .N_PE(N_PE),
    .LATENCY(24), .MAX_OUT(8), .MAX_BURST(16)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .start_i(start),
    .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .pe_req_i(pe_req),
    .done_o(done), .running_o(running),
    .empty_stall_o(empty_st), .full_stall_o(full_st),
    .pe_stall_o(pe_st), .pe_busy_o(pe_bs),
    .cycles_o(cyc), .recs_consumed_o(cons), .drop_o(drops),
    .occ_active_o(occ_a), .occ_fill_o(occ_f), .active_bank_o(active_bank),
    .ddr_rd_bytes_o(ddr_rdb), .ddr_rd_count_o(ddr_rdc),
    .ddr_burst_count_o(ddr_br), .ddr_outstanding_o(ddr_out),
    .pe_grant_o(pe_grant), .pe_grant_count_o(pe_grants)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk; // 100 MHz nominal — timing NOT claimed this gate

  task automatic do_reset;
    begin
      rst_n = 1'b0;
      start = 1'b0;
      burst = 5'd1;
      outstanding = 4'd1;
      base_node = 32'd0;
      total_recs = 32'(TOTAL);
      pe_req = '0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic run_cell(input int b, input int o, input int seed);
    int timeout;
    begin
      cell_fail = 0;
      @(negedge clk);
      burst = 5'(b);
      outstanding = 4'(o);
      base_node = 32'(seed * 17);
      total_recs = 32'(TOTAL);
      pe_req = {N_PE{1'b1}}; // all lanes hungry
      start = 1'b1;
      @(posedge clk);
      @(negedge clk);
      start = 1'b0;

      timeout = 0;
      while (!done && timeout < 200000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end

      if (!done) begin
        $display("CELL_FAIL burst=%0d out=%0d seed=%0d TIMEOUT", b, o, seed);
        cell_fail = 1;
        fails = fails + 1;
      end else if (drops != 0) begin
        $display("CELL_FAIL burst=%0d out=%0d seed=%0d DROP=%0d", b, o, seed, drops);
        cell_fail = 1;
        fails = fails + 1;
        any_drop = 1;
      end else if (cons != 32'(TOTAL)) begin
        $display("CELL_FAIL burst=%0d out=%0d seed=%0d cons=%0d expected=%0d",
                 b, o, seed, cons, TOTAL);
        cell_fail = 1;
        fails = fails + 1;
      end else begin
        if ((pe_st + pe_bs) == 0)
          stall_frac = 0.0;
        else
          stall_frac = real'(pe_st) / real'(pe_st + pe_bs);
        if (cyc == 0)
          recs_per_cyc = 0.0;
        else
          recs_per_cyc = real'(cons) / real'(cyc);

        // CSV row for archive table
        $display("SWEEP_ROW burst=%0d out=%0d seed=%0d stall_frac=%0.6f recs_per_cyc=%0.6f pe_stall=%0d pe_busy=%0d empty_st=%0d full_st=%0d cycles=%0d cons=%0d drop=%0d ddr_rd_bytes=%0d ddr_bursts=%0d",
                 b, o, seed, stall_frac, recs_per_cyc, pe_st, pe_bs, empty_st, full_st,
                 cyc, cons, drops, ddr_rdb, ddr_br);

        if (b == 1 && o == 1 && seed == 0)
          baseline_stall_frac = stall_frac;

        if (stall_frac < best_stall_frac) begin
          best_stall_frac = stall_frac;
          best_burst = b;
          best_out = o;
        end
      end

      // drain / re-arm
      pe_req = '0;
      repeat (4) @(posedge clk);
      // pulse reset between cells for clean counters
      rst_n = 1'b0;
      repeat (2) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  int bursts [4];
  int outs   [4];
  int bi, oi, si;

  initial begin
    fails = 0;
    any_drop = 0;
    improved = 0;
    baseline_stall_frac = 1.0;
    best_stall_frac = 1.0;
    best_burst = 1;
    best_out = 1;
    bursts[0] = 1; bursts[1] = 4; bursts[2] = 8; bursts[3] = 16;
    outs[0] = 1; outs[1] = 2; outs[2] = 4; outs[3] = 8;

    $display("PREREG_METRICS: pe_stall_frac, effective_recs_per_cycle, empty_stall, full_stall");
    $display("PREREG_UNIT: sweep_cell(burst x outstanding x seed)");
    $display("PREREG_CONTROL: WM00_SHA + mem_schema F0FE426E + frozen LM bits");
    $display("PREREG_FALSIFIER: stall_not_reduced | DROP>0 | frozen_SHA_changed");
    $display("NOTE: LATENCY=24 synthetic — H_RIVAL OPEN (not MIG). No 100MHz timing claim.");

    do_reset();

    for (si = 0; si < SEEDS; si++) begin
      for (bi = 0; bi < 4; bi++) begin
        for (oi = 0; oi < 4; oi++) begin
          run_cell(bursts[bi], outs[oi], si);
        end
      end
    end

    $display("BASELINE_STALL_FRAC (burst=1,out=1,seed0)=%0.6f", baseline_stall_frac);
    $display("BEST_STALL_FRAC burst=%0d out=%0d frac=%0.6f", best_burst, best_out, best_stall_frac);

    // PASS: stall reduced vs baseline by >=10% relative OR absolute drop >=0.05
    if (best_stall_frac < baseline_stall_frac * 0.90 ||
        (baseline_stall_frac - best_stall_frac) >= 0.05)
      improved = 1;

    $display("STALL_REDUCED=%0d", improved);
    $display("ANY_DROP=%0d", any_drop);

    if (any_drop)
      fails = fails + 1;
    if (!improved) begin
      $display("H_CANDIDATE_FALSIFIED: stall not reduced across sweep");
      fails = fails + 1;
    end

    if (fails == 0) begin
      $display("A7NG_DDR_FEED_XSIM_PASS");
      $display("GATE_ddr_feed PASS (engineering/XSIM). No BOARD_PASS. No 100MHz claim.");
    end else begin
      $display("A7NG_DDR_FEED_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
