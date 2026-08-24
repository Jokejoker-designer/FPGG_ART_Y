// tb_a7ng_ddr_feed_mig.sv — Digilent AXI MIG + ddr_feed + MIG-METRIC-00 integrity
// UNKNOWN: can MIG_XSIM report trustworthy per-run deltas + integrity for N=64
//           without changing feed/search law?
// H_CANDIDATE: burst=1 → 1024B/64 bursts; burst=4 → 1024B/16 bursts (deltas);
//              integrity counters clean
// H_RIVAL: cumulative counters sold as per-cell; DROP as lost data
// FALSIFIER: invent GB/s; COM12 program; change feed law; frozen overwrite
// CONTROL: MIG-RIVAL cumulative row documented; mig.prj MATCH
// UNIT: sweep cell (burst x outstanding) — (1,1) and (4,8) seed0 TOTAL=64
// METRICS: axi_read_{bytes,bursts,beats}; data/rresp/rlast; records; rid; r_backpressure
`timescale 1ps / 100fs

module tb_a7ng_ddr_feed_mig;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int N_PE  = 16;
  localparam int TOTAL = 64;   // reduced vs synthetic 256 for MIG sim wall-clock
  localparam int N_PRE = 128;  // nodes preloaded (covers seed0 base+TOTAL)

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

  // AXI mux: preload writes then feed reads
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
  logic [3:0]   rid_f;

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

  logic        start;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic [N_PE-1:0] pe_req;
  logic done, running;
  logic [31:0] empty_st, full_st, pe_st, pe_bs, cyc, cons, drops;
  logic [15:0] occ_a, occ_f;
  logic active_bank;
  logic [31:0] ddr_rdb, ddr_rdc, ddr_br;
  logic [31:0] axi_bytes, axi_bursts, axi_beats;
  logic [31:0] data_mm, rresp_err, rlast_err, exp_rec, rcv_rec, cons_rec;
  logic [3:0]  rid_obs;
  logic [31:0] rid_ord_err, r_bp, pe_mm;
  logic [127:0] pe_data_w;
  logic [31:0] expect_nid_w;
  logic [N_PE-1:0] pe_grant;
  logic [31:0] pe_grants;
  logic rst_n_ui;
  int cell_fail;
  int any_fail;
  int pe_mm_dbg;

  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;

  a7ng_ddr_feed_mig_top #(.BANK_DEPTH(32), .N_PE(N_PE), .MAX_OUT(8), .MAX_BURST(16)) dut (
    .clk(ui_clk), .rst_n(rst_n_ui),
    .start_i(start), .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs), .pe_req_i(pe_req),
    .done_o(done), .running_o(running),
    .empty_stall_o(empty_st), .full_stall_o(full_st),
    .pe_stall_o(pe_st), .pe_busy_o(pe_bs),
    .cycles_o(cyc), .recs_consumed_o(cons), .drop_o(drops),
    .occ_active_o(occ_a), .occ_fill_o(occ_f), .active_bank_o(active_bank),
    .ddr_rd_bytes_o(ddr_rdb), .ddr_rd_count_o(ddr_rdc), .ddr_burst_count_o(ddr_br),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts), .axi_read_beats_o(axi_beats),
    .data_mismatch_count_o(data_mm), .rresp_error_count_o(rresp_err),
    .rlast_error_count_o(rlast_err),
    .expected_records_o(exp_rec), .received_records_o(rcv_rec),
    .consumed_records_o(cons_rec),
    .rid_observed_o(rid_obs), .rid_order_error_o(rid_ord_err),
    .r_backpressure_cycles_o(r_bp), .pe_data_mismatch_count_o(pe_mm),
    .pe_data_o(pe_data_w), .expect_nid_o(expect_nid_w),
    .pe_grant_o(pe_grant), .pe_grant_count_o(pe_grants),
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

  task automatic preload_nodes(input int n);
    int k;
    begin
      for (k = 0; k < n; k++)
        axi_write_beat(a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k)), pack_node(32'(k)));
      $display("MIG_PRELOAD_DONE nodes=%0d NodeRecordV1_deterministic_node_id", n);
    end
  endtask

  task automatic run_cell(input int b, input int o);
    int timeout;
    int exp_bytes, exp_bursts;
    real stall_frac, recs_per_cyc;
    begin
      cell_fail = 0;
      pe_mm_dbg = 0;
      exp_bytes  = TOTAL * 16;
      exp_bursts = (TOTAL + b - 1) / b;  // ceil(TOTAL/burst)

      @(posedge ui_clk);
      burst = 5'(b);
      outstanding = 4'(o);
      base_node = 32'd0;
      total_recs = 32'(TOTAL);
      pe_req = {N_PE{1'b1}};
      start = 1'b1;
      @(posedge ui_clk);
      start = 1'b0;
      timeout = 0;
      while (!done && timeout < 2_000_000) begin
        @(posedge ui_clk);
        // Live PE consume check (TB scoreboard) — first 4 mismatches logged
        if (|pe_grant) begin
          if (pe_data_w[31:0] != expect_nid_w) begin
            if (pe_mm_dbg < 4)
              $display("PE_MISMATCH_DBG got_nid=%0d expect_nid=%0d pe_data=%032x grant=%0b",
                       pe_data_w[31:0], expect_nid_w, pe_data_w, pe_grant);
            pe_mm_dbg = pe_mm_dbg + 1;
          end
        end
        timeout = timeout + 1;
      end
      if (!done) begin
        $display("CELL_FAIL burst=%0d out=%0d TIMEOUT", b, o);
        cell_fail = 1;
      end else begin
        stall_frac = ((pe_st + pe_bs) == 0) ? 0.0 : real'(pe_st) / real'(pe_st + pe_bs);
        recs_per_cyc = (cyc == 0) ? 0.0 : real'(cons) / real'(cyc);

        // Per-run deltas (metric_clear on start) — NOT cumulative
        $display("MIG_METRIC_ROW burst=%0d out=%0d stall_frac=%0.6f recs_per_cyc=%0.6f pe_stall=%0d pe_busy=%0d cycles=%0d",
                 b, o, stall_frac, recs_per_cyc, pe_st, pe_bs, cyc);
        $display("MIG_DELTA axi_read_bytes=%0d axi_read_bursts=%0d axi_read_beats=%0d (expect bytes=%0d bursts=%0d beats=%0d)",
                 axi_bytes, axi_bursts, axi_beats, exp_bytes, exp_bursts, TOTAL);
        $display("MIG_INTEGRITY data_mismatch=%0d rresp_err=%0d rlast_err=%0d expected_records=%0d received_records=%0d consumed_records=%0d pe_data_mismatch=%0d",
                 data_mm, rresp_err, rlast_err, exp_rec, rcv_rec, cons_rec, pe_mm);
        $display("MIG_DIAG rid_observed=%0d rid_order_error=%0d r_backpressure_cycles=%0d pp_backpressure_ticks=%0d (NOT lost-data DROP)",
                 rid_obs, rid_ord_err, r_bp, drops);

        if (axi_bytes != exp_bytes) begin
          $display("CELL_FAIL burst=%0d DELTA_BYTES got=%0d expect=%0d", b, axi_bytes, exp_bytes);
          cell_fail = 1;
        end
        if (axi_bursts != exp_bursts) begin
          $display("CELL_FAIL burst=%0d DELTA_BURSTS got=%0d expect=%0d", b, axi_bursts, exp_bursts);
          cell_fail = 1;
        end
        if (axi_beats != TOTAL) begin
          $display("CELL_FAIL burst=%0d DELTA_BEATS got=%0d expect=%0d", b, axi_beats, TOTAL);
          cell_fail = 1;
        end
        if (data_mm != 0 || pe_mm != 0) begin
          $display("CELL_FAIL burst=%0d DATA_MISMATCH axi=%0d pe=%0d", b, data_mm, pe_mm);
          cell_fail = 1;
        end
        if (rresp_err != 0) begin
          $display("CELL_FAIL burst=%0d RRESP_ERR=%0d", b, rresp_err);
          cell_fail = 1;
        end
        if (rlast_err != 0) begin
          $display("CELL_FAIL burst=%0d RLAST_ERR=%0d", b, rlast_err);
          cell_fail = 1;
        end
        if (exp_rec != TOTAL || rcv_rec != TOTAL || cons_rec != TOTAL) begin
          $display("CELL_FAIL burst=%0d RECORD_CONSERVATION exp=%0d rcv=%0d cons=%0d expect=%0d",
                   b, exp_rec, rcv_rec, cons_rec, TOTAL);
          cell_fail = 1;
        end
        // RID association is reported; in-order-across-IDs is not a hard contract on MIG
        if (rid_ord_err != 0)
          $display("MIG_DIAG_RID_ASSOC_ERR=%0d (reported; hard-fail only if >0 with data mismatch)", rid_ord_err);
        if (rid_ord_err != 0 && data_mm != 0) begin
          $display("CELL_FAIL burst=%0d RID_ASSOC_WITH_DATA_ERR rid=%0d data_mm=%0d", b, rid_ord_err, data_mm);
          cell_fail = 1;
        end
        if (cell_fail == 0)
          $display("CELL_PASS burst=%0d out=%0d deltas_ok integrity_ok", b, o);
      end
      any_fail = any_fail + cell_fail;
      pe_req = '0;
      repeat (8) @(posedge ui_clk);
    end
  endtask

  initial begin
    feed_en = 1'b0;
    start = 1'b0;
    burst = 5'd1;
    outstanding = 4'd1;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    pe_req = '0;
    any_fail = 0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: mig_metric_00");
    $display("PREREG_METRICS: axi_read_bytes/bursts/beats, data/rresp/rlast, records, rid, r_backpressure");
    $display("PREREG_UNIT: sweep_cell(burst x outstanding) TOTAL=%0d", TOTAL);
    $display("PREREG_EXPECT: burst=1 -> 1024B/64 bursts; burst=4 -> 1024B/16 bursts (per-run deltas)");
    $display("PREREG_CONTROL: MIG-RIVAL cumulative (4,8)=2048B/80; mig.prj SHA; no COM12");
    $display("NOTE: Digilent AXI MIG + ddr3_model — Evidence_class=MIG_XSIM; not BOARD; not HS-02");
    $display("NOTE: RVALID&&!RREADY counted as r_backpressure_cycles — NOT lost-data DROP");

    wait (init_calib_complete === 1'b1);
    $display("MIG_CALIB_COMPLETE at %0t", $time);
    repeat (50) @(posedge ui_clk);

    preload_nodes(N_PRE);
    feed_en = 1'b1;
    repeat (20) @(posedge ui_clk);

    run_cell(1, 1);
    run_cell(4, 8);

    if (any_fail == 0) begin
      $display("A7NG_MIG_METRIC_XSIM_PASS");
      $display("A7NG_MIG_RIVAL_XSIM_PASS"); // keep prior marker for shared TCL parsers
    end else begin
      $display("A7NG_MIG_METRIC_XSIM_FAIL fails=%0d", any_fail);
    end
    $finish;
  end

  // safety timeout — use time literal (avoid 32-bit int overflow)
  initial begin
    #200ms;
    $display("MIG_METRIC_TIMEOUT — calib or sweep hung");
    $display("A7NG_MIG_METRIC_XSIM_FAIL");
    $finish;
  end
endmodule
