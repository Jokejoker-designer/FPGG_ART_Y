// Codex Gate-14 counterexample → expected-reject after resolver fix.
`timescale 1ns/1ps

module tb_resolver_counterexample;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n, learn, freeze;
  logic latch_valid, latch_ready;
  logic [31:0] subj, obj;
  logic [7:0] rel, conf;
  logic [15:0] qe, pe, txn;
  logic contradict, pending;
  logic reward_valid, echo_valid;
  logic signed [3:0] reward;
  logic [15:0] echo;
  logic ack_valid;
  logic [2:0] ack;
  logic consume_valid;
  logic signed [3:0] consume_reward;
  logic [31:0] consume_subj, consume_obj;
  logic [7:0] consume_rel, consume_conf;
  logic [15:0] n_consume, n_orphan, n_range, n_late, n_drop;

  a7ng_feedback_resolver dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .latch_valid_i(latch_valid), .latch_ready_o(latch_ready),
    .subj_i(subj), .rel_i(rel), .obj_i(obj),
    .q_epoch_i(qe), .p_epoch_i(pe), .conf_i(conf), .contradict_i(contradict),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(reward_valid), .reward_i(reward),
    .txn_echo_valid_i(echo_valid), .txn_echo_i(echo),
    .reward_ready_o(),
    .ack_valid_o(ack_valid), .ack_ready_i(1'b1), .ack_o(ack),
    .consume_valid_o(consume_valid), .consume_ready_i(1'b1),
    .consume_reward_o(consume_reward),
    .consume_subj_o(consume_subj), .consume_rel_o(consume_rel),
    .consume_obj_o(consume_obj),
    .consume_q_epoch_o(), .consume_p_epoch_o(),
    .consume_conf_o(consume_conf), .consume_contradict_o(), .consume_txn_o(),
    .n_consume_o(n_consume), .n_orphan_o(n_orphan), .n_range_o(n_range),
    .n_late_o(n_late), .n_drop_o(n_drop), .n_dup_o(), .n_mode_o()
  );

  integer fails;
  initial begin
    fails = 0;
    rst_n = 0; learn = 0; freeze = 0;
    latch_valid = 0; reward_valid = 0; echo_valid = 0;
    subj = 32'd41; rel = 8'd2; obj = 32'd57;
    qe = 16'd7; pe = 16'd9; conf = 8'd200; contradict = 1;
    reward = 0; echo = 0;
    repeat (3) @(posedge clk);
    @(negedge clk); rst_n = 1;

    @(negedge clk); latch_valid = 1;
    @(posedge clk); @(negedge clk); latch_valid = 0;
    if (pending || latch_ready) begin
      $display("FAIL learn0 still latched pending=%0b ready=%0b", pending, latch_ready);
      fails = fails + 1;
    end else $display("PASS learn0_latch_rejected");

    learn = 1;
    @(negedge clk); latch_valid = 1;
    @(posedge clk); @(negedge clk); latch_valid = 0;
    if (!pending) begin $display("FAIL learn1 no latch"); fails = fails + 1; end

    @(negedge clk); reward = 4'sd2; reward_valid = 1; echo_valid = 0;
    @(posedge clk); @(negedge clk); reward_valid = 0;
    if (consume_valid || ack == 3'd1) begin
      $display("FAIL no_echo consumed ack=%0d", ack);
      fails = fails + 1;
    end else if (ack_valid && ack == 3'd4 && pending) $display("PASS no_echo_reject_late");
    else begin $display("FAIL no_echo ack=%0d pending=%0b", ack, pending); fails = fails + 1; end

    if (fails == 0) $display("RESOLVER_COUNTEREXAMPLE_XSIM_PASS");
    else $display("RESOLVER_COUNTEREXAMPLE_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
