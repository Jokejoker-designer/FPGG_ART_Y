`timescale 1ns/1ps
package a7eam01r_pkg;
    localparam int E1_RECS      = 4096;
    localparam int E1_AW        = 12;
    localparam int E1_BANKS     = 8;
    localparam int E1_BUCK      = 256;
    localparam int E1_SLOTS     = 32;
    localparam int E1_SLOT_W    = 5;
    localparam int E1_IDX_AW    = 13; // {bucket[7:0], slot[4:0]}
    localparam int E1_IDX_DW    = 13; // {valid, id[11:0]}
    localparam int E1_HIT_MAX0  = 8;
    localparam int E1_MARGIN0   = 4;

    function automatic logic [7:0] e1_byte(input logic [63:0] key, input int unsigned b);
        return key[8*b +: 8];
    endfunction

    function automatic logic [12:0] e1_idx_addr(input logic [7:0] buck, input logic [4:0] slot);
        return {buck, slot};
    endfunction

    function automatic logic [7:0] e1_flip1(input logic [7:0] s, input logic [2:0] bitn);
        return s ^ (8'h1 << bitn);
    endfunction
endpackage
