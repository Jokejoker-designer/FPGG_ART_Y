`timescale 1ns / 1ps
module tb_a7ng_gate14_authority;
  `include "../../rtl/native_graph/control/a7ng_gate14_crc.svh"
  logic clk, rst_n, bv, crdy, cv, in_r, out_v, out_r, snap, mis;
  logic [7:0] b, typ, tok, qtok, rjv, rjl, rjc, rjt, rjd, rjb;
  logic signed [3:0] rew, qrew;
  logic [15:0] seq, echo, txn;
  logic [3:0] cmd;
  logic mis_lat;
  integer fails, i;
  a7ng_gate14_uart_cmd_rx u_d (
    .clk(clk), .rst_n(rst_n), .byte_i(b), .byte_v_i(bv),
    .cmd_valid_o(cv), .cmd_ready_i(in_r),
    .cmd_type_o(typ), .cmd_seq_o(seq), .tok_o(tok), .rew_o(rew), .echo_o(echo),
    .rj_ver(rjv), .rj_len(rjl), .rj_crc(rjc), .rj_typ(rjt), .rj_dup(rjd), .rj_busy(rjb)
  );
  a7ng_gate14_cmd_map u_m (
    .clk(clk), .rst_n(rst_n), .in_v(cv), .in_r(in_r),
    .typ(typ), .tok(tok), .rew(rew), .echo(echo), .fpga_txn(txn),
    .out_v(out_v), .out_r(out_r), .cmd(cmd), .tok_o(qtok), .rew_o(qrew),
    .snap_v(snap), .rew_mismatch(mis)
  );
  initial clk = 0; always #5 clk = ~clk;
  always @(posedge clk) if (mis) mis_lat <= 1'b1;
  task automatic push(input logic [7:0] x);
    begin @(negedge clk); b = x; bv = 1; @(posedge clk); @(negedge clk); bv = 0; end
  endtask
  task automatic send_empty(input logic [7:0] t, input logic [15:0] s);
    logic [15:0] c;
    begin
      c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, t);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, 8'h00); c = crc16_byte(c, 8'h00);
      push(8'hA7); push(8'h14); push(8'h01); push(t);
      push(s[7:0]); push(s[15:8]); push(8'h00); push(8'h00);
      push(c[7:0]); push(c[15:8]);
    end
  endtask
  task automatic send_1(input logic [7:0] t, input logic [15:0] s, input logic [7:0] p0);
    logic [15:0] c;
    begin
      c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, t);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, 8'h00);
      c = crc16_byte(c, p0);
      push(8'hA7); push(8'h14); push(8'h01); push(t);
      push(s[7:0]); push(s[15:8]); push(8'h01); push(8'h00); push(p0);
      push(c[7:0]); push(c[15:8]);
    end
  endtask
  task automatic send_rew_bad(input logic [15:0] s);
    logic [15:0] c;
    logic [7:0] p0, p1, p2;
    begin
      p0 = 8'h03; p1 = 8'h00; p2 = 8'h00;
      c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, 8'h05);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, 8'h03); c = crc16_byte(c, 8'h00);
      c = crc16_byte(c, p0); c = crc16_byte(c, p1); c = crc16_byte(c, p2);
      push(8'hA7); push(8'h14); push(8'h01); push(8'h05);
      push(s[7:0]); push(s[15:8]); push(8'h03); push(8'h00);
      push(p0); push(p1); push(p2);
      push(c[7:0]); push(c[15:8]);
    end
  endtask
  initial begin
    fails = 0; bv = 0; out_r = 1; rst_n = 0; txn = 16'h00AA; mis_lat = 0;
    repeat (4) @(posedge clk); rst_n = 1;
    send_empty(8'h02, 16'd1);
    i = 0; while (!out_v && i < 50) begin @(posedge clk); i++; end
    if (cmd !== 4'd9) begin $display("FAIL TRAIN map"); fails++; end
    if (cmd == 4'h5) begin $display("FAIL host MODE bits"); fails++; end
    @(posedge clk);
    send_empty(8'h99, 16'd2);
    repeat (30) @(posedge clk);
    if (rjt == 0) begin $display("FAIL unknown type"); fails++; end
    send_rew_bad(16'd3);
    repeat (40) @(posedge clk);
    if (!mis_lat) begin $display("FAIL reward txn mismatch"); fails++; end
    send_empty(8'h09, 16'd4);
    i = 0; while (!out_v && i < 50) begin @(posedge clk); i++; end
    if (cmd !== 4'd7) begin $display("FAIL FREEZE"); fails++; end
    send_1(8'h10, 16'd5, 8'h08);
    repeat (30) @(posedge clk);
    if (rjt < 8'd2) begin $display("FAIL MODE-like TYPE"); fails++; end
    if (fails == 0) $display("GATE14_COMMAND_AUTHORITY_XSIM_PASS");
    else $display("GATE14_COMMAND_AUTHORITY_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
