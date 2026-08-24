`timescale 1ns/1ps
package a7lm02_pkg;
    localparam int N_LANES = 128;
    localparam int K_MAX   = 256;
    localparam int M_TILE  = 8;
    localparam int N_GEMM  = 16;
    localparam int ROW_B   = 128;
endpackage
