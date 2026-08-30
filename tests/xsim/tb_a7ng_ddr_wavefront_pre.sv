// tb_a7ng_ddr_wavefront_pre.sv — PREFLIGHT ONLY for ddr_wavefront_00
// Evidence_class: SYNTH_AXI_PREFLIGHT. This is NOT gate evidence and NOT MIG.
// Purpose: exercise the bounded wave stage + conservation ledger against the behavioural
// AXI model (single outstanding) so logic faults are caught before the MIG run.
// The gate result comes only from tb_a7ng_ddr_wavefront (Digilent AXI MIG + ddr3_model).
//
// MODEL LIMIT (measured, not assumed): a7ng_axi_mem_model registers rdata from the *previous*
// ar_a on every beat after the first, so any burst > 1 returns a duplicated/lagged beat. The
// preflight therefore sweeps burst=1 x {outstanding, throttle} only. Burst depth 1/4/16 is
// exercised on the real Digilent AXI MIG in the gate testbench.
`timescale 1ns / 1ps

module tb_a7ng_ddr_wavefront_pre;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int N_LANES = 16;
  localparam int ENT_PB  = 16;
  localparam int WS_BOUND = N_LANES * ENT_PB;
  localparam int TOTAL   = 64;

  logic clk = 1'b0;
  logic rst_n;
  always #5 clk = ~clk;

  logic [3:0]  awid, arid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0]  awlen, arlen;
  logic [2:0]  awsize, arsize;
  logic [1:0]  awburst, arburst, bresp, rresp;
  logic        awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic        arvalid, arready, rvalid, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0]  wstrb;
  logic [3:0]   bid;

  logic        start, flush, sink_ready;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;

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
  logic [31:0] lane_scored, lane_busy_cyc, topk_batches, top1_id;
  logic signed [15:0] top1_score;

  assign flush = feed_done;

  int thr_period, thr_cnt;
  assign sink_ready = (thr_period == 0) ? 1'b1 : (thr_cnt == 0);
  always @(posedge clk) begin
    if (thr_period == 0) thr_cnt <= 0;
    else                 thr_cnt <= (thr_cnt + 1) % thr_period;
  end

  a7ng_ddr_wavefront_top #(
    .BANK_DEPTH(32), .N_LANES(N_LANES), .ENTRIES_PER_BANK(ENT_PB),
    .MAX_OUT(8), .MAX_BURST(16)
  ) dut (
    .clk(clk), .rst_n(rst_n),
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
    .topk_batches_o(topk_batches), .top1_id_o(top1_id), .top1_score_o(top1_score),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  a7ng_axi_mem_model #(.DEPTH_WORDS(4096)) u_mem (
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

  int tb_mm, tb_waves, tb_cands, tb_full;

  always @(posedge clk) begin
    if (rst_n && w_fire) begin
      int width;
      width = 0;
      for (int b = 0; b < N_LANES; b++) begin
        if (w_mask[b]) begin
          logic [31:0] exp_id;
          width = width + 1;
          exp_id = base_node + 32'(w_index) * 32'(N_LANES) + 32'(b);
          if (w_id[b] !== exp_id || w_cue[b] !== (32'hDDFE_0000 + exp_id)) begin
            tb_mm = tb_mm + 1;
            if (tb_mm < 6)
              $display("PRE_MISMATCH wave=%0d lane=%0d got=%0d exp=%0d cue=%08x",
                       w_index, b, w_id[b], exp_id, w_cue[b]);
          end
        end
      end
      tb_waves = tb_waves + 1;
      tb_cands = tb_cands + width;
      if (width == N_LANES) tb_full = tb_full + 1;
    end
  end

  int any_fail;

  task automatic preload();
    int k;
    begin
      for (k = 0; k < TOTAL; k++) begin
        @(posedge clk);
        awid <= 4'd0;
        awaddr <= a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k));
        awlen <= 8'd0; awsize <= 3'd4; awburst <= 2'b01;
        awvalid <= 1'b1;
        wdata <= pack_node(32'(k)); wstrb <= 16'hFFFF; wlast <= 1'b1; wvalid <= 1'b1;
        bready <= 1'b1;
        wait (awvalid && awready); @(posedge clk); awvalid <= 1'b0;
        wait (wvalid && wready);   @(posedge clk); wvalid <= 1'b0; wlast <= 1'b0;
        wait (bvalid && bready);   @(posedge clk); bready <= 1'b0;
      end
      $display("PRE_PRELOAD_DONE n=%0d", TOTAL);
    end
  endtask

  task automatic run_pattern(input int pid, input int b, input int o, input int thr);
    int timeout, exp_bytes, exp_bursts, in_flight, fail;
    int e1, e2, e3, e4, e5;
    real jpe;
    begin
      fail = 0; tb_mm = 0; tb_waves = 0; tb_cands = 0; tb_full = 0;
      exp_bytes = TOTAL * 16;
      exp_bursts = (TOTAL + b - 1) / b;
      thr_period = thr;
      @(posedge clk);
      burst = 5'(b); outstanding = 4'(o);
      base_node = 32'd0; total_recs = 32'(TOTAL);
      start = 1'b1; @(posedge clk); start = 1'b0;
      timeout = 0;
      while (!(feed_done && wave_done) && timeout < 200000) begin
        @(posedge clk); timeout = timeout + 1;
      end
      // running_o includes min-heap busy + TG/SC inflight. Bitonic settle was 8.
      begin
        int heap_wait;
        heap_wait = 0;
        while (running && heap_wait < 4096) begin
          @(posedge clk);
          heap_wait = heap_wait + 1;
        end
        repeat (8) @(posedge clk);
      end
      if (!(feed_done && wave_done)) begin
        $display("PRE_FAIL p=%0d TIMEOUT feed=%0b wave=%0b accepted=%0d dispatched=%0d resident=%0d rcv=%0d beat_mm=%0d struct=%0d bank=%0d tb=%0d",
                 pid, feed_done, wave_done, w_accepted, w_dispatched, w_resident, rcv_rec,
                 beat_mm, w_struct_mm, w_bank_err, tb_mm);
        fail = 1;
      end else begin
        in_flight = int'(exp_rec) - int'(rcv_rec);
        e1 = (in_flight == 0);
        e2 = (int'(rcv_rec) == int'(pp_cons) + int'(pp_res));
        e3 = (int'(w_accepted) == int'(w_dispatched) + int'(w_resident));
        e4 = (int'(w_dispatched) == int'(lane_scored));
        e5 = (int'(w_dispatched) == TOTAL) && (int'(rcv_rec) == TOTAL);
        jpe = (w_emit_cyc == 0) ? 0.0 : real'(w_dispatched) / real'(w_emit_cyc);
        $display("PRE_ROW p=%0d burst=%0d out=%0d thr=%0d bytes=%0d(exp %0d) bursts=%0d(exp %0d) beats=%0d waves=%0d full=%0d jpe=%0.3f max_res=%0d",
                 pid, b, o, thr, axi_bytes, exp_bytes, axi_bursts, exp_bursts, axi_beats,
                 w_waves, tb_full, jpe, w_max_res);
        $display("PRE_CONS E1=%0d E2=%0d E3=%0d E4=%0d E5=%0d acc=%0d disp=%0d res=%0d scored=%0d mm(axi/struct/bank/tb)=%0d/%0d/%0d/%0d bank_full_stall=%0d swap=%0d",
                 e1, e2, e3, e4, e5, w_accepted, w_dispatched, w_resident, lane_scored,
                 beat_mm, w_struct_mm, w_bank_err, tb_mm, w_bank_full_st, swap_cnt);
        if (!(e1 && e2 && e3 && e4 && e5)) fail = 1;
        if (axi_bytes != exp_bytes || axi_bursts != exp_bursts || axi_beats != TOTAL) fail = 1;
        if (beat_mm != 0 || w_struct_mm != 0 || w_bank_err != 0 || tb_mm != 0) fail = 1;
        if (tb_full == 0 || jpe < 15.999) fail = 1;
        if (tb_cands != TOTAL) fail = 1;
        if (w_max_res > WS_BOUND) fail = 1;
        if (fail == 0) $display("PRE_PASS p=%0d", pid);
        else           $display("PRE_FAIL p=%0d checks", pid);
      end
      any_fail = any_fail + fail;
      thr_period = 0;
      repeat (16) @(posedge clk);
    end
  endtask

  initial begin
    rst_n = 1'b0;
    start = 1'b0; burst = 5'd1; outstanding = 4'd1;
    base_node = 32'd0; total_recs = 32'(TOTAL);
    thr_period = 0; thr_cnt = 0; any_fail = 0;
    tb_mm = 0; tb_waves = 0; tb_cands = 0; tb_full = 0;
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    awid = 4'd0; awaddr = 28'd0; awlen = 8'd0; awsize = 3'd4; awburst = 2'b01;
    wdata = '0; wstrb = 16'hFFFF;
    $display("PRE_NOTE Evidence_class=SYNTH_AXI_PREFLIGHT — NOT gate evidence, NOT MIG");
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    repeat (10) @(posedge clk);
    preload();
    repeat (10) @(posedge clk);

    run_pattern(1, 1, 1, 0);
    run_pattern(2, 1, 8, 0);
    run_pattern(3, 1, 1, 8);
    run_pattern(4, 1, 8, 4);

    if (any_fail == 0) $display("A7NG_DDR_WAVEFRONT_PREFLIGHT_PASS");
    else               $display("A7NG_DDR_WAVEFRONT_PREFLIGHT_FAIL fails=%0d", any_fail);
    $finish;
  end

  initial begin
    #20ms;
    $display("PRE_TIMEOUT");
    $display("A7NG_DDR_WAVEFRONT_PREFLIGHT_FAIL");
    $finish;
  end
endmodule
