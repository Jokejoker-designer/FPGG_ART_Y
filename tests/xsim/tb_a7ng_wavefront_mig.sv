// tb_a7ng_wavefront_mig.sv — ddr_wavefront_00 on Digilent AXI MIG + ddr3_model
//
// UNKNOWN (one): from correctly measured MIG, can a BOUNDED candidate/cue working set feed
//                16 physical lanes with EXACTLY measured traffic?
// H_CANDIDATE:   bounded ping/pong cue working set sustains 16-lane waves, candidates
//                conserved, zero data mismatch, all traffic accounted per-run.
// H_RIVAL:       bounded buffer starves the wave, or loses/duplicates candidates, or traffic
//                can only be reported cumulatively.
// FALSIFIER:     invented GB/s; cumulative counters sold as per-run; candidate loss hidden as
//                backpressure; law change; COM12 program.
// CONTROL:       MIG-METRIC-00 cells (1,1)=1024B/64 bursts and (4,8)=1024B/16 bursts, TOTAL=64.
// UNIT:          one query run (seed x candidate list x burst/outstanding x consumer pattern).
//                Six runs, three seeds, three consumer patterns — not one long single pattern.
// NON-GATE:      PE utilization is a diagnostic here, never a pass/fail criterion.
`timescale 1ps / 100fs

module tb_a7ng_wavefront_mig;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int WAVE  = 16;
  localparam int N_PRE = 160;  // nodes preloaded: covers base 0 / 64 / 128 runs
  localparam int NRUN  = 6;

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
  logic        start;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic        cons_ready;
  logic [63:0] q_query, q_intent, q_relation, q_context, q_path;

  logic        done, running;
  logic [31:0] cyc, waves;
  logic [31:0] c_acc, c_del, c_que, c_inf, c_prn, c_err, wf_mm;
  logic [31:0] swaps, empty_st, full_st, cr_cyc, fill_cyc, fill_eps;
  logic [15:0] occ_f, occ_d;
  logic [31:0] axi_bytes, axi_bursts, axi_beats, axi_mm;
  logic [31:0] rresp_err, rlast_err, exp_rec, rcv_rec, rid_err, r_bp;
  logic [31:0] batches, closs, tkb, busyc, fpush, fovf;
  logic [7:0]  fcount;
  logic        wave_valid_w;
  logic [127:0] wave_rec_w [WAVE];
  logic [31:0] wave_base_w;
  logic        topk_valid_w;
  score_t      topk_sc_w [8];
  node_id_t    topk_id_w [8];

  logic rst_n_ui;
  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;

  a7ng_wavefront_mig_top #(.WAVE(WAVE), .MAX_OUT(8), .MAX_BURST(16)) dut (
    .clk(ui_clk), .rst_n(rst_n_ui),
    .start_i(start), .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .cons_ready_i(cons_ready),
    .q_query_cue_i(q_query), .q_intent_cue_i(q_intent),
    .q_relation_cue_i(q_relation), .q_context_cue_i(q_context), .q_path_cue_i(q_path),
    .done_o(done), .running_o(running),
    .cycles_o(cyc), .waves_o(waves),
    .cand_accepted_o(c_acc), .cand_delivered_o(c_del), .cand_queued_o(c_que),
    .cand_inflight_o(c_inf), .cand_pruned_o(c_prn), .conserve_err_o(c_err),
    .data_mismatch_o(wf_mm), .swap_count_o(swaps),
    .buffer_empty_stall_o(empty_st), .buffer_full_stall_o(full_st),
    .cons_ready_cycles_o(cr_cyc),
    .fill_cycles_o(fill_cyc), .fill_episodes_o(fill_eps),
    .occ_fill_o(occ_f), .occ_drain_o(occ_d),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts), .axi_read_beats_o(axi_beats),
    .axi_data_mismatch_o(axi_mm),
    .rresp_error_count_o(rresp_err), .rlast_error_count_o(rlast_err),
    .expected_records_o(exp_rec), .received_records_o(rcv_rec),
    .rid_order_error_o(rid_err), .r_backpressure_cycles_o(r_bp),
    .batches_accepted_o(batches), .consumer_loss_o(closs),
    .topk_batches_o(tkb), .flow_busy_cycles_o(busyc),
    .frontier_push_o(fpush), .frontier_overflow_o(fovf), .frontier_count_o(fcount),
    .wave_valid_o(wave_valid_w), .wave_rec_o(wave_rec_w), .wave_base_id_o(wave_base_w),
    .topk_valid_o(topk_valid_w), .topk_score_o(topk_sc_w), .topk_id_o(topk_id_w),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f)
  );

  // ---------------- consumer pattern generator ----------------
  int pat_sel;
  int pcnt;
  always @(posedge ui_clk) begin
    if (!rst_n_ui) pcnt <= 0;
    else           pcnt <= pcnt + 1;
  end
  always_comb begin
    case (pat_sel)
      1:       cons_ready = ((pcnt % 4) == 0);        // SPARSE: ready 1 of 4
      2:       cons_ready = ((pcnt % 32) < 8);        // BURSTY: 8 ready / 24 idle
      default: cons_ready = 1'b1;                     // ALWAYS
    endcase
  end

  // ---------------- deterministic preload pattern (TB-side, independent of RTL) ----------
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

  function automatic logic [63:0] qcue(input int seed, input int which);
    return {32'h5A5A_0000 + 32'(seed*7 + which*13), 32'hC3C3_0000 + 32'(seed*31 + which*17)};
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

  task automatic preload_nodes(input int n);
    int k;
    begin
      for (k = 0; k < n; k++)
        axi_write_beat(a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k)), pack_node(32'(k)));
      $display("WF_PRELOAD_DONE nodes=%0d NodeRecordV1_deterministic", n);
    end
  endtask

  // ---------------- independent TB scoreboard on the wave bus ----------------
  int  seen [0:255];        // per-candidate delivery count for the active run
  int  tb_mm;               // TB-side record mismatches
  int  tb_seq;              // TB-side node_id sequence violations
  int  tb_delivered;
  int  run_base;
  int  sb_on;

  int  cap_n  [0:NRUN-1];
  int  cap_id [0:NRUN-1][0:7][0:7];
  int  cap_sc [0:NRUN-1][0:7][0:7];
  int  cap_run;
  int  cap_on;

  logic [31:0] want_id;

  // per-run summary rows (for the closeout metric table)
  int m_bytes [0:NRUN-1];
  int m_beats [0:NRUN-1];
  int m_burst [0:NRUN-1];
  int m_waves [0:NRUN-1];
  int m_fill  [0:NRUN-1];
  int m_feps  [0:NRUN-1];
  int m_empty [0:NRUN-1];
  int m_full  [0:NRUN-1];
  int m_crdy  [0:NRUN-1];
  int m_cyc   [0:NRUN-1];
  int m_swap  [0:NRUN-1];

  always @(posedge ui_clk) begin
    if (sb_on && wave_valid_w) begin
      for (int k = 0; k < WAVE; k++) begin
        want_id = wave_base_w + 32'(k);
        if (wave_rec_w[k][31:0] !== want_id) begin
          if (tb_seq < 4)
            $display("WF_SEQ_ERR wave_base=%0d lane=%0d got_id=%0d want_id=%0d",
                     wave_base_w, k, wave_rec_w[k][31:0], want_id);
          tb_seq = tb_seq + 1;
        end
        if (wave_rec_w[k] !== pack_node(want_id)) begin
          if (tb_mm < 4)
            $display("WF_REC_ERR lane=%0d id=%0d got=%032x want=%032x",
                     k, want_id, wave_rec_w[k], pack_node(want_id));
          tb_mm = tb_mm + 1;
        end
        if ((int'(want_id) - run_base) >= 0 && (int'(want_id) - run_base) < 256)
          seen[int'(want_id) - run_base] = seen[int'(want_id) - run_base] + 1;
      end
      tb_delivered = tb_delivered + WAVE;
    end
    if (cap_on && topk_valid_w && (cap_n[cap_run] < 8)) begin
      for (int k = 0; k < 8; k++) begin
        cap_id[cap_run][cap_n[cap_run]][k] = int'(topk_id_w[k]);
        cap_sc[cap_run][cap_n[cap_run]][k] = int'(topk_sc_w[k]);
      end
      cap_n[cap_run] = cap_n[cap_run] + 1;
    end
  end

  int any_fail;
  int run_fail;

  task automatic run_query(input int idx, input int seed, input int base, input int total,
                           input int b, input int o, input int pat);
    int timeout;
    int exp_bytes, exp_bursts, exp_waves;
    real bpc, mem_wait_f, mem_wait_t, jobs_pc, fill_avg, pe_util;
    begin
      run_fail = 0;
      exp_bytes  = total * 16;
      exp_bursts = (total + b - 1) / b;
      exp_waves  = total / WAVE;

      for (int k = 0; k < 256; k++) seen[k] = 0;
      tb_mm = 0; tb_seq = 0; tb_delivered = 0; run_base = base;
      cap_run = idx; cap_n[idx] = 0;

      @(posedge ui_clk);
      pat_sel     = pat;
      burst       = 5'(b);
      outstanding = 4'(o);
      base_node   = 32'(base);
      total_recs  = 32'(total);
      q_query     = qcue(seed, 0);
      q_intent    = qcue(seed, 1);
      q_relation  = qcue(seed, 2);
      q_context   = qcue(seed, 3);
      q_path      = qcue(seed, 4);
      @(posedge ui_clk);
      sb_on  = 1;
      cap_on = 1;
      start  = 1'b1;
      @(posedge ui_clk);
      start  = 1'b0;
      @(posedge ui_clk);   // running asserts before done is sampled (avoid stale done=1)

      timeout = 0;
      while (!done && timeout < 400_000) begin
        @(posedge ui_clk);
        timeout = timeout + 1;
      end
      // let the last batch finish score -> Top-8 -> frontier push
      repeat (40) @(posedge ui_clk);
      sb_on  = 0;
      cap_on = 0;

      if (!done) begin
        $display("RUN_FAIL Q%0d TIMEOUT delivered=%0d/%0d", idx, c_del, total);
        run_fail = 1;
      end else begin
        bpc        = (c_del == 0) ? 0.0 : real'(axi_bytes) / real'(c_del);
        mem_wait_f = (cr_cyc == 0) ? 0.0 : real'(empty_st) / real'(cr_cyc);
        mem_wait_t = (cyc == 0) ? 0.0 : real'(empty_st) / real'(cyc);
        jobs_pc    = (cyc == 0) ? 0.0 : real'(c_del) / real'(cyc);
        fill_avg   = (fill_eps == 0) ? 0.0 : real'(fill_cyc) / real'(fill_eps);
        // diagnostic only: 16 scorer lanes are occupied 2 cycles per accepted batch
        pe_util    = (cyc == 0) ? 0.0 : (real'(batches) * 2.0) / real'(cyc);

        $display("WF_RUN Q%0d seed=%0d base=%0d total=%0d burst=%0d out=%0d pattern=%0d",
                 idx, seed, base, total, b, o, pat);
        $display("WF_TRAFFIC Q%0d ddr_bytes_per_query=%0d beats_per_query=%0d bursts=%0d ddr_bytes_per_candidate=%0.4f (expect bytes=%0d beats=%0d bursts=%0d)",
                 idx, axi_bytes, axi_beats, axi_bursts, bpc, exp_bytes, total, exp_bursts);
        $display("WF_WAVE Q%0d waves=%0d wavefront_fill_cycles=%0d fill_episodes=%0d fill_cycles_per_wave=%0.4f swap_count=%0d",
                 idx, waves, fill_cyc, fill_eps, fill_avg, swaps);
        $display("WF_STALL Q%0d memory_wait_fraction=%0.6f memory_wait_fraction_total=%0.6f buffer_empty_stall=%0d buffer_full_stall=%0d cons_ready_cycles=%0d cycles=%0d r_backpressure_cycles=%0d",
                 idx, mem_wait_f, mem_wait_t, empty_st, full_st, cr_cyc, cyc, r_bp);
        $display("WF_CONSERVE Q%0d accepted=%0d completed=%0d queued=%0d pruned=%0d in_flight=%0d conserve_err=%0d tb_delivered=%0d tb_seq_err=%0d",
                 idx, c_acc, c_del, c_que, c_prn, c_inf, c_err, tb_delivered, tb_seq);
        $display("WF_INTEGRITY Q%0d data_mismatch=%0d axi_data_mismatch=%0d tb_record_mismatch=%0d rresp=%0d rlast=%0d expected_records=%0d received_records=%0d rid_order_error=%0d",
                 idx, wf_mm, axi_mm, tb_mm, rresp_err, rlast_err, exp_rec, rcv_rec, rid_err);
        $display("WF_CONSUMER Q%0d jobs_per_cycle_during_wave=%0.6f batches_accepted=%0d consumer_loss=%0d topk_batches=%0d frontier_push=%0d frontier_overflow=%0d flow_busy=%0d",
                 idx, jobs_pc, batches, closs, tkb, fpush, fovf, busyc);
        $display("WF_DIAG Q%0d pe_utilization_diagnostic=%0.4f (NOT A GATE) cache_hit_ratio=0.000 (no reuse cache in path)",
                 idx, pe_util);

        m_bytes[idx] = axi_bytes; m_beats[idx] = axi_beats; m_burst[idx] = axi_bursts;
        m_waves[idx] = waves;     m_fill[idx]  = fill_cyc;  m_feps[idx]  = fill_eps;
        m_empty[idx] = empty_st;  m_full[idx]  = full_st;   m_crdy[idx]  = cr_cyc;
        m_cyc[idx]   = cyc;       m_swap[idx]  = swaps;

        if (axi_bytes != exp_bytes) begin
          $display("RUN_FAIL Q%0d BYTES got=%0d expect=%0d (per-run delta, not cumulative)",
                   idx, axi_bytes, exp_bytes);
          run_fail = 1;
        end
        if (axi_beats != total) begin
          $display("RUN_FAIL Q%0d BEATS got=%0d expect=%0d", idx, axi_beats, total);
          run_fail = 1;
        end
        if (axi_bursts != exp_bursts) begin
          $display("RUN_FAIL Q%0d BURSTS got=%0d expect=%0d", idx, axi_bursts, exp_bursts);
          run_fail = 1;
        end
        if (bpc != 16.0) begin
          $display("RUN_FAIL Q%0d BYTES_PER_CANDIDATE got=%0.4f expect=16.0000", idx, bpc);
          run_fail = 1;
        end
        if (c_acc != total || c_del != total || c_que != 0 || c_inf != 0 || c_prn != 0) begin
          $display("RUN_FAIL Q%0d CONSERVATION acc=%0d del=%0d que=%0d inf=%0d prn=%0d total=%0d",
                   idx, c_acc, c_del, c_que, c_inf, c_prn, total);
          run_fail = 1;
        end
        if (c_err != 0) begin
          $display("RUN_FAIL Q%0d CONSERVE_IDENTITY_ERR=%0d", idx, c_err);
          run_fail = 1;
        end
        if (wf_mm != 0 || axi_mm != 0 || tb_mm != 0) begin
          $display("RUN_FAIL Q%0d DATA_MISMATCH wf=%0d axi=%0d tb=%0d", idx, wf_mm, axi_mm, tb_mm);
          run_fail = 1;
        end
        if (tb_seq != 0) begin
          $display("RUN_FAIL Q%0d SEQUENCE_ERR=%0d", idx, tb_seq);
          run_fail = 1;
        end
        if (rresp_err != 0 || rlast_err != 0) begin
          $display("RUN_FAIL Q%0d AXI_PROTO rresp=%0d rlast=%0d", idx, rresp_err, rlast_err);
          run_fail = 1;
        end
        if (exp_rec != total || rcv_rec != total) begin
          $display("RUN_FAIL Q%0d RECORDS exp=%0d rcv=%0d expect=%0d", idx, exp_rec, rcv_rec, total);
          run_fail = 1;
        end
        if (waves != exp_waves) begin
          $display("RUN_FAIL Q%0d WAVES got=%0d expect=%0d", idx, waves, exp_waves);
          run_fail = 1;
        end
        if (closs != 0) begin
          $display("RUN_FAIL Q%0d CONSUMER_LOSS=%0d (wave reached a consumer that could not take it)",
                   idx, closs);
          run_fail = 1;
        end
        if (batches != exp_waves) begin
          $display("RUN_FAIL Q%0d BATCHES_ACCEPTED got=%0d expect=%0d", idx, batches, exp_waves);
          run_fail = 1;
        end
        if (tkb != exp_waves) begin
          $display("RUN_FAIL Q%0d TOPK_BATCHES got=%0d expect=%0d", idx, tkb, exp_waves);
          run_fail = 1;
        end
        if (tb_delivered != total) begin
          $display("RUN_FAIL Q%0d TB_DELIVERED got=%0d expect=%0d", idx, tb_delivered, total);
          run_fail = 1;
        end
        // exactly-once: catches loss AND duplication independently of RTL counters
        for (int k = 0; k < total; k++) begin
          if (seen[k] != 1) begin
            $display("RUN_FAIL Q%0d EXACTLY_ONCE node_off=%0d seen=%0d", idx, k, seen[k]);
            run_fail = 1;
          end
        end
        if (cap_n[idx] != exp_waves) begin
          $display("RUN_FAIL Q%0d TOPK_CAPTURE got=%0d expect=%0d", idx, cap_n[idx], exp_waves);
          run_fail = 1;
        end
        if (run_fail == 0)
          $display("RUN_PASS Q%0d bounded_wave_ok traffic_exact conservation_ok integrity_ok", idx);
      end
      any_fail = any_fail + run_fail;
      pat_sel = 0;
      repeat (16) @(posedge ui_clk);
    end
  endtask

  task automatic compare_runs(input int a, input int b);
    int diff;
    begin
      diff = 0;
      if (cap_n[a] != cap_n[b]) diff = 1;
      else begin
        for (int w = 0; w < cap_n[a]; w++)
          for (int k = 0; k < 8; k++)
            if (cap_id[a][w][k] != cap_id[b][w][k] || cap_sc[a][w][k] != cap_sc[b][w][k])
              diff = diff + 1;
      end
      if (diff == 0)
        $display("WF_INVARIANCE_PASS Q%0d==Q%0d top8_sequence_identical waves=%0d", a, b, cap_n[a]);
      else begin
        $display("WF_INVARIANCE_FAIL Q%0d!=Q%0d diffs=%0d", a, b, diff);
        any_fail = any_fail + 1;
      end
    end
  endtask

  initial begin
    feed_en = 1'b0;
    start = 1'b0;
    burst = 5'd1;
    outstanding = 4'd1;
    base_node = 32'd0;
    total_recs = 32'd64;
    pat_sel = 0;
    sb_on = 0;
    cap_on = 0;
    any_fail = 0;
    tb_mm = 0; tb_seq = 0; tb_delivered = 0; run_base = 0; cap_run = 0;
    q_query = '0; q_intent = '0; q_relation = '0; q_context = '0; q_path = '0;
    for (int k = 0; k < NRUN; k++) cap_n[k] = 0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: ddr_wavefront_00");
    $display("PREREG_UNKNOWN: from correctly measured MIG, can a BOUNDED candidate/cue working set feed 16 physical lanes with EXACTLY measured traffic?");
    $display("PREREG_H_CANDIDATE: bounded ping/pong cue working set sustains 16-lane waves; candidates conserved; zero data mismatch; traffic accounted per-run");
    $display("PREREG_H_RIVAL: buffer starves the wave, or loses/duplicates candidates, or traffic is only cumulative");
    $display("PREREG_FALSIFIER: invented GB/s; cumulative counters as per-run; loss hidden as backpressure; law change; COM12 program");
    $display("PREREG_CONTROL: MIG-METRIC-00 cells (1,1)=1024B/64bursts (4,8)=1024B/16bursts TOTAL=64");
    $display("PREREG_UNIT: one query run (seed x candidates x burst/out x consumer pattern); 6 runs / 3 seeds / 3 patterns");
    $display("PREREG_METRICS: ddr_bytes_per_candidate, ddr_bytes_per_query, beats_per_query, wavefront_fill_cycles, memory_wait_fraction, jobs_per_cycle_during_wave, candidate_conservation, data_mismatch, swap_count, buffer_empty_stall, buffer_full_stall");
    $display("PREREG_NON_GATE: PE utilization >= 80%% is NOT a gate here (scheduler-local); reported as diagnostic only");
    $display("PREREG_LIMIT: frozen a7ng_ng02_core needs all 16 lane valids, so candidate counts are quantized to WAVE=16");
    $display("NOTE: Digilent AXI MIG + ddr3_model — Evidence_class=MIG_XSIM; not BOARD; not HS-02");
    $display("NOTE: runs execute back-to-back WITHOUT rst_n; only start_i clears per-run telemetry");

    wait (init_calib_complete === 1'b1);
    $display("WF_CALIB_COMPLETE at %0t", $time);
    repeat (50) @(posedge ui_clk);

    preload_nodes(N_PRE);
    feed_en = 1'b1;
    repeat (20) @(posedge ui_clk);

    //          idx seed base total burst out pattern
    run_query(  0,   0,   0,   64,    1,   1,  0);  // CONTROL cell (1,1)
    run_query(  1,   0,   0,   64,    4,   8,  0);  // CONTROL cell (4,8)
    run_query(  2,   0,   0,   64,   16,   8,  0);  // long burst vs 16-record bank
    run_query(  3,   1,  64,   64,    4,   8,  0);  // second seed
    run_query(  4,   1,  64,   64,   16,   8,  1);  // SPARSE consumer
    run_query(  5,   2, 128,   32,    8,   4,  2);  // third seed + BURSTY consumer

    // Candidate conservation across traffic shapes: identical Top-8 stream or candidates moved.
    compare_runs(0, 1);
    compare_runs(0, 2);
    compare_runs(3, 4);

    // Bounded-buffer backpressure observation: preregistered as expected in a slow-consumer
    // run. Reported either way; absence is a stated observation, not a silent omission.
    if ((m_full[4] + m_full[5]) > 0)
      $display("WF_BACKPRESSURE_OBSERVED slow_consumer_buffer_full_stall Q4=%0d Q5=%0d (beats held, none dropped)",
               m_full[4], m_full[5]);
    else
      $display("WF_BACKPRESSURE_NOT_OBSERVED Q4=0 Q5=0 — bounded buffer never had to hold a beat back");

    $display("WF_SUMMARY_HDR run bytes beats bursts waves fill_cycles fill_eps empty_stall full_stall cons_ready cycles swaps");
    for (int r = 0; r < NRUN; r++)
      $display("WF_SUMMARY %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
               r, m_bytes[r], m_beats[r], m_burst[r], m_waves[r], m_fill[r], m_feps[r],
               m_empty[r], m_full[r], m_crdy[r], m_cyc[r], m_swap[r]);

    if (any_fail == 0) begin
      $display("A7NG_DDR_WAVEFRONT00_XSIM_PASS");
    end else begin
      $display("A7NG_DDR_WAVEFRONT00_XSIM_FAIL fails=%0d", any_fail);
    end
    $finish;
  end

  initial begin
    #400ms;
    $display("WF_TIMEOUT — calib or run hung");
    $display("A7NG_DDR_WAVEFRONT00_XSIM_FAIL");
    $finish;
  end
endmodule
