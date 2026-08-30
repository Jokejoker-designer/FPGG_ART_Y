`timescale 1ns / 1ps
// tb_go_grant_quiesce_00.sv — GO-GRANT-QUIESCE-00 (composition, no MIG/SoC)
// xvlog: this-tree a7ng_wdma_cdc + ddr_tile_dma + sync_bits + bag-local
// snap_top_grant_quiesce_slice + this TB.
// ONE UNKNOWN: after dest wdma_owner drop while DMA parked in AR (and
// idle_c already 0), does grant HOLD then DROP only after idle+empty+quiet?
// CLASS=QUIESCE_HOLD iff GRANT_HOLD_IN_AR=1 and GRANT_DROP_AFTER_IDLE=1.
// PROGRAM=NO. CDC not edited. UNIT_PASS ≠ existence.
module tb_go_grant_quiesce_00;
  localparam realtime M_HALF = 40.0;  // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;   // 10 ns → 100 MHz ui
  localparam int unsigned WAIT_OWNED = 4000;
  localparam int unsigned WAIT_DROP  = 4000;
  localparam int unsigned HOLD_WIN_M = 16;
  localparam int unsigned BEAT_TO    = 2000;
  localparam int unsigned IDLE_TO    = 4000;
  localparam int unsigned GRANT_TO   = 4000;

  logic         m_clk, m_rst_n;
  logic         m_go, m_wr;
  logic [27:0]  m_addr;
  logic [31:0]  m_bytes;
  logic         m_w_valid, m_w_ready;
  logic [127:0] m_w_data;
  logic         m_r_valid, m_r_ready;
  logic [127:0] m_r_data;
  logic         m_busy, m_done;
  logic [2:0]   m_tile_dst;

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
  logic [2:0]   dma_dbg_st;

  logic         boot_active;
  logic         wdma_owner, r_path_idle, wdma_owner_grant, wdma_owner_ui;
  logic         d_arvalid, d_rready;
  logic         cdc_arvalid, cdc_rready, cdc_arready;
  logic         arvalid, arready, rready;
  logic         rvalid, rlast;
  logic [1:0]   rresp;
  logic [3:0]   rid;
  logic [127:0] rdata;
  logic         d_awvalid, d_wvalid, d_wlast, d_bready;
  logic [3:0]   d_awid, d_arid;
  logic [27:0]  d_awaddr, d_araddr;
  logic [7:0]   d_awlen, d_arlen;
  logic [2:0]   d_awsize, d_arsize;
  logic [1:0]   d_awburst, d_arburst;
  logic [127:0] d_wdata;
  logic [15:0]  d_wstrb;
  logic         dma_under, axi_berr, axi_rerr;
  logic         go_gated, arready_gated, rvalid_gated;
  logic         awready, wready, bvalid;
  logic [3:0]   wdma_arr_outst;
  logic         wdma_dma_idle_ui, wdma_arr_quiet_ui, wdma_cmd_empty_ui;
  logic         wdma_dma_idle_c, wdma_arr_quiet_c, wdma_cmd_empty_c;

  wire cmd_wr_en = u_cdc.cmd_wr_en;
  wire cmd_full  = u_cdc.cmd_full;
  wire cmd_empty = u_cdc.cmd_empty;
  wire cmd_rd_en = u_cdc.cmd_rd_en;

  bit owned_ar, grant_hold_in_ar, grant_drop_after_idle, saw_ui_quiet;
  bit [2:0] hold_st;
  string cls;

  a7ng_wdma_cdc u_cdc (
    .m_clk(m_clk), .m_rst_n(m_rst_n),
    .m_owner(wdma_owner_grant), .m_go(m_go), .m_wr(m_wr),
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

  assign wdma_owner_ui = s_owner;

  snap_top_grant_quiesce_slice u_slice (
    .core_clk(m_clk), .core_rst_n(m_rst_n),
    .ui_clk(s_clk), .ui_rst_n(s_rst_n),
    .wdma_owner(wdma_owner),
    .r_path_idle(r_path_idle),
    .wdma_dbg_st(dma_dbg_st),
    .cmd_empty(cmd_empty),
    .wdma_owner_ui(wdma_owner_ui),
    .d_arvalid(d_arvalid),
    .d_rready(d_rready),
    .boot_active(boot_active),
    .dma_go(s_go),
    .arready(arready),
    .rvalid(rvalid),
    .rlast(rlast),
    .cdc_arvalid(cdc_arvalid),
    .cdc_rready(cdc_rready),
    .wdma_owner_grant(wdma_owner_grant),
    .go_gated(go_gated),
    .arready_gated(arready_gated),
    .rvalid_gated(rvalid_gated),
    .arvalid(arvalid),
    .rready(rready),
    .cdc_arready(cdc_arready),
    .wdma_arr_outst(wdma_arr_outst),
    .wdma_dma_idle_ui(wdma_dma_idle_ui),
    .wdma_arr_quiet_ui(wdma_arr_quiet_ui),
    .wdma_cmd_empty_ui(wdma_cmd_empty_ui),
    .wdma_dma_idle_c(wdma_dma_idle_c),
    .wdma_arr_quiet_c(wdma_arr_quiet_c),
    .wdma_cmd_empty_c(wdma_cmd_empty_c)
  );

  ddr_tile_dma u_dma (
    .clk(s_clk), .rst_n(s_rst_n),
    .go(go_gated), .wr(s_wr), .addr(s_addr), .bytes(s_bytes),
    .busy(s_busy), .done(s_done), .underflow(dma_under),
    .axi_berr(axi_berr), .axi_rerr(axi_rerr),
    .w_valid(s_w_valid), .w_ready(s_w_ready), .w_data(s_w_data),
    .r_valid(s_r_valid), .r_ready(s_r_ready), .r_data(s_r_data),
    .m_axi_awid(d_awid), .m_axi_awaddr(d_awaddr), .m_axi_awlen(d_awlen),
    .m_axi_awsize(d_awsize), .m_axi_awburst(d_awburst),
    .m_axi_awvalid(d_awvalid), .m_axi_awready(awready),
    .m_axi_wdata(d_wdata), .m_axi_wstrb(d_wstrb), .m_axi_wlast(d_wlast),
    .m_axi_wvalid(d_wvalid), .m_axi_wready(wready),
    .m_axi_bid(4'd0), .m_axi_bresp(2'b00), .m_axi_bvalid(bvalid), .m_axi_bready(d_bready),
    .m_axi_arid(d_arid), .m_axi_araddr(d_araddr), .m_axi_arlen(d_arlen),
    .m_axi_arsize(d_arsize), .m_axi_arburst(d_arburst),
    .m_axi_arvalid(d_arvalid), .m_axi_arready(arready_gated),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid_gated), .m_axi_rready(d_rready),
    .dbg_st(dma_dbg_st)
  );

  assign s_dma_idle = (dma_dbg_st == 3'd0);

  assign rresp   = 2'b00;
  assign rid     = 4'd0;
  assign rdata   = 128'd0;
  assign awready = 1'b0;
  assign wready  = 1'b0;
  assign bvalid  = 1'b0;

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  always @(posedge s_clk) begin
    if (s_go)
      $display("S_GO_CYCLE T=%0t dma_st=%0d grant=%0b owner_ui=%0b wr=%0b addr=%h bytes=%0d go_gated=%0b arready=%0b arready_gated=%0b",
        $time, dma_dbg_st, wdma_owner_grant, wdma_owner_ui, s_wr, s_addr, s_bytes,
        go_gated, arready, arready_gated);
    if (arready && ((d_arvalid === 1'b1) || (dma_dbg_st >= 3'd4)))
      $display("SAMP T=%0t st=%0d arv=%0b arr=%0b gated=%0b own=%0b outst=%0d rdy=%0b rv=%0b rlast=%0b grant=%0b",
        $time, dma_dbg_st, d_arvalid, arready, arready_gated, wdma_owner_ui, wdma_arr_outst,
        d_rready, rvalid, rlast, wdma_owner_grant);
  end

  initial begin
    int unsigned i;
    int unsigned accepted;

    boot_active    = 1'b0;
    m_rst_n        = 1'b0;
    s_rst_n        = 1'b0;
    wdma_owner     = 1'b0;
    r_path_idle    = 1'b1;
    m_go           = 1'b0;
    m_wr           = 1'b0;
    m_addr         = 28'h000_2000;
    m_bytes        = 32'd128;
    m_w_valid      = 1'b0;
    m_w_data       = '0;
    m_r_ready      = 1'b1;
    m_tile_dst     = 3'd0;
    cdc_arvalid    = 1'b0;
    cdc_rready     = 1'b0;
    arready        = 1'b0;
    rvalid         = 1'b0;
    rlast          = 1'b0;
    owned_ar       = 1'b0;
    grant_hold_in_ar      = 1'b0;
    grant_drop_after_idle = 1'b0;
    saw_ui_quiet          = 1'b0;
    hold_st        = 3'd0;
    cls            = "INCONCLUSIVE";

    $display("GO-GRANT-QUIESCE-00 START m_period=80ns s_period=10ns TOP_ELAB=slice_not_soc");

    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (40) @(posedge m_clk);
    repeat (80) @(posedge s_clk);
    $display("RECOVERY T=%0t cmd_empty=%0b cmd_wr_en=%0b cmd_rd_en=%0b dma_st=%0d grant=%0b",
      $time, cmd_empty, cmd_wr_en, cmd_rd_en, dma_dbg_st, wdma_owner_grant);

    wdma_owner = 1'b1;
    $display("TILE_OWNER_RAISE T=%0t r_path_idle=%0b", $time, r_path_idle);
    i = 0;
    while ((wdma_owner_grant !== 1'b1) && (i < WAIT_DROP)) begin
      @(posedge m_clk);
      i = i + 1;
    end
    if (wdma_owner_grant !== 1'b1) begin
      $display("OWNED_AR=0");
      $display("GRANT_HOLD_IN_AR=0");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", dma_dbg_st);
      $display("CLASS=INCONCLUSIVE");
      $display("GO_GRANT_QUIESCE_00_UNIT_FAIL reason=grant_never_1");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end
    $display("GRANT_1 T=%0t", $time);

    i = 0;
    while ((wdma_owner_ui !== 1'b1) && (i < WAIT_DROP)) begin
      @(posedge s_clk);
      i = i + 1;
    end
    if (wdma_owner_ui !== 1'b1) begin
      $display("OWNED_AR=0");
      $display("GRANT_HOLD_IN_AR=0");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", dma_dbg_st);
      $display("CLASS=INCONCLUSIVE");
      $display("GO_GRANT_QUIESCE_00_UNIT_FAIL reason=owner_ui_never_1");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end
    $display("OWNER_UI_1 T=%0t arready=%0b rvalid=%0b grant=%0b",
      $time, arready, rvalid, wdma_owner_grant);

    @(posedge m_clk);
    m_go = 1'b1;
    $display("OWNED_M_GO_PULSE T=%0t grant=%0b owner_ui=%0b arready=%0b cmd_wr_en=%0b cmd_full=%0b",
      $time, wdma_owner_grant, wdma_owner_ui, arready, cmd_wr_en, cmd_full);
    @(posedge m_clk);
    m_go = 1'b0;

    for (i = 0; i < WAIT_OWNED; i = i + 1) begin
      @(posedge s_clk);
      if ((dma_dbg_st == 3'd4) && (d_arvalid === 1'b1) && (wdma_owner_ui === 1'b1)) begin
        owned_ar = 1'b1;
        $display("OWNED_AR=1 T=%0t dma_st=%0d d_arvalid=%0b owner_ui=%0b grant=%0b arready=%0b arready_gated=%0b idle_c=%0b",
          $time, dma_dbg_st, d_arvalid, wdma_owner_ui, wdma_owner_grant, arready, arready_gated, wdma_dma_idle_c);
        break;
      end
    end
    if (!owned_ar) begin
      $display("OWNED_AR=0");
      $display("GRANT_HOLD_IN_AR=0");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", dma_dbg_st);
      $display("CLASS=INCONCLUSIVE");
      $display("GO_GRANT_QUIESCE_00_UNIT_PASS");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end

    // Wait until core sees DMA not-idle so dest drop cannot use stale idle_c=1.
    i = 0;
    while ((wdma_dma_idle_c !== 1'b0) && (i < WAIT_DROP)) begin
      @(posedge m_clk);
      i = i + 1;
    end
    repeat (2) @(posedge m_clk);
    $display("IDLE_C_0 T=%0t idle_c=%0b empty_c=%0b quiet_c=%0b dma_st=%0d grant=%0b",
      $time, wdma_dma_idle_c, wdma_cmd_empty_c, wdma_arr_quiet_c, dma_dbg_st, wdma_owner_grant);

    @(posedge m_clk);
    wdma_owner = 1'b0;
    $display("TILE_OWNER_DROP T=%0t keep_arready=0 dma_st=%0d grant=%0b idle_c=%0b empty_c=%0b quiet_c=%0b",
      $time, dma_dbg_st, wdma_owner_grant, wdma_dma_idle_c, wdma_cmd_empty_c, wdma_arr_quiet_c);

    for (i = 0; i < HOLD_WIN_M; i = i + 1)
      @(posedge m_clk);

    hold_st = dma_dbg_st;
    if ((wdma_owner_grant === 1'b1) && (dma_dbg_st == 3'd4))
      grant_hold_in_ar = 1'b1;
    $display("GRANT_HOLD_SAMPLE T=%0t grant=%0b dma_st=%0d tile_owner=%0b owner_ui=%0b cmd_empty=%0b arr_outst=%0d idle_ui=%0b idle_c=%0b quiet_c=%0b",
      $time, wdma_owner_grant, dma_dbg_st, wdma_owner, wdma_owner_ui, cmd_empty,
      wdma_arr_outst, wdma_dma_idle_ui, wdma_dma_idle_c, wdma_arr_quiet_c);
    $display("GRANT_HOLD_IN_AR=%0b", grant_hold_in_ar);

    if (!grant_hold_in_ar) begin
      $display("OWNED_AR=%0b", owned_ar);
      $display("GRANT_HOLD_IN_AR=0");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", hold_st);
      $display("CLASS=IMMEDIATE_DROP");
      $display("GO_GRANT_QUIESCE_00_UNIT_PASS");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end

    // One-cycle AR handshake (level arready=1 double-counts arr_outst).
    @(posedge s_clk);
    arready = 1'b1;
    rvalid  = 1'b0;
    rlast   = 1'b0;
    $display("STUB_ARREADY_PULSE T=%0t grant=%0b owner_ui=%0b arready_gated=%0b",
      $time, wdma_owner_grant, wdma_owner_ui, arready_gated);
    @(posedge s_clk);
    arready = 1'b0;
    i = 0;
    while ((dma_dbg_st != 3'd5) && (i < BEAT_TO)) begin
      @(posedge s_clk);
      i = i + 1;
    end
    $display("AR_COMPLETE T=%0t i=%0d dma_st=%0d arr_outst=%0d grant=%0b d_arvalid=%0b",
      $time, i, dma_dbg_st, wdma_arr_outst, wdma_owner_grant, d_arvalid);
    if (dma_dbg_st != 3'd5) begin
      $display("OWNED_AR=1");
      $display("GRANT_HOLD_IN_AR=1");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", hold_st);
      $display("CLASS=GRANT_STUCK");
      $display("GO_GRANT_QUIESCE_00_UNIT_FAIL reason=no_R");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end

    arready = 1'b1;
    accepted = 0;
    i = 0;
    while ((dma_dbg_st != 3'd0) && (i < BEAT_TO)) begin
      rvalid = 1'b1;
      rlast  = (accepted >= 7) || (dma_dbg_st == 3'd6);
      @(posedge s_clk);
      if ((rvalid_gated === 1'b1) && (d_rready === 1'b1))
        accepted = accepted + 1;
      i = i + 1;
    end
    rvalid = 1'b0;
    rlast  = 1'b0;
    $display("R_BEATS T=%0t accepted=%0d dma_st=%0d arr_outst=%0d grant=%0b",
      $time, accepted, dma_dbg_st, wdma_arr_outst, wdma_owner_grant);

    i = 0;
    while (!((dma_dbg_st == 3'd0) && (cmd_empty === 1'b1) && (wdma_arr_outst == 4'd0)) && (i < IDLE_TO)) begin
      @(posedge s_clk);
      i = i + 1;
    end
    if ((dma_dbg_st == 3'd0) && (cmd_empty === 1'b1) && (wdma_arr_outst == 4'd0))
      saw_ui_quiet = 1'b1;
    $display("UI_QUIET T=%0t saw=%0b dma_st=%0d cmd_empty=%0b arr_outst=%0d grant=%0b idle_c=%0b empty_c=%0b quiet_c=%0b",
      $time, saw_ui_quiet, dma_dbg_st, cmd_empty, wdma_arr_outst, wdma_owner_grant,
      wdma_dma_idle_c, wdma_cmd_empty_c, wdma_arr_quiet_c);
    if (!saw_ui_quiet) begin
      $display("OWNED_AR=1");
      $display("GRANT_HOLD_IN_AR=1");
      $display("GRANT_DROP_AFTER_IDLE=0");
      $display("HOLD_ST=%0d", hold_st);
      $display("CLASS=GRANT_STUCK");
      $display("GO_GRANT_QUIESCE_00_UNIT_FAIL reason=arr_outst");
      $display("EXISTENCE=not_claimed");
      $display("PRED664=not_claimed");
      $finish;
    end

    i = 0;
    while ((wdma_owner_grant !== 1'b0) && (i < GRANT_TO)) begin
      @(posedge m_clk);
      i = i + 1;
    end
    if (wdma_owner_grant === 1'b0)
      grant_drop_after_idle = 1'b1;
    $display("GRANT_AFTER_IDLE T=%0t grant=%0b i=%0d idle_c=%0b empty_c=%0b quiet_c=%0b",
      $time, wdma_owner_grant, i, wdma_dma_idle_c, wdma_cmd_empty_c, wdma_arr_quiet_c);

    if (grant_hold_in_ar && grant_drop_after_idle)
      cls = "QUIESCE_HOLD";
    else if (!grant_hold_in_ar)
      cls = "IMMEDIATE_DROP";
    else
      cls = "GRANT_STUCK";

    $display("OWNED_AR=%0b", owned_ar);
    $display("GRANT_HOLD_IN_AR=%0b", grant_hold_in_ar);
    $display("GRANT_DROP_AFTER_IDLE=%0b", grant_drop_after_idle);
    $display("HOLD_ST=%0d", hold_st);
    $display("CLASS=%s", cls);
    $display("GO_GRANT_QUIESCE_00_UNIT_PASS");
    $display("EXISTENCE=not_claimed");
    $display("PRED664=not_claimed");
    $finish;
  end

  initial begin
    #1_000_000;
    $display("OWNED_AR=X");
    $display("GRANT_HOLD_IN_AR=X");
    $display("GRANT_DROP_AFTER_IDLE=X");
    $display("HOLD_ST=X");
    $display("CLASS=TIMEOUT");
    $display("GO_GRANT_QUIESCE_00_UNIT_FAIL reason=timeout");
    $finish;
  end
endmodule
