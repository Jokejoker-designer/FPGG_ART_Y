`timescale 1ns / 1ps
module tb_a7ng_gate14_parser;
  `include "../../rtl/native_graph/control/a7ng_gate14_crc.svh"
  logic clk, rst_n, bv, crdy, cv;
  logic [7:0] b, typ, tok, rjv, rjl, rjc, rjt, rjd, rjb;
  logic signed [3:0] rew;
  logic [15:0] seq, echo;
  integer fails, n, i, got;
  logic [31:0] lfsr;
  a7ng_gate14_uart_cmd_rx u_d (
    .clk(clk), .rst_n(rst_n), .byte_i(b), .byte_v_i(bv),
    .cmd_valid_o(cv), .cmd_ready_i(crdy),
    .cmd_type_o(typ), .cmd_seq_o(seq), .tok_o(tok), .rew_o(rew), .echo_o(echo),
    .rj_ver(rjv), .rj_len(rjl), .rj_crc(rjc), .rj_typ(rjt), .rj_dup(rjd), .rj_busy(rjb)
  );
  initial clk = 0; always #5 clk = ~clk;
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
  task automatic send_tok(input logic [7:0] t, input logic [15:0] s, input logic [7:0] p0);
    logic [15:0] c;
    begin
      c = 16'hFFFF;
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, t);
      c = crc16_byte(c, s[7:0]); c = crc16_byte(c, s[15:8]);
      c = crc16_byte(c, 8'h01); c = crc16_byte(c, 8'h00);
      c = crc16_byte(c, p0);
      push(8'hA7); push(8'h14); push(8'h01); push(t);
      push(s[7:0]); push(s[15:8]); push(8'h01); push(8'h00);
      push(p0);
      push(c[7:0]); push(c[15:8]);
    end
  endtask
  initial begin
    fails = 0; bv = 0; b = 0; crdy = 1; rst_n = 0; got = 0;
    repeat (4) @(posedge clk); rst_n = 1;
    send_tok(8'h03, 16'd1, 8'hA2);
    i = 0; while (!cv && i < 40) begin @(posedge clk); i++; end
    if (!cv || typ !== 8'h03 || tok !== 8'hA2) begin $display("FAIL good frame"); fails++; end
    else got++;
    @(posedge clk);
    send_tok(8'h03, 16'd1, 8'hA2);
    repeat (20) @(posedge clk);
    if (rjd == 0) begin $display("FAIL dup"); fails++; end
    push(8'hA7); push(8'h14); push(8'h02);
    repeat (8) @(posedge clk);
    if (rjv == 0) begin $display("FAIL ver"); fails++; end
    crdy = 0;
    send_empty(8'h02, 16'd2);
    i = 0; while (!cv && i < 40) begin @(posedge clk); i++; end
    send_empty(8'h09, 16'd3);
    repeat (20) @(posedge clk);
    if (rjb == 0) begin $display("FAIL busy"); fails++; end
    crdy = 1; @(posedge clk); @(posedge clk);
    lfsr = 32'hACE1;
    for (n = 0; n < 100000; n++) begin
      lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
      push(lfsr[7:0]);
    end
    repeat (1100000) @(posedge clk);
    send_empty(8'h02, 16'd7);
    i = 0; while (!cv && i < 40) begin @(posedge clk); i++; end
    if (!cv || typ !== 8'h02) begin $display("FAIL after noise"); fails++; end
    if (fails == 0) $display("GATE14_PARSER_RANDOM_XSIM_PASS n=100000 got=%0d crc_rj=%0d dup=%0d", got, rjc, rjd);
    else $display("GATE14_PARSER_RANDOM_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
  initial begin #400ms; $display("FAIL timeout"); $finish; end
endmodule
