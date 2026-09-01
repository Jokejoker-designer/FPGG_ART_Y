// TB-only AXI4 128b slave for persist region. Not silicon. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_persist_axi_mem #(
  parameter logic [27:0] BASE = 28'h0300_0000
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [3:0]   stall_aw_i,
  input  logic [3:0]   stall_w_i,
  input  logic [3:0]   stall_ar_i,
  input  logic [3:0]   stall_r_i,
  input  logic [3:0]   stall_b_i,
  input  logic         inj_bresp_i,
  input  logic         inj_rresp_i,
  input  logic         inj_no_rlast_i,
  output logic         saw_bresp_err_o,
  output logic         saw_rresp_err_o,
  output logic         saw_no_rlast_o,
  output logic [31:0]  aw_count_o,
  output logic [31:0]  ar_count_o,
  output logic         region_violation_o,
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
  logic [127:0] mem [0:31];
  integer i, j;
  logic [4:0] aw_idx, ar_idx;
  logic [3:0] awid_h, arid_h;
  logic [127:0] rbuf, wbuf;
  logic [3:0] st_aw, st_w, st_ar, st_r, st_b;
  logic inj_b, inj_r, inj_nl;
  typedef enum logic [1:0] {WIDLE, WDATA, WRESP} wst_t;
  typedef enum logic [1:0] {RIDLE, RDATA} rst_t;
  wst_t wst;
  rst_t rst;

  function automatic logic [4:0] idx_of(input logic [27:0] a);
    return a[8:4];
  endfunction
  function automatic logic in_reg(input logic [27:0] a);
    return (a >= BASE) && (a < (BASE + 28'h0000_0200)) && (a[3:0] == 4'd0);
  endfunction

  initial begin
    for (i = 0; i < 32; i = i + 1) mem[i] = '0;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wst <= WIDLE; rst <= RIDLE;
      s_axi_awready <= 1'b0; s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0; s_axi_bresp <= 2'b00; s_axi_bid <= '0;
      s_axi_arready <= 1'b0; s_axi_rvalid <= 1'b0; s_axi_rlast <= 1'b0;
      s_axi_rdata <= '0; s_axi_rid <= '0; s_axi_rresp <= 2'b00;
      st_aw <= '0; st_w <= '0; st_ar <= '0; st_r <= '0; st_b <= '0;
      inj_b <= 1'b0; inj_r <= 1'b0; inj_nl <= 1'b0;
      saw_bresp_err_o <= 1'b0; saw_rresp_err_o <= 1'b0; saw_no_rlast_o <= 1'b0;
      aw_count_o <= '0; ar_count_o <= '0; region_violation_o <= 1'b0;
      for (j = 0; j < 32; j = j + 1) mem[j] <= '0;
    end else begin
      if (inj_bresp_i) inj_b <= 1'b1;
      if (inj_rresp_i) inj_r <= 1'b1;
      if (inj_no_rlast_i) inj_nl <= 1'b1;

      unique case (wst)
        WIDLE: begin
          s_axi_bvalid <= 1'b0;
          if (st_aw < stall_aw_i) begin
            s_axi_awready <= 1'b0;
            st_aw <= st_aw + 4'd1;
          end else begin
            s_axi_awready <= 1'b1;
            if (s_axi_awvalid && s_axi_awready) begin
              if (!in_reg(s_axi_awaddr)) region_violation_o <= 1'b1;
              aw_idx <= idx_of(s_axi_awaddr);
              awid_h <= s_axi_awid;
              aw_count_o <= aw_count_o + 32'd1;
              s_axi_awready <= 1'b0;
              st_aw <= '0; st_w <= '0;
              wst <= WDATA;
            end
          end
        end
        WDATA: begin
          if (st_w < stall_w_i) begin
            s_axi_wready <= 1'b0;
            st_w <= st_w + 4'd1;
          end else begin
            s_axi_wready <= 1'b1;
            if (s_axi_wvalid && s_axi_wready) begin
              mem[aw_idx] <= s_axi_wdata;
              wbuf <= s_axi_wdata;
              s_axi_wready <= 1'b0;
              st_w <= '0; st_b <= '0;
              wst <= WRESP;
            end
          end
        end
        WRESP: begin
          if (st_b < stall_b_i) begin
            s_axi_bvalid <= 1'b0;
            st_b <= st_b + 4'd1;
          end else begin
            s_axi_bvalid <= 1'b1;
            s_axi_bid    <= awid_h;
            if (inj_b) begin
              s_axi_bresp <= 2'b10;
              inj_b <= 1'b0;
              saw_bresp_err_o <= 1'b1;
            end else
              s_axi_bresp <= 2'b00;
            if (s_axi_bvalid && s_axi_bready) begin
              s_axi_bvalid <= 1'b0;
              st_b <= '0;
              wst <= WIDLE;
            end
          end
        end
        default: wst <= WIDLE;
      endcase

      unique case (rst)
        RIDLE: begin
          s_axi_rvalid <= 1'b0;
          s_axi_rlast  <= 1'b0;
          if (st_ar < stall_ar_i) begin
            s_axi_arready <= 1'b0;
            st_ar <= st_ar + 4'd1;
          end else begin
            s_axi_arready <= 1'b1;
            if (s_axi_arvalid && s_axi_arready) begin
              if (!in_reg(s_axi_araddr)) region_violation_o <= 1'b1;
              ar_idx <= idx_of(s_axi_araddr);
              arid_h <= s_axi_arid;
              rbuf <= mem[idx_of(s_axi_araddr)];
              ar_count_o <= ar_count_o + 32'd1;
              s_axi_arready <= 1'b0;
              st_ar <= '0; st_r <= '0;
              rst <= RDATA;
            end
          end
        end
        RDATA: begin
          if (st_r < stall_r_i) begin
            s_axi_rvalid <= 1'b0;
            st_r <= st_r + 4'd1;
          end else begin
            s_axi_rvalid <= 1'b1;
            s_axi_rid    <= arid_h;
            s_axi_rdata  <= rbuf;
            if (inj_r) begin
              s_axi_rresp <= 2'b10;
              inj_r <= 1'b0;
              saw_rresp_err_o <= 1'b1;
            end else
              s_axi_rresp <= 2'b00;
            if (inj_nl) begin
              s_axi_rlast <= 1'b0;
              inj_nl <= 1'b0;
              saw_no_rlast_o <= 1'b1;
            end else
              s_axi_rlast <= 1'b1;
            if (s_axi_rvalid && s_axi_rready) begin
              s_axi_rvalid <= 1'b0;
              s_axi_rlast  <= 1'b0;
              st_r <= '0;
              rst <= RIDLE;
            end
          end
        end
        default: rst <= RIDLE;
      endcase
    end
  end
endmodule
