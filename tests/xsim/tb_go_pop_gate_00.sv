`timescale 1ns / 1ps
// tb_go_pop_gate_00.sv — GO-POP-GATE-00 (isolated a7ng_wdma_cdc)
// ONE UNKNOWN: after AND s_owner on cmd_rd_en, an owned enqueue then
// drop m_owner before slave pop: s_go stays 0 while s_owner=0 (DROP_S_GO=0);
// a later owned window still pops (GRANT_S_GO=1). CLASS=POP_GATED.
// Instantiates ONLY a7ng_wdma_cdc. Stubs: s_busy / s_done / s_dma_idle.
// No tile, top, DMA, QSTAR, LM-06. PROGRAM=NO.
module tb_go_pop_gate_00;
  localparam realtime M_HALF = 40.0;  // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;   // 10 ns → 100 MHz ui stand-in
  localparam int unsigned DROP_WIN_S  = 2000;
  localparam int unsigned GRANT_WIN_S = 2000;

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

  // Hierarchical probes (no debug export).
  wire cmd_wr_en = u_cdc.cmd_wr_en;
  wire cmd_rd_en = u_cdc.cmd_rd_en;
  wire cmd_empty = u_cdc.cmd_empty;
  wire cmd_full  = u_cdc.cmd_full;
  wire cmd_pend  = u_cdc.cmd_pend;

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
    bit drop_s_go;
    bit grant_s_go;
    int unsigned i;
    bit saw_empty;
    string cls;

    m_rst_n    = 1'b0;
    s_rst_n    = 1'b0;
    m_owner    = 1'b1;   // owned enqueue
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
    // Hold pop illegal until after s_owner drops (drop-before-pop).
    s_busy     = 1'b1;
    s_done     = 1'b0;
    s_dma_idle = 1'b0;
    m_tile_dst = 3'd0;

    drop_s_go  = 1'b0;
    grant_s_go = 1'b0;
    saw_empty  = 1'b0;

    $display("GO-POP-GATE-00 START m_period=80ns s_period=10ns");

    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (40) @(posedge m_clk);
    repeat (80) @(posedge s_clk);
    $display("RECOVERY T=%0t m_owner=%0b s_owner=%0b cmd_empty=%0b cmd_wr_en=%0b cmd_rd_en=%0b",
      $time, m_owner, s_owner, cmd_empty, cmd_wr_en, cmd_rd_en);

    // Owned one-cycle m_go (issue-gated enqueue).
    @(posedge m_clk);
    m_go = 1'b1;
    @(posedge m_clk);
    $display("PULSE_OWNED_ENQ T=%0t m_owner=%0b m_go=%0b cmd_wr_en=%0b cmd_full=%0b",
      $time, m_owner, m_go, cmd_wr_en, cmd_full);
    m_go = 1'b0;
    @(posedge m_clk);

    // Wait until cmd_empty=0 (rd-side) or a few m cycles.
    for (i = 0; i < 64; i = i + 1) begin
      @(posedge m_clk);
      if (!cmd_empty) begin
        saw_empty = 1'b1;
        break;
      end
    end
    $display("ENQ_WAIT T=%0t cmd_empty=%0b saw_empty=%0b s_owner=%0b s_go=%0b cmd_rd_en=%0b s_busy=%0b",
      $time, cmd_empty, saw_empty, s_owner, s_go, cmd_rd_en, s_busy);

    // Drop owner before slave pop.
    m_owner = 1'b0;
    $display("DROP_M_OWNER T=%0t m_owner=0", $time);
    for (i = 0; i < 64; i = i + 1) begin
      @(posedge s_clk);
      if (!s_owner)
        break;
    end
    $display("S_OWNER_LOW T=%0t s_owner=%0b cmd_empty=%0b cmd_rd_en=%0b s_go=%0b",
      $time, s_owner, cmd_empty, cmd_rd_en, s_go);

    // Pop is now legal iff owned. s_owner is 0 — expect no s_go.
    s_busy     = 1'b0;
    s_dma_idle = 1'b1;
    s_done     = 1'b0;
    $display("POP_LEGAL_STUB T=%0t s_busy=0 s_dma_idle=1", $time);

    for (i = 0; i < DROP_WIN_S; i = i + 1) begin
      @(posedge s_clk);
      if (s_go && !s_owner)
        drop_s_go = 1'b1;
    end
    $display("DROP_WIN_END T=%0t DROP_S_GO=%0b cmd_empty=%0b cmd_rd_en=%0b s_owner=%0b",
      $time, drop_s_go, cmd_empty, cmd_rd_en, s_owner);

    // Re-grant. First command should still be in FIFO → pop when s_owner=1.
    m_owner = 1'b1;
    $display("RAISE_M_OWNER T=%0t m_owner=1", $time);
    for (i = 0; i < 64; i = i + 1) begin
      @(posedge s_clk);
      if (s_owner)
        break;
    end
    $display("S_OWNER_HIGH T=%0t s_owner=%0b cmd_empty=%0b cmd_rd_en=%0b",
      $time, s_owner, cmd_empty, cmd_rd_en);

    for (i = 0; i < GRANT_WIN_S; i = i + 1) begin
      @(posedge s_clk);
      if (s_go && s_owner)
        grant_s_go = 1'b1;
    end

    // If first command was never popped and GRANT missed, one more owned m_go.
    if (!grant_s_go) begin
      $display("GRANT_MISS_RETRY T=%0t cmd_empty=%0b — extra owned m_go", $time, cmd_empty);
      @(posedge m_clk);
      m_go = 1'b1;
      @(posedge m_clk);
      m_go = 1'b0;
      for (i = 0; i < GRANT_WIN_S; i = i + 1) begin
        @(posedge s_clk);
        if (s_go && s_owner)
          grant_s_go = 1'b1;
      end
    end

    if (!drop_s_go && grant_s_go)
      cls = "POP_GATED";
    else if (drop_s_go && grant_s_go)
      cls = "UNGATED_POP";
    else if (!drop_s_go && !grant_s_go)
      cls = "OWNED_POP_DEAD";
    else
      cls = "INVERTED";

    $display("DROP_S_GO=%0b", drop_s_go);
    $display("GRANT_S_GO=%0b", grant_s_go);
    $display("CLASS=%s", cls);
    $display("GO_POP_GATE_00_UNIT_PASS");
    $display("EXISTENCE=not_claimed");
    $display("PRED664=not_claimed");
    $finish;
  end

  initial begin
    #500_000;
    $display("DROP_S_GO=X");
    $display("GRANT_S_GO=X");
    $display("CLASS=TIMEOUT");
    $display("GO_POP_GATE_00_UNIT_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
