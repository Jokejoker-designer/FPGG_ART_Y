`timescale 1ns/1ps
// AXI4 master: 128-bit beats, INCR. 256/16/8-beat bursts.
module ddr_tile_dma (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         go,
    input  logic         wr,
    input  logic [27:0]  addr,
    input  logic [31:0]  bytes,
    output logic         busy,
    output logic         done,
    output logic         underflow,
    output logic         axi_berr,
    output logic         axi_rerr,
    input  logic         w_valid,
    output logic         w_ready,
    input  logic [127:0] w_data,
    output logic         r_valid,
    input  logic         r_ready,
    output logic [127:0] r_data,
    output logic [3:0]   m_axi_awid,
    output logic [27:0]  m_axi_awaddr,
    output logic [7:0]   m_axi_awlen,
    output logic [2:0]   m_axi_awsize,
    output logic [1:0]   m_axi_awburst,
    output logic         m_axi_awvalid,
    input  logic         m_axi_awready,
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
    typedef enum logic [2:0] {IDLE, AW, W, B, AR, R, DONE} st_t;
    st_t st;
    logic [27:0] a;
    logic [31:0] left;
    logic [8:0]  beat, last_beat;
    logic [7:0]  blen;
    logic        is_wr;

    assign m_axi_awid = 4'd0;
    assign m_axi_arid = 4'd0;
    assign m_axi_awsize = 3'd4;
    assign m_axi_arsize = 3'd4;
    assign m_axi_awburst = 2'b01;
    assign m_axi_arburst = 2'b01;
    assign m_axi_wstrb = 16'hFFFF;
    assign m_axi_bready = 1'b1;
    assign m_axi_awaddr = a;
    assign m_axi_araddr = a;
    assign m_axi_awlen = blen;
    assign m_axi_arlen = blen;
    assign m_axi_wdata = w_data;
    assign r_data = m_axi_rdata;
    assign busy = (st != IDLE) && (st != DONE);
    assign w_ready = (st == W) && m_axi_wready;
    assign r_valid = (st == R) && m_axi_rvalid;
    assign m_axi_rready = (st == R) && r_ready;
    assign m_axi_wvalid = (st == W) && w_valid;
    assign m_axi_wlast = (st == W) && (beat == last_beat);

    function automatic void pick_burst(input [31:0] rem, output [7:0] len, output [8:0] last);
        begin
            if (rem >= 32'd4096) begin len = 8'd255; last = 9'd255; end
            else if (rem >= 32'd256) begin len = 8'd15; last = 9'd15; end
            else begin len = 8'd7; last = 9'd7; end
        end
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= IDLE;
            a <= 28'd0;
            left <= 32'd0;
            beat <= 9'd0;
            last_beat <= 9'd0;
            blen <= 8'd0;
            is_wr <= 1'b0;
            m_axi_awvalid <= 1'b0;
            m_axi_arvalid <= 1'b0;
            done <= 1'b0;
            underflow <= 1'b0;
            axi_berr <= 1'b0;
            axi_rerr <= 1'b0;
        end else begin
            done <= 1'b0;
            axi_berr <= 1'b0;
            axi_rerr <= 1'b0;
            unique case (st)
                IDLE: if (go) begin
                    a <= addr;
                    left <= (bytes < 32'd128) ? 32'd128 : bytes;
                    is_wr <= wr;
                    underflow <= 1'b0;
                    pick_burst((bytes < 32'd128) ? 32'd128 : bytes, blen, last_beat);
                    beat <= 9'd0;
                    st <= wr ? AW : AR;
                end
                AW: begin
                    m_axi_awvalid <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        beat <= 9'd0;
                        st <= W;
                    end
                end
                W: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        if (beat == last_beat) st <= B;
                        else beat <= beat + 9'd1;
                    end else if (!w_valid)
                        underflow <= 1'b1;
                end
                B: if (m_axi_bvalid) begin
                    if (m_axi_bresp != 2'b00) axi_berr <= 1'b1;
                    if (left > ({23'd0, last_beat} + 32'd1) * 32'd16) begin
                        left <= left - ({23'd0, last_beat} + 32'd1) * 32'd16;
                        a <= a + ({19'd0, last_beat} + 28'd1) * 28'd16;
                        pick_burst(left - ({23'd0, last_beat} + 32'd1) * 32'd16, blen, last_beat);
                        st <= AW;
                    end else st <= DONE;
                end
                AR: begin
                    m_axi_arvalid <= 1'b1;
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        beat <= 9'd0;
                        st <= R;
                    end
                end
                R: if (m_axi_rvalid && m_axi_rready) begin
                    if (m_axi_rresp != 2'b00) axi_rerr <= 1'b1;
                    if (m_axi_rlast) begin
                        if (left > ({23'd0, last_beat} + 32'd1) * 32'd16) begin
                            left <= left - ({23'd0, last_beat} + 32'd1) * 32'd16;
                            a <= a + ({19'd0, last_beat} + 28'd1) * 28'd16;
                            pick_burst(left - ({23'd0, last_beat} + 32'd1) * 32'd16, blen, last_beat);
                            st <= AR;
                        end else st <= DONE;
                    end else beat <= beat + 9'd1;
                end
                DONE: begin
                    done <= 1'b1;
                    st <= IDLE;
                end
                default: st <= IDLE;
            endcase
        end
    end
endmodule
