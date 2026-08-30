// tb_a7ng_wf_global_topk_integrated.sv — wf_global_topk_integrated_00
// UNKNOWN: Does integrated a7ng_ddr_wavefront_top + global accumulator compile and pass
//          cross-wave counterexample (closes carried_risk_r1)?
// H_CANDIDATE: G_(t+1)=TopK(G_t ∪ TopK(W_t)) through full ddr_wavefront_top path.
// H_RIVAL: per-wave-only suffices on non-sequential node_id stream.
// FALSIFIER: rank-9 0xDEADBEEF score 135 beats W1 8th (130) but per-wave-only differs.
// UNIT: one query = 32 candidates = 2 waves (not one clock cycle).
// Evidence_class: MIG_XSIM_WAVEFRONT_INTEGRATED — not BOARD.
`timescale 1ps / 100fs

module tb_a7ng_wf_global_topk_integrated;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;
  `include "tb_a7ng_wf_global_topk_integrated_golden.svh"

  localparam int N_LANES = 16;
  localparam int ENT_PB  = 16;
  localparam int TOTAL   = WFGI_N;  // 32 = 2 full waves

  localparam COL_WIDTH   = 10;
  localparam DM_WIDTH    = 2;
  localparam DQ_WIDTH    = 16;
  localparam DQS_WIDTH   = 2;
  localparam ROW_WIDTH   = 14;
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

  logic        start, flush, sink_ready;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic        rst_n_ui;

  logic        feed_done, wave_done, running;
  logic [31:0] axi_bytes, axi_beats, exp_rec, rcv_rec, beat_mm;
  logic [31:0] w_dispatched, w_waves, lane_scored;
  logic [31:0] global_merge_cnt, top1_id;
  logic        global_tk_valid;
  logic [31:0] global_tk_id [8];
  logic signed [15:0] global_tk_score [8];
  logic signed [15:0] top1_score;

  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;
  assign flush    = feed_done;
  assign sink_ready = 1'b1;

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
    .buffer_empty_stall_o(), .buffer_full_stall_o(),
    .swap_count_o(), .pp_cycles_o(), .pp_consumed_o(),
    .occ_active_o(), .occ_fill_o(), .pp_resident_o(),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(),
    .axi_read_beats_o(axi_beats),
    .expected_records_o(exp_rec), .received_records_o(rcv_rec),
    .beat_mismatch_o(beat_mm),
    .rresp_error_count_o(), .rlast_error_count_o(),
    .rid_order_error_o(), .r_backpressure_cycles_o(),
    .wave_accepted_o(), .wave_dispatched_o(w_dispatched),
    .wave_resident_o(), .wave_max_resident_o(),
    .waves_o(w_waves), .partial_waves_o(),
    .emit_cycles_o(), .fill_cycles_o(),
    .mem_wait_cycles_o(), .sink_wait_cycles_o(),
    .active_cycles_o(),
    .bank_full_stall_o(), .wave_struct_mismatch_o(),
    .wave_bank_map_err_o(),
    .wave_fire_o(), .wave_mask_o(), .wave_id_o(), .wave_cue_o(),
    .wave_index_o(),
    .lane_scored_o(lane_scored), .lane_busy_cycles_o(),
    .topk_batches_o(), .global_merge_count_o(global_merge_cnt),
    .global_topk_valid_o(global_tk_valid),
    .global_topk_id_o(global_tk_id), .global_topk_score_o(global_tk_score),
    .top1_id_o(top1_id), .top1_score_o(top1_score),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f)
  );

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

  task automatic preload_counterexample();
    int k;
    begin
      for (k = 0; k < WFGI_N; k = k + 1)
        axi_write_beat(
          a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k)),
          pack_node(32'(k))
        );
      $display("WFGI_PRELOAD_DONE nodes=%0d two_wave_counterexample", WFGI_N);
    end
  endtask

  int fails;

  task automatic check_global_topk();
    int c, diff;
    begin
      for (c = 0; c < 8; c = c + 1) begin
        if (global_tk_id[c] !== WFGI_EXP_GID[c] ||
            global_tk_score[c] !== WFGI_EXP_GSCORE[c]) begin
          $display("FAIL integrated_global slot%0d got id=%0h score=%0d exp id=%0h score=%0d",
                   c, global_tk_id[c], global_tk_score[c],
                   WFGI_EXP_GID[c], WFGI_EXP_GSCORE[c]);
          fails = fails + 1;
        end
      end
      if (fails == 0) begin
        logic w1_8th_present;
        w1_8th_present = 1'b0;
        for (c = 0; c < 8; c = c + 1)
          if (global_tk_id[c] === WFGI_W1_8TH_ID &&
              global_tk_score[c] === WFGI_W1_8TH_SCORE)
            w1_8th_present = 1'b1;
        if (w1_8th_present) begin
          $display("FAIL integrated w1_8th id=%0d still in G_final", WFGI_W1_8TH_ID);
          fails = fails + 1;
        end else
          $display("PASS integrated_global w1_8th id=%0d@%0d displaced by cross-wave merge",
                   WFGI_W1_8TH_ID, WFGI_W1_8TH_SCORE);
      end

      diff = 0;
      for (c = 0; c < 8; c = c + 1)
        if (global_tk_id[c] !== WFGI_EXP_PWID[c] ||
            global_tk_score[c] !== WFGI_EXP_PWSCORE[c])
          diff = diff + 1;
      if (diff == 0) begin
        $display("FAIL integrated_perwave_only matches global (reducer not needed)");
        fails = fails + 1;
      end else begin
        $display("PASS integrated_perwave_only differs from global (%0d slots)", diff);
      end
    end
  endtask

  initial begin
    fails = 0;
    feed_en = 1'b0;
    start = 1'b0;
    burst = 5'd1;
    outstanding = 4'd1;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: wf_global_topk_integrated_00");
    $display("PREREG_UNKNOWN: integrated ddr_wavefront_top + global accumulator cross-wave");
    $display("PREREG_UNIT: one query TOTAL=%0d candidates (2 waves)", TOTAL);
    $display("NOTE: Evidence_class=MIG_XSIM_WAVEFRONT_INTEGRATED. Not BOARD.");

    wait (init_calib_complete === 1'b1);
    $display("WFGI_MIG_CALIB_COMPLETE at %0t", $time);
    repeat (50) @(posedge ui_clk);

    preload_counterexample();
    feed_en = 1'b1;
    repeat (20) @(posedge ui_clk);

    start = 1'b1;
    @(posedge ui_clk);
    start = 1'b0;

    begin : run_query
      int timeout;
      timeout = 0;
      while (!(feed_done && wave_done) && timeout < 1_000_000) begin
        @(posedge ui_clk);
        timeout = timeout + 1;
      end
      // running_o includes min-heap busy. Bitonic settle was 16. Wait for G_(t).
      begin
        int heap_wait;
        heap_wait = 0;
        while ((global_merge_cnt < 32'd2 || running) && heap_wait < 4096) begin
          @(posedge ui_clk);
          heap_wait = heap_wait + 1;
        end
        repeat (4) @(posedge ui_clk);
      end

      if (!(feed_done && wave_done)) begin
        $display("FAIL integrated TIMEOUT feed=%0b wave=%0b", feed_done, wave_done);
        fails = fails + 1;
      end else begin
        if (int'(rcv_rec) != TOTAL || int'(w_dispatched) != TOTAL) begin
          $display("FAIL integrated conservation rcv=%0d disp=%0d expect=%0d",
                   rcv_rec, w_dispatched, TOTAL);
          fails = fails + 1;
        end
        if (w_waves < 2) begin
          $display("FAIL integrated waves=%0d expect>=2", w_waves);
          fails = fails + 1;
        end
        if (beat_mm != 0) begin
          $display("FAIL integrated beat_mm=%0d", beat_mm);
          fails = fails + 1;
        end
        if (global_merge_cnt != 32'd2) begin
          $display("FAIL integrated merge_count got %0d exp 2", global_merge_cnt);
          fails = fails + 1;
        end
        check_global_topk();
        $display("WFGI_DIAG top1_id=%0h top1_score=%0d scored=%0d waves=%0d merges=%0d",
                 top1_id, top1_score, lane_scored, w_waves, global_merge_cnt);
      end
    end

    if (fails == 0)
      $display("A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS fails=0 merge_count=%0d", global_merge_cnt);
    else
      $display("A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_FAIL fails=%0d", fails);
    $finish;
  end

  initial begin
    #200ms;
    $display("WFGI_TIMEOUT");
    $display("A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_FAIL");
    $finish;
  end
endmodule
