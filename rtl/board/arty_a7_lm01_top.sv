`timescale 1ns/1ps
module arty_a7_lm01_top (
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
    logic ui_clk, ui_rst, calib, mig_mmcm;
    logic [3:0] sw_s;
    logic rx_valid;
    logic [7:0] rx_data;
    logic start_bist, start_meta, start_ui, start_ui_q;
    logic [2:0] mode;
    logic [31:0] nbytes;
    logic busy, done, pass;
    logic calib_s, busy_s, pass_s, done_s, done_s_q;
    logic [7:0] phase;
    logic [31:0] err_count;
    logic [63:0] wr_bytes, rd_bytes, wr_cyc, rd_cyc;
    logic tx_start, tx_busy;
    logic [7:0] tx_frame [0:14];
    integer fi;
    logic [23:0] mig_rst_hold;
    logic mig_rst_n;
    logic cmd_srst;
    logic sw0_q;

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
        .sys_clk_i(clk166), .clk_ref_i(clk200), .sys_rst_n(mig_rst_n),
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

    logic ui_rst_n;
    assign ui_rst_n = ~ui_rst;

    ddr_bist u_bist (
        .clk(ui_clk), .rst_n(ui_rst_n && calib),
        .start(start_ui), .mode(mode), .nbytes(nbytes),
        .busy(busy), .done(done), .pass(pass), .phase(phase),
        .err_count(err_count),
        .wr_bytes(wr_bytes), .rd_bytes(rd_bytes),
        .wr_cycles(wr_cyc), .rd_cycles(rd_cyc),
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

    sync_bits #(.WIDTH(4)) u_ui_stat (
        .clk(CLK100MHZ), .rst_n(rst100_n),
        .async_in({pass, busy, calib, done}),
        .sync_out({pass_s, busy_s, calib_s, done_s})
    );

    assign mig_rst_n = rst100_n && (mig_rst_hold == 24'd0);
    // While sys_rst is held, ui_clk may stop and freeze init_calib_complete=1.
    // Report "not ready" for the whole hold so the host can observe 0→1.
    wire calib_vis = calib_s && mig_rst_n;

    // CDC start: 100 MHz -> ui_clk. Clear only on rising done (ST_DONE is sticky).
    always_ff @(posedge CLK100MHZ) begin
        if (!rst100_n) begin
            start_meta <= 1'b0;
            done_s_q <= 1'b0;
        end else begin
            done_s_q <= done_s;
            if (start_bist) start_meta <= 1'b1;
            else if ((done_s && !done_s_q) || !mig_rst_n) start_meta <= 1'b0;
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

    logic collecting;
    logic [3:0] idx;
    logic [7:0] buf_b [0:14];
    logic [7:0] run_xor;
    logic cmd_stat, cmd_cnt, cmd_wrc;

    always_ff @(posedge CLK100MHZ) begin
        if (!rst100_n) begin
            collecting <= 1'b0;
            idx <= 4'd0;
            run_xor <= 8'd0;
            start_bist <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_cnt <= 1'b0;
            cmd_wrc <= 1'b0;
            cmd_srst <= 1'b0;
            mode <= 3'd0;
            nbytes <= 32'h0010_0000; // 1 MB default bring-up
            tx_start <= 1'b0;
            sw0_q <= 1'b0;
            mig_rst_hold <= 24'd10_000_000; // 100 ms after MMCM lock / UART 0x16
        end else begin
            start_bist <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_cnt <= 1'b0;
            cmd_wrc <= 1'b0;
            cmd_srst <= 1'b0;
            tx_start <= 1'b0;
            sw0_q <= sw_s[0];
            if (mig_rst_hold != 24'd0)
                mig_rst_hold <= mig_rst_hold - 24'd1;
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
                            if (buf_b[2] == 8'h13) begin
                                start_bist <= 1'b1;
                                mode <= buf_b[3][2:0];
                                unique case (buf_b[4])
                                    8'd0: nbytes <= 32'h0010_0000;
                                    8'd1: nbytes <= 32'h0100_0000;
                                    8'd2: nbytes <= 32'h1000_0000;
                                    default: nbytes <= 32'h0010_0000;
                                endcase
                            end
                            if (buf_b[2] == 8'h14) cmd_stat <= 1'b1;
                            if (buf_b[2] == 8'h15) cmd_cnt <= 1'b1;
                            if (buf_b[2] == 8'h16) begin
                                cmd_srst <= 1'b1;
                                mig_rst_hold <= 24'd10_000_000;
                            end
                            if (buf_b[2] == 8'h17) cmd_wrc <= 1'b1;
                        end
                    end else
                        idx <= idx + 4'd1;
                end
            end
            if (!tx_busy && !tx_start) begin
                if (cmd_stat || sw_s[1]) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h81;
                    tx_frame[2] <= {5'd0, pass_s, busy_s, calib_vis};
                    tx_frame[3] <= phase;
                    tx_frame[4] <= err_count[7:0];
                    tx_frame[5] <= err_count[15:8];
                    tx_frame[6] <= err_count[23:16];
                    tx_frame[7] <= err_count[31:24];
                    for (fi = 8; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h81 ^ {5'd0, pass_s, busy_s, calib_vis} ^ phase
                        ^ err_count[7:0] ^ err_count[15:8] ^ err_count[23:16] ^ err_count[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_cnt) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h82;
                    tx_frame[2] <= rd_bytes[7:0];
                    tx_frame[3] <= rd_bytes[15:8];
                    tx_frame[4] <= rd_bytes[23:16];
                    tx_frame[5] <= rd_bytes[31:24];
                    tx_frame[6] <= rd_cyc[7:0];
                    tx_frame[7] <= rd_cyc[15:8];
                    tx_frame[8] <= rd_cyc[23:16];
                    tx_frame[9] <= rd_cyc[31:24];
                    tx_frame[10] <= wr_bytes[7:0];
                    tx_frame[11] <= wr_bytes[15:8];
                    tx_frame[12] <= wr_bytes[23:16];
                    tx_frame[13] <= wr_bytes[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'h82
                        ^ rd_bytes[7:0] ^ rd_bytes[15:8] ^ rd_bytes[23:16] ^ rd_bytes[31:24]
                        ^ rd_cyc[7:0] ^ rd_cyc[15:8] ^ rd_cyc[23:16] ^ rd_cyc[31:24]
                        ^ wr_bytes[7:0] ^ wr_bytes[15:8] ^ wr_bytes[23:16] ^ wr_bytes[31:24];
                    tx_start <= 1'b1;
                end else if (cmd_wrc) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h84;
                    tx_frame[2] <= wr_cyc[7:0];
                    tx_frame[3] <= wr_cyc[15:8];
                    tx_frame[4] <= wr_cyc[23:16];
                    tx_frame[5] <= wr_cyc[31:24];
                    tx_frame[6] <= wr_bytes[7:0];
                    tx_frame[7] <= wr_bytes[15:8];
                    tx_frame[8] <= wr_bytes[23:16];
                    tx_frame[9] <= wr_bytes[31:24];
                    for (fi = 10; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'h84
                        ^ wr_cyc[7:0] ^ wr_cyc[15:8] ^ wr_cyc[23:16] ^ wr_cyc[31:24]
                        ^ wr_bytes[7:0] ^ wr_bytes[15:8] ^ wr_bytes[23:16] ^ wr_bytes[31:24];
                    tx_start <= 1'b1;
                end
            end
            if (sw_s[0] && !sw0_q && calib_s && !busy_s)
                start_bist <= 1'b1;
        end
    end

    assign led[0] = calib_vis;
    assign led[1] = busy_s;
    assign led[2] = pass_s;
    assign led[3] = |err_count;
endmodule
