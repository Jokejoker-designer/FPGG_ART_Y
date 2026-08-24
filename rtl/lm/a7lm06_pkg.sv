`timescale 1ns/1ps
package a7lm06_pkg;
    localparam int V  = 1024;
    localparam int D  = 128;
    localparam int C  = 128;
    localparam int H  = 4;
    localparam int L  = 4;
    localparam int FF = 256;
    localparam int DH = 32;
    localparam int NPARAM = 802816;

    localparam int OFF_TOK  = 0;
    localparam int OFF_POS  = 131072;
    localparam int OFF_L0   = 147456;
    localparam int LAYER_W  = 131072;
    localparam int OFF_HEAD = 671744;

    localparam int LIN_SHIFT = 4;
    localparam int ATTN_QK_SHIFT = 8;
    localparam int BLOCK_DEADZONE = 2;

    localparam int DDR_WBASE = 28'h0010_0000;

    // Silicon (135 RAMB36). Do not keep emb+layer+head together.
    //   W: one 131072 INT8 region (tok OR pos-slice OR layer OR head) = 32 BRAM
    //   act: 8 * C * D INT16 = 131072 x 16 = 32 BRAM (2kx18)
    //        — wait 131072/2048 = 64 of 18-bit. Use 2kx18 → 64 BRAM.
    //   snap 4096 x 16 = 2 BRAM
    //   tensor+MIG ~34
    //   total ~132 / 135. Serialize tok/pos so both are not resident.
    localparam int ACT_CELLS   = 131072;          // 8 * C * D
    localparam int ACT_STRIDE  = 16384;           // C * D
    localparam int TILE_W      = 131072;          // max region
    localparam int TILE_POS    = 16384;
    localparam int NCHUNK      = NPARAM / 128;    // 6272
    localparam int SNAP_DEPTH  = 4096;

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

    function automatic logic [19:0] layer_base(input logic [1:0] ly);
        return 20'(OFF_L0) + 20'(ly) * 20'(LAYER_W);
    endfunction

    localparam int LO_WQ  = 0;
    localparam int LO_WK  = 16384;
    localparam int LO_WV  = 32768;
    localparam int LO_WO  = 49152;
    localparam int LO_FF1 = 65536;
    localparam int LO_FF2 = 98304;
endpackage
