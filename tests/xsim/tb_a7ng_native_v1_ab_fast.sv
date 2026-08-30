// A-FAST-LM-BOARD-LANE-00 — SIM_FULL=1, AXI mem stub (no MIG/DDR3)
`timescale 1ns/1ps

module tb_a7ng_native_v1_ab_fast;
  import a7ng_pkg::*;

  localparam int TOTAL = 64;
  localparam int N_PRE = 64;
  localparam int SOA_BYTES_PER_QUERY = 832;
  localparam int SOA_BEATS_PER_QUERY = 52;

  logic clk = 1'b0;
  logic dut_rst_n;
  logic stub_rst_n;
  always #5 clk = ~clk;

  logic [3:0]  arid_f, rid;
  logic [27:0] araddr_f;
  logic [7:0]  arlen_f;
  logic [2:0]  arsize_f;
  logic [1:0]  arburst_f;
  logic        arvalid_f, arready;
  logic [3:0]  arid;
  logic [27:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arvalid;
  logic [127:0] rdata;
  logic [1:0]  rresp;
  logic        rlast, rvalid, rready_f;
  logic        rready;
  logic [3:0]  awid, bid;
  logic [27:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        awvalid, awready;
  logic [127:0] wdata;
  logic [15:0] wstrb;
  logic        wlast, wvalid, wready;
  logic [1:0]  bresp;
  logic        bvalid, bready;

  bit lm_hold;

  assign arid    = lm_hold ? 4'd0 : arid_f;
  assign araddr  = lm_hold ? 28'd0 : araddr_f;
  assign arlen   = lm_hold ? 8'd0 : arlen_f;
  assign arsize  = lm_hold ? 3'd4 : arsize_f;
  assign arburst = lm_hold ? 2'b01 : arburst_f;
  assign arvalid = lm_hold ? 1'b0 : arvalid_f;
  assign rready  = lm_hold ? 1'b1 : rready_f;

  a7ng_axi_soa_mem_stub u_mem (
    .clk(clk), .rst_n(stub_rst_n),
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

  logic start, cons_ready, do_lm, poison, mem_we, bind_done;
  logic ctx_we, start_fwd, capture_valid, core_busy, core_done, final_accept, dual_err;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node, total_recs;
  logic done, running;
  logic [31:0] axi_bytes, axi_beats, axi_bursts, gv_count;
  logic [31:0] id_beats, cue_beats, prior_beats, delivered, waves;
  logic [9:0] pred;
  logic [7:0] phase;
  logic [63:0] ctx_pack;
  logic [31:0] ctx_beats, st_beats;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic [19:0] mem_addr;
  node_id_t poison_id [8];
  logic topk_valid;
  node_id_t topk_id [8];
  score_t topk_score [8];
  logic owner_ready;
  bit exam;
  int mem_we_exam, dual_ticks;
  logic query_ar_seen;
  logic [31:0] topk_update_count, topk_batches;
  logic [31:0] ar_fire_count;
  logic topk_seen;

  assign cons_ready = 1'b1;

  always_ff @(posedge clk) begin
    if (!dut_rst_n) begin
      mem_we_exam <= 0;
      dual_ticks <= 0;
    end else begin
      if (exam && mem_we) mem_we_exam <= mem_we_exam + 1;
      if (dual_err) dual_ticks <= dual_ticks + 1;
    end
  end

  a7ng_native_v1_ab_core #(.SIM_FULL(1'b1), .WAVE(16), .MAX_CANDS(TOTAL)) dut (
    .clk(clk), .rst_n(dut_rst_n),
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

  always_ff @(posedge clk) begin
    if (!dut_rst_n) begin
      topk_seen <= 1'b0;
      topk_update_count <= '0;
      query_ar_seen <= 1'b0;
      ar_fire_count <= '0;
    end else begin
      if (start) begin
        topk_seen <= 1'b0;
        topk_update_count <= '0;
        query_ar_seen <= 1'b0;
        ar_fire_count <= '0;
      end
      if (arvalid_f && arready) ar_fire_count <= ar_fire_count + 1;
      if (arvalid_f && arready && start) query_ar_seen <= 1'b1;
      if (topk_valid) begin
        topk_seen <= 1'b1;
        topk_update_count <= topk_update_count + 1;
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

  logic [31:0] topk_id_seen [8];
  logic signed [15:0] topk_score_seen [8];
  logic [31:0] top1_id_seen;
  logic signed [15:0] top1_score_seen;

  always_ff @(posedge clk) begin
    if (!dut_rst_n) begin
      top1_id_seen <= '0;
      top1_score_seen <= '0;
    end else if (start) begin
      top1_id_seen <= '0;
      top1_score_seen <= '0;
      for (int tk = 0; tk < 8; tk++) begin
        topk_id_seen[tk]    <= '0;
        topk_score_seen[tk] <= '0;
      end
    end else if (topk_valid) begin
      top1_id_seen <= topk_id[0];
      top1_score_seen <= topk_score[0];
      for (int tk = 0; tk < 8; tk++) begin
        topk_id_seen[tk] <= topk_id[tk];
        topk_score_seen[tk] <= topk_score[tk];
      end
    end
  end

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = golden_cue32(nid);
    return {c32, c32};
  endfunction

  function automatic logic [127:0] golden_desc_tb(input logic [31:0] nid);
    return {24'h0, 8'h03, golden_cue64(nid), nid};
  endfunction

  task automatic axi_write_beat(input logic [27:0] addr, input logic [127:0] data);
    @(posedge clk);
    awid <= 4'd0; awaddr <= addr; awlen <= 8'd0; awsize <= 3'd4; awburst <= 2'b01;
    awvalid <= 1'b1; wdata <= data; wstrb <= 16'hFFFF; wlast <= 1'b1; wvalid <= 1'b1; bready <= 1'b1;
    fork
      begin wait (awvalid && awready); @(posedge clk); awvalid <= 1'b0; end
      begin wait (wvalid && wready); @(posedge clk); wvalid <= 1'b0; wlast <= 1'b0; end
    join
    wait (bvalid && bready);
    @(posedge clk);
    bready <= 1'b0;
  endtask

  task automatic drain_stale_axi_r;
    int drain;
    begin
      drain = 0;
      while (rvalid && drain < 64) begin
        @(posedge clk);
        drain = drain + 1;
      end
      repeat (20) @(posedge clk);
    end
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
    dut_rst_n = 1'b0;
    stub_rst_n = 1'b0;
    start = 1'b0;
    do_lm = 1'b0;
    poison = 1'b0;
    mem_we = 1'b0;
    exam = 1'b0;
    lm_hold = 1'b0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    awid = 0; awaddr = 0; awlen = 0; awsize = 3'd4; awburst = 2'b01;
    wdata = 0; wstrb = 16'hFFFF;

    $display("PREREG_GATE: A-FAST-LM-BOARD-LANE-00");
    $display("EVIDENCE_CLASS: XSIM_FAST_CAUSAL");
    $display("STRUCTURAL TB_DOES_NOT_DRIVE_BIND_OR_TOP8_INJECTION");

    preload_soa_planes(N_PRE);
    $readmemh("a7lm06_wmem.hex", dut.u_core.u_w.FULL.u_full.mem);
    $display("LM06_WMEM_BACKDOOR_DONE");
    repeat (10) @(posedge clk);
    stub_rst_n = 1'b1;
    dut_rst_n = 1'b1;
    repeat (50) @(posedge clk);
    drain_stale_axi_r();

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

    exam = 1'b1;
    repeat (20) @(posedge clk);

    burst = 5'd16;
    outstanding = 4'd8;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;

    begin
      int timeout;
      timeout = 0;
      while (done !== 1'b1 && timeout < 200000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      if (done !== 1'b1) begin
        $display("A_FAST_LM_BOARD_LANE_FAIL SOA_TIMEOUT bytes=%0d beats=%0d gv=%0d ar_fires=%0d rlast_err=%0d br_out=%0d",
                 axi_bytes, axi_beats, gv_count, ar_fire_count,
                 dut.u_soa.u_br.rlast_error_count_o, dut.u_soa.u_br.outstanding_beats_o);
        $finish;
      end
    end

    begin
      int topk_wait;
      topk_wait = 0;
      // Min-heap merge is multi-cycle; bitonic was ~2. Wait for 4 global_valid.
      while ((topk_update_count < 4 || gv_count < 4) && topk_wait < 4096) begin
        @(posedge clk);
        topk_wait = topk_wait + 1;
      end
      @(negedge clk);
    end

    $display("SOA_DELTA axi_read_bytes=%0d axi_read_beats=%0d bursts=%0d gv=%0d topk_updates=%0d",
             axi_bytes, axi_beats, axi_bursts, gv_count, topk_update_count);
    $display("SOA_PLANE id=%0d cue=%0d prior=%0d delivered=%0d waves=%0d",
             id_beats, cue_beats, prior_beats, delivered, waves);

    if (axi_bytes != SOA_BYTES_PER_QUERY || axi_beats != SOA_BEATS_PER_QUERY ||
        topk_update_count != 4 || gv_count != 4 || !topk_seen || topk_batches != 4) begin
      $display("A_FAST_LM_BOARD_LANE_FAIL SOA_PATTERN bytes=%0d beats=%0d gv=%0d topk=%0d batches=%0d",
               axi_bytes, axi_beats, gv_count, topk_update_count, topk_batches);
      $finish;
    end
    $display("SOA_PATTERN_PASS burst=16 out=8");
    $display("SOA_DATA_MISMATCH=%0d", dut.u_soa.data_mismatch_o);
    $display("SOA_TOP1 id=%0d score=%0d (expect id=9 score=165)", top1_id_seen, top1_score_seen);
    for (int k = 0; k < 8; k++)
      $display("SOA_GLOBAL_TOP8[%0d] id=%0d score=%0d expect_id=%0d",
               k, topk_id_seen[k], topk_score_seen[k], aos_global_top8_id(k));
    if (dut.u_soa.data_mismatch_o !== 32'd0) begin
      $display("A_FAST_LM_BOARD_LANE_FAIL SOA_DATA_MISMATCH=%0d", dut.u_soa.data_mismatch_o);
      $finish;
    end
    if (top1_id_seen != 9 || top1_score_seen != 165) begin
      $display("A_FAST_LM_BOARD_LANE_FAIL SOA_SCORE_LAW id=%0d score=%0d", top1_id_seen, top1_score_seen);
      $finish;
    end
    for (int k = 0; k < 8; k++) begin
      if (topk_id_seen[k] != aos_global_top8_id(k) || topk_score_seen[k] != 165) begin
        $display("A_FAST_LM_BOARD_LANE_FAIL SOA_GLOBAL_TOP8[%0d] id=%0d score=%0d expect=%0d/165",
                 k, topk_id_seen[k], topk_score_seen[k], aos_global_top8_id(k));
        $finish;
      end
    end

    lm_hold = 1'b1;
    $display("AXI_LM_HOLD freeze DUT AR after SOA_PATTERN_PASS");
    $display("NEG_CHECK pred=%0d start_fwd_beats=%0d do_lm=%0d", pred, st_beats, do_lm);
    if (st_beats !== 32'd0 || pred !== 10'd0) begin
      $display("A_FAST_LM_BOARD_LANE_FAIL NEG pred=%0d st=%0d", pred, st_beats);
      $finish;
    end

    @(negedge clk);
    do_lm = 1'b1;
    fork
      begin wait (final_accept); end
      begin
        repeat (4096) @(posedge clk);
        $display("A_FAST_LM_BOARD_LANE_FAIL NO_FINAL_ACCEPT gv=%0d pending_check", gv_count);
        $finish;
      end
    join_any
    disable fork;
    @(posedge clk);
    @(negedge clk);
    poison = 1'b1;
    for (int k = 0; k < 8; k++) poison_id[k] = 32'd255;
    @(posedge clk);
    #1;
    if (ctx_we !== 1'b1 || ctx_pack !== 64'h3b392b291b190b09) begin
      $display("A_FAST_LM_BOARD_LANE_FAIL CAPTURE pack=%h ctx_we=%0b", ctx_pack, ctx_we);
      $finish;
    end
    $display("CAPTURE_OK pack=%h", ctx_pack);
    @(posedge clk);
    poison = 1'b0;

    begin
      int lt;
      lt = 0;
      while (bind_done !== 1'b1 && lt < 200_000_000) begin
        @(posedge clk);
        lt = lt + 1;
        if (lt % 200000 == 0)
          $display("LM_HB cyc=%0d phase=%0d busy=%0b done=%0b pred=%0d bind_done=%0b",
                   lt, phase, core_busy, core_done, pred, bind_done);
      end
      if (bind_done !== 1'b1) begin
        $display("A_FAST_LM_BOARD_LANE_FAIL LM_TIMEOUT pred=%0d phase=%0d", pred, phase);
        $finish;
      end
    end

    if (pred === 10'd664 && dual_ticks === 0 && mem_we_exam === 0 && st_beats === 32'd1)
      $display("A_FAST_LM_BOARD_LANE_XSIM_PASS pred=%0d", pred);
    else
      $display("A_FAST_LM_BOARD_LANE_FAIL pred=%0d dual=%0d mem_we=%0d st=%0d",
               pred, dual_ticks, mem_we_exam, st_beats);
    $finish;
  end

  initial begin
    #2500ms;
    $display("A_FAST_LM_BOARD_LANE_FAIL WALL_TIMEOUT");
    $finish;
  end
endmodule
