`timescale 1ns/1ps
import a7eam03e_pkg::*;
// 03E-A0.3 encoder. No 01R / no LM-06. Law eam03e-a03-signed-h-v1.
//
// Byte-identical to eam03e_core.sv (law eam03e-a0-signsgd-v1) except for the
// signedness of the state update, see S_HWR. Contract:
// docs/contracts/A7-EAM-03E-A03.md. Golden bag pre-registered in
// results/A7-EAM-03E/A03_SIGNED/golden_a03_predicted.json before this file
// existed; this module must reproduce it, and the table is not editable.
//
// The A0.1-T integers 3930/5362/1093/2012/3930/451/1574 belong to the parent
// law and are not this module's authority.
module eam03e_a03_core (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start_seed,
    input  logic         start_pair,
    input  logic         start_enc,
    input  logic [31:0]  seed_in,
    input  logic         learn,
    input  logic         freeze,
    input  logic         label_same,
    input  logic         enc_slot,
    input  logic [7:0]   nA,
    input  logic [7:0]   nB,
    input  logic [7:0]   seqA [0:E3_TMAX-1],
    input  logic [7:0]   seqB [0:E3_TMAX-1],
    output logic         idle,
    output logic         result_valid,
    output logic         updated,
    output logic [6:0]   dH,
    output logic [15:0]  d1,
    output logic [63:0]  cue,
    output logic [31:0]  seed_used
);
    typedef enum logic [4:0] {
        S_IDLE, S_SEED,
        S_TINIT, S_EISS, S_ELAT,
        S_WISS, S_WMUL, S_WADD,
        S_HWR, S_PCLR, S_PACC,
        S_NEXT, S_DIST, S_DADD, S_GRAD,
        S_EISS2, S_ELAT2, S_EUPD,
        S_WISS2, S_WLAT2, S_WUPD,
        S_HOLD, S_OUT
    } st_t;

    st_t st;
    logic [31:0] lfsr, seed_r;
    logic [13:0] sa;
    logic [5:0]  t, ncur;
    logic [5:0]  nA_r, nB_r, ntp [0:1];
    logic [4:0]  i, j;
    logic        which, do_upd, same_r, enc_only;
    logic [7:0]  bcur, btape [0:1][0:E3_TMAX-1];

    (* ram_style = "block" *) logic signed [7:0] E  [0:8191];
    (* ram_style = "block" *) logic signed [7:0] Wh [0:1023];
    logic [31:0] Prow [0:63];

    logic signed [7:0]  e_q, wh_q, e_lat [0:31];
    logic [12:0] e_ra, e_wa;
    logic [9:0]  wh_ra, wh_wa;
    logic        e_we, wh_we;
    logic signed [7:0] e_wd, wh_wd;

    logic signed [15:0] h [0:31], hprev [0:31];
    logic signed [15:0] hA [0:31], hB [0:31];
    logic signed [15:0] gA [0:31], gB [0:31];
    logic signed [31:0] acc [0:31];
    logic signed [31:0] psum;
    (* use_dsp = "no" *) logic signed [23:0] prod_r;
    logic signed [15:0] gsel_r, hprev_j_r;
    logic signed [7:0]  sgn_r, wdelta_r;
    logic        wdo_r;
    logic [5:0]  pk;
    logic [63:0] cueA, cueB, cue_r;
    logic [15:0] d1_acc;
    logic [6:0]  dH_acc;
    logic [15:0] ad;
    logic [6:0]  pbi;

    integer k;

    always_ff @(posedge clk) begin
        e_q  <= E[e_ra];
        wh_q <= Wh[wh_ra];
        if (e_we)  E[e_wa]   <= e_wd;
        if (wh_we) Wh[wh_wa] <= wh_wd;
    end

    assign idle = (st == S_IDLE);
    assign seed_used = seed_r;

    function automatic logic [7:0] sbyte(input logic w, input logic [5:0] tt);
        return w ? seqB[tt] : seqA[tt];
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            result_valid <= 1'b0;
            updated <= 1'b0;
            dH <= 7'd64;
            d1 <= 16'd0;
            cue <= 64'd0;
            d1_acc <= 16'd0;
            dH_acc <= 7'd0;
            for (k = 0; k < 32; k++) begin
                h[k] <= 16'sd0;
                hA[k] <= 16'sd0;
                hB[k] <= 16'sd0;
                gA[k] <= 16'sd0;
                gB[k] <= 16'sd0;
            end
            seed_r <= E3_SEED0;
            lfsr <= E3_SEED0;
            e_we <= 1'b0;
            wh_we <= 1'b0;
            do_upd <= 1'b0;
            enc_only <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            e_we <= 1'b0;
            wh_we <= 1'b0;
            unique case (st)
                S_IDLE: begin
                    if (start_seed) begin
                        seed_r <= (seed_in == 32'd0) ? E3_SEED0 : seed_in;
                        lfsr <= (seed_in == 32'd0) ? E3_SEED0 : seed_in;
                        sa <= 14'd0;
                        st <= S_SEED;
                    end else if (start_pair || start_enc) begin
                        enc_only <= start_enc;
                        same_r <= label_same;
                        do_upd <= start_pair && learn && !freeze;
                        nA_r <= (nA > 8'(E3_TMAX)) ? 6'(E3_TMAX) : nA[5:0];
                        nB_r <= (nB > 8'(E3_TMAX)) ? 6'(E3_TMAX) : nB[5:0];
                        which <= start_enc ? enc_slot : 1'b0;
                        st <= S_TINIT;
                    end
                end

                S_SEED: begin
                    lfsr <= e3_xorshift(lfsr);
                    if (sa < 14'd8192) begin
                        e_wa <= sa[12:0];
                        e_wd <= signed'(lfsr[7:0]);
                        e_we <= 1'b1;
                    end else if (sa < 14'd9216) begin
                        wh_wa <= sa[9:0];
                        wh_wd <= signed'(lfsr[15:8]);
                        wh_we <= 1'b1;
                    end else
                        Prow[sa[5:0]] <= e3_xorshift(lfsr);
                    if (sa == 14'd9279)
                        st <= S_HOLD;
                    else
                        sa <= sa + 14'd1;
                end

                S_TINIT: begin
                    ncur <= which ? nB_r : nA_r;
                    t <= 6'd0;
                    j <= 5'd0;
                    i <= 5'd0;
                    for (k = 0; k < 32; k++) begin
                        h[k] <= 16'sd0;
                        hprev[k] <= 16'sd0;
                    end
                    if ((which ? nB_r : nA_r) == 6'd0) begin
                        cue_r <= 64'd0;
                        for (k = 0; k < 32; k++) begin
                            if (which) hB[k] <= 16'sd0;
                            else hA[k] <= 16'sd0;
                        end
                        if (which) begin
                            d1_acc <= 16'd0;
                            dH_acc <= 7'd0;
                            i <= 5'd0;
                            pbi <= 7'd0;
                        end
                        st <= enc_only ? S_HOLD : (which ? S_DIST : S_NEXT);
                    end else
                        st <= S_EISS;
                end

                S_EISS: begin
                    bcur <= sbyte(which, t);
                    e_ra <= {sbyte(which, t), 5'd0};
                    j <= 5'd0;
                    st <= S_ELAT;
                end

                S_ELAT: begin
                    e_lat[j] <= e_q;
                    if (j == 5'd31) begin
                        j <= 5'd0;
                        i <= 5'd0;
                        for (k = 0; k < 32; k++)
                            acc[k] <= 32'sd0;
                        wh_ra <= 10'd0;
                        st <= S_WISS;
                    end else begin
                        j <= j + 5'd1;
                        e_ra <= {bcur, j + 5'd1};
                    end
                end

                S_WISS: st <= S_WMUL;

                S_WMUL: begin
                    prod_r <= $signed(wh_q) * $signed(h[j]);
                    st <= S_WADD;
                end

                S_WADD: begin
                    acc[i] <= acc[i] + 32'(prod_r);
                    if (j == 5'd31) begin
                        j <= 5'd0;
                        if (i == 5'd31)
                            st <= S_HWR;
                        else begin
                            i <= i + 5'd1;
                            wh_ra <= {i + 5'd1, 5'd0};
                            st <= S_WISS;
                        end
                    end else begin
                        j <= j + 5'd1;
                        wh_ra <= {i, j + 5'd1};
                        st <= S_WISS;
                    end
                end

                S_HWR: begin
                    for (k = 0; k < 32; k++)
                        hprev[k] <= h[k];
                    for (k = 0; k < 32; k++)
                        h[k] <= e3_sat16(($signed({{8{e_lat[k][7]}}, e_lat[k], 8'd0})
                                          + acc[k]) >>> E3_SH);
                    btape[which][t] <= bcur;
                    ntp[which] <= ncur;
                    if (t + 6'd1 == ncur)
                        st <= S_PCLR;
                    else begin
                        t <= t + 6'd1;
                        st <= S_EISS;
                    end
                end

                S_PCLR: begin
                    for (k = 0; k < 32; k++) begin
                        if (which) hB[k] <= h[k];
                        else       hA[k] <= h[k];
                    end
                    pk <= 6'd0;
                    j <= 5'd0;
                    psum <= 32'sd0;
                    st <= S_PACC;
                end

                S_PACC: begin
                    if (Prow[pk][j])
                        psum <= psum + {{16{h[j][15]}}, h[j]};
                    else
                        psum <= psum - {{16{h[j][15]}}, h[j]};
                    if (j == 5'd31) begin
                        cue_r[pk] <= ((Prow[pk][j] ? (psum + {{16{h[j][15]}}, h[j]})
                                                    : (psum - {{16{h[j][15]}}, h[j]})) > 32'sd0);
                        j <= 5'd0;
                        psum <= 32'sd0;
                        if (pk == 6'd63)
                            st <= enc_only ? S_HOLD : S_NEXT;
                        else
                            pk <= pk + 6'd1;
                    end else
                        j <= j + 5'd1;
                end

                S_NEXT: begin
                    if (!which) begin
                        cueA <= cue_r;
                        which <= 1'b1;
                        st <= S_TINIT;
                    end else begin
                        cueB <= cue_r;
                        d1_acc <= 16'd0;
                        dH_acc <= 7'd0;
                        i <= 5'd0;
                        pbi <= 7'd0;
                        st <= S_DIST;
                    end
                end

                S_DIST: begin
                    ad <= e3_abs16(hA[i] - hB[i]) >> 5;
                    st <= S_DADD;
                end

                S_DADD: begin
                    d1_acc <= (d1_acc > 16'hFFFF - ad) ? 16'hFFFF : (d1_acc + ad);
                    if (i == 5'd31)
                        st <= S_GRAD;
                    else begin
                        i <= i + 5'd1;
                        st <= S_DIST;
                    end
                end

                S_GRAD: begin
                    if (pbi < 7'd64) begin
                        dH_acc <= dH_acc + {6'd0, cueA[pbi[5:0]] ^ cueB[pbi[5:0]]};
                        pbi <= pbi + 7'd1;
                    end else begin
                        for (k = 0; k < 32; k++) begin
                            if (same_r) begin
                                gA[k] <= hA[k] - hB[k];
                                gB[k] <= hB[k] - hA[k];
                            end else if (d1_acc < E3_MARG[15:0]) begin
                                gA[k] <= hB[k] - hA[k];
                                gB[k] <= hA[k] - hB[k];
                            end else begin
                                gA[k] <= 16'sd0;
                                gB[k] <= 16'sd0;
                            end
                        end
                        if (!do_upd)
                            st <= S_HOLD;
                        else begin
                            which <= 1'b0;
                            t <= 6'd0;
                            i <= 5'd0;
                            st <= S_EISS2;
                        end
                    end
                end

                S_EISS2: begin
                    bcur <= btape[which][t];
                    e_ra <= {btape[which][t], i};
                    st <= S_ELAT2;
                end

                S_ELAT2: begin
                    gsel_r <= which ? gB[i] : gA[i];
                    sgn_r  <= e3_sgn8(which ? gB[i] : gA[i]);
                    st <= S_EUPD;
                end

                S_EUPD: begin
                    e_wa <= {bcur, i};
                    e_wd <= e3_sat8($signed({e_q[7], e_q}) -
                                    $signed({sgn_r[7], sgn_r}));
                    e_we <= (sgn_r != 8'sd0);
                    if (i == 5'd31) begin
                        i <= 5'd0;
                        if (t + 6'd1 == ntp[which]) begin
                            if (!which) begin
                                which <= 1'b1;
                                t <= 6'd0;
                                st <= S_EISS2;
                            end else begin
                                i <= 5'd0;
                                j <= 5'd0;
                                wh_ra <= 10'd0;
                                st <= S_WISS2;
                            end
                        end else begin
                            t <= t + 6'd1;
                            st <= S_EISS2;
                        end
                    end else begin
                        i <= i + 5'd1;
                        st <= S_EISS2;
                    end
                end

                S_WISS2: st <= S_WLAT2;
                S_WLAT2: begin
                    gsel_r    <= gB[i];
                    hprev_j_r <= hprev[j];
                    wdo_r     <= !(e3_sgn8(gB[i]) == 8'sd0 || hprev[j] == 16'sd0);
                    wdelta_r  <= (gB[i][15] == hprev[j][15]) ? 8'sd1 : -8'sd1;
                    st <= S_WUPD;
                end

                S_WUPD: begin
                    wh_wa <= {i, j};
                    wh_wd <= e3_sat8(16'(wh_q) - (wdo_r ? 16'(wdelta_r) : 16'sd0));
                    wh_we <= wdo_r;
                    if (j == 5'd31) begin
                        j <= 5'd0;
                        if (i == 5'd31)
                            st <= S_HOLD;
                        else begin
                            i <= i + 5'd1;
                            wh_ra <= {i + 5'd1, 5'd0};
                            st <= S_WISS2;
                        end
                    end else begin
                        j <= j + 5'd1;
                        wh_ra <= {i, j + 5'd1};
                        st <= S_WISS2;
                    end
                end

                S_HOLD: begin
                    dH <= enc_only ? 7'd0 : dH_acc;
                    d1 <= enc_only ? 16'd0 : d1_acc;
                    cue <= cue_r;
                    updated <= do_upd && !enc_only;
                    st <= S_OUT;
                end

                S_OUT: begin
                    result_valid <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
