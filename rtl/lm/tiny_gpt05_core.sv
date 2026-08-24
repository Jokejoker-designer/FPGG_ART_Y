`timescale 1ns/1ps
import lm03_pkg::*;
module tiny_gpt05_core (
    input  logic clk,
    input  logic rst_n,
    input  logic mem_we,
    input  logic [3:0] mem_bank,
    input  logic [11:0] mem_addr,
    input  logic signed [7:0] mem_wdata,
    output logic signed [7:0] mem_rdata,
    input  logic ctx_load,
    input  logic [3:0] ctx_n,
    input  logic [4:0] ctx_tok [0:7],
    input  logic start,
    input  logic start_train,
    input  logic after_mode,
    input  logic do_snap,
    input  logic do_restore,
    input  logic [4:0] tgt,
    input  logic [3:0] lr,
    input  logic [2:0] dump_t,
    input  logic [3:0] dump_d,
    output logic busy,
    output logic done,
    output logic [4:0] pred,
    output logic signed [31:0] logits [0:31],
    output logic signed [15:0] y_reg [0:7][0:15],
    output logic [7:0] attn_w [0:7][0:7],
    output logic signed [15:0] dZ [0:31],
    output logic signed [15:0] dH [0:15],
    output logic signed [15:0] g_tok [0:15],
    output logic signed [15:0] g_pos [0:15],
    output logic signed [15:0] g_head0 [0:15],
    output logic signed [15:0] g_head1 [0:15],
    output logic signed [15:0] g_headt [0:15],
    output logic [15:0] wr_tok_n,
    output logic [15:0] wr_pos_n,
    output logic [15:0] wr_head_n,
    output logic [15:0] wr_blk_n,
    output logic [15:0] last_loss
);
    typedef enum logic [6:0] {
        ST_IDLE    = 6'd0,
        ST_EMB_SET = 6'd1,
        ST_EMB_W   = 6'd2,
        ST_EMB_CAP = 6'd3,
        ST_LN_INIT = 6'd4,
        ST_LN_RS   = 6'd5,
        ST_LN_WS   = 6'd6,
        ST_LN_MU   = 6'd7,
        ST_LN_RV   = 6'd8,
        ST_LN_WV   = 6'd9,
        ST_LN_SC   = 6'd10,
        ST_LN_SQ   = 6'd11,
        ST_LN_OI   = 6'd12,
        ST_LN_RO   = 6'd13,
        ST_LN_WO   = 6'd14,
        ST_LN_DV   = 6'd15,
        ST_MV_INIT = 6'd16,
        ST_MV_SET  = 6'd17,
        ST_MV_W    = 6'd18,
        ST_MV_MAC  = 6'd19,
        ST_MV_WR   = 6'd20,
        ST_AT_I    = 6'd21,
        ST_AT_SET  = 6'd22,
        ST_AT_W    = 6'd23,
        ST_AT_MAC  = 6'd24,
        ST_AT_SC   = 6'd25,
        ST_AT_MX   = 6'd26,
        ST_AT_EX   = 6'd27,
        ST_AT_Z    = 6'd28,
        ST_AT_VS   = 6'd29,
        ST_AT_VW   = 6'd30,
        ST_AT_VM   = 6'd31,
        ST_AT_GO   = 6'd32,
        ST_AT_DV   = 6'd33,
        ST_RES_SET = 6'd34,
        ST_RES_W   = 6'd35,
        ST_RES_CAP = 6'd36,
        ST_ARG     = 6'd37,
        ST_DONE    = 6'd38,
        ST_SMX     = 6'd39,
        ST_SEX     = 6'd40,
        ST_SS      = 6'd41,
        ST_DZ      = 6'd42,
        ST_DH_SET  = 6'd43,
        ST_DH_W    = 6'd44,
        ST_DH_MAC  = 6'd45,
        ST_DH_DV   = 6'd46,
        ST_HU_SET  = 6'd47,
        ST_HU_W    = 6'd48,
        ST_HU_DV   = 6'd49,
        ST_HU_WR   = 6'd50,
        ST_TK_SET  = 6'd51,
        ST_TK_W    = 6'd52,
        ST_TK_WR   = 6'd53,
        ST_PS_SET  = 6'd54,
        ST_PS_W    = 6'd55,
        ST_PS_WR   = 6'd56,
        ST_CP_RD   = 6'd57,
        ST_CP_WR   = 6'd58,
        ST_DH_GO   = 7'd59,
        ST_HU_GO   = 7'd60,
        ST_YCP     = 7'd61,
        ST_F2_SET  = 7'd62,
        ST_F2_W    = 7'd63,
        ST_F2_ACC  = 7'd64,
        ST_F1_SET  = 7'd65,
        ST_F1_W    = 7'd66,
        ST_F1_ACC  = 7'd67,
        ST_DHADD   = 7'd68,
        ST_WO_SET  = 7'd69,
        ST_WO_W    = 7'd70,
        ST_WO_ACC  = 7'd71,
        ST_ATB_VS  = 7'd72,
        ST_ATB_VW  = 7'd73,
        ST_ATB_VD  = 7'd74,
        ST_ATB_VG  = 7'd75,
        ST_ATB_DE  = 7'd76,
        ST_ATB_DG  = 7'd77,
        ST_ATB_KS  = 7'd78,
        ST_ATB_KW  = 7'd79,
        ST_ATB_QK  = 7'd80,
        ST_WQ_SET  = 7'd81,
        ST_WQ_W    = 7'd82,
        ST_WQ_ACC  = 7'd83,
        ST_WK_SET  = 7'd84,
        ST_WK_W    = 7'd85,
        ST_WK_ACC  = 7'd86,
        ST_WV_SET  = 7'd87,
        ST_WV_W    = 7'd88,
        ST_WV_ACC  = 7'd89,
        ST_TE_S    = 7'd90,
        ST_TE_W    = 7'd91,
        ST_TE_A    = 7'd92
    } state_t;

    typedef enum logic [2:0] {
        MV_Q    = 3'd0,
        MV_K    = 3'd1,
        MV_V    = 3'd2,
        MV_WO   = 3'd3,
        MV_FF1  = 3'd4,
        MV_FF2  = 3'd5,
        MV_HEAD = 3'd6
    } mv_t;

    state_t state;
    mv_t mv_kind;
    logic ln_pass;
    logic res_pass;
    logic [3:0] n;
    logic [4:0] toks [0:7];
    logic [2:0] t, qi, kj;
    logic [3:0] d;
    logic [5:0] row, col;
    logic signed [47:0] acc48;
    logic signed [31:0] mu;
    logic [15:0] scale;
    logic signed [31:0] score [0:7];
    logic [7:0] exps [0:7];
    logic [15:0] zsum;
    logic signed [15:0] hid [0:31];
    logic signed [31:0] mx;
    integer zi, zk, zj;

    logic idle;
    logic [11:0] waddr_a, waddr_b, host_abs, w_off;
    logic signed [7:0] wr, wr_b;
    logic act_we;
    logic [9:0] aaddr_a, aaddr_b;
    logic signed [31:0] act_wd, act_a, act_b;
    logic mac_clr, mac_en;
    logic signed [31:0] mac_a, mac_b;
    logic signed [63:0] mac_acc;
    logic div_start, div_done;
    logic signed [47:0] div_n;
    logic [15:0] div_d;
    logic signed [31:0] div_q;
    logic sq_start, sq_done;
    logic [15:0] sq_y;
    logic [31:0] var_u;
    logic arg_init, arg_step;
    logic [4:0] arg_pred;
    logic signed [31:0] arg_best;
    logic signed [31:0] z_now;
    logic signed [31:0] x_s, y_s, emb_s, hid_s;
    logic [2:0] n_last;
    logic [5:0] rows_m, cols_m;
    logic [3:0] wbank;
    logic [2:0] src_ten, dst_ten;
    logic signed [31:0] mx_c;
    logic [15:0] z_c;
    logic signed [31:0] e_tmp;
    logic signed [15:0] s16;
    logic do_train, cp_up, sum_ok;
    logic [4:0] tgt_r, vv;
    logic [3:0] lr_r;
    logic [11:0] cp_i;
    logic [15:0] sm_exps [0:31];
    logic [15:0] sm_s;
    logic signed [31:0] z_mx;
    logic signed [31:0] e32;
    logic signed [15:0] g16, h16;
    logic signed [7:0] new_w;
    logic sgd_we, cp_we;
    logic [11:0] sgd_addr, cp_waddr;
    logic signed [7:0] sgd_data, ckpt_r, ckpt_w;
    logic [11:0] ckpt_a;
    logic signed [15:0] n1_reg [0:7][0:15];
    logic signed [15:0] n2_reg [0:15];
    logic signed [15:0] a_last [0:15];
    logic [15:0] az_last;
    logic signed [15:0] dY [0:15];
    logic signed [15:0] dHb [0:15];
    logic signed [15:0] dN2 [0:15];
    logic signed [15:0] dA [0:15];
    logic signed [15:0] dQ [0:15];
    logic signed [15:0] dN1 [0:15];
    logic signed [15:0] dHid [0:31];
    logic signed [31:0] dHid_acc [0:31];
    logic signed [31:0] dN2_acc [0:15];
    logic signed [31:0] dA_acc [0:15];
    logic signed [31:0] dN1_acc [0:15];
    logic signed [15:0] dK [0:7][0:15];
    logic signed [15:0] dV [0:7][0:15];
    logic signed [31:0] gacc;
    logic signed [31:0] de_acc;
    logic signed [15:0] dscore;
    logic signed [31:0] dq_acc [0:15];
    logic [2:0] bj;
    logic [4:0] last_tok;
    logic [2:0] last_pos;
    logic [3:0] elr;

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
    function automatic logic signed [31:0] sx8(input logic signed [7:0] x);
        return {{24{x[7]}}, x};
    endfunction
    function automatic logic signed [31:0] sx16(input logic signed [15:0] x);
        return {{16{x[15]}}, x};
    endfunction
    function automatic logic signed [31:0] mul_shr4(input logic signed [31:0] a, input logic signed [31:0] b);
        return sat32((64'(a) * 64'(b)) >>> 4);
    endfunction
    function automatic logic signed [31:0] mul32(input logic signed [31:0] a, input logic signed [31:0] b);
        return sat32(64'(a) * 64'(b));
    endfunction

    context_buffer ctx_i (
        .clk(clk), .rst_n(rst_n),
        .load(ctx_load), .load_n(ctx_n), .load_tok(ctx_tok),
        .append(1'b0), .append_tok(5'd0),
        .n(n), .tok(toks)
    );

    assign idle = (state == ST_IDLE) || (state == ST_DONE);
    assign busy = !idle;
    assign done = (state == ST_DONE);
    assign last_tok = (n == 4'd0) ? 5'd0 : toks[n_last];
    assign last_pos = n_last;
    assign elr = lr_r + 4'd3;
    assign n_last = (n == 4'd0) ? 3'd0 : (n[2:0] - 3'd1);
    assign host_abs = bank_base(mem_bank) + mem_addr;
    assign pred = arg_pred;
    assign z_now = sat32(mac_acc);
    assign var_u = (acc48 >>> 4);

    always_comb begin
        rows_m = 6'd16;
        cols_m = 6'd16;
        wbank = 4'd2;
        src_ten = T_N1;
        dst_ten = T_Q;
        unique case (mv_kind)
            MV_Q: begin wbank = 4'd2; src_ten = T_N1; dst_ten = T_Q; rows_m = 6'd16; cols_m = 6'd16; end
            MV_K: begin wbank = 4'd3; src_ten = T_N1; dst_ten = T_K; rows_m = 6'd16; cols_m = 6'd16; end
            MV_V: begin wbank = 4'd4; src_ten = T_N1; dst_ten = T_V; rows_m = 6'd16; cols_m = 6'd16; end
            MV_WO: begin wbank = 4'd5; src_ten = T_A; dst_ten = T_H; rows_m = 6'd16; cols_m = 6'd16; end
            MV_FF1: begin wbank = 4'd6; src_ten = T_N1; dst_ten = T_A; rows_m = 6'd32; cols_m = 6'd16; end
            MV_FF2: begin wbank = 4'd7; src_ten = T_A; dst_ten = T_A; rows_m = 6'd16; cols_m = 6'd32; end
            default: begin wbank = 4'd8; src_ten = T_Y; dst_ten = T_Y; rows_m = 6'd32; cols_m = 6'd16; end
        endcase
        if (mv_kind == MV_FF1 || mv_kind == MV_HEAD)
            w_off = {3'd0, row[4:0], col[3:0]};
        else if (mv_kind == MV_FF2)
            w_off = {3'd0, row[3:0], col[4:0]};
        else
            w_off = {4'd0, row[3:0], col[3:0]};
    end

    always_comb begin
        waddr_a = 12'd0;
        waddr_b = 12'd0;
        aaddr_a = 10'd0;
        aaddr_b = 10'd0;
        act_we = 1'b0;
        act_wd = 32'sd0;
        emb_s = $signed({{24{wr[7]}}, wr}) + $signed({{24{wr_b[7]}}, wr_b});
        s16 = sat16(emb_s);
        x_s = act_a - mu;
        y_s = act_a + act_b;
        hid_s = sat16(sat32(mac_acc));
        if (sgd_we || (state == ST_HU_SET) || (state == ST_HU_W) || (state == ST_HU_GO) ||
            (state == ST_HU_DV) || (state == ST_HU_WR) || (state == ST_TK_SET) ||
            (state == ST_TK_W) || (state == ST_TK_WR) || (state == ST_PS_SET) ||
            (state == ST_PS_W) || (state == ST_PS_WR) || (state == ST_DH_SET) ||
            (state == ST_DH_W) || (state == ST_DH_MAC) || (state == ST_DH_GO) ||
            (state == ST_DH_DV) || (state == ST_CP_RD) || (state == ST_CP_WR) ||
            (state == ST_F2_SET) || (state == ST_F2_W) || (state == ST_F2_ACC) ||
            (state == ST_F1_SET) || (state == ST_F1_W) || (state == ST_F1_ACC) ||
            (state == ST_WO_SET) || (state == ST_WO_W) || (state == ST_WO_ACC) ||
            (state == ST_WQ_SET) || (state == ST_WQ_W) || (state == ST_WQ_ACC) ||
            (state == ST_WK_SET) || (state == ST_WK_W) || (state == ST_WK_ACC) ||
            (state == ST_WV_SET) || (state == ST_WV_W) || (state == ST_WV_ACC) ||
            (state == ST_TE_S) || (state == ST_TE_W) || (state == ST_TE_A)) begin
            waddr_a = sgd_addr;
            aaddr_b = act_addr(T_Y, dump_t, dump_d);
        end else if (idle) begin
            waddr_a = host_abs;
            aaddr_b = act_addr(T_Y, dump_t, dump_d);
        end else begin
            unique case (state)
                ST_EMB_SET, ST_EMB_W, ST_EMB_CAP: begin
                    waddr_a = 12'(BASE_TOK) + {3'd0, toks[t], d};
                    waddr_b = 12'(BASE_POS) + {5'd0, t, d};
                    if (state == ST_EMB_CAP) begin
                        act_we = 1'b1;
                        aaddr_a = act_addr(T_XS, t, d);
                        act_wd = {{16{s16[15]}}, s16};
                    end
                end
                ST_LN_RS, ST_LN_WS, ST_LN_RV, ST_LN_WV, ST_LN_RO, ST_LN_WO, ST_LN_DV: begin
                    aaddr_a = act_addr(ln_pass ? T_H : T_XS, t, d);
                    if (state == ST_LN_DV && div_done) begin
                        act_we = 1'b1;
                        aaddr_a = act_addr(T_N1, t, d);
                        act_wd = {{16{sat16(div_q)[15]}}, sat16(div_q)};
                    end
                end
                ST_MV_SET, ST_MV_W, ST_MV_MAC, ST_MV_WR: begin
                    waddr_a = bank_base(wbank) + w_off;
                    if (mv_kind == MV_HEAD)
                        aaddr_a = act_addr(T_Y, n_last, col[3:0]);
                    else if (mv_kind != MV_FF2)
                        aaddr_a = act_addr(src_ten, t, col[3:0]);
                    if (state == ST_MV_WR && mv_kind != MV_FF1 && mv_kind != MV_HEAD) begin
                        act_we = 1'b1;
                        aaddr_a = act_addr(dst_ten, t, row[3:0]);
                        act_wd = sat32(mac_acc);
                    end
                end
                ST_AT_SET, ST_AT_W, ST_AT_MAC, ST_AT_SC: begin
                    aaddr_a = act_addr(T_Q, qi, d);
                    aaddr_b = act_addr(T_K, kj, d);
                end
                ST_AT_VS, ST_AT_VW, ST_AT_VM, ST_AT_GO, ST_AT_DV: begin
                    aaddr_a = act_addr(T_V, kj, d);
                    if (state == ST_AT_DV && div_done) begin
                        act_we = 1'b1;
                        aaddr_a = act_addr(T_A, qi, d);
                        act_wd = {{16{sat16(div_q)[15]}}, sat16(div_q)};
                    end
                end
                ST_RES_SET, ST_RES_W, ST_RES_CAP: begin
                    aaddr_a = act_addr(res_pass ? T_H : T_XS, t, d);
                    aaddr_b = act_addr(res_pass ? T_A : T_H, t, d);
                    if (state == ST_RES_CAP) begin
                        act_we = 1'b1;
                        aaddr_a = act_addr(res_pass ? T_Y : T_H, t, d);
                        act_wd = {{16{sat16(y_s)[15]}}, sat16(y_s)};
                    end
                end
                ST_ATB_VS, ST_ATB_VW, ST_ATB_VD, ST_ATB_VG: begin
                    aaddr_a = act_addr(T_V, bj, d);
                end
                ST_ATB_KS, ST_ATB_KW, ST_ATB_QK: begin
                    aaddr_a = act_addr(T_K, bj, d);
                    aaddr_b = act_addr(T_Q, n_last, d);
                end
                default: ;
            endcase
        end
    end

    assign mac_clr =
        ((state == ST_MV_SET) && (col == 6'd0)) ||
        ((state == ST_AT_SET) && (d == 4'd0)) ||
        ((state == ST_AT_VS) && (kj == 3'd0)) ||
        ((state == ST_DH_SET) && (vv == 5'd0));
    assign mac_en = (state == ST_MV_MAC) || (state == ST_AT_MAC) || (state == ST_AT_VM) ||
                    (state == ST_DH_MAC);

    always_comb begin
        mac_a = 32'sd0;
        mac_b = 32'sd0;
        if (state == ST_MV_MAC) begin
            mac_a = {{24{wr[7]}}, wr};
            if (mv_kind == MV_FF2)
                mac_b = {{16{hid[col[4:0]][15]}}, hid[col[4:0]]};
            else
                mac_b = act_a;
        end else if (state == ST_AT_MAC) begin
            mac_a = act_a;
            mac_b = act_b;
        end else if (state == ST_AT_VM) begin
            mac_a = {24'd0, exps[kj]};
            mac_b = act_a;
        end else if (state == ST_DH_MAC) begin
            mac_a = {{24{wr[7]}}, wr};
            mac_b = {{16{dZ[vv][15]}}, dZ[vv]};
        end
    end

    always_comb begin
        mx_c = score[0];
        z_c = {8'd0, exps[0]};
        for (zj = 1; zj < 8; zj = zj + 1) begin
            if (zj <= qi && score[zj] > mx_c)
                mx_c = score[zj];
            if (zj <= qi)
                z_c = z_c + {8'd0, exps[zj]};
        end
        if (z_c == 16'd0)
            z_c = 16'd1;
    end

    assign sq_start = (state == ST_LN_SC) && (var_u != 32'd0);
    assign div_start = (state == ST_LN_WO) || (state == ST_AT_GO) ||
                       (state == ST_DH_GO) || (state == ST_HU_GO) ||
                       (state == ST_ATB_VD) || (state == ST_ATB_DE);
    assign div_n =
        (state == ST_ATB_VD) ? 48'(64'(attn_w[n_last][bj]) * 64'(dA[d])) :
        (state == ST_ATB_DE) ? {{16{de_acc[31]}}, de_acc} :
        (state == ST_AT_GO || state == ST_DH_GO) ? mac_acc[47:0] :
        ((state == ST_HU_GO) ? 48'(64'(dZ[vv]) * 64'(y_reg[n_last][d])) :
         {{12{x_s[31]}}, x_s, 4'd0});
    assign div_d =
        (state == ST_ATB_VD || state == ST_ATB_DE) ? (az_last == 16'd0 ? 16'd1 : az_last) :
        (state == ST_AT_GO) ? zsum :
        ((state == ST_DH_GO || state == ST_HU_GO) ? (sm_s == 16'd0 ? 16'd1 : sm_s) : scale);

    always_comb begin
        sgd_addr = 12'd0;
        sgd_we = 1'b0;
        sgd_data = 8'sd0;
        cp_waddr = cp_i;
        unique case (state)
            ST_DH_SET, ST_DH_W, ST_DH_MAC, ST_DH_GO, ST_DH_DV:
                sgd_addr = 12'(BASE_HEAD) + {3'd0, vv, d};
            ST_HU_SET, ST_HU_W, ST_HU_GO, ST_HU_DV:
                sgd_addr = 12'(BASE_HEAD) + {3'd0, vv, d};
            ST_HU_WR: begin
                sgd_addr = 12'(BASE_HEAD) + {3'd0, vv, d};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_TK_SET, ST_TK_W:
                sgd_addr = 12'(BASE_TOK) + {3'd0, last_tok, d};
            ST_TK_WR: begin
                sgd_addr = 12'(BASE_TOK) + {3'd0, last_tok, d};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_PS_SET, ST_PS_W:
                sgd_addr = 12'(BASE_POS) + {5'd0, last_pos, d};
            ST_PS_WR: begin
                sgd_addr = 12'(BASE_POS) + {5'd0, last_pos, d};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_CP_RD, ST_CP_WR: begin
                sgd_addr = cp_waddr;
                if (state == ST_CP_WR && !cp_up) begin
                    sgd_we = 1'b1;
                    sgd_data = ckpt_r;
                end
            end
            ST_F2_SET, ST_F2_W:
                sgd_addr = 12'(BASE_FF2) + {3'd0, row[3:0], col[4:0]};
            ST_F2_ACC: begin
                sgd_addr = 12'(BASE_FF2) + {3'd0, row[3:0], col[4:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_F1_SET, ST_F1_W:
                sgd_addr = 12'(BASE_FF1) + {3'd0, row[4:0], col[3:0]};
            ST_F1_ACC: begin
                sgd_addr = 12'(BASE_FF1) + {3'd0, row[4:0], col[3:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_WO_SET, ST_WO_W:
                sgd_addr = 12'(BASE_WO) + {4'd0, row[3:0], col[3:0]};
            ST_WO_ACC: begin
                sgd_addr = 12'(BASE_WO) + {4'd0, row[3:0], col[3:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_WQ_SET, ST_WQ_W:
                sgd_addr = 12'(BASE_WQ) + {4'd0, row[3:0], col[3:0]};
            ST_WQ_ACC: begin
                sgd_addr = 12'(BASE_WQ) + {4'd0, row[3:0], col[3:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_WK_SET, ST_WK_W:
                sgd_addr = 12'(BASE_WK) + {4'd0, row[3:0], col[3:0]};
            ST_WK_ACC: begin
                sgd_addr = 12'(BASE_WK) + {4'd0, row[3:0], col[3:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_WV_SET, ST_WV_W:
                sgd_addr = 12'(BASE_WV) + {4'd0, row[3:0], col[3:0]};
            ST_WV_ACC: begin
                sgd_addr = 12'(BASE_WV) + {4'd0, row[3:0], col[3:0]};
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            ST_TE_S, ST_TE_W:
                sgd_addr = (bj == 3'd0) ? (12'(BASE_TOK) + {3'd0, last_tok, d})
                                        : (12'(BASE_POS) + {5'd0, last_pos, d});
            ST_TE_A: begin
                sgd_addr = (bj == 3'd0) ? (12'(BASE_TOK) + {3'd0, last_tok, d})
                                        : (12'(BASE_POS) + {5'd0, last_pos, d});
                sgd_we = 1'b1;
                sgd_data = new_w;
            end
            default: ;
        endcase
    end

    weight_bram4096 wmem_i (
        .clk(clk),
        .we_a((idle && mem_we) || sgd_we),
        .addr_a(waddr_a),
        .wdata_a(sgd_we ? sgd_data : mem_wdata),
        .rdata_a(wr),
        .addr_b(waddr_b),
        .rdata_b(wr_b)
    );
    ckpt_bram3200 ckpt_i (
        .clk(clk),
        .we(cp_we),
        .addr(cp_i),
        .wdata(wr),
        .rdata(ckpt_r)
    );
    assign cp_we = (state == ST_CP_WR) && cp_up;
    assign mem_rdata = wr;

    act_ram_tdp32 act_i (
        .clk(clk),
        .we_a(act_we),
        .addr_a(aaddr_a),
        .wdata_a(act_wd),
        .rdata_a(act_a),
        .addr_b(aaddr_b),
        .rdata_b(act_b)
    );

    mac64 mac_i (
        .clk(clk), .rst_n(rst_n), .clr(mac_clr), .en(mac_en),
        .a(mac_a), .b(mac_b), .acc(mac_acc)
    );
    floordiv_s48 div_i (
        .clk(clk), .rst_n(rst_n), .start(div_start),
        .numer(div_n), .denom(div_d), .quot(div_q), .done(div_done)
    );
    isqrt32 sq_i (
        .clk(clk), .rst_n(rst_n), .start(sq_start),
        .x(var_u), .y(sq_y), .done(sq_done)
    );
    argmax32 arg_i (
        .clk(clk), .rst_n(rst_n),
        .init(arg_init), .step(arg_step),
        .z(z_now), .idx(row[4:0]),
        .pred(arg_pred), .best(arg_best)
    );

    assign arg_init = (state == ST_MV_WR) && (mv_kind == MV_HEAD) && (row == 5'd0);
    assign arg_step = (state == ST_MV_WR) && (mv_kind == MV_HEAD) && (row != 5'd0);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            mv_kind <= MV_Q;
            ln_pass <= 1'b0;
            res_pass <= 1'b0;
            t <= 3'd0;
            qi <= 3'd0;
            kj <= 3'd0;
            d <= 4'd0;
            row <= 5'd0;
            col <= 5'd0;
            acc48 <= 48'sd0;
            mu <= 32'sd0;
            scale <= 16'd16;
            zsum <= 16'd1;
            mx <= 32'sd0;
            do_train <= 1'b0;
            cp_up <= 1'b0;
            tgt_r <= 5'd0;
            lr_r <= 4'd8;
            vv <= 5'd0;
            cp_i <= 12'd0;
            sm_s <= 16'd1;
            z_mx <= 32'sd0;
            g16 <= 16'sd0;
            new_w <= 8'sd0;
            wr_tok_n <= 16'd0;
            wr_pos_n <= 16'd0;
            wr_head_n <= 16'd0;
            wr_blk_n <= 16'd0;
            last_loss <= 16'd0;
            sum_ok <= 1'b0;
            for (zi = 0; zi < 32; zi = zi + 1) begin
                logits[zi] <= 32'sd0;
                hid[zi] <= 16'sd0;
                dZ[zi] <= 16'sd0;
                sm_exps[zi] <= 16'd0;
            end
            for (zi = 0; zi < 16; zi = zi + 1) begin
                dH[zi] <= 16'sd0;
                g_tok[zi] <= 16'sd0;
                g_pos[zi] <= 16'sd0;
                g_head0[zi] <= 16'sd0;
                g_head1[zi] <= 16'sd0;
                g_headt[zi] <= 16'sd0;
            end
            for (zi = 0; zi < 8; zi = zi + 1) begin
                score[zi] <= 32'sd0;
                exps[zi] <= 8'd0;
                for (zk = 0; zk < 16; zk = zk + 1)
                    y_reg[zi][zk] <= 16'sd0;
                for (zk = 0; zk < 8; zk = zk + 1)
                    attn_w[zi][zk] <= 8'd0;
            end
        end else begin
            unique case (state)
                ST_IDLE: begin
                    if (do_snap) begin
                        cp_up <= 1'b1;
                        cp_i <= 12'd0;
                        state <= ST_CP_RD;
                    end else if (do_restore) begin
                        cp_up <= 1'b0;
                        cp_i <= 12'd0;
                        state <= ST_CP_RD;
                    end else if (start || start_train) begin
                        t <= 3'd0;
                        d <= 4'd0;
                        row <= 5'd0;
                        col <= 5'd0;
                        vv <= 5'd0;
                        ln_pass <= 1'b0;
                        res_pass <= 1'b0;
                        mv_kind <= MV_Q;
                        do_train <= start_train && !after_mode;
                        tgt_r <= tgt;
                        lr_r <= (lr == 4'd0) ? 4'd8 : lr;
                        for (zi = 0; zi < 8; zi = zi + 1)
                            for (zk = 0; zk < 8; zk = zk + 1)
                                attn_w[zi][zk] <= 8'd0;
                        if (n == 4'd0) begin
                            for (zi = 0; zi < 32; zi = zi + 1)
                                logits[zi] <= 32'sd0;
                            state <= ST_ARG;
                        end else
                            state <= ST_EMB_SET;
                    end
                end
                ST_EMB_SET: state <= ST_EMB_W;
                ST_EMB_W: state <= ST_EMB_CAP;
                ST_EMB_CAP: begin
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        if (t == n_last) begin
                            t <= 3'd0;
                            ln_pass <= 1'b0;
                            state <= ST_LN_INIT;
                        end else begin
                            t <= t + 3'd1;
                            state <= ST_EMB_SET;
                        end
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_EMB_SET;
                    end
                end
                ST_LN_INIT: begin
                    d <= 4'd0;
                    acc48 <= 48'sd0;
                    state <= ST_LN_RS;
                end
                ST_LN_RS: state <= ST_LN_WS;
                ST_LN_WS: begin
                    acc48 <= acc48 + {{16{act_a[31]}}, act_a};
                    if (d == 4'd15)
                        state <= ST_LN_MU;
                    else begin
                        d <= d + 4'd1;
                        state <= ST_LN_RS;
                    end
                end
                ST_LN_MU: begin
                    mu <= acc48 >>> 4;
                    d <= 4'd0;
                    acc48 <= 48'sd0;
                    state <= ST_LN_RV;
                end
                ST_LN_RV: state <= ST_LN_WV;
                ST_LN_WV: begin
                    acc48 <= acc48 + 48'(64'(x_s) * 64'(x_s));
                    if (d == 4'd15)
                        state <= ST_LN_SC;
                    else begin
                        d <= d + 4'd1;
                        state <= ST_LN_RV;
                    end
                end
                ST_LN_SC: begin
                    if (var_u == 32'd0) begin
                        scale <= 16'd16;
                        state <= ST_LN_OI;
                    end else
                        state <= ST_LN_SQ;
                end
                ST_LN_SQ: if (sq_done) begin
                    scale <= (sq_y == 16'd0) ? 16'd1 : sq_y;
                    state <= ST_LN_OI;
                end
                ST_LN_OI: begin
                    d <= 4'd0;
                    state <= ST_LN_RO;
                end
                ST_LN_RO: state <= ST_LN_WO;
                ST_LN_WO: state <= ST_LN_DV;
                ST_LN_DV: if (div_done) begin
                    if (!ln_pass)
                        n1_reg[t][d] <= sat16(div_q);
                    else if (t == n_last)
                        n2_reg[d] <= sat16(div_q);
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        if (t == n_last) begin
                            t <= 3'd0;
                            if (!ln_pass) begin
                                mv_kind <= MV_Q;
                                state <= ST_MV_INIT;
                            end else begin
                                mv_kind <= MV_FF1;
                                state <= ST_MV_INIT;
                            end
                        end else begin
                            t <= t + 3'd1;
                            state <= ST_LN_INIT;
                        end
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_LN_RO;
                    end
                end
                ST_MV_INIT: begin
                    if (mv_kind == MV_HEAD)
                        t <= n_last;
                    row <= 5'd0;
                    col <= 5'd0;
                    state <= ST_MV_SET;
                end
                ST_MV_SET: state <= ST_MV_W;
                ST_MV_W: state <= ST_MV_MAC;
                ST_MV_MAC: begin
                    if (col == (cols_m - 5'd1))
                        state <= ST_MV_WR;
                    else begin
                        col <= col + 5'd1;
                        state <= ST_MV_SET;
                    end
                end
                ST_MV_WR: begin
                    if (mv_kind == MV_FF1)
                        hid[row[4:0]] <= hid_s[15] ? 16'sd0 : hid_s;
                    else if (mv_kind == MV_HEAD)
                        logits[row] <= sat32(mac_acc);
                    if (row == (rows_m - 5'd1)) begin
                        row <= 5'd0;
                        col <= 5'd0;
                        if (mv_kind == MV_HEAD)
                            state <= ST_ARG;
                        else if (mv_kind == MV_FF1) begin
                            mv_kind <= MV_FF2;
                            state <= ST_MV_INIT;
                        end else if (mv_kind == MV_FF2) begin
                            if (t == n_last) begin
                                t <= 3'd0;
                                d <= 4'd0;
                                res_pass <= 1'b1;
                                state <= ST_RES_SET;
                            end else begin
                                t <= t + 3'd1;
                                mv_kind <= MV_FF1;
                                state <= ST_MV_INIT;
                            end
                        end else if (t == n_last) begin
                            t <= 3'd0;
                            unique case (mv_kind)
                                MV_Q: begin mv_kind <= MV_K; state <= ST_MV_INIT; end
                                MV_K: begin mv_kind <= MV_V; state <= ST_MV_INIT; end
                                MV_V: begin qi <= 3'd0; kj <= 3'd0; d <= 4'd0; state <= ST_AT_I; end
                                default: begin
                                    t <= 3'd0;
                                    d <= 4'd0;
                                    res_pass <= 1'b0;
                                    state <= ST_RES_SET;
                                end
                            endcase
                        end else begin
                            t <= t + 3'd1;
                            state <= ST_MV_SET;
                        end
                    end else begin
                        row <= row + 5'd1;
                        col <= 5'd0;
                        state <= ST_MV_SET;
                    end
                end
                ST_AT_I: begin
                    qi <= 3'd0;
                    kj <= 3'd0;
                    d <= 4'd0;
                    state <= ST_AT_SET;
                end
                ST_AT_SET: state <= ST_AT_W;
                ST_AT_W: state <= ST_AT_MAC;
                ST_AT_MAC: begin
                    if (d == 4'd15)
                        state <= ST_AT_SC;
                    else begin
                        d <= d + 4'd1;
                        state <= ST_AT_SET;
                    end
                end
                ST_AT_SC: begin
                    score[kj] <= sat32(mac_acc >>> 2);
                    if (kj == qi)
                        state <= ST_AT_MX;
                    else begin
                        kj <= kj + 3'd1;
                        d <= 4'd0;
                        state <= ST_AT_SET;
                    end
                end
                ST_AT_MX: begin
                    mx <= mx_c;
                    state <= ST_AT_EX;
                end
                ST_AT_EX: begin
                    for (zk = 0; zk < 8; zk = zk + 1) begin
                        if (zk <= qi) begin
                            e_tmp = score[zk] - mx + 32'sd16;
                            if (e_tmp <= 32'sd0) begin
                                exps[zk] <= 8'd0;
                                attn_w[qi][zk] <= 8'd0;
                            end else if (e_tmp > 32'sd255) begin
                                exps[zk] <= 8'd255;
                                attn_w[qi][zk] <= 8'd255;
                            end else begin
                                exps[zk] <= e_tmp[7:0];
                                attn_w[qi][zk] <= e_tmp[7:0];
                            end
                        end else begin
                            exps[zk] <= 8'd0;
                            attn_w[qi][zk] <= 8'd0;
                        end
                    end
                    state <= ST_AT_Z;
                end
                ST_AT_Z: begin
                    zsum <= z_c;
                    if (qi == n_last)
                        az_last <= (z_c == 16'd0) ? 16'd1 : z_c;
                    d <= 4'd0;
                    kj <= 3'd0;
                    state <= ST_AT_VS;
                end
                ST_AT_VS: state <= ST_AT_VW;
                ST_AT_VW: state <= ST_AT_VM;
                ST_AT_VM: begin
                    if (kj == qi)
                        state <= ST_AT_GO;
                    else begin
                        kj <= kj + 3'd1;
                        state <= ST_AT_VS;
                    end
                end
                ST_AT_GO: state <= ST_AT_DV;
                ST_AT_DV: if (div_done) begin
                    if (qi == n_last)
                        a_last[d] <= sat16(div_q);
                    if (d == 4'd15) begin
                        if (qi == n_last) begin
                            mv_kind <= MV_WO;
                            state <= ST_MV_INIT;
                        end else begin
                            qi <= qi + 3'd1;
                            kj <= 3'd0;
                            d <= 4'd0;
                            state <= ST_AT_SET;
                        end
                    end else begin
                        d <= d + 4'd1;
                        kj <= 3'd0;
                        state <= ST_AT_VS;
                    end
                end
                ST_RES_SET: state <= ST_RES_W;
                ST_RES_W: state <= ST_RES_CAP;
                ST_RES_CAP: begin
                    if (res_pass)
                        y_reg[t][d] <= sat16(y_s);
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        if (t == n_last) begin
                            t <= 3'd0;
                            if (!res_pass) begin
                                ln_pass <= 1'b1;
                                state <= ST_LN_INIT;
                            end else begin
                                mv_kind <= MV_HEAD;
                                state <= ST_MV_INIT;
                            end
                        end else begin
                            t <= t + 3'd1;
                            state <= ST_RES_SET;
                        end
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_RES_SET;
                    end
                end
                ST_ARG: state <= (do_train && n != 4'd0) ? ST_SMX : ST_DONE;
                ST_SMX: begin
                    vv <= 5'd0;
                    z_mx <= logits[0];
                    state <= ST_SEX;
                end
                ST_SEX: begin
                    if (logits[vv] > z_mx)
                        z_mx <= logits[vv];
                    if (vv == 5'd31) begin
                        vv <= 5'd0;
                        state <= ST_SS;
                    end else
                        vv <= vv + 5'd1;
                end
                ST_SS: begin
                    e32 = logits[vv] - z_mx + 32'sd16;
                    sm_exps[vv] <= e32[31] ? 16'd0 : e32[15:0];
                    if (vv == 5'd31) begin
                        vv <= 5'd0;
                        sm_s <= 16'd0;
                        state <= ST_DZ;
                    end else
                        vv <= vv + 5'd1;
                end
                ST_DZ: begin
                    if (!sum_ok) begin
                        sm_s <= sm_exps[0] + sm_exps[1] + sm_exps[2] + sm_exps[3]
                            + sm_exps[4] + sm_exps[5] + sm_exps[6] + sm_exps[7]
                            + sm_exps[8] + sm_exps[9] + sm_exps[10] + sm_exps[11]
                            + sm_exps[12] + sm_exps[13] + sm_exps[14] + sm_exps[15]
                            + sm_exps[16] + sm_exps[17] + sm_exps[18] + sm_exps[19]
                            + sm_exps[20] + sm_exps[21] + sm_exps[22] + sm_exps[23]
                            + sm_exps[24] + sm_exps[25] + sm_exps[26] + sm_exps[27]
                            + sm_exps[28] + sm_exps[29] + sm_exps[30] + sm_exps[31];
                        if ((sm_exps[0] + sm_exps[1] + sm_exps[2] + sm_exps[3]
                            + sm_exps[4] + sm_exps[5] + sm_exps[6] + sm_exps[7]
                            + sm_exps[8] + sm_exps[9] + sm_exps[10] + sm_exps[11]
                            + sm_exps[12] + sm_exps[13] + sm_exps[14] + sm_exps[15]
                            + sm_exps[16] + sm_exps[17] + sm_exps[18] + sm_exps[19]
                            + sm_exps[20] + sm_exps[21] + sm_exps[22] + sm_exps[23]
                            + sm_exps[24] + sm_exps[25] + sm_exps[26] + sm_exps[27]
                            + sm_exps[28] + sm_exps[29] + sm_exps[30] + sm_exps[31]) == 16'd0)
                            sm_s <= 16'd1;
                        sum_ok <= 1'b1;
                        vv <= 5'd0;
                    end else begin
                        dZ[vv] <= $signed(sm_exps[vv]) - ((vv == tgt_r) ? $signed(sm_s) : 16'sd0);
                        if (vv == 5'd0)
                            last_loss <= sm_s - sm_exps[tgt_r];
                        if (vv == 5'd31) begin
                            vv <= 5'd0;
                            d <= 4'd0;
                            sum_ok <= 1'b0;
                            state <= ST_DH_SET;
                        end else
                            vv <= vv + 5'd1;
                    end
                end
                ST_DH_SET: state <= ST_DH_W;
                ST_DH_W: state <= ST_DH_MAC;
                ST_DH_MAC: begin
                    if (vv == 5'd31)
                        state <= ST_DH_GO;
                    else begin
                        vv <= vv + 5'd1;
                        state <= ST_DH_SET;
                    end
                end
                ST_DH_GO: state <= ST_DH_DV;
                ST_DH_DV: if (div_done) begin
                    dH[d] <= sat16(div_q);
                    g_tok[d] <= sat16(div_q);
                    g_pos[d] <= sat16(div_q);
                    if (d == 4'd15) begin
                        vv <= 5'd0;
                        d <= 4'd0;
                        state <= ST_HU_SET;
                    end else begin
                        d <= d + 4'd1;
                        vv <= 5'd0;
                        state <= ST_DH_SET;
                    end
                end
                ST_HU_SET: state <= ST_HU_W;
                ST_HU_W: state <= ST_HU_GO;
                ST_HU_GO: state <= ST_HU_DV;
                ST_HU_DV: if (div_done) begin
                    g16 <= sat16(div_q);
                    if (vv == 5'd0) g_head0[d] <= sat16(div_q);
                    if (vv == 5'd1) g_head1[d] <= sat16(div_q);
                    if (vv == tgt_r) g_headt[d] <= sat16(div_q);
                    new_w <= sat8(32'(wr) - 32'(sat16(div_q) >>> lr_r));
                    state <= ST_HU_WR;
                end
                ST_HU_WR: begin
                    wr_head_n <= wr_head_n + 16'd1;
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        if (vv == 5'd31) begin
                            d <= 4'd0;
                            state <= ST_YCP;
                        end else begin
                            vv <= vv + 5'd1;
                            state <= ST_HU_SET;
                        end
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_HU_SET;
                    end
                end
                ST_YCP: begin
                    for (zi = 0; zi < 16; zi = zi + 1) begin
                        dY[zi] <= dH[zi];
                        dN2[zi] <= 16'sd0;
                        dA[zi] <= 16'sd0;
                        dQ[zi] <= 16'sd0;
                        dN1[zi] <= 16'sd0;
                        dq_acc[zi] <= 32'sd0;
                        dHid[zi] <= 16'sd0;
                        dHid[zi + 16] <= 16'sd0;
                        dHid_acc[zi] <= 32'sd0;
                        dHid_acc[zi + 16] <= 32'sd0;
                        dN2_acc[zi] <= 32'sd0;
                        dA_acc[zi] <= 32'sd0;
                        dN1_acc[zi] <= 32'sd0;
                    end
                    for (zi = 0; zi < 8; zi = zi + 1)
                        for (zk = 0; zk < 16; zk = zk + 1) begin
                            dK[zi][zk] <= 16'sd0;
                            dV[zi][zk] <= 16'sd0;
                        end
                    row <= 6'd0;
                    col <= 6'd0;
                    bj <= 3'd0;
                    gacc <= 32'sd0;
                    de_acc <= 32'sd0;
                    state <= ST_F2_SET;
                end
                ST_F2_SET: state <= ST_F2_W;
                ST_F2_W: begin
                    g16 <= sat16(mul_shr4(sx16(dY[row[3:0]]), sx16(hid[col[4:0]])));
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(mul_shr4(sx16(dY[row[3:0]]), sx16(hid[col[4:0]]))))));
                    state <= ST_F2_ACC;
                end
                ST_F2_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dHid_acc[col[4:0]] <= dHid_acc[col[4:0]] + mul32(sx8(wr), sx16(dY[row[3:0]]));
                    if (row == 6'd0 && col[4:0] < 5'd16)
                        g_headt[col[3:0]] <= g16;
                    if (col == 6'd31) begin
                        col <= 6'd0;
                        if (row == 6'd15) begin
                            row <= 6'd0;
                            state <= ST_F1_SET;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_F2_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_F2_SET;
                    end
                end
                ST_F1_SET: begin
                    if (row == 6'd0 && col == 6'd0)
                        for (zi = 0; zi < 32; zi = zi + 1)
                            dHid[zi] <= (hid[zi] == 16'sd0) ? 16'sd0 : sat16(dHid_acc[zi] >>> 4);
                    state <= ST_F1_W;
                end
                ST_F1_W: begin
                    g16 <= sat16(mul_shr4(sx16(dHid[row[4:0]]), sx16(n2_reg[col[3:0]])));
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(mul_shr4(sx16(dHid[row[4:0]]), sx16(n2_reg[col[3:0]]))))));
                    state <= ST_F1_ACC;
                end
                ST_F1_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dN2_acc[col[3:0]] <= dN2_acc[col[3:0]] + mul32(sx8(wr), sx16(dHid[row[4:0]]));
                    if (col == 6'd15) begin
                        col <= 6'd0;
                        if (row == 6'd31) begin
                            row <= 6'd0;
                            state <= ST_DHADD;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_F1_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_F1_SET;
                    end
                end
                ST_DHADD: begin
                    for (zi = 0; zi < 16; zi = zi + 1)
                        dN2[zi] <= sat16(dN2_acc[zi] >>> 4);
                    row <= 6'd0;
                    col <= 6'd0;
                    state <= ST_WO_SET;
                end
                ST_WO_SET: begin
                    if (row == 6'd0 && col == 6'd0)
                        for (zi = 0; zi < 16; zi = zi + 1)
                            dHb[zi] <= sat16(32'(dY[zi]) + 32'(dN2[zi]));
                    state <= ST_WO_W;
                end
                ST_WO_W: begin
                    g16 <= sat16(mul_shr4(sx16(dHb[row[3:0]]), sx16(a_last[col[3:0]])));
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(mul_shr4(sx16(dHb[row[3:0]]), sx16(a_last[col[3:0]]))))));
                    state <= ST_WO_ACC;
                end
                ST_WO_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dA_acc[col[3:0]] <= dA_acc[col[3:0]] + mul32(sx8(wr), sx16(dHb[row[3:0]]));
                    if (row == 6'd0)
                        g_head1[col[3:0]] <= g16;
                    if (col == 6'd15) begin
                        col <= 6'd0;
                        if (row == 6'd15) begin
                            row <= 6'd0;
                            d <= 4'd0;
                            bj <= 3'd0;
                            de_acc <= 32'sd0;
                            state <= ST_ATB_VS;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_WO_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_WO_SET;
                    end
                end
                ST_ATB_VS: begin
                    if (d == 4'd0 && bj == 3'd0)
                        for (zi = 0; zi < 16; zi = zi + 1)
                            dA[zi] <= sat16(dA_acc[zi] >>> 4);
                    state <= ST_ATB_VW;
                end
                ST_ATB_VW: state <= ST_ATB_VD;
                ST_ATB_VD: state <= ST_ATB_VG;
                ST_ATB_VG: if (div_done) begin
                    dV[bj][d] <= sat16(div_q);
                    de_acc <= de_acc + mul32(sx16(dA[d]), sx16(sat16(act_a)));
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        state <= ST_ATB_DE;
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_ATB_VS;
                    end
                end
                ST_ATB_DE: state <= ST_ATB_DG;
                ST_ATB_DG: if (div_done) begin
                    dscore <= (attn_w[n_last][bj] == 8'd0) ? 16'sd0 : sat16(div_q);
                    d <= 4'd0;
                    state <= ST_ATB_KS;
                end
                ST_ATB_KS: state <= ST_ATB_KW;
                ST_ATB_KW: state <= ST_ATB_QK;
                ST_ATB_QK: begin
                    dq_acc[d] <= dq_acc[d] + (mul32(sx16(dscore), sx16(sat16(act_a))) >>> 8);
                    dK[bj][d] <= sat16(mul32(sx16(dscore), sx16(sat16(act_b))) >>> 8);
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        de_acc <= 32'sd0;
                        if (bj == n_last) begin
                            row <= 6'd0;
                            col <= 6'd0;
                            bj <= 3'd0;
                            gacc <= 32'sd0;
                            state <= ST_WQ_SET;
                        end else begin
                            bj <= bj + 3'd1;
                            state <= ST_ATB_VS;
                        end
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_ATB_KS;
                    end
                end
                ST_WQ_SET: begin
                    if (row == 6'd0 && col == 6'd0)
                        for (zi = 0; zi < 16; zi = zi + 1)
                            dQ[zi] <= sat16(dq_acc[zi]);
                    state <= ST_WQ_W;
                end
                ST_WQ_W: begin
                    g16 <= sat16(mul_shr4(sx16(dQ[row[3:0]]), sx16(n1_reg[n_last][col[3:0]])));
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(mul_shr4(sx16(dQ[row[3:0]]), sx16(n1_reg[n_last][col[3:0]]))))));
                    state <= ST_WQ_ACC;
                end
                ST_WQ_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dN1_acc[col[3:0]] <= dN1_acc[col[3:0]] + mul32(sx8(wr), sx16(dQ[row[3:0]]));
                    if (row == 6'd0)
                        g_tok[col[3:0]] <= g16;
                    if (col == 6'd15) begin
                        col <= 6'd0;
                        if (row == 6'd15) begin
                            row <= 6'd0;
                            bj <= 3'd0;
                            gacc <= 32'sd0;
                            state <= ST_WK_SET;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_WQ_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_WQ_SET;
                    end
                end
                ST_WK_SET: begin
                    if (bj == 3'd0)
                        gacc <= 32'((64'(dK[0][row[3:0]]) * 64'(n1_reg[0][col[3:0]])) >>> 4);
                    else
                        gacc <= gacc + 32'((64'(dK[bj][row[3:0]]) * 64'(n1_reg[bj][col[3:0]])) >>> 4);
                    if (bj == n_last) begin
                        bj <= 3'd0;
                        state <= ST_WK_W;
                    end else
                        bj <= bj + 3'd1;
                end
                ST_WK_W: begin
                    g16 <= sat16(gacc);
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(gacc))));
                    state <= ST_WK_ACC;
                end
                ST_WK_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dN1_acc[col[3:0]] <= dN1_acc[col[3:0]] + mul32(sx8(wr), sx16(dK[n_last][row[3:0]]));
                    if (row == 6'd0)
                        g_pos[col[3:0]] <= g16;
                    if (col == 6'd15) begin
                        col <= 6'd0;
                        if (row == 6'd15) begin
                            row <= 6'd0;
                            bj <= 3'd0;
                            gacc <= 32'sd0;
                            state <= ST_WV_SET;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_WK_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_WK_SET;
                    end
                end
                ST_WV_SET: begin
                    if (bj == 3'd0)
                        gacc <= 32'((64'(dV[0][row[3:0]]) * 64'(n1_reg[0][col[3:0]])) >>> 4);
                    else
                        gacc <= gacc + 32'((64'(dV[bj][row[3:0]]) * 64'(n1_reg[bj][col[3:0]])) >>> 4);
                    if (bj == n_last) begin
                        bj <= 3'd0;
                        state <= ST_WV_W;
                    end else
                        bj <= bj + 3'd1;
                end
                ST_WV_W: begin
                    g16 <= sat16(gacc);
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(gacc))));
                    state <= ST_WV_ACC;
                end
                ST_WV_ACC: begin
                    wr_blk_n <= wr_blk_n + 16'd1;
                    dN1_acc[col[3:0]] <= dN1_acc[col[3:0]] + mul32(sx8(wr), sx16(dV[n_last][row[3:0]]));
                    if (row == 6'd0)
                        g_head0[col[3:0]] <= g16;
                    if (col == 6'd15) begin
                        col <= 6'd0;
                        if (row == 6'd15) begin
                            d <= 4'd0;
                            bj <= 3'd0;
                            state <= ST_TE_S;
                        end else begin
                            row <= row + 6'd1;
                            state <= ST_WV_SET;
                        end
                    end else begin
                        col <= col + 6'd1;
                        state <= ST_WV_SET;
                    end
                end
                ST_TE_S: begin
                    if (d == 4'd0 && bj == 3'd0)
                        for (zi = 0; zi < 16; zi = zi + 1)
                            dN1[zi] <= sat16(dN1_acc[zi] >>> 4);
                    state <= ST_TE_W;
                end
                ST_TE_W: begin
                    g16 <= sat16(32'(dN1[d]) + 32'(dHb[d]));
                    new_w <= sat8(32'(wr) - 32'(step_sign(sat16(32'(dN1[d]) + 32'(dHb[d])))));
                    state <= ST_TE_A;
                end
                ST_TE_A: begin
                    if (bj == 3'd0)
                        wr_tok_n <= wr_tok_n + 16'd1;
                    else
                        wr_pos_n <= wr_pos_n + 16'd1;
                    if (d == 4'd15) begin
                        d <= 4'd0;
                        if (bj == 3'd0) begin
                            bj <= 3'd1;
                            state <= ST_TE_S;
                        end else
                            state <= ST_DONE;
                    end else begin
                        d <= d + 4'd1;
                        state <= ST_TE_S;
                    end
                end
                ST_CP_RD: state <= ST_CP_WR;
                ST_CP_WR: begin
                    if (cp_i == 12'd3199)
                        state <= ST_DONE;
                    else begin
                        cp_i <= cp_i + 12'd1;
                        state <= ST_CP_RD;
                    end
                end
                ST_DONE: state <= ST_IDLE;
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
