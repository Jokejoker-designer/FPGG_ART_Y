// tb_a7ng_wide_dispatch.sv — NG-06R-WIDE ladder + ready-sparsity bags
// Law unchanged: a7ng-share-v1. Free-running ungated clock only.
// Measure authority = lane_grant_o (pop_valid_o DEBUG only).
// Bags (UNIT = ready-pattern / seed, not 100k cycles as queries):
//   BAG_ALWAYS_READY  — control (all idle lanes req)
//   BAG_SPARSE_READY  — Bernoulli p≈50% idle-lane req (seeded LFSR)
//   BAG_BURSTY_READY  — duty windows: READY_WIN all-req / IDLE_WIN none
`timescale 1ns / 1ps

// BAG_KIND encoding
`define A7NG_BAG_ALWAYS 0
`define A7NG_BAG_SPARSE 1
`define A7NG_BAG_BURSTY 2

module a7ng_wide_rung #(
  parameter int unsigned N_WAY     = 16,
  parameter int unsigned HORIZON   = 100000,
  parameter int unsigned SERVICE   = 1,
  parameter int unsigned N_PHYS    = 16,
  parameter int unsigned BAG_KIND  = `A7NG_BAG_ALWAYS,
  parameter int unsigned BAG_SEED  = 32'hA7_06_16,  // recorded seed for SPARSE
  parameter int unsigned READY_WIN = 64,            // BURSTY on-window
  parameter int unsigned IDLE_WIN  = 64             // BURSTY off-window
) (
  input  logic        clk,
  input  logic        start_i,
  output logic        done_o,
  output real         util_pct_o,
  output real         jobs_per_cyc_o,
  output real         ready_duty_o,
  output longint      busy_acc_o,
  output longint      jobs_acc_o,
  output longint      ready_acc_o,
  output longint      starve_o,
  output longint      sch_conf_acc_o,
  output int          max_jpc_o,
  output int          q_occ_end_o
);
  logic rst_n, fail, hot_we, hot_feed;
  logic [7:0] fail_log, phys, nway, hot_ptr, hot_addr, hot_log_w;
  logic [15:0] qcnt, nlog, lane_req, lane_done, lane_grant, lane_busy, q_occ;
  logic [255:0] alive;
  logic [N_WAY-1:0] push, push_rdy;
  logic [7:0] log_id [N_WAY];
  logic signed [15:0] score [N_WAY];
  logic [31:0] nid [N_WAY];
  logic [15:0] qep [N_WAY];
  logic [15:0] pep [N_WAY];
  logic [7:0] grant_log [N_PHYS];
  logic signed [15:0] grant_score [N_PHYS];
  logic [31:0] grant_node [N_PHYS];
  logic [15:0] grant_qep [N_PHYS];
  logic [15:0] grant_pep [N_PHYS];
  // Legacy first-grant ports — DEBUG/COMPAT only (do not infer wide width from these).
  logic pop_v;
  logic [7:0] pop_log;
  logic signed [15:0] pop_score, hot_score_w;
  logic [31:0] pop_nid, hot_node_w;
  logic [4:0] jobs_pc;
  logic sch_idle, sch_conf, q_full;
  logic [31:0] starve, drop_stale;
  logic [15:0] active_ep, hot_qep_w, hot_pep_w;

  int svc_left [N_PHYS];
  longint busy_sum, job_sum, conf_sum, ready_sum;
  int mj, cyc;
  logic [31:0] lfsr;
  int burst_phase;  // cycles into current READY/IDLE window
  bit burst_on;

  function automatic logic [31:0] lfsr_next(input logic [31:0] s);
    // xorshift32 — deterministic, seed recorded in BAG_SEED
    logic [31:0] x;
    x = s;
    if (x == 32'd0) x = 32'hA7_06_16;
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    return x;
  endfunction

  a7ng_multi_agent_share #(
    .N_PHYS(N_PHYS), .N_WAY(N_WAY), .QDEPTH(8), .N_BANKS(16)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(active_ep),
    .push_i(push), .log_id_i(log_id), .score_i(score), .node_id_i(nid),
    .query_epoch_i(qep), .path_epoch_i(pep),
    .push_ready_o(push_rdy),
    .lane_req_i(lane_req), .lane_done_i(lane_done), .lane_grant_o(lane_grant),
    .grant_log_o(grant_log), .grant_score_o(grant_score), .grant_node_o(grant_node),
    .grant_qepoch_o(grant_qep), .grant_pepoch_o(grant_pep),
    .pop_valid_o(pop_v), .pop_log_o(pop_log), .pop_score_o(pop_score), .pop_node_o(pop_nid),
    .fail_i(fail), .fail_log_i(fail_log), .ctx_alive_o(alive),
    .q_count_o(qcnt), .phys_lanes_o(phys), .logical_ctx_o(nlog), .n_way_o(nway),
    .lane_busy_o(lane_busy), .jobs_per_cycle_o(jobs_pc),
    .scheduler_idle_o(sch_idle), .scheduler_conflict_o(sch_conf),
    .queue_occupancy_o(q_occ), .queue_full_o(q_full),
    .starvation_count_o(starve), .drop_stale_o(drop_stale),
    .hot_we_i(hot_we), .hot_addr_i(hot_addr), .hot_log_i(hot_log_w),
    .hot_score_i(hot_score_w), .hot_node_i(hot_node_w),
    .hot_query_epoch_i(hot_qep_w), .hot_path_epoch_i(hot_pep_w),
    .hot_feed_en_i(hot_feed), .hot_ptr_o(hot_ptr)
  );

  initial begin
    done_o = 1'b0;
    util_pct_o = 0.0; jobs_per_cyc_o = 0.0; ready_duty_o = 0.0;
    busy_acc_o = 0; jobs_acc_o = 0; ready_acc_o = 0;
    starve_o = 0; sch_conf_acc_o = 0;
    max_jpc_o = 0; q_occ_end_o = 0;
    rst_n = 0; fail = 0; fail_log = 0;
    hot_we = 0; hot_feed = 0; hot_addr = 0;
    hot_log_w = 0; hot_score_w = 0; hot_node_w = 0;
    active_ep = 16'd1; hot_qep_w = 16'd1; hot_pep_w = 16'd1;
    push = '0; lane_req = '0; lane_done = '0;
    lfsr = BAG_SEED;
    burst_phase = 0;
    burst_on = 1'b1;
    for (int i = 0; i < N_WAY; i++) begin
      log_id[i] = '0; score[i] = '0; nid[i] = '0;
      qep[i] = 16'd1; pep[i] = 16'd1;
    end
    for (int i = 0; i < N_PHYS; i++) svc_left[i] = 0;

    wait (start_i === 1'b1);
    @(posedge clk);

    rst_n = 0;
    busy_sum = 0; job_sum = 0; conf_sum = 0; ready_sum = 0; mj = 0;
    hot_feed = 0; lane_req = 0; lane_done = 0; push = 0;
    active_ep = 16'd1; hot_qep_w = 16'd1; hot_pep_w = 16'd1;
    lfsr = BAG_SEED;
    burst_phase = 0;
    burst_on = 1'b1;
    for (int i = 0; i < N_PHYS; i++) svc_left[i] = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Prefill banks from on-chip hotset (NO DDR)
    hot_feed = 1'b1;
    repeat (32) @(posedge clk);

    for (cyc = 0; cyc < HORIZON; cyc++) begin
      @(negedge clk);
      lane_done = '0;
      lane_req  = '0;

      if (BAG_KIND == `A7NG_BAG_BURSTY) begin
        burst_phase = burst_phase + 1;
        if (burst_on && (burst_phase >= int'(READY_WIN))) begin
          burst_on = 1'b0;
          burst_phase = 0;
        end else if (!burst_on && (burst_phase >= int'(IDLE_WIN))) begin
          burst_on = 1'b1;
          burst_phase = 0;
        end
      end

      for (int i = 0; i < N_PHYS; i++) begin
        if (svc_left[i] > 0) begin
          svc_left[i] = svc_left[i] - 1;
          if (svc_left[i] == 0) lane_done[i] = 1'b1;
        end
        if (svc_left[i] == 0) begin
          case (BAG_KIND)
            `A7NG_BAG_ALWAYS: lane_req[i] = 1'b1;
            `A7NG_BAG_SPARSE: begin
              // Bernoulli p=0.5 per idle lane (bit0 of LFSR stream)
              lfsr = lfsr_next(lfsr);
              lane_req[i] = lfsr[0];
            end
            `A7NG_BAG_BURSTY: lane_req[i] = burst_on ? 1'b1 : 1'b0;
            default: lane_req[i] = 1'b1;
          endcase
        end
      end
      @(posedge clk);
      #1;
      begin
        automatic int pe_busy = 0;
        automatic int gcnt = 0;
        automatic int rcnt = 0;
        for (int i = 0; i < N_PHYS; i++) begin
          if (lane_req[i]) rcnt++;
          if (lane_grant[i]) begin
            svc_left[i] = SERVICE;
            gcnt++;
          end
          if ((svc_left[i] > 0) || lane_grant[i] || lane_busy[i]) pe_busy++;
        end
        busy_sum  += pe_busy;
        ready_sum += rcnt;
        // Authority = registered wide grant vector (not pop_valid_o)
        job_sum += gcnt;
        if (gcnt > mj) mj = gcnt;
        if (sch_conf) conf_sum++;
      end
    end

    hot_feed = 1'b0;
    util_pct_o     = (100.0 * busy_sum) / (1.0 * N_PHYS * HORIZON);
    jobs_per_cyc_o = (1.0 * job_sum) / (1.0 * HORIZON);
    ready_duty_o   = (100.0 * ready_sum) / (1.0 * N_PHYS * HORIZON);
    busy_acc_o     = busy_sum;
    jobs_acc_o     = job_sum;
    ready_acc_o    = ready_sum;
    starve_o       = longint'(starve);
    sch_conf_acc_o = conf_sum;
    max_jpc_o      = mj;
    q_occ_end_o    = int'(q_occ);
    $display("LADDER bag=%0d N_WAY=%0d util=%.2f%% ready_duty=%.2f%% busy_acc=%0d jobs_acc=%0d jobs/cyc=%.4f max_jpc=%0d starve=%0d q_occ=%0d sch_conf_acc=%0d jobs_pc_tele=%0d pop_v_dbg=%0d seed=0x%08h",
             BAG_KIND, N_WAY, util_pct_o, ready_duty_o, busy_acc_o, jobs_acc_o, jobs_per_cyc_o,
             max_jpc_o, starve_o, q_occ_end_o, sch_conf_acc_o, jobs_pc, pop_v, BAG_SEED);
    done_o = 1'b1;
  end
endmodule

// Preferred top: one N_WAY × one BAG per simulation, ungated free-running clock.
module tb_a7ng_wide_dispatch_top #(
  parameter int unsigned N_WAY     = 16,
  parameter int unsigned HORIZON   = 100000,
  parameter int unsigned SERVICE   = 1,
  parameter int unsigned BAG_KIND  = `A7NG_BAG_ALWAYS,
  parameter int unsigned BAG_SEED  = 32'hA7_06_16,
  parameter int unsigned READY_WIN = 64,
  parameter int unsigned IDLE_WIN  = 64
);
  logic clk;
  initial clk = 1'b0;
  always #5 clk = ~clk;  // never gate this clock

  logic start, done;
  real  util_pct, jobs_per_cyc, ready_duty;
  longint busy_acc, jobs_acc, ready_acc, starve, sch_conf_acc;
  int max_jpc, q_occ_end;
  integer fails;
  int min_jpc_req;
  string bag_name;

  a7ng_wide_rung #(
    .N_WAY(N_WAY), .HORIZON(HORIZON), .SERVICE(SERVICE),
    .BAG_KIND(BAG_KIND), .BAG_SEED(BAG_SEED),
    .READY_WIN(READY_WIN), .IDLE_WIN(IDLE_WIN)
  ) u_rung (
    .clk(clk), .start_i(start), .done_o(done),
    .util_pct_o(util_pct), .jobs_per_cyc_o(jobs_per_cyc), .ready_duty_o(ready_duty),
    .busy_acc_o(busy_acc), .jobs_acc_o(jobs_acc), .ready_acc_o(ready_acc),
    .starve_o(starve), .sch_conf_acc_o(sch_conf_acc),
    .max_jpc_o(max_jpc), .q_occ_end_o(q_occ_end)
  );

  initial begin
    fails = 0;
    start = 1'b0;
    case (BAG_KIND)
      `A7NG_BAG_ALWAYS: bag_name = "BAG_ALWAYS_READY";
      `A7NG_BAG_SPARSE: bag_name = "BAG_SPARSE_READY";
      `A7NG_BAG_BURSTY: bag_name = "BAG_BURSTY_READY";
      default:          bag_name = "BAG_UNKNOWN";
    endcase
    case (N_WAY)
      1:  min_jpc_req = 0;
      4:  min_jpc_req = 2;
      8:  min_jpc_req = 4;
      16: min_jpc_req = 8;
      default: min_jpc_req = 0;
    endcase

    repeat (2) @(posedge clk);
    start = 1'b1;
    wait (done);
    start = 1'b0;

    $display("RESULT bag=%s way=%0d util=%.2f%% ready_duty=%.2f%% jobs_acc=%0d jobs/cyc=%.4f max_jpc=%0d busy_acc=%0d starve=%0d q_occ=%0d sch_conf_acc=%0d",
             bag_name, N_WAY, util_pct, ready_duty, jobs_acc, jobs_per_cyc, max_jpc, busy_acc, starve, q_occ_end, sch_conf_acc);

    // --- Preregistered gates (FACT checks) ---
    // max_jpc ladder: applies to all bags (sparse/bursty must still peak when enough lanes ready)
    if (N_WAY == 1 && max_jpc > 1) begin
      $display("FAIL way=1 max_jpc=%0d (must <=1)", max_jpc); fails++;
    end
    if (N_WAY != 1 && max_jpc < min_jpc_req) begin
      $display("FAIL way=%0d max_jpc=%0d (must >=%0d)", N_WAY, max_jpc, min_jpc_req); fails++;
    end
    if (N_WAY == 16 && starve != 0) begin
      $display("FAIL starvation_count=%0d", starve); fails++;
    end
    if (jobs_acc <= 0) begin
      $display("FAIL jobs_acc=%0d (allocator produced no grants)", jobs_acc); fails++;
    end

    // Occupancy util≥80% is the ALWAYS_READY control gate only.
    // Sparse/bursty occupancy util is duty-bounded (FACT); do not lower ALWAYS gate (HS-17).
    if (BAG_KIND == `A7NG_BAG_ALWAYS && N_WAY == 16 && util_pct < 80.0) begin
      $display("FAIL util16=%.2f%% < 80%% (ALWAYS_READY control gate)", util_pct); fails++;
    end

    if (fails == 0)
      $display("A7NG06R_WIDE_XSIM_PASS bag=%s way=%0d util=%.2f ready_duty=%.2f max_jpc=%0d jobs_acc=%0d starve=%0d",
               bag_name, N_WAY, util_pct, ready_duty, max_jpc, jobs_acc, starve);
    else
      $display("A7NG06R_WIDE_XSIM_FAIL bag=%s way=%0d fails=%0d", bag_name, N_WAY, fails);
    $finish;
  end
endmodule

// Thin tops — separate elaboration/sim per rung×bag (no multi-DUT clock coupling)
// ALWAYS_READY control ladder
module tb_a7ng_wide_dispatch_way1;
  tb_a7ng_wide_dispatch_top #(.N_WAY(1),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_ALWAYS)) u ();
endmodule
module tb_a7ng_wide_dispatch_way4;
  tb_a7ng_wide_dispatch_top #(.N_WAY(4),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_ALWAYS)) u ();
endmodule
module tb_a7ng_wide_dispatch_way8;
  tb_a7ng_wide_dispatch_top #(.N_WAY(8),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_ALWAYS)) u ();
endmodule
module tb_a7ng_wide_dispatch_way16;
  tb_a7ng_wide_dispatch_top #(.N_WAY(16), .HORIZON(100000), .BAG_KIND(`A7NG_BAG_ALWAYS)) u ();
endmodule

// BAG_SPARSE_READY ladder (Bernoulli p=0.5, seed=0xA70616)
module tb_a7ng_wide_sparse_way1;
  tb_a7ng_wide_dispatch_top #(.N_WAY(1),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_SPARSE), .BAG_SEED(32'h00A70616)) u ();
endmodule
module tb_a7ng_wide_sparse_way4;
  tb_a7ng_wide_dispatch_top #(.N_WAY(4),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_SPARSE), .BAG_SEED(32'h00A70616)) u ();
endmodule
module tb_a7ng_wide_sparse_way8;
  tb_a7ng_wide_dispatch_top #(.N_WAY(8),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_SPARSE), .BAG_SEED(32'h00A70616)) u ();
endmodule
module tb_a7ng_wide_sparse_way16;
  tb_a7ng_wide_dispatch_top #(.N_WAY(16), .HORIZON(100000), .BAG_KIND(`A7NG_BAG_SPARSE), .BAG_SEED(32'h00A70616)) u ();
endmodule

// BAG_BURSTY_READY ladder (64 on / 64 off)
module tb_a7ng_wide_bursty_way1;
  tb_a7ng_wide_dispatch_top #(.N_WAY(1),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_BURSTY)) u ();
endmodule
module tb_a7ng_wide_bursty_way4;
  tb_a7ng_wide_dispatch_top #(.N_WAY(4),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_BURSTY)) u ();
endmodule
module tb_a7ng_wide_bursty_way8;
  tb_a7ng_wide_dispatch_top #(.N_WAY(8),  .HORIZON(100000), .BAG_KIND(`A7NG_BAG_BURSTY)) u ();
endmodule
module tb_a7ng_wide_bursty_way16;
  tb_a7ng_wide_dispatch_top #(.N_WAY(16), .HORIZON(100000), .BAG_KIND(`A7NG_BAG_BURSTY)) u ();
endmodule

// Default alias → way16 ALWAYS (control)
module tb_a7ng_wide_dispatch;
  tb_a7ng_wide_dispatch_way16 u ();
endmodule
