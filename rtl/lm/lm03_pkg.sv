`timescale 1ns/1ps
package lm03_pkg;
    localparam int V  = 32;
    localparam int D  = 16;
    localparam int C  = 8;
    localparam int FF = 32;

    localparam int BANK_TOK  = 0;
    localparam int BANK_POS  = 1;
    localparam int BANK_WQ   = 2;
    localparam int BANK_WK   = 3;
    localparam int BANK_WV   = 4;
    localparam int BANK_WO   = 5;
    localparam int BANK_FF1  = 6;
    localparam int BANK_FF2  = 7;
    localparam int BANK_HEAD = 8;

    localparam int BASE_TOK  = 0;
    localparam int BASE_POS  = 512;
    localparam int BASE_WQ   = 640;
    localparam int BASE_WK   = 896;
    localparam int BASE_WV   = 1152;
    localparam int BASE_WO   = 1408;
    localparam int BASE_FF1  = 1664;
    localparam int BASE_FF2  = 2176;
    localparam int BASE_HEAD = 2688;
    localparam int WMEM_WORDS = 3200;

    localparam logic [2:0] T_XS = 3'd0;
    localparam logic [2:0] T_N1 = 3'd1;
    localparam logic [2:0] T_Q  = 3'd2;
    localparam logic [2:0] T_K  = 3'd3;
    localparam logic [2:0] T_V  = 3'd4;
    localparam logic [2:0] T_A  = 3'd5;
    localparam logic [2:0] T_H  = 3'd6;
    localparam logic [2:0] T_Y  = 3'd7;

    function automatic logic [11:0] bank_base(input logic [3:0] bank);
        unique case (bank)
            4'd0: return 12'd0;
            4'd1: return 12'd512;
            4'd2: return 12'd640;
            4'd3: return 12'd896;
            4'd4: return 12'd1152;
            4'd5: return 12'd1408;
            4'd6: return 12'd1664;
            4'd7: return 12'd2176;
            4'd8: return 12'd2688;
            default: return 12'd0;
        endcase
    endfunction

    function automatic logic [9:0] act_addr(
        input logic [2:0] ten,
        input logic [2:0] tok,
        input logic [3:0] dim
    );
        return {ten, tok, dim};
    endfunction

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
endpackage
