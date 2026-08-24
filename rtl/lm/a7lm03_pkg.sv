`timescale 1ns/1ps
package a7lm03_pkg;
    localparam int V  = 128;
    localparam int D  = 32;
    localparam int C  = 16;
    localparam int H  = 2;
    localparam int L  = 2;
    localparam int FF = 64;
    localparam int DH = 16;
    localparam int NPARAM = 25088;

    localparam int OFF_TOK  = 0;
    localparam int OFF_POS  = 4096;
    localparam int OFF_L0   = 4608;
    localparam int LAYER_W  = 8192;
    localparam int OFF_HEAD = 20992;

    localparam int LIN_SHIFT = 4;
    localparam int ATTN_QK_SHIFT = 8;
    localparam int BLOCK_DEADZONE = 2;

    function automatic logic signed [15:0] sat16(input logic signed [31:0] x);
        if (x > 32'sd32767) return 16'sd32767;
        if (x < -32'sd32768) return -16'sd32768;
        return x[15:0];
    endfunction

    function automatic logic signed [31:0] sat32(input logic signed [63:0] x);
        if (x > 64'sd2147483647) return 32'sd2147483647;
        if (x < -64'sd2147483648) return -32'sd2147483648;
        return x[31:0];
    endfunction

    function automatic logic signed [7:0] sat8(input logic signed [31:0] x);
        if (x > 32'sd127) return 8'sd127;
        if (x < -32'sd128) return -8'sd128;
        return x[7:0];
    endfunction

    function automatic logic signed [7:0] step_sign(input logic signed [15:0] g);
        if (g > 16'sd2) return 8'sd1;
        if (g < -16'sd2) return -8'sd1;
        return 8'sd0;
    endfunction

    function automatic logic [14:0] layer_base(input logic ly);
        return ly ? 15'(OFF_L0 + LAYER_W) : 15'(OFF_L0);
    endfunction

    // Layer offsets from layer_base
    localparam int LO_WQ  = 0;
    localparam int LO_WK  = 1024;
    localparam int LO_WV  = 2048;
    localparam int LO_WO  = 3072;
    localparam int LO_FF1 = 4096;
    localparam int LO_FF2 = 6144;
endpackage
