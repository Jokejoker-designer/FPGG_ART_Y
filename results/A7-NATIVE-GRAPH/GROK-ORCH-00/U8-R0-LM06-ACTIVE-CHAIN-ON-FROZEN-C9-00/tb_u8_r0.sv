// tb_u8_r0.sv — U8-R0-LM06-ACTIVE-CHAIN-ON-FROZEN-C9-00
// Legacy C9 graph → bind → LM-06. No TYPE_CLASS glue. PROGRAM=NO. QHEAD=NO.
`timescale 1ns / 1ps

module tb_u8_r0;
  import a7ng_pkg::*;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_FREEZE=4'd7;
  localparam logic [7:0] T_HOLD_A=8'hA2;
  localparam logic [63:0] HOLD_A_C9 = 64'h8382238122802120;
  localparam int NPARAM = 802816;
  localparam int TO = 400000000;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd, mode;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic [63:0] anch, topk;
  logic lmst, lmdn;
  logic [9:0] lmout;
  logic [15:0] ncue, nwin, naddr, ntok, nw, nmode;
  logic [2:0] ack;
  logic lmused;
  node_id_t tid [8];
  score_t tsc [8];
  logic [15:0] txn;
  logic c5, pbusy, c7v;
  logic [31:0] c8g, c7a, r1s, r1o;
  logic [63:0] c8d;
  logic [7:0] r1r;
  logic [127:0] scpack;
  logic [63:0] adig, bdig;
  logic afor, bvis;

  a7ng_gate14_c9_soa_lm_xsim dut (
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
    .topk_id_o(tid), .topk_sc_o(tsc),
    .p_txn_o(txn), .c5_cons_o(c5), .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .c7_addr_o(c7a), .c7_v_o(c7v), .persist_busy_o(pbusy),
    .c11_adig_o(adig), .c11_bdig_o(bdig), .c11_a_for_o(afor), .c11_b_vis_o(bvis)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer n_ctx_we, n_sfwd, n_busy_rise, n_done, n_lmst_rise, n_lmdn_rise;
  logic ctx_d, sf_d, busy_d, done_d, lmst_d, lmdn_d;
  logic signed [7:0] wmem [0:NPARAM-1];
  integer i, g, wd;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      n_ctx_we <= 0; n_sfwd <= 0; n_busy_rise <= 0; n_done <= 0;
      n_lmst_rise <= 0; n_lmdn_rise <= 0;
      ctx_d <= 0; sf_d <= 0; busy_d <= 0; done_d <= 0; lmst_d <= 0; lmdn_d <= 0;
    end else begin
      ctx_d <= dut.ctx_we;
      sf_d  <= dut.start_fwd;
      busy_d <= dut.core_busy;
      done_d <= dut.core_done;
      lmst_d <= lmst;
      lmdn_d <= lmdn;
      if (dut.ctx_we && !ctx_d) n_ctx_we <= n_ctx_we + 1;
      if (dut.start_fwd && !sf_d) n_sfwd <= n_sfwd + 1;
      if (dut.core_busy && !busy_d) n_busy_rise <= n_busy_rise + 1;
      if (dut.core_done && !done_d) n_done <= n_done + 1;
      if (lmst && !lmst_d) n_lmst_rise <= n_lmst_rise + 1;
      if (lmdn && !lmdn_d) n_lmdn_rise <= n_lmdn_rise + 1;
    end
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
      #20 $finish;
    end
  endtask

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t);
    begin
      g = 0;
      while (!cr && g < TO) begin @(posedge clk); g++; end
      if (!cr) diverge("EARLY_DONE", "cmd_ready");
      @(negedge clk); cmd = c; tok = t; rew = 0; cv = 1;
      @(posedge clk); @(negedge clk); cv = 0;
      g = 0;
      while (!cr && g < TO) begin @(posedge clk); g++; end
      if (!cr) diverge("EARLY_DONE", "cmd_done");
    end
  endtask

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;
  initial begin
    wd = 0;
    wait (wd > TO);
    $display("FAIL TB watchdog cyc=%0d", wd);
    $finish;
  end

  initial begin
    rst_n = 0; cv = 0; cmd = 0; tok = 0; rew = 0; mem_we = 0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk); rst_n = 1;
    i = 0;
    while (!cr && i < 80000) begin @(posedge clk); i++; end
    if (!cr) diverge("EARLY_DONE", "boot");

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    $display("WMEM_INIT n=%0d", NPARAM);

    do_cmd(C_FREEZE, 0);
    $display("EXAM_MODE=%h", mode);
    if (mode != 4'h8) diverge("MODE", "not exam");

    do_cmd(C_TOK, T_HOLD_A);
    do_cmd(C_FIRE, 0);

    g = 0;
    while (!lmdn && g < TO) begin @(posedge clk); g++; end
    if (!lmdn) diverge("LM_DONE", "timeout");
    repeat (4) @(posedge clk);

    $display("CHAIN ctx_we=%0d sfwd_pulses=%0d busy_rise=%0d core_done=%0d",
      n_ctx_we, n_sfwd, n_busy_rise, n_done);
    $display("CHAIN ctx_beats=%0d sfwd_beats=%0d lmst=%0d lmdn=%0d",
      dut.ctx_beats, dut.st_beats, n_lmst_rise, n_lmdn_rise);
    $display("PRED c10=%0d bind=%0d core=%0d lmused=%0d",
      lmout, dut.bind_pred, dut.core_pred, lmused);
    $display("C9_OBS pack=%h HOLD_A_HIST=%h match=%0d",
      topk, HOLD_A_C9, topk === HOLD_A_C9);
    $display("HOST cue=%0d win=%0d addr=%0d tok=%0d w=%0d mode=%0d",
      ncue, nwin, naddr, ntok, nw, nmode);

    if (n_ctx_we !== 1) diverge("CTX_WE", "not exactly once");
    if (dut.ctx_beats !== 32'd1) diverge("CTX_WE", "beats");
    if (n_busy_rise !== 1) diverge("LM_BUSY", "not one forward");
    if (n_done !== 1) diverge("LM_DONE", "not exactly once");
    if (n_sfwd < 1) diverge("START_FWD", "zero pulses");
    if (n_lmst_rise !== 1) diverge("LMST", "rise");
    if (n_lmdn_rise !== 1) diverge("LMDN", "rise");
    if (!lmused) diverge("LM_USED", "exam_lm_used");
    if (lmout !== dut.core_pred) diverge("PRED_OWNER", "c10!=core");
    if (dut.bind_pred !== dut.core_pred) diverge("PRED_OWNER", "bind!=core");
    if (ncue !== 0 || nwin !== 0 || naddr !== 0 || ntok !== 0 || nw !== 0)
      diverge("HOST_SEMANTIC_LEAK", "counters");
    if (n_sfwd > 1)
      $display("NOTE BIND_REISSUE_UNTIL_BUSY sfwd_pulses=%0d (H4 frozen; one busy rise)", n_sfwd);

    $display("HOLD_A_REGRESSION_EVIDENCE_IMMUTABLE c9=8382238122802120 out=653/689/237/60");
    $display("CLAIM_NOT_TYPECLASS_TO_LM");
    $display("U8_R0_LM06_ACTIVE_CHAIN_ON_FROZEN_C9_PASS");
    $finish;
  end
endmodule
