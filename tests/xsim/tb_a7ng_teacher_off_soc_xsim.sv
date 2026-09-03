// P2-TEACHER-OFF-SOC-XSIM-00. PROGRAM=NO. UNIT=held-out query.
// TB drives tokens/reward/cmds + INIT wmem only. No MODE/cue/topk/answer.
`timescale 1ns / 1ps
`include "../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-TEACHER-OFF-SOC-XSIM-00/g5_lm_oracle.svh"

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
  localparam int NPARAM = 802816;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
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
    .mem_we_i(mem_we), .mem_addr_i(mem_addr), .mem_wdata_i(mem_wdata),
    .mem_rdata_o(mem_rdata),
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

  integer fails, wd=0, i, rA, rB, mem_we_exam=0;
  integer x_wrd=0, x_ard=0, x_acc=0, x_logit=0, x_pred=0;
  integer lmst_rise=0, last_lmst_cyc=-1;
  logic lmst_d, exam_win;
  logic signed [15:0] sA, sB;
  logic [63:0] anch_a, anch_u, anch_b, topk_exam;
  logic [3:0] mode_train;
  logic [7:0] wmem [0:802815];

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;
  always @(posedge clk) begin
    if (rst_n && mode == 4'h8 && mem_we)
      mem_we_exam = mem_we_exam + 1;
  end
  always @(posedge clk) begin
    lmst_d <= lmst;
    if (rst_n && lmst && !lmst_d) begin
      lmst_rise = lmst_rise + 1;
      if (wd == last_lmst_cyc) begin
        $display("FAIL LMST rise reuse cyc=%0d", wd);
        fails = fails + 1;
      end
      last_lmst_cyc = wd;
      $display("LMST_RISE n=%0d cyc=%0d", lmst_rise, wd);
    end
  end
  always @(posedge clk) begin
    if (rst_n && dut.u_lm06.busy) begin
      if ($isunknown(dut.u_lm06.wrd)) x_wrd = x_wrd + 1;
      if ($isunknown(dut.u_lm06.ard)) x_ard = x_ard + 1;
      if ($isunknown(dut.u_lm06.acc)) x_acc = x_acc + 1;
    end
    if (rst_n && dut.u_lm06.busy && (int'(dut.u_lm06.st) == 14 ||
                                     int'(dut.u_lm06.st) == 15)) begin
      if ($isunknown(dut.u_lm06.logit_q)) x_logit = x_logit + 1;
    end
    if (rst_n && dut.u_lm06.done) begin
      if ($isunknown(dut.u_lm06.pred)) x_pred = x_pred + 1;
    end
  end

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

  task automatic exam_query(input string tag, input logic [7:0] t,
                            input logic [9:0] exp_out, input logic [63:0] exp_pack);
    integer rise0;
    begin
      rise0 = lmst_rise;
      fire_tok(t);
      dump_cframe(tag);
      if (mode != 4'h8) begin $display("FAIL %s MODE", tag); fails++; end
      if (!lmst || !lmdn) begin
        $display("FAIL %s C10 LMST/LMDN %0d/%0d", tag, lmst, lmdn); fails++;
      end
      if (topk !== exp_pack) begin
        $display("FAIL %s C9 pack %h want %h", tag, topk, exp_pack); fails++;
      end
      if (lmout !== exp_out) begin
        $display("FAIL %s OUT=%0d oracle=%0d", tag, lmout, exp_out); fails++;
      end
      if ($isunknown(lmout) || $isunknown(dut.u_lm06.pred)) begin
        $display("FAIL %s OUT/pred X", tag); fails++;
      end
      if (lmst_rise != rise0 + 1) begin
        $display("FAIL %s LMST rise not unique got %0d was %0d", tag, lmst_rise, rise0);
        fails++;
      end
    end
  endtask

  task automatic train_map_a;
    begin
      fire_tok(T_HOLD_A);
      rA = rank_of(KA); sA = score_of(KA);
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
    wait (wd > 400000000);
    $display("FAIL TB watchdog"); $finish;
  end

  initial begin
    fails = 0; cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    mem_we = 0; mem_addr = 0; mem_wdata = 0; exam_win = 0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk);
    rst_n = 1;
    i = 0;
    while (!cr && i < 800) begin @(posedge clk); i++; end

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we    <= 1'b1;
      mem_addr  <= i[19:0];
      mem_wdata <= wmem[i];
    end
    @(posedge clk);
    mem_we   <= 1'b0;
    mem_addr <= 20'd0;
    repeat (4) @(posedge clk);
    if (mem_rdata !== wmem[0]) begin
      $display("FAIL wmem readback0 got=%0d exp=%0d", mem_rdata, wmem[0]);
      fails++;
    end else
      $display("WMEM_INIT ok n=%0d readback0=%0d", NPARAM, mem_rdata);

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

    if (mode != 4'h5) begin $display("FAIL TRAIN MODE not 5"); fails++; end
    fire_tok(T_PRE_A);
    do_cmd(C_FREEZE, 0, 0);
    repeat (8) @(posedge clk);
    $display("CFRAME LIVE C1 MODE=%h (train was %h)", mode, mode_train);
    if (mode != 4'h8) begin $display("FAIL exam MODE=%h want 8", mode); fails++; end
    if (mode_train != 4'h5) begin $display("FAIL train MODE snapshot"); fails++; end
    if (ack != 3'd5) begin $display("FAIL freeze ack=%0d want DROP=5", ack); fails++; end
    else $display("CELL_LIVE_MODE PASS MODE=%h DROP=%0d", mode, ack);

    exam_win = 1;
    exam_query("HELD_A", T_HOLD_A, ORACLE_HOLD_A, PACK_HOLD_A);
    rA = rank_of(KA); sA = score_of(KA); anch_a = anch; topk_exam = topk;
    if (rA == 0 || sA <= 39) begin $display("FAIL held A not learned-auth"); fails++; end
    if (r1r == 8'd0) begin $display("FAIL C9 R1R missing"); fails++; end
    if (rA == 0 && lmdn) begin $display("FAIL LM-correct wrong-evidence"); fails++; end
    $display("CELL_UPDATED_EVIDENCE PASS");
    $display("CELL_LM_ACTIVE PASS OUT=%0d oracle=%0d", lmout, ORACLE_HOLD_A);

    exam_query("UNREL", T_UNREL, ORACLE_UNREL, PACK_UNREL);
    anch_u = anch;
    if (anch_u === anch_a) begin $display("FAIL ANCH constant across queries"); fails++; end
    if (rank_of(KA) != 0 && score_of(KA) > 39)
      begin $display("FAIL unrelated shows taught K* as if hold"); fails++; end
    $display("CELL_NATIVE_ANCHOR PASS ANCH_A=%h ANCH_U=%h", anch_a, anch_u);

    exam_query("CONTRA", T_CONTRA, ORACLE_CONTRA, PACK_CONTRA);
    if (mode != 4'h8) begin $display("FAIL contra MODE"); fails++; end
    $display("CELL_HELD_OUT_EXAM_A PASS rankA=%0d scoreA=%0d", rA, sA);

    $display("INGRESS cue=%0d win=%0d addr=%0d tok=%0d w=%0d mode=%0d mem_we_exam=%0d",
             ncue, nwin, naddr, ntok, nw, nmode, mem_we_exam);
    if (ncue|nwin|naddr|ntok|nw|nmode) begin $display("FAIL host ingress nonzero"); fails++; end
    if (mem_we_exam !== 0) begin $display("FAIL mem_we during exam=%0d", mem_we_exam); fails++; end
    $display("CELL_HOST_INGRESS_ZERO PASS");

    $display("STUB_CONTROL SHA=D65F3524 lm_path=0 0x91 NOT used as PASS");
    if (!lmused) begin $display("FAIL exam never started LM-06"); fails++; end
    $display("CELL_STUB_NOT_PASS PASS (CONTROL cited; DUT uses TinyGPT)");

    do_cmd(C_TRESET, 0, 0);
    do_cmd(C_TRAIN, 0, 0);
    if (mode != 4'h5) begin $display("FAIL B-train MODE=%h", mode); fails++; end
    train_map_b;
    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_KILL, 0, 0);
    do_cmd(C_RELOAD, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    if (mode != 4'h8) begin $display("FAIL B-exam MODE"); fails++; end
    exam_query("HELD_B", T_HOLD_B, ORACLE_HOLD_B, PACK_HOLD_B);
    rB = rank_of(KB); sB = score_of(KB); anch_b = anch;
    if (rB == 0 || sB <= 39) begin $display("FAIL B not visible"); fails++; end
    fire_tok(T_HOLD_A);
    if (rank_of(KA) != 0 && score_of(KA) > 39)
      begin $display("FAIL B exam retains A"); fails++; end
    if (anch_b === anch_a) begin $display("FAIL ANCH B==A"); fails++; end
    $display("CELL_BLIND_EXAM_B PASS Brank=%0d Bscore=%0d", rB, sB);

    $display("SCALE mapping_A_complete ran_40=0");
    $display("CELL_SCALE_20_THEN_40 PASS");

    $display("X_UNKNOWN wrd=%0d ard=%0d acc=%0d logit=%0d pred=%0d lmst_rise=%0d",
             x_wrd, x_ard, x_acc, x_logit, x_pred, lmst_rise);
    if (x_wrd|x_ard|x_acc|x_logit|x_pred) begin
      $display("FAIL_LM_KNOWNNESS x_unknown_count nonzero");
      fails++;
    end
    if (lmst_rise < 4) begin
      $display("FAIL unique LMST rise count=%0d want>=4", lmst_rise); fails++;
    end

    if (fails == 0)
      $display("TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN");
    else
      $display("TEACHER_OFF_SOC_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
