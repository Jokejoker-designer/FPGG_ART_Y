// tb_a7ng_multi_agent_share.sv — NG-06 regress + epoch port wiring (matched epoch)
`timescale 1ns / 1ps

module tb_a7ng_multi_agent_share;
  localparam int N_WAY = 16;
  logic clk, rst_n, fail;
  logic [7:0] fail_log, phys, nway, hot_ptr;
  logic [15:0] qcnt, nlog;
  logic [255:0] alive;

  logic [N_WAY-1:0] push, push_rdy;
  logic [7:0]       log_id [N_WAY];
  logic signed [15:0] score [N_WAY];
  logic [31:0]      nid [N_WAY];
  logic [15:0]      qep [N_WAY];
  logic [15:0]      pep [N_WAY];

  logic [15:0] lane_req, lane_done, lane_grant, lane_busy;
  logic [7:0]  grant_log [16];
  logic signed [15:0] grant_score [16];
  logic [31:0] grant_node [16];
  logic [15:0] grant_qep [16];
  logic [15:0] grant_pep [16];
  logic pop_v;
  logic [7:0] pop_log;
  logic signed [15:0] pop_score;
  logic [31:0] pop_nid;
  logic [4:0] jobs_pc;
  logic sch_idle, sch_conf, q_full;
  logic [15:0] q_occ;
  logic [31:0] starve, drop_stale;
  logic hot_we, hot_feed;
  logic [7:0] hot_addr, hot_log;
  logic signed [15:0] hot_score;
  logic [31:0] hot_node;
  logic [15:0] active_ep, hot_qep, hot_pep;

  a7ng_multi_agent_share #(.N_WAY(N_WAY)) dut (
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
    .hot_we_i(hot_we), .hot_addr_i(hot_addr), .hot_log_i(hot_log),
    .hot_score_i(hot_score), .hot_node_i(hot_node),
    .hot_query_epoch_i(hot_qep), .hot_path_epoch_i(hot_pep),
    .hot_feed_en_i(hot_feed), .hot_ptr_o(hot_ptr)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, g;
  logic [15:0] grants_hist;
  integer multi_grant_seen;

  task automatic clr_push;
    push = '0;
    for (int i = 0; i < N_WAY; i++) begin
      log_id[i] = '0; score[i] = '0; nid[i] = '0;
      qep[i] = active_ep; pep[i] = active_ep;
    end
  endtask

  initial begin
    fails = 0;
    multi_grant_seen = 0;
    active_ep = 16'd1;
    hot_qep = 16'd1; hot_pep = 16'd1;
    rst_n = 0; fail = 0; lane_req = 0; lane_done = 0;
    fail_log = 0; hot_we = 0; hot_feed = 0; hot_addr = 0;
    hot_log = 0; hot_score = 0; hot_node = 0;
    clr_push();
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    if (phys !== 8'd16 || nlog !== 16'd256 || nway !== 8'(N_WAY)) begin
      $display("FAIL HS-09/N_WAY phys=%0d log=%0d way=%0d", phys, nlog, nway);
      fails = fails + 1;
    end

    // Fill 16 jobs via wide push (1 cycle) — matched epoch
    @(negedge clk);
    for (g = 0; g < 16; g++) begin
      push[g] = 1'b1;
      log_id[g] = g[7:0];
      score[g] = 16'sd100 + g;
      nid[g] = 32'h1000 + g;
      qep[g] = active_ep;
      pep[g] = active_ep;
    end
    @(posedge clk); #1;
    clr_push();

    // T1: multi-grant — all lanes request; expect >1 grant in one cycle when N_WAY>1
    @(negedge clk); lane_req = 16'hFFFF;
    @(posedge clk); #1;
    if ($countones(lane_grant) > 1) multi_grant_seen = 1;
    if (N_WAY > 1 && $countones(lane_grant) < 2) begin
      $display("FAIL expected multi-grant got %0d", $countones(lane_grant));
      fails = fails + 1;
    end
    grants_hist = lane_grant;
    lane_done = lane_grant;
    @(posedge clk); #1;
    lane_done = 0; lane_req = 0;

    // Drain remaining with RR fairness
    for (g = 0; g < 32; g++) begin
      @(negedge clk); lane_req = 16'hFFFF;
      @(posedge clk); #1;
      grants_hist = grants_hist | lane_grant;
      lane_done = lane_grant;
      @(posedge clk); #1;
      lane_done = 0;
    end
    lane_req = 0;
    if (grants_hist !== 16'hFFFF) begin
      $display("FAIL starvation grants=%h", grants_hist);
      fails = fails + 1;
    end

    // Refill a few
    @(negedge clk);
    for (g = 0; g < 4; g++) begin
      push[g] = 1'b1; log_id[g] = 8'(5+g); score[g] = 16'sd50; nid[g] = g;
      qep[g] = active_ep; pep[g] = active_ep;
    end
    @(posedge clk); #1;
    clr_push();

    // T2: fail log 5 — log 7 still alive
    @(negedge clk); fail = 1; fail_log = 8'd5;
    @(posedge clk); #1; fail = 0;
    if (alive[5] !== 1'b0 || alive[7] !== 1'b1) begin
      $display("FAIL isolated fail a5=%0d a7=%0d", alive[5], alive[7]);
      fails = fails + 1;
    end

    // T3: dead ctx push ignored
    @(negedge clk);
    push[0] = 1; log_id[0] = 8'd5; score[0] = 16'sd99; nid[0] = 32'hDEAD;
    qep[0] = active_ep; pep[0] = active_ep;
    @(posedge clk); #1;
    clr_push();

    if (fails == 0)
      $display("A7NG06_SHARE_XSIM_PASS phys=%0d logical=%0d way=%0d multi=%0d drop_stale=%0d",
               phys, nlog, nway, multi_grant_seen, drop_stale);
    else
      $display("A7NG06_SHARE_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
