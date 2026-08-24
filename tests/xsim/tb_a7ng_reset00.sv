// tb_a7ng_reset00.sv — A7-NATIVE-RESET-00 logical QUERY + TRAIN bags (RST-01 / RST-03)
// UNKNOWN: can epoch/generation + pointer reset make old WM non-authoritative
//           without physical BRAM wipe and without touching LM-06?
// H_CANDIDATE: QUERY_RESET / TRAIN generation bump suffices (RESET plan §§2–7)
// H_RIVAL: old generation still accepted after bump; OR reset wipes LM-06
// FALSIFIER: auth_valid>0 after QUERY; learned_visible>0 after TRAIN; LM SHA changed
// UNIT: reset event / training generation bag — not cycles-as-queries
// CONTROL: lm_frozen_intact_i=1 (file SHA LM-06 checked outside RTL)
`timescale 1ns / 1ps

module tb_a7ng_reset00;
  localparam logic [1:0] LVL_QUERY = 2'd0;
  localparam logic [1:0] LVL_TRAIN = 2'd2;
  localparam logic [1:0] LVL_HARD  = 2'd3;

  logic clk, rst_n;
  logic reset_req;
  logic [1:0] reset_level;
  logic lm_ok;
  logic wm_wr;
  logic [31:0] wm_node, wm_pay;
  logic learn_c;
  logic [31:0] learn_node;
  logic [15:0] learn_score;

  logic busy, done, err;
  logic [15:0] qep, pep;
  logic [31:0] tgen;
  logic [15:0] wm_auth, wm_phys, wm_work;
  logic [15:0] learn_vis, learn_phys, learn_old_phys;
  logic vpass, vfail;
  logic [31:0] vcode, cyc_last, cnt_q, cnt_t;

  int fails;
  int bag_fail;

  a7ng_reset00_top dut (
    .clk(clk), .rst_n(rst_n),
    .reset_req_i(reset_req), .reset_level_i(reset_level),
    .lm_frozen_intact_i(lm_ok),
    .wm_write_i(wm_wr), .wm_node_i(wm_node), .wm_payload_i(wm_pay),
    .learn_commit_i(learn_c), .learn_node_i(learn_node), .learn_score_i(learn_score),
    .reset_busy_o(busy), .reset_done_o(done), .reset_error_o(err),
    .query_epoch_o(qep), .path_epoch_o(pep), .training_generation_o(tgen),
    .wm_auth_valid_count_o(wm_auth), .wm_physical_valid_count_o(wm_phys),
    .wm_workset_count_o(wm_work),
    .learned_visible_count_o(learn_vis),
    .learned_physical_count_o(learn_phys),
    .learned_old_gen_physical_count_o(learn_old_phys),
    .verify_pass_o(vpass), .verify_fail_o(vfail), .verify_fail_code_o(vcode),
    .reset_cycles_last_o(cyc_last),
    .reset_count_query_o(cnt_q), .reset_count_train_o(cnt_t)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic do_reset(input logic [1:0] lvl);
    begin
      @(negedge clk);
      reset_level = lvl;
      reset_req   = 1'b1;
      @(negedge clk);
      reset_req   = 1'b0;
      // Wait for done or error
      begin : wait_done
        int guard;
        guard = 0;
        while (!done && !err && guard < 100) begin
          @(posedge clk);
          guard = guard + 1;
        end
        if (guard >= 100) begin
          $display("FAIL timeout level=%0d", lvl);
          bag_fail = bag_fail + 1;
        end
      end
      @(posedge clk);
    end
  endtask

  // -------- RST-01 QUERY_RESET --------
  task automatic bag_rst01_query;
    logic [15:0] ep_before;
    logic [31:0] gen_before;
    begin
      bag_fail = 0;
      $display("BAG RST-01 QUERY_RESET start");
      ep_before  = qep;
      gen_before = tgen;

      // Populate WM working set
      for (int i = 0; i < 8; i++) begin
        @(negedge clk);
        wm_wr   = 1'b1;
        wm_node = 32'hA100_0000 + i;
        wm_pay  = 32'hDEAD_0000 + i;
        learn_c = 1'b0;
      end
      @(negedge clk);
      wm_wr = 1'b0;

      // Also commit a learned binding that must SURVIVE query reset
      @(negedge clk);
      learn_c     = 1'b1;
      learn_node  = 32'hB200_0042;
      learn_score = 16'h00AA;
      @(negedge clk);
      learn_c = 1'b0;
      @(posedge clk);

      if (wm_auth != 16'd8) begin
        $display("FAIL RST-01 pre auth=%0d want 8", wm_auth);
        bag_fail = bag_fail + 1;
      end
      if (learn_vis < 16'd1) begin
        $display("FAIL RST-01 pre learn_vis=%0d", learn_vis);
        bag_fail = bag_fail + 1;
      end

      do_reset(LVL_QUERY);

      if (err) begin
        $display("FAIL RST-01 unexpected error");
        bag_fail = bag_fail + 1;
      end
      if (wm_auth != 16'd0) begin
        $display("FAIL RST-01 auth_valid=%0d (stale accepted)", wm_auth);
        bag_fail = bag_fail + 1;
      end
      if (wm_work != 16'd0) begin
        $display("FAIL RST-01 workset=%0d", wm_work);
        bag_fail = bag_fail + 1;
      end
      // Physical remnants OK — prove no scrub required
      if (wm_phys == 16'd0) begin
        $display("FAIL RST-01 expected physical remnant >0 got 0 (scrub happened?)");
        bag_fail = bag_fail + 1;
      end
      if (qep != (ep_before + 16'd1)) begin
        $display("FAIL RST-01 epoch %0d -> %0d", ep_before, qep);
        bag_fail = bag_fail + 1;
      end
      if (tgen != gen_before) begin
        $display("FAIL RST-01 train gen changed on QUERY %0d", tgen);
        bag_fail = bag_fail + 1;
      end
      if (learn_vis < 16'd1) begin
        $display("FAIL RST-01 learned wiped on QUERY vis=%0d", learn_vis);
        bag_fail = bag_fail + 1;
      end
      if (cyc_last == 32'd0 || cyc_last > 32'd16) begin
        $display("FAIL RST-01 cycles/query_reset=%0d (want small fixed)", cyc_last);
        bag_fail = bag_fail + 1;
      end
      if (!lm_ok) begin
        $display("FAIL RST-01 LM control broken");
        bag_fail = bag_fail + 1;
      end

      if (bag_fail == 0)
        $display("RST-01 PASS auth=0 phys=%0d work=0 ep=%0d learn_vis=%0d cyc=%0d",
                 wm_phys, qep, learn_vis, cyc_last);
      else begin
        $display("RST-01 FAIL count=%0d vcode=%0h", bag_fail, vcode);
        fails = fails + bag_fail;
      end
    end
  endtask

  // -------- RST-03 TRAINING generation bump --------
  task automatic bag_rst03_train;
    logic [31:0] gen_before;
    logic [15:0] learn_phys_before;
    begin
      bag_fail = 0;
      $display("BAG RST-03 TRAIN generation start");
      gen_before = tgen;

      // Fill learned records under generation N
      for (int i = 0; i < 12; i++) begin
        @(negedge clk);
        learn_c     = 1'b1;
        learn_node  = 32'hC300_0000 + i;
        learn_score = 16'h0100 + i[15:0];
        wm_wr       = 1'b0;
      end
      @(negedge clk);
      learn_c = 1'b0;

      // Also fill some WM under gen N
      for (int i = 0; i < 4; i++) begin
        @(negedge clk);
        wm_wr   = 1'b1;
        wm_node = 32'hD400_0000 + i;
        wm_pay  = 32'hBEEF_0000 + i;
      end
      @(negedge clk);
      wm_wr = 1'b0;
      @(posedge clk);

      if (learn_vis < 16'd12) begin
        $display("FAIL RST-03 pre learn_vis=%0d", learn_vis);
        bag_fail = bag_fail + 1;
      end
      learn_phys_before = learn_phys;

      do_reset(LVL_TRAIN);

      if (err) begin
        $display("FAIL RST-03 unexpected error");
        bag_fail = bag_fail + 1;
      end
      if (tgen != (gen_before + 32'd1)) begin
        $display("FAIL RST-03 gen %0d -> %0d", gen_before, tgen);
        bag_fail = bag_fail + 1;
      end
      if (wm_auth != 16'd0) begin
        $display("FAIL RST-03 wm auth_valid=%0d", wm_auth);
        bag_fail = bag_fail + 1;
      end
      if (learn_vis != 16'd0) begin
        $display("FAIL RST-03 learned still visible=%0d (old gen accepted)", learn_vis);
        bag_fail = bag_fail + 1;
      end
      // Physical remnants prove no full scrub
      if (learn_phys < learn_phys_before) begin
        $display("FAIL RST-03 physical scrub detected phys %0d -> %0d",
                 learn_phys_before, learn_phys);
        bag_fail = bag_fail + 1;
      end
      if (learn_old_phys == 16'd0) begin
        $display("FAIL RST-03 expected physical old-gen remnant >0");
        bag_fail = bag_fail + 1;
      end
      // Metric name in plan: old_generation_visible_count==0 after authority cut
      // (visible = accepted; we check learn_vis==0 above)
      if (!lm_ok) begin
        $display("FAIL RST-03 LM wiped/control fail — DESIGN ERROR");
        bag_fail = bag_fail + 1;
      end

      // New gen write must become visible
      @(negedge clk);
      learn_c     = 1'b1;
      learn_node  = 32'hE500_0099;
      learn_score = 16'h2222;
      @(negedge clk);
      learn_c = 1'b0;
      @(posedge clk);
      if (learn_vis < 16'd1) begin
        $display("FAIL RST-03 new gen not visible");
        bag_fail = bag_fail + 1;
      end

      if (bag_fail == 0)
        $display("RST-03 PASS gen=%0d learn_vis=0 learn_phys=%0d old_phys=%0d new_vis=%0d cyc=%0d",
                 tgen, learn_phys, learn_old_phys, learn_vis, cyc_last);
      else begin
        $display("RST-03 FAIL count=%0d vcode=%0h", bag_fail, vcode);
        fails = fails + bag_fail;
      end
    end
  endtask

  // HARD must error (unsupported this gate — no fake scrub PASS)
  task automatic bag_hard_reject;
    begin
      bag_fail = 0;
      $display("BAG HARD reject (expected error)");
      @(negedge clk);
      reset_level = LVL_HARD;
      reset_req   = 1'b1;
      @(negedge clk);
      reset_req = 1'b0;
      repeat (5) @(posedge clk);
      if (!err) begin
        $display("FAIL HARD should error this gate");
        bag_fail = bag_fail + 1;
        fails = fails + 1;
      end else
        $display("HARD reject PASS (error as designed)");
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 0;
    reset_req = 0;
    reset_level = LVL_QUERY;
    lm_ok = 1'b1; // CONTROL: TB asserts LM-06 intact (SHA checked in archive script)
    wm_wr = 0;
    wm_node = 0;
    wm_pay = 0;
    learn_c = 0;
    learn_node = 0;
    learn_score = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    bag_rst01_query();
    bag_rst03_train();
    bag_hard_reject();

    if (fails == 0) begin
      $display("A7NG_RESET00_XSIM_PASS");
      $display("METRICS cnt_query=%0d cnt_train=%0d", cnt_q, cnt_t);
      $display("CONTROL lm_frozen_intact=1");
    end else begin
      $display("A7NG_RESET00_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
