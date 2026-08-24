`timescale 1ns/1ps
// Descriptor DMA used by later milestones. A7-LM-01 BIST has its own master.
module ddr_dma (
    input  logic clk,
    input  logic rst_n,
    input  logic go,
    input  logic wr,
    input  logic [27:0] addr,
    input  logic [31:0] bytes,
    output logic busy,
    output logic done
);
    assign busy = 1'b0;
    assign done = 1'b0;
endmodule
