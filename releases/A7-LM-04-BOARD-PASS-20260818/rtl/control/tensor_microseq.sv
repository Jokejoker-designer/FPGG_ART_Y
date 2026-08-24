`timescale 1ns/1ps
module tensor_microseq (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               start,
    input  logic [2:0]         cmd,
    input  logic               in_mode,
    input  logic [3:0]         in_m,
    input  logic [7:0]         in_n,
    input  logic [15:0]        in_k,
    input  logic [31:0]        in_seed,
    input  logic [15:0]        in_count,
    input  logic [15:0]        in_idx,
    input  logic [3:0]         rq_shift,
    output logic               busy,
    output logic               done,
    output logic               pass,
    output logic [7:0]         phase,
    output logic [31:0]        xor32,
    output logic [31:0]        add32,
    output logic [31:0]        macs,
    output logic [31:0]        cycles,
    output logic [31:0]        stalls,
    output logic [31:0]        hazards,
    output logic [31:0]        dma_unders,
    output logic [31:0]        bank_hazards,
    output logic [15:0]        axi_berrs,
    output logic [15:0]        axi_rerrs,
    output logic [15:0]        swaps,
    output logic [31:0]        overlap_cyc,
    output logic [15:0]        ntile_out,
    output logic [31:0]        cases_done,
    output logic signed [31:0] psum_rd,
    input  logic [6:0]         psum_idx,
    output logic               wr_bank,
    output logic               rd_bank,
    output logic               w_wr_en,
    output logic [7:0]         w_wr_k,
    output logic [2:0]         w_wr_chunk,
    output logic [127:0]       w_wr_data,
    output logic [7:0]         w_rd_k,
    input  logic [1023:0]      w_rd_data,
    output logic               a_wr_en,
    output logic [7:0]         a_wr_k,
    output logic [127:0]       a_wr_data,
    output logic [7:0]         a_rd_k,
    input  logic [127:0]       a_rd_data,
    output logic               mac_clr,
    output logic               mac_en,
    output logic signed [15:0] mac_a [0:127],
    output logic signed [7:0]  mac_b [0:127],
    input  logic signed [47:0] mac_acc [0:127],
    output logic               gemv_start,
    output logic               gemm_start,
    output logic               acc_cont,
    output logic [8:0]         k_len,
    input  logic               gemv_done,
    input  logic               gemm_done,
    input  logic               gemv_en,
    input  logic               gemm_en,
    input  logic               gemv_clr,
    input  logic               gemm_clr,
    input  logic [7:0]         gemv_k,
    input  logic [7:0]         gemm_k,
    input  logic signed [15:0] gemv_a [0:127],
    input  logic signed [7:0]  gemv_b [0:127],
    input  logic signed [15:0] gemm_a [0:127],
    input  logic signed [7:0]  gemm_b [0:127],
    output logic               dma_go,
    output logic               dma_wr,
    output logic [27:0]        dma_addr,
    output logic [31:0]        dma_bytes,
    input  logic               dma_busy,
    input  logic               dma_done,
    input  logic               dma_under,
    input  logic               axi_berr,
    input  logic               axi_rerr,
    output logic               dma_w_valid,
    input  logic               dma_w_ready,
    output logic [127:0]       dma_w_data,
    input  logic               dma_r_valid,
    output logic               dma_r_ready,
    input  logic [127:0]       dma_r_data
);
    typedef enum logic [4:0] {
        ST_IDLE, ST_DEC, ST_FILL, ST_WAITF, ST_GO, ST_WAITC,
        ST_CAP, ST_FOLD, ST_ACCUM, ST_NEXT, ST_RQ,
        ST_DDRW, ST_DDRR, ST_DUMP, ST_PREFILL_NXT, ST_FETCH, ST_DONE
    } st_t;
    st_t st;
    logic mode, corner, satc, fill_go, fill_done, fill_busy;
    logic [3:0]  M;
    logic [7:0]  N;
    logic [15:0] K;
    logic [8:0]  Ktile, Knext, fill_Ksel;
    logic [31:0] seed0, i_case, ncase, sdec;
    logic [31:0] case_xor, case_add;
    logic [8:0]  fi;
    logic [3:0]  fm;
    logic [7:0]  fn;
    logic signed [31:0] pmem [0:127];
    logic [15:0] tile, ntile, k_base;
    logic [7:0]  seqb;
    logic        dma_kick;
    logic        ddr_roof, pp_ddr, prefill, prefetch, dump_act, comp_latched;
    logic [10:0] dbeat;
    logic        fill_w_wr_en, fill_a_wr_en;
    logic [7:0]  fill_w_wr_k, fill_a_wr_k;
    logic [2:0]  fill_w_wr_chunk;
    logic [127:0] fill_w_wr_data, fill_a_wr_data;
    logic        ddr_w_wr_en;
    logic [1:0]  fill_kind;
    logic        wr_b, rd_b;
    logic [7:0]  dump_k;
    logic [2:0]  dump_ch;
    // Two-cycle prime for the synchronous ping/pong BRAM read port.
    // Cycle 1 presents dump_k=0; cycle 2 captures the resulting row.
    logic [1:0]  dump_hold;
    logic [1023:0] row_q;
    integer li;
    // Per-bank generation tags. Cleared on every new command so a leftover
    // third tile after ntile 2→3 cannot be computed. Compute only if
    // valid && command_id_match && tile_index_match.
    logic [1:0]  bank_valid;
    logic [7:0]  bank_cmd [0:1];
    logic [15:0] bank_tile [0:1];
    logic [7:0]  cmd_id;
    logic [15:0] last_ntile;
    logic        force_w;
    logic        grow_tiles;
    logic        rd_ok;

    function automatic [31:0] xs32(input [31:0] x);
        logic [31:0] s;
        begin
            s = x;
            s = s ^ (s << 13);
            s = s ^ (s >> 17);
            s = s ^ (s << 5);
            return s;
        end
    endfunction

    function automatic signed [31:0] sat32(input signed [47:0] x);
        begin
            if (x > 48'sd2147483647) return 32'sd2147483647;
            else if (x < -48'sd2147483648) return -32'sd2147483648;
            else return x[31:0];
        end
    endfunction

    function automatic [15:0] ktab(input [3:0] s);
        case (s)
            0: return 16'd1;   1: return 16'd7;   2: return 16'd16;
            3: return 16'd32;  4: return 16'd63;  5: return 16'd64;
            6: return 16'd127; 7: return 16'd128; 8: return 16'd129;
            9: return 16'd192; 10: return 16'd255; 11: return 16'd256;
            12: return 16'd8;  13: return 16'd24; 14: return 16'd48; default: return 16'd96;
        endcase
    endfunction

    function automatic [7:0] ngev(input [2:0] s);
        case (s)
            0: return 8'd1;  1: return 8'd15; 2: return 8'd16; 3: return 8'd17;
            4: return 8'd64; 5: return 8'd100; 6: return 8'd127; default: return 8'd128;
        endcase
    endfunction

    function automatic [3:0] mgem(input [1:0] s);
        case (s)
            0: return 4'd1; 1: return 4'd3; 2: return 4'd7; default: return 4'd8;
        endcase
    endfunction

    function automatic [7:0] ngem(input [1:0] s);
        case (s)
            0: return 8'd1; 1: return 8'd8; 2: return 8'd15; default: return 8'd16;
        endcase
    endfunction

    function automatic [15:0] tiles_of(input [15:0] kk);
        logic [15:0] t;
        begin
            t = (kk + 16'd255) >> 8;
            return (t == 16'd0) ? 16'd1 : t;
        end
    endfunction

    function automatic [8:0] tile_len(input [15:0] t, input [15:0] nt, input [15:0] kk);
        begin
            if (t + 16'd1 < nt) return 9'd256;
            else return kk[8:0] - {t[7:0], 8'd0};
        end
    endfunction

    prbs_tile_fill u_fill (
        .clk(clk), .rst_n(rst_n), .start(fill_go),
        .mode(mode), .M(M), .N(N), .K(fill_Ksel),
        .k_base(k_base), .kind(fill_kind),
        .seed0(seed0), .i_case(i_case), .corner(corner), .satc(satc),
        .busy(fill_busy), .done(fill_done),
        .w_wr_en(fill_w_wr_en), .w_wr_k(fill_w_wr_k), .w_wr_chunk(fill_w_wr_chunk), .w_wr_data(fill_w_wr_data),
        .a_wr_en(fill_a_wr_en), .a_wr_k(fill_a_wr_k), .a_wr_data(fill_a_wr_data)
    );

    assign ddr_w_wr_en = (st == ST_FETCH || st == ST_WAITC) && dma_r_valid && !ddr_roof;
    assign w_wr_en = ddr_w_wr_en | fill_w_wr_en;
    assign w_wr_k = ddr_w_wr_en ? dbeat[10:3] : fill_w_wr_k;
    assign w_wr_chunk = ddr_w_wr_en ? dbeat[2:0] : fill_w_wr_chunk;
    assign w_wr_data = ddr_w_wr_en ? dma_r_data : fill_w_wr_data;
    assign a_wr_en = fill_a_wr_en;
    assign a_wr_k = fill_a_wr_k;
    assign a_wr_data = fill_a_wr_data;

    assign busy = (st != ST_IDLE) && (st != ST_DONE);
    assign phase = {3'd0, st};
    assign wr_bank = wr_b;
    assign rd_bank = dump_act ? wr_b : rd_b;
    assign mac_clr = gemv_clr | gemm_clr;
    assign mac_en  = gemv_en  | gemm_en;
    assign w_rd_k = dump_act ? dump_k : (mode ? gemm_k : gemv_k);
    assign a_rd_k = mode ? gemm_k : gemv_k;
    assign psum_rd = pmem[psum_idx];
    assign dma_r_ready = (st == ST_DDRR) || (st == ST_FETCH) || (st == ST_WAITC && prefetch && !dma_wr);
    assign dma_w_valid = dump_act ? ((dump_hold == 2'd0) && dma_busy) : ((st == ST_DDRW) && dma_busy);
    assign dma_w_data = dump_act ? row_q[{dump_ch, 7'd0} +: 128] : {8{seqb}};
    assign k_len = Ktile;
    assign ntile_out = ntile;
    assign fill_Ksel = (prefetch && fill_kind == 2'd1) ? Knext : Ktile;
    assign rd_ok = bank_valid[rd_b]
                && (bank_cmd[rd_b] == cmd_id)
                && (bank_tile[rd_b] == tile);

    always_comb begin
        for (li = 0; li < 128; li = li + 1) begin
            mac_a[li] = mode ? gemm_a[li] : gemv_a[li];
            mac_b[li] = mode ? gemm_b[li] : gemv_b[li];
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= ST_IDLE;
            done <= 1'b0;
            pass <= 1'b0;
            xor32 <= 32'd0;
            add32 <= 32'd0;
            macs <= 32'd0;
            cycles <= 32'd0;
            stalls <= 32'd0;
            hazards <= 32'd0;
            dma_unders <= 32'd0;
            bank_hazards <= 32'd0;
            axi_berrs <= 16'd0;
            axi_rerrs <= 16'd0;
            swaps <= 16'd0;
            overlap_cyc <= 32'd0;
            cases_done <= 32'd0;
            gemv_start <= 1'b0;
            gemm_start <= 1'b0;
            acc_cont <= 1'b0;
            fill_go <= 1'b0;
            dma_go <= 1'b0;
            dma_wr <= 1'b0;
            dma_addr <= 28'd0;
            dma_bytes <= 32'd0;
            mode <= 1'b0;
            M <= 4'd1;
            N <= 8'd1;
            K <= 16'd1;
            Ktile <= 9'd1;
            seed0 <= 32'd0;
            i_case <= 32'd0;
            ncase <= 32'd1;
            tile <= 16'd0;
            ntile <= 16'd1;
            k_base <= 16'd0;
            seqb <= 8'd0;
            dma_kick <= 1'b0;
            ddr_roof <= 1'b0;
            pp_ddr <= 1'b0;
            prefill <= 1'b0;
            prefetch <= 1'b0;
            dump_act <= 1'b0;
            comp_latched <= 1'b0;
            dump_hold <= 2'd0;
            dbeat <= 11'd0;
            fill_kind <= 2'd0;
            wr_b <= 1'b0;
            rd_b <= 1'b0;
            dump_k <= 8'd0;
            dump_ch <= 3'd0;
            bank_valid <= 2'b00;
            bank_cmd[0] <= 8'd0;
            bank_cmd[1] <= 8'd0;
            bank_tile[0] <= 16'd0;
            bank_tile[1] <= 16'd0;
            cmd_id <= 8'd0;
            last_ntile <= 16'd0;
            force_w <= 1'b0;
            grow_tiles <= 1'b0;
        end else begin
            done <= 1'b0;
            gemv_start <= 1'b0;
            gemm_start <= 1'b0;
            fill_go <= 1'b0;
            dma_go <= 1'b0;
            if (busy) cycles <= cycles + 32'd1;
            if (mac_en) stalls <= stalls + 32'd1;
            if (dma_under) dma_unders <= dma_unders + 32'd1;
            if (axi_berr) axi_berrs <= axi_berrs + 16'd1;
            if (axi_rerr) axi_rerrs <= axi_rerrs + 16'd1;
            if (w_wr_en && (wr_b == rd_b) && (gemv_en || gemm_en || (st == ST_WAITC)))
                bank_hazards <= bank_hazards + 32'd1;
            if (mac_en && (dma_busy || fill_busy))
                overlap_cyc <= overlap_cyc + 32'd1;
            unique case (st)
                ST_IDLE: if (start) begin
                    xor32 <= 32'd0;
                    add32 <= 32'd0;
                    macs <= 32'd0;
                    cycles <= 32'd0;
                    stalls <= 32'd0;
                    hazards <= 32'd0;
                    dma_unders <= 32'd0;
                    bank_hazards <= 32'd0;
                    axi_berrs <= 16'd0;
                    axi_rerrs <= 16'd0;
                    swaps <= 16'd0;
                    overlap_cyc <= 32'd0;
                    cases_done <= 32'd0;
                    seed0 <= in_seed;
                    i_case <= 32'd0;
                    pass <= 1'b0;
                    acc_cont <= 1'b0;
                    tile <= 16'd0;
                    wr_b <= 1'b0;
                    rd_b <= 1'b0;
                    prefetch <= 1'b0;
                    dump_act <= 1'b0;
                    comp_latched <= 1'b0;
                    dma_kick <= 1'b0;
                    dbeat <= 11'd0;
                    force_w <= 1'b0;
                    cmd_id <= cmd_id + 8'd1;
                    bank_valid <= 2'b00;
                    grow_tiles <= 1'b0;
                    ncase <= (cmd == 3'd1) ? {16'd0, in_count} : 32'd1;
                    if (cmd == 3'd2) begin
                        mode <= 1'b0; M <= 4'd1; N <= 8'd128; K <= 16'd256;
                        corner <= 1'b0; satc <= 1'b0;
                        ntile <= 16'd1;
                        Ktile <= 9'd256;
                        k_base <= 16'd0;
                        fill_kind <= 2'd0;
                        seqb <= 8'd0;
                        ddr_roof <= 1'b1;
                        pp_ddr <= 1'b0;
                        prefill <= 1'b0;
                        seed0 <= (in_seed == 32'd0) ? 32'hC0FFEE00 : in_seed;
                        st <= ST_FILL;
                    end else if (cmd == 3'd3) begin
                        mode <= 1'b1; M <= 4'd8; N <= 8'd16; K <= 16'd256;
                        corner <= 1'b0; satc <= 1'b0;
                        Ktile <= 9'd256;
                        ntile <= 16'd1;
                        k_base <= 16'd0;
                        fill_kind <= 2'd0;
                        ddr_roof <= 1'b0;
                        pp_ddr <= 1'b0;
                        prefill <= 1'b0;
                        st <= ST_FILL;
                    end else if (cmd == 3'd4) begin
                        fi <= 9'd0;
                        xor32 <= 32'd0;
                        add32 <= 32'd0;
                        st <= ST_RQ;
                    end else if (cmd == 3'd5) begin
                        mode <= 1'b0; M <= 4'd1; N <= 8'd128;
                        K <= (in_k == 16'd0) ? 16'd513 : in_k;
                        corner <= 1'b0; satc <= 1'b0;
                        i_case <= {16'd0, in_idx};
                        seed0 <= (in_seed == 32'd0) ? 32'hC0FFEE00 : in_seed;
                        ntile <= tiles_of((in_k == 16'd0) ? 16'd513 : in_k);
                        tile <= 16'd0;
                        k_base <= 16'd0;
                        Ktile <= tile_len(16'd0, tiles_of((in_k == 16'd0) ? 16'd513 : in_k),
                                          (in_k == 16'd0) ? 16'd513 : in_k);
                        fill_kind <= 2'd1;
                        wr_b <= 1'b0;
                        rd_b <= 1'b0;
                        ddr_roof <= 1'b0;
                        pp_ddr <= 1'b1;
                        prefill <= 1'b1;
                        grow_tiles <= (tiles_of((in_k == 16'd0) ? 16'd513 : in_k) > last_ntile);
                        st <= ST_FILL;
                    end else if (cmd == 3'd0) begin
                        logic [31:0] s0, s1, s2;
                        mode <= in_mode; M <= in_m; N <= in_n; K <= in_k;
                        i_case <= {16'd0, in_idx};
                        s0 = xs32(in_seed + {16'd0, in_idx});
                        s1 = xs32(s0);
                        s2 = xs32(s1);
                        corner <= (s2[4:0] == 5'd0);
                        satc   <= (s2[4:0] == 5'd1);
                        ntile <= tiles_of(in_k);
                        Ktile <= tile_len(16'd0, tiles_of(in_k), in_k);
                        k_base <= 16'd0;
                        fill_kind <= 2'd0;
                        ddr_roof <= 1'b0;
                        pp_ddr <= 1'b0;
                        prefill <= 1'b0;
                        st <= ST_FILL;
                    end else begin
                        ddr_roof <= 1'b0;
                        pp_ddr <= 1'b0;
                        st <= ST_DEC;
                    end
                end
                ST_DEC: begin
                    sdec <= xs32(seed0 + i_case);
                    mode <= (xs32(seed0 + i_case)[1:0] == 2'b11);
                    begin
                        logic [31:0] s0, s1, s2;
                        s0 = xs32(seed0 + i_case);
                        s1 = xs32(s0);
                        s2 = xs32(s1);
                        K <= ktab(s1[3:0]);
                        if (s0[1:0] != 2'b11) begin
                            M <= 4'd1;
                            N <= ngev(s2[2:0]);
                        end else begin
                            M <= mgem(s2[1:0]);
                            N <= ngem(s2[5:4]);
                        end
                        corner <= (s2[4:0] == 5'd0);
                        satc   <= (s2[4:0] == 5'd1);
                        ntile <= 16'd1;
                        Ktile <= ktab(s1[3:0])[8:0];
                        k_base <= 16'd0;
                        fill_kind <= 2'd0;
                        tile <= 16'd0;
                        wr_b <= 1'b0;
                        rd_b <= 1'b0;
                        acc_cont <= 1'b0;
                    end
                    st <= ST_FILL;
                end
                ST_FILL: begin
                    fill_go <= 1'b1;
                    st <= ST_WAITF;
                end
                ST_WAITF: if (fill_done) begin
                    if (fill_kind != 2'd2) begin
                        bank_valid[wr_b] <= 1'b1;
                        bank_cmd[wr_b] <= cmd_id;
                        bank_tile[wr_b] <= tile;
                    end
                    if (pp_ddr && prefill)
                        st <= ST_DUMP;
                    else
                        st <= ddr_roof ? ST_DDRW : ST_GO;
                end
                ST_GO: begin
                    if (pp_ddr && (!rd_ok || (grow_tiles && (tile >= last_ntile) && (bank_tile[rd_b] != tile)))) begin
                        // ntile grew (2→3) or bank still holds another command/tile.
                        // DMA-fill this tile before compute. Do not use leftover rows.
                        force_w <= 1'b1;
                        prefetch <= 1'b0;
                        st <= ST_FETCH;
                    end else begin
                    if (mode) gemm_start <= 1'b1;
                    else gemv_start <= 1'b1;
                    if (!pp_ddr && (tile + 16'd1 < ntile)) begin
                        wr_b <= ~rd_b;
                        k_base <= (tile + 16'd1) << 8;
                        Knext <= tile_len(tile + 16'd1, ntile, K);
                        fill_kind <= 2'd1;
                        fill_go <= 1'b1;
                        prefetch <= 1'b1;
                    end else if (pp_ddr && !prefill && (tile + 16'd1 < ntile)) begin
                        wr_b <= ~rd_b;
                        dma_wr <= 1'b0;
                        dma_addr <= { (tile + 16'd1), 15'd0 };
                        dma_bytes <= {16'd0, tile_len(tile + 16'd1, ntile, K), 7'd0};
                        dma_go <= 1'b1;
                        dma_kick <= 1'b1;
                        dbeat <= 11'd0;
                        prefetch <= 1'b1;
                    end else
                        prefetch <= 1'b0;
                    comp_latched <= 1'b0;
                    st <= ST_WAITC;
                    end
                end
                ST_WAITC: begin
                    if (mode ? gemm_done : gemv_done) comp_latched <= 1'b1;
                    if (prefetch && dma_r_valid) dbeat <= dbeat + 11'd1;
                    if (prefetch && dma_done) begin
                        bank_valid[wr_b] <= 1'b1;
                        bank_cmd[wr_b] <= cmd_id;
                        bank_tile[wr_b] <= tile + 16'd1;
                    end
                    if ((comp_latched || (mode ? gemm_done : gemv_done))
                            && !(prefetch && (fill_busy || (pp_ddr && dma_busy && !dma_done)))) begin
                        prefetch <= 1'b0;
                        dma_kick <= 1'b0;
                        comp_latched <= 1'b0;
                        if (tile + 16'd1 < ntile) begin
                            tile <= tile + 16'd1;
                            rd_b <= wr_b;
                            acc_cont <= 1'b1;
                            swaps <= swaps + 16'd1;
                            k_base <= (tile + 16'd1) << 8;
                            Ktile <= tile_len(tile + 16'd1, ntile, K);
                            fill_kind <= 2'd2;
                            st <= ST_FILL;
                        end else begin
                            fi <= 9'd0;
                            st <= ST_CAP;
                        end
                    end
                end
                ST_CAP: begin
                    pmem[fi[6:0]] <= sat32(mac_acc[fi[6:0]]);
                    if (fi == 9'd127) begin
                        case_xor <= 32'd0;
                        case_add <= 32'd0;
                        fm <= 4'd0;
                        fn <= 8'd0;
                        fi <= 9'd0;
                        st <= ST_FOLD;
                    end else
                        fi <= fi + 9'd1;
                end
                ST_FOLD: begin
                    logic signed [31:0] vv;
                    logic [7:0] lane;
                    lane = mode ? (fm * 8'd16 + fn) : fn;
                    vv = pmem[lane[6:0]];
                    case_xor <= case_xor ^ vv[31:0];
                    case_add <= case_add + vv[31:0];
                    if (!mode) begin
                        if (fn + 8'd1 >= N) st <= ST_ACCUM;
                        else fn <= fn + 8'd1;
                    end else begin
                        if (fn + 8'd1 >= N) begin
                            fn <= 8'd0;
                            if (fm + 4'd1 >= M) st <= ST_ACCUM;
                            else fm <= fm + 4'd1;
                        end else
                            fn <= fn + 8'd1;
                    end
                end
                ST_ACCUM: begin
                    xor32 <= xor32 ^ case_xor;
                    add32 <= add32 + case_add;
                    macs <= macs + (32'(M) * 32'(N) * 32'(K));
                    cases_done <= cases_done + 32'd1;
                    st <= ST_NEXT;
                end
                ST_NEXT: begin
                    if (i_case + 32'd1 >= ncase) begin
                        pass <= 1'b1;
                        st <= ST_DONE;
                    end else begin
                        i_case <= i_case + 32'd1;
                        acc_cont <= 1'b0;
                        tile <= 16'd0;
                        wr_b <= 1'b0;
                        rd_b <= 1'b0;
                        st <= ST_DEC;
                    end
                end
                ST_RQ: begin
                    logic signed [15:0] q16;
                    logic signed [31:0] s32;
                    s32 = pmem[fi[6:0]] >>> rq_shift;
                    if (s32 > 32'sd32767) q16 = 16'sd32767;
                    else if (s32 < -32'sd32768) q16 = -16'sd32768;
                    else q16 = s32[15:0];
                    if (fi == 9'd0) begin
                        xor32 <= {16'd0, q16};
                        add32 <= {16'd0, q16};
                    end else begin
                        xor32 <= xor32 ^ {16'd0, q16};
                        add32 <= add32 + {16'd0, q16};
                    end
                    if (fi == 9'd127) begin
                        pass <= 1'b1;
                        st <= ST_DONE;
                    end else
                        fi <= fi + 9'd1;
                end
                ST_DDRW: begin
                    dma_wr <= 1'b1;
                    dma_addr <= 28'd0;
                    dma_bytes <= 32'd32768;
                    if (!dma_kick) begin
                        dma_go <= 1'b1;
                        dma_kick <= 1'b1;
                    end else if (dma_done) begin
                        dma_kick <= 1'b0;
                        dma_wr <= 1'b0;
                        cycles <= 32'd0;
                        dbeat <= 11'd0;
                        st <= ST_DDRR;
                    end
                    if (dma_w_ready) seqb <= seqb + 8'd16;
                end
                ST_DDRR: begin
                    dma_wr <= 1'b0;
                    dma_addr <= 28'd0;
                    dma_bytes <= 32'd32768;
                    if (!dma_kick) begin
                        dma_go <= 1'b1;
                        dma_kick <= 1'b1;
                    end else if (dma_done) begin
                        dma_kick <= 1'b0;
                        st <= ST_GO;
                    end
                    if (dma_r_valid) dbeat <= dbeat + 11'd1;
                end
                ST_DUMP: begin
                    dump_act <= 1'b1;
                    dump_hold <= 2'd2;
                    dump_k <= 8'd0;
                    dump_ch <= 3'd0;
                    dma_wr <= 1'b1;
                    dma_addr <= {tile[12:0], 15'd0};
                    dma_bytes <= {16'd0, Ktile, 7'd0};
                    st <= ST_PREFILL_NXT;
                end
                ST_PREFILL_NXT: begin
                    if (dump_hold != 2'd0) begin
                        dump_hold <= dump_hold - 2'd1;
                        if (dump_hold == 2'd1) begin
                            row_q <= w_rd_data;
                            dump_k <= 8'd1;
                            if (!dma_kick) begin
                                dma_go <= 1'b1;
                                dma_kick <= 1'b1;
                            end
                        end
                    end else if (dma_w_ready) begin
                        if (dump_ch == 3'd7) begin
                            dump_ch <= 3'd0;
                            row_q <= w_rd_data;
                            dump_k <= dump_k + 8'd1;
                        end else
                            dump_ch <= dump_ch + 3'd1;
                    end
                    if (dma_done) begin
                        dump_act <= 1'b0;
                        dump_hold <= 2'd0;
                        dma_kick <= 1'b0;
                        dma_wr <= 1'b0;
                        if (tile + 16'd1 < ntile) begin
                            tile <= tile + 16'd1;
                            k_base <= (tile + 16'd1) << 8;
                            Ktile <= tile_len(tile + 16'd1, ntile, K);
                            fill_kind <= 2'd1;
                            wr_b <= 1'b0;
                            st <= ST_FILL;
                        end else begin
                            tile <= 16'd0;
                            k_base <= 16'd0;
                            Ktile <= tile_len(16'd0, ntile, K);
                            wr_b <= 1'b0;
                            rd_b <= 1'b0;
                            prefill <= 1'b0;
                            st <= ST_FETCH;
                        end
                    end
                end
                ST_FETCH: begin
                    dma_wr <= 1'b0;
                    dma_addr <= {tile[12:0], 15'd0};
                    dma_bytes <= {16'd0, Ktile, 7'd0};
                    wr_b <= tile[0];
                    if (!dma_kick) begin
                        dma_go <= 1'b1;
                        dma_kick <= 1'b1;
                        dbeat <= 11'd0;
                    end else if (dma_done) begin
                        dma_kick <= 1'b0;
                        bank_valid[wr_b] <= 1'b1;
                        bank_cmd[wr_b] <= cmd_id;
                        bank_tile[wr_b] <= tile;
                        rd_b <= tile[0];
                        if (force_w) begin
                            force_w <= 1'b0;
                            st <= ST_GO;
                        end else begin
                            fill_kind <= 2'd2;
                            k_base <= tile << 8;
                            st <= ST_FILL;
                        end
                    end
                    if (dma_r_valid) dbeat <= dbeat + 11'd1;
                end
                ST_DONE: begin
                    done <= 1'b1;
                    last_ntile <= ntile;
                    st <= ST_IDLE;
                end
                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
