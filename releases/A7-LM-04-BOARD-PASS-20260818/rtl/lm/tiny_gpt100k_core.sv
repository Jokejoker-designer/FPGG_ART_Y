`timescale 1ns/1ps
import a7lm04_pkg::*;
// Sequential 2-layer 2-head TinyGPT. law_id lm05-signsgd-v1.
// Timing: no combinational 64-bit /. Power-of-two via ASR. Variable via floordiv_s48.
// Counters are 9-bit so V=256 and FF=128 do not wrap.
module tiny_gpt100k_core (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               mem_we,
    input  logic [16:0]        mem_addr,
    input  logic signed [7:0]  mem_wdata,
    output logic signed [7:0]  mem_rdata,
    input  logic               ctx_we,
    input  logic [4:0]         ctx_idx,
    input  logic [4:0]         ctx_n_in,
    input  logic [63:0]        ctx_pack,
    input  logic               start_fwd,
    input  logic               start_train,
    input  logic               start_ce,
    input  logic               start_corpus,
    input  logic               after_mode,
    input  logic               do_snap,
    input  logic               do_restore,
    input  logic               do_fold,
    input  logic [7:0]         tgt_in,
    input  logic [3:0]         lr_in,
    input  logic [7:0]         corpus_n,
    input  logic [7:0]         corpus_ep,
    output logic               busy,
    output logic               done,
    output logic [7:0]         pred,
    output logic [15:0]        last_loss,
    output logic [31:0]        ce0,
    output logic [31:0]        ce1,
    output logic [31:0]        wr_n,
    output logic [31:0]        xor32,
    output logic [31:0]        add32,
    output logic [7:0]         phase
);
    typedef enum logic [5:0] {
        ST_IDLE, ST_EMB, ST_LN_S, ST_LN_V, ST_LN_SQ, ST_LN_O,
        ST_MV, ST_ATT_SC, ST_ATT_MX, ST_ATT_E, ST_ATT_Z, ST_ATT_O,
        ST_ADD, ST_SMX, ST_ARG,
        ST_BH, ST_DHID, ST_AFF2, ST_DN2, ST_AFF1, ST_ALIN, ST_BEM,
        ST_FOLD, ST_SNAP, ST_REST,
        ST_PAIR, ST_CEACC, ST_NEXT, ST_DONE
    } st_t;

    st_t st;
    logic [4:0] ntok, tok_i, tok_j;
    logic [7:0] tok [0:31];
    logic [7:0] tgt;
    logic [3:0] lr;
    logic       ly;
    logic [2:0] ten, ten_o;
    logic [8:0] dim, col, row, nrows, ncols;
    logic [7:0] vix;
    logic signed [63:0] acc;
    logic signed [31:0] mu, tmp32, mx, zsum, ssoft, dz_r, op_a, op_b, x_r, dy_r;
    logic [31:0]        var_u;
    logic signed [31:0] score [0:31];
    logic [7:0]         exps [0:31];
    logic [7:0]         e_last [0:3][0:31];
    logic signed [31:0] z_last [0:3];
    logic [15:0]        isq_y, scale;
    logic               isq_go, isq_done, fd_go, fd_done;
    logic [31:0]        isq_x;
    logic signed [47:0] fd_n;
    logic [15:0]        fd_d;
    logic signed [31:0] fd_q;
    logic               train, corpus, after_r, head_only, do_full, ce_after;
    logic [7:0]         pi, ep, n_pair, n_ep;
    logic [16:0]        waddr, caddr, ck_raddr;
    logic signed [7:0]  wrd, crd, ckd, wwd;
    logic               wwe, cwe;
    logic signed [31:0] ard, ard_b, awd;
    logic [15:0]        aaddr, aaddr_b;
    logic               awe;
    logic signed [31:0] logits [0:255];
    logic [7:0]         smx_e [0:255];
    logic [7:0]         arg_best;
    logic signed [31:0] arg_v;
    logic [1:0]         hix;
    logic               relu;
    logic [16:0]        wbase;
    logic [3:0]         sub;
    // Isolation: full-backprop scratch must stay FF arrays. Vivado mapped the
    // bare dHid[0:63] array to RAMS64E; behavioral xsim then diverges from
    // the post-synth netlist. Same risk on the sibling scratch tensors.
    (* ram_style = "registers" *) logic signed [31:0] dY [0:63];
    (* ram_style = "registers" *) logic signed [31:0] dH [0:63];
    (* ram_style = "registers" *) logic signed [31:0] dHid [0:127];
    (* ram_style = "registers" *) logic signed [31:0] n1_last [0:1][0:63];
    (* ram_style = "registers" *) logic signed [31:0] a_last [0:1][0:63];
    logic signed [15:0] gtmp;
    logic               isq_pend;
    integer ii;

    // 64K act map, no overlap:
    //   0x0000-0x7FFF tensors {ly,t[2:0],tk[4:0],d[5:0]}
    //   0x8000-0x9FFF hid     0x8000+{ly,tk[4:0],hh[6:0]}
    //   0xA000-0xAFFF y       0xA000+{ly,tk[4:0],d[5:0]}
    function automatic [15:0] aa(input ly_, input [2:0] t, input [4:0] tk, input [5:0] d);
        return {1'b0, ly_, t, tk, d};
    endfunction

    function automatic [15:0] ah(input ly_, input [4:0] tk, input [6:0] hh);
        return 16'h8000 + {ly_, tk, hh};
    endfunction

    function automatic [15:0] ay(input ly_, input [4:0] tk, input [5:0] d);
        return 16'hA000 + {ly_, tk, d};
    endfunction

    function automatic [4:0] last_tok(input [4:0] n);
        return (n == 5'd0) ? 5'd0 : (n - 5'd1);
    endfunction

    function automatic [15:0] denom16(input signed [31:0] s);
        if (s <= 32'sd0) return 16'd1;
        if (s > 32'sd65535) return 16'd65535;
        return s[15:0];
    endfunction

    function automatic [7:0] relu_exp(input signed [31:0] sc, input signed [31:0] mxx);
        logic signed [31:0] e;
        e = sc - mxx + 32'sd16;
        if (e <= 32'sd0) return 8'd0;
        if (e > 32'sd255) return 8'd255;
        return e[7:0];
    endfunction

    logic host_sel, host_we;
    // Idle: host owns port A so 0x31 readback sees mem_addr the same cycle.
    // BRAM output latency is then exactly 1 clk (see weight_bram100k).
    assign host_sel = (st == ST_IDLE);
    assign host_we  = host_sel && mem_we;
    weight_bram100k u_w (
        .clk(clk),
        .we_a(host_we || wwe),
        .addr_a(host_sel ? mem_addr : waddr),
        .wdata_a(host_we ? mem_wdata : wwd),
        .rdata_a(wrd),
        .addr_b(caddr), .rdata_b(crd)
    );
    // On-chip checkpoint dropped: a second 100k BRAM does not fit with
    // act RAM + MIG tiles. Snap/restore are DDR persist in the LM-04 top.
    assign ckd = 8'sd0;
    act_ram64k u_a (
        .clk(clk), .we_a(awe), .addr_a(aaddr), .wdata_a(awd), .rdata_a(ard),
        .addr_b(aaddr_b), .rdata_b(ard_b)
    );
    isqrt32 u_isq (
        .clk(clk), .rst_n(rst_n), .start(isq_go), .x(isq_x), .y(isq_y), .done(isq_done)
    );
    floordiv_s48 u_fd (
        .clk(clk), .rst_n(rst_n), .start(fd_go), .numer(fd_n), .denom(fd_d),
        .quot(fd_q), .done(fd_done)
    );

    assign mem_rdata = wrd;
    assign busy = (st != ST_IDLE);
    assign phase = {2'd0, st};

`ifndef SYNTHESIS
    always_ff @(posedge clk) begin
        if (rst_n && st == ST_EMB && sub == 4'd2 && tok_i == 4'd0 && dim < 9'd2)
            $display("EMB t=%0t dim=%0d wrd=%0d crd=%0d awd=%0d", $time, dim, wrd, crd, sat16(32'(wrd)+32'(crd)));
        if (rst_n && st == ST_LN_V && sub == 4'd4)
            $display("LNV t=%0t acc=%0d var=%0d mu=%0d", $time, acc, acc[37:6], mu);
        if (rst_n && st == ST_LN_O && fd_done && dim == 9'd0)
            $display("LNO t=%0t ly=%0d ten=%0d ard=%0d mu=%0d sc=%0d q=%0d", $time, ly, ten, ard, mu, scale, fd_q);
        if (rst_n && st == ST_MV && sub == 4'd3 && row == 9'd0 && col == 9'd0)
            $display("MV0 t=%0t ly=%0d ten_o=%0d acc=%0d dest=%0d", $time, ly, ten_o, acc, aa(ly, ten_o, tok_i, row[5:0]));
        if (rst_n && st == ST_ATT_SC && sub == 4'd2 && dim == 9'd0 && tok_j == 4'd0)
            $display("ATTQK t=%0t ard=%0d ardb=%0d qa=%0d ka=%0d", $time, ard, ard_b, aaddr, aaddr_b);
        if (rst_n && st == ST_ATT_O && fd_done && dim == 9'd0)
            $display("ATTO t=%0t h=%0d q=%0d z=%0d acc=%0d dest=%0d", $time, hix, fd_q, z_last[hix], acc, aa(ly, 3'd5, tok_i, {hix[1:0], dim[3:0]}));
        if (rst_n && st == ST_ADD && sub == 4'd2 && dim == 9'd0)
            $display("ADD t=%0t ly=%0d ten=%0d ard=%0d ardb=%0d", $time, ly, ten, ard, ard_b);
        if (rst_n && st == ST_MV && ten_o == 3'd7 && sub == 4'd2 && row == 9'd0 && col < 9'd2)
            $display("HEAD t=%0t col=%0d wrd=%0d ard=%0d waddr=%0d aaddr=%0d acc=%0d", $time, col, wrd, ard, waddr, aaddr, acc);
        if (rst_n && st == ST_SMX && vix == 8'd0)
            $display("SMX t=%0t logit0=%0d logit1=%0d logit127=%0d", $time, logits[0], logits[1], logits[127]);
        if (rst_n && st == ST_ALIN && ten == 3'd1 && row == 9'd0 && col == 9'd0)
            $display("ALINWQ t=%0t ly=%0d sub=%0d aaddr=%0d waddr=%0d ard=%0d wrd=%0d", $time, ly, sub, aaddr, waddr, ard, wrd);
        if (rst_n && st == ST_ALIN && sub == 4'd0 && row == 9'd0 && col == 9'd0)
            $display("ALIN_ENTER t=%0t ly=%0d ten=%0d", $time, ly, ten);
        if (rst_n && st == ST_DN2 && sub == 4'd3 && dim == 9'd0)
            $display("DH0 t=%0t dY0=%0d acc=%0d dH=%0d", $time, dY[0], acc, sat16(dY[0] + 32'(sat16(sat32(acc >>> LIN_SHIFT)))));
    end
`endif

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= ST_IDLE;
            done <= 1'b0;
            pred <= 8'd0;
            last_loss <= 16'd0;
            ce0 <= 32'd0;
            ce1 <= 32'd0;
            wr_n <= 32'd0;
            xor32 <= 32'd0;
            add32 <= 32'd0;
            ntok <= 5'd0;
            wwe <= 1'b0;
            cwe <= 1'b0;
            awe <= 1'b0;
            isq_go <= 1'b0;
            fd_go <= 1'b0;
            isq_pend <= 1'b0;
            scale <= 16'd16;
            train <= 1'b0;
            corpus <= 1'b0;
            after_r <= 1'b0;
            head_only <= 1'b1;
            do_full <= 1'b0;
            ce_after <= 1'b0;
            waddr <= 17'd0;
            caddr <= 17'd0;
            ck_raddr <= 17'd0;
            acc <= 64'sd0;
            sub <= 4'd0;
            for (ii = 0; ii < 32; ii = ii + 1) tok[ii] <= 8'd0;
            for (ii = 0; ii < 256; ii = ii + 1) begin
                logits[ii] <= 32'sd0;
                smx_e[ii] <= 8'd0;
            end
        end else begin
            done <= 1'b0;
            wwe <= 1'b0;
            cwe <= 1'b0;
            awe <= 1'b0;
            isq_go <= 1'b0;
            fd_go <= 1'b0;
            after_r <= after_mode;
            if (st == ST_IDLE && !mem_we)
                waddr <= mem_addr;
            if (st == ST_IDLE && ctx_we) begin
                if (ctx_idx == 4'd0)
                    ntok <= ctx_n_in;
                for (ii = 0; ii < 8; ii = ii + 1)
                    if ({11'd0, ctx_idx} + ii < 32)
                        tok[ctx_idx + ii[4:0]] <= ctx_pack[8*ii +: 8];
            end
            unique case (st)
                ST_IDLE: begin
                    if (start_fwd || start_train || start_ce || start_corpus || do_snap || do_restore || do_fold) begin
                        tgt <= tgt_in;
                        lr <= lr_in;
                        train <= start_train;
                        corpus <= start_corpus;
                        head_only <= !start_train;
                        do_full <= start_train;
                        ce_after <= 1'b0;
                        n_pair <= (corpus_n == 8'd0) ? 8'd8 : corpus_n;
                        n_ep <= (corpus_ep == 8'd0) ? 8'd24 : corpus_ep;
                        pi <= 8'd0;
                        ep <= 8'd0;
                        if (do_fold) begin
                            xor32 <= 32'd0; add32 <= 32'd0; caddr <= 17'd0; waddr <= 17'd0; sub <= 4'd0; st <= ST_FOLD;
                        end else if (do_snap || do_restore) begin
                            st <= ST_DONE;
                        end else if (start_corpus) begin
                            ce0 <= 32'd0; ce1 <= 32'd0; wr_n <= 32'd0;
                            train <= 1'b0; head_only <= 1'b1; do_full <= 1'b0; ce_after <= 1'b0;
                            st <= ST_PAIR;
                        end else if (ntok == 4'd0) begin
                            st <= ST_DONE;
                        end else begin
                            ly <= 1'b0; tok_i <= 5'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;
                        end
                    end
                end
                ST_PAIR: begin
                    begin
                        logic [7:0] k;
                        k = 8'd1 + (pi % 8);
                        tgt <= (8'd32 + (k - 8'd1));
                        ntok <= 5'd1;
                        tok[0] <= k;
                    end
                    if (do_full) begin
                        train <= 1'b1;
                        head_only <= 1'b0;
                    end else if (ce_after || (ep == 8'd0)) begin
                        train <= 1'b0;
                        head_only <= 1'b1;
                    end else begin
                        train <= 1'b1;
                        head_only <= 1'b1;
                    end
                    ly <= 1'b0; tok_i <= 5'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;
                end
                ST_EMB: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= 17'(OFF_TOK) + 17'(tok[tok_i]) * 17'(D) + 17'(dim);
                            caddr <= 17'(OFF_POS) + 17'(tok_i) * 17'(D) + 17'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        default: begin
                            awe <= 1'b1;
                            aaddr <= aa(1'b0, 3'd0, tok_i, dim[5:0]);
                            awd <= 32'(sat16(32'(wrd) + 32'(crd)));
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 5'd1 >= ntok) begin
                                    tok_i <= 5'd0; ly <= 1'b0; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                end else
                                    tok_i <= tok_i + 5'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_LN_S: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) begin
                                if (ly) aaddr <= ay(1'b0, tok_i, dim[5:0]);
                                else aaddr <= aa(1'b0, 3'd0, tok_i, dim[5:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[5:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            acc <= acc + 64'(ard);
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                sub <= 4'd3;
                            end else
                                dim <= dim + 9'd1;
                        end
                        default: begin
                            mu <= sat32(acc >>> 6); // D=64
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            st <= ST_LN_V;
                        end
                    endcase
                end
                ST_LN_V: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) begin
                                if (ly) aaddr <= ay(1'b0, tok_i, dim[5:0]);
                                else aaddr <= aa(1'b0, 3'd0, tok_i, dim[5:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[5:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= ard - mu;
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_a);
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                sub <= 4'd4;
                            end else
                                dim <= dim + 9'd1;
                        end
                        default: begin
                            var_u <= acc[37:6]; // (sum sq) // 64, unsigned, may set bit31
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            isq_pend <= 1'b0;
                            st <= ST_LN_SQ;
                        end
                    endcase
                end
                ST_LN_SQ: begin
                    if (var_u == 32'd0) begin
                        scale <= 16'd16;
                        isq_pend <= 1'b0;
                        st <= ST_LN_O;
                    end else if (isq_done) begin
                        scale <= (isq_y < 16'd1) ? 16'd1 : isq_y;
                        isq_pend <= 1'b0;
                        st <= ST_LN_O;
                    end else if (!isq_pend) begin
                        isq_x <= var_u;
                        isq_go <= 1'b1;
                        isq_pend <= 1'b1;
                    end
                end
                ST_LN_O: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) begin
                                if (ly) aaddr <= ay(1'b0, tok_i, dim[5:0]);
                                else aaddr <= aa(1'b0, 3'd0, tok_i, dim[5:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[5:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            fd_n <= 48'(ard - mu) * 48'sd16;
                            fd_d <= (scale == 16'd0) ? 16'd1 : scale;
                            fd_go <= 1'b1;
                            sub <= 4'd3;
                        end
                        default: if (fd_done) begin
                            awe <= 1'b1;
                            aaddr <= aa(ly, (ten == 3'd0) ? 3'd1 : 3'd7, tok_i, dim[5:0]);
                            awd <= 32'(sat16(fd_q));
                            if (ten == 3'd0 && tok_i == last_tok(ntok))
                                n1_last[ly][dim[5:0]] <= 32'(sat16(fd_q));
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 5'd1 >= ntok) begin
                                    tok_i <= 5'd0;
                                    if (ten == 3'd0) begin
                                        wbase <= layer_base(ly) + 17'(LO_WQ);
                                        ten_o <= 3'd2; nrows <= 9'(D); ncols <= 9'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end else begin
                                        wbase <= layer_base(ly) + 17'(LO_FF1);
                                        ten_o <= 3'd0; nrows <= 9'(FF); ncols <= 9'(D); relu <= 1'b1;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end
                                end else begin
                                    // Layernorm statistics are token-local. Re-enter the
                                    // sum/variance path instead of reusing token 0 mu/scale.
                                    tok_i <= tok_i + 5'd1;
                                    acc <= 64'sd0;
                                    st <= ST_LN_S;
                                end
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_MV: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= wbase + 17'(row) * 17'(ncols) + 17'(col);
                            if (relu && ten_o == 3'd0)
                                aaddr <= aa(ly, 3'd7, tok_i, col[5:0]);
                            else if (ten_o == 3'd2 || ten_o == 3'd3 || ten_o == 3'd4)
                                aaddr <= aa(ly, 3'd1, tok_i, col[5:0]);
                            else if (ten_o == 3'd5)
                                aaddr <= aa(ly, 3'd5, tok_i, col[5:0]);
                            else if (ten_o == 3'd6)
                                aaddr <= ah(ly, tok_i, col[6:0]);
                            else if (ten_o == 3'd7)
                                aaddr <= ay(ly, tok_i, col[5:0]);
                            else
                                aaddr <= aa(ly, 3'd1, tok_i, col[5:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(wrd);
                            op_b <= ard;
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (col + 9'd1 == ncols) begin
                                col <= 9'd0;
                                sub <= 4'd4;
                            end else begin
                                col <= col + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        default: begin
                            tmp32 <= sat32(acc);
                            if (relu && ten_o == 3'd0) begin
                                awe <= 1'b1;
                                aaddr <= ah(ly, tok_i, row[6:0]);
                                awd <= (sat16(sat32(acc)) < 0) ? 32'sd0 : 32'(sat16(sat32(acc)));
                            end else if (ten_o == 3'd7) begin
                                logits[row[7:0]] <= sat32(acc);
                            end else if (ten_o == 3'd6) begin
                                awe <= 1'b1;
                                aaddr <= ay(ly, tok_i, row[5:0]);
                                awd <= sat32(acc);
                            end else if (ten_o == 3'd5) begin
                                awe <= 1'b1;
                                aaddr <= aa(ly, 3'd2, tok_i, row[5:0]); // WO into Q slot; keep a
                                awd <= sat32(acc);
                            end else begin
                                awe <= 1'b1;
                                aaddr <= aa(ly, ten_o, tok_i, row[5:0]);
                                awd <= sat32(acc);
                            end
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (row + 9'd1 == nrows) begin
                                row <= 9'd0;
                                if (ten_o == 3'd7) begin
                                    vix <= 8'd0; mx <= logits[0]; st <= ST_SMX;
                                end else if (tok_i + 5'd1 >= ntok) begin
                                    tok_i <= 5'd0;
                                    if (ten_o == 3'd2) begin
                                        wbase <= layer_base(ly) + 17'(LO_WK); ten_o <= 3'd3; st <= ST_MV;
                                    end else if (ten_o == 3'd3) begin
                                        wbase <= layer_base(ly) + 17'(LO_WV); ten_o <= 3'd4; st <= ST_MV;
                                    end else if (ten_o == 3'd4) begin
                                        hix <= 2'd0; tok_i <= 5'd0; tok_j <= 5'd0; dim <= 9'd0; acc <= 64'sd0;
                                        st <= ST_ATT_SC;
                                    end else if (ten_o == 3'd5) begin
                                        tok_i <= 5'd0; dim <= 9'd0; ten <= 3'd0; st <= ST_ADD;
                                    end else if (ten_o == 3'd0 && relu) begin
                                        wbase <= layer_base(ly) + 17'(LO_FF2); ten_o <= 3'd6;
                                        nrows <= 9'(D); ncols <= 9'(FF); relu <= 1'b0; st <= ST_MV;
                                    end else if (ten_o == 3'd6) begin
                                        tok_i <= 5'd0; dim <= 9'd0; ten <= 3'd1; st <= ST_ADD;
                                    end else
                                        st <= ST_DONE;
                                end else
                                    tok_i <= tok_i + 5'd1;
                            end else
                                row <= row + 9'd1;
                        end
                    endcase
                end
                ST_ATT_SC: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= aa(ly, 3'd2, tok_i, {hix[1:0], dim[3:0]});
                            aaddr_b <= aa(ly, 3'd3, tok_j, {hix[1:0], dim[3:0]});
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= ard;
                            op_b <= ard_b;
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (dim + 9'd1 == 9'(DH)) begin
                                dim <= 9'd0;
                                sub <= 4'd4;
                            end else begin
                                dim <= dim + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        default: begin
                            score[tok_j] <= sat32(acc >>> 2); // //4
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (tok_j + 5'd1 > tok_i) begin
                                mx <= score[0];
                                tok_j <= 5'd0;
                                st <= ST_ATT_MX;
                            end else
                                tok_j <= tok_j + 5'd1;
                        end
                    endcase
                end
                ST_ATT_MX: begin
                    if (tok_j <= tok_i) begin
                        if (tok_j == 4'd0) mx <= score[0];
                        else if (score[tok_j] > mx) mx <= score[tok_j];
                        if (tok_j == tok_i) begin
                            tok_j <= 5'd0; st <= ST_ATT_E;
                        end else
                            tok_j <= tok_j + 5'd1;
                    end
                end
                ST_ATT_E: begin
                    if (tok_j > tok_i) exps[tok_j] <= 8'd0;
                    else exps[tok_j] <= relu_exp(score[tok_j], mx);
                    if (tok_j == 5'd31) begin
                        tok_j <= 5'd0; zsum <= 32'sd0; st <= ST_ATT_Z;
                    end else
                        tok_j <= tok_j + 5'd1;
                end
                ST_ATT_Z: begin
                    if (tok_j <= tok_i)
                        zsum <= zsum + 32'(exps[tok_j]);
                    if (tok_j == tok_i) begin
                        if (zsum + 32'(exps[tok_j]) == 0) z_last[hix] <= 32'sd1;
                        else z_last[hix] <= zsum + 32'(exps[tok_j]);
                        for (ii = 0; ii < 32; ii = ii + 1)
                            e_last[hix][ii] <= exps[ii];
                        tok_j <= 5'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0;
                        st <= ST_ATT_O;
                    end else
                        tok_j <= tok_j + 5'd1;
                end
                ST_ATT_O: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= aa(ly, 3'd4, tok_j, {hix[1:0], dim[3:0]});
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(exps[tok_j]);
                            op_b <= ard;
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (tok_j + 5'd1 > tok_i) begin
                                sub <= 4'd4;
                            end else begin
                                tok_j <= tok_j + 5'd1;
                                sub <= 4'd0;
                            end
                        end
                        4'd4: begin
                            fd_n <= acc[47:0];
                            fd_d <= denom16(z_last[hix]);
                            fd_go <= 1'b1;
                            sub <= 4'd5;
                        end
                        default: if (fd_done) begin
                            awe <= 1'b1;
                            aaddr <= aa(ly, 3'd5, tok_i, {hix[1:0], dim[3:0]});
                            awd <= 32'(sat16(fd_q));
                            if (tok_i == last_tok(ntok))
                                a_last[ly][{hix[1:0], dim[3:0]}] <= 32'(sat16(fd_q));
                            acc <= 64'sd0;
                            tok_j <= 5'd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(DH)) begin
                                dim <= 9'd0;
                                if (hix != 2'd3) begin
                                    hix <= hix + 2'd1; st <= ST_ATT_SC;
                                end else begin
                                    hix <= 2'd0;
                                    if (tok_i + 5'd1 >= ntok) begin
                                        tok_i <= 5'd0;
                                        wbase <= layer_base(ly) + 17'(LO_WO);
                                        ten_o <= 3'd5; nrows <= 9'(D); ncols <= 9'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; st <= ST_MV;
                                    end else begin
                                        tok_i <= tok_i + 5'd1; st <= ST_ATT_SC;
                                    end
                                end
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_ADD: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) begin
                                if (ly) aaddr <= ay(1'b0, tok_i, dim[5:0]);
                                else aaddr <= aa(1'b0, 3'd0, tok_i, dim[5:0]);
                                aaddr_b <= aa(ly, 3'd2, tok_i, dim[5:0]); // WO result
                            end else begin
                                aaddr <= aa(ly, 3'd6, tok_i, dim[5:0]);
                                aaddr_b <= ay(ly, tok_i, dim[5:0]);
                            end
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        default: begin
                            awe <= 1'b1;
                            if (ten == 3'd0) begin
                                aaddr <= aa(ly, 3'd6, tok_i, dim[5:0]);
                                awd <= 32'(sat16(ard + ard_b));
                            end else begin
                                aaddr <= ay(ly, tok_i, dim[5:0]);
                                awd <= 32'(sat16(ard + ard_b));
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 5'd1 >= ntok) begin
                                    tok_i <= 5'd0;
                                    if (ten == 3'd0) begin
                                        ten <= 3'd6; acc <= 64'sd0; st <= ST_LN_S;
                                    end else if (!ly) begin
                                        ly <= 1'b1; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                    end else begin
                                        tok_i <= last_tok(ntok);
                                        wbase <= 17'(OFF_HEAD); ten_o <= 3'd7;
                                        nrows <= 9'(V); ncols <= 9'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end
                                end else
                                    tok_i <= tok_i + 5'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_SMX: begin
                    if (vix == 8'd0)
                        mx <= logits[0];
                    if (logits[vix] > mx) mx <= logits[vix];
                    if (vix == 8'd255) begin
                        vix <= 8'd0; ssoft <= 32'sd0; sub <= 4'd0; st <= ST_ARG;
                    end else
                        vix <= vix + 8'd1;
                end
                ST_ARG: begin
                    unique case (sub)
                        4'd0: begin
                            smx_e[vix] <= relu_exp(logits[vix], mx);
                            if (vix == 8'd0) begin
                                arg_best <= 8'd0; arg_v <= logits[0];
                            end else if ((logits[vix] > arg_v) || (logits[vix] == arg_v && vix < arg_best)) begin
                                arg_best <= vix; arg_v <= logits[vix];
                            end
                            if (vix == 8'd255) begin
                                vix <= 8'd0; ssoft <= 32'sd0; sub <= 4'd1;
                            end else
                                vix <= vix + 8'd1;
                        end
                        4'd1: begin
                            ssoft <= ssoft + 32'(smx_e[vix]);
                            if (vix == 8'd255) begin
                                if (ssoft + 32'(smx_e[vix]) == 0) ssoft <= 32'sd1;
                                else ssoft <= ssoft + 32'(smx_e[vix]);
                                pred <= arg_best;
                                last_loss <= 16'((ssoft + 32'(smx_e[vix]) == 0 ? 32'sd1 : ssoft + 32'(smx_e[vix]))
                                    - 32'(smx_e[tgt]));
                                if (train && !after_r) begin
                                    vix <= 8'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_BH;
                                end else if (corpus) begin
                                    st <= ST_CEACC;
                                end else
                                    st <= ST_DONE;
                            end else
                                vix <= vix + 8'd1;
                        end
                        default: sub <= 4'd0;
                    endcase
                end
                ST_CEACC: begin
                    if (!train) begin
                        if (!ce_after) ce0 <= ce0 + 32'(last_loss);
                        else ce1 <= ce1 + 32'(last_loss);
                    end
                    st <= ST_NEXT;
                end
                ST_NEXT: begin
                    if (do_full) begin
                        do_full <= 1'b0;
                        train <= 1'b0;
                        ce_after <= 1'b1;
                        pi <= 8'd0;
                        st <= ST_PAIR;
                    end else if (pi + 8'd1 >= n_pair) begin
                        pi <= 8'd0;
                        if (ep == 8'd0 && !ce_after && corpus) begin
                            ep <= 8'd1; st <= ST_PAIR;
                        end else if (train && head_only && ep < n_ep) begin
                            ep <= ep + 8'd1; st <= ST_PAIR;
                        end else if (train && head_only && ep >= n_ep && corpus) begin
                            do_full <= 1'b1; pi <= 8'd0; st <= ST_PAIR;
                        end else
                            st <= ST_DONE;
                    end else begin
                        pi <= pi + 8'd1; st <= ST_PAIR;
                    end
                end
                ST_BH: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= ay(1'b1, last_tok(ntok), dim[5:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            tmp32 <= ard;
                            vix <= 8'd0;
                            acc <= 64'sd0;
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            dz_r <= 32'(smx_e[vix]) - ((vix == tgt) ? ssoft : 32'sd0);
                            sub <= 4'd4;
                        end
                        4'd4: begin
                            fd_n <= 48'(dz_r) * 48'(tmp32);
                            fd_d <= denom16(ssoft);
                            fd_go <= 1'b1;
                            waddr <= 17'(OFF_HEAD) + 17'(vix) * 17'(D) + 17'(dim);
                            sub <= 4'd5;
                        end
                        4'd5: if (fd_done) begin
                            gtmp <= sat16(fd_q);
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(sat16(fd_q) >>> lr));
                                wr_n <= wr_n + 32'd1;
                            end
                            op_a <= 32'(wrd);
                            op_b <= dz_r;
                            if (vix == 8'd255 && head_only) begin
                                vix <= 8'd0; acc <= 64'sd0; sub <= 4'd0;
                                if (dim + 9'd1 == 9'(D)) begin
                                    dim <= 9'd0;
                                    if (corpus || ce_after) st <= ST_CEACC;
                                    else st <= ST_DONE;
                                end else
                                    dim <= dim + 9'd1;
                            end else
                                sub <= 4'd8;
                        end
                        4'd8: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (vix == 8'd255) begin
                                sub <= 4'd6;
                            end else begin
                                vix <= vix + 8'd1;
                                sub <= 4'd3;
                            end
                        end
                        4'd6: begin
                            fd_n <= acc[47:0];
                            fd_d <= denom16(ssoft);
                            fd_go <= 1'b1;
                            sub <= 4'd7;
                        end
                        default: if (fd_done) begin
                            dY[dim[5:0]] <= 32'(sat16(fd_q));
                            acc <= 64'sd0;
                            vix <= 8'd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0; col <= 9'd0; ly <= 1'b1; st <= ST_DHID;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_DHID: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= layer_base(ly) + 17'(LO_FF2) + 17'(dim) * 17'(FF) + 17'(col);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(wrd);
                            op_b <= dY[dim[5:0]];
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                aaddr <= ah(ly, last_tok(ntok), col[6:0]);
                                sub <= 4'd4;
                            end else begin
                                dim <= dim + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        4'd4: sub <= 4'd5;
                        default: begin
                            dHid[col[6:0]] <= (ard == 32'sd0) ? 32'sd0 : 32'(sat16(acc >>> LIN_SHIFT));
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (col + 9'd1 == 9'(FF)) begin
                                col <= 9'd0; dim <= 9'd0; st <= ST_AFF2;
                            end else
                                col <= col + 9'd1;
                        end
                    endcase
                end
                ST_AFF2: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= ah(ly, last_tok(ntok), col[6:0]);
                            waddr <= layer_base(ly) + 17'(LO_FF2) + 17'(dim) * 17'(FF) + 17'(col);
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            dy_r <= dY[dim[5:0]];
                            sub <= 4'd2;
                        end
                        4'd2: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(ard)) >>> LIN_SHIFT));
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (col + 9'd1 == 9'(FF)) begin
                                col <= 9'd0;
                                if (dim + 9'd1 == 9'(D)) begin
                                    dim <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_DN2;
                                end else
                                    dim <= dim + 9'd1;
                            end else
                                col <= col + 9'd1;
                        end
                    endcase
                end
                ST_DN2: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= layer_base(ly) + 17'(LO_FF1) + 17'(col) * 17'(D) + 17'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(wrd);
                            op_b <= dHid[col[6:0]];
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (col + 9'd1 == 9'(FF)) begin
                                col <= 9'd0;
                                sub <= 4'd4;
                            end else begin
                                col <= col + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        default: begin
                            dH[dim[5:0]] <= 32'(sat16(dY[dim[5:0]] + 32'(sat16(sat32(acc >>> LIN_SHIFT)))));
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0; col <= 9'd0; st <= ST_AFF1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_AFF1: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= aa(ly, 3'd7, last_tok(ntok), dim[5:0]);
                            waddr <= layer_base(ly) + 17'(LO_FF1) + 17'(col) * 17'(D) + 17'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            dy_r <= dHid[col[6:0]];
                            sub <= 4'd2;
                        end
                        4'd2: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(ard)) >>> LIN_SHIFT));
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                dim <= 9'd0;
                                if (col + 9'd1 == 9'(FF)) begin
                                    col <= 9'd0; row <= 9'd0; ten <= 3'd0; st <= ST_ALIN;
                                end else
                                    col <= col + 9'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_ALIN: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) aaddr <= aa(ly, 3'd5, last_tok(ntok), col[5:0]);
                            else aaddr <= aa(ly, 3'd1, last_tok(ntok), col[5:0]);
                            unique case (ten)
                                3'd0: waddr <= layer_base(ly) + 17'(LO_WO) + 17'(row) * 17'(D) + 17'(col);
                                3'd1: waddr <= layer_base(ly) + 17'(LO_WQ) + 17'(row) * 17'(D) + 17'(col);
                                3'd2: waddr <= layer_base(ly) + 17'(LO_WK) + 17'(row) * 17'(D) + 17'(col);
                                default: waddr <= layer_base(ly) + 17'(LO_WV) + 17'(row) * 17'(D) + 17'(col);
                            endcase
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            x_r <= (ten == 3'd0) ? a_last[ly][col[5:0]] : n1_last[ly][col[5:0]];
                            dy_r <= dH[row[5:0]];
                            sub <= 4'd2;
                        end
                        4'd2: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(x_r)) >>> LIN_SHIFT));
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (col + 9'd1 == 9'(D)) begin
                                col <= 9'd0;
                                if (row + 9'd1 == 9'(D)) begin
                                    row <= 9'd0;
                                    if (ten == 3'd3) begin
                                        for (ii = 0; ii < 64; ii = ii + 1)
                                            dY[ii] <= dH[ii];
                                        if (ly) begin
                                            ly <= 1'b0; col <= 9'd0; dim <= 9'd0; acc <= 64'sd0; st <= ST_DHID;
                                        end else begin
                                            dim <= 9'd0; sub <= 4'd0; st <= ST_BEM;
                                        end
                                    end else
                                        ten <= ten + 3'd1;
                                end else
                                    row <= row + 9'd1;
                            end else
                                col <= col + 9'd1;
                        end
                    endcase
                end
                ST_BEM: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= 17'(OFF_TOK) + 17'(tok[last_tok(ntok)]) * 17'(D) + 17'(dim);
                            caddr <= 17'(OFF_POS) + 17'(last_tok(ntok)) * 17'(D) + 17'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(sat16(dY[dim[5:0]]))));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                waddr <= 17'(OFF_POS) + 17'(last_tok(ntok)) * 17'(D) + 17'(dim);
                                wwd <= sat8(32'(crd) - 32'(step_sign(sat16(dY[dim[5:0]]))));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(D)) begin
                                if (corpus || ce_after) st <= ST_CEACC;
                                else st <= ST_DONE;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_FOLD: begin
                    unique case (sub)
                        4'd0: begin waddr <= caddr; sub <= 4'd1; end
                        4'd1: sub <= 4'd2;
                        default: begin
                            xor32 <= xor32 ^ {24'd0, wrd};
                            add32 <= add32 + {24'd0, wrd};
                            sub <= 4'd0;
                            if (caddr + 17'd1 >= 17'(NPARAM)) st <= ST_DONE;
                            else caddr <= caddr + 17'd1;
                        end
                    endcase
                end
                ST_SNAP: begin
                    unique case (sub)
                        4'd0: begin waddr <= caddr; sub <= 4'd1; end
                        4'd1: sub <= 4'd2;
                        default: begin
                            cwe <= 1'b1;
                            sub <= 4'd0;
                            if (caddr + 17'd1 >= 17'(NPARAM)) st <= ST_DONE;
                            else begin
                                caddr <= caddr + 17'd1;
                                waddr <= caddr + 17'd1;
                            end
                        end
                    endcase
                end
                ST_REST: begin
                    unique case (sub)
                        4'd0: begin ck_raddr <= caddr; sub <= 4'd1; end
                        4'd1: sub <= 4'd2;
                        default: begin
                            wwe <= 1'b1; wwd <= ckd; waddr <= caddr;
                            sub <= 4'd0;
                            if (caddr + 17'd1 >= 17'(NPARAM)) st <= ST_DONE;
                            else caddr <= caddr + 17'd1;
                        end
                    endcase
                end
                ST_DONE: begin
                    done <= 1'b1;
                    st <= ST_IDLE;
                end
                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
