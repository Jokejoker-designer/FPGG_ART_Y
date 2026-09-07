// tb_a7ng_id20_pack.sv — sentinel 799999 = 20'hC34FF, no low-8 alias. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_id20_pack;
  import a7ng_pkg::*;
  node_id_t id [8];
  logic [159:0] p20;
  logic [63:0]  p8;
  logic         alias8;
  integer fail, i;

  a7ng_id20_pack dut (
    .id_i(id), .pack20_o(p20), .pack8_diag_o(p8), .low8_alias_o(alias8)
  );

  initial begin
    fail = 0;
    for (i = 0; i < 8; i = i + 1) id[i] = '0;
    id[0] = 32'h000C_34FF; // 799999
    id[1] = 32'h0000_00FF;
    id[2] = 32'h0000_04FF;
    #1;
    if (p20[19:0] !== 20'hC34FF) begin fail = fail + 1; $display("SENT20 %h", p20[19:0]); end
    if (p8[7:0] !== 8'hFF) begin fail = fail + 1; $display("DIAG8 %h", p8[7:0]); end
    if (p20[19:0] === {12'd0, p8[7:0]}) begin
      fail = fail + 1; $display("LIVE_PATH_COLLAPSED_TO_LOW8");
    end
    if (p20[19:0] === p20[7:0]) begin
      fail = fail + 1; $display("20BIT_EQ_LOW8");
    end
    if (p20[19:0] === 20'h000FF) begin fail = fail + 1; $display("ALIASED_FF"); end
    if (p20[19:0] === 20'h004FF) begin fail = fail + 1; $display("ALIASED_4FF"); end
    if (!alias8) begin fail = fail + 1; $display("ALIAS_FLAG"); end
    if (fail == 0) $display("U4B_ID20_PACK_PASS sentinel=C34FF");
    else $display("U4B_ID20_PACK_FAIL fail=%0d", fail);
    $finish;
  end
endmodule
