`timescale 1ns/1ps
package a7eam00_pkg;
    localparam int EAM_SETS     = 256;
    localparam int EAM_WAYS     = 16;
    localparam int EAM_ENTRIES  = EAM_SETS * EAM_WAYS;
    localparam int EAM_AW       = 12;
    localparam int EAM_SET_W    = 8;
    localparam int EAM_WAY_W    = 4;
    localparam int EAM_VEC_B    = 16;
    localparam int EAM_CTRL_D   = 32;
    localparam int EAM_HIT_MAX0 = 0;
    localparam int EAM_EMA_SH0  = 2;

    typedef struct packed {
        logic [15:0] flags;
        logic [15:0] tag;
        logic [15:0] age;
        logic [7:0]  conf;
        logic [7:0]  token;
        logic [127:0] vec;
        logic [63:0] key;
    } eam_entry_t;

    function automatic logic [EAM_SET_W-1:0] eam_set_of(input logic [63:0] key);
        return key[EAM_SET_W-1:0];
    endfunction

    function automatic logic [EAM_AW-1:0] eam_addr(
        input logic [EAM_SET_W-1:0] setx,
        input logic [EAM_WAY_W-1:0] wayx
    );
        return {setx, wayx};
    endfunction

    function automatic logic eam_valid_of(
        input eam_entry_t e,
        input logic [7:0] epoch
    );
        return e.flags[0] && (e.tag[7:0] == epoch);
    endfunction

    // Balanced adder tree (not a 64-step chain) so Hamming fits a 100 MHz stage.
    function automatic logic [3:0] eam_pop8(input logic [7:0] x);
        logic [3:0] n;
        n = {3'b0, x[0]} + {3'b0, x[1]} + {3'b0, x[2]} + {3'b0, x[3]}
          + {3'b0, x[4]} + {3'b0, x[5]} + {3'b0, x[6]} + {3'b0, x[7]};
        return n;
    endfunction

    function automatic logic [6:0] eam_pop64(input logic [63:0] x);
        logic [3:0] p0, p1, p2, p3, p4, p5, p6, p7;
        logic [5:0] lo, hi;
        p0 = eam_pop8(x[7:0]);
        p1 = eam_pop8(x[15:8]);
        p2 = eam_pop8(x[23:16]);
        p3 = eam_pop8(x[31:24]);
        p4 = eam_pop8(x[39:32]);
        p5 = eam_pop8(x[47:40]);
        p6 = eam_pop8(x[55:48]);
        p7 = eam_pop8(x[63:56]);
        lo = {2'b0, p0} + {2'b0, p1} + {2'b0, p2} + {2'b0, p3};
        hi = {2'b0, p4} + {2'b0, p5} + {2'b0, p6} + {2'b0, p7};
        return {1'b0, lo} + {1'b0, hi};
    endfunction

    function automatic logic [6:0] eam_hamming(input logic [63:0] a, input logic [63:0] b);
        return eam_pop64(a ^ b);
    endfunction

    function automatic logic signed [7:0] eam_sat8(input logic signed [15:0] x);
        if (x > 16'sd127) return 8'sd127;
        if (x < -16'sd128) return -8'sd128;
        return x[7:0];
    endfunction

    function automatic logic signed [7:0] eam_ema8(
        input logic signed [7:0] vold,
        input logic signed [7:0] ctx,
        input logic [3:0] sh
    );
        logic signed [8:0] d, adj;
        logic signed [15:0] sum;
        logic [3:0] s;
        s = (sh == 4'd0) ? 4'd1 : ((sh > 4'd7) ? 4'd7 : sh);
        d = $signed({ctx[7], ctx}) - $signed({vold[7], vold});
        adj = d >>> s;
        sum = $signed({{7{vold[7]}}, vold}) + $signed({{7{adj[8]}}, adj});
        return eam_sat8(sum);
    endfunction

    function automatic logic [127:0] eam_ema_vec(
        input logic [127:0] vold,
        input logic [127:0] ctx,
        input logic [3:0] sh
    );
        logic [127:0] r;
        int i;
        for (i = 0; i < EAM_VEC_B; i++)
            r[8*i +: 8] = eam_ema8(vold[8*i +: 8], ctx[8*i +: 8], sh);
        return r;
    endfunction

    function automatic logic [7:0] eam_inc_conf(input logic [7:0] c);
        return (c == 8'hFF) ? c : (c + 8'd1);
    endfunction

    function automatic logic [15:0] eam_inc_age(input logic [15:0] a);
        return (a == 16'hFFFF) ? a : (a + 16'd1);
    endfunction

    function automatic eam_entry_t eam_new_entry(
        input logic [63:0] key,
        input logic [127:0] vec,
        input logic [7:0] token,
        input logic [7:0] epoch
    );
        eam_entry_t e;
        e.key   = key;
        e.vec   = vec;
        e.token = token;
        e.conf  = 8'd1;
        e.age   = 16'd0;
        e.tag   = {8'd0, epoch};
        e.flags = 16'd1;
        return e;
    endfunction
endpackage
