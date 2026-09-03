// tb_a7ng_gate14_c9_soa_lm.sv — P2-GATE14-C9-SOA-LM-BIT-04
// 20 distinct facts. Frozen ORACLE 653/689/237/60. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_gate14_c9_soa_lm;
  import a7ng_pkg::*;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  localparam logic [7:0] T_HOLD_A=8'hA2, T_UNREL=8'hA3, T_CONTRA=8'hA4, T_HOLD_B=8'hB2;
  localparam logic [63:0] PACK_A  = 64'h8382238122802120;
  localparam logic [63:0] PACK_U  = 64'h8786858483828180;
  localparam logic [63:0] PACK_C  = 64'h2322832182208180;
  localparam logic [63:0] PACK_B  = 64'h8382438142804140;
  localparam logic [9:0]  OUT_A = 10'd653, OUT_U = 10'd689, OUT_C = 10'd237, OUT_B = 10'd60;
  localparam int NPARAM = 802816;
  localparam int LM_TO = 40000000;

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
  logic c5, pbusy, c7v, afor, bvis;
  logic [31:0] c8g, c7a, r1s, r1o;
  logic [63:0] c8d, adig, bdig;
  logic [7:0] r1r;
  logic [127:0] scpack;

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
  always #40 clk = ~clk;

  integer fails, i, g, wd, k;
  logic signed [7:0] wmem [0:NPARAM-1];
  integer lmst_rise, last_lmst_cyc;
  logic lmst_d;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;
  always @(posedge clk) begin
    lmst_d <= lmst;
    if (rst_n && lmst && !lmst_d) begin
      lmst_rise = lmst_rise + 1;
      last_lmst_cyc = wd;
      $display("LMST_RISE n=%0d cyc=%0d", lmst_rise, wd);
    end
  end

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
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

  task automatic exam_query(input string tag, input logic [7:0] t,
                            input logic [9:0] exp_out, input logic [63:0] exp_pack);
    integer rise0;
    begin
      rise0 = lmst_rise;
      fire_tok(t);
      $display("EXAM %s MODE=%h C9=%h OUT=%0d LMST=%0d LMDN=%0d",
               tag, mode, topk, lmout, lmst, lmdn);
      if (mode != 4'h8) begin $display("FAIL %s MODE", tag); fails++; end
      if (!lmst || !lmdn) begin $display("FAIL %s LMST/LMDN", tag); fails++; end
      if (topk !== exp_pack) begin
        $display("FAIL %s C9 pack %h want %h", tag, topk, exp_pack); fails++;
      end
      if (lmout !== exp_out) begin
        $display("FAIL %s OUT=%0d oracle=%0d", tag, lmout, exp_out); fails++;
      end
      if (lmst_rise != rise0 + 1) begin
        $display("FAIL %s LMST rise", tag); fails++;
      end
    end
  endtask

  initial begin
    wait (wd > 400000000);
    $display("FAIL TB watchdog"); $finish;
  end

  initial begin
    fails = 0; cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    mem_we = 0; lmst_rise = 0; last_lmst_cyc = -1;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk);
    rst_n = 1;
    i = 0;
    while (!cr && i < 4000) begin @(posedge clk); i++; end

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    $display("WMEM_INIT n=%0d", NPARAM);

    if (mode != 4'h5) begin $display("FAIL boot MODE=%h", mode); fails++; end
    do_cmd(C_TRAIN, 0, 0);

    for (k = 0; k < 20; k = k + 1) begin
      $display("LESSON_A k=%0d tok=%h", k, 8'h10 + k[7:0]);
      fire_tok(8'h10 + k[7:0]);
      do_cmd(C_REW, 0, 4'sd3);
    end
    $display("A_TRAIN_20 done GEN=%0d", c8g);

    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    $display("PRE_EXAM MODE=%h qr=%0d pbusy=%0d pend=%0d boot=%0d",
             mode, dut.u_graph.query_ready_o, pbusy, dut.u_graph.pending_o,
             dut.u_graph.boot_done);
    if (mode != 4'h8) begin $display("FAIL FREEZE MODE=%h", mode); fails++; end

    exam_query("HOLD_A", T_HOLD_A, OUT_A, PACK_A);
    exam_query("UNREL",  T_UNREL,  OUT_U, PACK_U);
    exam_query("CONTRA", T_CONTRA, OUT_C, PACK_C);

    do_cmd(C_TRESET, 0, 0);
    do_cmd(C_TRAIN, 0, 0);
    for (k = 0; k < 20; k = k + 1) begin
      $display("LESSON_B k=%0d tok=%h", k, 8'h30 + k[7:0]);
      fire_tok(8'h30 + k[7:0]);
      do_cmd(C_REW, 0, 4'sd3);
    end
    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    exam_query("HOLD_B", T_HOLD_B, OUT_B, PACK_B);

    if (ncue != 0 || nwin != 0 || naddr != 0 || ntok != 0 || nw != 0 || nmode != 0)
      begin $display("FAIL host ingress"); fails++; end

    if (fails == 0)
      $display("GATE14_C9_SOA_LM_XSIM_PASS fails=0 OUTA=653 OUTU=689 OUTC=237 OUTB=60");
    else
      $display("GATE14_C9_SOA_LM_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
