`timescale 1ns/1ps
package a7lm05_pkg;
    localparam int V  = 512;
    localparam int D  = 96;
    localparam int C  = 64;
    localparam int H  = 4;
    localparam int L  = 4;
    localparam int FF = 192;
    localparam int DH = 24;
    localparam int NPARAM = 399360;

    localparam int OFF_TOK  = 0;
    localparam int OFF_POS  = 49152;
    localparam int OFF_L0   = 55296;
    localparam int LAYER_W  = 73728;
    localparam int OFF_HEAD = 350208;

    localparam int LIN_SHIFT = 4;
    localparam int ATTN_QK_SHIFT = 8;
    localparam int BLOCK_DEADZONE = 2;

    localparam int DDR_WBASE = 28'h0010_0000;

    // Silicon packing (XC7A100T 135 RAMB36; LM-04 r3 used 130).
    //   act_ram48k  49152 x 32 = 48 BRAM  (dense map, ly reused)
    //   W tile      emb 55296 + layer 73728 + head 49152 = 44 BRAM
    //   tensor+MIG  ~34 BRAM
    //   total       ~126 / 135
    localparam int ACT_CELLS   = 49152;           // 8 * C * D
    localparam int ACT_STRIDE  = 6144;            // C * D
    localparam int TILE_EMB    = 55296;           // OFF_L0
    localparam int TILE_LAYER  = 73728;           // LAYER_W
    localparam int TILE_HEAD   = 49152;           // NPARAM - OFF_HEAD
    localparam int NCHUNK      = NPARAM / 128;    // 3120 persist lines

    function automatic logic signed [15:0] sat16(input logic signed [31:0] x);
        if (x > 32'sd32767) return 16'sd32767;
        if (x < -32'sd32768) return -32'sd32768;
        return x[15:0];
    endfunction

    function automatic logic signed [31:0] sat32(input logic signed [63:0] x);
        if (x > 64'sd2147483647) return 32'sd2147483647;
        if (x < -64'sd2147483648) return -32'sd2147483648;
        return x[31:0];
    endfunction

    function automatic logic signed [7:0] sat8(input logic signed [31:0] x);
        if (x > 32'sd127) return 8'sd127;
        if (x < -32'sd128) return -32'sd128;
        return x[7:0];
    endfunction

    function automatic logic signed [7:0] step_sign(input logic signed [15:0] g);
        if (g > 16'sd2) return 8'sd1;
        if (g < -16'sd2) return -8'sd1;
        return 8'sd0;
    endfunction

    function automatic logic [18:0] layer_base(input logic [1:0] ly);
        return 19'(OFF_L0) + 19'(ly) * 19'(LAYER_W);
    endfunction

    localparam int LO_WQ  = 0;
    localparam int LO_WK  = 9216;
    localparam int LO_WV  = 18432;
    localparam int LO_WO  = 27648;
    localparam int LO_FF1 = 36864;
    localparam int LO_FF2 = 55296;
endpackage
