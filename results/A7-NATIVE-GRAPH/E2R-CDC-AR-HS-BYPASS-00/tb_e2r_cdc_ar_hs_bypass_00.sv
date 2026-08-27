`timescale 1ns / 1ps
// tb_e2r_cdc_ar_hs_bypass_00.sv — E2R-CDC-AR-HS-BYPASS-00 (F1k)
// Adapted F1f: one m AR beat → s_axi_arvalid within 50 s_clk (xpm_cdc_handshake AR)
module tb_e2r_cdc_ar_hs_bypass_00;
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

  logic         dbg_r_ne_o, dbg_ar_ne_o, dbg_ar_hold_o, dbg_ar_empty_o;

  // Hierarchical probes (handshake AR path)
  wire ar_src_send = dut.ar_src_send;
  wire ar_src_rcv  = dut.ar_src_rcv;
  wire ar_dest_req = dut.ar_dest_req;
  wire ar_dest_ack = dut.ar_dest_ack;
  wire ar_empty    = dut.ar_empty;
  wire s_ar_hold   = dut.s_ar_hold;

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
    .dbg_ar_hold_o(dbg_ar_hold_o),
    .dbg_ar_empty_o(dbg_ar_empty_o)
  );

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  always @(ar_src_send or ar_src_rcv or ar_dest_req or ar_dest_ack or s_axi_arvalid
           or m_axi_arvalid or m_axi_arready or m_rst_n or s_rst_n or s_ar_hold) begin
    $display("T=%0t m_rst=%0b s_rst=%0b | m_arv=%0b m_arr=%0b send=%0b rcv=%0b | dest_req=%0b dest_ack=%0b hold=%0b s_arv=%0b empty=%0b",
      $time, m_rst_n, s_rst_n,
      m_axi_arvalid, m_axi_arready, ar_src_send, ar_src_rcv,
      ar_dest_req, ar_dest_ack, s_ar_hold, s_axi_arvalid, ar_empty);
  end

  // Sample AXI AR handshake at posedge (ready drops combo after accept)
  bit m_accept_pulse;
  always @(posedge m_clk)
    m_accept_pulse <= m_axi_arvalid && m_axi_arready;

  initial begin
    int unsigned s_cycles_after_m;
    bit m_accepted;
    bit saw_s_arv;

    m_rst_n = 1'b0;
    s_rst_n = 1'b0;
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
    m_accepted    = 1'b0;
    saw_s_arv     = 1'b0;
    s_cycles_after_m = 0;

    $display("E2R-CDC-AR-HS-BYPASS-00 F1k START m_period=80ns s_period=10ns window=%0d", S_WINDOW);

    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (20) @(posedge m_clk);
    repeat (40) @(posedge s_clk);

    @(posedge m_clk);
    m_axi_arvalid = 1'b1;
    $display("M_AR_DRIVE T=%0t addr=%h", $time, m_axi_araddr);

    // Wait for registered accept pulse (captures edge where valid&&ready)
    while (!m_accept_pulse)
      @(posedge m_clk);
    m_accepted = 1'b1;
    $display("M_AR_ACCEPT T=%0t send=%0b rcv=%0b", $time, ar_src_send, ar_src_rcv);
    m_axi_arvalid = 1'b0;

    while (s_cycles_after_m < S_WINDOW && !saw_s_arv) begin
      @(posedge s_clk);
      s_cycles_after_m++;
      if (s_axi_arvalid) begin
        saw_s_arv = 1'b1;
        $display("S_ARVALID T=%0t s_cycles_after_m=%0d addr=%h dest_req=%0b hold=%0b",
          $time, s_cycles_after_m, s_axi_araddr, ar_dest_req, s_ar_hold);
      end
    end

    repeat (20) @(posedge s_clk);

    $display("SUMMARY m_accepted=%0b saw_s_arv=%0b s_cycles_after_m=%0d ar_empty_final=%0b dbg_ne=%0b dbg_hold=%0b dbg_empty=%0b",
      m_accepted, saw_s_arv, s_cycles_after_m, ar_empty, dbg_ar_ne_o, dbg_ar_hold_o, dbg_ar_empty_o);

    if (!m_accepted) begin
      $display("E2R_CDC_AR_HS_XSIM_FAIL reason=no_m_handshake");
      $fatal(1);
    end
    if (saw_s_arv && s_cycles_after_m <= S_WINDOW) begin
      $display("E2R_CDC_AR_HS_XSIM_PASS s_cycles_after_m=%0d (window=%0d)",
        s_cycles_after_m, S_WINDOW);
      $finish;
    end else begin
      $display("E2R_CDC_AR_HS_XSIM_FAIL reason=no_s_arvalid_in_window s_cycles=%0d window=%0d",
        s_cycles_after_m, S_WINDOW);
      $fatal(1);
    end
  end

  initial begin
    #200_000;
    $display("E2R_CDC_AR_HS_XSIM_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
