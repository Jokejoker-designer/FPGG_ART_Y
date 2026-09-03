// Gate14 20-fact via UART bytes into G5 stack. PROGRAM=NO.
`timescale 1ns / 1ps
module tb_a7ng_gate14_20_uart;
  `include "../../rtl/native_graph/control/a7ng_gate14_crc.svh"
  import a7ng_pkg::*;
  localparam int CLK_HZ = 100_000_000;
  localparam int BAUD = 115200;
  localparam int CPB = (CLK_HZ + BAUD/2) / BAUD;
  localparam logic [7:0] T_PRE_A=8'hA1, T_HOLD_A=8'hA2, T_UNREL=8'hA3,
                         T_CONTRA=8'hA4, T_PRE_B=8'hB1, T_HOLD_B=8'hB2;
  localparam int NPARAM = 802816;
  logic clk, rst_n, rx, urx_v, cv, in_r, out_v, out_r, snap, mis;
  logic [7:0] urx_d, typ, tok, qtok, ferr, oerr;
  logic signed [3:0] rew, qrew;
  logic [15:0] seq, echo, txn;
  logic [3:0] cmd, mode;
  logic [63:0] anch, topk, c8d, adig, bdig;
  logic [9:0] lmout;
  logic lmst, lmdn, c5, afor, bvis, pbusy, c7v, cf_start, cf_busy;
  logic [31:0] c8g, c7a;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  integer fails, i, seqn;
  logic signed [7:0] wmem [0:NPARAM-1];
  logic [11:0] saw_ckpt;
  logic [7:0] cf_ckpt, cf_pay [0:47], cf_byte;
  logic [15:0] cf_seq, cf_len;
  logic cf_v, dump;

  a7ng_uart_rx100 u_rx (.clk(clk), .rst_n(rst_n), .rx(rx), .data(urx_d), .valid(urx_v), .ferr(ferr), .oerr(oerr));
  a7ng_gate14_uart_cmd_rx u_dec (
    .clk(clk), .rst_n(rst_n), .byte_i(urx_d), .byte_v_i(urx_v),
    .cmd_valid_o(cv), .cmd_ready_i(in_r),
    .cmd_type_o(typ), .cmd_seq_o(seq), .tok_o(tok), .rew_o(rew), .echo_o(echo),
    .rj_ver(), .rj_len(), .rj_crc(), .rj_typ(), .rj_dup(), .rj_busy()
  );
  a7ng_gate14_cmd_map u_map (
    .clk(clk), .rst_n(rst_n), .in_v(cv), .in_r(in_r),
    .typ(typ), .tok(tok), .rew(rew), .echo(echo), .fpga_txn(txn),
    .out_v(out_v), .out_r(out_r), .cmd(cmd), .tok_o(qtok), .rew_o(qrew),
    .snap_v(snap), .rew_mismatch(mis)
  );
  a7ng_teacher_off_soc_xsim dut (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(out_v), .cmd_ready_o(out_r), .cmd_i(cmd), .tok_i(qtok), .reward_i(qrew),
    .mem_we_i(mem_we), .mem_addr_i(mem_addr), .mem_wdata_i(mem_wdata), .mem_rdata_o(mem_rdata),
    .c1_mode_o(mode), .c2_anch_o(anch), .c9_topk_o(topk), .c9_score_o(),
    .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(lmst), .c10_lmdn_o(lmdn), .c10_out_o(lmout),
    .n_host_cue_o(), .n_host_win_o(), .n_host_addr_o(),
    .n_host_tok_o(), .n_host_w_o(), .n_host_mode_o(),
    .last_ack_o(), .exam_lm_used_o(), .topk_id_o(), .topk_sc_o(),
    .p_txn_o(txn), .c5_cons_o(c5), .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .c7_addr_o(c7a), .c7_v_o(c7v), .persist_busy_o(pbusy),
    .c11_adig_o(adig), .c11_bdig_o(bdig), .c11_a_for_o(afor), .c11_b_vis_o(bvis)
  );
  a7ng_gate14_cframe_sched u_cfs (
    .clk(clk), .rst_n(rst_n), .start_all(dump), .tx_busy(cf_busy),
    .start_tx(cf_start), .ckpt(cf_ckpt), .seq(cf_seq), .len(cf_len), .pay(cf_pay),
    .c0_id(64'hA714_01C0_4743_3134), .c1_mode(mode), .c2_anch(anch),
    .c3_ids(topk), .c3_sc(128'd0), .c4_ev(64'd0),
    .c5_cons({31'd0, c5}), .c5_rej(32'd0), .c5_ack(8'd0),
    .c6_rsv(16'd0), .c6_sat(1'b0),
    .c7_addr(c7a), .c7_ack({7'd0, c7v}), .c7_err({7'd0, pbusy}),
    .c8_gen(c8g), .c8_sdig(c8d),
    .c9_ids(topk), .c9_sc(128'd0), .c9_pack(topk), .c9_poison(1'b0),
    .c9_r1s(32'd0), .c9_r1r(8'd0), .c9_r1o(32'd0),
    .c10_lmst(lmst), .c10_lmdn(lmdn), .c10_out(lmout), .c10_x(16'd0),
    .c11_adig(adig), .c11_bdig(bdig), .c11_afor(afor), .c11_bvis(bvis)
  );
  a7ng_gate14_cframe_tx u_cftx (
    .clk(clk), .rst_n(rst_n), .start(cf_start), .ckpt(cf_ckpt), .seq(cf_seq),
    .pay(cf_pay), .len(cf_len), .byte_o(cf_byte), .byte_v(cf_v), .byte_r(1'b1), .busy(cf_busy)
  );

  initial clk = 0; always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) saw_ckpt <= 12'd0;
    else if (cf_start) saw_ckpt[cf_ckpt[3:0]] <= 1'b1;
  end

  task automatic u8(input logic [7:0] val);
    integer k;
    begin
      rx = 0; repeat (CPB) @(posedge clk);
      for (k = 0; k < 8; k++) begin rx = val[k]; repeat (CPB) @(posedge clk); end
      rx = 1; repeat (CPB) @(posedge clk);
    end
  endtask
  task automatic wait_ready;
    integer w;
    begin
      w = 0;
      while (!out_r && w < 40000000) begin @(posedge clk); w++; end
    end
  endtask
  task automatic uart_cmd(input logic [7:0] t, input logic [7:0] p0, input int n);
    logic [15:0] c, ln, s;
    begin
      wait_ready();
      s = seqn[15:0]; seqn = seqn + 1;
      ln = n[15:0]; c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, t);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, ln[7:0]); c = crc16_byte(c, ln[15:8]);
      if (n > 0) c = crc16_byte(c, p0);
      u8(8'hA7); u8(8'h14); u8(8'h01); u8(t);
      u8(s[7:0]); u8(s[15:8]); u8(ln[7:0]); u8(ln[15:8]);
      if (n > 0) u8(p0);
      u8(c[7:0]); u8(c[15:8]);
      repeat (40) @(posedge clk);
    end
  endtask
  task automatic uart_rew(input logic signed [7:0] rv);
    logic [15:0] c, s, ln, tnow;
    logic [7:0] p0, p1, p2;
    begin
      wait_ready();
      tnow = txn;
      p0 = rv[7:0]; p1 = tnow[7:0]; p2 = tnow[15:8];
      s = seqn[15:0]; seqn = seqn + 1; ln = 16'd3; c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, 8'h05);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, ln[7:0]); c = crc16_byte(c, ln[15:8]);
      c = crc16_byte(c, p0); c = crc16_byte(c, p1); c = crc16_byte(c, p2);
      u8(8'hA7); u8(8'h14); u8(8'h01); u8(8'h05);
      u8(s[7:0]); u8(s[15:8]); u8(ln[7:0]); u8(ln[15:8]);
      u8(p0); u8(p1); u8(p2);
      u8(c[7:0]); u8(c[15:8]);
      repeat (40) @(posedge clk);
    end
  endtask
  task automatic dump_cframes;
    integer w;
    begin
      dump = 1; @(posedge clk); dump = 0;
      w = 0;
      while (saw_ckpt != 12'hFFF && w < 200000) begin @(posedge clk); w++; end
    end
  endtask

  initial begin
    fails = 0; rx = 1; rst_n = 0; seqn = 1; mem_we = 0; dump = 0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk); rst_n = 1;
    for (i = 0; i < NPARAM; i++) begin
      @(posedge clk); mem_we <= 1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 0;
    if (mode != 4'h5) begin $display("FAIL boot MODE"); fails++; end
    $display("CFRAME C1 MODE=%h", mode);
    uart_cmd(8'h02, 0, 0);
    wait_ready();
    if (mode != 4'h5) begin $display("FAIL TRAIN MODE"); fails++; end
    // G5 mapping via UART (legal tokens/reward only). 20 PRE_A lessons wrap persist (WRAP=6);
    // HOLD_A probe + PRE_A reward is the mapping that yields pack 0706050403010002 / OUT 549.
    uart_cmd(8'h03, T_HOLD_A, 1); uart_cmd(8'h04, 0, 0);
    uart_cmd(8'h03, T_PRE_A, 1); uart_cmd(8'h04, 0, 0); uart_rew(8'sd3);
    uart_cmd(8'h03, T_HOLD_A, 1); uart_cmd(8'h04, 0, 0);
    uart_cmd(8'h06, 0, 0);
    uart_cmd(8'h07, 0, 0);
    uart_cmd(8'h08, 0, 0);
    uart_cmd(8'h03, T_HOLD_A, 1); uart_cmd(8'h04, 0, 0);
    uart_cmd(8'h03, T_PRE_A, 1); uart_cmd(8'h04, 0, 0);
    uart_cmd(8'h09, 0, 0);
    wait_ready();
    $display("CFRAME C1 MODE=%h (want 8)", mode);
    if (mode != 4'h8) begin $display("FAIL FREEZE MODE=%h", mode); fails++; end
    dump_cframes();
    uart_cmd(8'h0C, T_HOLD_A, 1);
    i = 0; while (!lmdn && i < 40000000) begin @(posedge clk); i++; end
    $display("CFRAME C10 OUT=%0d LMST=%0d LMDN=%0d TOPK=%h", lmout, lmst, lmdn, topk);
    if (lmout !== 10'd549) begin $display("FAIL HELD_A OUT"); fails++; end
    uart_cmd(8'h0C, T_UNREL, 1);
    i = 0; while (!lmdn && i < 40000000) begin @(posedge clk); i++; end
    $display("CFRAME C10 UNREL OUT=%0d TOPK=%h", lmout, topk);
    if (lmout !== 10'd861) begin $display("FAIL UNREL OUT"); fails++; end
    uart_cmd(8'h0C, T_CONTRA, 1);
    i = 0; while (!lmdn && i < 40000000) begin @(posedge clk); i++; end
    uart_cmd(8'h0A, 0, 0);
    uart_cmd(8'h02, 0, 0);
    wait_ready();
    if (mode != 4'h5) begin $display("FAIL B TRAIN MODE"); fails++; end
    uart_cmd(8'h03, T_PRE_B, 1); uart_cmd(8'h04, 0, 0); uart_rew(8'sd3);
    uart_cmd(8'h03, T_HOLD_B, 1); uart_cmd(8'h04, 0, 0);
    uart_cmd(8'h06, 0, 0); uart_cmd(8'h07, 0, 0); uart_cmd(8'h08, 0, 0);
    uart_cmd(8'h09, 0, 0);
    wait_ready();
    if (mode != 4'h8) begin $display("FAIL B FREEZE"); fails++; end
    uart_cmd(8'h0C, T_HOLD_B, 1);
    i = 0; while (!lmdn && i < 40000000) begin @(posedge clk); i++; end
    $display("CFRAME C10 HOLDB OUT=%0d TOPK=%h", lmout, topk);
    if (lmout !== 10'd237) begin $display("FAIL HELD_B OUT"); fails++; end
    if (saw_ckpt != 12'hFFF) begin $display("FAIL missing CFRAME ckpt=%h", saw_ckpt); fails++; end
    if (fails == 0) $display("GATE14_20_UART_XSIM_PASS MODE8=%0d OUTA=549 OUTB=%0d ckpt=%h", mode==4'h8, lmout, saw_ckpt);
    else $display("GATE14_20_UART_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
  initial begin #800s; $display("FAIL watchdog"); $finish; end
endmodule
