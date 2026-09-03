// G14-METRIC-MEASURE-01 P3/M7 — cue_soa_mig_top PHYS=4 (SoC u_soa). NO RTL EDIT.
`timescale 1ns / 1ps

module tb_g14_metric_p3m7_soa_xsim;
  import a7ng_pkg::*;
  localparam int TOTAL = 64;
  localparam int PHYS  = 4;
  localparam int WAVE  = 16;

  logic clk = 1'b0;
  always #5 clk = ~clk;
  logic rst_n, start, cons_ready;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node, total_recs;
  logic done, running, owner_ready, topk_valid;
  logic [31:0] axi_bytes, axi_beats, axi_bursts, cycles, waves, delivered;
  logic [31:0] empty_st, full_st, rbp;
  node_id_t topk_id [8];
  score_t   topk_score [8];

  logic [3:0] arid, rid, awid, bid;
  logic [27:0] araddr, awaddr;
  logic [7:0] arlen, awlen;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst, rresp, bresp;
  logic arvalid, arready, rvalid, rready, rlast;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic [127:0] rdata, wdata;
  logic [15:0] wstrb;

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

  assign cons_ready = 1'b1;

  a7ng_cue_soa_mig_top #(.WAVE(WAVE), .MAX_CANDS(TOTAL), .MAX_OUT(8), .MAX_BURST(16), .PHYS(PHYS)) dut (
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
    .cycles_o(cycles), .waves_o(waves), .cand_delivered_o(delivered),
    .data_mismatch_o(), .swap_count_o(),
    .buffer_empty_stall_o(empty_st), .buffer_full_stall_o(full_st),
    .soa_id_beats_o(), .soa_cue_beats_o(), .soa_prior_beats_o(),
    .bytes_id_o(), .bytes_cue_o(), .bytes_prior_o(), .bytes_total_o(),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts),
    .axi_read_beats_o(axi_beats),
    .expected_records_o(), .received_records_o(),
    .rresp_error_count_o(), .rlast_error_count_o(),
    .rid_order_error_o(), .r_backpressure_cycles_o(rbp),
    .topk_batches_o(), .topk_valid_o(topk_valid),
    .topk_score_o(topk_score), .topk_id_o(topk_id),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(), .global_topk_busy_o()
  );

  integer elig_cyc, lane_act_sum, fire_cyc, axi_w_bytes;
  integer snap32_act, snap32_elig, snap32_fire, got32;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      elig_cyc <= 0; lane_act_sum <= 0; fire_cyc <= 0; axi_w_bytes <= 0;
      snap32_act <= 0; snap32_elig <= 0; snap32_fire <= 0; got32 <= 0;
    end else begin
      if (running) begin
        elig_cyc <= elig_cyc + 1;
        if (|dut.tg_valid_in) fire_cyc <= fire_cyc + 1;
        lane_act_sum <= lane_act_sum + $countones(dut.tg_valid_in);
      end
      if (wvalid && wready) axi_w_bytes <= axi_w_bytes + 16;
      if (delivered == 32 && !got32) begin
        got32 <= 1;
        snap32_act <= lane_act_sum;
        snap32_elig <= elig_cyc;
        snap32_fire <= fire_cyc;
      end
    end
  end

  function automatic logic [31:0] golden_cue32(input logic [31:0] nid);
    return 32'hDDFE_0000 + nid;
  endfunction
  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32; c32 = golden_cue32(nid); return {c32, c32};
  endfunction

  task automatic preload(input int n);
    int b, k, pi; logic [127:0] beat;
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
    end
  endtask

  real lane_util, stall_frac;
  integer timeout, rd0;

  initial begin
    rst_n = 0; start = 0; burst = 5'd16; outstanding = 4'd8;
    base_node = 0; total_recs = TOTAL;
    awvalid = 0; wvalid = 0; bready = 0; wlast = 0;
    awid = 0; awaddr = 0; awlen = 0; awsize = 3'd4; awburst = 2'b01;
    wdata = 0; wstrb = 16'hFFFF;
    $display("G14-METRIC-MEASURE-01 P3/M7 SOA cue_soa_mig_top PHYS=4");
    $display("EVIDENCE_CLASS=XSIM AXI_STUB");
    preload(TOTAL);
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (40) @(posedge clk);
    timeout = 0;
    while (!owner_ready && timeout < 200000) begin @(posedge clk); timeout++; end
    $display("OWNER_READY=%0b wait=%0d", owner_ready, timeout);
    rd0 = axi_bytes;
    @(negedge clk); start = 1;
    @(negedge clk); start = 0;
    timeout = 0;
    while (!done && timeout < 300000) begin
      @(posedge clk); timeout++;
      if (timeout % 50000 == 0)
        $display("HB t=%0d bytes=%0d deliv=%0d run=%0b sch=%0d wf_st=%0d busy=%0b batch=%0b tg_rdy=%0b empty=%0d ng02=%0d stall=%0b",
                 timeout, axi_bytes, delivered, running, dut.sch, dut.u_soa.st,
                 dut.global_topk_busy, dut.core_batch_ready, dut.tg_ready, empty_st,
                 dut.u_core.flow_state_o, dut.u_core.push_stall_o);
    end
    repeat (8) @(posedge clk);
    if (!done) begin
      $display("P3_SNAP32_ACT=%0d ELIG=%0d FIRE=%0d", snap32_act, snap32_elig, snap32_fire);
      if (snap32_elig > 0)
        $display("P3_LANE_UTIL_AT_32=%0.6f",
                 real'(snap32_act) / (real'(PHYS) * real'(snap32_elig)));
      $display("M7_SOA_AXI_READ_BYTES_AT_HANG=%0d DELIVERED=%0d", axi_bytes, delivered);
      $display("HANG ng02_batch_ready=0 after 32/64 recs (XSIM). Not a complete query.");
      $display("G14_METRIC_P3M7_SOA_XSIM_PARTIAL");
      $finish;
    end
    lane_util = (elig_cyc == 0) ? 0.0 : real'(lane_act_sum) / (real'(PHYS) * real'(elig_cyc));
    stall_frac = (elig_cyc == 0) ? 0.0 : real'(empty_st) / real'(elig_cyc);
    $display("P3_LANE_ACTIVE_SUM=%0d", lane_act_sum);
    $display("P3_ELIGIBLE_CYCLES=%0d", elig_cyc);
    $display("P3_FIRE_CYCLES=%0d", fire_cyc);
    $display("P3_PHYS=%0d", PHYS);
    $display("P3_LANE_UTIL=%0.6f", lane_util);
    $display("P3_CYCLES_O=%0d WAVES=%0d DELIVERED=%0d", cycles, waves, delivered);
    $display("P4_XSIM_STUB_EMPTY_STALL=%0d (NOT MIG_XSIM)", empty_st);
    $display("P4_XSIM_STUB_FULL_STALL=%0d", full_st);
    $display("P4_XSIM_STUB_R_BACKPRESSURE=%0d", rbp);
    $display("P4_XSIM_STUB_STALL_FRAC=%0.6f", stall_frac);
    $display("M7_SOA_AXI_READ_BYTES=%0d delta=%0d", axi_bytes, axi_bytes - rd0);
    $display("M7_SOA_AXI_READ_BEATS=%0d BURSTS=%0d", axi_beats, axi_bursts);
    $display("M7_SOA_AXI_WRITE_BYTES=%0d", axi_w_bytes);
    $display("M7_SOA_BYTES_PER_QUERY=%0d", axi_bytes - rd0);
    $display("M7_SOA_BYTES_PER_CAND=%0.4f",
             (delivered == 0) ? 0.0 : real'(axi_bytes - rd0) / real'(delivered));
    $display("G14_METRIC_P3M7_SOA_XSIM_PASS");
    $finish;
  end
  initial begin #80ms; $display("G14_METRIC_P3M7_FAIL WALL"); $finish; end
endmodule
