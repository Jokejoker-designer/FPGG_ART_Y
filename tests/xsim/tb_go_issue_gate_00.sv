`timescale 1ns / 1ps
// tb_go_issue_gate_00.sv — GO-ISSUE-GATE-00 (isolated a7ng_wdma_cdc)
// ONE UNKNOWN: after AND m_owner on cmd_wr_en, unowned m_go prints
// CMD_WR_UNOWNED=0 while owned prints CMD_WR_OWNED=1.
// Instantiates ONLY a7ng_wdma_cdc. Stubs: s_busy=0, s_done=0, s_dma_idle=0.
// No tile, top, DMA, QSTAR, LM-06. PROGRAM=NO.
module tb_go_issue_gate_00;
  localparam realtime M_HALF = 40.0;  // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;   // 10 ns → 100 MHz ui stand-in

  logic         m_clk, m_rst_n;
  logic         m_owner, m_go, m_wr;
  logic [27:0]  m_addr;
  logic [31:0]  m_bytes;
  logic         m_w_valid, m_w_ready;
  logic [127:0] m_w_data;
  logic         m_r_valid, m_r_ready;
  logic [127:0] m_r_data;
  logic         m_busy, m_done;

  logic         s_clk, s_rst_n;
  logic         s_owner, s_go, s_wr;
  logic [27:0]  s_addr;
  logic [31:0]  s_bytes;
  logic         s_w_valid, s_w_ready;
  logic [127:0] s_w_data;
  logic         s_r_valid, s_r_ready;
  logic [127:0] s_r_data;
  logic         s_busy, s_done;
  logic         s_dma_idle;
  logic [2:0]   m_tile_dst;

  // Hierarchical probe of module-local wire (prefer this over a debug export).
  wire cmd_wr_en = u_cdc.cmd_wr_en;
  wire cmd_full  = u_cdc.cmd_full;

  a7ng_wdma_cdc u_cdc (
    .m_clk(m_clk), .m_rst_n(m_rst_n),
    .m_owner(m_owner), .m_go(m_go), .m_wr(m_wr),
    .m_addr(m_addr), .m_bytes(m_bytes),
    .m_w_valid(m_w_valid), .m_w_ready(m_w_ready), .m_w_data(m_w_data),
    .m_r_valid(m_r_valid), .m_r_ready(m_r_ready), .m_r_data(m_r_data),
    .m_busy(m_busy), .m_done(m_done),
    .dbg_s_done_sticky(),
    .dbg_m_done_sticky(),
    .dbg_busy_hold(),
    .dbg_s_go_sticky(),
    .dbg_m_go_sticky(),
    .dbg_sbusy_pend(),
    .dbg_cmd_st(),
    .dbg_cmd_empty_mgo(),
    .dbg_cmd_rd_sticky(),
    .s_clk(s_clk), .s_rst_n(s_rst_n),
    .s_owner(s_owner),
    .s_go(s_go), .s_wr(s_wr), .s_addr(s_addr), .s_bytes(s_bytes),
    .s_w_valid(s_w_valid), .s_w_ready(s_w_ready), .s_w_data(s_w_data),
    .s_r_valid(s_r_valid), .s_r_ready(s_r_ready), .s_r_data(s_r_data),
    .s_busy(s_busy), .s_done(s_done),
    .m_tile_dst(m_tile_dst),
    .s_dma_idle(s_dma_idle)
  );

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  initial begin
    bit cmd_wr_unowned;
    bit cmd_wr_owned;
    string cls;

    m_rst_n    = 1'b0;
    s_rst_n    = 1'b0;
    m_owner    = 1'b0;
    m_go       = 1'b0;
    m_wr       = 1'b1;
    m_addr     = 28'h000_1000;
    m_bytes    = 32'd64;
    m_w_valid  = 1'b0;
    m_w_data   = '0;
    m_r_ready  = 1'b1;
    s_w_ready  = 1'b1;
    s_r_valid  = 1'b0;
    s_r_data   = '0;
    s_busy     = 1'b0;  // stub
    s_done     = 1'b0;  // stub
    s_dma_idle = 1'b0;  // stub
    m_tile_dst = 3'd0;

    cmd_wr_unowned = 1'b0;
    cmd_wr_owned   = 1'b0;

    $display("GO-ISSUE-GATE-00 START m_period=80ns s_period=10ns");

    // Hold reset, then XPM FIFO recovery (same recipe as CMDCDC-TB-00).
    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (40) @(posedge m_clk);
    repeat (80) @(posedge s_clk);
    $display("RECOVERY T=%0t cmd_full=%0b cmd_wr_en=%0b", $time, cmd_full, cmd_wr_en);

    // Pulse 1: m_owner=0, 1-cycle m_go. Expect cmd_wr_en=0 at FIFO sample edge.
    m_owner = 1'b0;
    @(posedge m_clk);
    m_go = 1'b1;
    @(posedge m_clk);
    cmd_wr_unowned = cmd_wr_en;
    $display("PULSE_UNOWNED T=%0t m_owner=%0b m_go=%0b cmd_wr_en=%0b cmd_full=%0b",
      $time, m_owner, m_go, cmd_wr_en, cmd_full);
    m_go = 1'b0;
    @(posedge m_clk);

    // Gap so domains settle; FIFO must not be full for pulse 2.
    repeat (8) @(posedge m_clk);

    // Pulse 2: m_owner=1, 1-cycle m_go. Expect cmd_wr_en=1 at FIFO sample edge.
    m_owner = 1'b1;
    @(posedge m_clk);
    m_go = 1'b1;
    @(posedge m_clk);
    cmd_wr_owned = cmd_wr_en;
    $display("PULSE_OWNED T=%0t m_owner=%0b m_go=%0b cmd_wr_en=%0b cmd_full=%0b",
      $time, m_owner, m_go, cmd_wr_en, cmd_full);
    m_go = 1'b0;
    @(posedge m_clk);

    if (!cmd_wr_unowned && cmd_wr_owned)
      cls = "ISSUE_GATED";
    else if (cmd_wr_unowned && cmd_wr_owned)
      cls = "UNGATED";
    else if (!cmd_wr_unowned && !cmd_wr_owned)
      cls = "OWNED_WR_DEAD";
    else
      cls = "INVERTED";

    $display("CMD_WR_UNOWNED=%0b", cmd_wr_unowned);
    $display("CMD_WR_OWNED=%0b", cmd_wr_owned);
    $display("CLASS=%s", cls);
    $display("GO_ISSUE_GATE_00_UNIT_PASS");
    $display("EXISTENCE=not_claimed");
    $display("PRED664=not_claimed");
    $finish;
  end

  initial begin
    #200_000;
    $display("CMD_WR_UNOWNED=X");
    $display("CMD_WR_OWNED=X");
    $display("CLASS=TIMEOUT");
    $display("GO_ISSUE_GATE_00_UNIT_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
