`timescale 1ns/1ps
import a7eam01r_pkg::*;
// 8192 x 13 TDP. addr = {bucket[7:0], slot[4:0]}.
// Init 0 so xsim treats empty slots as !valid (X would skip every hole).
module eam01r_ibank (
    input  logic                 clk,
    input  logic                 we,
    input  logic [E1_IDX_AW-1:0] waddr,
    input  logic [E1_IDX_DW-1:0] wdata,
    input  logic [E1_IDX_AW-1:0] raddr_a,
    input  logic [E1_IDX_AW-1:0] raddr_b,
    output logic [E1_IDX_DW-1:0] rdata_a,
    output logic [E1_IDX_DW-1:0] rdata_b
);
    (* ram_style = "block", rw_addr_collision = "no" *)
    logic [E1_IDX_DW-1:0] mem [0:8191];

    integer ii;
    initial begin
        for (ii = 0; ii < 8192; ii = ii + 1)
            mem[ii] = '0;
    end

    always_ff @(posedge clk) begin
        rdata_a <= mem[raddr_a];
        if (we)
            mem[waddr] <= wdata;
    end
    always_ff @(posedge clk) begin
        rdata_b <= mem[raddr_b];
    end
endmodule
