`timescale 1ns/1ps
// A7-LM-04: 100k core + official AXI MIG persist + LM-02 128-lane K-tests.
// Bitstream arty_a7_lm04.bit only. Does not overwrite 00-03.
import a7lm04_pkg::*;
module arty_a7_lm04_top (
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
    logic clk166, clk200, clk_locked, btn0_s, btn50, rst100_n, clk50, rst50_n, calib50;
    logic ui_clk, ui_rst, calib, mig_mmcm, ui_rst_n;
    logic [3:0] sw_s;

    clk_arty_ddr u_clk (
        .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
    );
    sync_bits #(.WIDTH(1)) u_b0 (.clk(CLK100MHZ), .rst_n(clk_locked), .async_in(btn[0]), .sync_out(btn0_s));
    assign rst100_n = clk_locked && !btn0_s;
    clkdiv2 u_div (.clk_in(CLK100MHZ), .rst_n(rst100_n), .clk_out(clk50));
    sync_bits #(.WIDTH(1)) u_b50 (.clk(clk50), .rst_n(rst100_n), .async_in(btn[0]), .sync_out(btn50));
    sync_bits #(.WIDTH(1)) u_cal50 (.clk(clk50), .rst_n(rst100_n), .async_in(calib), .sync_out(calib50));
    logic rst_uart_n;
    assign rst_uart_n = rst100_n && !btn50;
    assign rst50_n = rst_uart_n && calib50;
    sync_bits #(.WIDTH(4)) u_sw (.clk(clk50), .rst_n(rst50_n), .async_in(sw), .sync_out(sw_s));

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

    // UART + 100k core on clk50 (LM-03 timing class). MIG/tensor stay on ui_clk.
    logic rx_valid;
    logic [7:0] rx_data;
    logic tx_start, tx_busy;
    logic [7:0] tx_frame [0:14];
    uart_rx #(.CLK_HZ(50000000), .BAUD(115200)) u_rx (
        .clk(clk50), .rst_n(rst_uart_n), .rx(uart_txd_in), .data(rx_data), .valid(rx_valid)
    );
    lm02_tx #(.CLK_HZ(50000000), .BAUD(115200)) u_tx (
        .clk(clk50), .rst_n(rst_uart_n), .start(tx_start), .frame(tx_frame),
        .tx(uart_rxd_out), .busy(tx_busy)
    );

    // --- 100k core ---
    logic mem_we, mem_we_u, mem_we_p;
    logic [16:0] mem_addr, mem_addr_u, mem_addr_p;
    logic signed [7:0] mem_wdata, mem_wdata_u, mem_wdata_p, mem_rdata;
    logic ctx_we;
    logic [4:0] ctx_idx, ctx_n;
    logic [7:0] ctx_bytes [0:7];
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [7:0] tgt;
    logic [3:0] lr;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [7:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;

    logic p_busy, p_done, p_go_flush, p_go_reload, p_dma_owner;
    logic p_under, p_berr, p_rerr;
    logic [31:0] p_bytes;

    assign mem_we    = p_busy ? mem_we_p    : mem_we_u;
    assign mem_addr  = p_busy ? mem_addr_p  : mem_addr_u;
    assign mem_wdata = p_busy ? mem_wdata_p : mem_wdata_u;

    tiny_gpt100k_core u_core (
        .clk(clk50), .rst_n(rst50_n),
        .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n),
        .ctx_pack({ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                   ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]}),
        .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
        .start_corpus(start_corpus), .after_mode(after_mode || sw_s[0]),
        .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
        .tgt_in(tgt), .lr_in(lr), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
        .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
        .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32), .phase(phase)
    );

    // --- tensor / DMA (LM-02 class) ---
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
    logic t_dma_go, t_dma_wr, t_dma_w_valid, t_dma_w_ready, t_dma_r_valid, t_dma_r_ready;
    logic p_dma_go, p_dma_wr, p_dma_w_valid, p_dma_w_ready, p_dma_r_valid, p_dma_r_ready;
    logic dma_go, dma_wr, dma_busy, dma_done, dma_under, axi_berr, axi_rerr;
    logic dma_w_valid, dma_w_ready, dma_r_valid, dma_r_ready;
    logic [27:0] t_dma_addr, p_dma_addr, dma_addr;
    logic [31:0] t_dma_bytes, p_dma_bytes, dma_bytes;
    logic [127:0] t_dma_w_data, p_dma_w_data, dma_w_data, t_dma_r_data, p_dma_r_data, dma_r_data;

    assign dma_go      = p_dma_owner ? p_dma_go      : t_dma_go;
    assign dma_wr      = p_dma_owner ? p_dma_wr      : t_dma_wr;
    assign dma_addr    = p_dma_owner ? p_dma_addr    : t_dma_addr;
    assign dma_bytes   = p_dma_owner ? p_dma_bytes   : t_dma_bytes;
    assign dma_w_valid = p_dma_owner ? p_dma_w_valid : t_dma_w_valid;
    assign dma_w_data  = p_dma_owner ? p_dma_w_data  : t_dma_w_data;
    assign dma_r_ready = p_dma_owner ? p_dma_r_ready : t_dma_r_ready;
    assign t_dma_w_ready = dma_w_ready && !p_dma_owner;
    assign p_dma_w_ready = dma_w_ready &&  p_dma_owner;
    assign t_dma_r_valid = dma_r_valid && !p_dma_owner;
    assign p_dma_r_valid = dma_r_valid &&  p_dma_owner;
    assign t_dma_r_data  = dma_r_data;
    assign p_dma_r_data  = dma_r_data;

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

    logic t_start, t_busy, t_done, t_pass;
    logic [2:0] t_cmd;
    logic t_mode;
    logic [3:0] t_m, t_rq;
    logic [7:0] t_n, t_phase;
    logic [15:0] t_k, t_count, t_idx;
    logic [31:0] t_seed, t_xor, t_add, t_macs, t_cyc, t_stalls, t_haz;
    logic [31:0] t_unders, t_bhaz, t_ovl, t_cases;
    logic [15:0] t_berrs, t_rerrs, t_swaps, t_ntile;
    logic signed [31:0] t_psum;
    logic [6:0] t_psum_idx;

    tensor_microseq u_seq (
        .clk(ui_clk), .rst_n(ui_rst_n), .start(t_start), .cmd(t_cmd),
        .in_mode(t_mode), .in_m(t_m), .in_n(t_n), .in_k(t_k),
        .in_seed(t_seed), .in_count(t_count), .in_idx(t_idx), .rq_shift(t_rq),
        .busy(t_busy), .done(t_done), .pass(t_pass), .phase(t_phase),
        .xor32(t_xor), .add32(t_add), .macs(t_macs), .cycles(t_cyc),
        .stalls(t_stalls), .hazards(t_haz),
        .dma_unders(t_unders), .bank_hazards(t_bhaz),
        .axi_berrs(t_berrs), .axi_rerrs(t_rerrs),
        .swaps(t_swaps), .overlap_cyc(t_ovl), .ntile_out(t_ntile),
        .cases_done(t_cases),
        .psum_rd(t_psum), .psum_idx(t_psum_idx),
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
        .dma_go(t_dma_go), .dma_wr(t_dma_wr), .dma_addr(t_dma_addr), .dma_bytes(t_dma_bytes),
        .dma_busy(dma_busy && !p_dma_owner), .dma_done(dma_done && !p_dma_owner), .dma_under(dma_under),
        .axi_berr(axi_berr), .axi_rerr(axi_rerr),
        .dma_w_valid(t_dma_w_valid), .dma_w_ready(t_dma_w_ready), .dma_w_data(t_dma_w_data),
        .dma_r_valid(t_dma_r_valid), .dma_r_ready(t_dma_r_ready), .dma_r_data(t_dma_r_data)
    );

    lm04_persist u_persist (
        .clk_bram(clk50), .rst_bram_n(rst50_n),
        .clk_dma(ui_clk), .rst_dma_n(ui_rst_n),
        .go_flush(p_go_flush), .go_reload(p_go_reload),
        .busy(p_busy), .done(p_done), .bytes_done(p_bytes),
        .last_under(p_under), .last_berr(p_berr), .last_rerr(p_rerr),
        .dma_owner(p_dma_owner),
        .mem_we(mem_we_p), .mem_addr(mem_addr_p), .mem_wdata(mem_wdata_p), .mem_rdata(mem_rdata),
        .dma_go(p_dma_go), .dma_wr(p_dma_wr), .dma_addr(p_dma_addr), .dma_bytes(p_dma_bytes),
        .dma_busy(dma_busy && p_dma_owner), .dma_done(dma_done && p_dma_owner),
        .dma_under(dma_under), .axi_berr(axi_berr), .axi_rerr(axi_rerr),
        .dma_w_valid(p_dma_w_valid), .dma_w_ready(p_dma_w_ready), .dma_w_data(p_dma_w_data),
        .dma_r_valid(p_dma_r_valid), .dma_r_ready(p_dma_r_ready), .dma_r_data(p_dma_r_data)
    );

    // --- UART A5/0x84 ---
    logic collecting, cmd_stat, cmd_ce, cmd_pred, cmd_persist, cmd_tstat, cmd_tfold, cmd_tcnt, cmd_tcnt2, cmd_tovl, cmd_tpsum;
    logic [3:0] idx;
    logic [7:0] buf_b [0:14];
    logic [7:0] run_xor;
    logic pend_a2, pend_p, fold_after_reload;
    logic rd_go, rd_pend;
    logic [2:0] rd_i, rd_wait;
    logic [16:0] rd_base;
    logic [7:0] rd_bytes [0:7];
    logic [3:0] wr_i, wr_n8;
    logic wr_go;
    logic [16:0] wr_base;
    logic [7:0] wr_bytes [0:7];
    integer fi;

    logic t_start_cmd, t_start_meta, t_start_ui_q, t_busy50, t_done50, t_done50_q, t_pass50;
    sync_bits #(.WIDTH(3)) u_tstat50 (
        .clk(clk50), .rst_n(rst50_n),
        .async_in({t_pass, t_busy, t_done}),
        .sync_out({t_pass50, t_busy50, t_done50})
    );
    logic t_busy50_q;
    always_ff @(posedge clk50) begin
        if (!rst50_n) begin
            t_start_meta <= 1'b0;
            t_done50_q <= 1'b0;
            t_busy50_q <= 1'b0;
        end else begin
            t_done50_q <= t_done50;
            t_busy50_q <= t_busy50;
            if (t_start_cmd) t_start_meta <= 1'b1;
            // Clear on busy falling edge (level, CDC-safe). A 1-cycle t_done
            // pulse is routinely dropped by the 2-FF sync and stuck the meta
            // high, so a second 0x50/0x59 never produced t_start.
            else if (t_busy50_q && !t_busy50) t_start_meta <= 1'b0;
        end
    end
    always_ff @(posedge ui_clk) begin
        if (!ui_rst_n) begin
            t_start_ui_q <= 1'b0;
            t_start <= 1'b0;
        end else begin
            t_start_ui_q <= t_start_meta;
            t_start <= t_start_meta & ~t_start_ui_q;
        end
    end

    always_ff @(posedge clk50) begin
        if (!rst_uart_n) begin
            collecting <= 1'b0;
            idx <= 4'd0;
            run_xor <= 8'd0;
            mem_we_u <= 1'b0;
            ctx_we <= 1'b0;
            start_fwd <= 1'b0;
            start_train <= 1'b0;
            start_ce <= 1'b0;
            start_corpus <= 1'b0;
            do_snap <= 1'b0;
            do_restore <= 1'b0;
            do_fold <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_ce <= 1'b0;
            cmd_pred <= 1'b0;
            cmd_persist <= 1'b0;
            cmd_tstat <= 1'b0;
            cmd_tfold <= 1'b0;
            cmd_tcnt <= 1'b0;
            cmd_tcnt2 <= 1'b0;
            cmd_tovl <= 1'b0;
            cmd_tpsum <= 1'b0;
            pend_a2 <= 1'b0;
            pend_p <= 1'b0;
            fold_after_reload <= 1'b0;
            rd_go <= 1'b0;
            rd_pend <= 1'b0;
            rd_i <= 3'd0;
            rd_wait <= 3'd0;
            rd_base <= 17'd0;
            wr_go <= 1'b0;
            wr_i <= 4'd0;
            wr_n8 <= 4'd0;
            wr_base <= 17'd0;
            tx_start <= 1'b0;
            after_mode <= 1'b0;
            tgt <= 8'd0;
            lr <= 4'd3;
            corpus_n <= 8'd8;
            corpus_ep <= 8'd24;
            mem_addr_u <= 17'd0;
            p_go_flush <= 1'b0;
            p_go_reload <= 1'b0;
            t_start_cmd <= 1'b0;
            t_cmd <= 3'd1;
            t_mode <= 1'b0;
            t_m <= 4'd1;
            t_n <= 8'd16;
            t_k <= 16'd32;
            t_seed <= 32'hC0FFEE00;
            t_count <= 16'd10000;
            t_idx <= 16'd0;
            t_rq <= 4'd0;
            t_psum_idx <= 7'd0;
        end else begin
            mem_we_u <= 1'b0;
            ctx_we <= 1'b0;
            start_fwd <= 1'b0;
            start_train <= 1'b0;
            start_ce <= 1'b0;
            start_corpus <= 1'b0;
            do_snap <= 1'b0;
            do_restore <= 1'b0;
            do_fold <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_ce <= 1'b0;
            cmd_pred <= 1'b0;
            cmd_persist <= 1'b0;
            cmd_tstat <= 1'b0;
            cmd_tfold <= 1'b0;
            cmd_tcnt <= 1'b0;
            cmd_tcnt2 <= 1'b0;
            cmd_tovl <= 1'b0;
            cmd_tpsum <= 1'b0;
            tx_start <= 1'b0;
            p_go_flush <= 1'b0;
            p_go_reload <= 1'b0;
            t_start_cmd <= 1'b0;

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
                        if ((run_xor ^ rx_data) == 8'd0 && buf_b[1] == 8'h84) begin
                            unique case (buf_b[2])
                                8'h30: begin
                                    wr_base <= {buf_b[5][4], buf_b[4], buf_b[3]};
                                    wr_n8 <= (buf_b[5][3:0] == 4'd0 || buf_b[5][3:0] > 4'd8)
                                        ? 4'd1 : buf_b[5][3:0];
                                    wr_bytes[0] <= buf_b[6];
                                    wr_bytes[1] <= buf_b[7];
                                    wr_bytes[2] <= buf_b[8];
                                    wr_bytes[3] <= buf_b[9];
                                    wr_bytes[4] <= buf_b[10];
                                    wr_bytes[5] <= buf_b[11];
                                    wr_bytes[6] <= buf_b[12];
                                    wr_bytes[7] <= buf_b[13];
                                    wr_i <= 4'd0;
                                    wr_go <= 1'b1;
                                end
                                8'h31: begin
                                    rd_base <= {buf_b[5][0], buf_b[4], buf_b[3]};
                                    mem_addr_u <= {buf_b[5][0], buf_b[4], buf_b[3]};
                                    rd_i <= 3'd0;
                                    rd_wait <= 3'd0;
                                    rd_go <= 1'b1;
                                    rd_pend <= 1'b0;
                                end
                                8'h32: begin
                                    ctx_we <= 1'b1;
                                    ctx_idx <= buf_b[3][4:0];
                                    ctx_n <= buf_b[4][4:0];
                                    ctx_bytes[0] <= buf_b[5];
                                    ctx_bytes[1] <= buf_b[6];
                                    ctx_bytes[2] <= buf_b[7];
                                    ctx_bytes[3] <= buf_b[8];
                                    ctx_bytes[4] <= buf_b[9];
                                    ctx_bytes[5] <= buf_b[10];
                                    ctx_bytes[6] <= buf_b[11];
                                    ctx_bytes[7] <= buf_b[12];
                                end
                                8'h33: if (calib50) start_fwd <= 1'b1;
                                8'h34: if (calib50) begin
                                    tgt <= buf_b[3];
                                    lr <= buf_b[4][3:0];
                                    start_train <= 1'b1;
                                end
                                8'h35: cmd_stat <= 1'b1;
                                8'h36: do_fold <= 1'b1;
                                8'h37: cmd_ce <= 1'b1;
                                8'h38: after_mode <= buf_b[3][0];
                                8'h39: begin
                                    if (calib50 && !busy && !t_busy50) begin
                                        if (buf_b[3][0]) p_go_reload <= 1'b1;
                                        else p_go_flush <= 1'b1;
                                    end
                                end
                                8'h3A: begin
                                    corpus_n <= buf_b[3];
                                    corpus_ep <= buf_b[4];
                                    lr <= buf_b[5][3:0];
                                    start_corpus <= 1'b1;
                                end
                                8'h3B: cmd_pred <= 1'b1;
                                8'h3C: start_ce <= 1'b1;
                                8'h40: if (calib50 && !busy && !t_busy50) p_go_flush <= 1'b1;
                                8'h41: if (calib50 && !busy && !t_busy50) begin
                                    p_go_reload <= 1'b1;
                                    fold_after_reload <= 1'b1;
                                end
                                8'h42: cmd_persist <= 1'b1;
                                8'h50: begin
                                    t_cmd <= 3'd0;
                                    t_mode <= buf_b[3][0];
                                    t_m <= buf_b[4][3:0];
                                    t_n <= buf_b[5];
                                    t_k <= {buf_b[7], buf_b[6]};
                                    t_seed <= {buf_b[11], buf_b[10], buf_b[9], buf_b[8]};
                                    t_idx <= {buf_b[13], buf_b[12]};
                                    t_start_cmd <= !p_busy;
                                end
                                8'h51: begin
                                    t_cmd <= 3'd1;
                                    t_count <= {buf_b[4], buf_b[3]};
                                    t_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    t_start_cmd <= !p_busy;
                                end
                                8'h52: cmd_tstat <= 1'b1;
                                8'h53: cmd_tfold <= 1'b1;
                                8'h54: cmd_tcnt <= 1'b1;
                                8'h55: begin
                                    t_psum_idx <= buf_b[3][6:0];
                                    cmd_tpsum <= 1'b1;
                                end
                                8'h56: begin
                                    t_cmd <= 3'd2;
                                    t_k <= {buf_b[4], buf_b[3]};
                                    t_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    t_start_cmd <= !p_busy;
                                end
                                8'h57: begin
                                    t_cmd <= 3'd3;
                                    t_start_cmd <= !p_busy;
                                end
                                8'h58: begin
                                    t_cmd <= 3'd4;
                                    t_rq <= buf_b[3][3:0];
                                    t_start_cmd <= !p_busy;
                                end
                                8'h59: begin
                                    t_cmd <= 3'd5;
                                    t_k <= {buf_b[4], buf_b[3]};
                                    t_seed <= {buf_b[8], buf_b[7], buf_b[6], buf_b[5]};
                                    t_idx <= {buf_b[10], buf_b[9]};
                                    t_n <= 8'd128;
                                    t_mode <= 1'b0;
                                    t_start_cmd <= !p_busy;
                                end
                                8'h5C: cmd_tcnt2 <= 1'b1;
                                8'h5D: cmd_tovl <= 1'b1;
                                default: ;
                            endcase
                        end
                    end else
                        idx <= idx + 4'd1;
                end
            end

            if (wr_go && !busy && !p_busy) begin
                mem_we_u <= 1'b1;
                mem_addr_u <= wr_base + {13'd0, wr_i};
                mem_wdata_u <= wr_bytes[wr_i[2:0]];
                if (wr_i + 4'd1 >= wr_n8)
                    wr_go <= 1'b0;
                else
                    wr_i <= wr_i + 4'd1;
            end

            if (done)
                pend_a2 <= 1'b1;
            if (p_done) begin
                pend_p <= 1'b1;
                if (fold_after_reload) begin
                    do_fold <= 1'b1;
                    fold_after_reload <= 1'b0;
                end
            end

            if (rd_go && !busy && !p_busy) begin
                mem_addr_u <= rd_base + {14'd0, rd_i};
                if (rd_wait < 3'd3)
                    rd_wait <= rd_wait + 3'd1;
                else begin
                    rd_bytes[rd_i] <= mem_rdata;
                    rd_wait <= 3'd0;
                    if (rd_i == 3'd7) begin
                        rd_go <= 1'b0;
                        rd_pend <= 1'b1;
                    end else
                        rd_i <= rd_i + 3'd1;
                end
            end

            if (!tx_busy && !tx_start) begin
                if (cmd_stat) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA1;
                    tx_frame[2] <= {after_mode, busy || p_busy || t_busy50, done, calib50, p_busy, 3'd0};
                    tx_frame[3] <= phase;
                    tx_frame[4] <= wr_n[7:0]; tx_frame[5] <= wr_n[15:8];
                    tx_frame[6] <= wr_n[23:16]; tx_frame[7] <= wr_n[31:24];
                    tx_frame[8] <= pred; tx_frame[9] <= last_loss[7:0];
                    tx_frame[10] <= last_loss[15:8];
                    tx_frame[11] <= 8'd0; tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA1
                        ^ {after_mode, busy || p_busy || t_busy50, done, calib50, p_busy, 3'd0} ^ phase
                        ^ wr_n[7:0] ^ wr_n[15:8] ^ wr_n[23:16] ^ wr_n[31:24]
                        ^ pred ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end else if (pend_a2) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA2;
                    tx_frame[2] <= xor32[7:0]; tx_frame[3] <= xor32[15:8];
                    tx_frame[4] <= xor32[23:16]; tx_frame[5] <= xor32[31:24];
                    tx_frame[6] <= add32[7:0]; tx_frame[7] <= add32[15:8];
                    tx_frame[8] <= add32[23:16]; tx_frame[9] <= add32[31:24];
                    tx_frame[10] <= wr_n[7:0]; tx_frame[11] <= wr_n[15:8];
                    tx_frame[12] <= wr_n[23:16]; tx_frame[13] <= wr_n[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'hA2
                        ^ xor32[7:0] ^ xor32[15:8] ^ xor32[23:16] ^ xor32[31:24]
                        ^ add32[7:0] ^ add32[15:8] ^ add32[23:16] ^ add32[31:24]
                        ^ wr_n[7:0] ^ wr_n[15:8] ^ wr_n[23:16] ^ wr_n[31:24];
                    tx_start <= 1'b1;
                    pend_a2 <= 1'b0;
                end else if (cmd_ce) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA3;
                    tx_frame[2] <= ce0[7:0]; tx_frame[3] <= ce0[15:8];
                    tx_frame[4] <= ce0[23:16]; tx_frame[5] <= ce0[31:24];
                    tx_frame[6] <= ce1[7:0]; tx_frame[7] <= ce1[15:8];
                    tx_frame[8] <= ce1[23:16]; tx_frame[9] <= ce1[31:24];
                    tx_frame[10] <= last_loss[7:0]; tx_frame[11] <= last_loss[15:8];
                    tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA3
                        ^ ce0[7:0] ^ ce0[15:8] ^ ce0[23:16] ^ ce0[31:24]
                        ^ ce1[7:0] ^ ce1[15:8] ^ ce1[23:16] ^ ce1[31:24]
                        ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end else if (rd_pend) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA4;
                    tx_frame[2] <= rd_base[7:0];
                    tx_frame[3] <= rd_base[15:8];
                    tx_frame[4] <= rd_bytes[0]; tx_frame[5] <= rd_bytes[1];
                    tx_frame[6] <= rd_bytes[2]; tx_frame[7] <= rd_bytes[3];
                    tx_frame[8] <= rd_bytes[4]; tx_frame[9] <= rd_bytes[5];
                    tx_frame[10] <= rd_bytes[6]; tx_frame[11] <= rd_bytes[7];
                    tx_frame[12] <= {7'd0, rd_base[16]};
                    tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA4
                        ^ rd_base[7:0] ^ rd_base[15:8]
                        ^ rd_bytes[0] ^ rd_bytes[1] ^ rd_bytes[2] ^ rd_bytes[3]
                        ^ rd_bytes[4] ^ rd_bytes[5] ^ rd_bytes[6] ^ rd_bytes[7]
                        ^ {7'd0, rd_base[16]};
                    tx_start <= 1'b1;
                    rd_pend <= 1'b0;
                end else if (cmd_pred) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA0;
                    tx_frame[2] <= pred;
                    tx_frame[3] <= last_loss[7:0];
                    tx_frame[4] <= last_loss[15:8];
                    for (fi = 5; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA0 ^ pred ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end else if (cmd_persist || pend_p) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA6;
                    tx_frame[2] <= {calib50, p_busy, p_under, p_berr, p_rerr, 3'd0};
                    tx_frame[3] <= 8'd0;
                    tx_frame[4] <= p_bytes[7:0]; tx_frame[5] <= p_bytes[15:8];
                    tx_frame[6] <= p_bytes[23:16]; tx_frame[7] <= p_bytes[31:24];
                    tx_frame[8] <= xor32[7:0]; tx_frame[9] <= xor32[15:8];
                    tx_frame[10] <= xor32[23:16]; tx_frame[11] <= xor32[31:24];
                    tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA6
                        ^ {calib50, p_busy, p_under, p_berr, p_rerr, 3'd0}
                        ^ p_bytes[7:0] ^ p_bytes[15:8] ^ p_bytes[23:16] ^ p_bytes[31:24]
                        ^ xor32[7:0] ^ xor32[15:8] ^ xor32[23:16] ^ xor32[31:24];
                    tx_start <= 1'b1;
                    pend_p <= 1'b0;
                end else if (cmd_tstat) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h90;
                    tx_frame[2] <= {t_pass50, t_busy50, calib50, t_done50, 4'd0};
                    tx_frame[3] <= t_phase;
                    tx_frame[4] <= t_cases[7:0]; tx_frame[5] <= t_cases[15:8];
                    tx_frame[6] <= t_cases[23:16]; tx_frame[7] <= t_cases[31:24];
                    for (fi = 8; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h90 ^ {t_pass50, t_busy50, calib50, t_done50, 4'd0} ^ t_phase
                        ^ t_cases[7:0] ^ t_cases[15:8] ^ t_cases[23:16] ^ t_cases[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_tfold) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h91;
                    tx_frame[2] <= t_xor[7:0]; tx_frame[3] <= t_xor[15:8];
                    tx_frame[4] <= t_xor[23:16]; tx_frame[5] <= t_xor[31:24];
                    tx_frame[6] <= t_add[7:0]; tx_frame[7] <= t_add[15:8];
                    tx_frame[8] <= t_add[23:16]; tx_frame[9] <= t_add[31:24];
                    tx_frame[10] <= t_macs[7:0]; tx_frame[11] <= t_macs[15:8];
                    tx_frame[12] <= t_macs[23:16]; tx_frame[13] <= t_macs[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'h91
                        ^ t_xor[7:0] ^ t_xor[15:8] ^ t_xor[23:16] ^ t_xor[31:24]
                        ^ t_add[7:0] ^ t_add[15:8] ^ t_add[23:16] ^ t_add[31:24]
                        ^ t_macs[7:0] ^ t_macs[15:8] ^ t_macs[23:16] ^ t_macs[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_tcnt) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h92;
                    tx_frame[2] <= t_cyc[7:0]; tx_frame[3] <= t_cyc[15:8];
                    tx_frame[4] <= t_cyc[23:16]; tx_frame[5] <= t_cyc[31:24];
                    tx_frame[6] <= t_stalls[7:0]; tx_frame[7] <= t_stalls[15:8];
                    tx_frame[8] <= t_stalls[23:16]; tx_frame[9] <= t_stalls[31:24];
                    tx_frame[10] <= t_haz[7:0]; tx_frame[11] <= t_haz[15:8];
                    tx_frame[12] <= t_haz[23:16]; tx_frame[13] <= t_haz[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'h92
                        ^ t_cyc[7:0] ^ t_cyc[15:8] ^ t_cyc[23:16] ^ t_cyc[31:24]
                        ^ t_stalls[7:0] ^ t_stalls[15:8] ^ t_stalls[23:16] ^ t_stalls[31:24]
                        ^ t_haz[7:0] ^ t_haz[15:8] ^ t_haz[23:16] ^ t_haz[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_tcnt2) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h94;
                    tx_frame[2] <= t_unders[7:0]; tx_frame[3] <= t_unders[15:8];
                    tx_frame[4] <= t_unders[23:16]; tx_frame[5] <= t_unders[31:24];
                    tx_frame[6] <= t_bhaz[7:0]; tx_frame[7] <= t_bhaz[15:8];
                    tx_frame[8] <= t_berrs[7:0]; tx_frame[9] <= t_rerrs[7:0];
                    tx_frame[10] <= t_swaps[7:0]; tx_frame[11] <= t_swaps[15:8];
                    tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h94
                        ^ t_unders[7:0] ^ t_unders[15:8] ^ t_unders[23:16] ^ t_unders[31:24]
                        ^ t_bhaz[7:0] ^ t_bhaz[15:8]
                        ^ t_berrs[7:0] ^ t_rerrs[7:0]
                        ^ t_swaps[7:0] ^ t_swaps[15:8];
                    tx_start <= 1'b1;
                end else if (cmd_tovl) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h95;
                    tx_frame[2] <= t_ovl[7:0]; tx_frame[3] <= t_ovl[15:8];
                    tx_frame[4] <= t_ovl[23:16]; tx_frame[5] <= t_ovl[31:24];
                    tx_frame[6] <= t_ntile[7:0]; tx_frame[7] <= t_ntile[15:8];
                    for (fi = 8; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h95
                        ^ t_ovl[7:0] ^ t_ovl[15:8] ^ t_ovl[23:16] ^ t_ovl[31:24]
                        ^ t_ntile[7:0] ^ t_ntile[15:8];
                    tx_start <= 1'b1;
                end else if (cmd_tpsum) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'h93;
                    tx_frame[2] <= t_psum[7:0]; tx_frame[3] <= t_psum[15:8];
                    tx_frame[4] <= t_psum[23:16]; tx_frame[5] <= t_psum[31:24];
                    for (fi = 6; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h93
                        ^ t_psum[7:0] ^ t_psum[15:8] ^ t_psum[23:16] ^ t_psum[31:24];
                    tx_start <= 1'b1;
                end
            end
        end
    end

    assign led[0] = calib;
    assign led[1] = busy || p_busy || t_busy;
    assign led[2] = (ce0 != 0) && (ce1 < ce0);
    assign led[3] = after_mode || sw_s[0];
endmodule
