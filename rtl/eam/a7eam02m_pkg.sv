`timescale 1ns/1ps
package a7eam02m_pkg;
    localparam int E2M_EPS       = 256;
    localparam int E2M_EP_W      = 8;
    localparam int E2M_TXT_MAX   = 46;
    localparam int E2M_HIT_MAX0  = 8;
    localparam int E2M_MARGIN0   = 4;

    localparam logic [63:0] E2M_FOLD_IV = 64'h0EA1020D02A70001;

    localparam logic [7:0] E2M_NACK_OK      = 8'd0;
    localparam logic [7:0] E2M_NACK_TEACH   = 8'd1;
    localparam logic [7:0] E2M_NACK_FULL    = 8'd2;
    localparam logic [7:0] E2M_NACK_BADEP   = 8'd3;
    localparam logic [7:0] E2M_NACK_COLLIDE = 8'd4;
    localparam logic [7:0] E2M_NACK_EMPTY   = 8'd5;

    typedef struct packed {
        logic         valid;
        logic [7:0]   gen;
        logic [7:0]   token;
        logic [7:0]   cue_n;
        logic [127:0] vec;
    } e2m_ep_t;

    function automatic logic e2m_live(input e2m_ep_t e, input logic [7:0] gen);
        return e.valid && (e.gen == gen);
    endfunction

    function automatic logic [63:0] e2m_rotl1(input logic [63:0] x);
        return {x[62:0], x[63]};
    endfunction

    function automatic logic [63:0] e2m_rotl8(input logic [63:0] x);
        return {x[55:0], x[63:56]};
    endfunction

    function automatic logic [63:0] e2m_fold_step(input logic [63:0] acc, input logic [7:0] b);
        logic [63:0] x;
        x = acc ^ {56'd0, b};
        x = e2m_rotl1(x);
        x = x ^ e2m_rotl8(x);
        x = x + {48'd0, b, 8'hA7};
        return x;
    endfunction

    function automatic logic [63:0] e2m_fold_mem(
        input logic [7:0] bytes [0:E2M_TXT_MAX-1],
        input int unsigned n
    );
        logic [63:0] acc;
        int unsigned i;
        acc = E2M_FOLD_IV;
        for (i = 0; i < n && i < E2M_TXT_MAX; i++)
            acc = e2m_fold_step(acc, bytes[i]);
        return acc;
    endfunction
endpackage
