`timescale 1ns/1ps
module requantize (
    input  logic signed [31:0] in32,
    input  logic [3:0]         shift,
    output logic signed [15:0] out16
);
    logic signed [31:0] s;
    assign s = in32 >>> shift;
    always_comb begin
        if (s > 32'sd32767) out16 = 16'sd32767;
        else if (s < -32'sd32768) out16 = -16'sd32768;
        else out16 = s[15:0];
    end
endmodule
