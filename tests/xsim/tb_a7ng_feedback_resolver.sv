// UNIT: a7ng-feedback-v1. PROGRAM=NO. Not on SoC.
`timescale 1ns / 1ps

module tb_a7ng_feedback_resolver;
  logic clk, rst_n, learn, freeze;
  logic latch_v, latch_rdy, pending;
  logic [31:0] subj, obj;
  logic [7:0] rel, conf;
  logic [15:0] qe, pe, txn;
  logic contra;
  logic rew_v, echo_v;
  logic signed [3:0] rew;
  logic [15:0] echo;
  logic ack_v;
  logic [2:0] ack;
  logic cons_v;
  logic signed [3:0] cons_r;
  logic [31:0] cons_s, cons_o;
  logic [7:0] cons_rel, cons_c;
  logic [15:0] n_c, n_or, n_rg, n_lt, n_dr;

  a7ng_feedback_resolver dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(subj), .rel_i(rel), .obj_i(obj),
    .q_epoch_i(qe), .p_epoch_i(pe), .conf_i(conf), .contradict_i(contra),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(),
    .ack_valid_o(ack_v), .ack_ready_i(1'b1), .ack_o(ack),
    .consume_valid_o(cons_v), .consume_ready_i(1'b1),
    .consume_reward_o(cons_r),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(), .consume_p_epoch_o(),
    .consume_conf_o(cons_c), .consume_contradict_o(), .consume_txn_o(),
    .n_consume_o(n_c), .n_orphan_o(n_or), .n_range_o(n_rg),
    .n_late_o(n_lt), .n_drop_o(n_dr), .n_dup_o(), .n_mode_o()
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer fails;

  task automatic tick;
    begin
      @(posedge clk);
      rew_v = 1'b0;
      latch_v = 1'b0;
      echo_v = 1'b0;
    end
  endtask

  task automatic do_latch;
    begin
      @(negedge clk);
      latch_v = 1'b1;
      subj = 32'd41; rel = 8'd2; obj = 32'd57;
      qe = 16'd1; pe = 16'd1; conf = 8'd200; contra = 1'b0;
      @(posedge clk);
      @(negedge clk);
      latch_v = 1'b0;
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 0; learn = 1; freeze = 0;
    latch_v = 0; rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    subj = 0; rel = 0; obj = 0; qe = 0; pe = 0; conf = 0; contra = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    tick;

    // Orphan
    @(negedge clk); rew_v = 1; rew = 4'sd1;
    @(posedge clk); @(negedge clk); rew_v = 0;
    if (!ack_v || ack != 3'd2) begin $display("FAIL orphan"); fails = fails + 1; end
    else $display("PASS orphan");

    do_latch;
    @(posedge clk); @(negedge clk);
    if (!pending) begin $display("FAIL latch"); fails = fails + 1; end

    // Range
    @(negedge clk); rew_v = 1; rew = 4'sd7;
    @(posedge clk); @(negedge clk); rew_v = 0;
    if (!ack_v || ack != 3'd3 || !pending) begin $display("FAIL range"); fails = fails + 1; end
    else $display("PASS range pending-held");

    // Late txn
    @(negedge clk); rew_v = 1; rew = 4'sd1; echo_v = 1; echo = 16'hDEAD;
    @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
    if (!ack_v || ack != 3'd4 || !pending) begin $display("FAIL late"); fails = fails + 1; end
    else $display("PASS late");

    // Consume
    @(negedge clk); rew_v = 1; rew = 4'sd2; echo_v = 1; echo = txn;
    @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
    if (!ack_v || ack != 3'd1 || pending || !cons_v || cons_s != 32'd41) begin
      $display("FAIL consume ack=%0d pending=%0b cons=%0b", ack, pending, cons_v);
      fails = fails + 1;
    end else $display("PASS consume subj=41 reward=2");

    do_latch;
    @(posedge clk);
    freeze = 1;
    @(posedge clk);
    if (!ack_v || ack != 3'd5 || pending) begin $display("FAIL drop-freeze"); fails = fails + 1; end
    else $display("PASS drop-freeze");
    freeze = 0;

    if (fails == 0)
      $display("FEEDBACK_RESOLVER_UNIT_XSIM_PASS fails=0");
    else
      $display("FEEDBACK_RESOLVER_UNIT_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
