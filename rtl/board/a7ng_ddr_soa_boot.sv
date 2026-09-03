`timescale 1ns / 1ps
// DDR boot: preload 16-byte AOS descriptors (id + cue64 + prior + pad).
// Gate: AOS-STREAM-ONEOWNER-00. Same golden content as former 3-plane SOA.
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
    typedef enum logic [1:0] {B_IDLE, B_WRITE, B_DONE} bst_t;
    bst_t st;
    logic [31:0] idx;

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

    function automatic logic [127:0] pack_desc(input logic [31:0] nid);
        logic [127:0] b;
        b = '0;
        b[31:0]    = nid;
        b[95:32]   = golden_cue64(nid);
        b[103:96]  = 8'h03;
        return b;
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
                        st <= B_WRITE;
                    end
                end
                B_WRITE: begin
                    m_axi_awaddr <= NG_DDR_NODE_BASE + {idx[23:0], 4'b0000};
                    m_axi_wdata <= pack_desc(idx);
                    m_axi_awvalid <= 1'b1;
                    m_axi_wvalid <= 1'b1;
                    m_axi_wlast <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        if (idx == 32'(N_CAND - 1))
                            st <= B_DONE;
                        else
                            idx <= idx + 32'd1;
                    end
                end
                B_DONE: st <= B_DONE;
                default: st <= B_IDLE;
            endcase
        end
    end
endmodule
