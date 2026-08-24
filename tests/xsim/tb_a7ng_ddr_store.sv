`timescale 1ns / 1ps
module tb_a7ng_ddr_store;
  import a7ng_pkg::*;
  logic clk, rst_n, sel, req, v;
  logic [15:0] id;
  logic [27:0] addr;
  logic [31:0] bytes;

  a7ng_ddr_store dut (
    .clk(clk), .rst_n(rst_n), .sel_episode_i(sel), .rec_id_i(id), .req_i(req),
    .req_valid_o(v), .ddr_addr_o(addr), .bytes_o(bytes)
  );

  initial clk=0; always #5 clk=~clk;
  integer fails;
  initial begin
    fails=0; rst_n=0; sel=0; req=0; id=0;
    repeat(3) @(posedge clk); rst_n=1; @(posedge clk);

    @(negedge clk); sel=1; id=16'd7; req=1;
    @(posedge clk); #1; req=0;
    if (!v || addr !== (NG_DDR_EPISODE_BASE + {16'd7, 5'b00000}) || bytes !== 32'd32) begin
      $display("FAIL ep addr=%h", addr); fails=fails+1;
    end

    @(negedge clk); sel=0; id=16'd3; req=1;
    @(posedge clk); #1; req=0;
    if (!v || addr !== (NG_DDR_INDEX_BASE + {12'd0, 16'd3, 4'b0000}) || bytes !== 32'd16) begin
      $display("FAIL idx addr=%h", addr); fails=fails+1;
    end

    // host cannot inject: no host_addr port exists
    if (fails==0) $display("A7NG_MEM12_DDR_XSIM_PASS");
    else $display("A7NG_MEM12_DDR_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
