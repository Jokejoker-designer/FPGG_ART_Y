`timescale 1ns/1ps
// Project A candidate. Interface and clocked READ_FIRST RTL behavior match
// snap_ram4k16; only the requested physical resource changes to distributed RAM.
module snap_ram4k16_lutram (
    input  logic               clk,
    input  logic               we,
    input  logic [11:0]        waddr,
    input  logic signed [15:0] wdata,
    input  logic [11:0]        raddr,
    output logic signed [15:0] rdata
);
    (* ram_style = "distributed", rw_addr_collision = "yes" *)
    logic signed [15:0] mem [0:4095];

    always_ff @(posedge clk) begin
        rdata <= mem[raddr];
        if (we)
            mem[waddr] <= wdata;
    end
endmodule

// Dedicated source-substitution bind. The frozen core keeps instantiating the
// frozen module name; candidate projects compile this file with the define and
// deliberately exclude rtl/lm/snap_ram4k16.sv.
`ifdef A7LM06_SNAP_LUTRAM_BIND
module snap_ram4k16 (
    input  logic               clk,
    input  logic               we,
    input  logic [11:0]        waddr,
    input  logic signed [15:0] wdata,
    input  logic [11:0]        raddr,
    output logic signed [15:0] rdata
);
    snap_ram4k16_lutram u_candidate (.*);
endmodule
`endif
