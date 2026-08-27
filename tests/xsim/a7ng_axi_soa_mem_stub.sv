// Behavioral AXI4 slave for SOA (no MIG). Multi-beat + outstanding AR (smoke-law read path).
`timescale 1ns / 1ps

module a7ng_axi_soa_mem_stub #(
  parameter int unsigned DEPTH_WORDS = 4096
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [3:0]  s_axi_awid,
  input  logic [27:0] s_axi_awaddr,
  input  logic [7:0]  s_axi_awlen,
  input  logic [2:0]  s_axi_awsize,
  input  logic [1:0]  s_axi_awburst,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  input  logic [127:0] s_axi_wdata,
  input  logic [15:0]  s_axi_wstrb,
  input  logic        s_axi_wlast,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  output logic [3:0]  s_axi_bid,
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  input  logic [3:0]  s_axi_arid,
  input  logic [27:0] s_axi_araddr,
  input  logic [7:0]  s_axi_arlen,
  input  logic [2:0]  s_axi_arsize,
  input  logic [1:0]  s_axi_arburst,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  output logic [3:0]  s_axi_rid,
  output logic [127:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rlast,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready
);
  import a7ng_pkg::*;

  logic [127:0] mem [DEPTH_WORDS];

  function automatic int unsigned idx_of(input logic [27:0] a);
    logic [27:0] rel;
    if (a >= NG_DDR_PRIOR_BASE) begin
      rel = a - NG_DDR_PRIOR_BASE;
      return 2048 + int'(rel[27:4]);
    end
    if (a >= NG_DDR_CUE64_BASE) begin
      rel = a - NG_DDR_CUE64_BASE;
      return 1024 + int'(rel[27:4]);
    end
    if (a >= NG_DDR_NODE_BASE) begin
      rel = a - NG_DDR_NODE_BASE;
      return int'(rel[27:4]);
    end
    return int'(a >> 4);
  endfunction

  localparam int unsigned QD = 8;
  logic [27:0] q_addr [QD];
  logic [7:0]  q_len  [QD];
  logic [3:0]  q_id   [QD];
  logic [3:0]  q_wr, q_rd, q_cnt;

  logic        streaming;
  logic [27:0] cur_a;
  logic [7:0]  cur_l;
  logic [3:0]  cur_id;

  assign s_axi_arready = (q_cnt < QD[3:0]);
  assign s_axi_rvalid  = streaming;
  assign s_axi_rdata   = (idx_of(cur_a) < DEPTH_WORDS) ? mem[idx_of(cur_a)] : '0;
  assign s_axi_rlast   = streaming && (cur_l == 8'd0);
  assign s_axi_rid     = cur_id;
  assign s_axi_rresp   = 2'b00;
  assign s_axi_bresp   = 2'b00;

  wire do_ar = s_axi_arvalid && s_axi_arready;
  wire do_r  = s_axi_rvalid && s_axi_rready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q_wr <= '0; q_rd <= '0; q_cnt <= '0;
      streaming <= 1'b0; cur_a <= '0; cur_l <= '0; cur_id <= '0;
    end else begin
      automatic logic [3:0] wr, rd, cn;
      automatic logic       st;
      wr = q_wr; rd = q_rd; cn = q_cnt; st = streaming;

      if (st && do_r) begin
        if (cur_l == 8'd0)
          st = 1'b0;
        else begin
          cur_l <= cur_l - 8'd1;
          cur_a <= cur_a + 28'd16;
        end
      end

      if (!st && (cn != 4'd0)) begin
        cur_a  <= q_addr[rd[2:0]];
        cur_l  <= q_len[rd[2:0]];
        cur_id <= q_id[rd[2:0]];
        rd     = rd + 4'd1;
        cn     = cn - 4'd1;
        st     = 1'b1;
      end

      if (do_ar) begin
        q_addr[wr[2:0]] <= s_axi_araddr;
        q_len[wr[2:0]]  <= s_axi_arlen;
        q_id[wr[2:0]]   <= s_axi_arid;
        wr = wr + 4'd1;
        cn = cn + 4'd1;
      end

      q_wr <= wr; q_rd <= rd; q_cnt <= cn;
      streaming <= st;
    end
  end

  typedef enum logic [1:0] {WIDLE, WDATA, WRESP} wst_t;
  wst_t wst;
  logic [27:0] aw_a;
  logic [3:0]  aw_id_r;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wst <= WIDLE;
      s_axi_awready <= 1'b1;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bid     <= '0;
      aw_a <= '0;
      aw_id_r <= '0;
    end else begin
      unique case (wst)
        WIDLE: begin
          s_axi_awready <= 1'b1;
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b0;
          if (s_axi_awvalid && s_axi_awready) begin
            aw_a      <= s_axi_awaddr;
            aw_id_r   <= s_axi_awid;
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
            s_axi_bid    <= aw_id_r;
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

  task automatic poke128(input logic [27:0] byte_addr, input logic [127:0] data);
    int unsigned ix;
    ix = idx_of(byte_addr);
    if (ix < DEPTH_WORDS)
      mem[ix] = data;
  endtask
endmodule
