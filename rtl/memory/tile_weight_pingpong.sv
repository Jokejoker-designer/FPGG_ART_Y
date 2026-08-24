`timescale 1ns/1ps
// Two banks x 8 x (256 x 128-bit). Forced Block RAM.
// Bank tags (valid / command_id / tile_index) live in tensor_microseq.
// This RAM has no generation ID; the sequencer must not read a bank
// unless that tag matches the current command and tile.
module tile_weight_pingpong (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         wr_en,
    input  logic         wr_bank,
    input  logic [7:0]   wr_k,
    input  logic [2:0]   wr_chunk,
    input  logic [127:0] wr_data,
    input  logic         rd_bank,
    input  logic [7:0]   rd_k,
    output logic [1023:0] rd_data
);
    genvar gi;
    generate
        for (gi = 0; gi < 8; gi++) begin : CH
            (* ram_style = "block" *) logic [127:0] ram0 [0:255];
            (* ram_style = "block" *) logic [127:0] ram1 [0:255];
            logic [127:0] q0, q1;
            always_ff @(posedge clk) begin
                if (wr_en && !wr_bank && (wr_chunk == gi[2:0]))
                    ram0[wr_k] <= wr_data;
                q0 <= ram0[rd_k];
            end
            always_ff @(posedge clk) begin
                if (wr_en && wr_bank && (wr_chunk == gi[2:0]))
                    ram1[wr_k] <= wr_data;
                q1 <= ram1[rd_k];
            end
            assign rd_data[gi*128 +: 128] = rd_bank ? q1 : q0;
        end
    endgenerate
endmodule
