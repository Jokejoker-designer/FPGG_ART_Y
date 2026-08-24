// tb_a7ng_ddr_wavefront.sv — ddr_wavefront_00 on the Digilent AXI MIG
// UNKNOWN: from correctly measured MIG, can a BOUNDED candidate/cue working set feed
//          16 PHYSICAL lanes with EXACTLY measured traffic?
// H_CANDIDATE: bounded ping/pong compact-cue working set sustains 16-wide waves with
//              conserved records and measured, explainable DDR traffic.
// H_RIVAL: healthy only because traffic is cumulative/unconserved, or the "16-wide wave"
//          is a <=1 candidate/cycle service renamed.
// FALSIFIER: record/data non-conservation; cumulative sold as per-run; invented GB/s;
//            frozen law change; board claim; PE utilisation declared a pass.
// CONTROL: MIG-METRIC-00 per-run deltas — burst=1 -> 1024B/64 bursts; burst=4 -> 1024B/16.
// UNIT: one query (TOTAL=64 candidates), 4 distinct traffic patterns.
// Evidence_class: MIG_XSIM_WAVEFRONT — not BOARD, not HS-02.
`timescale 1ps / 100fs

module tb_a7ng_ddr_wavefront;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int N_LANES = 16;
  localparam int ENT_PB  = 16;                    // 16 banks x 16 = 256-candidate bound
  localparam int WS_BOUND = N_LANES * ENT_PB;
  localparam int TOTAL   = 64;                    // candidates per query (MIG sim wall-clock)
  localparam int N_PRE   = 128;                   // preloaded NodeRecordV1

  localparam COL_WIDTH   = 10;
  localparam CS_WIDTH    = 1;
  localparam DM_WIDTH    = 2;
  localparam DQ_WIDTH    = 16;
  localparam DQS_WIDTH   = 2;
  localparam ROW_WIDTH   = 14;
  localparam ODT_WIDTH   = 1;
  localparam RANKS       = 1;
  localparam ADDR_WIDTH  = 28;
  localparam CLKIN_PERIOD = 6000;
  localparam real REFCLK_FREQ = 200.0;
  localparam real REFCLK_PERIOD = (1000000.0/(2*REFCLK_FREQ));
  localparam RESET_PERIOD = 200000;
  localparam RST_ACT_LOW = 1;
  localparam MEMORY_WIDTH = 16;
  localparam NUM_COMP = DQ_WIDTH/MEMORY_WIDTH;
  localparam real TPROP_DQS = 0.00;
  localparam real TPROP_DQS_RD = 0.00;
  localparam real TPROP_PCB_CTRL = 0.00;
  localparam real TPROP_PCB_DATA = 0.00;
  localparam real TPROP_PCB_DATA_RD = 0.00;

  reg sys_rst_n;
  wire sys_rst;
  reg sys_clk_i;
  reg clk_ref_i;

  wire init_calib_complete;
  wire ui_clk, ui_rst, mmcm_locked;
  wire ddr3_reset_n;
  wire [DQ_WIDTH-1:0]  ddr3_dq_fpga;
  wire [DQS_WIDTH-1:0] ddr3_dqs_p_fpga, ddr3_dqs_n_fpga;
  wire [ROW_WIDTH-1:0] ddr3_addr_fpga;
  wire [2:0]           ddr3_ba_fpga;
  wire ddr3_ras_n_fpga, ddr3_cas_n_fpga, ddr3_we_n_fpga;
  wire [0:0] ddr3_cke_fpga, ddr3_ck_p_fpga, ddr3_ck_n_fpga, ddr3_cs_n_fpga, ddr3_odt_fpga;
  wire [DM_WIDTH-1:0] ddr3_dm_fpga;

  wire [DQ_WIDTH-1:0]  ddr3_dq_sdram;
  reg  [ROW_WIDTH-1:0] ddr3_addr_sdram [0:1];
  reg  [2:0]           ddr3_ba_sdram [0:1];
  reg  ddr3_ras_n_sdram, ddr3_cas_n_sdram, ddr3_we_n_sdram;
  wire [0:0] ddr3_cs_n_sdram, ddr3_odt_sdram, ddr3_cke_sdram;
  wire [DM_WIDTH-1:0] ddr3_dm_sdram;
  wire [DQS_WIDTH-1:0] ddr3_dqs_p_sdram, ddr3_dqs_n_sdram;
  reg  [0:0] ddr3_ck_p_sdram, ddr3_ck_n_sdram;
  reg  [0:0] ddr3_cs_n_sdram_tmp, ddr3_odt_sdram_tmp;
  reg  [DM_WIDTH-1:0] ddr3_dm_sdram_tmp;
  reg  [0:0] ddr3_cke_sdram_r;

  // AXI mux: preload writes then wavefront reads
  logic feed_en;
  logic [3:0]  awid, arid_w, arid_f, arid, rid;
  logic [27:0] awaddr, araddr_w, araddr_f, araddr;
  logic [7:0]  awlen, arlen_w, arlen_f, arlen;
  logic [2:0]  awsize, arsize_w, arsize_f, arsize;
  logic [1:0]  awburst, arburst_w, arburst_f, arburst;
  logic        awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic        arvalid_w, arvalid_f, arvalid, arready;
  logic        rvalid, rready_w, rready_f, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0]  wstrb;
  logic [3:0]   bid;
  logic [1:0]   bresp, rresp;

  assign arid    = feed_en ? arid_f    : arid_w;
  assign araddr  = feed_en ? araddr_f  : araddr_w;
  assign arlen   = feed_en ? arlen_f   : arlen_w;
  assign arsize  = feed_en ? arsize_f  : arsize_w;
  assign arburst = feed_en ? arburst_f : arburst_w;
  assign arvalid = feed_en ? arvalid_f : arvalid_w;
  assign rready  = feed_en ? rready_f  : rready_w;

  initial begin
    sys_rst_n = 1'b0;
    #RESET_PERIOD sys_rst_n = 1'b1;
  end
  assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  initial sys_clk_i = 1'b0;
  always sys_clk_i = #(CLKIN_PERIOD/2.0) ~sys_clk_i;
  initial clk_ref_i = 1'b0;
  always clk_ref_i = #REFCLK_PERIOD ~clk_ref_i;

  always @(*) begin
    ddr3_ck_p_sdram    <= #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
    ddr3_ck_n_sdram    <= #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
    ddr3_addr_sdram[0] <= #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_addr_sdram[1] <= #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_ba_sdram[0]   <= #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ba_sdram[1]   <= #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ras_n_sdram   <= #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
    ddr3_cas_n_sdram   <= #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
    ddr3_we_n_sdram    <= #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
    ddr3_cke_sdram_r   <= #(TPROP_PCB_CTRL) ddr3_cke_fpga;
  end
  assign ddr3_cke_sdram = ddr3_cke_sdram_r;
  always @(*) ddr3_cs_n_sdram_tmp <= #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;
  assign ddr3_cs_n_sdram = ddr3_cs_n_sdram_tmp;
  always @(*) ddr3_dm_sdram_tmp <= #(TPROP_PCB_DATA) ddr3_dm_fpga;
  assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;
  always @(*) ddr3_odt_sdram_tmp <= #(TPROP_PCB_CTRL) ddr3_odt_fpga;
  assign ddr3_odt_sdram = ddr3_odt_sdram_tmp;

  genvar dqwd;
  generate
    for (dqwd = 0; dqwd < DQ_WIDTH; dqwd = dqwd+1) begin : dq_delay
      WireDelay #(.Delay_g(TPROP_PCB_DATA), .Delay_rd(TPROP_PCB_DATA_RD), .ERR_INSERT("OFF"))
        u_delay_dq (.A(ddr3_dq_fpga[dqwd]), .B(ddr3_dq_sdram[dqwd]),
                    .reset(sys_rst_n), .phy_init_done(init_calib_complete));
    end
  endgenerate
  genvar dqswd;
  generate
    for (dqswd = 0; dqswd < DQS_WIDTH; dqswd = dqswd+1) begin : dqs_delay
      WireDelay #(.Delay_g(TPROP_DQS), .Delay_rd(TPROP_DQS_RD), .ERR_INSERT("OFF"))
        u_dqs_p (.A(ddr3_dqs_p_fpga[dqswd]), .B(ddr3_dqs_p_sdram[dqswd]),
                 .reset(sys_rst_n), .phy_init_done(init_calib_complete));
      WireDelay #(.Delay_g(TPROP_DQS), .Delay_rd(TPROP_DQS_RD), .ERR_INSERT("OFF"))
        u_dqs_n (.A(ddr3_dqs_n_fpga[dqswd]), .B(ddr3_dqs_n_sdram[dqswd]),
                 .reset(sys_rst_n), .phy_init_done(init_calib_complete));
    end
  endgenerate

  mig_native_wrap u_mig (
    .sys_clk_i(sys_clk_i), .clk_ref_i(clk_ref_i), .sys_rst_n(sys_rst),
    .ui_clk(ui_clk), .ui_rst(ui_rst), .init_calib_complete(init_calib_complete),
    .mmcm_locked(mmcm_locked),
    .ddr3_addr(ddr3_addr_fpga), .ddr3_ba(ddr3_ba_fpga),
    .ddr3_cas_n(ddr3_cas_n_fpga), .ddr3_ck_n(ddr3_ck_n_fpga), .ddr3_ck_p(ddr3_ck_p_fpga),
    .ddr3_cke(ddr3_cke_fpga), .ddr3_cs_n(ddr3_cs_n_fpga),
    .ddr3_ras_n(ddr3_ras_n_fpga), .ddr3_reset_n(ddr3_reset_n), .ddr3_we_n(ddr3_we_n_fpga),
    .ddr3_dq(ddr3_dq_fpga), .ddr3_dqs_n(ddr3_dqs_n_fpga), .ddr3_dqs_p(ddr3_dqs_p_fpga),
    .ddr3_dm(ddr3_dm_fpga), .ddr3_odt(ddr3_odt_fpga),
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

  genvar i;
  generate
    for (i = 0; i < NUM_COMP; i = i + 1) begin : gen_mem
      ddr3_model u_comp_ddr3 (
        .rst_n   (ddr3_reset_n),
        .ck      (ddr3_ck_p_sdram),
        .ck_n    (ddr3_ck_n_sdram),
        .cke     (ddr3_cke_sdram[0]),
        .cs_n    (ddr3_cs_n_sdram[0]),
        .ras_n   (ddr3_ras_n_sdram),
        .cas_n   (ddr3_cas_n_sdram),
        .we_n    (ddr3_we_n_sdram),
        .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
        .ba      (ddr3_ba_sdram[0]),
        .addr    (ddr3_addr_sdram[0]),
        .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
        .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
        .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
        .tdqs_n  (),
        .odt     (ddr3_odt_sdram[0])
      );
    end
  endgenerate

  // ---------------- DUT ----------------
  logic        start, flush, sink_ready;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic        rst_n_ui;

  logic        feed_done, wave_done, running;
  logic [31:0] buf_empty_st, buf_full_st, swap_cnt, pp_cyc, pp_cons, pp_res;
  logic [15:0] occ_a, occ_f;
  logic [31:0] axi_bytes, axi_bursts, axi_beats, exp_rec, rcv_rec, beat_mm;
  logic [31:0] rresp_err, rlast_err, rid_ord_err, r_bp;
  logic [31:0] w_accepted, w_dispatched, w_resident, w_max_res;
  logic [31:0] w_waves, w_partial, w_emit_cyc, w_fill_cyc, w_mem_wait, w_sink_wait, w_active_cyc;
  logic [31:0] w_bank_full_st, w_struct_mm, w_bank_err, w_index;
  logic        w_fire;
  logic [N_LANES-1:0] w_mask;
  logic [31:0] w_id  [N_LANES];
  logic [31:0] w_cue [N_LANES];
  logic [31:0] lane_scored, lane_busy_cyc, topk_batches, global_merge_cnt, top1_id;
  logic        global_tk_valid;
  logic [31:0] global_tk_id [8];
  logic signed [15:0] global_tk_score [8];
  logic signed [15:0] top1_score;

  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;
  assign flush    = feed_done;   // feed complete → let any tail wave leave (no stranding)

  a7ng_ddr_wavefront_top #(
    .BANK_DEPTH(32), .N_LANES(N_LANES), .ENTRIES_PER_BANK(ENT_PB),
    .MAX_OUT(8), .MAX_BURST(16)
  ) dut (
    .clk(ui_clk), .rst_n(rst_n_ui),
    .start_i(start), .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .sink_ready_i(sink_ready), .flush_i(flush),
    .query_cue_i(64'hA5A5_0F0F_1234_5678),
    .relation_cue_i(64'h0F1E_2D3C_4B5A_6978),
    .intent_cue_i(64'h1111_2222_3333_4444),
    .context_cue_i(64'hDEAD_BEEF_CAFE_0001),
    .path_cue_i(64'h00FF_00FF_00FF_00FF),
    .learned_prior_i(8'sd3),
    .feed_done_o(feed_done), .wave_done_o(wave_done), .running_o(running),
    .buffer_empty_stall_o(buf_empty_st), .buffer_full_stall_o(buf_full_st),
    .swap_count_o(swap_cnt), .pp_cycles_o(pp_cyc), .pp_consumed_o(pp_cons),
    .occ_active_o(occ_a), .occ_fill_o(occ_f), .pp_resident_o(pp_res),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts),
    .axi_read_beats_o(axi_beats),
    .expected_records_o(exp_rec), .received_records_o(rcv_rec),
    .beat_mismatch_o(beat_mm),
    .rresp_error_count_o(rresp_err), .rlast_error_count_o(rlast_err),
    .rid_order_error_o(rid_ord_err), .r_backpressure_cycles_o(r_bp),
    .wave_accepted_o(w_accepted), .wave_dispatched_o(w_dispatched),
    .wave_resident_o(w_resident), .wave_max_resident_o(w_max_res),
    .waves_o(w_waves), .partial_waves_o(w_partial),
    .emit_cycles_o(w_emit_cyc), .fill_cycles_o(w_fill_cyc),
    .mem_wait_cycles_o(w_mem_wait), .sink_wait_cycles_o(w_sink_wait),
    .active_cycles_o(w_active_cyc),
    .bank_full_stall_o(w_bank_full_st),
    .wave_struct_mismatch_o(w_struct_mm), .wave_bank_map_err_o(w_bank_err),
    .wave_fire_o(w_fire), .wave_mask_o(w_mask),
    .wave_id_o(w_id), .wave_cue_o(w_cue), .wave_index_o(w_index),
    .lane_scored_o(lane_scored), .lane_busy_cycles_o(lane_busy_cyc),
    .topk_batches_o(topk_batches), .global_merge_count_o(global_merge_cnt),
    .global_topk_valid_o(global_tk_valid),
    .global_topk_id_o(global_tk_id), .global_topk_score_o(global_tk_score),
    .top1_id_o(top1_id), .top1_score_o(top1_score),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f)
  );

  // ---------------- downstream throttle (traffic pattern axis) ----------------
  int thr_period;         // 0 = always ready
  int thr_cnt;
  assign sink_ready = (thr_period == 0) ? 1'b1 : (thr_cnt == 0);
  always @(posedge ui_clk) begin
    if (thr_period == 0) thr_cnt <= 0;
    else                 thr_cnt <= (thr_cnt + 1) % thr_period;
  end

  // ---------------- golden NodeRecordV1 (same pack as MIG-METRIC-00) ----------------
  function automatic logic [127:0] pack_node(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[47:32]   = 16'd1;
    b[63:48]   = 16'(nid[7:0]);
    b[95:64]   = 32'hDDFE_0000 + nid;
    b[111:96]  = 16'h0100;
    b[119:112] = 8'(nid[7:0]);
    b[127:120] = A7NG_MEM_SCHEMA_VERSION[7:0];
    return b;
  endfunction

  function automatic logic [31:0] golden_cue(input logic [31:0] nid);
    return 32'hDDFE_0000 + nid;
  endfunction

  // ---------------- TB scoreboard on all 16 lanes at consumption ----------------
  int tb_wave_mismatch;
  int tb_waves;
  int tb_cands;
  int tb_full_waves;
  int tb_min_wave_width;
  int tb_dbg;

  always @(posedge ui_clk) begin
    if (rst_n_ui && w_fire) begin
      int width;
      width = 0;
      for (int b = 0; b < N_LANES; b++) begin
        if (w_mask[b]) begin
          logic [31:0] exp_id;
          width  = width + 1;
          exp_id = base_node + 32'(w_index) * 32'(N_LANES) + 32'(b);
          if (w_id[b] !== exp_id || w_cue[b] !== golden_cue(exp_id)) begin
            tb_wave_mismatch = tb_wave_mismatch + 1;
            if (tb_dbg < 6) begin
              $display("WF_MISMATCH_DBG wave=%0d lane=%0d got_id=%0d exp_id=%0d got_cue=%08x exp_cue=%08x",
                       w_index, b, w_id[b], exp_id, w_cue[b], golden_cue(exp_id));
              tb_dbg = tb_dbg + 1;
            end
          end
        end
      end
      tb_waves = tb_waves + 1;
      tb_cands = tb_cands + width;
      if (width == N_LANES) tb_full_waves = tb_full_waves + 1;
      if (width < tb_min_wave_width) tb_min_wave_width = width;
    end
  end

  // ---------------- AXI preload ----------------
  task automatic axi_write_beat(input logic [27:0] addr, input logic [127:0] data);
    begin
      @(posedge ui_clk);
      awid    <= 4'd0;
      awaddr  <= addr;
      awlen   <= 8'd0;
      awsize  <= 3'd4;
      awburst <= 2'b01;
      awvalid <= 1'b1;
      wdata   <= data;
      wstrb   <= 16'hFFFF;
      wlast   <= 1'b1;
      wvalid  <= 1'b1;
      bready  <= 1'b1;
      fork
        begin wait (awvalid && awready); @(posedge ui_clk); awvalid <= 1'b0; end
        begin wait (wvalid && wready); @(posedge ui_clk); wvalid <= 1'b0; wlast <= 1'b0; end
      join
      wait (bvalid && bready);
      @(posedge ui_clk);
      bready <= 1'b0;
    end
  endtask

  task automatic preload_nodes(input int n);
    int k;
    begin
      for (k = 0; k < n; k++)
        axi_write_beat(a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k)), pack_node(32'(k)));
      $display("WF_PRELOAD_DONE nodes=%0d NodeRecordV1_deterministic_node_id", n);
    end
  endtask

  // ---------------- measured ui_clk period (for an honest, derived rate) ----------------
  real ui_clk_ps;
  task automatic measure_ui_clk();
    real t0, t1;
    begin
      @(posedge ui_clk); t0 = $realtime;
      repeat (100) @(posedge ui_clk);
      t1 = $realtime;
      ui_clk_ps = (t1 - t0) / 100.0;
      $display("WF_UICLK measured_period_ps=%0.2f over_100_edges (derived, XSim clock only)", ui_clk_ps);
    end
  endtask

  int any_fail;
  int cell_fail;

  task automatic run_pattern(input int pid, input int b, input int o, input int thr);
    int timeout;
    int exp_bytes, exp_bursts;
    int in_flight;
    real fill_per_wave, mem_wait_frac, jobs_per_cycle, jobs_per_emit;
    real bytes_per_cand, lane_util, bytes_per_cycle, mbytes_per_s;
    int e1, e2, e3, e4, e5, cons_ok;
    begin
      cell_fail = 0;
      tb_wave_mismatch = 0;
      tb_waves = 0;
      tb_cands = 0;
      tb_full_waves = 0;
      tb_min_wave_width = 999;
      tb_dbg = 0;
      exp_bytes  = TOTAL * 16;
      exp_bursts = (TOTAL + b - 1) / b;

      thr_period = thr;
      @(posedge ui_clk);
      burst       = 5'(b);
      outstanding = 4'(o);
      base_node   = 32'd0;
      total_recs  = 32'(TOTAL);
      start       = 1'b1;
      @(posedge ui_clk);
      start = 1'b0;

      timeout = 0;
      while (!(feed_done && wave_done) && timeout < 2_000_000) begin
        @(posedge ui_clk);
        timeout = timeout + 1;
      end
      // TermGen + scorer are each one registered stage: let the last wave retire through the
      // 16 lanes before sampling, otherwise `scored` lags `dispatched` by exactly one wave.
      repeat (8) @(posedge ui_clk);

      if (!(feed_done && wave_done)) begin
        $display("PATTERN_FAIL p=%0d burst=%0d out=%0d thr=%0d TIMEOUT feed_done=%0b wave_done=%0b",
                 pid, b, o, thr, feed_done, wave_done);
        cell_fail = 1;
      end else begin
        in_flight = int'(exp_rec) - int'(rcv_rec);

        fill_per_wave   = (w_waves == 0)       ? 0.0 : real'(w_fill_cyc)    / real'(w_waves);
        mem_wait_frac   = (w_active_cyc == 0)  ? 0.0 : real'(w_mem_wait)    / real'(w_active_cyc);
        jobs_per_cycle  = (w_active_cyc == 0)  ? 0.0 : real'(w_dispatched)  / real'(w_active_cyc);
        jobs_per_emit   = (w_emit_cyc == 0)    ? 0.0 : real'(w_dispatched)  / real'(w_emit_cyc);
        bytes_per_cand  = (w_dispatched == 0)  ? 0.0 : real'(axi_bytes)     / real'(w_dispatched);
        lane_util       = (w_active_cyc == 0)  ? 0.0 : real'(lane_busy_cyc) / real'(w_active_cyc);
        bytes_per_cycle = (w_active_cyc == 0)  ? 0.0 : real'(axi_bytes)     / real'(w_active_cyc);
        mbytes_per_s    = (ui_clk_ps == 0.0)   ? 0.0 : bytes_per_cycle * (1.0e6 / ui_clk_ps);

        // ---- conservation ledger ----
        e1 = (in_flight == 0);
        e2 = (int'(rcv_rec)     == int'(pp_cons) + int'(pp_res));
        e3 = (int'(w_accepted)  == int'(w_dispatched) + int'(w_resident) + 0);
        e4 = (int'(w_dispatched) == int'(lane_scored));
        e5 = (int'(w_dispatched) == TOTAL) && (int'(rcv_rec) == TOTAL);
        cons_ok = e1 && e2 && e3 && e4 && e5;

        $display("=== WF_PATTERN p=%0d burst=%0d outstanding=%0d throttle=%0d (UNIT=1 query, TOTAL=%0d) ===",
                 pid, b, o, thr, TOTAL);
        $display("WF_DELTA axi_read_bytes=%0d axi_read_bursts=%0d axi_read_beats=%0d (expect %0d/%0d/%0d)",
                 axi_bytes, axi_bursts, axi_beats, exp_bytes, exp_bursts, TOTAL);
        $display("WF_METRIC ddr_bytes_per_query=%0d ddr_bytes_per_candidate=%0.4f beats_per_query=%0d",
                 axi_bytes, bytes_per_cand, axi_beats);
        $display("WF_WAVE waves=%0d full_waves=%0d partial_waves=%0d min_wave_width=%0d emit_cycles=%0d dispatched=%0d",
                 w_waves, tb_full_waves, w_partial, tb_min_wave_width, w_emit_cyc, w_dispatched);
        $display("WF_WIDTH jobs_per_emit_cycle=%0.4f (16 => a real 16-wide wave, not 1/cycle renamed) jobs_per_cycle_during_wave=%0.6f",
                 jobs_per_emit, jobs_per_cycle);
        $display("WF_TIME active_cycles=%0d fill_cycles_accum=%0d wavefront_fill_cycles=%0.4f mem_wait=%0d memory_wait_fraction=%0.6f sink_wait=%0d",
                 w_active_cyc, w_fill_cyc, fill_per_wave, w_mem_wait, mem_wait_frac, w_sink_wait);
        $display("WF_CONS exp_beats=%0d rcv_beats=%0d in_flight=%0d pp_consumed=%0d pp_resident=%0d accepted=%0d dispatched=%0d resident=%0d pruned=0 scored=%0d",
                 exp_rec, rcv_rec, in_flight, pp_cons, pp_res, w_accepted, w_dispatched, w_resident, lane_scored);
        $display("WF_CONS_EQ E1=%0d E2=%0d E3=%0d E4=%0d E5=%0d candidate_conservation=%0d",
                 e1, e2, e3, e4, e5, cons_ok);
        $display("WF_INTEG data_mismatch_total=%0d (axi_beat=%0d wave_struct=%0d bank_map=%0d tb_lane_golden=%0d) rresp=%0d rlast=%0d rid_assoc=%0d r_backpressure_cycles=%0d",
                 beat_mm + w_struct_mm + w_bank_err + tb_wave_mismatch,
                 beat_mm, w_struct_mm, w_bank_err, tb_wave_mismatch,
                 rresp_err, rlast_err, rid_ord_err, r_bp);
        $display("WF_PP swap_count=%0d buffer_empty_stall=%0d buffer_full_stall=%0d bank_full_stall=%0d max_resident=%0d bound=%0d",
                 swap_cnt, buf_empty_st, buf_full_st, w_bank_full_st, w_max_res, WS_BOUND);
        $display("WF_DIAG lane_busy_cycles=%0d lane_utilisation=%0.6f (NON-GATE) topk_batches=%0d top1_id=%0d top1_score=%0d cache_hit_ratio=0.000000 (no cue cache in this path)",
                 lane_busy_cyc, lane_util, topk_batches, top1_id, top1_score);
        $display("WF_RATE derivation: bytes=%0d / active_cycles=%0d = %0.6f B/cycle; x (1e6/%0.2f ps) = %0.2f MB/s (XSim ui_clk-derived, NOT silicon bandwidth)",
                 axi_bytes, w_active_cyc, bytes_per_cycle, ui_clk_ps, mbytes_per_s);

        // ---- gate checks ----
        if (axi_bytes != exp_bytes) begin
          $display("PATTERN_FAIL p=%0d DELTA_BYTES got=%0d expect=%0d", pid, axi_bytes, exp_bytes);
          cell_fail = 1;
        end
        if (axi_bursts != exp_bursts) begin
          $display("PATTERN_FAIL p=%0d DELTA_BURSTS got=%0d expect=%0d", pid, axi_bursts, exp_bursts);
          cell_fail = 1;
        end
        if (axi_beats != TOTAL) begin
          $display("PATTERN_FAIL p=%0d DELTA_BEATS got=%0d expect=%0d", pid, axi_beats, TOTAL);
          cell_fail = 1;
        end
        if (!cons_ok) begin
          $display("PATTERN_FAIL p=%0d CONSERVATION E1=%0d E2=%0d E3=%0d E4=%0d E5=%0d",
                   pid, e1, e2, e3, e4, e5);
          cell_fail = 1;
        end
        if (beat_mm != 0 || w_struct_mm != 0 || w_bank_err != 0 || tb_wave_mismatch != 0) begin
          $display("PATTERN_FAIL p=%0d DATA_MISMATCH axi=%0d struct=%0d bank=%0d tb=%0d",
                   pid, beat_mm, w_struct_mm, w_bank_err, tb_wave_mismatch);
          cell_fail = 1;
        end
        if (rresp_err != 0 || rlast_err != 0) begin
          $display("PATTERN_FAIL p=%0d AXI_INTEGRITY rresp=%0d rlast=%0d", pid, rresp_err, rlast_err);
          cell_fail = 1;
        end
        if (w_max_res > WS_BOUND) begin
          $display("PATTERN_FAIL p=%0d BOUND_VIOLATION max_resident=%0d bound=%0d",
                   pid, w_max_res, WS_BOUND);
          cell_fail = 1;
        end
        // F7: a full wave must be 16 wide, else the "16-wide wave" claim is a rename
        if (tb_full_waves == 0 || jobs_per_emit < 15.999) begin
          $display("PATTERN_FAIL p=%0d WIDTH_CLAIM full_waves=%0d jobs_per_emit=%0.4f",
                   pid, tb_full_waves, jobs_per_emit);
          cell_fail = 1;
        end
        if (tb_cands != TOTAL) begin
          $display("PATTERN_FAIL p=%0d TB_LANE_COUNT got=%0d expect=%0d", pid, tb_cands, TOTAL);
          cell_fail = 1;
        end
        if (cell_fail == 0)
          $display("PATTERN_PASS p=%0d burst=%0d out=%0d thr=%0d deltas_ok conservation_ok width_16_ok",
                   pid, b, o, thr);
      end
      any_fail = any_fail + cell_fail;
      thr_period = 0;
      repeat (16) @(posedge ui_clk);
    end
  endtask

  initial begin
    feed_en = 1'b0;
    start = 1'b0;
    burst = 5'd1;
    outstanding = 4'd1;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    thr_period = 0;
    thr_cnt = 0;
    any_fail = 0;
    tb_wave_mismatch = 0;
    tb_waves = 0; tb_cands = 0; tb_full_waves = 0; tb_min_wave_width = 999; tb_dbg = 0;
    ui_clk_ps = 0.0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: ddr_wavefront_00");
    $display("PREREG_UNKNOWN: can a BOUNDED candidate/cue working set feed 16 PHYSICAL lanes with exactly measured traffic?");
    $display("PREREG_H_CANDIDATE: bounded ping/pong compact-cue working set sustains 16-wide waves, conserved records, measured DDR traffic");
    $display("PREREG_H_RIVAL: cumulative/unconserved traffic, or <=1 candidate/cycle service renamed 16-wide");
    $display("PREREG_FALSIFIER: non-conservation | cumulative-as-per-run | invented GB/s | frozen law change | board claim | PE-util-as-pass | wave width < 16");
    $display("PREREG_CONTROL: MIG-METRIC-00 per-run deltas burst=1 -> 1024B/64; burst=4 -> 1024B/16");
    $display("PREREG_UNIT: one query (TOTAL=%0d candidates); 4 distinct traffic patterns", TOTAL);
    $display("PREREG_BOUND: %0d banks x %0d entries = %0d candidate entries (compact 8B cue entry)",
             N_LANES, ENT_PB, WS_BOUND);
    $display("PREREG_METRICS: ddr_bytes_per_candidate ddr_bytes_per_query beats_per_query wavefront_fill_cycles memory_wait_fraction jobs_per_cycle_during_wave candidate_conservation data_mismatch swap_count buffer_empty_stall buffer_full_stall");
    $display("NOTE: Evidence_class=MIG_XSIM_WAVEFRONT (Digilent AXI MIG + ddr3_model). Not BOARD. Not HS-02.");
    $display("NOTE: RVALID&&!RREADY = backpressure, NOT a drop. Conservation authority = record/data equality.");
    $display("NOTE: PE/lane utilisation is a DIAGNOSTIC here, not a gate.");
    $display("NOTE: frozen law untouched — 01R / HIT_MAX / TermGen / Top-K / relation / LM-06 / 02M / training / mig.prj");

    wait (init_calib_complete === 1'b1);
    $display("MIG_CALIB_COMPLETE at %0t", $time);
    repeat (50) @(posedge ui_clk);
    measure_ui_clk();

    preload_nodes(N_PRE);
    feed_en = 1'b1;
    repeat (20) @(posedge ui_clk);

    run_pattern(1, 1,  1, 0);   // CONTROL row 1
    run_pattern(2, 4,  8, 0);   // CONTROL row 2
    run_pattern(3, 4,  8, 8);   // backpressure: sink ready 1-in-8
    run_pattern(4, 16, 8, 0);   // distinct burst depth

    if (any_fail == 0)
      $display("A7NG_DDR_WAVEFRONT_XSIM_PASS");
    else
      $display("A7NG_DDR_WAVEFRONT_XSIM_FAIL fails=%0d", any_fail);
    $finish;
  end

  initial begin
    #300ms;
    $display("WF_TIMEOUT — calib or pattern hung");
    $display("A7NG_DDR_WAVEFRONT_XSIM_FAIL");
    $finish;
  end
endmodule
