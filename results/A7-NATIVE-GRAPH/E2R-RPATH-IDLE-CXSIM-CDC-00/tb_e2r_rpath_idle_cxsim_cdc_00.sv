`timescale 1ns / 1ps
// tb_e2r_rpath_idle_cxsim_cdc_00.sv — E2R-RPATH-IDLE-CXSIM-CDC-00
// One AR/R through a7ng_axi_read_cdc into a7ng_ddr_soa_axi_bridge.
// Probe idle + four bridge wires + CDC rvalid/hold/empty.
// Not isolated no-CDC drain. Not stub-INT. No product RTL. No r_path_idle bypass.
module tb_e2r_rpath_idle_cxsim_cdc_00;
  localparam realtime M_HALF = 40.0;  // 80 ns → 12.5 MHz core
  localparam realtime S_HALF = 5.0;   // 10 ns → 100 MHz ui
  localparam int unsigned BEATS    = 4;
  localparam int unsigned SETTLE_M = 32;
  localparam int unsigned CONS_TO  = 2000;

  logic         m_clk, m_rst_n, s_clk, s_rst_n;
  logic         metric_clear_i;
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

  logic [3:0]   br_arid, cdc_rid;
  logic [27:0]  br_araddr;
  logic [7:0]   br_arlen;
  logic [2:0]   br_arsize;
  logic [1:0]   br_arburst, cdc_rresp;
  logic         br_arvalid, br_arready;
  logic [127:0] cdc_rdata;
  logic         cdc_rlast, cdc_rvalid, br_rready;

  logic [3:0]   s_arid, s_rid;
  logic [27:0]  s_araddr;
  logic [7:0]   s_arlen;
  logic [2:0]   s_arsize;
  logic [1:0]   s_arburst, s_rresp;
  logic         s_arvalid, s_arready;
  logic [127:0] s_rdata;
  logic         s_rlast, s_rvalid, s_rready;

  logic         dbg_r_ne, dbg_ar_ne, dbg_ar_hold, dbg_ar_empty;
  logic [31:0]  axi_read_bytes_o, axi_read_bursts_o, axi_read_beats_o;
  logic [31:0]  rresp_error_count_o, rlast_error_count_o;
  logic [31:0]  expected_records_o, received_records_o;
  logic [31:0]  rid_order_error_o, r_backpressure_cycles_o;

  integer pf;
  logic        iso_d, iso_v;
  logic [2:0]  iso_f;
  logic [4:0]  iso_t;

  a7ng_ddr_soa_axi_bridge u_br (
    .clk(m_clk), .rst_n(m_rst_n),
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
    .m_axi_arid(br_arid), .m_axi_araddr(br_araddr),
    .m_axi_arlen(br_arlen), .m_axi_arsize(br_arsize),
    .m_axi_arburst(br_arburst), .m_axi_arvalid(br_arvalid),
    .m_axi_arready(br_arready),
    .m_axi_rid(cdc_rid), .m_axi_rdata(cdc_rdata),
    .m_axi_rresp(cdc_rresp), .m_axi_rlast(cdc_rlast),
    .m_axi_rvalid(cdc_rvalid), .m_axi_rready(br_rready),
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

  a7ng_axi_read_cdc u_cdc (
    .m_clk(m_clk), .m_rst_n(m_rst_n),
    .m_axi_arid(br_arid), .m_axi_araddr(br_araddr),
    .m_axi_arlen(br_arlen), .m_axi_arsize(br_arsize),
    .m_axi_arburst(br_arburst),
    .m_axi_arvalid(br_arvalid), .m_axi_arready(br_arready),
    .m_axi_rid(cdc_rid), .m_axi_rdata(cdc_rdata),
    .m_axi_rresp(cdc_rresp), .m_axi_rlast(cdc_rlast),
    .m_axi_rvalid(cdc_rvalid), .m_axi_rready(br_rready),
    .s_clk(s_clk), .s_rst_n(s_rst_n),
    .s_axi_arid(s_arid), .s_axi_araddr(s_araddr),
    .s_axi_arlen(s_arlen), .s_axi_arsize(s_arsize),
    .s_axi_arburst(s_arburst),
    .s_axi_arvalid(s_arvalid), .s_axi_arready(s_arready),
    .s_axi_rid(s_rid), .s_axi_rdata(s_rdata),
    .s_axi_rresp(s_rresp), .s_axi_rlast(s_rlast),
    .s_axi_rvalid(s_rvalid), .s_axi_rready(s_rready),
    .dbg_r_ne_o(dbg_r_ne),
    .dbg_ar_ne_o(dbg_ar_ne),
    .dbg_ar_hold_o(dbg_ar_hold),
    .dbg_ar_empty_o(dbg_ar_empty)
  );

  // Autonomous s_clk slave: accept one AR, return exact beats.
  typedef enum logic [1:0] { S_IDLE = 2'd0, S_R = 2'd1 } s_st_t;
  s_st_t        s_st;
  logic [7:0]   s_left;
  logic [3:0]   s_id_h;
  int unsigned  s_beat_i;

  always_ff @(posedge s_clk or negedge s_rst_n) begin
    if (!s_rst_n) begin
      s_st      <= S_IDLE;
      s_left    <= 8'd0;
      s_id_h    <= 4'd0;
      s_beat_i  <= 0;
      s_rvalid  <= 1'b0;
      s_rlast   <= 1'b0;
      s_rdata   <= '0;
      s_rresp   <= 2'b00;
      s_rid     <= 4'd0;
    end else begin
      if (s_st == S_IDLE) begin
        s_rvalid <= 1'b0;
        s_rlast  <= 1'b0;
        if (s_arvalid && s_arready) begin
          s_left   <= s_arlen;
          s_id_h   <= s_arid;
          s_beat_i <= 0;
          s_st     <= S_R;
        end
      end else begin
        if (!s_rvalid) begin
          s_rvalid <= 1'b1;
          s_rid    <= s_id_h;
          s_rdata  <= {96'd0, 32'(s_beat_i)};
          s_rresp  <= 2'b00;
          s_rlast  <= (s_beat_i == 32'(s_left));
        end else if (s_rvalid && s_rready) begin
          if (s_beat_i == 32'(s_left)) begin
            s_rvalid <= 1'b0;
            s_rlast  <= 1'b0;
            s_st     <= S_IDLE;
          end else begin
            s_beat_i <= s_beat_i + 1;
            s_rdata  <= {96'd0, 32'(s_beat_i + 1)};
            s_rlast  <= ((s_beat_i + 1) == 32'(s_left));
          end
        end
      end
    end
  end
  assign s_arready = s_rst_n && (s_st == S_IDLE) && !s_rvalid;

  initial m_clk = 1'b0;
  always #(M_HALF) m_clk = ~m_clk;
  initial s_clk = 1'b0;
  always #(S_HALF) s_clk = ~s_clk;

  assign r_ready_i = 1'b1;

  wire        p_drain   = u_br.r_drain_hold;
  wire [2:0]  p_fifo    = u_br.fifo_cnt[2:0];
  wire [4:0]  p_tr      = u_br.tr_cnt[4:0];
  wire        p_rvalid  = cdc_rvalid;
  wire        p_mrv     = u_cdc.m_rvalid_r;
  wire        p_hold    = u_cdc.m_r_hold;
  wire        p_empty   = u_cdc.r_empty;
  wire        p_pend    = u_cdc.m_r_pend;
  wire        p_arhold  = u_cdc.s_ar_hold;
  wire [1:0]  p_armst   = u_cdc.ar_m_st;
  wire        p_cdc_q   = !p_mrv && !p_hold && p_empty && !p_pend && !p_arhold
                          && (p_armst == 2'd0);

  int unsigned cons_beats;
  bit          cons_last;
  always_ff @(posedge m_clk or negedge m_rst_n) begin
    if (!m_rst_n) begin
      cons_beats <= 0;
      cons_last  <= 1'b0;
    end else if (r_valid_o && r_ready_i) begin
      cons_beats <= cons_beats + 1;
      if (r_last_o)
        cons_last <= 1'b1;
    end
  end

  function automatic int unsigned dirty_count;
    return (p_drain ? 1 : 0) + ((p_fifo != 3'd0) ? 1 : 0)
         + (p_rvalid ? 1 : 0) + ((p_tr != 5'd0) ? 1 : 0);
  endfunction

  task automatic dump_row(input string phase);
    begin
      $fdisplay(pf, "%0t,%s,%0b,%0d,%0b,%0d,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0d,%0b,%0d,%0b",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle_o, dirty_count(),
        p_mrv, p_hold, p_empty, p_pend, p_arhold, p_armst, p_cdc_q, cons_beats, cons_last);
      $display("PROBE t=%0t phase=%s drain=%0b fifo=%0d rvalid=%0b tr=%0d idle=%0b dirty=%0d mrv=%0b hold=%0b empty=%0b pend=%0b arhold=%0b armst=%0d cdc_q=%0b cons=%0d last=%0b",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle_o, dirty_count(),
        p_mrv, p_hold, p_empty, p_pend, p_arhold, p_armst, p_cdc_q, cons_beats, cons_last);
    end
  endtask

  task automatic pulse_metric_clear;
    begin
      @(posedge m_clk);
      metric_clear_i <= 1'b1;
      @(posedge m_clk);
      metric_clear_i <= 1'b0;
    end
  endtask

  task automatic issue_one_ar;
    begin
      @(posedge m_clk);
      ar_valid_i <= 1'b1;
      ar_addr_i  <= 28'h000_1000;
      ar_len_i   <= 8'(BEATS - 1);
      ar_id_i    <= 4'd0;
      ar_size_i  <= 3'd4;
      @(posedge m_clk);
      while (!(ar_valid_i && ar_ready_o)) @(posedge m_clk);
      ar_valid_i <= 1'b0;
    end
  endtask

  task isolate_leave_one(output logic [3:0] mask);
    begin
      iso_d = p_drain;
      iso_f = p_fifo;
      iso_v = p_rvalid;
      iso_t = p_tr;
      mask  = 4'b0000;

      force u_br.fifo_cnt = 3'd0;
      force u_br.tr_cnt   = 5'd0;
      force u_cdc.m_rvalid_r = 1'b0;
      force u_br.r_drain_hold = iso_d;
      #1;
      if (!r_path_idle_o && iso_d)
        mask[0] = 1'b1;

      force u_br.r_drain_hold = 1'b0;
      force u_br.fifo_cnt     = iso_f;
      force u_br.tr_cnt       = 5'd0;
      force u_cdc.m_rvalid_r  = 1'b0;
      #1;
      if (!r_path_idle_o && (iso_f != 3'd0))
        mask[1] = 1'b1;

      force u_br.r_drain_hold = 1'b0;
      force u_br.fifo_cnt     = 3'd0;
      force u_br.tr_cnt       = 5'd0;
      force u_cdc.m_rvalid_r  = iso_v;
      #1;
      if (!r_path_idle_o && iso_v)
        mask[2] = 1'b1;

      force u_br.r_drain_hold = 1'b0;
      force u_br.fifo_cnt     = 3'd0;
      force u_br.tr_cnt       = iso_t;
      force u_cdc.m_rvalid_r  = 1'b0;
      #1;
      if (!r_path_idle_o && (iso_t != 5'd0))
        mask[3] = 1'b1;

      force u_br.r_drain_hold = iso_d;
      force u_br.fifo_cnt     = iso_f;
      force u_br.tr_cnt       = iso_t;
      force u_cdc.m_rvalid_r  = iso_v;
      #1;
      release u_br.r_drain_hold;
      release u_br.fifo_cnt;
      release u_br.tr_cnt;
      release u_cdc.m_rvalid_r;
    end
  endtask

  function automatic int unsigned popcount4(input logic [3:0] m);
    return m[0] + m[1] + m[2] + m[3];
  endfunction

  function automatic string wire_of(input logic [3:0] m);
    begin
      if (m == 4'b0001) wire_of = "r_drain_hold";
      else if (m == 4'b0010) wire_of = "fifo_cnt";
      else if (m == 4'b0100) wire_of = "m_rvalid_r";
      else if (m == 4'b1000) wire_of = "tr_cnt";
      else if (m == 4'b0000) wire_of = "NONE";
      else wire_of = "AMBIGUOUS";
    end
  endfunction

  task automatic force_clean_combo;
    begin
      force u_br.r_drain_hold = 1'b0;
      force u_br.fifo_cnt     = 3'd0;
      force u_br.tr_cnt       = 5'd0;
      force u_cdc.m_rvalid_r  = 1'b0;
      #1;
    end
  endtask

  task automatic release_forces;
    begin
      release u_br.r_drain_hold;
      release u_br.fifo_cnt;
      release u_br.tr_cnt;
      release u_cdc.m_rvalid_r;
    end
  endtask

  initial begin
    int unsigned i;
    int unsigned n_indep;
    logic [3:0] mask_u, mask_law;
    bit idle_u, idle_rst, idle_clr, law_ok, probes_ok, reached;
    bit drain_u, rvalid_u, hold_u, empty_u, pend_u, arhold_u, cdc_q_u;
    bit [2:0] fifo_u;
    bit [4:0] tr_u;
    bit [1:0] armst_u;
    string wire_named, c_fix, verdict, next_u;

    pf = $fopen("probe_table.csv", "w");
    if (pf == 0) begin
      $display("E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,phase,r_drain_hold,fifo_cnt,m_axi_rvalid,tr_cnt,r_path_idle,dirty_count,m_rvalid_r,m_r_hold,r_empty,m_r_pend,s_ar_hold,ar_m_st,cdc_quiet,cons_beats,cons_last");

    m_rst_n        = 1'b0;
    s_rst_n        = 1'b0;
    metric_clear_i = 1'b0;
    ar_valid_i     = 1'b0;
    ar_addr_i      = 28'd0;
    ar_len_i       = 8'd0;
    ar_id_i        = 4'd0;
    ar_size_i      = 3'd4;
    mask_u   = 4'b0000;
    mask_law = 4'b0000;
    n_indep  = 0;
    law_ok   = 1'b1;
    probes_ok = 1'b0;
    reached  = 1'b0;

    $display("E2R-RPATH-IDLE-CXSIM-CDC-00 START beats=%0d settle_m=%0d m_period=80ns s_period=10ns",
      BEATS, SETTLE_M);
    $display("PREREG_UNKNOWN: after one completed AR/R through CDC into SOA bridge, leftover idle=0?");
    $display("VEHICLE=soa_bridge+axi_read_cdc PRIOR=isolated_NONE+stubINT_NONE");

    repeat (25) @(posedge m_clk);
    m_rst_n = 1'b1;
    s_rst_n = 1'b1;
    $display("RESET_RELEASED t=%0t", $time);
    repeat (20) @(posedge m_clk);
    repeat (40) @(posedge s_clk);
    idle_rst = r_path_idle_o;
    dump_row("RESET");

    pulse_metric_clear;
    for (i = 0; i < 16; i++) begin
      @(posedge m_clk);
      if (r_path_idle_o)
        i = 16;
    end
    idle_clr = r_path_idle_o;
    dump_row("POST_CLEAR");

    issue_one_ar;
    dump_row("AR_ACCEPTED");

    for (i = 0; i < CONS_TO; i++) begin
      @(posedge m_clk);
      if ((cons_beats >= BEATS) && cons_last)
        i = CONS_TO;
    end
    dump_row("R_CONSUMED");
    if ((cons_beats < BEATS) || !cons_last) begin
      $display("XSIM=FAIL");
      $display("E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_FAIL reason=consumer_timeout cons=%0d last=%0b",
        cons_beats, cons_last);
      $fclose(pf);
      $fatal(1);
    end
    reached = 1'b1;

    repeat (SETTLE_M) @(posedge m_clk);
    idle_u    = r_path_idle_o;
    drain_u   = p_drain;
    fifo_u    = p_fifo;
    rvalid_u  = p_rvalid;
    tr_u      = p_tr;
    hold_u    = p_hold;
    empty_u   = p_empty;
    pend_u    = p_pend;
    arhold_u  = p_arhold;
    armst_u   = p_armst;
    cdc_q_u   = p_cdc_q;
    dump_row("UNIT_CDC_SOA_SETTLE");

    if (!idle_u)
      isolate_leave_one(mask_u);
    else
      mask_u = 4'b0000;
    n_indep = popcount4(mask_u);
    wire_named = idle_u ? "NONE" : wire_of(mask_u);
    $display("UNIT idle=%0b drain=%0b fifo=%0d rvalid=%0b tr=%0d mrv=%0b hold=%0b empty=%0b pend=%0b arhold=%0b armst=%0d cdc_q=%0b indep=%0d wire=%s mask=%b",
      idle_u, drain_u, fifo_u, rvalid_u, tr_u, rvalid_u, hold_u, empty_u, pend_u,
      arhold_u, armst_u, cdc_q_u, n_indep, wire_named, mask_u);

    force_clean_combo;
    dump_row("PHASE_C_CLEAN");
    if (r_path_idle_o !== 1'b1)
      law_ok = 1'b0;
    force u_cdc.m_rvalid_r = 1'b1;
    #1;
    dump_row("PHASE_C_FORCE_MRVALID_R");
    if (r_path_idle_o === 1'b0)
      mask_law[2] = 1'b1;
    else
      law_ok = 1'b0;
    force u_cdc.m_rvalid_r = 1'b0;
    #1;
    dump_row("PHASE_C_RESTORE");
    release_forces;
    $display("PHASE_C law_ok=%0b m_rvalid_r_holds_idle0=%0b", law_ok, mask_law[2]);

    probes_ok = 1'b1;

    if (!idle_u) begin
      if (n_indep == 1)
        c_fix = wire_named;
      else
        c_fix = "NONE";
      if (wire_named == "m_rvalid_r" || wire_named == "m_r_hold")
        verdict = "H_CANDIDATE_SUPPORTED";
      else if (wire_named == "AMBIGUOUS")
        verdict = "NOT_UNIQUE_NO_CFIX";
      else
        verdict = {"H_CANDIDATE_BRIDGE_OR_CDC_", wire_named};
    end else begin
      wire_named = "NONE";
      c_fix = "NONE";
      if (cdc_q_u)
        verdict = "H_RIVAL_CDC_QUIET_NO_CFIX";
      else
        verdict = "H_RIVAL_IDLE_1_CDC_NOT_QUIET";
    end

    if (c_fix != "NONE")
      next_u = {"C-FIX exclusive board on ", c_fix};
    else if (idle_u && cdc_q_u)
      next_u = "silicon leftover is mux/tile dest-wait (not CDC leftover after SOA-complete)";
    else if (idle_u)
      next_u = "CDC not quiet but idle=1 — no C-FIX; leftover does not hold idle";
    else
      next_u = "STOP — leftover not unique; no C-FIX";

    $display("RESET_IDLE=%0b POST_CLEAR_IDLE=%0b UNIT_IDLE=%0b CDC_QUIET=%0b LAW_OK=%0b REACHED=%0b",
      idle_rst, idle_clr, idle_u, cdc_q_u, law_ok, reached);
    $display("WIRE_THAT_HOLDS_IDLE_0=%s", wire_named);
    $display("C_FIX_CONSTITUENT=%s", c_fix);
    $display("VERDICT=%s", verdict);
    $display("NEXT_ONE_UNKNOWN=%s", next_u);
    $display("EXISTENCE=not_claimed");
    $display("BOARD_PASS=not_claimed");
    $fclose(pf);

    if (!probes_ok) begin
      $display("XSIM=FAIL");
      $display("E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_FAIL reason=probes");
      $fatal(1);
    end
    $display("XSIM=PASS");
    $display("E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_PASS probes_recorded=1 wire=%s c_fix=%s verdict=%s law_ok=%0b idle=%0b cdc_q=%0b",
      wire_named, c_fix, verdict, law_ok, idle_u, cdc_q_u);
    $finish;
  end

  initial begin
    #500_000;
    $display("XSIM=FAIL");
    $display("E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_FAIL reason=timeout");
    $fatal(1);
  end
endmodule
