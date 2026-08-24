`timescale 1ns/1ps
module arty_a7_lm02_top (
    input  logic CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic uart_rxd_out,
    input  logic uart_txd_in,
    output logic [13:0] ddr3_addr,
    output logic [2:0]  ddr3_ba,
    output logic        ddr3_cas_n,
    output logic [0:0]  ddr3_ck_n,
    output logic [0:0]  ddr3_ck_p,
    output logic [0:0]  ddr3_cke,
    output logic [0:0]  ddr3_cs_n,
    output logic        ddr3_ras_n,
    output logic        ddr3_reset_n,
    output logic        ddr3_we_n,
    inout  logic [15:0] ddr3_dq,
    inout  logic [1:0]  ddr3_dqs_n,
    inout  logic [1:0]  ddr3_dqs_p,
    output logic [1:0]  ddr3_dm,
    output logic [0:0]  ddr3_odt
);
    logic clk166, clk200, clk_locked, btn0_s, rst100_n;
    logic ui_clk, ui_rst, calib, mig_mmcm, ui_rst_n;
    logic [3:0] sw_s;
    logic rx_valid;
    logic [7:0] rx_data;
    logic start_meta, start_ui, start_ui_q, start_cmd;
    logic [2:0] cmd;
    logic in_mode;
    logic [3:0] in_m, rq_shift;
    logic [7:0] in_n;
    logic [15:0] in_k, in_count, in_idx;
    logic [31:0] in_seed;
    logic busy, done, pass;
    logic calib_s, busy_s, pass_s, done_s, done_s_q;
    logic [7:0] phase;
    logic [31:0] xor32, add32, macs, cycles, stalls, hazards, cases_done;
    logic [31:0] dma_unders, bank_hazards, overlap_cyc;
    logic [15:0] axi_berrs, axi_rerrs, swaps, ntile_out;
    logic signed [31:0] psum_rd;
    logic [6:0] psum_idx;
    logic tx_start, tx_busy;
    logic [7:0] tx_frame [0:14];
    integer fi;

    clk_arty_ddr u_clk (
        .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
    );
    sync_bits #(.WIDTH(1)) u_b0 (.clk(CLK100MHZ), .rst_n(clk_locked), .async_in(btn[0]), .sync_out(btn0_s));
    assign rst100_n = clk_locked && !btn0_s;
    sync_bits #(.WIDTH(4)) u_sw (.clk(CLK100MHZ), .rst_n(rst100_n), .async_in(sw), .sync_out(sw_s));

    uart_rx #(.CLK_HZ(100000000), .BAUD(115200)) u_rx (
        .clk(CLK100MHZ), .rst_n(rst100_n), .rx(uart_txd_in), .data(rx_data), .valid(rx_valid)
    );
    lm02_tx #(.CLK_HZ(100000000), .BAUD(115200)) u_tx (
        .clk(CLK100MHZ), .rst_n(rst100_n), .start(tx_start), .frame(tx_frame),
        .tx(uart_rxd_out), .busy(tx_busy)
    );

    logic [3:0] awid, arid, bid, rid;
    logic [27:0] awaddr, araddr;
    logic [7:0] awlen, arlen;
    logic [2:0] awsize, arsize;
    logic [1:0] awburst, arburst, bresp, rresp;
    logic awvalid, awready, wlast, wvalid, wready, bvalid, bready;
    logic arvalid, arready, rlast, rvalid, rready;
    logic [127:0] wdata, rdata;
    logic [15:0] wstrb;

    mig_native_wrap u_mig (
        .sys_clk_i(clk166), .clk_ref_i(clk200), .sys_rst_n(rst100_n),
        .ui_clk(ui_clk), .ui_rst(ui_rst), .init_calib_complete(calib), .mmcm_locked(mig_mmcm),
        .ddr3_addr(ddr3_addr), .ddr3_ba(ddr3_ba), .ddr3_cas_n(ddr3_cas_n),
        .ddr3_ck_n(ddr3_ck_n), .ddr3_ck_p(ddr3_ck_p), .ddr3_cke(ddr3_cke),
        .ddr3_cs_n(ddr3_cs_n), .ddr3_ras_n(ddr3_ras_n), .ddr3_reset_n(ddr3_reset_n),
        .ddr3_we_n(ddr3_we_n), .ddr3_dq(ddr3_dq), .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p), .ddr3_dm(ddr3_dm), .ddr3_odt(ddr3_odt),
        .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
        .s_axi_awsize(awsize), .s_axi_awburst(awburst),
        .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
        .s_axi_arsize(arsize), .s_axi_arburst(arburst),
        .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
        .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );
    assign ui_rst_n = ~ui_rst && calib;

    logic wr_bank, rd_bank, w_wr_en, a_wr_en, mac_clr, mac_en;
    logic [7:0] w_wr_k, w_rd_k, a_wr_k, a_rd_k;
    logic [2:0] w_wr_chunk;
    logic [127:0] w_wr_data, a_wr_data, a_rd_data;
    logic [1023:0] w_rd_data;
    logic signed [15:0] mac_a [0:127], gemv_a [0:127], gemm_a [0:127];
    logic signed [7:0]  mac_b [0:127], gemv_b [0:127], gemm_b [0:127];
    logic signed [47:0] mac_acc [0:127];
    logic gemv_start, gemm_start, acc_cont, gemv_done, gemm_done;
    logic gemv_en, gemm_en, gemv_clr, gemm_clr, gemv_busy, gemm_busy;
    logic [7:0] gemv_k, gemm_k;
    logic [8:0] k_len;
    logic dma_go, dma_wr, dma_busy, dma_done, dma_under, axi_berr, axi_rerr;
    logic dma_w_valid, dma_w_ready, dma_r_valid, dma_r_ready;
    logic [27:0] dma_addr;
    logic [31:0] dma_bytes;
    logic [127:0] dma_w_data, dma_r_data;

    tile_weight_pingpong u_w (
        .clk(ui_clk), .rst_n(ui_rst_n),
        .wr_en(w_wr_en), .wr_bank(wr_bank), .wr_k(w_wr_k), .wr_chunk(w_wr_chunk), .wr_data(w_wr_data),
        .rd_bank(rd_bank), .rd_k(w_rd_k), .rd_data(w_rd_data)
    );
    tile_activation u_a (
        .clk(ui_clk), .wr_en(a_wr_en), .wr_k(a_wr_k), .wr_data(a_wr_data),
        .rd_k(a_rd_k), .rd_data(a_rd_data)
    );
    mac_array_128 u_mac (
        .clk(ui_clk), .rst_n(ui_rst_n), .clr(mac_clr), .en(mac_en),
        .a(mac_a), .b(mac_b), .acc(mac_acc)
    );
    gemv_scheduler u_gemv (
        .clk(ui_clk), .rst_n(ui_rst_n), .start(gemv_start), .acc_cont(acc_cont),
        .k_len(k_len), .busy(gemv_busy), .done(gemv_done), .clr(gemv_clr), .en(gemv_en),
        .k_addr(gemv_k), .act_row(a_rd_data), .w_row(w_rd_data), .a(gemv_a), .b(gemv_b)
    );
    gemm_scheduler u_gemm (
        .clk(ui_clk), .rst_n(ui_rst_n), .start(gemm_start), .acc_cont(acc_cont),
        .k_len(k_len), .busy(gemm_busy), .done(gemm_done), .clr(gemm_clr), .en(gemm_en),
        .k_addr(gemm_k), .act_row(a_rd_data), .w_row(w_rd_data), .a(gemm_a), .b(gemm_b)
    );
    ddr_tile_dma u_dma (
        .clk(ui_clk), .rst_n(ui_rst_n), .go(dma_go), .wr(dma_wr),
        .addr(dma_addr), .bytes(dma_bytes), .busy(dma_busy), .done(dma_done), .underflow(dma_under),
        .axi_berr(axi_berr), .axi_rerr(axi_rerr),
        .w_valid(dma_w_valid), .w_ready(dma_w_ready), .w_data(dma_w_data),
        .r_valid(dma_r_valid), .r_ready(dma_r_ready), .r_data(dma_r_data),
        .m_axi_awid(awid), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen),
        .m_axi_awsize(awsize), .m_axi_awburst(awburst),
        .m_axi_awvalid(awvalid), .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
        .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
        .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
        .m_axi_arsize(arsize), .m_axi_arburst(arburst),
        .m_axi_arvalid(arvalid), .m_axi_arready(arready),
        .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
        .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
    );
    tensor_microseq u_seq (
        .clk(ui_clk), .rst_n(ui_rst_n), .start(start_ui), .cmd(cmd),
        .in_mode(in_mode), .in_m(in_m), .in_n(in_n), .in_k(in_k),
        .in_seed(in_seed), .in_count(in_count), .in_idx(in_idx), .rq_shift(rq_shift),
        .busy(busy), .done(done), .pass(pass), .phase(phase),
        .xor32(xor32), .add32(add32), .macs(macs), .cycles(cycles),
        .stalls(stalls), .hazards(hazards),
        .dma_unders(dma_unders), .bank_hazards(bank_hazards),
        .axi_berrs(axi_berrs), .axi_rerrs(axi_rerrs),
        .swaps(swaps), .overlap_cyc(overlap_cyc), .ntile_out(ntile_out),
        .cases_done(cases_done),
        .psum_rd(psum_rd), .psum_idx(psum_idx),
        .wr_bank(wr_bank), .rd_bank(rd_bank),
        .w_wr_en(w_wr_en), .w_wr_k(w_wr_k), .w_wr_chunk(w_wr_chunk), .w_wr_data(w_wr_data),
        .w_rd_k(w_rd_k), .w_rd_data(w_rd_data),
        .a_wr_en(a_wr_en), .a_wr_k(a_wr_k), .a_wr_data(a_wr_data),
        .a_rd_k(a_rd_k), .a_rd_data(a_rd_data),
        .mac_clr(mac_clr), .mac_en(mac_en), .mac_a(mac_a), .mac_b(mac_b), .mac_acc(mac_acc),
        .gemv_start(gemv_start), .gemm_start(gemm_start), .acc_cont(acc_cont), .k_len(k_len),
        .gemv_done(gemv_done), .gemm_done(gemm_done),
        .gemv_en(gemv_en), .gemm_en(gemm_en), .gemv_clr(gemv_clr), .gemm_clr(gemm_clr),
        .gemv_k(gemv_k), .gemm_k(gemm_k),
        .gemv_a(gemv_a), .gemv_b(gemv_b), .gemm_a(gemm_a), .gemm_b(gemm_b),
        .dma_go(dma_go), .dma_wr(dma_wr), .dma_addr(dma_addr), .dma_bytes(dma_bytes),
        .dma_busy(dma_busy), .dma_done(dma_done), .dma_under(dma_under),
        .axi_berr(axi_berr), .axi_rerr(axi_rerr),
        .dma_w_valid(dma_w_valid), .dma_w_ready(dma_w_ready), .dma_w_data(dma_w_data),
        .dma_r_valid(dma_r_valid), .dma_r_ready(dma_r_ready), .dma_r_data(dma_r_data)
    );

    sync_bits #(.WIDTH(4)) u_st (
        .clk(CLK100MHZ), .rst_n(rst100_n),
        .async_in({pass, busy, calib, done}),
        .sync_out({pass_s, busy_s, calib_s, done_s})
    );

    always_ff @(posedge CLK100MHZ) begin
        if (!rst100_n) begin
            start_meta <= 1'b0;
            done_s_q <= 1'b0;
        end else begin
            done_s_q <= done_s;
            if (start_cmd) start_meta <= 1'b1;
            else if (done_s && !done_s_q) start_meta <= 1'b0;
        end
    end
    always_ff @(posedge ui_clk) begin
        if (!ui_rst_n) begin
            start_ui_q <= 1'b0;
            start_ui <= 1'b0;
        end else begin
            start_ui_q <= start_meta;
            start_ui <= start_meta & ~start_ui_q;
        end
    end

    logic collecting, cmd_stat, cmd_fold, cmd_cnt, cmd_psum, cmd_cnt2, cmd_ovl;
    logic [3:0] idx;
    logic [7:0] buf_b [0:14];
    logic [7:0] run_xor;
    logic sw0_q;

    always_ff @(posedge CLK100MHZ) begin
        if (!rst100_n) begin
            collecting <= 1'b0;
            idx <= 4'd0;
            run_xor <= 8'd0;
            start_cmd <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_fold <= 1'b0;
            cmd_cnt <= 1'b0;
            cmd_psum <= 1'b0;
            cmd_cnt2 <= 1'b0;
            cmd_ovl <= 1'b0;
            tx_start <= 1'b0;
            cmd <= 3'd1;
            in_mode <= 1'b0;
            in_m <= 4'd1;
            in_n <= 8'd16;
            in_k <= 16'd32;
            in_seed <= 32'hC0FFEE00;
            in_count <= 16'd10000;
            in_idx <= 16'd0;
            rq_shift <= 4'd0;
            psum_idx <= 7'd0;
            sw0_q <= 1'b0;
        end else begin
            start_cmd <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_fold <= 1'b0;
            cmd_cnt <= 1'b0;
            cmd_psum <= 1'b0;
            cmd_cnt2 <= 1'b0;
            cmd_ovl <= 1'b0;
            tx_start <= 1'b0;
            sw0_q <= sw_s[0];
            if (rx_valid) begin
                if (!collecting) begin
                    if (rx_data == 8'hA5) begin
                        collecting <= 1'b1;
                        idx <= 4'd1;
                        buf_b[0] <= 8'hA5;
                        run_xor <= 8'hA5;
                    end
                end else begin
                    buf_b[idx] <= rx_data;
                    if (idx < 4'd14) run_xor <= run_xor ^ rx_data;
                    if (idx == 4'd14) begin
                        collecting <= 1'b0;
                        idx <= 4'd0;
                        if ((run_xor ^ rx_data) == 8'd0 && buf_b[1] == 8'h72) begin
                            unique case (buf_b[2])
                                8'h20: begin
                                    cmd <= 3'd0;
                                    in_mode <= buf_b[3][0];
                                    in_m <= buf_b[4][3:0];
                                    in_n <= buf_b[5];
                                    in_k <= {buf_b[7], buf_b[6]};
                                    in_seed <= {buf_b[11], buf_b[10], buf_b[9], buf_b[8]};
                                    in_idx <= {buf_b[13], buf_b[12]};
                                    start_cmd <= 1'b1;
                                end
                                8'h21: begin
                                    cmd <= 3'd1;
                                    in_count <= {buf_b[4], buf_b[3]};
                                    in_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    start_cmd <= 1'b1;
                                end
                                8'h22: cmd_stat <= 1'b1;
                                8'h23: cmd_fold <= 1'b1;
                                8'h24: cmd_cnt <= 1'b1;
                                8'h25: begin
                                    psum_idx <= buf_b[3][6:0];
                                    cmd_psum <= 1'b1;
                                end
                                8'h26: begin
                                    cmd <= 3'd2;
                                    in_k <= {buf_b[4], buf_b[3]};
                                    in_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    start_cmd <= 1'b1;
                                end
                                8'h27: begin
                                    cmd <= 3'd3;
                                    start_cmd <= 1'b1;
                                end
                                8'h28: begin
                                    cmd <= 3'd4;
                                    rq_shift <= buf_b[3][3:0];
                                    start_cmd <= 1'b1;
                                end
                                8'h29: begin
                                    cmd <= 3'd5;
                                    in_k <= {buf_b[4], buf_b[3]};
                                    in_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    in_idx <= {buf_b[10], buf_b[9]};
                                    in_n <= 8'd128;
                                    in_mode <= 1'b0;
                                    start_cmd <= 1'b1;
                                end
                                8'h2C: cmd_cnt2 <= 1'b1;
                                8'h2D: cmd_ovl <= 1'b1;
                                default: ;
                            endcase
                        end
                    end else
                        idx <= idx + 4'd1;
                end
            end
            if (!tx_busy && !tx_start) begin
                if (cmd_stat || sw_s[1]) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h90;
                    tx_frame[2] <= {pass_s, busy_s, calib_s, done_s, 4'd0};
                    tx_frame[3] <= phase;
                    tx_frame[4] <= cases_done[7:0];
                    tx_frame[5] <= cases_done[15:8];
                    tx_frame[6] <= cases_done[23:16];
                    tx_frame[7] <= cases_done[31:24];
                    for (fi = 8; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h90 ^ {pass_s, busy_s, calib_s, done_s, 4'd0} ^ phase
                        ^ cases_done[7:0] ^ cases_done[15:8] ^ cases_done[23:16] ^ cases_done[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_fold) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h91;
                    tx_frame[2] <= xor32[7:0];
                    tx_frame[3] <= xor32[15:8];
                    tx_frame[4] <= xor32[23:16];
                    tx_frame[5] <= xor32[31:24];
                    tx_frame[6] <= add32[7:0];
                    tx_frame[7] <= add32[15:8];
                    tx_frame[8] <= add32[23:16];
                    tx_frame[9] <= add32[31:24];
                    tx_frame[10] <= macs[7:0];
                    tx_frame[11] <= macs[15:8];
                    tx_frame[12] <= macs[23:16];
                    tx_frame[13] <= macs[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'h91
                        ^ xor32[7:0] ^ xor32[15:8] ^ xor32[23:16] ^ xor32[31:24]
                        ^ add32[7:0] ^ add32[15:8] ^ add32[23:16] ^ add32[31:24]
                        ^ macs[7:0] ^ macs[15:8] ^ macs[23:16] ^ macs[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_cnt) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h92;
                    tx_frame[2] <= cycles[7:0];
                    tx_frame[3] <= cycles[15:8];
                    tx_frame[4] <= cycles[23:16];
                    tx_frame[5] <= cycles[31:24];
                    tx_frame[6] <= stalls[7:0];
                    tx_frame[7] <= stalls[15:8];
                    tx_frame[8] <= stalls[23:16];
                    tx_frame[9] <= stalls[31:24];
                    tx_frame[10] <= hazards[7:0];
                    tx_frame[11] <= hazards[15:8];
                    tx_frame[12] <= hazards[23:16];
                    tx_frame[13] <= hazards[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'h92
                        ^ cycles[7:0] ^ cycles[15:8] ^ cycles[23:16] ^ cycles[31:24]
                        ^ stalls[7:0] ^ stalls[15:8] ^ stalls[23:16] ^ stalls[31:24]
                        ^ hazards[7:0] ^ hazards[15:8] ^ hazards[23:16] ^ hazards[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_cnt2) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h94;
                    tx_frame[2] <= dma_unders[7:0];
                    tx_frame[3] <= dma_unders[15:8];
                    tx_frame[4] <= dma_unders[23:16];
                    tx_frame[5] <= dma_unders[31:24];
                    tx_frame[6] <= bank_hazards[7:0];
                    tx_frame[7] <= bank_hazards[15:8];
                    tx_frame[8] <= axi_berrs[7:0];
                    tx_frame[9] <= axi_rerrs[7:0];
                    tx_frame[10] <= swaps[7:0];
                    tx_frame[11] <= swaps[15:8];
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h94
                        ^ dma_unders[7:0] ^ dma_unders[15:8] ^ dma_unders[23:16] ^ dma_unders[31:24]
                        ^ bank_hazards[7:0] ^ bank_hazards[15:8]
                        ^ axi_berrs[7:0] ^ axi_rerrs[7:0]
                        ^ swaps[7:0] ^ swaps[15:8];
                    tx_start <= 1'b1;
                end else if (cmd_ovl) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h95;
                    tx_frame[2] <= overlap_cyc[7:0];
                    tx_frame[3] <= overlap_cyc[15:8];
                    tx_frame[4] <= overlap_cyc[23:16];
                    tx_frame[5] <= overlap_cyc[31:24];
                    tx_frame[6] <= ntile_out[7:0];
                    tx_frame[7] <= ntile_out[15:8];
                    for (fi = 8; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h95
                        ^ overlap_cyc[7:0] ^ overlap_cyc[15:8] ^ overlap_cyc[23:16] ^ overlap_cyc[31:24]
                        ^ ntile_out[7:0] ^ ntile_out[15:8];
                    tx_start <= 1'b1;
                end else if (cmd_psum) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h93;
                    tx_frame[2] <= psum_rd[7:0];
                    tx_frame[3] <= psum_rd[15:8];
                    tx_frame[4] <= psum_rd[23:16];
                    tx_frame[5] <= psum_rd[31:24];
                    for (fi = 6; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h93 ^ psum_rd[7:0] ^ psum_rd[15:8]
                        ^ psum_rd[23:16] ^ psum_rd[31:24];
                    tx_start <= 1'b1;
                end
            end
            if (sw_s[0] && !sw0_q && calib_s && !busy_s) begin
                cmd <= 3'd1;
                in_count <= 16'd10000;
                in_seed <= 32'hC0FFEE00;
                start_cmd <= 1'b1;
            end
        end
    end

    assign led[0] = calib_s;
    assign led[1] = busy_s;
    assign led[2] = pass_s;
    assign led[3] = |{dma_unders, bank_hazards, axi_berrs, axi_rerrs};
endmodule
