// tb_a7ng_ddr_cue_soa.sv — ddr_cue_soa_00 MIG XSim
// UNKNOWN: Can physical SOA layout reduce first-stage DDR bytes/query without changing laws?
// CONTROL: AOS NodeRecordV1 path = 1024 B / 64 candidates (ddr_wavefront_00)
// UNIT: one query = 64 candidates; SOA target = 832 B (52 beats)
`timescale 1ps / 100fs

module tb_a7ng_native_v1_ab_mig;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int N_LANES = 16;
  localparam int TOTAL   = 64;
  localparam int N_PRE   = 64;
  localparam int SOA_BYTES_PER_QUERY = TOTAL * 13;
  localparam int SOA_BEATS_PER_QUERY = (TOTAL+3)/4 + (TOTAL+1)/2 + (TOTAL+15)/16;
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

  bit lm_hold;
  // After SOA_PATTERN_PASS freeze DUT AR so TinyGPT is not drowned by
  // leftover PRIOR fetches (R5: MV0 still in layer 0 at 878 ms sim).
  // feed_en stays 1 so rst_n_ui remains asserted.
  assign arid    = (feed_en && !lm_hold) ? arid_f    : arid_w;
  assign araddr  = (feed_en && !lm_hold) ? araddr_f  : araddr_w;
  assign arlen   = (feed_en && !lm_hold) ? arlen_f   : arlen_w;
  assign arsize  = (feed_en && !lm_hold) ? arsize_f  : arsize_w;
  assign arburst = (feed_en && !lm_hold) ? arburst_f : arburst_w;
  assign arvalid = (feed_en && !lm_hold) ? arvalid_f : (feed_en ? 1'b0 : arvalid_w);
  assign rready  = (feed_en && !lm_hold) ? rready_f  : (feed_en ? 1'b1 : rready_w);

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
  logic        owner_ready;

  int ar_mon_cnt;
  int ar_mon_fail;
  logic [27:0] ar_mon_addr [4];
  logic [7:0]  ar_mon_len  [4];
  logic        query_active;
  logic        query_running_seen;
  logic        start_seen;
  logic        query_ar_seen;
  logic        topk_seen;
  logic [31:0] topk_update_count;
  logic [31:0] top1_id_seen;
  logic signed [15:0] top1_score_seen;
  logic [31:0] topk_id_seen [8];
  logic signed [15:0] topk_score_seen [8];
  logic        ar_stall_q, r_stall_q;
  logic [3:0]  ar_stall_id_q, r_stall_id_q;
  logic [27:0] ar_stall_addr_q;
  logic [7:0]  ar_stall_len_q;
  logic [2:0]  ar_stall_size_q;
  logic [1:0]  ar_stall_burst_q, r_stall_resp_q;
  logic [127:0] r_stall_data_q;
  logic         r_stall_last_q;
  logic [31:0]  ar_stable_err, r_stable_err;
  int          ar_before_start;
  int          ar_after_start;

  assign rst_n_ui = ~ui_rst & init_calib_complete & feed_en;
  assign cons_ready = 1'b1;

  logic do_lm, poison, mem_we, bind_done, ctx_we, start_fwd, capture_valid;
  logic core_busy, core_done, final_accept, dual_err;
  logic [7:0] phase;
  logic [9:0] pred;
  logic [63:0] ctx_pack;
  logic [31:0] ctx_beats, st_beats, gv_count;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic [19:0] mem_addr;
  a7ng_pkg::node_id_t poison_id [8];
  integer pzi;
  bit exam;
  int unsigned mem_we_exam;
  int unsigned dual_ticks;
  always_ff @(posedge ui_clk) begin
    if (!rst_n_ui) begin
      mem_we_exam <= 0;
      dual_ticks  <= 0;
    end else begin
      if (exam && mem_we) mem_we_exam <= mem_we_exam + 1;
      if (dual_err) dual_ticks <= dual_ticks + 1;
    end
  end

  a7ng_native_v1_ab_core #(.SIM_FULL(1'b1), .WAVE(N_LANES), .MAX_CANDS(TOTAL)) dut (
    .clk(ui_clk), .rst_n(rst_n_ui),
    .start_query_i(start), .do_lm_i(do_lm),
    .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .cons_ready_i(cons_ready),
    .q_query_cue_i(64'hA5A5_0F0F_1234_5678),
    .q_intent_cue_i(64'h1111_2222_3333_4444),
    .q_relation_cue_i(64'h0F1E_2D3C_4B5A_6978),
    .q_context_cue_i(64'hDEAD_BEEF_CAFE_0001),
    .q_path_cue_i(64'h00FF_00FF_00FF_00FF),
    .poison_i(poison), .poison_id_i(poison_id),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .soa_done_o(done), .soa_running_o(running),
    .axi_read_bytes_o(axi_bytes), .axi_read_beats_o(axi_beats), .axi_read_bursts_o(axi_bursts),
    .soa_id_beats_o(id_beats), .soa_cue_beats_o(cue_beats), .soa_prior_beats_o(prior_beats),
    .waves_o(waves), .cand_delivered_o(delivered),
    .topk_batches_o(topk_batches), .topk_valid_o(topk_valid),
    .topk_score_o(topk_score), .topk_id_o(topk_id),
    .gv_count_o(gv_count),
    .grant_graph_o(), .grant_lm_o(), .dual_owner_err_o(dual_err),
    .bind_busy_o(), .bind_done_o(bind_done),
    .ctx_we_o(ctx_we), .ctx_pack_o(ctx_pack), .start_fwd_o(start_fwd),
    .capture_valid_o(capture_valid),
    .ctx_we_beats_o(ctx_beats), .start_fwd_beats_o(st_beats),
    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred),
    .phase_o(phase), .final_accept_o(final_accept),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f),
    .owner_ready_o(owner_ready),
    .r_path_idle_o()
  );
  assign bytes_id = dut.u_soa.bytes_id_o;
  assign bytes_cue = dut.u_soa.bytes_cue_o;
  assign bytes_prior = dut.u_soa.bytes_prior_o;
  assign bytes_total = dut.u_soa.bytes_total_o;
  assign exp_rec = dut.u_soa.expected_records_o;
  assign rcv_rec = dut.u_soa.received_records_o;
  assign data_mm = dut.u_soa.data_mismatch_o;
  assign swap_cnt = dut.u_soa.swap_count_o;
  assign buf_empty = dut.u_soa.buffer_empty_stall_o;
  assign buf_full = dut.u_soa.buffer_full_stall_o;
  assign rresp_err = dut.u_soa.rresp_error_count_o;
  assign rlast_err = dut.u_soa.rlast_error_count_o;
  assign rid_ord_err = dut.u_soa.rid_order_error_o;
  assign r_bp = dut.u_soa.r_backpressure_cycles_o;


  // ===== ddr_cue_soa_bench_01 common metrics =====
  logic        bench_arm;
  logic        bench_first_ar_seen;
  logic        bench_first_wave_seen;
  logic        bench_fourth_wave_seen;
  logic        bench_done_seen;
  int unsigned bench_wave_accept_count;
  int unsigned bench_L_first_wave;
  int unsigned bench_L_last_wave;
  int unsigned bench_L_query;
  int unsigned bench_M_wait_common;
  int unsigned bench_DDR_service_span;
  int unsigned bench_cycle_from_ar;
  logic        bench_wave_fire;
  logic        bench_consumer_ready;

  assign bench_consumer_ready = cons_ready;
  // Accepted wave = SOA wave_valid handshake into consumer path
  assign bench_wave_fire = dut.u_soa.wave_valid && dut.u_soa.wf_cons_ready;

  always_ff @(posedge ui_clk) begin
    if (!feed_en) begin
      bench_arm <= 1'b0;
      bench_first_ar_seen <= 1'b0;
      bench_first_wave_seen <= 1'b0;
      bench_fourth_wave_seen <= 1'b0;
      bench_done_seen <= 1'b0;
      bench_wave_accept_count <= 0;
      bench_L_first_wave <= 0;
      bench_L_last_wave <= 0;
      bench_L_query <= 0;
      bench_M_wait_common <= 0;
      bench_DDR_service_span <= 0;
      bench_cycle_from_ar <= 0;
    end else begin
      if (start) begin
        bench_arm <= 1'b1;
        bench_first_ar_seen <= 1'b0;
        bench_first_wave_seen <= 1'b0;
        bench_fourth_wave_seen <= 1'b0;
        bench_done_seen <= 1'b0;
        bench_wave_accept_count <= 0;
        bench_L_first_wave <= 0;
        bench_L_last_wave <= 0;
        bench_L_query <= 0;
        bench_M_wait_common <= 0;
        bench_DDR_service_span <= 0;
        bench_cycle_from_ar <= 0;
      end

      if (bench_arm && arvalid_f && arready && !bench_first_ar_seen) begin
        bench_first_ar_seen <= 1'b1;
        bench_cycle_from_ar <= 0;
      end else if (bench_arm && bench_first_ar_seen) begin
        bench_cycle_from_ar <= bench_cycle_from_ar + 1;
      end

      if (bench_arm && bench_first_ar_seen && rvalid && rready_f)
        bench_DDR_service_span <= bench_cycle_from_ar + 1;

      if (bench_arm && bench_first_ar_seen && !bench_fourth_wave_seen) begin
        if (bench_consumer_ready && !bench_wave_fire)
          bench_M_wait_common <= bench_M_wait_common + 1;
        if (bench_wave_fire) begin
          bench_wave_accept_count <= bench_wave_accept_count + 1;
          if (!bench_first_wave_seen) begin
            bench_first_wave_seen <= 1'b1;
            bench_L_first_wave <= bench_cycle_from_ar + 1;
          end
          if ((bench_wave_accept_count + 1) == 4) begin
            bench_fourth_wave_seen <= 1'b1;
            bench_L_last_wave <= bench_cycle_from_ar + 1;
          end
        end
      end

      // L_query: first AR -> final Global Top-K / done
      // L_query = first AR -> query completion (done after final Global Top-K).
      if (bench_arm && bench_first_ar_seen && done && !bench_done_seen) begin
        bench_done_seen <= 1'b1;
        bench_L_query <= bench_cycle_from_ar + 1;
        bench_arm <= 1'b0;
      end
    end
  end

  function automatic bit ar_is_id_plane(input logic [27:0] a);
    return (a >= NG_DDR_NODE_BASE) && (a < NG_DDR_CUE64_BASE);
  endfunction

  function automatic bit ar_is_prior_plane(input logic [27:0] a);
    return (a >= NG_DDR_PRIOR_BASE);
  endfunction

  function automatic logic [27:0] expected_query_ar_addr(input int idx);
    case (idx)
      0: return NG_DDR_NODE_BASE;
      1: return NG_DDR_CUE64_BASE;
      2: return NG_DDR_CUE64_BASE + 28'h0000_0100;
      3: return NG_DDR_PRIOR_BASE;
      default: return '1;
    endcase
  endfunction

  function automatic logic [7:0] expected_query_ar_len(input int idx);
    case (idx)
      0, 1, 2: return 8'd15;
      3: return 8'd3;
      default: return 8'hFF;
    endcase
  endfunction

  // Unconditional AXI AR-fire ledger (NOT gated by query_active).
  // Attempt 10 drives start across a full posedge so start_seen cannot race
  // the task's deassertion and misclassify query ARs as PRELOAD.
  always @(posedge ui_clk) begin
    if (!feed_en) begin
      query_active    <= 1'b0;
      query_running_seen <= 1'b0;
      ar_mon_cnt      <= 0;
      start_seen      <= 1'b0;
      query_ar_seen   <= 1'b0;
      ar_before_start <= 0;
      ar_after_start  <= 0;
    end else begin
      if (start) begin
        query_active  <= 1'b1;
        query_running_seen <= 1'b0;
        start_seen    <= 1'b1;
        query_ar_seen <= 1'b0;
        ar_mon_cnt    <= 0;
        ar_after_start <= 0;
      end else begin
        if (query_active && running)
          query_running_seen <= 1'b1;
        if (done && query_running_seen) begin
          query_active <= 1'b0;
          query_running_seen <= 1'b0;
        end
      end

      if (arvalid_f && arready) begin
        if (start_seen || start) begin
          $display("SOA_AR_LEDGER t=%0t addr=0x%08h feed_en=%0b start=%0b query_active=%0b running=%0b tag=QUERY",
                   $time, araddr_f, feed_en, start, query_active, running);
          ar_after_start <= ar_after_start + 1;
          if (!query_ar_seen || start) begin
            $display("SOA_AR_FIRST_QUERY addr=0x%08h t=%0t", araddr_f, $time);
            query_ar_seen <= 1'b1;
          end
        end else begin
          $display("SOA_AR_LEDGER t=%0t addr=0x%08h feed_en=%0b start=%0b query_active=%0b running=%0b tag=PRELOAD",
                   $time, araddr_f, feed_en, start, query_active, running);
          ar_before_start <= ar_before_start + 1;
        end

        // Optional extra: keep SOA_AR_MON. Ledger FACT is printed first.
        // Do not $fatal here — $finish only after ledger lines exist.
        if (start_seen || start) begin
          if (ar_mon_cnt < 4) begin
            ar_mon_addr[ar_mon_cnt] <= araddr_f;
            ar_mon_len[ar_mon_cnt]  <= arlen_f;
            $display("SOA_AR_MON[%0d] addr=0x%08h len=%0d phase=%s", ar_mon_cnt, araddr_f, arlen_f,
                     ar_is_id_plane(araddr_f) ? "ID" :
                     ar_is_prior_plane(araddr_f) ? "PRIOR" : "OTHER");
            if (ar_mon_cnt == 0 && araddr_f != NG_DDR_NODE_BASE) begin
              $display("SOA_AR_FAILFAST first_ar=0x%08h expect_id_base=0x%08h",
                       araddr_f, NG_DDR_NODE_BASE);
              $display("A7NG_DDR_CUE_SOA_BENCH_SOA_FAIL fails=1 first_ar_not_id");
              $finish;
            end
            ar_mon_cnt <= ar_mon_cnt + 1;
          end
        end
      end
    end
  end

  // Equivalent AXI stall-stability checker for the custom master boundary.
  // A payload presented without READY must remain valid and bit-stable until
  // the eventual handshake.  Bridge counters below cover RRESP/RLAST/RID.
  always @(posedge ui_clk) begin
    if (!feed_en || start) begin
      ar_stall_q        <= 1'b0;
      r_stall_q         <= 1'b0;
      ar_stable_err     <= '0;
      r_stable_err      <= '0;
      ar_stall_id_q     <= '0;
      ar_stall_addr_q   <= '0;
      ar_stall_len_q    <= '0;
      ar_stall_size_q   <= '0;
      ar_stall_burst_q  <= '0;
      r_stall_id_q      <= '0;
      r_stall_data_q    <= '0;
      r_stall_resp_q    <= '0;
      r_stall_last_q    <= 1'b0;
    end else begin
      if (ar_stall_q &&
          (!arvalid_f || arid_f !== ar_stall_id_q ||
           araddr_f !== ar_stall_addr_q || arlen_f !== ar_stall_len_q ||
           arsize_f !== ar_stall_size_q || arburst_f !== ar_stall_burst_q))
        ar_stable_err <= ar_stable_err + 32'd1;

      if (r_stall_q &&
          (!rvalid || rid !== r_stall_id_q || rdata !== r_stall_data_q ||
           rresp !== r_stall_resp_q || rlast !== r_stall_last_q))
        r_stable_err <= r_stable_err + 32'd1;

      ar_stall_q <= arvalid_f && !arready;
      if (arvalid_f && !arready) begin
        ar_stall_id_q    <= arid_f;
        ar_stall_addr_q  <= araddr_f;
        ar_stall_len_q   <= arlen_f;
        ar_stall_size_q  <= arsize_f;
        ar_stall_burst_q <= arburst_f;
      end

      r_stall_q <= rvalid && !rready_f;
      if (rvalid && !rready_f) begin
        r_stall_id_q   <= rid;
        r_stall_data_q <= rdata;
        r_stall_resp_q <= rresp;
        r_stall_last_q <= rlast;
      end
    end
  end

  // Top-K valid is a pulse; retain the latest complete result so the summary
  // cannot accidentally skip the law check after the pulse has deasserted.
  always_ff @(posedge ui_clk) begin
    if (!feed_en) begin
      topk_seen       <= 1'b0;
      topk_update_count <= '0;
      top1_id_seen    <= '0;
      top1_score_seen <= '0;
      for (int tk = 0; tk < 8; tk++) begin
        topk_id_seen[tk]    <= '0;
        topk_score_seen[tk] <= '0;
      end
    end else if (start) begin
      topk_seen       <= 1'b0;
      topk_update_count <= '0;
      top1_id_seen    <= '0;
      top1_score_seen <= '0;
      for (int tk = 0; tk < 8; tk++) begin
        topk_id_seen[tk]    <= '0;
        topk_score_seen[tk] <= '0;
      end
    end else if (topk_valid) begin
      topk_seen       <= 1'b1;
      topk_update_count <= topk_update_count + 32'd1;
      top1_id_seen    <= topk_id[0];
      top1_score_seen <= topk_score[0];
      for (int tk = 0; tk < 8; tk++) begin
        topk_id_seen[tk]    <= topk_id[tk];
        topk_score_seen[tk] <= topk_score[tk];
      end
    end
  end

  function automatic logic [31:0] golden_cue32(input logic [31:0] nid);
    return 32'hDDFE_0000 + nid;
  endfunction

  function automatic logic [31:0] aos_global_top8_id(input int idx);
    case (idx)
      0: return 32'd9;
      1: return 32'd11;
      2: return 32'd25;
      3: return 32'd27;
      4: return 32'd41;
      5: return 32'd43;
      6: return 32'd57;
      7: return 32'd59;
      default: return 32'hFFFF_FFFF;
    endcase
  endfunction

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = golden_cue32(nid);
    return {c32, c32};
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
    int b, k, pi;
    logic [127:0] beat;
    begin
      for (b = 0; b < (n+3)/4; b++) begin
        beat = '0;
        for (k = 0; k < 4; k++) begin
          pi = b*4 + k;
          if (pi < n) beat[k*32 +: 32] = 32'(pi);
        end
        axi_write_beat(NG_DDR_NODE_BASE + b*16, beat);
      end
      for (b = 0; b < (n+1)/2; b++) begin
        beat = '0;
        for (k = 0; k < 2; k++) begin
          pi = b*2 + k;
          if (pi < n) beat[k*64 +: 64] = golden_cue64(32'(pi));
        end
        axi_write_beat(NG_DDR_CUE64_BASE + b*16, beat);
      end
      for (b = 0; b < (n+15)/16; b++) begin
        beat = '0;
        for (k = 0; k < 16; k++) begin
          pi = b*16 + k;
          if (pi < n) beat[k*8 +: 8] = 8'h03;
        end
        axi_write_beat(NG_DDR_PRIOR_BASE + b*16, beat);
      end
      $display("SOA_PRELOAD_DONE planes id/cue64/prior candidates=%0d", n);
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
      // Drive away from the monitor/DUT sampling edge.  Attempt 9 used
      // blocking assignments around @(posedge), so the monitor could see
      // start=0 on the very edge where the DUT saw the pulse.
      @(negedge ui_clk);
      start = 1'b1;
      @(negedge ui_clk);
      start = 1'b0;
      $display("SOA_QUERY_START t=%0t p=%0d", $time, pid);
      begin
        int ar_wait;
        ar_wait = 0;
        while (!query_ar_seen && ar_wait < 1024) begin
          @(posedge ui_clk);
          ar_wait = ar_wait + 1;
        end
        $display("SOA_AR_COUNTS before_start=%0d after_start=%0d query_ar_seen=%0b wait_cyc=%0d",
                 ar_before_start, ar_after_start, query_ar_seen, ar_wait);
        if (!query_ar_seen) begin
          $display("SOA_NO_QUERY_AR");
          $display("A7NG_DDR_CUE_SOA_BENCH_SOA_FAIL fails=1 NO_QUERY_AR");
          $finish;
        end
      end
      timeout = 0;
      while (!done && timeout < 8192) begin
        @(posedge ui_clk);
        timeout = timeout + 1;
      end
      if (!done) begin
        $display("SOA_QUERY_TIMEOUT cycles=%0d ar_after_start=%0d id_beats=%0d cue_beats=%0d prior_beats=%0d",
                 timeout, ar_after_start, id_beats, cue_beats, prior_beats);
        $display("SOA_QUERY_TIMEOUT_STATE phase=%0d plane_active=%0b pf_running=%0b pf_done_pulse=%0b pf_issued=%0d pf_returned=%0d need_pack=%0b cnt0=%0d cnt1=%0d delivered=%0d waves=%0d axi_bytes=%0d axi_beats=%0d",
                 dut.u_soa.u_soa.phase, dut.u_soa.u_soa.plane_active, dut.u_soa.u_soa.pf_running,
                 dut.u_soa.u_soa.pf_done_pulse, dut.u_soa.u_soa.pf_issued, dut.u_soa.u_soa.pf_returned,
                 dut.u_soa.u_soa.need_pack, dut.u_soa.u_soa.cnt0, dut.u_soa.u_soa.cnt1,
                 delivered, waves, axi_bytes, axi_beats);
        $display("A7NG_DDR_CUE_SOA_BENCH_SOA_FAIL fails=1 QUERY_TIMEOUT");
        $finish;
      end
      begin
        int topk_wait;
        topk_wait = 0;
        // Min-heap merge is multi-cycle; bitonic was ~2. Do not reuse 64.
        while ((topk_update_count < 4 || gv_count < 4) && topk_wait < 4096) begin
          @(posedge ui_clk);
          topk_wait = topk_wait + 1;
        end
        @(negedge ui_clk);
      end

      bytes_per_cand = (delivered == 0) ? 0.0 : real'(axi_bytes) / real'(delivered);

      $display("=== SOA_PATTERN p=%0d burst=%0d out=%0d ===", pid, b, o);
      $display("SOA_AR_ORDER first4_cnt=%0d prior_in_first4=%0d", ar_mon_cnt, ar_mon_fail);
      for (k = 0; k < ar_mon_cnt && k < 4; k = k + 1)
        $display("SOA_AR_ORDER[%0d]=0x%08h len=%0d", k, ar_mon_addr[k], ar_mon_len[k]);
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

      top1_id = top1_id_seen; top1_score = top1_score_seen;
      $display("SOA_TOP1 seen=%0b updates=%0d id=%0d score=%0d (AOS GLOBAL id=9 score=165)",
               topk_seen, topk_update_count, top1_id, top1_score);
      for (k = 0; k < 8; k = k + 1)
        $display("SOA_GLOBAL_TOP8[%0d] id=%0d score=%0d expect_id=%0d expect_score=165",
                 k, topk_id_seen[k], topk_score_seen[k], aos_global_top8_id(k));
      $display("SOA_PROTOCOL pc_asserted=%0d ar_stable_err=%0d r_stable_err=%0d rresp_err=%0d rlast_err=%0d rid_err=%0d r_backpressure=%0d",
               ((ar_stable_err | r_stable_err | rresp_err | rlast_err | rid_ord_err) != 0),
               ar_stable_err, r_stable_err, rresp_err, rlast_err, rid_ord_err, r_bp);
      $display("SOA_CONSERVATION expected=%0d received=%0d consumed=%0d plane_sum=%0d bytes_total=%0d axi_bytes=%0d owner_ready=%0b",
               exp_rec, rcv_rec, axi_beats, id_beats + cue_beats + prior_beats,
               bytes_total, axi_bytes, owner_ready);

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
      if (axi_bursts != 4 || ar_after_start != 4) begin
        $display("SOA_PATTERN_FAIL p=%0d TRANSACTIONS axi_bursts=%0d ar_fires=%0d expect=4/4",
                 pid, axi_bursts, ar_after_start);
        cell_fail = 1;
      end
      if (id_beats != 16 || cue_beats != 32 || prior_beats != 4 ||
          (id_beats + cue_beats + prior_beats) != 52) begin
        $display("SOA_PATTERN_FAIL p=%0d PLANE_COUNTS id=%0d cue=%0d prior=%0d expect=16/32/4",
                 pid, id_beats, cue_beats, prior_beats);
        cell_fail = 1;
      end
      if (bytes_total != SOA_BYTES_PER_QUERY || bytes_total != axi_bytes) begin
        $display("SOA_PATTERN_FAIL p=%0d BYTE_CONSERVATION plane=%0d axi=%0d expect=%0d",
                 pid, bytes_total, axi_bytes, SOA_BYTES_PER_QUERY);
        cell_fail = 1;
      end
      if (exp_rec != SOA_BEATS_PER_QUERY || rcv_rec != SOA_BEATS_PER_QUERY ||
          exp_rec != rcv_rec || rcv_rec != axi_beats) begin
        $display("SOA_PATTERN_FAIL p=%0d RECORD_CONSERVATION expected=%0d received=%0d consumed=%0d expect=52/52/52",
                 pid, exp_rec, rcv_rec, axi_beats);
        cell_fail = 1;
      end
      if (rresp_err != 0 || rlast_err != 0 || rid_ord_err != 0 ||
          ar_stable_err != 0 || r_stable_err != 0) begin
        $display("SOA_PATTERN_FAIL p=%0d AXI_PROTOCOL ar_stable=%0d r_stable=%0d rresp=%0d rlast=%0d rid=%0d",
                 pid, ar_stable_err, r_stable_err, rresp_err, rlast_err, rid_ord_err);
        cell_fail = 1;
      end
      if (!owner_ready) begin
        $display("SOA_PATTERN_FAIL p=%0d OWNER_NOT_IDLE", pid);
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
      if (!topk_seen || topk_batches != 4 || topk_update_count != 4) begin
        $display("SOA_PATTERN_FAIL p=%0d TOPK_EVIDENCE seen=%0b batches=%0d updates=%0d expect=1/4/4",
                 pid, topk_seen, topk_batches, topk_update_count);
        cell_fail = 1;
      end else if (top1_id != 9 || top1_score != 165) begin
        $display("SOA_PATTERN_FAIL p=%0d SCORE_LAW id=%0d score=%0d", pid, top1_id, top1_score);
        cell_fail = 1;
      end
      for (k = 0; k < 8; k = k + 1) begin
        if (topk_id_seen[k] != aos_global_top8_id(k) || topk_score_seen[k] != 165) begin
          $display("SOA_PATTERN_FAIL p=%0d GLOBAL_TOP8[%0d] id=%0d score=%0d expect=%0d/165",
                   pid, k, topk_id_seen[k], topk_score_seen[k], aos_global_top8_id(k));
          cell_fail = 1;
        end
      end
      if (ar_mon_cnt != 4) begin
        $display("SOA_PATTERN_FAIL p=%0d AR_ORDER count=%0d expect=4", pid, ar_mon_cnt);
        cell_fail = 1;
      end
      for (k = 0; k < ar_mon_cnt && k < 4; k = k + 1) begin
        if (ar_mon_addr[k] != expected_query_ar_addr(k) ||
            ar_mon_len[k] != expected_query_ar_len(k)) begin
          $display("SOA_PATTERN_FAIL p=%0d AR_ORDER[%0d] got=0x%08h/%0d expect=0x%08h/%0d",
                   pid, k, ar_mon_addr[k], ar_mon_len[k],
                   expected_query_ar_addr(k), expected_query_ar_len(k));
          cell_fail = 1;
        end
      end
      $display("BENCH_ROW layout=SOA burst=%0d outstanding=%0d B_query=%0d R_beats=%0d AR_bursts=%0d L_first_wave=%0d L_last_wave=%0d L_query=%0d M_wait_common=%0d DDR_service_span=%0d cand_per_cyc=%0.6f useful_B_per_cyc=%0.6f waves=%0d",
               b, o, axi_bytes, axi_beats, axi_bursts,
               bench_L_first_wave, bench_L_last_wave, bench_L_query, bench_M_wait_common, bench_DDR_service_span,
               (bench_L_query == 0) ? 0.0 : (64.0 / real'(bench_L_query)),
               (bench_DDR_service_span == 0) ? 0.0 : (real'(axi_bytes) / real'(bench_DDR_service_span)),
               waves);
      if (bench_L_first_wave == 0 || bench_L_last_wave == 0 || bench_L_query == 0) begin
        $display("SOA_PATTERN_FAIL p=%0d BENCH_METRIC_ZERO L_first=%0d L_last=%0d L_query=%0d",
                 pid, bench_L_first_wave, bench_L_last_wave, bench_L_query);
        cell_fail = 1;
      end
      if (cell_fail == 0)
        $display("SOA_PATTERN_PASS p=%0d burst=%0d out=%0d", pid, b, o);
      any_fail = any_fail + cell_fail;
      repeat (16) @(posedge ui_clk);
    end
  endtask

  task automatic drain_stale_axi_r;
    int drain;
    begin
      rready_w = 1'b1;
      drain = 0;
      while (rvalid && drain < 64) begin
        @(posedge ui_clk);
        drain = drain + 1;
      end
      rready_w = 1'b0;
      repeat (4) @(posedge ui_clk);
    end
  endtask

  initial begin
    feed_en = 1'b0;
    start = 1'b0;
    any_fail = 0;
    ar_mon_cnt = 0;
    ar_mon_fail = 0;
    query_active = 1'b0;
    query_running_seen = 1'b0;
    start_seen = 1'b0;
    query_ar_seen = 1'b0;
    ar_before_start = 0;
    ar_after_start = 0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    arid_w = 4'd0; araddr_w = 28'd0; arlen_w = 8'd0; arsize_w = 3'd4;
    arburst_w = 2'b01; arvalid_w = 1'b0; rready_w = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;

    $display("STRUCTURAL TB_DOES_NOT_DRIVE_BIND_OR_TOP8_INJECTION");
    $display("CAUSAL_ONLY SIM_FULL=1 zero-latency W/act/snap substitution; physical candidate is SIM_FULL=0");
    $display("PREREG_GATE: native_v1_ab_integrate_accept_00");
    $display("PREREG_ATTEMPT: 10-CLOSURE-PROTOCOL-FINAL");
    $display("PREREG_UNKNOWN: with AOS-identical content and the frozen cross-wave reducer, does SOA preserve the full AOS Global Top-8 over 64 candidates?");
    $display("PREREG_CONTROL: AOS cue64={cue32,cue32}, prior=3, Global Top1=9/165, Top8 ids=9,11,25,27,41,43,57,59; AOS bytes=%0d", AOS_BYTES_CONTROL);
    $display("PREREG_H_CANDIDATE: both outstanding patterns use exact 4-AR plan, satisfy expected=received=consumed=52, zero protocol/stall errors, owner idle, all eight AOS Global Top-K slots, and 832/64/4-wave conservation.");
    $display("PREREG_H_RIVAL: SOA physical delivery or cross-wave accumulation changes candidate content/order despite identical logical fields.");
    $display("PREREG_FALSIFIER: any AR/length, burst, plane/byte/record conservation, RRESP/RLAST/RID, AR/R stall-stability, owner-idle, global oracle mismatch, or timeout.");
    $display("PREREG_UNIT: one query after preload; unit != clock cycle; TOTAL=%0d candidates", TOTAL);
    $display("PREREG_H_CANDIDATE_ENG: SOA 104b fields in 3 columns = %0d B/query (engineering UNKNOWN remains OPEN)", SOA_BYTES_PER_QUERY);

    do_lm = 1'b0; poison = 1'b0; mem_we = 1'b0; mem_addr = 20'd0; mem_wdata = 8'sd0;
    exam = 1'b0; lm_hold = 1'b0;
    for (pzi = 0; pzi < 8; pzi = pzi + 1) poison_id[pzi] = 32'd0;
    wait (init_calib_complete === 1'b1);
    repeat (50) @(posedge ui_clk);
    // Backdoor SIM_FULL weight image while DUT still held in reset (feed_en=0).
    // Cycle-by-cycle 802816 mem_we on a live MIG UI was R2 stall: TB thread
    // blocked in $readmemh after feed_en, DUT issued PRIOR reads without query.
    $readmemh("a7lm06_wmem.hex", dut.u_core.u_w.FULL.u_full.mem);
    $display("LM06_WMEM_BACKDOOR_DONE path=dut.u_core.u_w.FULL.u_full.mem");
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
    exam = 1'b1;
    repeat (20) @(posedge ui_clk);

    run_pattern(2, 16, 8);
    lm_hold = 1'b1;
    $display("AXI_LM_HOLD freeze DUT AR after SOA_PATTERN_PASS");
    $display("NEG_CHECK pred=%0d start_fwd_beats=%0d do_lm=%0d", pred, st_beats, do_lm);
    if (st_beats !== 32'd0 || pred !== 10'd0) begin
      $display("NATIVE_V1_AB_FAIL NEG");
      $finish;
    end
    begin
      integer k;
      @(negedge ui_clk);
      do_lm = 1'b1;
      // Level-sensitive wait: do not @(posedge) in the wait loop — that
      // consumed the accept edge in R3 and sampled ctx_we one cycle late
      // (pack already 3b392b291b190b09, ctx_we=0).
      fork
        begin wait (final_accept); end
        begin
          repeat (4096) @(posedge ui_clk);
          $display("NATIVE_V1_AB_FAIL NO_FINAL_ACCEPT");
          $finish;
        end
      join_any
      disable fork;
      @(posedge ui_clk);
      @(negedge ui_clk);
      poison = 1'b1;
      for (k = 0; k < 8; k = k + 1) poison_id[k] = 32'd255;
      $display("R2_POISON_NEGEDGE between_accept_and_S_CTX");
      @(posedge ui_clk);
      #1;
      if (ctx_we !== 1'b1 || ctx_pack !== 64'h3b392b291b190b09) begin
        $display("NATIVE_V1_AB_FAIL CAPTURE pack=%h ctx_we=%0b", ctx_pack, ctx_we);
        $finish;
      end
      $display("CAPTURE_OK pack=%h", ctx_pack);
      @(posedge ui_clk); poison = 1'b0;
      begin
        int lt;
        lt = 0;
        while (!bind_done && lt < 50_000_000) begin
          @(posedge ui_clk);
          #1;
          lt = lt + 1;
          if (lt % 200000 == 0)
            $display("LM_HB cyc=%0d phase=%0d busy=%0b done=%0b pred=%0d bind_done=%0b",
                     lt, phase, core_busy, core_done, pred, bind_done);
        end
        if (!bind_done) begin
          $display("NATIVE_V1_AB_FAIL LM_TIMEOUT phase=%0d pred=%0d busy=%0b", phase, pred, core_busy);
          $finish;
        end
        $display("BIND_DONE cyc=%0d pred=%0d", lt, pred);
      end
    end
    $display("AB_DYNAMIC axi_beats=%0d axi_bytes=%0d gv=%0d pred=%0d dual_ticks=%0d start_fwd=%0d mem_we_exam=%0d",
             axi_beats, axi_bytes, gv_count, pred, dual_ticks, st_beats, mem_we_exam);
    if (any_fail == 0 && pred === 10'd664 && axi_bytes === 32'd832 && axi_beats === 32'd52 &&
        dual_ticks === 0 && mem_we_exam === 0 && st_beats === 32'd1)
      $display("NATIVE_V1_AB_MIG_XSIM_PASS pred=%0d", pred);
    else
      $display("NATIVE_V1_AB_MIG_XSIM_FAIL pred=%0d bytes=%0d beats=%0d fail=%0d dual=%0d mem_we_exam=%0d st=%0d",
               pred, axi_bytes, axi_beats, any_fail, dual_ticks, mem_we_exam, st_beats);
    $finish;
  end

  initial begin
    // MIG XSim: preload + exact 4-AR/52-beat query plan + 4 drain waves.
    #5000ms;
    $display("SOA_TIMEOUT");
    $display("NATIVE_V1_AB_MIG_XSIM_FAIL");
    $finish;
  end
endmodule
