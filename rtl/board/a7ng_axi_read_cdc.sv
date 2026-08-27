// a7ng_axi_read_cdc.sv — AXI4 read-only clock converter (core_clk <-> ui_clk)
// E2R-CDC-AR-HS-BYPASS-00 F1k: AR path via xpm_cdc_handshake (47b, 1 outstanding).
// R path remains XPM async FIFO (unchanged).
`timescale 1ns / 1ps

module a7ng_axi_read_cdc (
  input  logic         m_clk,
  input  logic         m_rst_n,
  input  logic [3:0]   m_axi_arid,
  input  logic [27:0]  m_axi_araddr,
  input  logic [7:0]   m_axi_arlen,
  input  logic [2:0]   m_axi_arsize,
  input  logic [1:0]   m_axi_arburst,
  input  logic         m_axi_arvalid,
  output logic         m_axi_arready,
  output logic [3:0]   m_axi_rid,
  output logic [127:0] m_axi_rdata,
  output logic [1:0]   m_axi_rresp,
  output logic         m_axi_rlast,
  output logic         m_axi_rvalid,
  input  logic         m_axi_rready,
  input  logic         s_clk,
  input  logic         s_rst_n,
  output logic [3:0]   s_axi_arid,
  output logic [27:0]  s_axi_araddr,
  output logic [7:0]   s_axi_arlen,
  output logic [2:0]   s_axi_arsize,
  output logic [1:0]   s_axi_arburst,
  output logic         s_axi_arvalid,
  input  logic         s_axi_arready,
  input  logic [3:0]   s_axi_rid,
  input  logic [127:0] s_axi_rdata,
  input  logic [1:0]   s_axi_rresp,
  input  logic         s_axi_rlast,
  input  logic         s_axi_rvalid,
  output logic         s_axi_rready,
  // D3 probe: R-side CDC not empty / beat held toward core (no behavior change)
  output logic         dbg_r_ne_o,
  // E3 probe: AR-side occupancy / hold toward mux (registered; no behavior change)
  output logic         dbg_ar_ne_o,
  output logic         dbg_ar_hold_o,
  // F1j/F1k probe: registered "empty" on s_clk (!payload-pending-on-s)
  output logic         dbg_ar_empty_o
);
  localparam int unsigned AR_W = 47;
  localparam int unsigned R_W  = 135;

  // ---------------------------------------------------------------------------
  // AR path — xpm_cdc_handshake (m_clk → s_clk), depth 1 outstanding
  // ---------------------------------------------------------------------------
  logic [AR_W-1:0] ar_src_in;
  logic            ar_src_send;
  logic            ar_src_rcv;
  logic [AR_W-1:0] ar_dest_out;
  logic            ar_dest_req;
  logic            ar_dest_ack;

  // Master FSM: IDLE → ARMED (payload latched) → WAIT_RCV → WAIT_IDLE
  // Latch one cycle before src_send so XPM samples stable src_in (NBA-safe).
  typedef enum logic [1:0] {
    AR_M_IDLE      = 2'd0,
    AR_M_ARMED     = 2'd1,
    AR_M_WAIT_RCV  = 2'd2,
    AR_M_WAIT_IDLE = 2'd3
  } ar_m_state_t;
  ar_m_state_t ar_m_st;

  // Accept only when handshake idle (1 outstanding)
  assign m_axi_arready = m_rst_n && (ar_m_st == AR_M_IDLE) && !ar_src_rcv;

  always_ff @(posedge m_clk or negedge m_rst_n) begin
    if (!m_rst_n) begin
      ar_m_st     <= AR_M_IDLE;
      ar_src_send <= 1'b0;
      ar_src_in   <= '0;
    end else begin
      unique case (ar_m_st)
        AR_M_IDLE: begin
          ar_src_send <= 1'b0;
          if (m_axi_arvalid && m_axi_arready) begin
            ar_src_in <= {m_axi_arburst, m_axi_arsize, m_axi_arid, m_axi_arlen, m_axi_araddr};
            ar_m_st   <= AR_M_ARMED;
          end
        end
        AR_M_ARMED: begin
          ar_src_send <= 1'b1;
          ar_m_st     <= AR_M_WAIT_RCV;
        end
        AR_M_WAIT_RCV: begin
          if (ar_src_rcv) begin
            ar_src_send <= 1'b0;
            ar_m_st     <= AR_M_WAIT_IDLE;
          end else
            ar_src_send <= 1'b1;
        end
        AR_M_WAIT_IDLE: begin
          ar_src_send <= 1'b0;
          if (!ar_src_rcv)
            ar_m_st <= AR_M_IDLE;
        end
        default: begin
          ar_m_st     <= AR_M_IDLE;
          ar_src_send <= 1'b0;
        end
      endcase
    end
  end

  xpm_cdc_handshake #(
    .DEST_EXT_HSK  (1),
    .DEST_SYNC_FF  (3),
    .INIT_SYNC_FF  (0),
    .SIM_ASSERT_CHK(0),
    .SRC_SYNC_FF   (3),
    .WIDTH         (AR_W)
  ) u_ar_hs (
    .src_clk (m_clk),
    .src_in  (ar_src_in),
    .src_send(ar_src_send),
    .src_rcv (ar_src_rcv),
    .dest_clk(s_clk),
    .dest_out(ar_dest_out),
    .dest_req(ar_dest_req),
    .dest_ack(ar_dest_ack)
  );

  // Slave: present AR while dest_req; ack on AXI handshake
  logic        s_ar_hold;
  logic [AR_W-1:0] s_ar_payload;

  always_ff @(posedge s_clk or negedge s_rst_n) begin
    if (!s_rst_n) begin
      s_ar_hold    <= 1'b0;
      s_ar_payload <= '0;
      ar_dest_ack  <= 1'b0;
    end else begin
      if (!s_ar_hold && ar_dest_req && !ar_dest_ack) begin
        s_ar_hold    <= 1'b1;
        s_ar_payload <= ar_dest_out;
      end
      if (s_ar_hold && s_axi_arvalid && s_axi_arready) begin
        ar_dest_ack <= 1'b1;
        s_ar_hold   <= 1'b0;
      end
      if (ar_dest_ack && !ar_dest_req)
        ar_dest_ack <= 1'b0;
    end
  end

  assign {s_axi_arburst, s_axi_arsize, s_axi_arid, s_axi_arlen, s_axi_araddr} = s_ar_payload;
  assign s_axi_arvalid = s_rst_n && s_ar_hold;

  // Probe mapping: empty = !payload-pending-on-s; ne/hold = s-side valid hold
  wire ar_empty = !(s_ar_hold || (ar_dest_req && !ar_dest_ack));

  // ---------------------------------------------------------------------------
  // R path — XPM async FIFO (unchanged from F1j)
  // ---------------------------------------------------------------------------
  logic [R_W-1:0] r_wdata, r_rdata;
  logic           r_wr_en, r_rd_en;
  logic           r_full, r_empty;

  logic [3:0]   m_rid_r;
  logic [127:0] m_rdata_r;
  logic [1:0]   m_rresp_r;
  logic         m_rlast_r, m_rvalid_r;

  xpm_fifo_async #(
    .FIFO_MEMORY_TYPE("block"),
    .FIFO_WRITE_DEPTH(64),
    .WRITE_DATA_WIDTH(R_W),
    .READ_DATA_WIDTH(R_W),
    .FIFO_READ_LATENCY(1),
    .READ_MODE("std"),
    .CDC_SYNC_STAGES(3),
    .USE_ADV_FEATURES("0000"),
    .WR_DATA_COUNT_WIDTH(7),
    .RD_DATA_COUNT_WIDTH(7)
  ) u_r_fifo (
    .rst(!s_rst_n),
    .wr_clk(s_clk),
    .wr_en(r_wr_en),
    .din(r_wdata),
    .full(r_full),
    .rd_clk(m_clk),
    .rd_en(r_rd_en),
    .dout(r_rdata),
    .empty(r_empty),
    .sleep(1'b0),
    .injectsbiterr(1'b0),
    .injectdbiterr(1'b0)
  );

  assign r_wdata = {s_axi_rresp, s_axi_rid, s_axi_rlast, s_axi_rdata};
  assign s_axi_rready = s_rst_n && !r_full;
  assign r_wr_en      = s_axi_rvalid && s_axi_rready;

  logic m_r_hold;
  logic m_r_pend;
  assign r_rd_en = m_rst_n && !m_r_hold && !m_r_pend && !r_empty;

  always_ff @(posedge m_clk) begin
    if (!m_rst_n) begin
      m_r_hold   <= 1'b0;
      m_r_pend   <= 1'b0;
      m_rvalid_r <= 1'b0;
      m_rid_r    <= '0;
      m_rdata_r  <= '0;
      m_rresp_r  <= '0;
      m_rlast_r  <= 1'b0;
    end else begin
      if (r_rd_en)
        m_r_pend <= 1'b1;
      else if (m_r_pend) begin
        {m_rresp_r, m_rid_r, m_rlast_r, m_rdata_r} <= r_rdata;
        m_rvalid_r <= 1'b1;
        m_r_hold   <= 1'b1;
        m_r_pend   <= 1'b0;
      end else if (m_r_hold && m_rvalid_r && m_axi_rready) begin
        m_rvalid_r <= 1'b0;
        m_r_hold   <= 1'b0;
      end
    end
  end

  assign m_axi_rvalid = m_rvalid_r;
  assign m_axi_rid    = m_rid_r;
  assign m_axi_rdata  = m_rdata_r;
  assign m_axi_rresp  = m_rresp_r;
  assign m_axi_rlast  = m_rlast_r;
  assign dbg_r_ne_o = !r_empty || m_r_pend || m_rvalid_r;

  (* DONT_TOUCH = "TRUE" *) logic dbg_ar_ne_r, dbg_ar_hold_r, dbg_ar_empty_r;
  always_ff @(posedge s_clk or negedge s_rst_n) begin
    if (!s_rst_n) begin
      dbg_ar_ne_r    <= 1'b0;
      dbg_ar_hold_r  <= 1'b0;
      dbg_ar_empty_r <= 1'b1;
    end else begin
      dbg_ar_ne_r    <= !ar_empty;
      dbg_ar_hold_r  <= s_axi_arvalid;
      dbg_ar_empty_r <= ar_empty;
    end
  end
  assign dbg_ar_ne_o    = dbg_ar_ne_r;
  assign dbg_ar_hold_o  = dbg_ar_hold_r;
  assign dbg_ar_empty_o = dbg_ar_empty_r;
endmodule
