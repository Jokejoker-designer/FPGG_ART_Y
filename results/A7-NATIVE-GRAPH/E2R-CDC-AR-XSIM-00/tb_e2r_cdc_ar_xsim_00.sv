`timescale 1ns / 1ps
// tb_e2r_cdc_ar_xsim_00.sv — E2R-CDC-AR-XSIM-00 (F1f)
// Observation-only: one m AR beat → s_axi_arvalid within 50 s_clk?
module tb_e2r_cdc_ar_xsim_00;
  localparam realtime M_HALF = 40.0;   // 80 ns period → 12.5 MHz
  localparam realtime S_HALF = 5.0;    // 10 ns period → 100 MHz
  localparam int unsigned S_WINDOW = 50;

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

  // Hierarchical probes into DUT (observation)
  wire ar_empty = dut.ar_empty;
  wire ar_full  = dut.ar_full;
  wire ar_wr_en = dut.ar_wr_en;
  wire ar_rd_en = dut.ar_rd_en;

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

  // Clocks
  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  // Log on change of AR-path observables (keeps transcript readable)
  always @(ar_empty or s_axi_arvalid or ar_wr_en or ar_rd_en or m_axi_arvalid or m_axi_arready
           or m_rst_n or s_rst_n) begin
    $display("T=%0t m_rst_n=%0b s_rst_n=%0b | m_arv=%0b m_arr=%0b ar_wr_en=%0b ar_full=%0b | ar_empty=%0b s_arv=%0b ar_rd_en=%0b | dbg_ne=%0b dbg_hold=%0b",
      $time, m_rst_n, s_rst_n,
      m_axi_arvalid, m_axi_arready, ar_wr_en, ar_full,
      ar_empty, s_axi_arvalid, ar_rd_en,
      dbg_ar_ne_o, dbg_ar_hold_o);
  end

  initial begin
    int unsigned s_cycles_after_m;
    bit m_accepted;
    bit saw_s_arv;
    realtime t_m_accept;

    m_rst_n = 1'b0;
    s_rst_n = 1'b0;
    m_axi_arid    = 4'h1;
    m_axi_araddr  = 28'h000_1000;
    m_axi_arlen   = 8'd0;
    m_axi_arsize  = 3'b100; // 16 B
    m_axi_arburst = 2'b01;  // INCR
    m_axi_arvalid = 1'b0;
    m_axi_rready  = 1'b1;
    s_axi_arready = 1'b1;
    s_axi_rid     = '0;
    s_axi_rdata   = '0;
    s_axi_rresp   = '0;
    s_axi_rlast   = 1'b0;
    s_axi_rvalid  = 1'b0;
    m_accepted    = 1'b0;
    saw_s_arv     = 1'b0;
    s_cycles_after_m = 0;
    t_m_accept    = 0;

    $display("E2R-CDC-AR-XSIM-00 F1f START m_period=80ns s_period=10ns window=%0d", S_WINDOW);

    // Hold both domains in reset (FIFO rst = !(m&&s) → asserted)
    repeat (25) @(posedge m_clk);
    // Release both; XPM needs recovery before wr_en
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (40) @(posedge m_clk);
    repeat (80) @(posedge s_clk);

    if (ar_full) begin
      $display("WARN ar_full still 1 after recovery T=%0t", $time);
    end

    // Drive one AR beat; hold valid until ready handshake
    @(posedge m_clk);
    m_axi_arvalid = 1'b1;
    $display("M_AR_DRIVE T=%0t addr=%h", $time, m_axi_araddr);

    while (!m_accepted) begin
      @(posedge m_clk);
      if (m_axi_arvalid && m_axi_arready) begin
        m_accepted = 1'b1;
        t_m_accept = $realtime;
        $display("M_AR_ACCEPT T=%0t ar_wr_en=%0b ar_full=%0b ar_empty=%0b",
          $time, ar_wr_en, ar_full, ar_empty);
        // Drop valid after this beat so only one FIFO write occurs
        m_axi_arvalid = 1'b0;
      end
    end

    // Watch s_clk for up to S_WINDOW cycles after m accept
    while (s_cycles_after_m < S_WINDOW && !saw_s_arv) begin
      @(posedge s_clk);
      s_cycles_after_m++;
      if (s_axi_arvalid) begin
        saw_s_arv = 1'b1;
        $display("S_ARVALID T=%0t s_cycles_after_m=%0d ar_empty=%0b ar_rd_en=%0b addr=%h",
          $time, s_cycles_after_m, ar_empty, ar_rd_en, s_axi_araddr);
      end
    end

    // Drain a few more s cycles for log clarity
    repeat (10) @(posedge s_clk);

    $display("SUMMARY m_accepted=%0b saw_s_arv=%0b s_cycles_after_m=%0d ar_empty_final=%0b dbg_ne=%0b dbg_hold=%0b",
      m_accepted, saw_s_arv, s_cycles_after_m, ar_empty, dbg_ar_ne_o, dbg_ar_hold_o);

    if (!m_accepted) begin
      $display("E2R_CDC_AR_XSIM_FAIL reason=no_m_handshake");
      $fatal(1);
    end
    if (saw_s_arv && s_cycles_after_m <= S_WINDOW) begin
      $display("E2R_CDC_AR_XSIM_PASS s_cycles_after_m=%0d (window=%0d) H_RIVAL_FAVORED",
        s_cycles_after_m, S_WINDOW);
      $finish;
    end else begin
      $display("E2R_CDC_AR_XSIM_FAIL reason=no_s_arvalid_in_window s_cycles=%0d window=%0d H_CANDIDATE_FAVORED",
        s_cycles_after_m, S_WINDOW);
      $fatal(1);
    end
  end

  // Absolute watchdog
  initial begin
    #200_000;
    $display("E2R_CDC_AR_XSIM_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
