`timescale 1ns / 1ps
module tb_a7ng_uart_rx100;
  localparam int CLK_HZ = 100_000_000;
  localparam int BAUD = 115200;
  localparam int CPB = (CLK_HZ + BAUD/2) / BAUD;
  logic clk, rst_n, rx, v;
  logic [7:0] d, ferr, oerr, cap;
  logic got;
  integer fails, i, b;
  a7ng_uart_rx100 #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
    .clk(clk), .rst_n(rst_n), .rx(rx), .data(d), .valid(v), .ferr(ferr), .oerr(oerr)
  );
  initial clk = 0;
  always #5 clk = ~clk;
  always @(posedge clk) begin
    if (v) begin got <= 1'b1; cap <= d; end
  end
  task automatic send_byte(input logic [7:0] val, input int phase, input bit bad_stop);
    integer k;
    begin
      rx = 0;
      repeat (CPB + phase) @(posedge clk);
      for (k = 0; k < 8; k++) begin
        rx = val[k];
        repeat (CPB) @(posedge clk);
      end
      rx = bad_stop ? 1'b0 : 1'b1;
      repeat (CPB) @(posedge clk);
      rx = 1;
      repeat (CPB) @(posedge clk);
    end
  endtask
  initial begin
    fails = 0; rx = 1; rst_n = 0; got = 0; cap = 0;
    repeat (8) @(posedge clk); rst_n = 1;
    repeat (20) @(posedge clk);
    send_byte(8'hA5, 0, 0);
    if (!got || cap !== 8'hA5) begin $display("FAIL valid byte got=%0d cap=%h", got, cap); fails++; end
    got = 0;
    send_byte(8'h3C, 3, 0);
    if (cap !== 8'h3C) begin $display("FAIL phase cap=%h", cap); fails++; end
    send_byte(8'h11, 0, 0); send_byte(8'h22, 0, 0);
    send_byte(8'h00, 0, 1);
    repeat (CPB*4) @(posedge clk);
    if (ferr == 0) begin $display("FAIL ferr"); fails++; end
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    rx = 0; repeat (CPB/4) @(posedge clk); rx = 1;
    repeat (CPB*4) @(posedge clk);
    if (fails == 0) $display("UART_RX100_XSIM_PASS ferr=%0d", ferr);
    else $display("UART_RX100_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
  initial begin #50ms; $display("FAIL timeout"); $finish; end
endmodule
