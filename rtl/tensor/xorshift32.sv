`timescale 1ns/1ps
module xorshift32 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        load,
    input  logic [31:0] seed,
    input  logic        step,
    output logic [31:0] state
);
    function automatic [31:0] xs32(input [31:0] x);
        logic [31:0] s;
        begin
            s = x;
            s = s ^ (s << 13);
            s = s ^ (s >> 17);
            s = s ^ (s << 5);
            return s;
        end
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) state <= 32'h1;
        else if (load) state <= seed;
        else if (step) state <= xs32(state);
    end
endmodule
