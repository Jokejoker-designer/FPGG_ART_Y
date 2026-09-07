// tb_u9r_r3.sv — U9R R3 production-top wiring.
// Does NOT instantiate arty_a7_ng_native_v1_ab_soc_top (that pulls MIG).
// Fast AXI is not a substitute for missing UART→QSE→TYPE_CLASS nets.
// PROGRAM=NO. Cycle watchdog.
`timescale 1ns / 1ps

module tb_u9r_r3;
  logic clk, rst_n, byte_v, cmd_v, cmd_r, map_v, map_r, snap, rew_mis;
  logic [7:0] byte_i, typ, tok, rj_ver, rj_len, rj_crc, rj_typ, rj_dup, rj_busy;
  logic [15:0] seq, echo;
  logic signed [3:0] rew, rew_o;
  logic [3:0] cmd;
  integer cyc, tmo;

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_gate14_uart_cmd_rx u_rx (
    .clk(clk), .rst_n(rst_n),
    .byte_i(byte_i), .byte_v_i(byte_v),
    .cmd_valid_o(cmd_v), .cmd_ready_i(cmd_r),
    .cmd_type_o(typ), .cmd_seq_o(seq), .tok_o(tok), .rew_o(rew), .echo_o(echo),
    .rj_ver(rj_ver), .rj_len(rj_len), .rj_crc(rj_crc), .rj_typ(rj_typ),
    .rj_dup(rj_dup), .rj_busy(rj_busy)
  );

  a7ng_gate14_cmd_map u_map (
    .clk(clk), .rst_n(rst_n),
    .in_v(cmd_v), .in_r(cmd_r),
    .typ(typ), .tok(tok), .rew(rew), .echo(echo), .fpga_txn(16'd0),
    .out_v(map_v), .out_r(map_r),
    .cmd(cmd), .tok_o(), .rew_o(rew_o), .snap_v(snap), .rew_mismatch(rew_mis)
  );

  logic map_seen;
  assign map_r = 1'b1;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) map_seen <= 1'b0;
    else if (map_v) map_seen <= 1'b1;
  end

  `include "a7ng_gate14_crc.svh"
  task automatic send_frame(input logic [7:0] t, input logic [15:0] s, input logic [15:0] ln);
    logic [15:0] crc;
    integer k;
    begin
      crc = 16'hFFFF;
      crc = crc16_byte(crc, 8'h01);
      crc = crc16_byte(crc, t);
      crc = crc16_byte(crc, s[7:0]);
      crc = crc16_byte(crc, s[15:8]);
      crc = crc16_byte(crc, ln[7:0]);
      crc = crc16_byte(crc, ln[15:8]);
      @(negedge clk); byte_v = 1; byte_i = 8'hA7; @(posedge clk);
      @(negedge clk); byte_i = 8'h14; @(posedge clk);
      @(negedge clk); byte_i = 8'h01; @(posedge clk);
      @(negedge clk); byte_i = t; @(posedge clk);
      @(negedge clk); byte_i = s[7:0]; @(posedge clk);
      @(negedge clk); byte_i = s[15:8]; @(posedge clk);
      @(negedge clk); byte_i = ln[7:0]; @(posedge clk);
      @(negedge clk); byte_i = ln[15:8]; @(posedge clk);
      @(negedge clk); byte_i = crc[7:0]; @(posedge clk);
      @(negedge clk); byte_i = crc[15:8]; @(posedge clk);
      @(negedge clk); byte_v = 0; byte_i = 0;
      for (k = 0; k < 4; k = k + 1) @(posedge clk);
    end
  endtask

  initial begin
    rst_n = 0; byte_v = 0; byte_i = 0;
    repeat (8) @(posedge clk); rst_n = 1;
    repeat (4) @(posedge clk);
    $display("R3_DUT uart_cmd_rx+cmd_map (NOT soc_top; MIG not instantiated)");
    $display("R3_RTL_FACT SOC_TOP_HAS_TYPECLASS=0 SOC_TOP_HAS_QSE=0 SOC_TOP_HAS_MIG=1");
    $display("R3_RTL_FACT TINY_GPT_DMA_GO_READY_UNCONNECTED AB_CORE_NATIVE_CTX_BIND=1");
    send_frame(8'h04, 16'd1, 16'd0);
    tmo = 0;
    while (!map_seen && tmo < 64) begin @(posedge clk); tmo++; end
    $display("R3_UART_FIRE map_seen=%0d cmd=%0d typ=%0d (no QSE fields on this path)", map_seen, cmd, typ);
    if (!map_seen || cmd !== 4'd2) begin
      $display("FIRST_DIVERGENCE UART_FIRE_DECODE map_seen=%0d cmd=%0d typ=%0d", map_seen, cmd, typ);
      #20 $finish;
    end
    $display("FULL_SOC_RESULT INTEGRATION_GAP SOC_TOP_INSTANTIATES_MIG_NO_FAST_AXI_SUBSTITUTE");
    $display("FULL_SOC_RESULT INTEGRATION_GAP UART_QSE_TYPECLASS_NOT_IN_SOC_TOP");
    $display("FULL_SOC_RESULT INTEGRATION_GAP NATIVE_CTX_BIND_STILL_PRODUCTION_LM_PACK");
    $display("U9R_R3_INTEGRATION_GAP");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > 400000) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
