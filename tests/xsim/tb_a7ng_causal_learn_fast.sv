// P2-CAUSAL-LEARN-FAST-00. PROGRAM=NO. UNIT=held-out query. Host reward-only.
// C3/C9 are DUT FPGA topk_id/score. No host score_fn. No MIG.
`timescale 1ns / 1ps

module tb_a7ng_causal_learn_fast;
  import a7ng_pkg::*;

  localparam logic [7:0] Q_PRE        = 8'd1;
  localparam logic [7:0] Q_HOLD       = 8'd2;
  localparam logic [7:0] Q_UNREL      = 8'd3;
  localparam logic [7:0] Q_PRE_CONTRA = 8'd4;
  localparam node_id_t   KSTAR        = 32'h1000;

  logic clk, rst_n, learn, freeze;
  logic qv, qr, sv, sr;
  logic [7:0] qid;
  node_id_t top_id [8];
  score_t   top_s  [8];
  logic [31:0] evs, evo;
  logic [7:0]  evr;
  logic pending;
  logic [15:0] txn;
  logic rew_v, echo_v, rew_rdy, ack_v;
  logic signed [3:0] rew;
  logic [15:0] echo;
  logic [2:0] ack;
  logic c5, c6v, c6sat, c7v, c7r, c7e;
  logic signed [15:0] c6d;
  logic [31:0] c7a;

  a7ng_causal_learn_fast dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .query_valid_i(qv), .query_ready_o(qr), .query_id_i(qid),
    .snap_valid_o(sv), .snap_ready_i(sr),
    .topk_id_o(top_id), .topk_score_o(top_s),
    .ev_subj_o(evs), .ev_rel_o(evr), .ev_obj_o(evo),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_o(ack),
    .c5_consume_o(c5), .c6_delta_o(c6d), .c6_valid_o(c6v), .c6_sat_o(c6sat),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(c7r), .c7_addr_o(c7a), .c7_err_o(c7e)
  );

  initial clk = 1'b0;
  always #40 clk = ~clk;

  integer fails, arm_fail;
  integer i, rA, rB, rPre;
  logic signed [15:0] sA, sB;
  node_id_t idA [8], idB [8], idPre [8];
  score_t   scA [8], scB [8], scPre [8];
  logic c7_seen;

  function automatic int rank_of(input node_id_t id, input node_id_t ids [8]);
    begin
      rank_of = 0;
      for (int k = 0; k < 8; k = k + 1)
        if (ids[k] == id) rank_of = k + 1;
    end
  endfunction
  function automatic logic signed [15:0] score_of(input node_id_t id,
      input node_id_t ids [8], input score_t scs [8]);
    begin
      score_of = 16'sd0;
      for (int k = 0; k < 8; k = k + 1)
        if (ids[k] == id) score_of = scs[k];
    end
  endfunction
  function automatic logic unchanged8(input node_id_t a [8], input score_t sa [8],
                                      input node_id_t b [8], input score_t sb [8]);
    begin
      unchanged8 = 1'b1;
      for (int k = 0; k < 8; k = k + 1)
        if ((a[k] !== b[k]) || (sa[k] !== sb[k])) unchanged8 = 1'b0;
    end
  endfunction
  function automatic logic move_up(input int ra, input int rb,
                                   input logic signed [15:0] sa, input logic signed [15:0] sb);
    begin
      if ((ra == 0) && (rb != 0)) move_up = 1'b1;
      else if ((ra != 0) && (rb != 0) && (rb < ra)) move_up = 1'b1;
      else if ((ra != 0) && (rb == ra) && (sb > sa)) move_up = 1'b1;
      else move_up = 1'b0;
    end
  endfunction
  function automatic logic move_down(input int ra, input int rb,
                                     input logic signed [15:0] sa, input logic signed [15:0] sb);
    begin
      if ((ra != 0) && (rb == 0)) move_down = 1'b1;
      else if ((ra != 0) && (rb != 0) && (rb > ra)) move_down = 1'b1;
      else if ((ra != 0) && (rb == ra) && (sb < sa)) move_down = 1'b1;
      else move_down = 1'b0;
    end
  endfunction

  task automatic arm_reset;
    begin
      rst_n = 1'b0; qv = 1'b0; rew_v = 1'b0; echo_v = 1'b0; sr = 1'b1; c7r = 1'b1;
      learn = 1'b1; freeze = 1'b0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
      c7_seen = 1'b0;
    end
  endtask

  task automatic do_query(input logic [7:0] q);
    integer guard;
    begin
      guard = 0;
      @(negedge clk);
      while (!qr && guard < 200) begin
        @(posedge clk); guard = guard + 1;
      end
      qid = q; qv = 1'b1;
      @(posedge clk);
      @(negedge clk); qv = 1'b0;
      guard = 0;
      while (!sv && guard < 400) begin
        @(posedge clk); guard = guard + 1;
      end
      if (!sv) begin
        $display("FAIL query %0d no snap", q);
        fails = fails + 1; arm_fail = arm_fail + 1;
      end
      @(posedge clk);
    end
  endtask

  task automatic capture(output node_id_t ids [8], output score_t scs [8]);
    begin
      for (i = 0; i < 8; i = i + 1) begin
        ids[i] = top_id[i];
        scs[i] = top_s[i];
      end
    end
  endtask

  task automatic dump_top(input string tag);
    begin
      $display("%s topk", tag);
      for (i = 0; i < 8; i = i + 1)
        $display("  [%0d] id=%h score=%0d", i, top_id[i], top_s[i]);
    end
  endtask

  task automatic send_reward(input logic signed [3:0] r);
    integer guard;
    begin
      guard = 0;
      while (!pending && guard < 200) begin
        @(posedge clk); guard = guard + 1;
      end
      if (!pending) begin
        $display("FAIL no pending for reward");
        fails = fails + 1; arm_fail = arm_fail + 1;
      end
      @(negedge clk);
      rew = r; rew_v = 1'b1; echo_v = 1'b1; echo = txn;
      @(posedge clk);
      @(negedge clk); rew_v = 1'b0; echo_v = 1'b0;
    end
  endtask

  task automatic wait_c7;
    integer guard;
    begin
      guard = 0;
      while (!c7v && guard < 200) begin
        @(posedge clk); guard = guard + 1;
      end
      if (!c7v) begin
        $display("FAIL C7 ACK missing");
        fails = fails + 1; arm_fail = arm_fail + 1;
      end else if (c7e) begin
        $display("FAIL C7 err");
        fails = fails + 1; arm_fail = arm_fail + 1;
      end else begin
        c7_seen = 1'b1;
        $display("C7 ACK addr=%h delta=%0d sat=%0b", c7a, c6d, c6sat);
      end
      @(posedge clk);
    end
  endtask

  initial begin
    fails = 0;
    qv = 0; rew_v = 0; echo_v = 0; sr = 1; c7r = 1;
    learn = 1; freeze = 0; rst_n = 0;
    repeat (2) @(posedge clk);

    // ----- positive -----
    arm_fail = 0;
    arm_reset;
    do_query(Q_PRE); capture(idPre, scPre); dump_top("POS A_pre");
    do_query(Q_HOLD); capture(idA, scA); dump_top("POS A_hold");
    rA = rank_of(KSTAR, idA); sA = score_of(KSTAR, idA, scA);
    send_reward(4'sd3);
    wait_c7;
    if (!c7_seen) begin $display("FAIL POS C7"); end
    do_query(Q_HOLD); capture(idB, scB); dump_top("POS B_hold");
    rB = rank_of(KSTAR, idB); sB = score_of(KSTAR, idB, scB);
    rPre = rank_of(KSTAR, idPre);
    $display("POS K* A rank=%0d score=%0d  B rank=%0d score=%0d", rA, sA, rB, sB);
    if (!move_up(rA, rB, sA, sB)) begin
      $display("FAIL POS not move_up"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    if (move_down(rPre, rB, score_of(KSTAR, idPre, scPre), sB) && move_up(rA, rB, sA, sB))
      $display("POS INDETERMINATE vs A_pre (keep hold contrast)");
    if (arm_fail == 0) $display("ARM_POSITIVE PASS");
    else               $display("ARM_POSITIVE FAIL");

    // ----- negative -----
    arm_fail = 0;
    arm_reset;
    do_query(Q_PRE); capture(idPre, scPre); dump_top("NEG A_pre");
    do_query(Q_HOLD); capture(idA, scA); dump_top("NEG A_hold");
    rA = rank_of(KSTAR, idA); sA = score_of(KSTAR, idA, scA);
    send_reward(-4'sd3);
    wait_c7;
    do_query(Q_HOLD); capture(idB, scB); dump_top("NEG B_hold");
    rB = rank_of(KSTAR, idB); sB = score_of(KSTAR, idB, scB);
    $display("NEG K* A rank=%0d score=%0d  B rank=%0d score=%0d", rA, sA, rB, sB);
    if (!move_down(rA, rB, sA, sB)) begin
      $display("FAIL NEG not move_down"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    if (arm_fail == 0) $display("ARM_NEGATIVE PASS");
    else               $display("ARM_NEGATIVE FAIL");

    // ----- unrelated -----
    arm_fail = 0;
    arm_reset;
    do_query(Q_PRE); capture(idPre, scPre); dump_top("UNR A_pre");
    do_query(Q_UNREL); capture(idA, scA); dump_top("UNR A_hold");
    if (rank_of(KSTAR, idA) != 0) begin
      $display("FAIL UNR A contains K*"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    send_reward(4'sd2);
    wait_c7;
    do_query(Q_UNREL); capture(idB, scB); dump_top("UNR B_hold");
    if (!unchanged8(idA, scA, idB, scB)) begin
      $display("FAIL UNR topk changed"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    if (arm_fail == 0) $display("ARM_UNRELATED PASS");
    else               $display("ARM_UNRELATED FAIL");

    // ----- contradiction -----
    arm_fail = 0;
    arm_reset;
    do_query(Q_PRE_CONTRA); capture(idPre, scPre); dump_top("CON A_pre");
    do_query(Q_HOLD); capture(idA, scA); dump_top("CON A_hold");
    rA = rank_of(KSTAR, idA); sA = score_of(KSTAR, idA, scA);
    send_reward(-4'sd3);
    wait_c7;
    do_query(Q_HOLD); capture(idB, scB); dump_top("CON B_hold");
    rB = rank_of(KSTAR, idB); sB = score_of(KSTAR, idB, scB);
    $display("CON K* A rank=%0d score=%0d  B rank=%0d score=%0d", rA, sA, rB, sB);
    if (!move_down(rA, rB, sA, sB)) begin
      $display("FAIL CON not move_down on K*"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    if (move_up(rA, rB, sA, sB)) begin
      $display("FAIL CON move_up on K*"); fails = fails + 1; arm_fail = arm_fail + 1;
    end
    if (arm_fail == 0) $display("ARM_CONTRADICTION PASS");
    else               $display("ARM_CONTRADICTION FAIL");

    if (fails == 0)
      $display("CAUSAL_LEARN_FAST_XSIM_PASS fails=0 UNIT=held-out-query");
    else
      $display("CAUSAL_LEARN_FAST_XSIM_FAIL fails=%0d", fails);
    $finish;
  end

  always @(posedge clk) begin
    if (rew_v && (rew > 4'sd3 || rew < -4'sd3)) begin
      $display("FAIL host reward out of range");
      fails = fails + 1;
    end
  end
endmodule
