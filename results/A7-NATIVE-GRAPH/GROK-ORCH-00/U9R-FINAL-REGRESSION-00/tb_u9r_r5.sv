// tb_u9r_r5.sv — U9R R5 learned-state: freeze, duplicate, full NAK, train_reset retrain.
// From-zero law: +3 then train_reset then +1 same key must be +1, not +4.
// PROGRAM=NO. Cycle watchdog.
`timescale 1ns / 1ps

module tb_u9r_r5;
  import a7ng_pkg::*;
  localparam int unsigned WATCH_CYC = 400000;

  logic clk, rst_n, learn, freeze, flush, reload, kill, trst;
  logic pbusy, pdone, pnak, boot_done;
  logic [31:0] live_gen;
  logic upd_v, upd_r, lk_go, lk_busy, lk_done, lk_hit;
  logic [31:0] us, uo, ls, lo;
  logic [7:0] ur, lr;
  logic signed [3:0] urew;
  logic uk;
  logic signed [7:0] lk_pri, lk_pen;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [15:0] c7seq, c7cnt;
  integer cyc, tmo, i, fails;
  logic saw_done, saw_nak;

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(clk), .rst_n(rst_n),
    .learn_i(learn), .freeze_i(freeze),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .live_gen_o(live_gen), .sdig_o(), .wrap_imminent_o(),
    .upd_valid_i(upd_v), .upd_ready_o(upd_r),
    .upd_subj_i(us), .upd_rel_i(ur), .upd_obj_i(uo),
    .upd_rew_i(urew), .upd_contra_i(uk),
    .lk_go_i(lk_go), .lk_subj_i(ls), .lk_rel_i(lr), .lk_obj_i(lo),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(), .c7_ack_ready_i(1'b1),
    .c7_addr_o(), .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ddr_ack <= 1'b0;
    else ddr_ack <= ddr_req;
  end
  assign ddr_rdata = 64'd0;

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", c, d, cyc);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  task automatic wait_boot;
    begin
      tmo = 0;
      while (!boot_done && tmo < 40000) begin @(posedge clk); tmo++; end
      if (!boot_done) diverge("TIMEOUT", "boot_done");
      tmo = 0;
      while (pbusy && tmo < 40000) begin @(posedge clk); tmo++; end
    end
  endtask

  task automatic issue_upd(input logic [31:0] s, input logic [31:0] o, input logic signed [3:0] r);
    begin
      tmo = 0;
      while (!upd_r && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!upd_r) diverge("TIMEOUT", "upd_ready");
      @(negedge clk);
      us = s; ur = 8'd1; uo = o; urew = r; uk = 1'b0; upd_v = 1'b1;
      @(posedge clk); @(negedge clk); upd_v = 1'b0;
      saw_done = 0; saw_nak = 0;
      tmo = 0;
      while (!saw_done && !saw_nak && tmo < 8000) begin
        @(posedge clk);
        if (pdone) saw_done = 1;
        if (pnak) saw_nak = 1;
        tmo++;
      end
      if (!saw_done && !saw_nak) diverge("TIMEOUT", "upd done/nak");
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while ((pbusy || lk_busy) && tmo < 8000) begin @(posedge clk); tmo++; end
      @(negedge clk); ls = s; lr = 8'd1; lo = o; lk_go = 1'b1;
      @(posedge clk); @(negedge clk); lk_go = 1'b0;
      tmo = 0;
      while (!lk_done && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!lk_done) diverge("TIMEOUT", "lookup");
      @(posedge clk);
    end
  endtask

  initial begin
    fails = 0; rst_n = 0; learn = 1; freeze = 0;
    flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; lk_go = 0; us = 0; uo = 0; ur = 1; urew = 0; uk = 0;
    ls = 0; lo = 0; lr = 1;
    repeat (8) @(posedge clk); rst_n = 1;
    wait_boot();
    $display("R5_BOOT gen=%0d", live_gen);

    freeze = 1;
    @(posedge clk);
    if (upd_r) diverge("FREEZE", "upd_ready must drop");
    $display("R5_FREEZE PASS upd_ready=0");
    freeze = 0;
    @(posedge clk);

    issue_upd(32'hA001, 32'hB001, 4'sd1);
    if (!saw_done) diverge("DUP_SETUP", "first write");
    issue_upd(32'hA001, 32'hB001, 4'sd1);
    if (!saw_done) diverge("DUPLICATE", "same-key must update");
    do_lk(32'hA001, 32'hB001);
    if (!lk_hit || lk_pri !== 8'sd2)
      diverge("DUPLICATE", $sformatf("pri=%0d hit=%0d expect 2", lk_pri, lk_hit));
    $display("R5_DUPLICATE PASS pri=2 same slot");

    // Isolated from-zero before filling the 32-slot store.
    issue_upd(32'hC0DE, 32'hF00D, 4'sd3);
    do_lk(32'hC0DE, 32'hF00D);
    if (!lk_hit || lk_pri !== 8'sd3)
      diverge("RESET_SETUP", $sformatf("pri=%0d", lk_pri));
    $display("R5_PRE_RESET pri=%0d gen=%0d", lk_pri, live_gen);
    @(negedge clk); trst = 1;
    @(posedge clk); @(negedge clk); trst = 0;
    tmo = 0;
    while (pbusy && tmo < 8000) begin @(posedge clk); tmo++; end
    do_lk(32'hC0DE, 32'hF00D);
    $display("R5_POST_RESET hit=%0d pri=%0d gen=%0d (lookup uses vis_w)", lk_hit, lk_pri, live_gen);
    issue_upd(32'hC0DE, 32'hF00D, 4'sd1);
    if (!saw_done) diverge("RESET_RETRAIN", "post-reset write");
    do_lk(32'hC0DE, 32'hF00D);
    $display("R5_RETRAIN hit=%0d pri=%0d gen=%0d (from-zero law wants pri=1)", lk_hit, lk_pri, live_gen);
    if (!lk_hit) diverge("RESET_RETRAIN", "miss after retrain");
    if (lk_pri !== 8'sd1)
      diverge("RESET_RETRAIN_RESTATES_OLD_PRIOR",
              $sformatf("pri=%0d not from-zero +1 (occ match restamps old prior)", lk_pri));
    $display("U9R_R5_LEARNED_STATE_PASS");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > WATCH_CYC) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
