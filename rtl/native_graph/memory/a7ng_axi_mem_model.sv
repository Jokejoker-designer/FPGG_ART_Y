// a7ng_axi_mem_model.sv — behavioral AXI4 128b slave for NG-03 XSim (not silicon MIG)
`timescale 1ns / 1ps

module a7ng_axi_mem_model #(
  parameter int unsigned DEPTH_WORDS = 4096  // 128-bit words
) (
  input  logic         clk,
  input  logic         rst_n,
  // write
  input  logic [3:0]   s_axi_awid,
  input  logic [27:0]  s_axi_awaddr,
  input  logic [7:0]   s_axi_awlen,
  input  logic [2:0]   s_axi_awsize,
  input  logic [1:0]   s_axi_awburst,
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,
  input  logic [127:0] s_axi_wdata,
  input  logic [15:0]  s_axi_wstrb,
  input  logic         s_axi_wlast,
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,
  output logic [3:0]   s_axi_bid,
  output logic [1:0]   s_axi_bresp,
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,
  // read
  input  logic [3:0]   s_axi_arid,
  input  logic [27:0]  s_axi_araddr,
  input  logic [7:0]   s_axi_arlen,
  input  logic [2:0]   s_axi_arsize,
  input  logic [1:0]   s_axi_arburst,
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,
  output logic [3:0]   s_axi_rid,
  output logic [127:0] s_axi_rdata,
  output logic [1:0]   s_axi_rresp,
  output logic         s_axi_rlast,
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready
);
  import a7ng_pkg::*;

  logic [127:0] mem [DEPTH_WORDS];
  integer i;

  // Absolute 128b word index with region remap (node @0, prior @2048)
  function automatic int unsigned idx_of(input logic [27:0] a);
    logic [27:0] rel;
    if (a >= NG_DDR_INDEX_BASE) begin
      rel = a - NG_DDR_INDEX_BASE;
      return 6144 + int'(rel[27:4]);
    end
    if (a >= NG_DDR_EPISODE_BASE) begin
      rel = a - NG_DDR_EPISODE_BASE;
      return 4096 + int'(rel[27:4]);
    end
    if (a >= NG_DDR_PRIOR_BASE) begin
      rel = a - NG_DDR_PRIOR_BASE;
      return 2048 + int'(rel[27:4]);
    end
    rel = a - NG_DDR_NODE_BASE;
    return int'(rel[27:4]);
  endfunction

  initial begin
    for (i = 0; i < DEPTH_WORDS; i = i + 1)
      mem[i] = '0;
    for (i = 0; i < 2048; i = i + 1)
      mem[i] = {64'h0, 32'hA700_0000 + i[31:0], 32'(i)};
  end

  // simple single-beat R/W
  typedef enum logic [1:0] {RIDLE, RDATA} rst_t;
  typedef enum logic [1:0] {WIDLE, WDATA, WRESP} wst_t;
  rst_t rst;
  wst_t wst;
  logic [27:0] ar_a, aw_a;
  logic [3:0]  ar_id, aw_id;
  logic [7:0]  ar_left;

  assign s_axi_bresp = 2'b00;
  assign s_axi_rresp = 2'b00;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst <= RIDLE; wst <= WIDLE;
      s_axi_arready <= 1'b1;
      s_axi_awready <= 1'b1;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rlast   <= 1'b0;
      s_axi_rdata   <= '0;
      s_axi_rid     <= '0;
      s_axi_bid     <= '0;
      ar_left <= '0;
    end else begin
      // READ
      unique case (rst)
        RIDLE: begin
          s_axi_arready <= 1'b1;
          s_axi_rvalid  <= 1'b0;
          s_axi_rlast   <= 1'b0;
          if (s_axi_arvalid && s_axi_arready) begin
            ar_a    <= s_axi_araddr;
            ar_id   <= s_axi_arid;
            ar_left <= s_axi_arlen;
            s_axi_arready <= 1'b0;
            rst <= RDATA;
          end
        end
        RDATA: begin
          s_axi_rvalid <= 1'b1;
          s_axi_rid    <= ar_id;
          if (idx_of(ar_a) < DEPTH_WORDS)
            s_axi_rdata <= mem[idx_of(ar_a)];
          else
            s_axi_rdata <= '0;
          s_axi_rlast <= (ar_left == 8'd0);
          if (s_axi_rvalid && s_axi_rready) begin
            if (ar_left == 8'd0) begin
              s_axi_rvalid <= 1'b0;
              s_axi_rlast  <= 1'b0;
              rst <= RIDLE;
            end else begin
              ar_left <= ar_left - 8'd1;
              ar_a    <= ar_a + 28'd16;
            end
          end
        end
        default: rst <= RIDLE;
      endcase

      // WRITE
      unique case (wst)
        WIDLE: begin
          s_axi_awready <= 1'b1;
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b0;
          if (s_axi_awvalid && s_axi_awready) begin
            aw_a  <= s_axi_awaddr;
            aw_id <= s_axi_awid;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b1;
            wst <= WDATA;
          end
        end
        WDATA: if (s_axi_wvalid && s_axi_wready) begin
          if (idx_of(aw_a) < DEPTH_WORDS)
            mem[idx_of(aw_a)] <= s_axi_wdata;
          if (s_axi_wlast) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b1;
            s_axi_bid    <= aw_id;
            wst <= WRESP;
          end else
            aw_a <= aw_a + 28'd16;
        end
        WRESP: if (s_axi_bvalid && s_axi_bready) begin
          s_axi_bvalid <= 1'b0;
          wst <= WIDLE;
        end
        default: wst <= WIDLE;
      endcase
    end
  end
endmodule
