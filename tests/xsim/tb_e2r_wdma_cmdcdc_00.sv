`timescale 1ns / 1ps
// tb_e2r_wdma_cmdcdc_00.sv — E2R-WDMA-CMDCDC-TB-00 (Class B)
// Canonical TB. Archive runner: results/A7-NATIVE-GRAPH/E2R-WDMA-CMDCDC-TB-00/run_xsim.cmd
// ONE CHANGE: unit XSim of a7ng_wdma_cdc cmd FIFO only.
// UNIT: one m_go. CONTROL: s_busy=0. No tile / grant / board.
module tb_e2r_wdma_cmdcdc_00;
  localparam realtime M_HALF = 40.0;   // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;    // 10 ns → 100 MHz ui stand-in
  localparam int unsigned S_WINDOW = 50;

  logic         m_clk, m_rst_n;
  logic         m_owner, m_go, m_wr;
  logic [27:0]  m_addr;
  logic [31:0]  m_bytes;
  logic         m_w_valid, m_w_ready;
  logic [127:0] m_w_data;
  logic         m_r_valid, m_r_ready;
  logic [127:0] m_r_data;
  logic         m_busy, m_done;
  logic         dbg_s_done_sticky, dbg_m_done_sticky, dbg_busy_hold;
  logic         dbg_s_go_sticky, dbg_m_go_sticky;

  logic         s_clk, s_rst_n;
  logic         s_owner, s_go, s_wr;
  logic [27:0]  s_addr;
  logic [31:0]  s_bytes;
  logic         s_w_valid, s_w_ready;
  logic [127:0] s_w_data;
  logic         s_r_valid, s_r_ready;
  logic [127:0] s_r_data;
  logic         s_busy, s_done;

  wire cmd_wr_en = dut.cmd_wr_en;
  wire cmd_full  = dut.cmd_full;
  wire cmd_empty = dut.cmd_empty;
  wire cmd_rd_en = dut.cmd_rd_en;
  wire cmd_pend  = dut.cmd_pend;
  wire s_go_r    = dut.s_go_r;

  integer pf;

  a7ng_wdma_cdc dut (
    .m_clk(m_clk), .m_rst_n(m_rst_n),
    .m_owner(m_owner), .m_go(m_go), .m_wr(m_wr),
    .m_addr(m_addr), .m_bytes(m_bytes),
    .m_w_valid(m_w_valid), .m_w_ready(m_w_ready), .m_w_data(m_w_data),
    .m_r_valid(m_r_valid), .m_r_ready(m_r_ready), .m_r_data(m_r_data),
    .m_busy(m_busy), .m_done(m_done),
    .dbg_s_done_sticky(dbg_s_done_sticky),
    .dbg_m_done_sticky(dbg_m_done_sticky),
    .dbg_busy_hold(dbg_busy_hold),
    .dbg_s_go_sticky(dbg_s_go_sticky),
    .dbg_m_go_sticky(dbg_m_go_sticky),
    .s_clk(s_clk), .s_rst_n(s_rst_n),
    .s_owner(s_owner),
    .s_go(s_go), .s_wr(s_wr), .s_addr(s_addr), .s_bytes(s_bytes),
    .s_w_valid(s_w_valid), .s_w_ready(s_w_ready), .s_w_data(s_w_data),
    .s_r_valid(s_r_valid), .s_r_ready(s_r_ready), .s_r_data(s_r_data),
    .s_busy(s_busy), .s_done(s_done)
  );

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  task automatic dump_row(input string clk);
    begin
      $fdisplay(pf, "%0t,%s,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b",
        $time, clk, m_go, s_go, cmd_wr_en, cmd_full, cmd_empty, cmd_rd_en, cmd_pend, s_go_r);
      $display("PROBE t=%0t clk=%s m_go=%0b s_go=%0b wr_en=%0b full=%0b empty=%0b rd_en=%0b pend=%0b s_go_r=%0b rst_m=%0b rst_s=%0b s_busy=%0b",
        $time, clk, m_go, s_go, cmd_wr_en, cmd_full, cmd_empty, cmd_rd_en, cmd_pend, s_go_r,
        m_rst_n, s_rst_n, s_busy);
    end
  endtask

  always @(m_go or s_go or cmd_wr_en or cmd_full or cmd_empty or cmd_rd_en or cmd_pend or s_go_r
           or m_rst_n or s_rst_n) begin
    if (pf != 0)
      $display("CHG  t=%0t m_go=%0b s_go=%0b wr_en=%0b full=%0b empty=%0b rd_en=%0b pend=%0b s_go_r=%0b",
        $time, m_go, s_go, cmd_wr_en, cmd_full, cmd_empty, cmd_rd_en, cmd_pend, s_go_r);
  end

  initial begin
    int unsigned s_cycles_after_m;
    bit saw_m_go;
    bit saw_wr_en;
    bit saw_empty_clear;
    bit saw_rd_en;
    bit saw_pend;
    bit saw_s_go_r;
    bit saw_s_go;
    realtime t_m_go;
    string marker;

    pf = $fopen("probe_table.csv", "w");
    if (pf == 0) begin
      $display("E2R_WDMA_CMDCDC_TB_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,clk,m_go,s_go,cmd_wr_en,cmd_full,cmd_empty,cmd_rd_en,cmd_pend,s_go_r");

    m_rst_n   = 1'b0;
    s_rst_n   = 1'b0;
    m_owner   = 1'b1;
    m_go      = 1'b0;
    m_wr      = 1'b1;
    m_addr    = 28'h000_1000;
    m_bytes   = 32'd64;
    m_w_valid = 1'b0;
    m_w_data  = '0;
    m_r_ready = 1'b1;
    s_w_ready = 1'b1;
    s_r_valid = 1'b0;
    s_r_data  = '0;
    s_busy    = 1'b0;
    s_done    = 1'b0;

    saw_m_go = 1'b0;
    saw_wr_en = 1'b0;
    saw_empty_clear = 1'b0;
    saw_rd_en = 1'b0;
    saw_pend = 1'b0;
    saw_s_go_r = 1'b0;
    saw_s_go = 1'b0;
    s_cycles_after_m = 0;
    t_m_go = 0;

    $display("E2R-WDMA-CMDCDC-TB-00 START m_period=80ns s_period=10ns window=%0d s_busy=0", S_WINDOW);

    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED T=%0t", $time);
    repeat (40) @(posedge m_clk);
    repeat (80) @(posedge s_clk);
    dump_row("post_recovery");
    $display("RECOVERY full=%0b empty=%0b", cmd_full, cmd_empty);

    @(posedge m_clk);
    m_go = 1'b1;
    saw_m_go = 1'b1;
    t_m_go = $realtime;
    if (cmd_wr_en) saw_wr_en = 1'b1;
    dump_row("m");
    $display("M_GO_PULSE T=%0t wr_en=%0b full=%0b empty=%0b", $time, cmd_wr_en, cmd_full, cmd_empty);

    @(posedge m_clk);
    if (cmd_wr_en) saw_wr_en = 1'b1;
    dump_row("m");
    m_go = 1'b0;
    @(posedge m_clk);
    dump_row("m");

    while (s_cycles_after_m < S_WINDOW) begin
      @(posedge s_clk);
      s_cycles_after_m++;
      if (!cmd_empty) saw_empty_clear = 1'b1;
      if (cmd_rd_en)  saw_rd_en = 1'b1;
      if (cmd_pend)   saw_pend = 1'b1;
      if (s_go_r)     saw_s_go_r = 1'b1;
      if (s_go)       saw_s_go = 1'b1;
      dump_row("s");
      if (s_go_r) begin
        $display("S_GO_R T=%0t s_cycles_after_m=%0d empty=%0b rd_en=%0b pend=%0b",
          $time, s_cycles_after_m, cmd_empty, cmd_rd_en, cmd_pend);
      end
      if (s_go) begin
        $display("S_GO T=%0t s_cycles_after_m=%0d addr=%h bytes=%0d wr=%0b",
          $time, s_cycles_after_m, s_addr, s_bytes, s_wr);
      end
    end

    repeat (8) @(posedge s_clk);
    dump_row("s");

    if (!saw_wr_en)            marker = "cmd_wr_en";
    else if (!saw_empty_clear) marker = "cmd_empty";
    else if (!saw_rd_en)       marker = "cmd_rd_en";
    else if (!saw_pend)        marker = "cmd_pend";
    else if (!saw_s_go_r)      marker = "s_go_r";
    else                       marker = "NONE";

    $display("SUMMARY m_go=%0b wr_en=%0b empty_clr=%0b rd_en=%0b pend=%0b s_go_r=%0b s_go=%0b s_cyc=%0d full_final=%0b empty_final=%0b",
      saw_m_go, saw_wr_en, saw_empty_clear, saw_rd_en, saw_pend, saw_s_go_r, saw_s_go,
      s_cycles_after_m, cmd_full, cmd_empty);
    $display("FIRST_MISSING_MARKER=%s", marker);
    $display("S_GO_SEEN=%0b S_GO_R_SEEN=%0b", saw_s_go, saw_s_go_r);
    $display("PROBE_TABLE=probe_table.csv");

    $fclose(pf);

    $display("E2R_WDMA_CMDCDC_TB_XSIM_PASS probes_recorded=1 s_go=%0b marker=%s window=%0d",
      saw_s_go, marker, S_WINDOW);
    $finish;
  end

  initial begin
    #200_000;
    $display("FIRST_MISSING_MARKER=timeout");
    $display("E2R_WDMA_CMDCDC_TB_XSIM_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
