`timescale 1ns/1ps
// Last-token snapshots for 4-layer bwd. All values are already sat16.
//   n1  : 0    + ly*96  + d     (384)
//   n2  : 384  + ly*96  + d     (384)
//   attn: 768  + ly*96  + d     (384)
//   hid : 1152 + ly*192 + hh    (768)
// Total 1920 of 2048 x INT16 = 1 RAMB36.
module snap_ram16 (
    input  logic               clk,
    input  logic               we,
    input  logic [10:0]        waddr,
    input  logic signed [15:0] wdata,
    input  logic [10:0]        raddr,
    output logic signed [15:0] rdata
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [15:0] mem [0:2047];

    always_ff @(posedge clk) begin
        rdata <= mem[raddr];
        if (we)
            mem[waddr] <= wdata;
    end
endmodule
