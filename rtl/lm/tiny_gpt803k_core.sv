`timescale 1ns/1ps
import a7lm06_pkg::*;

// One asynchronous read port is sufficient because softmax/argmax scan the
// vocabulary serially.  Keeping the write port outside the main FSM gives
// Vivado an unambiguous distributed-RAM template instead of 16K FFs and a
// 512:1 read mux.
module a7lm06_logits_lutram (
    input  logic               clk,
    input  logic               we,
    input  logic [9:0]         waddr,
    input  logic signed [31:0] wdata,
    input  logic [9:0]         raddr,
    output logic signed [31:0] rdata
);
    (* ram_style = "distributed" *) logic signed [31:0] mem [0:1023];
    always_ff @(posedge clk)
        if (we) mem[waddr] <= wdata;
    assign rdata = mem[raddr];
endmodule

// Sequential 4-layer 4-head TinyGPT. law_id lm06-signsgd-v1.
// Timing: no combinational 64-bit /. Power-of-two via ASR. Variable via floordiv_s48.
// Counters: V=1024 10-bit, C=128 7-bit, D/FF fit in 9-bit.
module tiny_gpt803k_core #(
    parameter bit SIM_FULL = 1'b1
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               mem_we,
    input  logic [19:0]        mem_addr,
    input  logic signed [7:0]  mem_wdata,
    output logic signed [7:0]  mem_rdata,
    input  logic               ctx_we,
    input  logic [6:0]         ctx_idx,
    input  logic [6:0]         ctx_n_in,
    input  logic [63:0]        ctx_pack,
    input  logic               start_fwd,
    input  logic               start_train,
    input  logic               start_ce,
    input  logic               start_corpus,
    input  logic               after_mode,
    input  logic               do_snap,
    input  logic               do_restore,
    input  logic               do_fold,
    input  logic [9:0]         tgt_in,
    input  logic [3:0]         lr_in,
    input  logic [7:0]         corpus_n,
    input  logic [7:0]         corpus_ep,
    output logic               busy,
    output logic               done,
    output logic [9:0]         pred,
    output logic [15:0]        last_loss,
    output logic [31:0]        ce0,
    output logic [31:0]        ce1,
    output logic [31:0]        wr_n,
    output logic [31:0]        xor32,
    output logic [31:0]        add32,
    output logic [7:0]         phase,
    output logic               w_stall,
    input  logic               clk_dma = 1'b0,
    input  logic               rst_dma_n = 1'b1,
    output logic               wdma_owner,
    output logic               wdma_go,
    output logic               wdma_wr,
    output logic [27:0]        wdma_addr,
    output logic [31:0]        wdma_bytes,
    input  logic               wdma_busy = 1'b0,
    input  logic               wdma_done = 1'b0,
    output logic               wdma_w_valid,
    input  logic               wdma_w_ready = 1'b0,
    output logic [127:0]       wdma_w_data,
    input  logic               wdma_r_valid = 1'b0,
    output logic               wdma_r_ready,
    input  logic [127:0]       wdma_r_data = 128'd0,
    output logic [3:0]         dbg_tile_bst,
    output logic [2:0]         dbg_tile_dst,
    output logic [2:0]         dbg_tile_rg,
    output logic               dbg_tile_miss,
    output logic               dbg_tile_dirty,
    output logic               dbg_tile_req
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
    logic [6:0] ntok, tok_i, tok_j;
    logic [7:0] tok [0:127];
    logic [9:0] tgt;
    logic [3:0] lr;
    logic [1:0]  ly;
    logic [2:0] ten, ten_o;
    logic [10:0] dim, col, row, nrows, ncols;
    logic [9:0] vix;
    logic signed [63:0] acc;
    logic signed [31:0] mu, tmp32, mx, zsum, ssoft, dz_r, op_a, op_b, x_r, dy_r;
    logic [31:0]        var_u;
    logic signed [31:0] score [0:127];
    logic [7:0]         exps [0:127];
    logic [7:0]         e_last [0:3][0:127];
    logic signed [31:0] z_last [0:3];
    logic [15:0]        isq_y, scale;
    logic               isq_go, isq_done, fd_go, fd_done;
    logic [31:0]        isq_x;
    logic signed [47:0] fd_n;
    logic [15:0]        fd_d;
    logic signed [31:0] fd_q;
    logic               train, corpus, after_r, head_only, do_full, ce_after;
    logic [7:0]         pi, ep, n_pair, n_ep;
    logic [19:0]        waddr, caddr, ck_raddr;
    logic signed [7:0]  wrd, crd, ckd, wwd;
    logic               wwe, cwe;
    logic signed [31:0] ard, ard_b, awd;
    logic [16:0]        aaddr, aaddr_b;
    logic               awe;
    logic signed [31:0] logit_q;
    logic               logit_we;
    logic [7:0]         smx_e [0:1023];
    logic [9:0]         arg_best;
    logic signed [31:0] arg_v;
    logic [1:0]         hix;
    logic               relu;
    logic [19:0]        wbase;
    logic [3:0]         sub;
    // Isolation: full-backprop scratch must stay FF arrays. Vivado mapped the
    // bare dHid[0:63] array to RAMS64E; behavioral xsim then diverges from
    // the post-synth netlist. Same risk on the sibling scratch tensors.
    (* ram_style = "registers" *) logic signed [31:0] dY [0:127];
    (* ram_style = "registers" *) logic signed [31:0] dH [0:127];
    (* ram_style = "registers" *) logic signed [31:0] dHid [0:255];
    logic               snap_we;
    logic [11:0]        snap_waddr, snap_raddr;
    logic signed [15:0] snap_wdata, snap_rdata;
    logic signed [15:0] gtmp;
    logic               isq_pend;
    integer ii;

    assign logit_we = rst_n && !w_stall && (st == ST_MV) &&
                      (sub == 4'd4) && (ten_o == 3'd7);
    a7lm06_logits_lutram u_logits (
        .clk(clk), .we(logit_we), .waddr(row[9:0]), .wdata(sat32(acc)),
        .raddr(vix), .rdata(logit_q)
    );

    // Dense 128K INT16 map. ly is reused: last-token bwd lives in snaps.
    //   aa(t,tk,d) = t*16384 + tk*128 + d         t=0..7 → 131072
    //   ah overlays t=3/4 after attn (K/V dead)
    //   ay overlays t=0 after residual-in is consumed (ADD ten=0 then FF2)
    function automatic [16:0] aa(input [1:0] ly_, input [2:0] t, input [6:0] tk, input [6:0] d);
        return 17'(t) * 17'(ACT_STRIDE) + 17'(tk) * 17'(D) + 17'(d);
    endfunction

    function automatic [16:0] ah(input [1:0] ly_, input [6:0] tk, input [8:0] hh);
        logic [2:0] t;
        logic [6:0] d;
        t = (hh < 8'(D)) ? 3'd3 : 3'd4;
        d = (hh < 8'(D)) ? hh[6:0] : 7'(hh - 8'(D));
        return aa(ly_, t, tk, d);
    endfunction

    function automatic [16:0] ay(input [1:0] ly_, input [6:0] tk, input [6:0] d);
        return aa(ly_, 3'd0, tk, d);
    endfunction

    function automatic [11:0] snap_n1(input [1:0] ly_, input [6:0] d);
        return 12'(ly_) * 12'(D) + 12'(d);
    endfunction
    function automatic [11:0] snap_n2(input [1:0] ly_, input [6:0] d);
        return 12'd512 + 12'(ly_) * 12'(D) + 12'(d);
    endfunction
    function automatic [11:0] snap_at(input [1:0] ly_, input [6:0] d);
        return 12'd1024 + 12'(ly_) * 12'(D) + 12'(d);
    endfunction
    function automatic [11:0] snap_h(input [1:0] ly_, input [8:0] hh);
        return 12'd1536 + 12'(ly_) * 12'(FF) + 12'(hh);
    endfunction

    function automatic [6:0] last_tok(input [6:0] n);
        return (n == 7'd0) ? 7'd0 : (n - 7'd1);
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
        if (e > 32'sd255) return 10'd1023;
        return e[7:0];
    endfunction

    logic host_sel, host_we;
    // Idle: host owns port A so 0x31 readback sees mem_addr the same cycle.
    // BRAM output latency is then exactly 1 clk (see weight_bram100k).
    assign host_sel = (st == ST_IDLE);
    assign host_we  = host_sel && mem_we;
    // One W region is resident. Port B must not sit in another region
    // or the tile refill oscillates (board C0: stall at OFF_POS=131072).
    // crd is display-only; fold/compute use wrd on port A. Host idle
    // parks B on mem_addr so UART writes cannot straddle TOK/POS.
    logic [19:0] w_addr_b;
    assign w_addr_b = host_sel ? mem_addr : waddr;
    weight_tile803k #(.SIM_FULL(SIM_FULL)) u_w (
        .clk(clk), .rst_n(rst_n),
        .clk_dma(clk_dma), .rst_dma_n(rst_dma_n),
        .we_a(host_we || wwe),
        .addr_a(host_sel ? mem_addr : waddr),
        .wdata_a(host_we ? mem_wdata : wwd),
        .rdata_a(wrd),
        .addr_b(w_addr_b), .rdata_b(crd),
        .stall(w_stall),
        .cached_rg(), .dirty(),
        .dma_owner(wdma_owner),
        .dma_go(wdma_go), .dma_wr(wdma_wr),
        .dma_addr(wdma_addr), .dma_bytes(wdma_bytes),
        .dma_busy(wdma_busy), .dma_done(wdma_done),
        .dma_w_valid(wdma_w_valid), .dma_w_ready(wdma_w_ready), .dma_w_data(wdma_w_data),
        .dma_r_valid(wdma_r_valid), .dma_r_ready(wdma_r_ready), .dma_r_data(wdma_r_data),
        .dbg_bst(dbg_tile_bst), .dbg_dst(dbg_tile_dst), .dbg_cur_rg(dbg_tile_rg),
        .dbg_miss(dbg_tile_miss), .dbg_dirty(dbg_tile_dirty), .dbg_req(dbg_tile_req)
    );
    // On-chip checkpoint dropped: snap/restore are DDR persist in the top.
    assign ckd = 8'sd0;
    logic signed [15:0] ard16, ard_b16, awd16;
    assign awd16 = sat16(awd);
    assign ard = {{16{ard16[15]}}, ard16};
    assign ard_b = {{16{ard_b16[15]}}, ard_b16};
    act_ram128k16 u_a (
        .clk(clk), .we_a(awe), .addr_a(aaddr), .wdata_a(awd16), .rdata_a(ard16),
        .addr_b(aaddr_b), .rdata_b(ard_b16)
    );
    snap_ram4k16 u_snap (
        .clk(clk), .we(snap_we), .waddr(snap_waddr), .wdata(snap_wdata),
        .raddr(snap_raddr), .rdata(snap_rdata)
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
            $display("MV0 t=%0t ly=%0d ten_o=%0d acc=%0d dest=%0d", $time, ly, ten_o, acc, aa(ly, ten_o, tok_i, row[6:0]));
        if (rst_n && st == ST_ATT_SC && sub == 4'd2 && dim == 9'd0 && tok_j == 4'd0)
            $display("ATTQK t=%0t ard=%0d ardb=%0d qa=%0d ka=%0d", $time, ard, ard_b, aaddr, aaddr_b);
        if (rst_n && st == ST_ATT_O && fd_done && dim == 9'd0)
            $display("ATTO t=%0t h=%0d q=%0d z=%0d acc=%0d dest=%0d", $time, hix, fd_q, z_last[hix], acc, aa(ly, 3'd5, tok_i, 7'(hix * 6'd32 + dim[4:0])));
        if (rst_n && st == ST_ADD && sub == 4'd2 && dim == 9'd0)
            $display("ADD t=%0t ly=%0d ten=%0d ard=%0d ardb=%0d", $time, ly, ten, ard, ard_b);
        if (rst_n && st == ST_MV && ten_o == 3'd7 && sub == 4'd2 && row == 9'd0 && col < 9'd2)
            $display("HEAD t=%0t col=%0d wrd=%0d ard=%0d waddr=%0d aaddr=%0d acc=%0d", $time, col, wrd, ard, waddr, aaddr, acc);
        if (rst_n && st == ST_SMX && vix == 9'd0)
            $display("SMX t=%0t logit0=%0d", $time, logit_q);
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
            ntok <= 7'd0;
            wwe <= 1'b0;
            cwe <= 1'b0;
            awe <= 1'b0;
            snap_we <= 1'b0;
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
            waddr <= 20'd0;
            caddr <= 20'd0;
            ck_raddr <= 20'd0;
            acc <= 64'sd0;
            sub <= 4'd0;
            for (ii = 0; ii < 128; ii = ii + 1) tok[ii] <= 8'd0;
            for (ii = 0; ii < 512; ii = ii + 1) begin
                smx_e[ii] <= 8'd0;
            end
        end else if (w_stall) begin
            done <= 1'b0;
            wwe <= 1'b0;
            cwe <= 1'b0;
            awe <= 1'b0;
            snap_we <= 1'b0;
            isq_go <= 1'b0;
            fd_go <= 1'b0;
        end else begin
            done <= 1'b0;
            wwe <= 1'b0;
            cwe <= 1'b0;
            awe <= 1'b0;
            snap_we <= 1'b0;
            isq_go <= 1'b0;
            fd_go <= 1'b0;
            after_r <= after_mode;
            if (st == ST_IDLE && !mem_we)
                waddr <= mem_addr;
            if (st == ST_IDLE && ctx_we) begin
                if (ctx_idx == 7'd0)
                    ntok <= ctx_n_in;
                for (ii = 0; ii < 8; ii = ii + 1)
                    if ({13'd0, ctx_idx} + ii < 128)
                        tok[ctx_idx + ii[6:0]] <= ctx_pack[8*ii +: 8];
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
                            xor32 <= 32'd0; add32 <= 32'd0; caddr <= 20'd0; waddr <= 20'd0; sub <= 4'd0; st <= ST_FOLD;
                        end else if (do_snap || do_restore) begin
                            st <= ST_DONE;
                        end else if (start_corpus) begin
                            ce0 <= 32'd0; ce1 <= 32'd0; wr_n <= 32'd0;
                            train <= 1'b0; head_only <= 1'b1; do_full <= 1'b0; ce_after <= 1'b0;
                            st <= ST_PAIR;
                        end else if (ntok == 4'd0) begin
                            st <= ST_DONE;
                        end else begin
                            ly <= 2'd0; tok_i <= 7'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;
                        end
                    end
                end
                ST_PAIR: begin
                    begin
                        logic [7:0] k;
                        k = 8'd1 + (pi % 8);
                        tgt <= (8'd32 + (k - 8'd1));
                        ntok <= 7'd1;
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
                    ly <= 2'd0; tok_i <= 7'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_EMB;
                end
                ST_EMB: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= 20'(OFF_TOK) + 20'(tok[tok_i]) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_TOK);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            acc[31:0] <= 32'(wrd);
                            waddr <= 20'(OFF_POS) + 20'(tok_i) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_POS);
                            sub <= 4'd3;
                        end
                        4'd3: sub <= 4'd4;
                        default: begin
                            awe <= 1'b1;
                            aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            awd <= 32'(sat16(acc[31:0] + 32'(wrd)));
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 7'd1 >= ntok) begin
                                    tok_i <= 7'd0; ly <= 2'd0; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                end else
                                    tok_i <= tok_i + 7'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_LN_S: begin
                    unique case (sub)
                        4'd0: begin
                            if (ten == 3'd0) begin
                                if (ly) aaddr <= ay(ly - 2'd1, tok_i, dim[6:0]);
                                else aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[6:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            acc <= acc + 64'(ard);
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                sub <= 4'd3;
                            end else
                                dim <= dim + 9'd1;
                        end
                        4'd3: begin
                            fd_n <= acc[47:0];
                            fd_d <= 16'(D);
                            fd_go <= 1'b1;
                            sub <= 4'd4;
                        end
                        default: if (fd_done) begin
                            mu <= sat32(fd_q);
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
                                if (ly) aaddr <= ay(ly - 2'd1, tok_i, dim[6:0]);
                                else aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[6:0]);
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
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                sub <= 4'd4;
                            end else
                                dim <= dim + 9'd1;
                        end
                        4'd4: begin
                            fd_n <= acc[47:0];
                            fd_d <= 16'(D);
                            fd_go <= 1'b1;
                            sub <= 4'd5;
                        end
                        default: if (fd_done) begin
                            var_u <= fd_q[31] ? 32'd0 : fd_q;
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
                                if (ly) aaddr <= ay(ly - 2'd1, tok_i, dim[6:0]);
                                else aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                            end else
                                aaddr <= aa(ly, 3'd6, tok_i, dim[6:0]);
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
                            aaddr <= aa(ly, (ten == 3'd0) ? 3'd1 : 3'd7, tok_i, dim[6:0]);
                            awd <= 32'(sat16(fd_q));
                            if (tok_i == last_tok(ntok)) begin
                                snap_we <= 1'b1;
                                snap_waddr <= (ten == 3'd0)
                                    ? snap_n1(ly, dim[6:0]) : snap_n2(ly, dim[6:0]);
                                snap_wdata <= sat16(fd_q);
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 7'd1 >= ntok) begin
                                    tok_i <= 7'd0;
                                    if (ten == 3'd0) begin
                                        wbase <= layer_base(ly) + 20'(LO_WQ);
                                        ten_o <= 3'd2; nrows <= 11'(D); ncols <= 11'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end else begin
                                        wbase <= layer_base(ly) + 20'(LO_FF1);
                                        ten_o <= 3'd0; nrows <= 11'(FF); ncols <= 11'(D); relu <= 1'b1;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end
                                end else
                                    tok_i <= tok_i + 7'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_MV: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= wbase + 20'(row) * 20'(ncols) + 20'(col);
                            if (relu && ten_o == 3'd0)
                                aaddr <= aa(ly, 3'd7, tok_i, col[6:0]);
                            else if (ten_o == 3'd2 || ten_o == 3'd3 || ten_o == 3'd4)
                                aaddr <= aa(ly, 3'd1, tok_i, col[6:0]);
                            else if (ten_o == 3'd5)
                                aaddr <= aa(ly, 3'd5, tok_i, col[6:0]);
                            else if (ten_o == 3'd6)
                                aaddr <= ah(ly, tok_i, col[7:0]);
                            else if (ten_o == 3'd7)
                                aaddr <= ay(2'd3, last_tok(ntok), col[6:0]);
                            else
                                aaddr <= aa(ly, 3'd1, tok_i, col[6:0]);
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
                                aaddr <= ah(ly, tok_i, row[7:0]);
                                awd <= (sat16(sat32(acc)) < 0) ? 32'sd0 : 32'(sat16(sat32(acc)));
                                if (tok_i == last_tok(ntok)) begin
                                    snap_we <= 1'b1;
                                    snap_waddr <= snap_h(ly, row[7:0]);
                                    snap_wdata <= (sat16(sat32(acc)) < 0)
                                        ? 16'sd0 : sat16(sat32(acc));
                                end
                            end else if (ten_o == 3'd7) begin
                                // u_logits captures row/acc on this edge.
                            end else if (ten_o == 3'd6) begin
                                awe <= 1'b1;
                                aaddr <= ay(ly, tok_i, row[6:0]);
                                awd <= sat32(acc);
                            end else if (ten_o == 3'd5) begin
                                awe <= 1'b1;
                                aaddr <= aa(ly, 3'd2, tok_i, row[6:0]); // WO into Q slot; keep a
                                awd <= sat32(acc);
                            end else begin
                                awe <= 1'b1;
                                aaddr <= aa(ly, ten_o, tok_i, row[6:0]);
                                awd <= sat32(acc);
                            end
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (row + 9'd1 == nrows) begin
                                row <= 9'd0;
                                if (ten_o == 3'd7) begin
                                    vix <= 9'd0; st <= ST_SMX;
                                end else if (tok_i + 7'd1 >= ntok) begin
                                    tok_i <= 7'd0;
                                    if (ten_o == 3'd2) begin
                                        wbase <= layer_base(ly) + 20'(LO_WK); ten_o <= 3'd3; st <= ST_MV;
                                    end else if (ten_o == 3'd3) begin
                                        wbase <= layer_base(ly) + 20'(LO_WV); ten_o <= 3'd4; st <= ST_MV;
                                    end else if (ten_o == 3'd4) begin
                                        hix <= 2'd0; tok_i <= 7'd0; tok_j <= 7'd0; dim <= 9'd0; acc <= 64'sd0;
                                        st <= ST_ATT_SC;
                                    end else if (ten_o == 3'd5) begin
                                        tok_i <= 7'd0; dim <= 9'd0; ten <= 3'd0; st <= ST_ADD;
                                    end else if (ten_o == 3'd0 && relu) begin
                                        wbase <= layer_base(ly) + 20'(LO_FF2); ten_o <= 3'd6;
                                        nrows <= 11'(D); ncols <= 11'(FF); relu <= 1'b0; st <= ST_MV;
                                    end else if (ten_o == 3'd6) begin
                                        tok_i <= 7'd0; dim <= 9'd0; ten <= 3'd1; st <= ST_ADD;
                                    end else
                                        st <= ST_DONE;
                                end else
                                    tok_i <= tok_i + 7'd1;
                            end else
                                row <= row + 9'd1;
                        end
                    endcase
                end
                ST_ATT_SC: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= aa(ly, 3'd2, tok_i, 7'(hix * 6'd32 + dim[4:0]));
                            aaddr_b <= aa(ly, 3'd3, tok_j, 7'(hix * 6'd32 + dim[4:0]));
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
                            if (tok_j + 7'd1 > tok_i) begin
                                mx <= score[0];
                                tok_j <= 7'd0;
                                st <= ST_ATT_MX;
                            end else
                                tok_j <= tok_j + 7'd1;
                        end
                    endcase
                end
                ST_ATT_MX: begin
                    if (tok_j <= tok_i) begin
                        if (tok_j == 4'd0) mx <= score[0];
                        else if (score[tok_j] > mx) mx <= score[tok_j];
                        if (tok_j == tok_i) begin
                            tok_j <= 7'd0; st <= ST_ATT_E;
                        end else
                            tok_j <= tok_j + 7'd1;
                    end
                end
                ST_ATT_E: begin
                    if (tok_j > tok_i) exps[tok_j] <= 8'd0;
                    else exps[tok_j] <= relu_exp(score[tok_j], mx);
                    if (tok_j == 7'd127) begin
                        tok_j <= 7'd0; zsum <= 32'sd0; st <= ST_ATT_Z;
                    end else
                        tok_j <= tok_j + 7'd1;
                end
                ST_ATT_Z: begin
                    if (tok_j <= tok_i)
                        zsum <= zsum + 32'(exps[tok_j]);
                    if (tok_j == tok_i) begin
                        if (zsum + 32'(exps[tok_j]) == 0) z_last[hix] <= 32'sd1;
                        else z_last[hix] <= zsum + 32'(exps[tok_j]);
                        for (ii = 0; ii < 128; ii = ii + 1)
                            e_last[hix][ii] <= exps[ii];
                        tok_j <= 7'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0;
                        st <= ST_ATT_O;
                    end else
                        tok_j <= tok_j + 7'd1;
                end
                ST_ATT_O: begin
                    unique case (sub)
                        4'd0: begin
                            aaddr <= aa(ly, 3'd4, tok_j, 7'(hix * 6'd32 + dim[4:0]));
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
                            if (tok_j + 7'd1 > tok_i) begin
                                sub <= 4'd4;
                            end else begin
                                tok_j <= tok_j + 7'd1;
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
                            aaddr <= aa(ly, 3'd5, tok_i, 7'(hix * 6'd32 + dim[4:0]));
                            awd <= 32'(sat16(fd_q));
                            if (tok_i == last_tok(ntok)) begin
                                snap_we <= 1'b1;
                                snap_waddr <= snap_at(ly, 7'(hix * 6'd32 + dim[4:0]));
                                snap_wdata <= sat16(fd_q);
                            end
                            acc <= 64'sd0;
                            tok_j <= 7'd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 9'(DH)) begin
                                dim <= 9'd0;
                                if (hix != 2'd3) begin
                                    hix <= hix + 2'd1; st <= ST_ATT_SC;
                                end else begin
                                    hix <= 2'd0;
                                    if (tok_i + 7'd1 >= ntok) begin
                                        tok_i <= 7'd0;
                                        wbase <= layer_base(ly) + 20'(LO_WO);
                                        ten_o <= 3'd5; nrows <= 11'(D); ncols <= 11'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; st <= ST_MV;
                                    end else begin
                                        tok_i <= tok_i + 7'd1; st <= ST_ATT_SC;
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
                                if (ly) aaddr <= ay(ly - 2'd1, tok_i, dim[6:0]);
                                else aaddr <= aa(2'd0, 3'd0, tok_i, dim[6:0]);
                                aaddr_b <= aa(ly, 3'd2, tok_i, dim[6:0]); // WO result
                            end else begin
                                aaddr <= aa(ly, 3'd6, tok_i, dim[6:0]);
                                aaddr_b <= ay(ly, tok_i, dim[6:0]);
                            end
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        default: begin
                            awe <= 1'b1;
                            if (ten == 3'd0) begin
                                aaddr <= aa(ly, 3'd6, tok_i, dim[6:0]);
                                awd <= 32'(sat16(ard + ard_b));
                            end else begin
                                aaddr <= ay(ly, tok_i, dim[6:0]);
                                awd <= 32'(sat16(ard + ard_b));
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                if (tok_i + 7'd1 >= ntok) begin
                                    tok_i <= 7'd0;
                                    if (ten == 3'd0) begin
                                        ten <= 3'd6; acc <= 64'sd0; st <= ST_LN_S;
                                    end else if (ly != 2'd3) begin
                                        ly <= ly + 2'd1; ten <= 3'd0; acc <= 64'sd0; st <= ST_LN_S;
                                    end else begin
                                        tok_i <= last_tok(ntok);
                                        wbase <= 20'(OFF_HEAD); ten_o <= 3'd7;
                                        nrows <= 11'(V); ncols <= 11'(D); relu <= 1'b0;
                                        row <= 9'd0; col <= 9'd0; acc <= 64'sd0; st <= ST_MV;
                                    end
                                end else
                                    tok_i <= tok_i + 7'd1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_SMX: begin
                    if (vix == 9'd0)
                        mx <= logit_q;
                    if (logit_q > mx) mx <= logit_q;
                    if (vix == 10'd1023) begin
                        vix <= 9'd0; ssoft <= 32'sd0; sub <= 4'd0; st <= ST_ARG;
                    end else
                        vix <= vix + 8'd1;
                end
                ST_ARG: begin
                    unique case (sub)
                        4'd0: begin
                            smx_e[vix] <= relu_exp(logit_q, mx);
                            if (vix == 9'd0) begin
                                arg_best <= 9'd0; arg_v <= logit_q;
                            end else if ((logit_q > arg_v) || (logit_q == arg_v && vix < arg_best)) begin
                                arg_best <= vix; arg_v <= logit_q;
                            end
                            if (vix == 10'd1023) begin
                                vix <= 9'd0; ssoft <= 32'sd0; sub <= 4'd1;
                            end else
                                vix <= vix + 8'd1;
                        end
                        4'd1: begin
                            ssoft <= ssoft + 32'(smx_e[vix]);
                            if (vix == 10'd1023) begin
                                if (ssoft + 32'(smx_e[vix]) == 0) ssoft <= 32'sd1;
                                else ssoft <= ssoft + 32'(smx_e[vix]);
                                pred <= arg_best;
                                last_loss <= 16'((ssoft + 32'(smx_e[vix]) == 0 ? 32'sd1 : ssoft + 32'(smx_e[vix]))
                                    - 32'(smx_e[tgt]));
                                if (train && !after_r) begin
                                    vix <= 9'd0; dim <= 9'd0; sub <= 4'd0; acc <= 64'sd0; st <= ST_BH;
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
                            aaddr <= ay(2'd3, last_tok(ntok), dim[6:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            tmp32 <= ard;
                            vix <= 9'd0;
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
                            waddr <= 20'(OFF_HEAD) + 20'(vix) * 20'(D) + 20'(dim);
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
                            if (vix == 10'd1023 && head_only) begin
                                vix <= 9'd0; acc <= 64'sd0; sub <= 4'd0;
                                if (dim + 9'd1 == 11'(D)) begin
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
                            if (vix == 10'd1023) begin
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
                            dY[dim[6:0]] <= 32'(sat16(fd_q));
                            acc <= 64'sd0;
                            vix <= 9'd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0; col <= 9'd0; ly <= 2'd3; st <= ST_DHID;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_DHID: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= layer_base(ly) + 20'(LO_FF2) + 20'(dim) * 20'(FF) + 20'(col);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(wrd);
                            op_b <= dY[dim[6:0]];
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                snap_raddr <= snap_h(ly, col[7:0]);
                                sub <= 4'd4;
                            end else begin
                                dim <= dim + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        4'd4: sub <= 4'd5;
                        default: begin
                            dHid[col[7:0]] <= (snap_rdata == 16'sd0)
                                ? 32'sd0 : 32'(sat16(acc >>> LIN_SHIFT));
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (col + 9'd1 == 11'(FF)) begin
                                col <= 9'd0; dim <= 9'd0; st <= ST_AFF2;
                            end else
                                col <= col + 9'd1;
                        end
                    endcase
                end
                ST_AFF2: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= layer_base(ly) + 20'(LO_FF2) + 20'(dim) * 20'(FF) + 20'(col);
                            snap_raddr <= snap_h(ly, col[7:0]);
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            dy_r <= dY[dim[6:0]];
                            sub <= 4'd2;
                        end
                        4'd2: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(snap_rdata)) >>> LIN_SHIFT));
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (col + 9'd1 == 11'(FF)) begin
                                col <= 9'd0;
                                if (dim + 9'd1 == 11'(D)) begin
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
                            waddr <= layer_base(ly) + 20'(LO_FF1) + 20'(col) * 20'(D) + 20'(dim);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            op_a <= 32'(wrd);
                            op_b <= dHid[col[7:0]];
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            acc <= acc + 64'(op_a) * 64'(op_b);
                            if (col + 9'd1 == 11'(FF)) begin
                                col <= 9'd0;
                                sub <= 4'd4;
                            end else begin
                                col <= col + 9'd1;
                                sub <= 4'd0;
                            end
                        end
                        default: begin
                            dH[dim[6:0]] <= 32'(sat16(dY[dim[6:0]] + 32'(sat16(sat32(acc >>> LIN_SHIFT)))));
                            acc <= 64'sd0;
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0; col <= 9'd0; st <= ST_AFF1;
                            end else
                                dim <= dim + 9'd1;
                        end
                    endcase
                end
                ST_AFF1: begin
                    unique case (sub)
                        4'd0: begin
                            waddr <= layer_base(ly) + 20'(LO_FF1) + 20'(col) * 20'(D) + 20'(dim);
                            snap_raddr <= snap_n2(ly, dim[6:0]);
                            sub <= 4'd1;
                        end
                        4'd1: begin
                            dy_r <= dHid[col[7:0]];
                            sub <= 4'd2;
                        end
                        4'd2: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(snap_rdata)) >>> LIN_SHIFT));
                            sub <= 4'd3;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
                                dim <= 9'd0;
                                if (col + 9'd1 == 11'(FF)) begin
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
                            if (ten == 3'd0) aaddr <= aa(ly, 3'd5, last_tok(ntok), col[6:0]);
                            else aaddr <= aa(ly, 3'd1, last_tok(ntok), col[6:0]);
                            unique case (ten)
                                3'd0: waddr <= layer_base(ly) + 20'(LO_WO) + 20'(row) * 20'(D) + 20'(col);
                                3'd1: waddr <= layer_base(ly) + 20'(LO_WQ) + 20'(row) * 20'(D) + 20'(col);
                                3'd2: waddr <= layer_base(ly) + 20'(LO_WK) + 20'(row) * 20'(D) + 20'(col);
                                default: waddr <= layer_base(ly) + 20'(LO_WV) + 20'(row) * 20'(D) + 20'(col);
                            endcase
                            snap_raddr <= (ten == 3'd0)
                                ? snap_at(ly, col[6:0]) : snap_n1(ly, col[6:0]);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            x_r <= 32'(snap_rdata);
                            dy_r <= dH[row[6:0]];
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            gtmp <= sat16(32'((64'(dy_r) * 64'(x_r)) >>> LIN_SHIFT));
                            sub <= 4'd4;
                        end
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(gtmp)));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (col + 9'd1 == 11'(D)) begin
                                col <= 9'd0;
                                if (row + 9'd1 == 11'(D)) begin
                                    row <= 9'd0;
                                    if (ten == 3'd3) begin
                                        for (ii = 0; ii < 128; ii = ii + 1)
                                            dY[ii] <= dH[ii];
                                        if (ly != 2'd0) begin
                                            ly <= ly - 2'd1; col <= 9'd0; dim <= 9'd0; acc <= 64'sd0; st <= ST_DHID;
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
                            waddr <= 20'(OFF_TOK) + 20'(tok[last_tok(ntok)]) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_TOK);
                            sub <= 4'd1;
                        end
                        4'd1: sub <= 4'd2;
                        4'd2: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(sat16(dY[dim[6:0]]))));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd3;
                        end
                        4'd3: begin
                            waddr <= 20'(OFF_POS) + 20'(last_tok(ntok)) * 20'(D) + 20'(dim);
                            caddr <= 20'(OFF_POS);
                            sub <= 4'd4;
                        end
                        4'd4: sub <= 4'd5;
                        default: begin
                            if (!after_r) begin
                                wwe <= 1'b1;
                                wwd <= sat8(32'(wrd) - 32'(step_sign(sat16(dY[dim[6:0]]))));
                                wr_n <= wr_n + 32'd1;
                            end
                            sub <= 4'd0;
                            if (dim + 9'd1 == 11'(D)) begin
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
                            if (caddr + 20'd1 >= 20'(NPARAM)) st <= ST_DONE;
                            else caddr <= caddr + 20'd1;
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
                            if (caddr + 20'd1 >= 20'(NPARAM)) st <= ST_DONE;
                            else begin
                                caddr <= caddr + 20'd1;
                                waddr <= caddr + 20'd1;
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
                            if (caddr + 20'd1 >= 20'(NPARAM)) st <= ST_DONE;
                            else caddr <= caddr + 20'd1;
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
