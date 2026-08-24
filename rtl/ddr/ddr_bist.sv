`timescale 1ns/1ps
// AXI4 master BIST for official Digilent AXI MIG (128-bit, 28-bit addr).
module ddr_bist (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [2:0] mode,   // 0=all, 1=walk, 2=addr, 3=prbs, 4=seq_bw, 5=rand, 6=bound
    input  logic [31:0] nbytes, // bytes to cover (multiple of 256)
    output logic busy,
    output logic done,
    output logic pass,
    output logic [7:0] phase,
    output logic [31:0] err_count,
    output logic [63:0] wr_bytes,
    output logic [63:0] rd_bytes,
    output logic [63:0] wr_cycles,
    output logic [63:0] rd_cycles,
    // AXI4
    output logic [3:0]  m_axi_awid,
    output logic [27:0] m_axi_awaddr,
    output logic [7:0]  m_axi_awlen,
    output logic [2:0]  m_axi_awsize,
    output logic [1:0]  m_axi_awburst,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,
    output logic [127:0] m_axi_wdata,
    output logic [15:0]  m_axi_wstrb,
    output logic         m_axi_wlast,
    output logic         m_axi_wvalid,
    input  logic         m_axi_wready,
    input  logic [3:0]   m_axi_bid,
    input  logic [1:0]   m_axi_bresp,
    input  logic         m_axi_bvalid,
    output logic         m_axi_bready,
    output logic [3:0]   m_axi_arid,
    output logic [27:0]  m_axi_araddr,
    output logic [7:0]   m_axi_arlen,
    output logic [2:0]   m_axi_arsize,
    output logic [1:0]   m_axi_arburst,
    output logic         m_axi_arvalid,
    input  logic         m_axi_arready,
    input  logic [3:0]   m_axi_rid,
    input  logic [127:0] m_axi_rdata,
    input  logic [1:0]   m_axi_rresp,
    input  logic         m_axi_rlast,
    input  logic         m_axi_rvalid,
    output logic         m_axi_rready
);
    typedef enum logic [3:0] {
        ST_IDLE, ST_ISSUE_AW, ST_WR, ST_B, ST_ISSUE_AR, ST_RD, ST_NEXT, ST_DONE
    } st_t;
    st_t st;
    logic [27:0] addr;
    logic [31:0] left;
    logic [8:0]  beat;
    logic [7:0]  burst_len;
    logic [31:0] burst_bytes;
    logic [8:0]  last_beat;
    logic [2:0]  tkind; // 0 walk1 1 walk0 2 addr 3 prbs 4 seq 5 rand 6 bound
    logic [2:0]  tkind_last;
    logic [31:0] prbs;
    logic [31:0] burst_seed;
    logic [31:0] rd_prbs;
    logic wr_act, rd_act, wr_b, rd_b, err_i;
    logic [127:0] expect_q;

    function automatic [31:0] prbs_next(input [31:0] p);
        return {p[30:0], p[31] ^ p[21] ^ p[1] ^ p[0]};
    endfunction

    function automatic [127:0] pat(input [2:0] k, input [27:0] a, input [4:0] b, input [31:0] p);
        logic [127:0] r;
        begin
            unique case (k)
                3'd0: r = 128'h1 << (b % 128);
                3'd1: r = ~(128'h1 << (b % 128));
                3'd2: r = {4{a + {23'd0, b, 4'd0}}};
                3'd3: r = {p, p, p ^ 32'hA5A5_5A5A, p + a};
                3'd4: r = {4{32'hC001_D00D ^ a ^ {27'd0, b}}};
                3'd5: r = {p, ~p, a, p ^ a};
                default: r = {4{a}};
            endcase
            return r;
        end
    endfunction

    // tkind 4 (seq BW): 256-beat INCR amortizes MIG read latency → ≥0.85 GB/s.
    // Other kinds stay 16-beat / 256 B for dense pattern coverage.
    assign burst_len   = (tkind == 3'd4) ? 8'd255 : 8'd15;
    assign last_beat   = (tkind == 3'd4) ? 9'd255 : 9'd15;
    assign burst_bytes = (tkind == 3'd4) ? 32'd4096 : 32'd256;

    assign m_axi_awid = 4'd0;
    assign m_axi_awlen = burst_len;
    assign m_axi_awsize = 3'd4;
    assign m_axi_awburst = 2'b01;
    assign m_axi_wstrb = 16'hFFFF;
    assign m_axi_arid = 4'd0;
    assign m_axi_arlen = burst_len;
    assign m_axi_arsize = 3'd4;
    assign m_axi_arburst = 2'b01;
    assign m_axi_bready = 1'b1;
    assign m_axi_awaddr = addr;
    assign m_axi_araddr = addr;

    ddr_perf_counters u_cnt (
        .clk(clk), .rst_n(rst_n), .clr(start),
        .wr_beat(wr_b), .rd_beat(rd_b), .err_inc(err_i),
        .wr_bytes(wr_bytes), .rd_bytes(rd_bytes),
        .wr_cycles(wr_cycles), .rd_cycles(rd_cycles),
        .err_count(err_count),
        .wr_active(wr_act), .rd_active(rd_act)
    );

    assign busy = (st != ST_IDLE) && (st != ST_DONE);
    assign phase = {1'b0, tkind, st};
    assign pass = (st == ST_DONE) && (err_count == 32'd0);
    assign done = (st == ST_DONE);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= ST_IDLE;
            addr <= 28'd0;
            left <= 32'd0;
            beat <= 5'd0;
            tkind <= 3'd0;
            tkind_last <= 3'd0;
            prbs <= 32'hACE1_ACE1;
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_wlast <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            m_axi_wdata <= 128'd0;
            wr_act <= 1'b0;
            rd_act <= 1'b0;
            wr_b <= 1'b0;
            rd_b <= 1'b0;
            err_i <= 1'b0;
            expect_q <= 128'd0;
        end else begin
            wr_b <= 1'b0;
            rd_b <= 1'b0;
            err_i <= 1'b0;
            unique case (st)
                ST_IDLE: begin
                    wr_act <= 1'b0;
                    rd_act <= 1'b0;
                    if (start) begin
                        addr <= 28'd0;
                        left <= (nbytes < 32'd256) ? 32'd256 : nbytes;
                        beat <= 9'd0;
                        tkind <= (mode == 3'd0) ? 3'd0 : (mode == 3'd1) ? 3'd0 : mode;
                        // mode 1 = walk1+walk0; mode 0 = all kinds 0..6
                        tkind_last <= (mode == 3'd0) ? 3'd6 : (mode == 3'd1) ? 3'd1 : mode;
                        prbs <= 32'hACE1_ACE1;
                        st <= ST_ISSUE_AW;
                    end
                end
                ST_ISSUE_AW: begin
                    m_axi_awvalid <= 1'b1;
                    wr_act <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        beat <= 9'd0;
                        burst_seed <= prbs;
                        m_axi_wdata <= pat(tkind, addr, 5'd0, prbs);
                        m_axi_wvalid <= 1'b1;
                        m_axi_wlast <= 1'b0;
                        st <= ST_WR;
                    end
                end
                ST_WR: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        wr_b <= 1'b1;
                        prbs <= prbs_next(prbs);
                        if (beat == last_beat) begin
                            m_axi_wvalid <= 1'b0;
                            m_axi_wlast <= 1'b0;
                            st <= ST_B;
                        end else begin
                            beat <= beat + 9'd1;
                            m_axi_wdata <= pat(tkind, addr, beat[4:0] + 5'd1, prbs_next(prbs));
                            m_axi_wlast <= (beat + 9'd1 == last_beat);
                        end
                    end
                end
                ST_B: begin
                    if (m_axi_bvalid) begin
                        if (m_axi_bresp != 2'b00) err_i <= 1'b1;
                        wr_act <= 1'b0;
                        st <= ST_ISSUE_AR;
                    end
                end
                ST_ISSUE_AR: begin
                    m_axi_arvalid <= 1'b1;
                    rd_act <= 1'b1;
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        beat <= 9'd0;
                        m_axi_rready <= 1'b1;
                        rd_prbs <= burst_seed;
                        expect_q <= pat(tkind, addr, 5'd0, burst_seed);
                        st <= ST_RD;
                    end
                end
                ST_RD: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        rd_b <= 1'b1;
                        if (m_axi_rdata !== expect_q || m_axi_rresp != 2'b00)
                            err_i <= 1'b1;
                        if (m_axi_rlast) begin
                            m_axi_rready <= 1'b0;
                            rd_act <= 1'b0;
                            st <= ST_NEXT;
                        end else begin
                            beat <= beat + 9'd1;
                            rd_prbs <= prbs_next(rd_prbs);
                            expect_q <= pat(tkind, addr, beat[4:0] + 5'd1, prbs_next(rd_prbs));
                        end
                    end
                end
                ST_NEXT: begin
                    if (left > burst_bytes) begin
                        left <= left - burst_bytes;
                        if (tkind == 3'd5)
                            addr <= {prbs[27:8], 8'd0};
                        else if (tkind == 3'd6)
                            addr <= addr + 28'h0000_4000; // 16 KB ~ row-ish step
                        else
                            addr <= addr + burst_bytes[27:0];
                        beat <= 9'd0;
                        st <= ST_ISSUE_AW;
                    end else if ((mode == 3'd0 || mode == 3'd1) && tkind < tkind_last) begin
                        tkind <= tkind + 3'd1;
                        addr <= 28'd0;
                        left <= (nbytes < 32'd256) ? 32'd256 : nbytes;
                        st <= ST_ISSUE_AW;
                    end else
                        st <= ST_DONE;
                end
                ST_DONE: begin
                    wr_act <= 1'b0;
                    rd_act <= 1'b0;
                    if (start) begin
                        addr <= 28'd0;
                        left <= (nbytes < 32'd256) ? 32'd256 : nbytes;
                        beat <= 9'd0;
                        tkind <= (mode == 3'd0) ? 3'd0 : (mode == 3'd1) ? 3'd0 : mode;
                        tkind_last <= (mode == 3'd0) ? 3'd6 : (mode == 3'd1) ? 3'd1 : mode;
                        prbs <= 32'hACE1_ACE1;
                        st <= ST_ISSUE_AW;
                    end
                end
                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
