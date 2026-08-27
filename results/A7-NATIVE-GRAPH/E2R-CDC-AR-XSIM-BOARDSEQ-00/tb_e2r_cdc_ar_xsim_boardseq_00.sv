`timescale 1ns / 1ps
// tb_e2r_cdc_ar_xsim_boardseq_00.sv — E2R-CDC-AR-XSIM-BOARDSEQ-00 (F1h)
// Observation-only: board-like staggered reset release → one AR → s_arv in 50 s_clk?
// Orders: A = s then m (calib then boot); B = m then s.
module tb_e2r_cdc_ar_xsim_boardseq_00;
  localparam realtime M_HALF = 40.0;   // 80 ns period → 12.5 MHz
  localparam realtime S_HALF = 5.0;    // 10 ns period → 100 MHz
  localparam int unsigned S_WINDOW = 50;
  localparam int unsigned HOLD_BOTH_M = 25;
  localparam int unsigned STAGGER_M   = 30;  // delay between first and second release
  localparam int unsigned RECOVERY_M  = 40;
  localparam int unsigned RECOVERY_S  = 80;

  logic         m_clk, m_rst_n;
  logic         s_clk, s_rst_n;

  logic [3:0]   m_axi_arid;
  logic [27:0]  m_axi_araddr;
  logic [7:0]   m_axi_arlen;
  logic [2:0]   m_axi_arsize;
  logic [1:0]   m_axi_arburst;
  logic         m_axi_arvalid;
  logic         m_axi_arready;
  logic [3:0]   m_axi_rid;
  logic [127:0] m_axi_rdata;
  logic [1:0]   m_axi_rresp;
  logic         m_axi_rlast;
  logic         m_axi_rvalid;
  logic         m_axi_rready;

  logic [3:0]   s_axi_arid;
  logic [27:0]  s_axi_araddr;
  logic [7:0]   s_axi_arlen;
  logic [2:0]   s_axi_arsize;
  logic [1:0]   s_axi_arburst;
  logic         s_axi_arvalid;
  logic         s_axi_arready;
  logic [3:0]   s_axi_rid;
  logic [127:0] s_axi_rdata;
  logic [1:0]   s_axi_rresp;
  logic         s_axi_rlast;
  logic         s_axi_rvalid;
  logic         s_axi_rready;

  logic         dbg_r_ne_o, dbg_ar_ne_o, dbg_ar_hold_o;

  wire ar_empty = dut.ar_empty;
  wire ar_full  = dut.ar_full;
  wire ar_wr_en = dut.ar_wr_en;
  wire ar_rd_en = dut.ar_rd_en;
  // Same law as DUT AR FIFO .rst(!(m_rst_n && s_rst_n)) — no XPM hierarchy probe
  wire fifo_rst = !(m_rst_n && s_rst_n);

  a7ng_axi_read_cdc dut (
    .m_clk(m_clk),
    .m_rst_n(m_rst_n),
    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .s_clk(s_clk),
    .s_rst_n(s_rst_n),
    .s_axi_arid(s_axi_arid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .dbg_r_ne_o(dbg_r_ne_o),
    .dbg_ar_ne_o(dbg_ar_ne_o),
    .dbg_ar_hold_o(dbg_ar_hold_o)
  );

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  always @(ar_empty or s_axi_arvalid or ar_wr_en or ar_rd_en or m_axi_arvalid or m_axi_arready
           or m_rst_n or s_rst_n or fifo_rst) begin
    $display("T=%0t m_rst_n=%0b s_rst_n=%0b fifo_rst=%0b | m_arv=%0b m_arr=%0b ar_wr=%0b ar_full=%0b | ar_empty=%0b s_arv=%0b ar_rd=%0b",
      $time, m_rst_n, s_rst_n, fifo_rst,
      m_axi_arvalid, m_axi_arready, ar_wr_en, ar_full,
      ar_empty, s_axi_arvalid, ar_rd_en);
  end

  task automatic idle_bus();
    m_axi_arid    = 4'h1;
    m_axi_araddr  = 28'h000_1000;
    m_axi_arlen   = 8'd0;
    m_axi_arsize  = 3'b100;
    m_axi_arburst = 2'b01;
    m_axi_arvalid = 1'b0;
    m_axi_rready  = 1'b1;
    s_axi_arready = 1'b1;
    s_axi_rid     = '0;
    s_axi_rdata   = '0;
    s_axi_rresp   = '0;
    s_axi_rlast   = 1'b0;
    s_axi_rvalid  = 1'b0;
  endtask

  // order: 0 = s then m; 1 = m then s
  task automatic run_case(input int unsigned order_id, input string order_name,
                          output bit m_accepted, output bit saw_s_arv,
                          output int unsigned s_cycles_after_m);
    m_accepted = 1'b0;
    saw_s_arv  = 1'b0;
    s_cycles_after_m = 0;

    $display("CASE_START id=%0d name=%s T=%0t", order_id, order_name, $time);

    m_rst_n = 1'b0;
    s_rst_n = 1'b0;
    idle_bus();
    repeat (HOLD_BOTH_M) @(posedge m_clk);
    $display("HOLD_BOTH T=%0t fifo_rst=%0b", $time, fifo_rst);

    if (order_id == 0) begin
      // Board-like: calib/ui (s) first, then core/boot (m)
      s_rst_n = 1'b1;
      $display("RELEASE_FIRST s_rst_n T=%0t fifo_rst=%0b (expect still 1)", $time, fifo_rst);
      repeat (STAGGER_M) @(posedge m_clk);
      m_rst_n = 1'b1;
      $display("RELEASE_SECOND m_rst_n T=%0t fifo_rst=%0b", $time, fifo_rst);
    end else begin
      // Reverse: core (m) first, then ui (s)
      m_rst_n = 1'b1;
      $display("RELEASE_FIRST m_rst_n T=%0t fifo_rst=%0b (expect still 1)", $time, fifo_rst);
      repeat (STAGGER_M) @(posedge m_clk);
      s_rst_n = 1'b1;
      $display("RELEASE_SECOND s_rst_n T=%0t fifo_rst=%0b", $time, fifo_rst);
    end

    // XPM recovery after both released (FIFO rst deasserted)
    repeat (RECOVERY_M) @(posedge m_clk);
    repeat (RECOVERY_S) @(posedge s_clk);

    if (fifo_rst) begin
      $display("WARN fifo_rst still asserted after both released T=%0t", $time);
    end
    if (ar_full) begin
      $display("WARN ar_full still 1 after recovery T=%0t", $time);
    end

    @(posedge m_clk);
    m_axi_arvalid = 1'b1;
    $display("M_AR_DRIVE case=%s T=%0t addr=%h", order_name, $time, m_axi_araddr);

    while (!m_accepted) begin
      @(posedge m_clk);
      if (m_axi_arvalid && m_axi_arready) begin
        m_accepted = 1'b1;
        $display("M_AR_ACCEPT case=%s T=%0t ar_wr_en=%0b ar_full=%0b ar_empty=%0b",
          order_name, $time, ar_wr_en, ar_full, ar_empty);
        m_axi_arvalid = 1'b0;
      end
    end

    while (s_cycles_after_m < S_WINDOW && !saw_s_arv) begin
      @(posedge s_clk);
      s_cycles_after_m++;
      if (s_axi_arvalid) begin
        saw_s_arv = 1'b1;
        $display("S_ARVALID case=%s T=%0t s_cycles_after_m=%0d ar_empty=%0b ar_rd_en=%0b addr=%h",
          order_name, $time, s_cycles_after_m, ar_empty, ar_rd_en, s_axi_araddr);
      end
    end

    // Drain / allow AR pop so next case starts empty
    repeat (20) @(posedge s_clk);
    m_axi_arvalid = 1'b0;

    $display("CASE_SUMMARY id=%0d name=%s m_accepted=%0b saw_s_arv=%0b s_cycles_after_m=%0d ar_empty_final=%0b",
      order_id, order_name, m_accepted, saw_s_arv, s_cycles_after_m, ar_empty);
  endtask

  initial begin
    bit m_ok_a, s_ok_a, m_ok_b, s_ok_b;
    int unsigned cyc_a, cyc_b;
    bit pass_a, pass_b;

    $display("E2R-CDC-AR-XSIM-BOARDSEQ-00 F1h START m_period=80ns s_period=10ns window=%0d", S_WINDOW);

    run_case(0, "s_then_m", m_ok_a, s_ok_a, cyc_a);
    pass_a = m_ok_a && s_ok_a && (cyc_a <= S_WINDOW);

    // Re-assert both before reverse order (clean FIFO state)
    m_rst_n = 1'b0;
    s_rst_n = 1'b0;
    idle_bus();
    repeat (HOLD_BOTH_M) @(posedge m_clk);

    run_case(1, "m_then_s", m_ok_b, s_ok_b, cyc_b);
    pass_b = m_ok_b && s_ok_b && (cyc_b <= S_WINDOW);

    $display("SUMMARY s_then_m: m_ok=%0b saw=%0b cyc=%0d PASS=%0b | m_then_s: m_ok=%0b saw=%0b cyc=%0d PASS=%0b",
      m_ok_a, s_ok_a, cyc_a, pass_a, m_ok_b, s_ok_b, cyc_b, pass_b);

    if (pass_a && pass_b) begin
      $display("E2R_CDC_AR_XSIM_BOARDSEQ_PASS s_then_m_cyc=%0d m_then_s_cyc=%0d (window=%0d) H_RIVAL_FAVORED",
        cyc_a, cyc_b, S_WINDOW);
      $finish;
    end else begin
      $display("E2R_CDC_AR_XSIM_BOARDSEQ_FAIL s_then_m_PASS=%0b m_then_s_PASS=%0b H_CANDIDATE_FAVORED",
        pass_a, pass_b);
      $fatal(1);
    end
  end

  initial begin
    #500_000;
    $display("E2R_CDC_AR_XSIM_BOARDSEQ_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
