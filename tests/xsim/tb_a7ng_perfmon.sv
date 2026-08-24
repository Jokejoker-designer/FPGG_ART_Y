// tb_a7ng_perfmon.sv — PERFMON-lite smoke (instrumentation only)
// Unknown: counters expose preregistered metrics without changing share/frontier law.
// Control: share SHA 4413C74B… untouched; regress share TB separately.
`timescale 1ns / 1ps

module tb_a7ng_perfmon;
  localparam int N_WAY  = 16;
  localparam int N_PHYS = 16;
  localparam int K      = 8;

  logic clk, rst_n, clear, enable;
  integer fails;

  // -------- Share DUT (law unchanged) --------
  logic [15:0] active_ep;
  logic [N_WAY-1:0] push, push_rdy;
  logic [7:0] log_id [N_WAY];
  logic signed [15:0] score [N_WAY];
  logic [31:0] nid [N_WAY];
  logic [15:0] qep [N_WAY], pep [N_WAY];
  logic [15:0] lane_req, lane_done, lane_grant, lane_busy;
  logic [7:0] grant_log [N_PHYS];
  logic signed [15:0] grant_score [N_PHYS];
  logic [31:0] grant_node [N_PHYS];
  logic [15:0] grant_qep [N_PHYS], grant_pep [N_PHYS];
  logic pop_v;
  logic [7:0] pop_log, phys, nway, hot_ptr;
  logic signed [15:0] pop_score;
  logic [31:0] pop_nid;
  logic fail;
  logic [7:0] fail_log;
  logic [255:0] alive;
  logic [15:0] qcnt, nlog, q_occ;
  logic [4:0] jobs_pc;
  logic sch_idle, sch_conf, q_full;
  logic [31:0] starve, drop_stale;
  logic hot_we, hot_feed;
  logic [7:0] hot_addr, hot_log;
  logic signed [15:0] hot_score;
  logic [31:0] hot_node;
  logic [15:0] hot_qep, hot_pep;

  a7ng_multi_agent_share #(.N_WAY(N_WAY)) u_share (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(active_ep),
    .push_i(push), .log_id_i(log_id), .score_i(score), .node_id_i(nid),
    .query_epoch_i(qep), .path_epoch_i(pep), .push_ready_o(push_rdy),
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

  // -------- Frontier DUT --------
  logic fr_push, fr_pop, fr_pop_v, fr_ovf, fr_rdy;
  logic signed [15:0] fr_score_i, fr_score_o;
  logic [31:0] fr_id_i, fr_id_o;
  logic [7:0] fr_cnt;

  a7ng_frontier_buckets u_fr (
    .clk(clk), .rst_n(rst_n),
    .push_i(fr_push), .score_i(fr_score_i), .id_i(fr_id_i),
    .pop_i(fr_pop), .pop_valid_o(fr_pop_v),
    .score_o(fr_score_o), .id_o(fr_id_o),
    .overflow_o(fr_ovf), .ready_o(fr_rdy), .count_o(fr_cnt)
  );

  // -------- Top-K DUT (pkg scores) --------
  logic tk_valid_i, tk_valid_o;
  logic [15:0] tk_mask;
  a7ng_pkg::score_t tk_score_i [16];
  a7ng_pkg::node_id_t tk_id_i [16];
  a7ng_pkg::score_t tk_score_o [K];
  a7ng_pkg::node_id_t tk_id_o [K];

  a7ng_topk #(.N(16), .K(K)) u_tk (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tk_valid_i), .valid_mask_i(tk_mask),
    .score_i(tk_score_i), .id_i(tk_id_i),
    .valid_o(tk_valid_o), .score_o(tk_score_o), .id_o(tk_id_o)
  );

  function automatic logic [4:0] popc16(input logic [15:0] m);
    logic [4:0] n;
    n = 5'd0;
    for (int i = 0; i < 16; i++) if (m[i]) n = n + 5'd1;
    return n;
  endfunction

  // -------- PERFMON observer --------
  logic [31:0] cyc_tot, jobs_acc, qocc_acc, qfull_c, idle_c, conf_c, grants;
  logic [31:0] starve_s, stale_s, fr_push_c, fr_pop_c, fr_full_c;
  logic [31:0] tk_bat, cand_in, cand_out;
  logic [31:0] lane_busy_acc [N_PHYS];

  a7ng_perfmon #(.N_PHYS(N_PHYS)) u_pm (
    .clk(clk), .rst_n(rst_n), .clear_i(clear), .enable_i(enable),
    .lane_busy_i(lane_busy),
    .jobs_per_cycle_i(jobs_pc),
    .queue_occupancy_i(q_occ),
    .queue_full_i(q_full),
    .scheduler_idle_i(sch_idle),
    .scheduler_conflict_i(sch_conf),
    .starvation_count_i(starve),
    .drop_stale_i(drop_stale),
    .frontier_push_fire_i(fr_push && fr_rdy),
    .frontier_pop_fire_i(fr_pop_v),
    .frontier_full_pulse_i(fr_ovf),
    .topk_batch_fire_i(tk_valid_i),
    .candidates_in_i(popc16(tk_mask)),
    .candidates_out_i(4'(K)),
    .cycles_total_o(cyc_tot),
    .lane_busy_accum_o(lane_busy_acc),
    .jobs_accum_o(jobs_acc),
    .queue_occ_accum_o(qocc_acc),
    .queue_full_cycles_o(qfull_c),
    .scheduler_idle_cycles_o(idle_c),
    .scheduler_conflict_cycles_o(conf_c),
    .scheduler_grants_o(grants),
    .starve_sample_o(starve_s),
    .stale_drop_sample_o(stale_s),
    .frontier_push_o(fr_push_c),
    .frontier_pop_o(fr_pop_c),
    .frontier_full_o(fr_full_c),
    .topk_batches_o(tk_bat),
    .candidates_in_accum_o(cand_in),
    .candidates_out_accum_o(cand_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic clr_push;
    push = '0;
    for (int i = 0; i < N_WAY; i++) begin
      log_id[i] = '0; score[i] = '0; nid[i] = '0;
      qep[i] = active_ep; pep[i] = active_ep;
    end
  endtask

  integer g, i, svc_left [N_PHYS];

  initial begin
    fails = 0;
    active_ep = 16'd1;
    hot_qep = 16'd1; hot_pep = 16'd1;
    rst_n = 0; clear = 0; enable = 0;
    fail = 0; fail_log = 0;
    lane_req = 0; lane_done = 0;
    hot_we = 0; hot_feed = 0; hot_addr = 0;
    hot_log = 0; hot_score = 0; hot_node = 0;
    fr_push = 0; fr_pop = 0; fr_score_i = 0; fr_id_i = 0;
    tk_valid_i = 0; tk_mask = 0;
    for (i = 0; i < 16; i++) begin
      tk_score_i[i] = 0; tk_id_i[i] = 0;
    end
    for (i = 0; i < N_PHYS; i++) svc_left[i] = 0;
    clr_push();

    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Clear + enable PERFMON
    @(negedge clk);
    clear = 1;
    @(posedge clk);
    @(negedge clk);
    clear = 0;
    enable = 1;

    // ---- Traffic bag: wide matched-epoch share + frontier + topk ----
    // UNIT = this bag / seed (seed=1), not cycles-as-queries.
    @(negedge clk);
    for (g = 0; g < 16; g++) begin
      push[g] = 1'b1;
      log_id[g] = g[7:0];
      score[g] = 16'sd200 + g;
      nid[g] = 32'h2000 + g;
      qep[g] = active_ep;
      pep[g] = active_ep;
    end
    lane_req = 16'hFFFF;
    @(posedge clk);
    @(negedge clk);
    clr_push();

    // Service grants for ~64 cycles; inject stale DROP once
    for (i = 0; i < 64; i++) begin
      @(negedge clk);
      lane_done = 16'd0;
      for (g = 0; g < N_PHYS; g++) begin
        if (lane_grant[g]) svc_left[g] = 2;
        if (svc_left[g] > 0) begin
          svc_left[g] = svc_left[g] - 1;
          if (svc_left[g] == 0) lane_done[g] = 1'b1;
        end
        lane_req[g] = (svc_left[g] == 0);
      end
      // Mid-bag: push one stale-epoch job so DROP_STALE increments
      if (i == 8) begin
        push[0] = 1'b1;
        log_id[0] = 8'd32;
        score[0] = 16'sd50;
        nid[0] = 32'hDEAD;
        qep[0] = 16'd9; // != active
        pep[0] = 16'd9;
      end else if (i == 9) begin
        push[0] = 1'b0;
      end
      // Frontier activity
      fr_push = (i < 20);
      fr_score_i = 16'sd1000 - i[15:0];
      fr_id_i = 32'(i);
      fr_pop = (i >= 10) && (i < 30);
      // Top-K batch every 8 cycles
      if ((i % 8) == 0) begin
        tk_valid_i = 1'b1;
        tk_mask = 16'hFFFF;
        for (g = 0; g < 16; g++) begin
          tk_score_i[g] = a7ng_pkg::score_t'(16'sd10 + g);
          tk_id_i[g] = a7ng_pkg::node_id_t'(32'h100 + g);
        end
      end else begin
        tk_valid_i = 1'b0;
      end
      @(posedge clk);
    end

    @(negedge clk);
    enable = 0;
    fr_push = 0; fr_pop = 0; tk_valid_i = 0; lane_req = 0; clr_push();
    @(posedge clk);
    @(posedge clk);

    // ---- Assertions (preregistered §21 subset) ----
    if (cyc_tot == 32'd0) begin
      $display("FAIL cycles_total=0"); fails = fails + 1;
    end
    if (jobs_acc == 32'd0 || grants == 32'd0) begin
      $display("FAIL jobs/grants=0 jobs=%0d grants=%0d", jobs_acc, grants);
      fails = fails + 1;
    end
    if (qocc_acc == 32'd0) begin
      $display("FAIL queue_occ_accum=0"); fails = fails + 1;
    end
    begin
      automatic int busy_any = 0;
      for (g = 0; g < N_PHYS; g++)
        if (lane_busy_acc[g] != 0) busy_any = 1;
      if (!busy_any) begin
        $display("FAIL lane_busy_accum all zero"); fails = fails + 1;
      end
    end
    if (idle_c == 32'd0 && conf_c == 32'd0 && jobs_acc == 32'd0) begin
      $display("FAIL scheduler idle/conflict/jobs all zero"); fails = fails + 1;
    end
    // idle OR grants must move under this bag
    if (idle_c == 32'd0 && grants == 32'd0) begin
      $display("FAIL no scheduler_idle and no grants"); fails = fails + 1;
    end
    if (stale_s == 32'd0) begin
      $display("FAIL stale_drop_sample=0 (expected DROP_STALE>0)"); fails = fails + 1;
    end
    if (fr_push_c == 32'd0 || fr_pop_c == 32'd0) begin
      $display("FAIL frontier push/pop push=%0d pop=%0d", fr_push_c, fr_pop_c);
      fails = fails + 1;
    end
    if (tk_bat == 32'd0 || cand_in == 32'd0 || cand_out == 32'd0) begin
      $display("FAIL topk bat=%0d in=%0d out=%0d", tk_bat, cand_in, cand_out);
      fails = fails + 1;
    end
    // Law id / HS-09 sanity on share
    if (phys !== 8'd16 || nlog !== 16'd256) begin
      $display("FAIL HS-09 phys/log"); fails = fails + 1;
    end
    if (&alive !== 1'b1) begin
      $display("FAIL HS-07 wipe alive!=all1"); fails = fails + 1;
    end

    $display("PERFMON_DUMP cycles=%0d jobs=%0d qocc_acc=%0d idle=%0d conf=%0d starve=%0d stale=%0d",
             cyc_tot, jobs_acc, qocc_acc, idle_c, conf_c, starve_s, stale_s);
    $display("PERFMON_DUMP fr_push=%0d fr_pop=%0d fr_full=%0d tk_bat=%0d cand_in=%0d cand_out=%0d",
             fr_push_c, fr_pop_c, fr_full_c, tk_bat, cand_in, cand_out);
    for (g = 0; g < N_PHYS; g++)
      $display("PERFMON_LANE busy_acc[%0d]=%0d", g, lane_busy_acc[g]);

    if (fails == 0) begin
      $display("A7NG_PERFMON_XSIM_PASS");
    end else begin
      $display("A7NG_PERFMON_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
