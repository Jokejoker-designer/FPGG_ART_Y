`timescale 1ns / 1ps
// tb_e2r_rpath_idle_cxsim_00.sv — E2R-RPATH-IDLE-CXSIM-00
// Isolated a7ng_ddr_soa_axi_bridge. Name which of four wires holds r_path_idle=0
// after one SOA-complete AR/R drain. No product RTL. No r_path_idle bypass.
module tb_e2r_rpath_idle_cxsim_00;
  localparam realtime HALF = 5.0;
  localparam int unsigned SETTLE_A = 16;
  localparam int unsigned SETTLE_B = 8;
  localparam int unsigned BEATS    = 4;

  logic         clk, rst_n, metric_clear_i;
  logic         r_path_idle_o, r_fifo_empty_o;
  logic [2:0]   r_fifo_level_o;
  logic [31:0]  outstanding_beats_o;
  logic         ar_valid_i, ar_ready_o;
  logic [27:0]  ar_addr_i;
  logic [7:0]   ar_len_i;
  logic [3:0]   ar_id_i;
  logic [2:0]   ar_size_i;
  logic         r_valid_o, r_ready_i, r_last_o;
  logic [127:0] r_data_o;
  logic [3:0]   r_id_o;
  logic [3:0]   m_axi_arid, m_axi_rid;
  logic [27:0]  m_axi_araddr;
  logic [7:0]   m_axi_arlen;
  logic [2:0]   m_axi_arsize;
  logic [1:0]   m_axi_arburst, m_axi_rresp;
  logic         m_axi_arvalid, m_axi_arready;
  logic [127:0] m_axi_rdata;
  logic         m_axi_rlast, m_axi_rvalid, m_axi_rready;
  logic [31:0]  axi_read_bytes_o, axi_read_bursts_o, axi_read_beats_o;
  logic [31:0]  rresp_error_count_o, rlast_error_count_o;
  logic [31:0]  expected_records_o, received_records_o;
  logic [31:0]  rid_order_error_o, r_backpressure_cycles_o;

  integer pf;
  // Static (not automatic) — XSim force RHS cannot be an automatic variable.
  logic        iso_d, iso_v;
  logic [2:0]  iso_f;
  logic [4:0]  iso_t;

  a7ng_ddr_soa_axi_bridge dut (
    .clk(clk), .rst_n(rst_n),
    .metric_clear_i(metric_clear_i),
    .r_path_idle_o(r_path_idle_o),
    .r_fifo_empty_o(r_fifo_empty_o),
    .r_fifo_level_o(r_fifo_level_o),
    .outstanding_beats_o(outstanding_beats_o),
    .ar_valid_i(ar_valid_i), .ar_ready_o(ar_ready_o),
    .ar_addr_i(ar_addr_i), .ar_len_i(ar_len_i),
    .ar_id_i(ar_id_i), .ar_size_i(ar_size_i),
    .r_valid_o(r_valid_o), .r_ready_i(r_ready_i),
    .r_data_o(r_data_o), .r_last_o(r_last_o), .r_id_o(r_id_o),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .axi_read_bytes_o(axi_read_bytes_o),
    .axi_read_bursts_o(axi_read_bursts_o),
    .axi_read_beats_o(axi_read_beats_o),
    .rresp_error_count_o(rresp_error_count_o),
    .rlast_error_count_o(rlast_error_count_o),
    .expected_records_o(expected_records_o),
    .received_records_o(received_records_o),
    .rid_order_error_o(rid_order_error_o),
    .r_backpressure_cycles_o(r_backpressure_cycles_o)
  );

  initial clk = 1'b0;
  always #(HALF) clk = ~clk;

  wire        p_drain  = dut.r_drain_hold;
  wire [2:0]  p_fifo   = dut.fifo_cnt;
  wire [4:0]  p_tr     = dut.tr_cnt;
  wire        p_rvalid = m_axi_rvalid;

  function automatic int unsigned dirty_count;
    return (p_drain ? 1 : 0) + ((p_fifo != 3'd0) ? 1 : 0)
         + (p_rvalid ? 1 : 0) + ((p_tr != 5'd0) ? 1 : 0);
  endfunction

  task automatic dump_row(input string phase);
    begin
      $fdisplay(pf, "%0t,%s,%0b,%0d,%0b,%0d,%0b,%0d",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle_o, dirty_count());
      $display("PROBE t=%0t phase=%s drain=%0b fifo=%0d rvalid=%0b tr=%0d idle=%0b dirty=%0d",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle_o, dirty_count());
    end
  endtask

  task automatic pulse_metric_clear;
    begin
      @(posedge clk);
      metric_clear_i <= 1'b1;
      @(posedge clk);
      metric_clear_i <= 1'b0;
    end
  endtask

  task automatic issue_one_ar;
    begin
      @(posedge clk);
      ar_valid_i <= 1'b1;
      ar_addr_i  <= 28'h000_1000;
      ar_len_i   <= 8'(BEATS - 1);
      ar_id_i    <= 4'd0;
      ar_size_i  <= 3'd4;
      @(posedge clk);
      while (!(ar_valid_i && ar_ready_o)) @(posedge clk);
      ar_valid_i <= 1'b0;
    end
  endtask

  task automatic return_exact_beats;
    int unsigned i;
    begin
      for (i = 0; i < BEATS; i++) begin
        @(posedge clk);
        m_axi_rvalid <= 1'b1;
        m_axi_rid    <= 4'd0;
        m_axi_rdata  <= {96'd0, 32'(i)};
        m_axi_rresp  <= 2'b00;
        m_axi_rlast  <= (i == (BEATS - 1));
        @(posedge clk);
        while (!(m_axi_rvalid && m_axi_rready)) @(posedge clk);
      end
      m_axi_rvalid <= 1'b0;
      m_axi_rlast  <= 1'b0;
    end
  endtask

  // Combo isolation: leave one natural dirty, force the other three clean.
  // mask [3:0] = {tr, rvalid, fifo, drain} of independent holders.
  task isolate_leave_one(output logic [3:0] mask);
    begin
      iso_d = p_drain;
      iso_f = p_fifo;
      iso_v = p_rvalid;
      iso_t = p_tr;
      mask  = 4'b0000;

      force dut.fifo_cnt = 3'd0;
      force dut.tr_cnt   = 5'd0;
      m_axi_rvalid = 1'b0;
      force dut.r_drain_hold = iso_d;
      #1;
      if (!r_path_idle_o && iso_d)
        mask[0] = 1'b1;

      force dut.r_drain_hold = 1'b0;
      force dut.fifo_cnt     = iso_f;
      force dut.tr_cnt       = 5'd0;
      m_axi_rvalid = 1'b0;
      #1;
      if (!r_path_idle_o && (iso_f != 3'd0))
        mask[1] = 1'b1;

      force dut.r_drain_hold = 1'b0;
      force dut.fifo_cnt     = 3'd0;
      force dut.tr_cnt       = 5'd0;
      m_axi_rvalid = iso_v;
      #1;
      if (!r_path_idle_o && iso_v)
        mask[2] = 1'b1;

      force dut.r_drain_hold = 1'b0;
      force dut.fifo_cnt     = 3'd0;
      force dut.tr_cnt       = iso_t;
      m_axi_rvalid = 1'b0;
      #1;
      if (!r_path_idle_o && (iso_t != 5'd0))
        mask[3] = 1'b1;

      force dut.r_drain_hold = iso_d;
      force dut.fifo_cnt     = iso_f;
      force dut.tr_cnt       = iso_t;
      m_axi_rvalid = iso_v;
      #1;
      release dut.r_drain_hold;
      release dut.fifo_cnt;
      release dut.tr_cnt;
    end
  endtask

  function automatic int unsigned popcount4(input logic [3:0] m);
    return m[0] + m[1] + m[2] + m[3];
  endfunction

  function automatic string wire_of(input logic [3:0] m);
    begin
      if (m == 4'b0001) wire_of = "r_drain_hold";
      else if (m == 4'b0010) wire_of = "fifo_cnt";
      else if (m == 4'b0100) wire_of = "m_axi_rvalid";
      else if (m == 4'b1000) wire_of = "tr_cnt";
      else if (m == 4'b0000) wire_of = "NONE";
      else wire_of = "AMBIGUOUS";
    end
  endfunction

  task automatic force_clean_combo;
    begin
      force dut.r_drain_hold = 1'b0;
      force dut.fifo_cnt     = 3'd0;
      force dut.tr_cnt       = 5'd0;
      m_axi_rvalid = 1'b0;
      #1;
    end
  endtask

  task automatic release_forces;
    begin
      release dut.r_drain_hold;
      release dut.fifo_cnt;
      release dut.tr_cnt;
    end
  endtask

  initial begin
    int unsigned i;
    int unsigned n_indep_a, n_indep_b;
    int unsigned n_law;
    logic [3:0] mask_a, mask_b, mask_law;
    bit idle_a, idle_b, idle_rst;
    bit drain_a, rvalid_a, drain_b, rvalid_b;
    bit [2:0] fifo_a, fifo_b;
    bit [4:0] tr_a, tr_b;
    string wire_a, wire_b, wire_named, c_fix, verdict, next_u;
    bit law_ok;
    bit probes_ok;

    pf = $fopen("probe_table.csv", "w");
    if (pf == 0) begin
      $display("E2R_RPATH_IDLE_CXSIM_00_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,phase,r_drain_hold,fifo_cnt,m_axi_rvalid,tr_cnt,r_path_idle,dirty_count");

    rst_n          = 1'b0;
    metric_clear_i = 1'b0;
    ar_valid_i     = 1'b0;
    ar_addr_i      = 28'd0;
    ar_len_i       = 8'd0;
    ar_id_i        = 4'd0;
    ar_size_i      = 3'd4;
    r_ready_i      = 1'b1;
    m_axi_arready  = 1'b1;
    m_axi_rid      = 4'd0;
    m_axi_rdata    = '0;
    m_axi_rresp    = 2'b00;
    m_axi_rlast    = 1'b0;
    m_axi_rvalid   = 1'b0;
    mask_a = 4'b0000;
    mask_b = 4'b0000;
    mask_law = 4'b0000;
    n_indep_a = 0;
    n_indep_b = 0;
    n_law = 0;
    law_ok = 1'b1;
    probes_ok = 1'b0;

    $display("E2R-RPATH-IDLE-CXSIM-00 START beats=%0d settle_a=%0d settle_b=%0d",
      BEATS, SETTLE_A, SETTLE_B);

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);
    idle_rst = r_path_idle_o;
    dump_row("RESET");
    $display("RESET idle=%0b dirty=%0d (expect idle=1 dirty=0)", idle_rst, dirty_count());

    pulse_metric_clear;
    for (i = 0; i < 8; i++) begin
      @(posedge clk);
      if (r_path_idle_o)
        i = 8;
    end
    dump_row("POST_CLEAR_WAIT");

    issue_one_ar;
    dump_row("AR_ACCEPTED");
    return_exact_beats;
    dump_row("R_RETURNED");
    repeat (SETTLE_A) @(posedge clk);
    idle_a   = r_path_idle_o;
    drain_a  = p_drain;
    fifo_a   = p_fifo;
    rvalid_a = p_rvalid;
    tr_a     = p_tr;
    dump_row("PHASE_A_SOA_COMPLETE");
    if (!idle_a)
      isolate_leave_one(mask_a);
    else
      mask_a = 4'b0000;
    n_indep_a = popcount4(mask_a);
    wire_a = idle_a ? "NONE" : wire_of(mask_a);
    $display("PHASE_A idle=%0b drain=%0b fifo=%0d rvalid=%0b tr=%0d indep=%0d wire=%s mask=%b",
      idle_a, drain_a, fifo_a, rvalid_a, tr_a, n_indep_a, wire_a, mask_a);

    pulse_metric_clear;
    repeat (SETTLE_B) @(posedge clk);
    idle_b   = r_path_idle_o;
    drain_b  = p_drain;
    fifo_b   = p_fifo;
    rvalid_b = p_rvalid;
    tr_b     = p_tr;
    dump_row("PHASE_B_METRIC_CLEAR_AFTER");
    if (!idle_b)
      isolate_leave_one(mask_b);
    else
      mask_b = 4'b0000;
    n_indep_b = popcount4(mask_b);
    wire_b = idle_b ? "NONE" : wire_of(mask_b);
    $display("PHASE_B idle=%0b drain=%0b fifo=%0d rvalid=%0b tr=%0d indep=%0d wire=%s mask=%b",
      idle_b, drain_b, fifo_b, rvalid_b, tr_b, n_indep_b, wire_b, mask_b);

    // Phase C: each wire alone from a forced-clean quad (combo).
    force_clean_combo;
    dump_row("PHASE_C_CLEAN");
    if (r_path_idle_o !== 1'b1)
      law_ok = 1'b0;

    force dut.r_drain_hold = 1'b1;
    #1;
    dump_row("PHASE_C_FORCE_DRAIN");
    if (r_path_idle_o === 1'b0)
      mask_law[0] = 1'b1;
    else
      law_ok = 1'b0;
    force dut.r_drain_hold = 1'b0;
    #1;

    force dut.fifo_cnt = 3'd1;
    #1;
    dump_row("PHASE_C_FORCE_FIFO");
    if (r_path_idle_o === 1'b0)
      mask_law[1] = 1'b1;
    else
      law_ok = 1'b0;
    force dut.fifo_cnt = 3'd0;
    #1;

    m_axi_rvalid = 1'b1;
    #1;
    dump_row("PHASE_C_FORCE_RVALID");
    if (r_path_idle_o === 1'b0)
      mask_law[2] = 1'b1;
    else
      law_ok = 1'b0;
    m_axi_rvalid = 1'b0;
    #1;

    force dut.tr_cnt = 5'd1;
    #1;
    dump_row("PHASE_C_FORCE_TR");
    if (r_path_idle_o === 1'b0)
      mask_law[3] = 1'b1;
    else
      law_ok = 1'b0;
    force dut.tr_cnt = 5'd0;
    #1;
    dump_row("PHASE_C_RESTORE");
    n_law = popcount4(mask_law);
    release_forces;
    $display("PHASE_C law_ok=%0b n_law=%0d mask=%b (expect 4)", law_ok, n_law, mask_law);

    probes_ok = 1'b1;

    // Naming priority: Phase A UNIT, then Phase B if A is NONE.
    if (!idle_a) begin
      wire_named = wire_a;
      if (n_indep_a == 1)
        c_fix = wire_a;
      else
        c_fix = "NONE";
    end else if (!idle_b) begin
      wire_named = wire_b;
      if (n_indep_b == 1)
        c_fix = wire_b;
      else
        c_fix = "NONE";
    end else begin
      wire_named = "NONE";
      c_fix = "NONE";
    end

    if (wire_named == "r_drain_hold" && c_fix == "r_drain_hold")
      verdict = "H_CANDIDATE_SUPPORTED";
    else if (wire_named == "NONE")
      verdict = "NO_LEFTOVER_AFTER_SOA_COMPLETE";
    else if (wire_named == "AMBIGUOUS")
      verdict = "NOT_UNIQUE_NO_CFIX";
    else
      verdict = {"H_RIVAL_SUPPORTED_", wire_named};

    if (c_fix != "NONE")
      next_u = {"C-FIX exclusive board on ", c_fix};
    else if (wire_named == "NONE")
      next_u = "silicon leftover source (orphan rvalid / incomplete consumer / full-core probe), not this isolated complete drain";
    else
      next_u = "STOP — leftover not unique; no C-FIX";

    $display("RESET_IDLE=%0b PHASE_A_IDLE=%0b PHASE_B_IDLE=%0b LAW_OK=%0b",
      idle_rst, idle_a, idle_b, law_ok);
    $display("WIRE_THAT_HOLDS_IDLE_0=%s", wire_named);
    $display("C_FIX_CONSTITUENT=%s", c_fix);
    $display("VERDICT=%s", verdict);
    $display("NEXT_ONE_UNKNOWN=%s", next_u);
    $display("EXISTENCE=not_claimed");
    $display("BOARD_PASS=not_claimed");
    $fclose(pf);

    if (!probes_ok) begin
      $display("XSIM=FAIL");
      $display("E2R_RPATH_IDLE_CXSIM_00_XSIM_FAIL reason=probes");
      $fatal(1);
    end
    $display("XSIM=PASS");
    $display("E2R_RPATH_IDLE_CXSIM_00_XSIM_PASS probes_recorded=1 wire=%s c_fix=%s verdict=%s law_ok=%0b",
      wire_named, c_fix, verdict, law_ok);
    $finish;
  end
endmodule
