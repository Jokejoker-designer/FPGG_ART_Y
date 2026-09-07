// tb_u9r_r4.sv — U9R R4 WDMA dest-ready on CDC slice (not soc_top dest).
// Production tiny_gpt803k_core does not connect dma_go_ready (default 1).
// PROGRAM=NO. Cycle watchdog.
`timescale 1ns / 1ps

module tb_u9r_r4;
  localparam int unsigned WATCH_CYC = 400000;

  logic core_clk, ui_clk, core_rst_n, ui_rst_n;
  integer cyc, tmo, fails;
  integer cmd_wr_count, s_go_count, wdma_b_ok, m_done_count;
  integer g_cmd0, g_sgo0, g_done0, g_bok0;
  logic cmd_wr_d, s_go_d, m_done_d;

  initial core_clk = 0;
  always #5 core_clk = ~core_clk;
  initial begin
    ui_clk = 0;
    #3;
    forever #4 ui_clk = ~ui_clk;
  end
  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  logic m_owner, m_go, m_go_ready, m_wr;
  logic [27:0] m_addr;
  logic [31:0] m_bytes;
  logic m_w_valid, m_w_ready;
  logic [127:0] m_w_data, m_r_data, s_w_data, s_r_data, d_wdata, d_rdata;
  logic m_r_valid, m_r_ready, m_busy, m_done;
  logic s_owner, s_go, s_wr, s_w_valid, s_w_ready, s_r_valid, s_r_ready, s_busy, s_done;
  logic [27:0] s_addr, d_awaddr, d_araddr;
  logic [31:0] s_bytes;
  logic dma_busy, dma_done, dma_under, axi_berr, axi_rerr;
  logic [2:0] dma_st;
  logic d_awvalid, d_awready, d_wvalid, d_wready, d_wlast, d_bvalid, d_bready;
  logic d_arvalid, d_arready, d_rvalid, d_rready, d_rlast;
  logic [7:0] d_awlen, d_arlen;
  logic [15:0] d_wstrb;

  wire cmd_wr_en         = u_cdc.cmd_wr_en;
  wire cmd_hold_valid    = u_cdc.cmd_hold_valid;
  wire cmd_hold_overflow = u_cdc.cmd_hold_overflow;

  a7ng_wdma_cdc u_cdc (
    .m_clk(core_clk), .m_rst_n(core_rst_n),
    .m_owner(m_owner), .m_go(m_go), .m_go_ready(m_go_ready), .m_wr(m_wr),
    .m_addr(m_addr), .m_bytes(m_bytes),
    .m_w_valid(m_w_valid), .m_w_ready(m_w_ready), .m_w_data(m_w_data),
    .m_r_valid(m_r_valid), .m_r_ready(m_r_ready), .m_r_data(m_r_data),
    .m_busy(m_busy), .m_done(m_done),
    .dbg_s_done_sticky(), .dbg_m_done_sticky(), .dbg_busy_hold(),
    .dbg_s_go_sticky(), .dbg_m_go_sticky(), .dbg_sbusy_pend(),
    .dbg_cmd_st(), .dbg_cmd_empty_mgo(), .dbg_cmd_rd_sticky(),
    .s_clk(ui_clk), .s_rst_n(ui_rst_n),
    .s_owner(s_owner),
    .s_go(s_go), .s_wr(s_wr), .s_addr(s_addr), .s_bytes(s_bytes),
    .s_w_valid(s_w_valid), .s_w_ready(s_w_ready), .s_w_data(s_w_data),
    .s_r_valid(s_r_valid), .s_r_ready(s_r_ready), .s_r_data(s_r_data),
    .s_busy(s_busy), .s_done(s_done),
    .m_tile_dst(3'd0),
    .s_dma_idle(dma_st == 3'd0)
  );

  ddr_tile_dma u_dma (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .go(s_go), .wr(s_wr), .addr(s_addr), .bytes(s_bytes),
    .busy(dma_busy), .done(dma_done), .underflow(dma_under),
    .axi_berr(axi_berr), .axi_rerr(axi_rerr),
    .w_valid(s_w_valid), .w_ready(s_w_ready), .w_data(s_w_data),
    .r_valid(s_r_valid), .r_ready(s_r_ready), .r_data(s_r_data),
    .m_axi_awid(), .m_axi_awaddr(d_awaddr), .m_axi_awlen(d_awlen),
    .m_axi_awsize(), .m_axi_awburst(),
    .m_axi_awvalid(d_awvalid), .m_axi_awready(d_awready),
    .m_axi_wdata(d_wdata), .m_axi_wstrb(d_wstrb), .m_axi_wlast(d_wlast),
    .m_axi_wvalid(d_wvalid), .m_axi_wready(d_wready),
    .m_axi_bid(4'd0), .m_axi_bresp(2'b00), .m_axi_bvalid(d_bvalid), .m_axi_bready(d_bready),
    .m_axi_arid(), .m_axi_araddr(d_araddr), .m_axi_arlen(d_arlen),
    .m_axi_arsize(), .m_axi_arburst(),
    .m_axi_arvalid(d_arvalid), .m_axi_arready(d_arready),
    .m_axi_rid(4'd0), .m_axi_rdata(d_rdata), .m_axi_rresp(2'b00),
    .m_axi_rlast(d_rlast), .m_axi_rvalid(d_rvalid), .m_axi_rready(d_rready),
    .dbg_st(dma_st)
  );

  assign s_busy = dma_busy;
  assign s_done = dma_done;
  assign d_rdata = 128'hA5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5;
  assign m_r_ready = 1'b1;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      d_awready <= 1'b1; d_wready <= 1'b1; d_bvalid <= 1'b0;
      d_arready <= 1'b1; d_rvalid <= 1'b0; d_rlast <= 1'b0;
      wdma_b_ok <= 0;
    end else begin
      d_awready <= 1'b1;
      d_wready  <= 1'b1;
      d_arready <= 1'b1;
      if (d_wvalid && d_wready && d_wlast)
        d_bvalid <= 1'b1;
      if (d_bvalid && d_bready) begin
        d_bvalid <= 1'b0;
        wdma_b_ok <= wdma_b_ok + 1;
      end
      if (d_arvalid && d_arready) begin
        d_rvalid <= 1'b1;
        d_rlast  <= 1'b1;
      end
      if (d_rvalid && d_rready) begin
        d_rvalid <= 1'b0;
        d_rlast  <= 1'b0;
      end
    end
  end

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      cmd_wr_count <= 0; m_done_count <= 0; cmd_wr_d <= 0; m_done_d <= 0;
    end else begin
      if (cmd_wr_en && !cmd_wr_d) cmd_wr_count <= cmd_wr_count + 1;
      if (m_done && !m_done_d) m_done_count <= m_done_count + 1;
      cmd_wr_d <= cmd_wr_en;
      m_done_d <= m_done;
    end
  end
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      s_go_count <= 0; s_go_d <= 0;
    end else begin
      if (s_go && !s_go_d) s_go_count <= s_go_count + 1;
      s_go_d <= s_go;
    end
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", c, d, cyc);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  task automatic dest_pulse_go;
    begin
      tmo = 0;
      while (!m_go_ready && tmo < 8000) begin @(posedge core_clk); tmo++; end
      if (!m_go_ready) diverge("TIMEOUT", "m_go_ready");
      @(negedge core_clk); m_go = 1'b1;
      @(posedge core_clk); @(negedge core_clk); m_go = 1'b0;
    end
  endtask

  initial begin
    fails = 0;
    core_rst_n = 0; ui_rst_n = 0;
    m_owner = 0; m_go = 0; m_wr = 1; m_addr = 28'h000_2000; m_bytes = 32'd128;
    m_w_valid = 0; m_w_data = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
    $display("R4_RTL_FACT SOC_TOP_M_GO_READY=0 TINY_GPT_DMA_GO_READY=0 dest_default=1");
    $display("R4_SCOPE CDC_SLICE dest-like producer; not production tile through soc_top");
    repeat (8) @(posedge ui_clk); ui_rst_n = 1;
    repeat (4) @(posedge core_clk); core_rst_n = 1;

    g_cmd0 = cmd_wr_count; g_sgo0 = s_go_count; g_done0 = m_done_count; g_bok0 = wdma_b_ok;
    m_owner = 1'b0;
    dest_pulse_go();
    tmo = 0;
    while (!cmd_hold_valid && tmo < 64) begin @(posedge core_clk); tmo++; end
    if (!cmd_hold_valid) diverge("TIMEOUT", "hold");
    if (m_go_ready) diverge("READY_WHILE_HOLD", "m_go_ready must drop");
    $display("R4_BACKPRESSURE ready=0 hold=1 ovf=%0d", cmd_hold_overflow);
    m_owner = 1'b1;
    m_w_valid = 1'b1;
    m_addr = 28'h000_3000;
    dest_pulse_go();
    tmo = 0;
    while ((m_done_count - g_done0) < 2 && tmo < 8000) begin
      @(posedge core_clk); tmo++;
    end
    m_w_valid = 1'b0;
    $display("R4_TWO_REQ ovf=%0d cmd=%0d s_go=%0d m_done=%0d b_ok=%0d under=%0d",
             cmd_hold_overflow, cmd_wr_count - g_cmd0, s_go_count - g_sgo0,
             m_done_count - g_done0, wdma_b_ok - g_bok0, dma_under);
    if (cmd_hold_overflow) diverge("WDMA_SILENT_DROP", "overflow");
    if ((cmd_wr_count - g_cmd0) !== 2) diverge("WDMA_CMD_COUNT", "expect 2");
    if ((m_done_count - g_done0) !== 2) diverge("WDMA_DONE_COUNT", "expect 2");
    if ((wdma_b_ok - g_bok0) !== 2) diverge("WDMA_ACK_NE_COMMIT", "BRESP != 2");
    $display("R4_SLICE_TWO_REQ PASS ACK=2 BRESP=2 (starvation under=%0d is not payload scoreboard)", dma_under);

    m_owner = 1'b1; m_addr = 28'h000_4000; m_w_valid = 1'b1;
    dest_pulse_go();
    tmo = 0;
    while ((dma_st == 3'd0) && tmo < 4000) begin @(posedge ui_clk); tmo++; end
    core_rst_n = 0; ui_rst_n = 0; m_go = 0; m_owner = 0; m_w_valid = 0;
    repeat (16) @(posedge core_clk);
    repeat (16) @(posedge ui_clk);
    ui_rst_n = 1; repeat (8) @(posedge core_clk); core_rst_n = 1;
    repeat (80) @(posedge ui_clk);
    if (cmd_hold_valid) diverge("GHOST_HOLD", "after rst");
    if (cmd_hold_overflow) diverge("GHOST_OVERFLOW", "after rst");
    g_done0 = m_done_count; g_bok0 = wdma_b_ok; g_cmd0 = cmd_wr_count;
    m_owner = 1; m_addr = 28'h000_5000; m_w_valid = 1;
    dest_pulse_go();
    tmo = 0;
    while ((m_done_count - g_done0) == 0 && tmo < 8000) begin @(posedge core_clk); tmo++; end
    if ((m_done_count - g_done0) !== 1) diverge("WDMA_DONE_COUNT", "post-rst");
    if ((wdma_b_ok - g_bok0) !== 1) diverge("WDMA_ACK_NE_COMMIT", "post-rst BRESP");
    $display("R4_MID_TXN_RESET PASS");
    $display("ROOT_B_SCOPE SLICE_XSIM_PASS PRODUCTION_DEST_UNWIRED INTEGRATION_GAP");
    $display("U9R_R4_SLICE_PASS_SOC_GAP");
    $finish;
  end

  always @(posedge core_clk) begin
    if (core_rst_n && cyc > WATCH_CYC) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
