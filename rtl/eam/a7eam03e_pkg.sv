`timescale 1ns/1ps
package a7eam03e_pkg;
    localparam int E3_D        = 32;
    localparam int E3_P        = 64;
    localparam int E3_VOC      = 256;
    localparam int E3_TMAX     = 46;
    localparam int E3_SH       = 8;
    localparam int E3_MARG     = 4096;
    localparam logic [31:0] E3_SEED0 = 32'hA7E03EA1;

    function automatic logic signed [15:0] e3_sat16(input logic signed [31:0] x);
        if (x > 32'sd32767)  return 16'sd32767;
        if (x < -32'sd32768) return -16'sd32768;
        return x[15:0];
    endfunction

    function automatic logic signed [7:0] e3_sat8(input logic signed [15:0] x);
        if (x > 16'sd127)  return 8'sd127;
        if (x < -16'sd128) return -8'sd128;
        return x[7:0];
    endfunction

    function automatic logic signed [7:0] e3_sgn8(input logic signed [15:0] g);
        if (g > 0) return 8'sd1;
        if (g < 0) return -8'sd1;
        return 8'sd0;
    endfunction

    function automatic logic [15:0] e3_abs16(input logic signed [15:0] x);
        return x[15] ? 16'(-x) : 16'(x);
    endfunction

    function automatic logic [31:0] e3_xorshift(input logic [31:0] s);
        logic [31:0] x;
        x = s ^ (s << 13);
        x = x ^ (x >> 17);
        x = x ^ (x << 5);
        return (x == 32'd0) ? E3_SEED0 : x;
    endfunction
endpackage
