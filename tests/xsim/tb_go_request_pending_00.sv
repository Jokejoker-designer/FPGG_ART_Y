`timescale 1ns / 1ps
// tb_go_request_pending_00.sv — GO-REQUEST-PENDING-00
// xvlog: this-tree a7ng_wdma_cdc + ddr_tile_dma + this TB + glbl. No SoC/MIG.
// ONE UNKNOWN: unowned 1-cycle m_go is held until owner grant; then one FIFO
// write and one s_go with the latched payload; DMA leaves IDLE.
// Keep POP cmd_rd_en && s_owner. PROGRAM=NO. UNIT_PASS ≠ existence.
module tb_go_request_pending_00;
  localparam realtime M_HALF = 40.0;  // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;   // 10 ns → 100 MHz ui
  localparam int unsigned WATCH_S    = 2000;
  localparam int unsigned WAIT_OWNED = 4000;
  localparam int unsigned WAIT_HOLD  = 64;
  localparam int unsigned FIFO_DEPTH = 16;

  localparam logic        EXP_WR    = 1'b0;
  localparam logic [27:0] EXP_ADDR  = 28'h000_2000;
  localparam logic [31:0] EXP_BYTES = 32'd128;
  localparam logic [60:0] EXP_PACK  = {EXP_WR, EXP_ADDR, EXP_BYTES};
  localparam logic [27:0] DUP_ADDR  = 28'h000_3000;
  localparam logic [31:0] DUP_BYTES = 32'd256;

  logic         m_clk, m_rst_n;
  logic         m_owner, m_go, m_wr;
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
  logic         s_busy, s_done, s_dma_idle;
  logic         dma_busy, dma_done;
  logic         tb_hold_busy;
  logic [2:0]   dma_dbg_st;

  logic         arready, rvalid, rlast;
  logic [1:0]   rresp;
  logic [3:0]   rid;
  logic [127:0] rdata;
  logic         awready, wready, bvalid;
  logic         d_arvalid, d_rready, d_awvalid, d_wvalid, d_wlast, d_bready;
  logic [3:0]   d_awid, d_arid;
  logic [27:0]  d_awaddr, d_araddr;
  logic [7:0]   d_awlen, d_arlen;
  logic [2:0]   d_awsize, d_arsize;
  logic [1:0]   d_awburst, d_arburst;
  logic [127:0] d_wdata;
  logic [15:0]  d_wstrb;
  logic         dma_under, axi_berr, axi_rerr;

  wire        cmd_wr_en         = u_cdc.cmd_wr_en;
  wire        cmd_full          = u_cdc.cmd_full;
  wire        cmd_empty         = u_cdc.cmd_empty;
  wire        cmd_rd_en         = u_cdc.cmd_rd_en;
  wire        cmd_hold_valid    = u_cdc.cmd_hold_valid;
  wire        cmd_hold_overflow = u_cdc.cmd_hold_overflow;
  wire [60:0] cmd_hold_data     = u_cdc.cmd_hold_data;
  wire        cmd_accept        = u_cdc.cmd_accept;

  int unsigned cmd_wr_count, s_go_count;
  int unsigned a_wr_count, a_s_go_count;
  bit          unowned_s_go, unowned_false_ar, payload_match;
  bit          dma_left_idle;
  bit          a_payload_match, a_unowned_s_go, a_unowned_false_ar, a_dma_left_idle;

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

  ddr_tile_dma u_dma (
    .clk(s_clk), .rst_n(s_rst_n),
    .go(s_go), .wr(s_wr), .addr(s_addr), .bytes(s_bytes),
    .busy(dma_busy), .done(dma_done), .underflow(dma_under),
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
    .m_axi_arvalid(d_arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(d_rready),
    .dbg_st(dma_dbg_st)
  );

  assign s_busy     = tb_hold_busy | dma_busy;
  assign s_done     = dma_done;
  assign s_dma_idle = (dma_dbg_st == 3'd0);

  assign rlast   = 1'b0;
  assign rresp   = 2'b00;
  assign rid     = 4'd0;
  assign rdata   = 128'd0;
  assign awready = 1'b0;
  assign wready  = 1'b0;
  assign bvalid  = 1'b0;
  assign arready = 1'b0;
  assign rvalid  = 1'b0;

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  always @(posedge m_clk) begin
    if (m_rst_n && cmd_wr_en)
      cmd_wr_count = cmd_wr_count + 1;
  end

  always @(posedge s_clk) begin
    if (s_rst_n && s_go) begin
      s_go_count = s_go_count + 1;
      if (!s_owner)
        unowned_s_go = 1'b1;
      if ((s_wr === EXP_WR) && (s_addr === EXP_ADDR) && (s_bytes === EXP_BYTES))
        payload_match = 1'b1;
      $display("S_GO_CYCLE T=%0t s_owner=%0b wr=%0b addr=%h bytes=%0d dma_st=%0d",
        $time, s_owner, s_wr, s_addr, s_bytes, dma_dbg_st);
    end
    if (s_rst_n && (dma_dbg_st == 3'd4) && !s_owner)
      unowned_false_ar = 1'b1;
    if (s_rst_n && (dma_dbg_st != 3'd0))
      dma_left_idle = 1'b1;
  end

  task automatic clr_counts;
    begin
      cmd_wr_count      = 0;
      s_go_count        = 0;
      unowned_s_go      = 1'b0;
      unowned_false_ar  = 1'b0;
      payload_match     = 1'b0;
      dma_left_idle     = 1'b0;
    end
  endtask

  task automatic apply_rst_recovery;
    begin
      m_rst_n      = 1'b0;
      s_rst_n      = 1'b0;
      m_owner      = 1'b0;
      m_go         = 1'b0;
      m_wr         = EXP_WR;
      m_addr       = EXP_ADDR;
      m_bytes      = EXP_BYTES;
      m_w_valid    = 1'b0;
      m_w_data     = '0;
      m_r_ready    = 1'b1;
      m_tile_dst   = 3'd0;
      tb_hold_busy = 1'b0;
      repeat (25) @(posedge m_clk);
      m_rst_n = 1'b1;
      s_rst_n = 1'b1;
      $display("RESET_RELEASED T=%0t", $time);
      repeat (40) @(posedge m_clk);
      repeat (80) @(posedge s_clk);
      $display("RECOVERY T=%0t cmd_full=%0b cmd_empty=%0b hold_v=%0b overflow=%0b dma_st=%0d",
        $time, cmd_full, cmd_empty, cmd_hold_valid, cmd_hold_overflow, dma_dbg_st);
    end
  endtask

  task automatic pulse_m_go_1;
    begin
      @(posedge m_clk);
      m_go = 1'b1;
      @(posedge m_clk);
      m_go = 1'b0;
    end
  endtask

  task automatic wait_hold_set(output bit ok);
    int unsigned i;
    begin
      ok = 1'b0;
      for (i = 0; i < WAIT_HOLD; i = i + 1) begin
        @(posedge m_clk);
        if (cmd_hold_valid) begin
          ok = 1'b1;
          return;
        end
      end
    end
  endtask

  task automatic wait_hold_clr(output bit ok);
    int unsigned i;
    begin
      ok = 1'b0;
      for (i = 0; i < WAIT_HOLD; i = i + 1) begin
        @(posedge m_clk);
        if (!cmd_hold_valid) begin
          ok = 1'b1;
          return;
        end
      end
    end
  endtask

  initial begin
    int unsigned i, n_fill;
    bit hold_ok, clr_ok, a_pass, c_pass, d_pass, b_pass, b_ran;
    bit case_b_forced;
    string cls;
    string b_status;

    m_rst_n      = 1'b0;
    s_rst_n      = 1'b0;
    m_owner      = 1'b0;
    m_go         = 1'b0;
    m_wr         = EXP_WR;
    m_addr       = EXP_ADDR;
    m_bytes      = EXP_BYTES;
    m_w_valid    = 1'b0;
    m_w_data     = '0;
    m_r_ready    = 1'b1;
    m_tile_dst   = 3'd0;
    tb_hold_busy = 1'b0;
    a_pass = 1'b0;
    c_pass = 1'b0;
    d_pass = 1'b0;
    b_pass = 1'b0;
    b_ran  = 1'b0;
    case_b_forced = 1'b0;
    b_status = "NEEDS_EXPERIMENT";
    clr_counts();

    $display("GO-REQUEST-PENDING-00 START m_period=80ns s_period=10ns");

    // ------------------------------------------------------------------
    // CASE A — delayed grant
    // ------------------------------------------------------------------
    apply_rst_recovery();
    clr_counts();
    m_owner = 1'b0;
    m_wr    = EXP_WR;
    m_addr  = EXP_ADDR;
    m_bytes = EXP_BYTES;
    $display("CASE_A_PULSE_UNOWNED T=%0t wr=%0b addr=%h bytes=%0d",
      $time, m_wr, m_addr, m_bytes);
    pulse_m_go_1();
    wait_hold_set(hold_ok);
    $display("CASE_A_HELD T=%0t hold_ok=%0b hold_v=%0b hold_data=%h wr_en=%0b owner=%0b wr_count=%0d",
      $time, hold_ok, cmd_hold_valid, cmd_hold_data, cmd_wr_en, m_owner, cmd_wr_count);
    if (!hold_ok || (cmd_hold_data !== EXP_PACK) || (cmd_wr_count != 0)) begin
      $display("CASE_A_FAIL reason=hold_after_unowned_go hold_ok=%0b data_ok=%0b wr_count=%0d",
        hold_ok, (cmd_hold_data === EXP_PACK), cmd_wr_count);
    end else begin
      repeat (8) @(posedge m_clk);
      if (cmd_wr_count != 0) begin
        $display("CASE_A_FAIL reason=write_before_grant wr_count=%0d", cmd_wr_count);
      end else begin
        @(posedge m_clk);
        m_owner = 1'b1;
        $display("CASE_A_GRANT T=%0t hold_v=%0b cmd_accept=%0b cmd_full=%0b",
          $time, cmd_hold_valid, cmd_accept, cmd_full);
        for (i = 0; i < WAIT_OWNED; i = i + 1) begin
          @(posedge s_clk);
          if ((s_go_count >= 1) && dma_left_idle)
            break;
        end
        $display("CASE_A_WAITEND T=%0t wr_count=%0d s_go_count=%0d payload=%0b dma_st=%0d left_idle=%0b s_owner=%0b empty=%0b",
          $time, cmd_wr_count, s_go_count, payload_match, dma_dbg_st, dma_left_idle, s_owner, cmd_empty);
        if ((cmd_wr_count == 1) && (s_go_count == 1) && payload_match &&
            dma_left_idle && !unowned_s_go && !unowned_false_ar)
          a_pass = 1'b1;
      end
    end
    a_wr_count          = cmd_wr_count;
    a_s_go_count        = s_go_count;
    a_payload_match     = payload_match;
    a_unowned_s_go      = unowned_s_go;
    a_unowned_false_ar  = unowned_false_ar;
    a_dma_left_idle     = dma_left_idle;
    $display("CASE_A_RESULT pass=%0b CMD_WR_COUNT=%0d S_GO_COUNT=%0d PAYLOAD_MATCH=%0b DMA_LEFT_IDLE=%0b UNOWNED_S_GO=%0b UNOWNED_FALSE_AR=%0b",
      a_pass, a_wr_count, a_s_go_count, a_payload_match, a_dma_left_idle, a_unowned_s_go, a_unowned_false_ar);

    // ------------------------------------------------------------------
    // CASE C — never grant
    // ------------------------------------------------------------------
    apply_rst_recovery();
    clr_counts();
    m_owner = 1'b0;
    m_wr    = EXP_WR;
    m_addr  = EXP_ADDR;
    m_bytes = EXP_BYTES;
    $display("CASE_C_PULSE_NEVER_GRANT T=%0t", $time);
    pulse_m_go_1();
    wait_hold_set(hold_ok);
    for (i = 0; i < WATCH_S; i = i + 1)
      @(posedge s_clk);
    $display("CASE_C_WATCHEND T=%0t hold_ok=%0b hold_v=%0b wr_count=%0d s_go_count=%0d dma_st=%0d overflow=%0b",
      $time, hold_ok, cmd_hold_valid, cmd_wr_count, s_go_count, dma_dbg_st, cmd_hold_overflow);
    if (hold_ok && cmd_hold_valid && (cmd_wr_count == 0) && (s_go_count == 0) &&
        !dma_left_idle && !unowned_s_go && !unowned_false_ar)
      c_pass = 1'b1;
    $display("CASE_C_RESULT pass=%0b CMD_WR_COUNT=%0d S_GO_COUNT=%0d",
      c_pass, cmd_wr_count, s_go_count);

    // ------------------------------------------------------------------
    // CASE D — duplicate m_go while pending
    // ------------------------------------------------------------------
    apply_rst_recovery();
    clr_counts();
    m_owner = 1'b0;
    m_wr    = EXP_WR;
    m_addr  = EXP_ADDR;
    m_bytes = EXP_BYTES;
    $display("CASE_D_FIRST_PULSE T=%0t", $time);
    pulse_m_go_1();
    wait_hold_set(hold_ok);
    m_wr    = 1'b1;
    m_addr  = DUP_ADDR;
    m_bytes = DUP_BYTES;
    $display("CASE_D_SECOND_PULSE T=%0t hold_v=%0b hold_data=%h",
      $time, cmd_hold_valid, cmd_hold_data);
    pulse_m_go_1();
    @(posedge m_clk);
    $display("CASE_D_AFTER T=%0t overflow=%0b hold_data=%h wr_count=%0d s_go_count=%0d",
      $time, cmd_hold_overflow, cmd_hold_data, cmd_wr_count, s_go_count);
    if (hold_ok && cmd_hold_overflow && (cmd_hold_data === EXP_PACK) &&
        (cmd_wr_count == 0) && (s_go_count == 0) && !unowned_s_go)
      d_pass = 1'b1;
    $display("CASE_D_RESULT pass=%0b overflow=%0b first_kept=%0b CMD_WR_COUNT=%0d",
      d_pass, cmd_hold_overflow, (cmd_hold_data === EXP_PACK), cmd_wr_count);

    // ------------------------------------------------------------------
    // CASE B — cmd_full: fill XPM (prefer) else hierarchical force
    // ------------------------------------------------------------------
    apply_rst_recovery();
    clr_counts();
    tb_hold_busy = 1'b1;
    m_owner      = 1'b1;
    m_wr         = EXP_WR;
    m_addr       = EXP_ADDR;
    m_bytes      = EXP_BYTES;
    i = 0;
    while ((s_owner !== 1'b1) && (i < WAIT_OWNED)) begin
      @(posedge s_clk);
      i = i + 1;
    end
    n_fill = 0;
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
      if (cmd_full)
        break;
      pulse_m_go_1();
      wait_hold_clr(clr_ok);
      if (clr_ok)
        n_fill = n_fill + 1;
      else
        break;
    end
    repeat (4) @(posedge m_clk);
    $display("CASE_B_FILL T=%0t n_fill=%0d cmd_full=%0b hold_v=%0b wr_count=%0d empty=%0b",
      $time, n_fill, cmd_full, cmd_hold_valid, cmd_wr_count, cmd_empty);

    if (!cmd_full) begin
      $display("CASE_B_FORCE_CMD_FULL T=%0t (XPM full did not assert after fill)", $time);
      force u_cdc.cmd_full = 1'b1;
      case_b_forced = 1'b1;
      @(posedge m_clk);
      @(posedge m_clk);
    end

    if (cmd_full) begin
      b_ran = 1'b1;
      clr_counts();
      if (cmd_hold_valid) begin
        // Occupied hold + full: extra m_go must overflow, no write.
        m_addr  = DUP_ADDR;
        m_bytes = DUP_BYTES;
        pulse_m_go_1();
        @(posedge m_clk);
        if ((cmd_wr_count == 0) && cmd_hold_overflow && cmd_hold_valid)
          b_pass = 1'b1;
        b_status = b_pass ? "PASS" : "FAIL";
      end else begin
        // Empty hold + full: m_go latches, must not write.
        m_wr    = EXP_WR;
        m_addr  = EXP_ADDR;
        m_bytes = EXP_BYTES;
        pulse_m_go_1();
        wait_hold_set(hold_ok);
        repeat (8) @(posedge m_clk);
        if (hold_ok && cmd_hold_valid && (cmd_wr_count == 0) && (cmd_hold_data === EXP_PACK))
          b_pass = 1'b1;
        b_status = b_pass ? "PASS" : "FAIL";
      end
    end else begin
      b_ran    = 1'b0;
      b_pass   = 1'b0;
      b_status = "NEEDS_EXPERIMENT";
    end
    if (case_b_forced)
      release u_cdc.cmd_full;
    $display("CASE_B_RESULT status=%s pass=%0b forced=%0b CMD_WR_COUNT=%0d hold_v=%0b overflow=%0b full=%0b",
      b_status, b_pass, case_b_forced, cmd_wr_count, cmd_hold_valid, cmd_hold_overflow, cmd_full);

    // ------------------------------------------------------------------
    // Marker (Case A) + UNIT
    // ------------------------------------------------------------------
    if (a_pass && c_pass && d_pass)
      cls = "REQUEST_HELD";
    else if (!a_pass)
      cls = "HOLD_DEAD";
    else if (!c_pass)
      cls = "NEVER_GRANT_LEAK";
    else
      cls = "DUP_OVERWRITE";

    $display("CLASS=%s", cls);
    $display("CMD_WR_COUNT=%0d", a_wr_count);
    $display("S_GO_COUNT=%0d", a_s_go_count);
    $display("PAYLOAD_MATCH=%0b", a_payload_match);
    $display("UNOWNED_S_GO=%0b", a_unowned_s_go);
    $display("UNOWNED_FALSE_AR=%0b", a_unowned_false_ar);
    $display("DMA_LEFT_IDLE=%0b", a_dma_left_idle);
    $display("CASE_B=%s", b_status);
    if (a_pass && c_pass && d_pass)
      $display("GO_REQUEST_PENDING_00_UNIT_PASS");
    else
      $display("GO_REQUEST_PENDING_00_UNIT_FAIL reason=a=%0b,c=%0b,d=%0b", a_pass, c_pass, d_pass);
    $display("EXISTENCE=not_claimed");
    $display("PRED664=not_claimed");
    $finish;
  end

  initial begin
    #2_000_000;
    $display("CMD_WR_COUNT=X");
    $display("S_GO_COUNT=X");
    $display("PAYLOAD_MATCH=X");
    $display("UNOWNED_S_GO=X");
    $display("UNOWNED_FALSE_AR=X");
    $display("CLASS=TIMEOUT");
    $display("GO_REQUEST_PENDING_00_UNIT_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
