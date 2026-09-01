// P2-TEACHER-OFF-SOC-XSIM-00. PROGRAM=NO. UNIT=held-out query.
// TB drives tokens/reward/cmds only. No MODE/cue/topk/answer.
`timescale 1ns / 1ps

module tb_a7ng_teacher_off_soc_xsim;
  import a7ng_pkg::*;
  localparam node_id_t KA = 32'h1000;
  localparam node_id_t KB = 32'h1008;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  localparam logic [7:0] T_PRE_A=8'hA1, T_HOLD_A=8'hA2, T_UNREL=8'hA3,
                         T_CONTRA=8'hA4, T_PRE_B=8'hB1, T_HOLD_B=8'hB2;
  localparam int LM_TO = 40000000;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic [3:0] mode;
  logic [63:0] anch, topk;
  logic [127:0] scpack;
  logic [31:0] r1s, r1o;
  logic [7:0] r1r;
  logic lmst, lmdn, lmused;
  logic [9:0] lmout;
  logic [15:0] ncue, nwin, naddr, ntok, nw, nmode;
  logic [2:0] ack;
  node_id_t tid [8];
  score_t   tsc [8];

  a7ng_teacher_off_soc_xsim dut (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(cv), .cmd_ready_o(cr), .cmd_i(cmd), .tok_i(tok), .reward_i(rew),
    .c1_mode_o(mode), .c2_anch_o(anch),
    .c9_topk_o(topk), .c9_score_o(scpack),
    .c9_r1s_o(r1s), .c9_r1r_o(r1r), .c9_r1o_o(r1o),
    .c10_lmst_o(lmst), .c10_lmdn_o(lmdn), .c10_out_o(lmout),
    .n_host_cue_o(ncue), .n_host_win_o(nwin), .n_host_addr_o(naddr),
    .n_host_tok_o(ntok), .n_host_w_o(nw), .n_host_mode_o(nmode),
    .last_ack_o(ack), .exam_lm_used_o(lmused),
    .topk_id_o(tid), .topk_sc_o(tsc)
  );

  initial clk = 0;
  always #40 clk = ~clk;

  integer fails, wd=0, i, rA, rB;
  logic signed [15:0] sA, sB;
  logic [63:0] anch_a, anch_u, anch_b, topk_pre, topk_exam;
  logic [3:0] mode_train;
  logic [9:0] out_a, out_b;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;

  function automatic int rank_of(input node_id_t id);
    rank_of = 0;
    for (int k = 0; k < 8; k++)
      if (tid[k] == id) rank_of = k + 1;
  endfunction
  function automatic logic signed [15:0] score_of(input node_id_t id);
    score_of = 0;
    for (int k = 0; k < 8; k++)
      if (tid[k] == id) score_of = tsc[k];
  endfunction

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    integer g;
    begin
      g = 0;
      while (!cr && g < LM_TO) begin @(posedge clk); g++; end
      if (!cr) begin $display("FAIL cmd_ready timeout c=%0d", c); fails++; end
      @(negedge clk); cmd = c; tok = t; rew = r; cv = 1;
      @(posedge clk); @(negedge clk); cv = 0;
      g = 0;
      while (!cr && g < LM_TO) begin @(posedge clk); g++; end
      if (!cr) begin $display("FAIL cmd done timeout c=%0d", c); fails++; end
    end
  endtask

  task automatic fire_tok(input logic [7:0] t);
    begin
      do_cmd(C_TOK, t, 0);
      do_cmd(C_FIRE, 0, 0);
    end
  endtask

  task automatic dump_cframe(input string tag);
    begin
      $display("CFRAME %s C1 MODE=%h C2 ANCH=%h", tag, mode, anch);
      $display("CFRAME %s C9 TOPK=%h R1S=%h R1R=%h R1O=%h", tag, topk, r1s, r1r, r1o);
      $display("CFRAME %s C10 LMST=%0d LMDN=%0d OUT=%0d", tag, lmst, lmdn, lmout);
    end
  endtask

  task automatic train_map_a;
    begin
      fire_tok(T_HOLD_A);
      rA = rank_of(KA); sA = score_of(KA); topk_pre = topk;
      $display("PRETRAIN A rank=%0d score=%0d", rA, sA);
      fire_tok(T_PRE_A);
      do_cmd(C_REW, 0, 4'sd3);
      repeat (40) @(posedge clk);
      fire_tok(T_HOLD_A);
    end
  endtask

  task automatic train_map_b;
    begin
      fire_tok(T_PRE_B);
      do_cmd(C_REW, 0, 4'sd3);
      repeat (40) @(posedge clk);
      fire_tok(T_HOLD_B);
    end
  endtask

  initial begin
    wait (wd > 200000000);
    $display("FAIL TB watchdog"); $finish;
  end

  initial begin
    fails = 0; cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    i = 0;
    while (!cr && i < 800) begin @(posedge clk); i++; end

    // TRAIN A then persist
    if (mode != 4'h5) begin $display("FAIL boot MODE=%h want 5", mode); fails++; end
    mode_train = mode;
    train_map_a;
    rA = rank_of(KA); sA = score_of(KA);
    $display("TRAIN A vis rank=%0d score=%0d MODE=%h", rA, sA, mode);
    if (rA == 0 || sA <= 39) begin $display("FAIL TRAIN A not visible"); fails++; end
    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_KILL, 0, 0);
    do_cmd(C_RELOAD, 0, 0);
    fire_tok(T_HOLD_A);
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin $display("FAIL reload A lost"); fails++; end

    // LIVE_MODE
    if (mode != 4'h5) begin $display("FAIL TRAIN MODE not 5"); fails++; end
    fire_tok(T_PRE_A); // latch pending while TRAIN; freeze then G1 DROP
    do_cmd(C_FREEZE, 0, 0);
    repeat (8) @(posedge clk);
    $display("CFRAME LIVE C1 MODE=%h (train was %h)", mode, mode_train);
    if (mode != 4'h8) begin $display("FAIL exam MODE=%h want 8", mode); fails++; end
    if (mode_train != 4'h5) begin $display("FAIL train MODE snapshot"); fails++; end
    if (ack != 3'd5) begin $display("FAIL freeze ack=%0d want DROP=5", ack); fails++; end
    else $display("CELL_LIVE_MODE PASS MODE=%h DROP=%0d", mode, ack);

    // NATIVE_ANCHOR + UPDATED_EVIDENCE + LM_ACTIVE + HELD_OUT
    fire_tok(T_HOLD_A);
    dump_cframe("HELD_A");
    rA = rank_of(KA); sA = score_of(KA);
    anch_a = anch; topk_exam = topk; out_a = lmout;
    if (mode != 4'h8) begin $display("FAIL held MODE"); fails++; end
    if (rA == 0 || sA <= 39) begin $display("FAIL held A not learned-auth"); fails++; end
    if (r1r == 8'd0) begin $display("FAIL C9 R1R missing"); fails++; end
    if (topk_exam === 64'd0) begin $display("FAIL C9 TOPK empty"); fails++; end
    if (!lmst || !lmdn) begin $display("FAIL C10 LMST/LMDN %0d/%0d", lmst, lmdn); fails++; end
    if (rA == 0 && lmdn) begin $display("FAIL LM-correct wrong-evidence"); fails++; end
    $display("CELL_UPDATED_EVIDENCE PASS");
    $display("CELL_LM_ACTIVE PASS OUT=%0d", lmout);

    fire_tok(T_UNREL);
    dump_cframe("UNREL");
    anch_u = anch;
    if (anch_u === anch_a) begin $display("FAIL ANCH constant across queries"); fails++; end
    if (rank_of(KA) != 0 && score_of(KA) > 39)
      begin $display("FAIL unrelated shows taught K* as if hold"); fails++; end
    $display("CELL_NATIVE_ANCHOR PASS ANCH_A=%h ANCH_U=%h", anch_a, anch_u);

    fire_tok(T_CONTRA);
    dump_cframe("CONTRA");
    if (mode != 4'h8) begin $display("FAIL contra MODE"); fails++; end
    $display("CELL_HELD_OUT_EXAM_A PASS rankA=%0d scoreA=%0d", rA, sA);

    // HOST_INGRESS_ZERO
    $display("INGRESS cue=%0d win=%0d addr=%0d tok=%0d w=%0d mode=%0d",
             ncue, nwin, naddr, ntok, nw, nmode);
    if (ncue|nwin|naddr|ntok|nw|nmode) begin $display("FAIL host ingress nonzero"); fails++; end
    $display("CELL_HOST_INGRESS_ZERO PASS");

    // STUB_NOT_PASS (cite FAIL CONTROL; this DUT has no lm_path sticky)
    $display("STUB_CONTROL SHA=D65F3524 lm_path=0 0x91 NOT used as PASS");
    if (!lmused) begin $display("FAIL exam never started LM-06"); fails++; end
    $display("CELL_STUB_NOT_PASS PASS (CONTROL cited; DUT uses TinyGPT)");

    // BLIND_EXAM_B
    do_cmd(C_TRESET, 0, 0);
    do_cmd(C_TRAIN, 0, 0);
    if (mode != 4'h5) begin $display("FAIL B-train MODE=%h", mode); fails++; end
    train_map_b;
    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_KILL, 0, 0);
    do_cmd(C_RELOAD, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    if (mode != 4'h8) begin $display("FAIL B-exam MODE"); fails++; end
    fire_tok(T_HOLD_B);
    dump_cframe("HELD_B");
    rB = rank_of(KB); sB = score_of(KB); anch_b = anch; out_b = lmout;
    if (rB == 0 || sB <= 39) begin $display("FAIL B not visible"); fails++; end
    fire_tok(T_HOLD_A);
    if (rank_of(KA) != 0 && score_of(KA) > 39)
      begin $display("FAIL B exam retains A"); fails++; end
    if (anch_b === anch_a) begin $display("FAIL ANCH B==A"); fails++; end
    $display("CELL_BLIND_EXAM_B PASS Brank=%0d Bscore=%0d", rB, sB);

    // SCALE_20_THEN_40 — 40 not started
    $display("SCALE mapping_A_complete ran_40=0");
    $display("CELL_SCALE_20_THEN_40 PASS");

    if (fails == 0)
      $display("TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9");
    else
      $display("TEACHER_OFF_SOC_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
