// tb_a7ng_wavefront_smoke.sv — PRE-FLIGHT smoke check for a7ng_cue_wavefront (NOT gate evidence)
// Behavioural AXI slave, no MIG. Evidence class for ddr_wavefront_00 is MIG_XSIM only; this
// file exists purely to catch delivery-layer logic faults in seconds before the MIG run.
`timescale 1ns / 1ps

module tb_a7ng_wavefront_smoke;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int WAVE  = 16;
  localparam int N_PRE = 160;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [3:0]   awid, arid_w, arid_f, arid;
  logic [27:0]  awaddr, araddr_w, araddr_f, araddr;
  logic [7:0]   awlen, arlen_w, arlen_f, arlen;
  logic [2:0]   awsize, arsize_w, arsize_f, arsize;
  logic [1:0]   awburst, arburst_w, arburst_f, arburst;
  logic         awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic         arvalid_w, arvalid_f, arvalid, arready;
  logic         rvalid, rready_w, rready_f, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0]  wstrb;
  logic [3:0]   bid, rid;
  logic [1:0]   bresp, rresp;
  logic         feed_en;

  assign arid    = feed_en ? arid_f    : arid_w;
  assign araddr  = feed_en ? araddr_f  : araddr_w;
  assign arlen   = feed_en ? arlen_f   : arlen_w;
  assign arsize  = feed_en ? arsize_f  : arsize_w;
  assign arburst = feed_en ? arburst_f : arburst_w;
  assign arvalid = feed_en ? arvalid_f : arvalid_w;
  assign rready  = feed_en ? rready_f  : rready_w;

  // TB-local AXI slave. a7ng_axi_mem_model is single-beat-only (it repeats the first beat and
  // never asserts RLAST with a valid beat on ARLEN>0), which is fine for its own single-beat
  // NG-03 use but unusable for burst sweeps. That file is owned by other gates and is left
  // untouched; the real evidence run uses the Digilent AXI MIG, which is AXI-compliant.
  wf_smoke_axi_slave #(.DEPTH_WORDS(8192)) u_mem (
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
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready_f)
  );

  logic        start, cons_ready, done, running;
  logic [4:0]  burst;
  logic [3:0]  outstanding;
  logic [31:0] base_node, total_recs;
  logic [63:0] q_query, q_intent, q_relation, q_context, q_path;
  logic [31:0] cyc, waves, c_acc, c_del, c_que, c_inf, c_prn, c_err, wf_mm;
  logic [31:0] swaps, empty_st, full_st, cr_cyc, fill_cyc, fill_eps;
  logic [15:0] occ_f, occ_d;
  logic [31:0] axi_bytes, axi_bursts, axi_beats, axi_mm;
  logic [31:0] rresp_err, rlast_err, exp_rec, rcv_rec, rid_err, r_bp;
  logic [31:0] batches, closs, tkb, busyc, fpush, fovf;
  logic [7:0]  fcount;
  logic        wave_valid_w, topk_valid_w;
  logic [127:0] wave_rec_w [WAVE];
  logic [31:0] wave_base_w;
  score_t      topk_sc_w [8];
  node_id_t    topk_id_w [8];
  logic        dut_rst_n;

  assign dut_rst_n = rst_n & feed_en;

  a7ng_wavefront_mig_top #(.WAVE(WAVE), .MAX_OUT(8), .MAX_BURST(16)) dut (
    .clk(clk), .rst_n(dut_rst_n),
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

  int pat_sel, pcnt;
  always @(posedge clk) pcnt <= dut_rst_n ? pcnt + 1 : 0;
  always_comb begin
    case (pat_sel)
      1:       cons_ready = ((pcnt % 4) == 0);
      2:       cons_ready = ((pcnt % 32) < 8);
      default: cons_ready = 1'b1;
    endcase
  end

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
      @(posedge clk);
      awid <= 4'd0; awaddr <= addr; awlen <= 8'd0; awsize <= 3'd4; awburst <= 2'b01;
      awvalid <= 1'b1; wdata <= data; wstrb <= 16'hFFFF; wlast <= 1'b1;
      wvalid <= 1'b1; bready <= 1'b1;
      fork
        begin wait (awvalid && awready); @(posedge clk); awvalid <= 1'b0; end
        begin wait (wvalid && wready); @(posedge clk); wvalid <= 1'b0; wlast <= 1'b0; end
      join
      wait (bvalid && bready);
      @(posedge clk);
      bready <= 1'b0;
    end
  endtask

  int seen [0:255];
  int tb_mm, tb_seq, tb_del, run_base, sb_on, any_fail, run_fail;
  logic [31:0] want_id;

  always @(posedge clk) begin
    if (sb_on && wave_valid_w) begin
      for (int k = 0; k < WAVE; k++) begin
        want_id = wave_base_w + 32'(k);
        if (wave_rec_w[k] !== pack_node(want_id)) begin
          if (tb_mm < 4)
            $display("SMOKE_REC_ERR lane=%0d id=%0d got=%032x want=%032x",
                     k, want_id, wave_rec_w[k], pack_node(want_id));
          tb_mm = tb_mm + 1;
        end
        if ((int'(want_id) - run_base) >= 0 && (int'(want_id) - run_base) < 256)
          seen[int'(want_id) - run_base] = seen[int'(want_id) - run_base] + 1;
      end
      tb_del = tb_del + WAVE;
    end
  end

  task automatic run_query(input int idx, input int base, input int total,
                           input int b, input int o, input int pat);
    int timeout, exp_bursts;
    begin
      run_fail = 0;
      exp_bursts = (total + b - 1) / b;
      for (int k = 0; k < 256; k++) seen[k] = 0;
      tb_mm = 0; tb_seq = 0; tb_del = 0; run_base = base;
      @(posedge clk);
      pat_sel = pat; burst = 5'(b); outstanding = 4'(o);
      base_node = 32'(base); total_recs = 32'(total);
      q_query = 64'hA5A5_1234_0F0F_5678 + 64'(idx);
      q_intent = 64'h1111_2222_3333_4444 + 64'(idx);
      q_relation = 64'h9999_8888_7777_6666 + 64'(idx);
      q_context = 64'hFEDC_BA98_7654_3210 + 64'(idx);
      q_path = 64'h0F0F_F0F0_00FF_FF00 + 64'(idx);
      @(posedge clk);
      sb_on = 1; start = 1'b1;
      @(posedge clk);
      start = 1'b0;
      @(posedge clk);
      timeout = 0;
      while (!done && timeout < 100000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      repeat (40) @(posedge clk);
      sb_on = 0;
      if (!done) begin
        $display("SMOKE_FAIL Q%0d TIMEOUT del=%0d/%0d que=%0d inf=%0d", idx, c_del, total, c_que, c_inf);
        run_fail = 1;
      end else begin
        $display("SMOKE_ROW Q%0d total=%0d burst=%0d out=%0d pat=%0d bytes=%0d beats=%0d bursts=%0d(exp %0d) waves=%0d cyc=%0d",
                 idx, total, b, o, pat, axi_bytes, axi_beats, axi_bursts, exp_bursts, waves, cyc);
        $display("SMOKE_CONS Q%0d acc=%0d del=%0d que=%0d inf=%0d cerr=%0d mm=%0d aximm=%0d tbmm=%0d tbdel=%0d batches=%0d closs=%0d topk=%0d",
                 idx, c_acc, c_del, c_que, c_inf, c_err, wf_mm, axi_mm, tb_mm, tb_del, batches, closs, tkb);
        $display("SMOKE_PP Q%0d swaps=%0d empty=%0d full=%0d crdy=%0d fill=%0d feps=%0d rbp=%0d",
                 idx, swaps, empty_st, full_st, cr_cyc, fill_cyc, fill_eps, r_bp);
        if (axi_bytes != total*16 || axi_beats != total || axi_bursts != exp_bursts) run_fail = 1;
        if (c_acc != total || c_del != total || c_que != 0 || c_inf != 0 || c_err != 0) run_fail = 1;
        if (wf_mm != 0 || axi_mm != 0 || tb_mm != 0) run_fail = 1;
        if (batches != total/WAVE || closs != 0 || tkb != total/WAVE) run_fail = 1;
        if (tb_del != total) run_fail = 1;
        for (int k = 0; k < total; k++)
          if (seen[k] != 1) begin
            $display("SMOKE_FAIL Q%0d EXACTLY_ONCE off=%0d seen=%0d", idx, k, seen[k]);
            run_fail = 1;
          end
        if (run_fail != 0) $display("SMOKE_FAIL Q%0d checks", idx);
        else               $display("SMOKE_PASS Q%0d", idx);
      end
      any_fail = any_fail + run_fail;
      pat_sel = 0;
      repeat (16) @(posedge clk);
    end
  endtask

  initial begin
    feed_en = 0; start = 0; burst = 5'd1; outstanding = 4'd1;
    base_node = 0; total_recs = 64; pat_sel = 0; sb_on = 0;
    any_fail = 0; tb_mm = 0; tb_seq = 0; tb_del = 0; run_base = 0;
    q_query = 0; q_intent = 0; q_relation = 0; q_context = 0; q_path = 0;
    awvalid = 0; wvalid = 0; bready = 0; wlast = 0;
    arid_w = 0; araddr_w = 0; arlen_w = 0; arsize_w = 3'd4; arburst_w = 2'b01;
    arvalid_w = 0; rready_w = 0;
    awid = 0; awaddr = 0; awlen = 0; awsize = 3'd4; awburst = 2'b01;
    wdata = 0; wstrb = 16'hFFFF;
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (8) @(posedge clk);
    for (int k = 0; k < N_PRE; k++)
      axi_write_beat(a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'(k)), pack_node(32'(k)));
    $display("SMOKE_PRELOAD_DONE nodes=%0d", N_PRE);
    feed_en = 1'b1;
    repeat (20) @(posedge clk);

    run_query(0,   0, 64,  1, 1, 0);
    run_query(1,   0, 64,  4, 8, 0);
    run_query(2,   0, 64, 16, 8, 0);
    run_query(3,  64, 64,  4, 8, 0);
    run_query(4,  64, 64, 16, 8, 1);
    run_query(5, 128, 32,  8, 4, 2);

    if (any_fail == 0) $display("A7NG_WAVEFRONT_SMOKE_PASS");
    else               $display("A7NG_WAVEFRONT_SMOKE_FAIL fails=%0d", any_fail);
    $finish;
  end

  initial begin
    #5ms;
    $display("SMOKE_TIMEOUT");
    $display("A7NG_WAVEFRONT_SMOKE_FAIL");
    $finish;
  end
endmodule

// AXI4 read slave with multi-beat bursts and multiple outstanding ARs (smoke aid only).
module wf_smoke_axi_slave #(
  parameter int unsigned DEPTH_WORDS = 8192
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [3:0]   s_axi_awid,
  input  logic [27:0]  s_axi_awaddr,
  input  logic [7:0]   s_axi_awlen,
  input  logic [2:0]   s_axi_awsize,
  input  logic [1:0]   s_axi_awburst,
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,
  input  logic [127:0] s_axi_wdata,
  input  logic [15:0]  s_axi_wstrb,
  input  logic         s_axi_wlast,
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,
  output logic [3:0]   s_axi_bid,
  output logic [1:0]   s_axi_bresp,
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,
  input  logic [3:0]   s_axi_arid,
  input  logic [27:0]  s_axi_araddr,
  input  logic [7:0]   s_axi_arlen,
  input  logic [2:0]   s_axi_arsize,
  input  logic [1:0]   s_axi_arburst,
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,
  output logic [3:0]   s_axi_rid,
  output logic [127:0] s_axi_rdata,
  output logic [1:0]   s_axi_rresp,
  output logic         s_axi_rlast,
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready
);
  import a7ng_pkg::*;

  logic [127:0] mem [DEPTH_WORDS];

  function automatic int unsigned idx_of(input logic [27:0] a);
    logic [27:0] rel;
    rel = a - NG_DDR_NODE_BASE;
    return int'(rel[27:4]);
  endfunction

  initial begin
    for (int i = 0; i < int'(DEPTH_WORDS); i++)
      mem[i] = '0;
  end

  // ---- AR queue (up to 8 outstanding) ----
  localparam int unsigned QD = 8;
  logic [27:0] q_addr [QD];
  logic [7:0]  q_len  [QD];
  logic [3:0]  q_id   [QD];
  logic [3:0]  q_wr, q_rd, q_cnt;

  logic        streaming;
  logic [27:0] cur_a;
  logic [7:0]  cur_l;
  logic [3:0]  cur_id;

  assign s_axi_arready = (q_cnt < QD[3:0]);
  assign s_axi_rvalid  = streaming;
  assign s_axi_rdata   = (idx_of(cur_a) < DEPTH_WORDS) ? mem[idx_of(cur_a)] : '0;
  assign s_axi_rlast   = streaming && (cur_l == 8'd0);
  assign s_axi_rid     = cur_id;
  assign s_axi_rresp   = 2'b00;
  assign s_axi_bresp   = 2'b00;

  wire do_ar = s_axi_arvalid && s_axi_arready;
  wire do_r  = s_axi_rvalid  && s_axi_rready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q_wr <= '0; q_rd <= '0; q_cnt <= '0;
      streaming <= 1'b0; cur_a <= '0; cur_l <= '0; cur_id <= '0;
    end else begin
      automatic logic [3:0] wr, rd, cn;
      automatic logic       st;
      wr = q_wr; rd = q_rd; cn = q_cnt; st = streaming;

      if (st && do_r) begin
        if (cur_l == 8'd0) begin
          st = 1'b0;                 // burst complete; next AR picked up below
        end else begin
          cur_l <= cur_l - 8'd1;
          cur_a <= cur_a + 28'd16;
        end
      end

      // Pop before push: an AR pushed this cycle is still NBA-pending in q_addr, so it must
      // not be popped until the next cycle.
      if (!st && (cn != 4'd0)) begin
        cur_a  <= q_addr[rd[2:0]];
        cur_l  <= q_len[rd[2:0]];
        cur_id <= q_id[rd[2:0]];
        rd = rd + 4'd1;
        cn = cn - 4'd1;
        st = 1'b1;
      end

      if (do_ar) begin
        q_addr[wr[2:0]] <= s_axi_araddr;
        q_len[wr[2:0]]  <= s_axi_arlen;
        q_id[wr[2:0]]   <= s_axi_arid;
        wr = wr + 4'd1;
        cn = cn + 4'd1;
      end

      q_wr <= wr; q_rd <= rd; q_cnt <= cn;
      streaming <= st;
    end
  end

  // ---- simple write path (preload) ----
  typedef enum logic [1:0] {WIDLE, WDATA, WRESP} wst_e;
  wst_e wst;
  logic [27:0] aw_a;
  logic [3:0]  aw_id;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wst <= WIDLE;
      s_axi_awready <= 1'b1;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bid     <= '0;
      aw_a <= '0; aw_id <= '0;
    end else begin
      unique case (wst)
        WIDLE: begin
          s_axi_awready <= 1'b1;
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b0;
          if (s_axi_awvalid && s_axi_awready) begin
            aw_a  <= s_axi_awaddr;
            aw_id <= s_axi_awid;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b1;
            wst <= WDATA;
          end
        end
        WDATA: if (s_axi_wvalid && s_axi_wready) begin
          if (idx_of(aw_a) < DEPTH_WORDS)
            mem[idx_of(aw_a)] <= s_axi_wdata;
          if (s_axi_wlast) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b1;
            s_axi_bid    <= aw_id;
            wst <= WRESP;
          end else
            aw_a <= aw_a + 28'd16;
        end
        WRESP: if (s_axi_bvalid && s_axi_bready) begin
          s_axi_bvalid <= 1'b0;
          wst <= WIDLE;
        end
        default: wst <= WIDLE;
      endcase
    end
  end
endmodule
