// tb_a7ng_hotset.sv — NG-03 hotset hit/miss/ddr_req
`timescale 1ns / 1ps

module tb_a7ng_hotset;
  logic clk, rst_n, lookup, fill, hit, miss, ddr_req;
  logic [31:0] nid, fill_id, hits, misses, ddr_addr;
  logic [63:0] data, fill_data, dout;

  a7ng_bram_hotset dut (
    .clk(clk), .rst_n(rst_n),
    .lookup_i(lookup), .node_id_i(nid),
    .hit_o(hit), .miss_o(miss), .data_o(dout),
    .fill_i(fill), .fill_id_i(fill_id), .fill_data_i(fill_data),
    .hits_o(hits), .misses_o(misses),
    .ddr_req_o(ddr_req), .ddr_addr_o(ddr_addr)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails;

  initial begin
    fails = 0;
    rst_n = 0; lookup = 0; fill = 0; nid = 0; fill_id = 0; fill_data = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // miss cold
    @(negedge clk); nid = 32'h42; lookup = 1;
    @(posedge clk); #1; lookup = 0;
    if (!miss || !ddr_req || hits !== 0 || misses !== 1) begin
      $display("FAIL cold miss"); fails = fails + 1;
    end
    if (ddr_addr !== {5'b0, 23'h42, 4'b0000}) begin
      $display("FAIL ddr_addr=%h expect NodeRecordV1 stride", ddr_addr); fails = fails + 1;
    end

    // fill then hit
    @(negedge clk); fill = 1; fill_id = 32'h42; fill_data = 64'hDEAD_BEEF_CAFE_F00D;
    @(posedge clk); #1; fill = 0;
    @(negedge clk); nid = 32'h42; lookup = 1;
    @(posedge clk); #1; lookup = 0;
    if (!hit || dout !== 64'hDEAD_BEEF_CAFE_F00D || hits !== 1) begin
      $display("FAIL hit"); fails = fails + 1;
    end

    if (fails == 0) $display("A7NG03_HOTSET_XSIM_PASS");
    else $display("A7NG03_HOTSET_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
