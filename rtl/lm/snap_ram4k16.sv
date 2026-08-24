`timescale 1ns/1ps
// Last-token snaps, 4 layer, d=128, ff=256.
//   n1   0     + ly*128 + d
//   n2   512   + ly*128 + d
//   attn 1024  + ly*128 + d
//   hid  1536  + ly*256 + hh
// Total 2560 of 4096 x INT16.
module snap_ram4k16 (
    input  logic               clk,
    input  logic               we,
    input  logic [11:0]        waddr,
    input  logic signed [15:0] wdata,
    input  logic [11:0]        raddr,
    output logic signed [15:0] rdata
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [15:0] mem [0:4095];

    always_ff @(posedge clk) begin
        rdata <= mem[raddr];
        if (we)
            mem[waddr] <= wdata;
    end
endmodule
