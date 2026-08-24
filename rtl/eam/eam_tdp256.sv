`timescale 1ns/1ps
import a7eam00_pkg::*;
// Inferred TDP 256-bit x 4096. Port A lookup / AXI; port B scan / write-back.
module eam_tdp256 (
    input  logic                 clk,
    input  logic                 we_a,
    input  logic [EAM_AW-1:0]    addr_a,
    input  logic [255:0]         wdata_a,
    output logic [255:0]         rdata_a,
    input  logic                 we_b,
    input  logic [EAM_AW-1:0]    addr_b,
    input  logic [255:0]         wdata_b,
    output logic [255:0]         rdata_b
);
    // Scan uses distinct even/odd ways; write is port-B only. No same-address
    // collision, so do not advertise "yes" (that trips 00S RAM-collision CWs).
    (* ram_style = "block", rw_addr_collision = "no" *)
    logic [255:0] mem [0:EAM_ENTRIES-1];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
        if (we_b)
            mem[addr_b] <= wdata_b;
    end
endmodule
