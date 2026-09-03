// a7ng_persist_axi_bridge.sv — P2-MIG-PERSIST-CDC-CLOSURE-02
// FPGA-owned AXI4 persist master. CDC: request toggle + stable payload +
// ack toggle + ASYNC_REG 3-flop. Do not sample UI bits as combo on core.
// C7 ready only after BRESP==OKAY. Reload only after R/RLAST/RRESP OK.
// persist_gen_fast SHA unedited. MIG unedited. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_persist_axi_bridge #(
  parameter logic [27:0] BASE = 28'h0300_0000,
  parameter int unsigned MAX_RETRY = 3
) (
  input  logic         core_clk,
  input  logic         core_rst_n,
  input  logic         ddr_req_i,
  input  logic         ddr_we_i,
  input  logic [4:0]   ddr_addr_i,
  input  logic [63:0]  ddr_wdata_i,
  output logic [63:0]  ddr_rdata_o,
  output logic         ddr_ack_o,
  input  logic         freeze_i,
  input  logic         c7_valid_i,
  input  logic [31:0]  c7_addr_i,
  output logic         c7_ready_o,

  input  logic         ui_clk,
  input  logic         ui_rst_n,
  input  logic         grant_i,
  output logic         req_o,
  output logic         idle_o,

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
  output logic         m_axi_rready,

  output logic [31:0]  wr_ok_o,
  output logic [31:0]  wr_err_o,
  output logic [31:0]  rd_ok_o,
  output logic [31:0]  rd_err_o,
  output logic [31:0]  bytes_wr_o,
  output logic [31:0]  bytes_rd_o,
  output logic         region_err_o,
  output logic [15:0]  freeze_drop_o
);
  localparam logic [4:0] C7_SLOT = 5'd31;
  localparam logic [1:0] B_OK = 2'b00;
  localparam logic [1:0] R_OK = 2'b00;

  typedef enum logic [1:0] {K_NONE=2'd0, K_WR=2'd1, K_RD=2'd2, K_C7=2'd3} kind_t;
  typedef enum logic [2:0] {
    U_IDLE=3'd0, U_GRANT=3'd1, U_AW=3'd2, U_W=3'd3, U_B=3'd4, U_AR=3'd5, U_R=3'd6, U_DONE=3'd7
  } ust_t;

  function automatic logic [27:0] slot_addr(input logic [4:0] s);
    return BASE + {19'd0, s, 4'b0000};
  endfunction
  function automatic logic in_region(input logic [27:0] a);
    return (a >= BASE) && (a < (BASE + 28'h0000_0200));
  endfunction

  // Handshake nets declared before both domains.
  logic        req_tog;
  logic        rsp_tog;
  logic        rsp_ok;
  logic [63:0] rsp_rdata;

  // ---- core: capture + request toggle. Payload held until ACK completes. ----
  kind_t       c_kind;
  logic        c_busy, c_ack_pend;
  logic [4:0]  c_slot;
  logic [63:0] c_wdata;
  logic [15:0] fz_drop;
  logic        ok_c;
  logic [63:0] rdata_c;

  (* ASYNC_REG = "TRUE" *) logic rsp_s0, rsp_s1, rsp_s2;
  logic rsp_seen;

  assign freeze_drop_o = fz_drop;

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      c_kind <= K_NONE; c_busy <= 1'b0; c_slot <= '0; c_wdata <= '0;
      req_tog <= 1'b0; ddr_ack_o <= 1'b0; c7_ready_o <= 1'b0; c_ack_pend <= 1'b0;
      ddr_rdata_o <= '0; fz_drop <= '0; ok_c <= 1'b0; rdata_c <= '0;
      rsp_s0 <= 1'b0; rsp_s1 <= 1'b0; rsp_s2 <= 1'b0; rsp_seen <= 1'b0;
    end else begin
      rsp_s0 <= rsp_tog;
      rsp_s1 <= rsp_s0;
      rsp_s2 <= rsp_s1;
      ddr_ack_o <= 1'b0;
      c7_ready_o <= 1'b0;

      if (c_ack_pend) begin
        if (c_kind == K_RD || c_kind == K_WR) begin
          if (ok_c) ddr_ack_o <= 1'b1;
        end else if (c_kind == K_C7) begin
          if (ok_c) c7_ready_o <= 1'b1;
        end
        if ((c_kind == K_C7) ? !c7_valid_i : !ddr_req_i) begin
          c_ack_pend <= 1'b0;
          c_busy <= 1'b0;
          c_kind <= K_NONE;
        end
      end else if (c_busy && (rsp_s2 != rsp_seen)) begin
        rsp_seen <= rsp_s2;
        ok_c <= rsp_ok;
        rdata_c <= rsp_rdata;
        ddr_rdata_o <= rsp_rdata;
        c_ack_pend <= 1'b1;
      end else if (!c_busy && !c_ack_pend) begin
        if (ddr_req_i && ddr_we_i && freeze_i) begin
          if (fz_drop != 16'hFFFF) fz_drop <= fz_drop + 16'd1;
        end else if (ddr_req_i) begin
          c_kind  <= ddr_we_i ? K_WR : K_RD;
          c_slot  <= ddr_addr_i;
          c_wdata <= ddr_wdata_i;
          c_busy  <= 1'b1;
          req_tog <= ~req_tog;
        end else if (c7_valid_i && !freeze_i) begin
          c_kind  <= K_C7;
          c_slot  <= C7_SLOT;
          c_wdata <= {c7_addr_i, 32'hC700_0001};
          c_busy  <= 1'b1;
          req_tog <= ~req_tog;
        end
      end
    end
  end

  // ---- UI: 3-flop req toggle, capture stable payload, AXI, rsp toggle ----
  (* ASYNC_REG = "TRUE" *) logic req_s0, req_s1, req_s2;
  logic req_seen;
  ust_t ust;
  kind_t u_kind;
  logic [4:0] u_slot;
  logic [63:0] u_wdata;
  logic [3:0] retry;
  logic [27:0] u_addr;
  logic region_err;
  logic [31:0] n_wrok, n_wrerr, n_rdok, n_rderr, n_bwr, n_brd;

  assign wr_ok_o = n_wrok;
  assign wr_err_o = n_wrerr;
  assign rd_ok_o = n_rdok;
  assign rd_err_o = n_rderr;
  assign bytes_wr_o = n_bwr;
  assign bytes_rd_o = n_brd;
  assign region_err_o = region_err;
  assign idle_o = (ust == U_IDLE) && (req_s2 == req_seen);
  assign req_o  = (ust != U_IDLE);

  assign m_axi_awid    = 4'hA;
  assign m_axi_arid    = 4'hA;
  assign m_axi_awlen   = 8'd0;
  assign m_axi_arlen   = 8'd0;
  assign m_axi_awsize  = 3'd4;
  assign m_axi_arsize  = 3'd4;
  assign m_axi_awburst = 2'b01;
  assign m_axi_arburst = 2'b01;
  assign m_axi_wstrb   = 16'hFFFF;
  assign m_axi_bready  = (ust == U_B);
  assign m_axi_wlast   = m_axi_wvalid;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      req_s0 <= 1'b0; req_s1 <= 1'b0; req_s2 <= 1'b0; req_seen <= 1'b0;
      ust <= U_IDLE; u_kind <= K_NONE; u_slot <= '0; u_wdata <= '0;
      retry <= '0; u_addr <= '0;
      m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0; m_axi_arvalid <= 1'b0;
      m_axi_rready <= 1'b0; m_axi_awaddr <= '0; m_axi_araddr <= '0;
      m_axi_wdata <= '0;
      n_wrok <= '0; n_wrerr <= '0; n_rdok <= '0; n_rderr <= '0;
      n_bwr <= '0; n_brd <= '0; region_err <= 1'b0;
      rsp_tog <= 1'b0; rsp_ok <= 1'b0; rsp_rdata <= '0;
    end else begin
      req_s0 <= req_tog;
      req_s1 <= req_s0;
      req_s2 <= req_s1;

      unique case (ust)
        U_IDLE: begin
          m_axi_awvalid <= 1'b0;
          m_axi_wvalid  <= 1'b0;
          m_axi_arvalid <= 1'b0;
          m_axi_rready  <= 1'b0;
          if (req_s2 != req_seen) begin
            req_seen <= req_s2;
            u_kind  <= c_kind;
            u_slot  <= c_slot;
            u_wdata <= c_wdata;
            u_addr  <= slot_addr(c_slot);
            retry   <= '0;
            ust     <= U_GRANT;
          end
        end
        U_GRANT: begin
          if (!in_region(u_addr)) begin
            region_err <= 1'b1;
            rsp_ok     <= 1'b0;
            ust        <= U_DONE;
          end else if (grant_i)
            ust <= (u_kind == K_RD) ? U_AR : U_AW;
        end
        U_AW: begin
          m_axi_awaddr  <= u_addr;
          m_axi_awvalid <= 1'b1;
          if (m_axi_awvalid && m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
            m_axi_wdata   <= {64'd0, u_wdata};
            m_axi_wvalid  <= 1'b1;
            ust           <= U_W;
          end
        end
        U_W: begin
          if (m_axi_wvalid && m_axi_wready) begin
            m_axi_wvalid <= 1'b0;
            ust          <= U_B;
          end
        end
        U_B: begin
          if (m_axi_bvalid && m_axi_bready) begin
            if (m_axi_bresp == B_OK) begin
              n_wrok  <= n_wrok + 32'd1;
              n_bwr   <= n_bwr + 32'd16;
              rsp_ok  <= 1'b1;
              ust     <= U_DONE;
            end else begin
              n_wrerr <= n_wrerr + 32'd1;
              if (retry < MAX_RETRY[3:0]) begin
                retry <= retry + 4'd1;
                ust   <= U_GRANT;
              end else begin
                rsp_ok <= 1'b0;
                ust    <= U_DONE;
              end
            end
          end
        end
        U_AR: begin
          m_axi_araddr  <= u_addr;
          m_axi_arvalid <= 1'b1;
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b1;
            ust           <= U_R;
          end
        end
        U_R: begin
          if (m_axi_rvalid && m_axi_rready) begin
            m_axi_rready <= 1'b0;
            rsp_rdata    <= m_axi_rdata[63:0];
            if ((m_axi_rresp == R_OK) && m_axi_rlast) begin
              n_rdok  <= n_rdok + 32'd1;
              n_brd   <= n_brd + 32'd16;
              rsp_ok  <= 1'b1;
              ust     <= U_DONE;
            end else begin
              n_rderr <= n_rderr + 32'd1;
              if (retry < MAX_RETRY[3:0]) begin
                retry <= retry + 4'd1;
                ust   <= U_GRANT;
              end else begin
                rsp_ok <= 1'b0;
                ust    <= U_DONE;
              end
            end
          end
        end
        U_DONE: begin
          rsp_tog <= ~rsp_tog;
          ust     <= U_IDLE;
        end
        default: ust <= U_IDLE;
      endcase
    end
  end
endmodule
