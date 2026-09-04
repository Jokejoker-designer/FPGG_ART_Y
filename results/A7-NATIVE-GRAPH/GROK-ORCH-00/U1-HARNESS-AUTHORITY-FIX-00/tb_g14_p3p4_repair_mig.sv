// tb_g14_p3p4_repair_mig.sv — P3P4-METRIC-REPAIR-00
// MEASUREMENT ONLY. NO RTL EDIT. NO BIT. NO PROGRAM.
// PHYS=4 WAVE=16 N=64 burst=16 outstanding=4 (silicon regs; plane engine still MAX_OUT=1).
`timescale 1ps / 100fs

module tb_g14_p3p4_repair_mig;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int N_LANES = 16;
  localparam int TOTAL   = 64;
  localparam int N_PRE   = 64;
  localparam int SOA_BYTES_PER_QUERY = TOTAL * 16;
  localparam int SOA_BEATS_PER_QUERY = TOTAL;
  localparam int AOS_BYTES_CONTROL = TOTAL * 16;

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

  initial begin sys_rst_n = 1'b0; #RESET_PERIOD sys_rst_n = 1'b1; end
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
        .rst_n(ddr3_reset_n), .ck(ddr3_ck_p_sdram), .ck_n(ddr3_ck_n_sdram),
        .cke(ddr3_cke_sdram[0]), .cs_n(ddr3_cs_n_sdram[0]),
        .ras_n(ddr3_ras_n_sdram), .cas_n(ddr3_cas_n_sdram), .we_n(ddr3_we_n_sdram),
        .dm_tdqs(ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
        .ba(ddr3_ba_sdram[0]), .addr(ddr3_addr_sdram[0]),
        .dq(ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
        .dqs(ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
        .dqs_n(ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
        .tdqs_n(), .odt(ddr3_odt_sdram[0])
      );
    end
  endgenerate

  logic        start, cons_ready;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic        rst_n_ui;

  logic        done, running;
  logic [31:0] axi_bytes, axi_bursts, axi_beats, exp_rec, rcv_rec;
  logic [31:0] data_mm, swap_cnt, buf_empty, buf_full;
  logic [31:0] id_beats, cue_beats, prior_beats;
  logic [31:0] bytes_id, bytes_cue, bytes_prior, bytes_total;
  logic [31:0] rresp_err, rlast_err, rid_ord_err, r_bp;
  logic [31:0] waves, delivered, topk_batches;
  logic        topk_valid;
  logic [31:0] topk_id [8];
  logic signed [15:0] topk_score [8];
  logic signed [15:0] top1_score;
  logic [31:0] top1_id;
  logic        topk_seen;
  logic signed [15:0] top1_score_hold;
  logic [31:0] top1_id_hold;
  int          topk_pulse;
  int          topk_pulse_live;
  logic        owner_ready;
  logic        gbusy;
  logic        merge_done;
  int          merge_pulse;

  // FINAL-ONLY: one ordered_valid. It may arrive after running=0.
  always_ff @(posedge ui_clk) begin
    if (!rst_n_ui || start) begin
      topk_seen <= 1'b0;
      topk_pulse <= 0;
      topk_pulse_live <= 0;
      merge_pulse <= 0;
    end else begin
      if (merge_done)
        merge_pulse <= merge_pulse + 1;
      if (topk_valid) begin
        $display("SOA_TOPK_PULSE n=%0d id=%0d score=%0d running=%0b gbusy=%0b",
                 topk_pulse + 1, topk_id[0], topk_score[0], running, gbusy);
        topk_pulse <= topk_pulse + 1;
        if (running || gbusy)
          topk_pulse_live <= topk_pulse_live + 1;
        if (!topk_seen) begin
          topk_seen <= 1'b1;
          top1_id_hold <= topk_id[0];
          top1_score_hold <= topk_score[0];
        end
      end
    end
  end

  int ar_mon_cnt;
  int ar_mon_fail;
  logic [27:0] ar_mon_addr [4];
  logic        query_active;

  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;
  assign cons_ready = 1'b1;

  a7ng_cue_soa_mig_top #(
    .WAVE(N_LANES), .MAX_CANDS(TOTAL), .MAX_OUT(8), .MAX_BURST(16), .PHYS(4)
  ) dut (
    .clk(ui_clk), .rst_n(rst_n_ui),
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
    .data_mismatch_o(data_mm), .swap_count_o(swap_cnt),
    .buffer_empty_stall_o(buf_empty), .buffer_full_stall_o(buf_full),
    .soa_id_beats_o(id_beats), .soa_cue_beats_o(cue_beats), .soa_prior_beats_o(prior_beats),
    .bytes_id_o(bytes_id), .bytes_cue_o(bytes_cue), .bytes_prior_o(bytes_prior),
    .bytes_total_o(bytes_total),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts), .axi_read_beats_o(axi_beats),
    .expected_records_o(exp_rec), .received_records_o(rcv_rec),
    .rresp_error_count_o(rresp_err), .rlast_error_count_o(rlast_err),
    .rid_order_error_o(rid_ord_err), .r_backpressure_cycles_o(r_bp),
    .topk_batches_o(topk_batches), .topk_valid_o(topk_valid),
    .topk_score_o(topk_score), .topk_id_o(topk_id),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(),
    .global_topk_busy_o(gbusy),
    .merge_done_o(merge_done)
  );

  function automatic bit ar_is_id_plane(input logic [27:0] a);
    return (a >= NG_DDR_NODE_BASE) && (a < NG_DDR_CUE64_BASE);
  endfunction

  function automatic bit ar_is_prior_plane(input logic [27:0] a);
    return (a >= NG_DDR_PRIOR_BASE);
  endfunction

  always @(posedge ui_clk) begin
    if (!feed_en || !rst_n_ui) begin
      query_active <= 1'b0;
      ar_mon_cnt   <= 0;
    end else if (start)
      query_active <= 1'b1;
    else if (done)
      query_active <= 1'b0;

    if (feed_en && rst_n_ui && query_active && arvalid_f && arready) begin
      if (ar_mon_cnt < 4) begin
        ar_mon_addr[ar_mon_cnt] <= araddr_f;
        $display("SOA_AR_MON[%0d] addr=0x%08h phase=%s", ar_mon_cnt, araddr_f,
                 ar_is_id_plane(araddr_f) ? "ID" :
                 ar_is_prior_plane(araddr_f) ? "PRIOR" : "OTHER");
        if (ar_mon_cnt < 4 && ar_is_prior_plane(araddr_f))
          ar_mon_fail <= ar_mon_fail + 1;
        ar_mon_cnt <= ar_mon_cnt + 1;
      end
    end
  end

  function automatic logic [31:0] golden_cue32(input logic [31:0] nid);
    return 32'hDDFE_0000 + nid;
  endfunction

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = golden_cue32(nid);
    return {c32, c32};
  endfunction

  function automatic logic [127:0] golden_aos_desc(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[95:32]   = golden_cue64(nid);
    b[103:96]  = 8'h03;
    return b;
  endfunction

  task automatic axi_write_beat(input logic [27:0] addr, input logic [127:0] data);
    @(posedge ui_clk);
    awid <= 4'd0; awaddr <= addr; awlen <= 8'd0; awsize <= 3'd4; awburst <= 2'b01;
    awvalid <= 1'b1; wdata <= data; wstrb <= 16'hFFFF; wlast <= 1'b1; wvalid <= 1'b1; bready <= 1'b1;
    fork
      begin wait (awvalid && awready); @(posedge ui_clk); awvalid <= 1'b0; end
      begin wait (wvalid && wready); @(posedge ui_clk); wvalid <= 1'b0; wlast <= 1'b0; end
    join
    wait (bvalid && bready);
    @(posedge ui_clk);
    bready <= 1'b0;
  endtask

  task automatic preload_soa_planes(input int n);
    int pi;
    begin
      for (pi = 0; pi < n; pi++)
        axi_write_beat(NG_DDR_NODE_BASE + 28'(pi * 16), golden_aos_desc(32'(pi)));
      $display("SOA_PRELOAD_DONE aos_desc candidates=%0d bytes=%0d", n, n * 16);
    end
  endtask

  int any_fail;
  int cell_fail;

  task automatic run_pattern(input int pid, input int b, input int o);
    int timeout;
    real bytes_per_cand;
    int k;
    begin
      cell_fail = 0;
      ar_mon_cnt = 0;
      ar_mon_fail = 0;
      burst = 5'(b); outstanding = 4'(o);
      base_node = 32'd0; total_recs = 32'(TOTAL);
      start = 1'b1;
      @(posedge ui_clk);
      start = 1'b0;
      timeout = 0;
      while (!done && timeout < 32_000_000) begin
        @(posedge ui_clk);
        timeout = timeout + 1;
      end
      // Drain last wave: running_o falls at last accept; TG/NG/Global still
      // in flight (gbusy is 0 at that instant). Wait a fixed drain window.
      begin
        int dwait;
        dwait = 0;
        while (dwait < 1024) begin
          @(posedge ui_clk);
          dwait = dwait + 1;
        end
        $display("P3P4_DRAIN_WAIT dwait=%0d gbusy=%0b running=%0b", dwait, gbusy, running);
      end
      repeat (16) @(posedge ui_clk);

      bytes_per_cand = (delivered == 0) ? 0.0 : real'(axi_bytes) / real'(delivered);

      $display("=== SOA_PATTERN p=%0d burst=%0d out=%0d ===", pid, b, o);
      $display("SOA_AR_ORDER first4_cnt=%0d prior_in_first4=%0d", ar_mon_cnt, ar_mon_fail);
      for (k = 0; k < ar_mon_cnt && k < 4; k = k + 1)
        $display("SOA_AR_ORDER[%0d]=0x%08h", k, ar_mon_addr[k]);
      $display("SOA_DELTA axi_read_bytes=%0d axi_read_beats=%0d (expect %0d/%0d)",
               axi_bytes, axi_beats, SOA_BYTES_PER_QUERY, SOA_BEATS_PER_QUERY);
      $display("SOA_CONTROL aos_bytes=%0d reduction_bytes=%0d bytes_per_cand=%0.4f (aos=16.0000)",
               AOS_BYTES_CONTROL, AOS_BYTES_CONTROL - axi_bytes, bytes_per_cand);
      $display("SOA_PLANE id_beats=%0d cue_beats=%0d prior_beats=%0d",
               id_beats, cue_beats, prior_beats);
      $display("SOA_PLANE_CREDIT id=%0d cue=%0d prior=%0d total=%0d",
               bytes_id, bytes_cue, bytes_prior, bytes_total);
      $display("SOA_SCORE delivered=%0d waves=%0d data_mismatch=%0d topk_batches=%0d",
               delivered, waves, data_mm, topk_batches);

      if (topk_seen) begin
        top1_id = top1_id_hold; top1_score = top1_score_hold;
        $display("SOA_TOP1 id=%0d score=%0d seen=1 pulse=%0d live=%0d merge=%0d",
                 top1_id, top1_score, topk_pulse, topk_pulse_live, merge_pulse);
      end else begin
        $display("SOA_PATTERN_FAIL p=%0d TOPK_NEVER_VALID", pid);
        cell_fail = 1;
      end

      if (!done) begin
        $display("SOA_PATTERN_FAIL p=%0d TIMEOUT", pid);
        cell_fail = 1;
      end
      if (axi_bytes != SOA_BYTES_PER_QUERY) begin
        $display("SOA_PATTERN_FAIL p=%0d BYTES got=%0d expect=%0d", pid, axi_bytes, SOA_BYTES_PER_QUERY);
        cell_fail = 1;
      end
      if (axi_beats != SOA_BEATS_PER_QUERY) begin
        $display("SOA_PATTERN_FAIL p=%0d BEATS got=%0d expect=%0d", pid, axi_beats, SOA_BEATS_PER_QUERY);
        cell_fail = 1;
      end
      if (delivered != TOTAL) begin
        $display("SOA_PATTERN_FAIL p=%0d DELIVERED got=%0d expect=%0d", pid, delivered, TOTAL);
        cell_fail = 1;
      end
      if (data_mm != 0) begin
        $display("SOA_PATTERN_FAIL p=%0d DATA_MISMATCH=%0d", pid, data_mm);
        cell_fail = 1;
      end
      if (topk_seen && (topk_pulse != 1)) begin
        $display("SOA_PATTERN_FAIL p=%0d ORDERED_VALID_COUNT got=%0d expect=1", pid, topk_pulse);
        cell_fail = 1;
      end
      if (merge_pulse != 4) begin
        $display("SOA_PATTERN_FAIL p=%0d MERGE_DONE got=%0d expect=4", pid, merge_pulse);
        cell_fail = 1;
      end
      if (ar_mon_fail != 0) begin
        $display("SOA_PATTERN_FAIL p=%0d AR_ORDER prior before ID bank0", pid);
        cell_fail = 1;
      end
      for (k = 0; k < ar_mon_cnt && k < 4; k = k + 1) begin
        if (!ar_is_id_plane(ar_mon_addr[k])) begin
          $display("SOA_PATTERN_FAIL p=%0d AR_ORDER[%0d]=0x%08h not ID plane", pid, k, ar_mon_addr[k]);
          cell_fail = 1;
        end
      end
      if (cell_fail == 0)
        $display("SOA_PATTERN_PASS p=%0d burst=%0d out=%0d", pid, b, o);
      any_fail = any_fail + cell_fail;
      repeat (16) @(posedge ui_clk);
    end
  endtask

  task automatic drain_stale_axi_r;
    int quiet, guard;
    begin
      rready_w = 1'b1;
      quiet = 0;
      guard = 0;
      // Attempt 8: idle MIG R after preload before DUT reset/feed_en.
      while (quiet < 32 && guard < 20000) begin
        @(posedge ui_clk);
        guard = guard + 1;
        if (rvalid || arvalid_w)
          quiet = 0;
        else
          quiet = quiet + 1;
      end
      rready_w = 1'b0;
      repeat (16) @(posedge ui_clk);
      $display("SOA_PRELOAD_DRAIN quiet=%0d guard=%0d", quiet, guard);
    end
  endtask

  initial begin
    feed_en = 1'b0;
    start = 1'b0;
    any_fail = 0;
    ar_mon_cnt = 0;
    ar_mon_fail = 0;
    query_active = 1'b0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: U1-HARNESS-AUTHORITY-FIX-00");
    $display("PREREG_UNKNOWN: fail-closed SOA_PATTERN; AOS 1024/64; ordered_valid after running=0");
    $display("PREREG_CONTROL: PHYS=4 WAVE=16 N=64 burst=16 AOS 16B/cand bytes=1024 beats=64");
    $display("PREREG_UNIT: TOTAL=%0d candidates", TOTAL);
    $display("PREREG_RTL_EDIT=NO_DUT BIT=NO PROGRAM=NO GATE14_PASS=NO");

    wait (init_calib_complete === 1'b1);
    repeat (50) @(posedge ui_clk);
    preload_soa_planes(N_PRE);
    drain_stale_axi_r();
    feed_en = 1'b1;
    begin
      int ow;
      ow = 0;
      while (!owner_ready && ow < 500_000) begin
        @(posedge ui_clk);
        ow = ow + 1;
      end
      if (!owner_ready)
        $display("SOA_OWNER_READY_TIMEOUT");
      else
        $display("SOA_OWNER_READY ok cycles=%0d", ow);
    end
    repeat (20) @(posedge ui_clk);

    $display("P3P4_REPAIR_N=%0d PHYS=4 WAVE=16 burst=16 out=4", TOTAL);
    run_pattern(1, 16, 4);

    $display("P3P4_REPAIR_TB_DONE delivered=%0d axi_bytes=%0d cell_fail=%0d",
             delivered, axi_bytes, any_fail);
    if (any_fail != 0) begin
      $display("HARNESS_AUTHORITY_FAIL cell_fail=%0d", any_fail);
      $display("P3P4_REPAIR_TB_FAIL");
    end else begin
      $display("HARNESS_AUTHORITY_PASS");
      $display("P3P4_REPAIR_TB_PASS");
    end
    $finish;
  end

  initial begin
    // MIG XSim: preload ~125 ms + 52 single-beat plane reads + 4 drain waves (wf ref ~1609 cyc/p1).
    #2500ms;
    $display("SOA_TIMEOUT");
    $display("A7NG_DDR_CUE_SOA_XSIM_FAIL");
    $finish;
  end
endmodule
