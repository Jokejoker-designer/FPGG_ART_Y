`timescale 1ns / 1ps
// DDR boot: preload SOA id/cue/prior planes (Stage A pattern) before query.
import a7ng_pkg::*;

module a7ng_ddr_soa_boot #(
    parameter int N_CAND = 64
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_i,
    output logic        busy_o,
    output logic        done_o,
    output logic [3:0]  m_axi_awid,
    output logic [27:0] m_axi_awaddr,
    output logic [7:0]  m_axi_awlen,
    output logic [2:0]  m_axi_awsize,
    output logic [1:0]  m_axi_awburst,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,
    output logic [127:0] m_axi_wdata,
    output logic [15:0] m_axi_wstrb,
    output logic        m_axi_wlast,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,
    input  logic [3:0]  m_axi_bid,
    input  logic [1:0]  m_axi_bresp,
    input  logic        m_axi_bvalid,
    output logic        m_axi_bready
);
    typedef enum logic [2:0] {B_IDLE, B_SOA_ID, B_SOA_CUE, B_SOA_PRIOR, B_DONE} bst_t;
    bst_t st;
    logic [31:0] idx;
    logic [127:0] wbeat;
    integer pi, k;

    // Registered status (no combo decode into CDC synchronizers)
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        busy_o <= 1'b0;
        done_o <= 1'b0;
      end else begin
        busy_o <= (st != B_IDLE) && (st != B_DONE);
        done_o <= (st == B_DONE);
      end
    end
    assign m_axi_awid = 4'd0;
    assign m_axi_awlen = 8'd0;
    assign m_axi_awsize = 3'd4;
    assign m_axi_awburst = 2'b01;
    assign m_axi_wstrb = 16'hFFFF;
    assign m_axi_bready = 1'b1;

    function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
        logic [31:0] c32;
        c32 = 32'hDDFE_0000 + nid;
        return {c32, c32};
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= B_IDLE;
            idx <= 32'd0;
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_wlast <= 1'b0;
            m_axi_awaddr <= 28'd0;
            m_axi_wdata <= 128'd0;
        end else begin
            unique case (st)
                B_IDLE: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid <= 1'b0;
                    if (start_i) begin
                        idx <= 32'd0;
                        st <= B_SOA_ID;
                    end
                end
                B_SOA_ID: begin
                    wbeat = 128'd0;
                    for (k = 0; k < 4; k = k + 1) begin
                        pi = idx * 4 + k;
                        if (pi < N_CAND) wbeat[k*32 +: 32] = 32'(pi);
                    end
                    m_axi_awaddr <= NG_DDR_NODE_BASE + idx * 16;
                    m_axi_wdata <= wbeat;
                    m_axi_awvalid <= 1'b1;
                    m_axi_wvalid <= 1'b1;
                    m_axi_wlast <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        if (idx == ((N_CAND + 3) / 4) - 1) begin
                            idx <= 32'd0;
                            st <= B_SOA_CUE;
                        end else idx <= idx + 32'd1;
                    end
                end
                B_SOA_CUE: begin
                    wbeat = 128'd0;
                    for (k = 0; k < 2; k = k + 1) begin
                        pi = idx * 2 + k;
                        if (pi < N_CAND) wbeat[k*64 +: 64] = golden_cue64(32'(pi));
                    end
                    m_axi_awaddr <= NG_DDR_CUE64_BASE + idx * 16;
                    m_axi_wdata <= wbeat;
                    m_axi_awvalid <= 1'b1;
                    m_axi_wvalid <= 1'b1;
                    m_axi_wlast <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        if (idx == ((N_CAND + 1) / 2) - 1) begin
                            idx <= 32'd0;
                            st <= B_SOA_PRIOR;
                        end else idx <= idx + 32'd1;
                    end
                end
                B_SOA_PRIOR: begin
                    wbeat = 128'd0;
                    for (k = 0; k < 16; k = k + 1) begin
                        pi = idx * 16 + k;
                        if (pi < N_CAND) wbeat[k*8 +: 8] = 8'h03;
                    end
                    m_axi_awaddr <= NG_DDR_PRIOR_BASE + idx * 16;
                    m_axi_wdata <= wbeat;
                    m_axi_awvalid <= 1'b1;
                    m_axi_wvalid <= 1'b1;
                    m_axi_wlast <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        if (idx == ((N_CAND + 15) / 16) - 1)
                            st <= B_DONE;
                        else idx <= idx + 32'd1;
                    end
                end
                B_DONE: st <= B_DONE;
                default: st <= B_IDLE;
            endcase
        end
    end
endmodule
