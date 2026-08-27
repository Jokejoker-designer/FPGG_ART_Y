`timescale 1ns / 1ps
// tb_e2r_rpath_idle_cxsim_int_00.sv — E2R-RPATH-IDLE-CXSIM-INT-00
// Integrated SOA + consumer (a7ng_cue_soa_mig_top). Probe r_path_idle and
// four constituents at SOA-done. No product RTL. No r_path_idle bypass.
// Not the isolated complete-drain TB. TILE_DST is not present and not faked.
module tb_e2r_rpath_idle_cxsim_int_00;
  import a7ng_pkg::*;

  localparam int TOTAL = 64;
  localparam int N_PRE = 64;
  localparam int unsigned SETTLE = 16;
  localparam int unsigned SOA_TO = 200000;

  logic clk = 1'b0;
  logic rst_n;
  always #5 clk = ~clk;

  logic [3:0]  arid, rid, awid, bid;
  logic [27:0] araddr, awaddr;
  logic [7:0]  arlen, awlen;
  logic [2:0]  arsize, awsize;
  logic [1:0]  arburst, awburst, rresp, bresp;
  logic        arvalid, arready, rlast, rvalid, rready;
  logic        awvalid, awready, wlast, wvalid, wready, bvalid, bready;
  logic [127:0] rdata, wdata;
  logic [15:0]  wstrb;

  logic start, cons_ready;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node, total_recs;
  logic done, running, owner_ready, r_path_idle;
  logic [31:0] axi_bytes, axi_beats, axi_bursts;
  logic [31:0] id_beats, cue_beats, prior_beats, delivered, waves;
  logic [31:0] topk_batches;
  logic        topk_valid;
  score_t      topk_score [8];
  node_id_t    topk_id [8];

  assign cons_ready = 1'b1;

  a7ng_axi_soa_mem_stub u_mem (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
    .s_axi_awsize(awsize), .s_axi_awburst(awburst),
    .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
    .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  a7ng_cue_soa_mig_top #(.WAVE(16), .MAX_CANDS(TOTAL), .MAX_OUT(8), .MAX_BURST(16)) dut (
    .clk(clk), .rst_n(rst_n),
    .start_i(start), .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .cons_ready_i(cons_ready),
    .q_query_cue_i(64'hA5A5_0F0F_1234_5678),
    .q_intent_cue_i(64'h1111_2222_3333_4444),
    .q_relation_cue_i(64'h0F1E_2D3C_4B5A_6978),
    .q_context_cue_i(64'hDEAD_BEEF_CAFE_0001),
    .q_path_cue_i(64'h00FF_00FF_00FF_00FF),
    .done_o(done), .running_o(running),
    .cycles_o(), .waves_o(waves), .cand_delivered_o(delivered),
    .data_mismatch_o(), .swap_count_o(),
    .buffer_empty_stall_o(), .buffer_full_stall_o(),
    .soa_id_beats_o(id_beats), .soa_cue_beats_o(cue_beats),
    .soa_prior_beats_o(prior_beats),
    .bytes_id_o(), .bytes_cue_o(), .bytes_prior_o(), .bytes_total_o(),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts),
    .axi_read_beats_o(axi_beats),
    .expected_records_o(), .received_records_o(),
    .rresp_error_count_o(), .rlast_error_count_o(),
    .rid_order_error_o(), .r_backpressure_cycles_o(),
    .topk_batches_o(topk_batches), .topk_valid_o(topk_valid),
    .topk_score_o(topk_score), .topk_id_o(topk_id),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(r_path_idle)
  );

  wire        p_drain  = dut.u_br.r_drain_hold;
  wire [2:0]  p_fifo   = dut.u_br.fifo_cnt[2:0];
  wire [4:0]  p_tr     = dut.u_br.tr_cnt[4:0];
  wire        p_rvalid = rvalid;
  wire        p_mc     = dut.metric_clear;
  wire        p_rvo    = dut.r_valid;
  wire        p_rri    = dut.r_ready;
  wire [1:0]  p_own    = dut.owner_st;

  int unsigned mc_count;
  int unsigned mc_after_start;
  bit          start_seen;
  bit          running_seen;
  integer      pf;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mc_count        <= 0;
      mc_after_start  <= 0;
      start_seen      <= 1'b0;
      running_seen    <= 1'b0;
    end else begin
      if (start)
        start_seen <= 1'b1;
      if (running)
        running_seen <= 1'b1;
      if (p_mc) begin
        mc_count <= mc_count + 1;
        if (start_seen)
          mc_after_start <= mc_after_start + 1;
      end
    end
  end

  function automatic int unsigned dirty_count;
    return (p_drain ? 1 : 0) + ((p_fifo != 3'd0) ? 1 : 0)
         + (p_rvalid ? 1 : 0) + ((p_tr != 5'd0) ? 1 : 0);
  endfunction

  task automatic dump_row(input string phase);
    begin
      $fdisplay(pf, "%0t,%s,%0b,%0d,%0b,%0d,%0b,%0d,%0d,%0d,%0b,%0b,%0d,%0b,%0b,%0d,%0d",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle, dirty_count(),
        mc_count, mc_after_start, p_rvo, p_rri, p_own, done, running,
        axi_beats, delivered);
      $display("PROBE t=%0t phase=%s drain=%0b fifo=%0d rvalid=%0b tr=%0d idle=%0b dirty=%0d mc=%0d mc_as=%0d rvo=%0b rri=%0b own=%0d done=%0b run=%0b beats=%0d del=%0d tile_dst=ABSENT",
        $time, phase, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle, dirty_count(),
        mc_count, mc_after_start, p_rvo, p_rri, p_own, done, running,
        axi_beats, delivered);
    end
  endtask

  logic        iso_d, iso_v;
  logic [2:0]  iso_f;
  logic [4:0]  iso_t;

  task isolate_leave_one(output logic [3:0] mask);
    begin
      iso_d = p_drain;
      iso_f = p_fifo;
      iso_v = p_rvalid;
      iso_t = p_tr;
      mask  = 4'b0000;

      force dut.u_br.fifo_cnt = '0;
      force dut.u_br.tr_cnt   = '0;
      force rvalid = 1'b0;
      force dut.u_br.r_drain_hold = iso_d;
      #1;
      if (!r_path_idle && iso_d)
        mask[0] = 1'b1;

      force dut.u_br.r_drain_hold = 1'b0;
      force dut.u_br.fifo_cnt     = iso_f;
      force dut.u_br.tr_cnt       = '0;
      force rvalid = 1'b0;
      #1;
      if (!r_path_idle && (iso_f != 3'd0))
        mask[1] = 1'b1;

      force dut.u_br.r_drain_hold = 1'b0;
      force dut.u_br.fifo_cnt     = '0;
      force dut.u_br.tr_cnt       = '0;
      force rvalid = iso_v;
      #1;
      if (!r_path_idle && iso_v)
        mask[2] = 1'b1;

      force dut.u_br.r_drain_hold = 1'b0;
      force dut.u_br.fifo_cnt     = '0;
      force dut.u_br.tr_cnt       = iso_t;
      force rvalid = 1'b0;
      #1;
      if (!r_path_idle && (iso_t != 5'd0))
        mask[3] = 1'b1;

      force dut.u_br.r_drain_hold = iso_d;
      force dut.u_br.fifo_cnt     = iso_f;
      force dut.u_br.tr_cnt       = iso_t;
      force rvalid = iso_v;
      #1;
      release dut.u_br.r_drain_hold;
      release dut.u_br.fifo_cnt;
      release dut.u_br.tr_cnt;
      release rvalid;
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

  function automatic logic [31:0] golden_cue32(input logic [31:0] nid);
    return 32'hDDFE_0000 + nid;
  endfunction

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = golden_cue32(nid);
    return {c32, c32};
  endfunction

  task automatic preload_soa_planes(input int n);
    int b, k, pi;
    logic [127:0] beat;
    begin
      for (b = 0; b < (n+3)/4; b++) begin
        beat = '0;
        for (k = 0; k < 4; k++) begin
          pi = b*4 + k;
          if (pi < n) beat[k*32 +: 32] = 32'(pi);
        end
        u_mem.poke128(NG_DDR_NODE_BASE + b*16, beat);
      end
      for (b = 0; b < (n+1)/2; b++) begin
        beat = '0;
        for (k = 0; k < 2; k++) begin
          pi = b*2 + k;
          if (pi < n) beat[k*64 +: 64] = golden_cue64(32'(pi));
        end
        u_mem.poke128(NG_DDR_CUE64_BASE + b*16, beat);
      end
      for (b = 0; b < (n+15)/16; b++) begin
        beat = '0;
        for (k = 0; k < 16; k++) begin
          pi = b*16 + k;
          if (pi < n) beat[k*8 +: 8] = 8'h03;
        end
        u_mem.poke128(NG_DDR_PRIOR_BASE + b*16, beat);
      end
      $display("SOA_PRELOAD_DONE candidates=%0d", n);
    end
  endtask

  initial begin
    int unsigned i;
    int unsigned timeout;
    int unsigned n_indep;
    logic [3:0] mask_u;
    bit idle_u, drain_u, rvalid_u, reached;
    bit [2:0] fifo_u;
    bit [4:0] tr_u;
    string wire_named, c_fix, verdict, next_u, xsim_tag;
    bit probes_ok;

    pf = $fopen("probe_table.csv", "w");
    if (pf == 0) begin
      $display("E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,phase,r_drain_hold,fifo_cnt,m_axi_rvalid,tr_cnt,r_path_idle,dirty_count,mc_count,mc_after_start,br_rvalid,br_rready,owner_st,soa_done,soa_running,axi_beats,delivered");

    rst_n = 1'b0;
    start = 1'b0;
    burst = 5'd16;
    outstanding = 4'd8;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;
    mask_u = 4'b0000;
    n_indep = 0;
    reached = 1'b0;
    probes_ok = 1'b0;

    $display("E2R-RPATH-IDLE-CXSIM-INT-00 START");
    $display("VEHICLE=a7ng_cue_soa_mig_top+axi_stub MIG_TB=not_bounded TILE_DST=ABSENT_NOT_FAKED");
    $display("PREREG_UNKNOWN: after integrated SOA-done, which leftover holds r_path_idle=0?");
    $display("PREREG_H_CANDIDATE: incomplete consumer / orphan m_axi_rvalid or tr_cnt");
    $display("PREREG_H_RIVAL: second metric_clear / boot overlap holds r_drain_hold");
    $display("PREREG_UNIT: one query to soa_done+settle; TILE_DST not faked");

    preload_soa_planes(N_PRE);
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (20) @(posedge clk);
    dump_row("RESET");

    begin
      int ow;
      ow = 0;
      while (!owner_ready && ow < 500_000) begin
        @(posedge clk);
        ow = ow + 1;
      end
      if (owner_ready !== 1'b1)
        $display("SOA_OWNER_READY_TIMEOUT");
      else
        $display("SOA_OWNER_READY ok cycles=%0d", ow);
    end
    dump_row("OWNER_READY");

    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    $display("SOA_QUERY_START t=%0t", $time);

    timeout = 0;
    while (done !== 1'b1 && timeout < SOA_TO) begin
      @(posedge clk);
      timeout = timeout + 1;
      if (timeout == 1)
        dump_row("POST_START_1");
      if (p_mc)
        dump_row("METRIC_CLEAR");
      if (running && !running_seen)
        dump_row("RUNNING_RISE");
    end

    if (done === 1'b1) begin
      reached = 1'b1;
      dump_row("SOA_DONE");
      repeat (SETTLE) @(posedge clk);
      dump_row("UNIT_SOA_DONE_SETTLE");
    end else begin
      $display("SOA_DONE_LIMIT timeout=%0d beats=%0d delivered=%0d run=%0b idle=%0b",
        timeout, axi_beats, delivered, running, r_path_idle);
      dump_row("LIMIT_NO_SOA_DONE");
    end

    idle_u   = r_path_idle;
    drain_u  = p_drain;
    fifo_u   = p_fifo;
    rvalid_u = p_rvalid;
    tr_u     = p_tr;

    if (reached && !idle_u)
      isolate_leave_one(mask_u);
    else
      mask_u = 4'b0000;
    n_indep = popcount4(mask_u);
    if (!reached)
      wire_named = idle_u ? "NONE" : (dirty_count() == 1 ? wire_of(
        {tr_u != 5'd0, rvalid_u, fifo_u != 3'd0, drain_u}) : "AMBIGUOUS");
    else if (idle_u)
      wire_named = "NONE";
    else
      wire_named = wire_of(mask_u);

    if (idle_u)
      c_fix = "NONE";
    else if (n_indep == 1)
      c_fix = wire_named;
    else
      c_fix = "NONE";

    if (!reached) begin
      verdict = "LIMIT_SOA_DONE_NOT_REACHED";
      next_u  = "bounded integrated path did not reach soa_done; do not fake TILE_DST=4";
      xsim_tag = "LIMIT";
    end else if (wire_named == "NONE") begin
      verdict = "NO_LEFTOVER_AFTER_INTEGRATED_SOA_DONE";
      next_u  = "silicon leftover is outside this stub-integrated TB (MIG/CDC/tile dest-wait / host mux)";
      xsim_tag = "PASS";
    end else if (wire_named == "AMBIGUOUS") begin
      verdict = "NOT_UNIQUE_NO_CFIX";
      next_u  = "STOP — leftover not unique; no C-FIX";
      xsim_tag = "PASS";
    end else if (wire_named == "r_drain_hold" && mc_after_start >= 2) begin
      verdict = "H_RIVAL_SUPPORTED";
      next_u  = "C-FIX exclusive: second metric_clear / r_drain_hold hold";
      xsim_tag = "PASS";
    end else if (wire_named == "r_drain_hold") begin
      verdict = "DRAIN_HOLD_AFTER_ONE_CLEAR";
      next_u  = "why first metric_clear hold did not release after integrated SOA-done";
      xsim_tag = "PASS";
    end else begin
      verdict = {"H_CANDIDATE_SUPPORTED_", wire_named};
      next_u  = {"C-FIX exclusive board on ", wire_named};
      xsim_tag = "PASS";
    end

    probes_ok = 1'b1;
    $display("REACHED_SOA_DONE=%0b UNIT_IDLE=%0b DRAIN=%0b FIFO=%0d RVALID=%0b TR=%0d MC=%0d MC_AFTER_START=%0d",
      reached, idle_u, drain_u, fifo_u, rvalid_u, tr_u, mc_count, mc_after_start);
    $display("TILE_DST=ABSENT_NOT_FAKED");
    $display("MIG_TB=NOT_BOUNDED");
    $display("WIRE_THAT_HOLDS_IDLE_0=%s", wire_named);
    $display("C_FIX_CONSTITUENT=%s", c_fix);
    $display("VERDICT=%s", verdict);
    $display("NEXT_ONE_UNKNOWN=%s", next_u);
    $display("EXISTENCE=not_claimed");
    $display("BOARD_PASS=not_claimed");
    $fclose(pf);

    if (!probes_ok) begin
      $display("XSIM=FAIL");
      $display("E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_FAIL reason=probes");
      $fatal(1);
    end
    $display("XSIM=%s", xsim_tag);
    $display("E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_%s probes_recorded=1 wire=%s c_fix=%s verdict=%s reached=%0b",
      xsim_tag, wire_named, c_fix, verdict, reached);
    $finish;
  end

  initial begin
    #50ms;
    $display("WALL_LIMIT");
    $display("XSIM=LIMIT");
    $display("E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_LIMIT reason=wall");
    $finish;
  end
endmodule
