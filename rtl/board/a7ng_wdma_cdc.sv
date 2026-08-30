// a7ng_wdma_cdc.sv — weight-tile DMA clock converter (core_clk <-> ui_clk)
// Block-RAM XPM async FIFOs + dest-side registered beats (report_cdc safe).
`timescale 1ns / 1ps

module a7ng_wdma_cdc (
  input  logic         m_clk,
  input  logic         m_rst_n,
  input  logic         m_owner,
  input  logic         m_go,
  input  logic         m_wr,
  input  logic [27:0]  m_addr,
  input  logic [31:0]  m_bytes,
  input  logic         m_w_valid,
  output logic         m_w_ready,
  input  logic [127:0] m_w_data,
  output logic         m_r_valid,
  input  logic         m_r_ready,
  output logic [127:0] m_r_data,
  output logic         m_busy,
  output logic         m_done,
  output logic         dbg_s_done_sticky, // F1t: latched s_done pulse on s_clk
  output logic         dbg_m_done_sticky, // F1t: latched m_done pulse on m_clk
  output logic         dbg_busy_hold,     // F1t: busy_hold register on m_clk
  output logic         dbg_s_go_sticky,   // F1u: latched s_go pulse on s_clk
  output logic         dbg_m_go_sticky,   // F1v: latched m_go pulse on m_clk
  output logic         dbg_sbusy_pend,    // F1B2: s_busy seen while !cmd_empty
  output logic [1:0]   dbg_cmd_st,        // F1B2: cmd_st latched while !cmd_empty
  output logic         dbg_cmd_empty_mgo, // F1B2: 1 if cmd_empty never cleared
  output logic         dbg_cmd_rd_sticky, // F1B2: cmd_rd_en ever fired
  input  logic         s_clk,
  input  logic         s_rst_n,
  output logic         s_owner,
  output logic         s_go,
  output logic         s_wr,
  output logic [27:0]  s_addr,
  output logic [31:0]  s_bytes,
  output logic         s_w_valid,
  input  logic         s_w_ready,
  output logic [127:0] s_w_data,
  input  logic         s_r_valid,
  output logic         s_r_ready,
  input  logic [127:0] s_r_data,
  input  logic         s_busy,
  input  logic         s_done,
  input  logic [2:0]   m_tile_dst = 3'd0,  // dest FSM on m_clk (D_GO=1, D_WAITDONE=4)
  input  logic         s_dma_idle = 1'b0   // ddr_tile_dma IDLE on s_clk
);
  localparam int unsigned CMD_W = 61;
  localparam int unsigned BEAT_W = 128;

  logic [CMD_W-1:0]  cmd_wdata, cmd_rdata;
  logic              cmd_wr_en, cmd_rd_en;
  logic              cmd_full, cmd_empty;

  logic [BEAT_W-1:0] w_wdata, w_rdata;
  logic              w_wr_en, w_rd_en;
  logic              w_full, w_empty;

  logic [BEAT_W-1:0] r_wdata, r_rdata;
  logic              r_wr_en, r_rd_en;
  logic              r_full, r_empty;

  logic       s_owner_cdc;
  logic       m_busy_cdc;
  logic       m_done_cdc;
  logic       busy_hold;
  logic       s_done_sticky;
  logic       m_done_sticky;
  logic       s_go_sticky;
  logic       m_go_sticky;
  logic       sbusy_pend_sticky;
  logic [1:0] cmd_st_latched;
  logic       cmd_empty_never_clr;
  logic       cmd_rd_en_sticky;

  logic       s_go_r;
  logic       s_wr_r;
  logic [27:0] s_addr_r;
  logic [31:0] s_bytes_r;

  logic              s_w_hold, s_w_pend;
  logic [BEAT_W-1:0] s_w_data_r;
  logic              s_w_valid_r;

  logic              m_r_hold, m_r_pend;
  logic [BEAT_W-1:0] m_r_data_r;
  logic              m_r_valid_r;

  logic              cmd_pend;

  typedef enum logic [1:0] {C_IDLE, C_GO, C_BUSY} cmd_st_t;
  cmd_st_t cmd_st;

  // GO-REQUEST-PENDING-00: hold one cmd on m_clk until owned accept.
  // Live-write (ISSUE_GATED) was: cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full.
  logic              cmd_hold_valid, cmd_hold_overflow;
  logic [CMD_W-1:0]  cmd_hold_data;
  wire               cmd_accept = cmd_hold_valid && m_owner && !cmd_full;
  assign cmd_wdata = cmd_hold_data;
  assign cmd_wr_en = m_rst_n && cmd_accept;

  always_ff @(posedge m_clk) begin
    if (!m_rst_n) begin
      cmd_hold_valid    <= 1'b0;
      cmd_hold_data     <= '0;
      cmd_hold_overflow <= 1'b0;
    end else if (cmd_accept) begin
      // Drop hold on accept. Do not relatch same-cycle m_go (371 3× GO).
      cmd_hold_valid    <= 1'b0;
    end else if (m_go && !cmd_hold_valid) begin
      cmd_hold_data     <= {m_wr, m_addr, m_bytes};
      cmd_hold_valid    <= 1'b1;
    end else if (m_go && cmd_hold_valid) begin
      cmd_hold_overflow <= 1'b1;
    end
  end

  assign m_w_ready = m_rst_n && !w_full;
  assign w_wr_en   = m_rst_n && m_w_valid && m_w_ready;
  assign w_wdata   = m_w_data;

  // rst is write-clock synchronous only (XPM requirement)
  xpm_fifo_async #(
    .FIFO_MEMORY_TYPE("block"),
    .FIFO_WRITE_DEPTH(16),
    .WRITE_DATA_WIDTH(CMD_W),
    .READ_DATA_WIDTH(CMD_W),
    .FIFO_READ_LATENCY(1),
    .READ_MODE("std"),
    .CDC_SYNC_STAGES(3),
    .USE_ADV_FEATURES("0000"),
    .WR_DATA_COUNT_WIDTH(5),
    .RD_DATA_COUNT_WIDTH(5)
  ) u_cmd_fifo (
    .rst(!m_rst_n),
    .wr_clk(m_clk),
    .wr_en(cmd_wr_en),
    .din(cmd_wdata),
    .full(cmd_full),
    .rd_clk(s_clk),
    .rd_en(cmd_rd_en),
    .dout(cmd_rdata),
    .empty(cmd_empty),
    .sleep(1'b0),
    .injectsbiterr(1'b0),
    .injectdbiterr(1'b0)
  );

  xpm_fifo_async #(
    .FIFO_MEMORY_TYPE("block"),
    .FIFO_WRITE_DEPTH(16),
    .WRITE_DATA_WIDTH(BEAT_W),
    .READ_DATA_WIDTH(BEAT_W),
    .FIFO_READ_LATENCY(1),
    .READ_MODE("std"),
    .CDC_SYNC_STAGES(3),
    .USE_ADV_FEATURES("0000"),
    .WR_DATA_COUNT_WIDTH(5),
    .RD_DATA_COUNT_WIDTH(5)
  ) u_w_fifo (
    .rst(!m_rst_n),
    .wr_clk(m_clk),
    .wr_en(w_wr_en),
    .din(w_wdata),
    .full(w_full),
    .rd_clk(s_clk),
    .rd_en(w_rd_en),
    .dout(w_rdata),
    .empty(w_empty),
    .sleep(1'b0),
    .injectsbiterr(1'b0),
    .injectdbiterr(1'b0)
  );

  xpm_fifo_async #(
    .FIFO_MEMORY_TYPE("block"),
    .FIFO_WRITE_DEPTH(32),
    .WRITE_DATA_WIDTH(BEAT_W),
    .READ_DATA_WIDTH(BEAT_W),
    .FIFO_READ_LATENCY(1),
    .READ_MODE("std"),
    .CDC_SYNC_STAGES(3),
    .USE_ADV_FEATURES("0000"),
    .WR_DATA_COUNT_WIDTH(6),
    .RD_DATA_COUNT_WIDTH(6)
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

  xpm_cdc_single #(
    .DEST_SYNC_FF(3),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG(1)
  ) u_owner_cdc (
    .dest_clk(s_clk),
    .src_clk(m_clk),
    .src_in(m_owner),
    .dest_out(s_owner_cdc)
  );
  assign s_owner = s_owner_cdc;

  xpm_cdc_single #(
    .DEST_SYNC_FF(3),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG(1)
  ) u_busy_cdc (
    .dest_clk(m_clk),
    .src_clk(s_clk),
    .src_in(s_busy),
    .dest_out(m_busy_cdc)
  );
  // Deassert m_busy after m_done until next m_go (CDC ghost busy fix)
  always_ff @(posedge m_clk) begin
    if (!m_rst_n)
      busy_hold <= 1'b0;
    else if (m_go)
      busy_hold <= 1'b1;
    else if (m_done)
      busy_hold <= 1'b0;
  end
  assign m_busy = busy_hold & m_busy_cdc;

  xpm_cdc_pulse #(
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(0),
    .REG_OUTPUT(1),
    .RST_USED(1),
    .SIM_ASSERT_CHK(0)
  ) u_done_cdc (
    .dest_clk(m_clk),
    .src_clk(s_clk),
    .src_pulse(s_done),
    .src_rst(!s_rst_n),
    .dest_rst(!m_rst_n),
    .dest_pulse(m_done_cdc)
  );
  assign m_done = m_done_cdc;

  // F1t: sticky done probes (probe-only; no functional change)
  always_ff @(posedge s_clk) begin
    if (!s_rst_n)
      s_done_sticky <= 1'b0;
    else if (s_done)
      s_done_sticky <= 1'b1;
  end
  assign dbg_s_done_sticky = s_done_sticky;

  always_ff @(posedge m_clk) begin
    if (!m_rst_n)
      m_done_sticky <= 1'b0;
    else if (m_done)
      m_done_sticky <= 1'b1;
  end
  assign dbg_m_done_sticky = m_done_sticky;
  assign dbg_busy_hold = busy_hold;

  // F1u: sticky s_go probe (probe-only; no functional change)
  always_ff @(posedge s_clk) begin
    if (!s_rst_n)
      s_go_sticky <= 1'b0;
    else if (s_go_r)
      s_go_sticky <= 1'b1;
  end
  assign dbg_s_go_sticky = s_go_sticky;

  // F1v: sticky m_go probe (probe-only; no functional change)
  always_ff @(posedge m_clk) begin
    if (!m_rst_n)
      m_go_sticky <= 1'b0;
    else if (m_go)
      m_go_sticky <= 1'b1;
  end
  assign dbg_m_go_sticky = m_go_sticky;

  // F1B2: UART stickies only (no FIFO / grant / r_path_idle / cmd_rd_en law edit)
  always_ff @(posedge s_clk) begin
    if (!s_rst_n) begin
      sbusy_pend_sticky   <= 1'b0;
      cmd_st_latched      <= 2'd0;
      cmd_empty_never_clr <= 1'b1;
      cmd_rd_en_sticky    <= 1'b0;
    end else begin
      if (!cmd_empty && s_busy)
        sbusy_pend_sticky <= 1'b1;
      if (!cmd_empty)
        cmd_st_latched <= cmd_st;
      if (!cmd_empty)
        cmd_empty_never_clr <= 1'b0;
      if (cmd_rd_en)
        cmd_rd_en_sticky <= 1'b1;
    end
  end
  assign dbg_sbusy_pend    = sbusy_pend_sticky;
  assign dbg_cmd_st        = cmd_st_latched;
  assign dbg_cmd_empty_mgo = cmd_empty_never_clr;
  assign dbg_cmd_rd_sticky = cmd_rd_en_sticky;

  // BFIX-00: dest D_GO/D_WAITDONE (m_clk) AND dma IDLE (s_clk) may
  // release cmd_rd_en / C_BUSY even if ghost s_busy=1. F1s busy_hold kept.
  localparam logic [2:0] DST_D_GO       = 3'd1;
  localparam logic [2:0] DST_D_WAITDONE = 3'd4;
  logic dest_allow_m;
  logic dest_allow_s;
  logic ghost_busy_rel;

  assign dest_allow_m = (m_tile_dst == DST_D_GO) || (m_tile_dst == DST_D_WAITDONE);

  xpm_cdc_single #(
    .DEST_SYNC_FF(3),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG(1)
  ) u_dest_allow_cdc (
    .dest_clk(s_clk),
    .src_clk(m_clk),
    .src_in(dest_allow_m),
    .dest_out(dest_allow_s)
  );

  assign ghost_busy_rel = dest_allow_s && s_dma_idle;

  assign cmd_rd_en = s_rst_n && (cmd_st == C_IDLE) && !cmd_pend && !cmd_empty &&
                     (!s_busy || ghost_busy_rel) && s_owner;

  always_ff @(posedge s_clk) begin
    if (!s_rst_n) begin
      cmd_st    <= C_IDLE;
      cmd_pend  <= 1'b0;
      s_go_r    <= 1'b0;
      s_wr_r    <= 1'b0;
      s_addr_r  <= '0;
      s_bytes_r <= '0;
    end else begin
      s_go_r <= 1'b0;
      if (cmd_rd_en)
        cmd_pend <= 1'b1;
      unique case (cmd_st)
        C_IDLE: begin
          if (cmd_pend) begin
            {s_wr_r, s_addr_r, s_bytes_r} <= cmd_rdata;
            s_go_r   <= 1'b1;
            cmd_pend <= 1'b0;
            cmd_st   <= C_GO;
          end
        end
        C_GO: cmd_st <= C_BUSY;
        C_BUSY: if (!s_busy || ghost_busy_rel) cmd_st <= C_IDLE;
        default: cmd_st <= C_IDLE;
      endcase
    end
  end

  assign s_go    = s_go_r;
  assign s_wr    = s_wr_r;
  assign s_addr  = s_addr_r;
  assign s_bytes = s_bytes_r;

  // Destination-side hold register: no BRAM dout → MIG combo path
  assign w_rd_en = s_rst_n && !s_w_hold && !s_w_pend && !w_empty;
  always_ff @(posedge s_clk) begin
    if (!s_rst_n) begin
      s_w_hold    <= 1'b0;
      s_w_pend    <= 1'b0;
      s_w_valid_r <= 1'b0;
      s_w_data_r  <= '0;
    end else begin
      if (w_rd_en)
        s_w_pend <= 1'b1;
      else if (s_w_pend) begin
        s_w_data_r  <= w_rdata;
        s_w_valid_r <= 1'b1;
        s_w_hold    <= 1'b1;
        s_w_pend    <= 1'b0;
      end else if (s_w_hold && s_w_valid_r && s_w_ready) begin
        s_w_valid_r <= 1'b0;
        s_w_hold    <= 1'b0;
      end
    end
  end
  assign s_w_valid = s_w_valid_r;
  assign s_w_data  = s_w_data_r;

  assign s_r_ready = s_rst_n && !r_full;
  assign r_wr_en   = s_r_valid && s_r_ready;
  assign r_wdata   = s_r_data;

  assign r_rd_en = m_rst_n && !m_r_hold && !m_r_pend && !r_empty;
  always_ff @(posedge m_clk) begin
    if (!m_rst_n) begin
      m_r_hold    <= 1'b0;
      m_r_pend    <= 1'b0;
      m_r_valid_r <= 1'b0;
      m_r_data_r  <= '0;
    end else begin
      if (r_rd_en)
        m_r_pend <= 1'b1;
      else if (m_r_pend) begin
        m_r_data_r  <= r_rdata;
        m_r_valid_r <= 1'b1;
        m_r_hold    <= 1'b1;
        m_r_pend    <= 1'b0;
      end else if (m_r_hold && m_r_valid_r && m_r_ready) begin
        m_r_valid_r <= 1'b0;
        m_r_hold    <= 1'b0;
      end
    end
  end
  assign m_r_valid = m_r_valid_r;
  assign m_r_data  = m_r_data_r;
endmodule
