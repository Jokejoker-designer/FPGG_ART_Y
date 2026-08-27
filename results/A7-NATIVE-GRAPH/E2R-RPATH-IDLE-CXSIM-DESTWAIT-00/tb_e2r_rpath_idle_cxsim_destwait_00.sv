// E2R-RPATH-IDLE-CXSIM-DESTWAIT-00 — dest-wait half of C-XSIM leftover unknown
// Vehicle: a7ng_native_v1_ab_core SIM_FULL=0 (silicon SoC). AXI SOA stub + legal WDMA
// responder. Probe four r_path_idle AND terms at first DUT-driven TILE_DST==4.
// Do not force dst / TILE_DST. Do not assign r_path_idle. Do not apply C-FIX.
// Sealed complete-query bags are not this bag. XSim ≠ board.
`timescale 1ns/1ps

module tb_e2r_rpath_idle_cxsim_destwait_00;
  import a7ng_pkg::*;

  localparam int TOTAL = 64;
  localparam int N_PRE = 64;
  localparam int unsigned SOA_TO = 200000;
  localparam int unsigned DESTWAIT_TO = 250000;
  localparam int unsigned HB_EVERY = 2000;

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

  assign arid    = arid_f;
  assign araddr  = araddr_f;
  assign arlen   = arlen_f;
  assign arsize  = arsize_f;
  assign arburst = arburst_f;
  assign arvalid = arvalid_f;
  assign rready  = rready_f;

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
  logic r_path_idle;
  logic [2:0] tile_dst;
  logic [3:0] tile_bst;
  logic tile_miss, tile_req_s1, w_stall;
  logic wdma_owner, wdma_go, wdma_wr;
  logic [27:0] wdma_addr;
  logic [31:0] wdma_bytes;
  logic wdma_busy, wdma_done;
  logic wdma_w_valid, wdma_w_ready;
  logic [127:0] wdma_w_data;
  logic wdma_r_valid, wdma_r_ready;
  logic [127:0] wdma_r_data;
  logic wdma_owner_grant;

  assign cons_ready = 1'b1;

  a7ng_native_v1_ab_core #(.SIM_FULL(1'b0), .WAVE(16), .MAX_CANDS(TOTAL)) dut (
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
    .topk_batches_o(), .topk_valid_o(topk_valid),
    .topk_score_o(topk_score), .topk_id_o(topk_id),
    .gv_count_o(gv_count),
    .grant_graph_o(), .grant_lm_o(), .dual_owner_err_o(dual_err),
    .bind_busy_o(), .bind_done_o(bind_done),
    .ctx_we_o(ctx_we), .ctx_pack_o(ctx_pack), .start_fwd_o(start_fwd),
    .capture_valid_o(capture_valid),
    .ctx_we_beats_o(ctx_beats), .start_fwd_beats_o(st_beats),
    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred),
    .phase_o(phase), .final_accept_o(final_accept),
    .w_stall_o(w_stall),
    .dbg_tile_miss_o(tile_miss),
    .dbg_tile_bst_o(tile_bst),
    .dbg_tile_dst_o(tile_dst),
    .dbg_tile_req_s1_o(tile_req_s1),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(r_path_idle),
    .wdma_owner(wdma_owner), .wdma_go(wdma_go), .wdma_wr(wdma_wr),
    .wdma_addr(wdma_addr), .wdma_bytes(wdma_bytes),
    .wdma_busy(wdma_busy), .wdma_done(wdma_done),
    .wdma_w_valid(wdma_w_valid), .wdma_w_ready(wdma_w_ready), .wdma_w_data(wdma_w_data),
    .wdma_r_valid(wdma_r_valid), .wdma_r_ready(wdma_r_ready), .wdma_r_data(wdma_r_data)
  );

  // Hierarchical READ of SOA bridge AND terms (same style as INT/CDC). Not a force.
  wire        p_drain  = dut.u_soa.u_br.r_drain_hold;
  wire [2:0]  p_fifo   = dut.u_soa.u_br.fifo_cnt[2:0];
  wire [4:0]  p_tr     = dut.u_soa.u_br.tr_cnt[4:0];
  wire        p_rvalid = rvalid;

  // TB replica of SoC B1 grant law — metric only. Not a product C-FIX.
  always_ff @(posedge clk or negedge dut_rst_n) begin
    if (!dut_rst_n)
      wdma_owner_grant <= 1'b0;
    else if (!wdma_owner)
      wdma_owner_grant <= 1'b0;
    else if (r_path_idle)
      wdma_owner_grant <= 1'b1;
  end

  // Legal WDMA responder: go → busy, 8 R beats, then hold busy=1 done=0 (D_WAITDONE).
  logic [3:0] wdma_r_left;
  always_ff @(posedge clk or negedge dut_rst_n) begin
    if (!dut_rst_n) begin
      wdma_busy   <= 1'b0;
      wdma_done   <= 1'b0;
      wdma_r_valid <= 1'b0;
      wdma_r_data <= 128'd0;
      wdma_w_ready <= 1'b0;
      wdma_r_left <= 4'd0;
    end else begin
      wdma_done <= 1'b0;
      if (wdma_go && !wdma_busy) begin
        wdma_busy   <= 1'b1;
        wdma_r_left <= 4'd8;
        wdma_r_valid <= 1'b1;
        wdma_r_data <= 128'hA5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5;
      end else if (wdma_busy && (wdma_r_left != 4'd0) && wdma_r_valid && wdma_r_ready) begin
        if (wdma_r_left == 4'd1) begin
          wdma_r_left  <= 4'd0;
          wdma_r_valid <= 1'b0;
        end else
          wdma_r_left <= wdma_r_left - 4'd1;
      end
    end
  end

  bit destwait_seen;
  bit soa_done_seen;
  bit start_fwd_seen;
  bit wdma_go_seen;
  logic [2:0]  snap_dst;
  logic        snap_drain, snap_rvalid, snap_idle, snap_own, snap_grant;
  logic [2:0]  snap_fifo;
  logic [4:0]  snap_tr;
  logic [31:0] snap_cyc;
  integer      pf;

  always_ff @(posedge clk or negedge dut_rst_n) begin
    if (!dut_rst_n) begin
      destwait_seen  <= 1'b0;
      soa_done_seen  <= 1'b0;
      start_fwd_seen <= 1'b0;
      wdma_go_seen   <= 1'b0;
      snap_dst    <= 3'd0;
      snap_drain  <= 1'b0;
      snap_fifo   <= 3'd0;
      snap_rvalid <= 1'b0;
      snap_tr     <= 5'd0;
      snap_idle   <= 1'b0;
      snap_own    <= 1'b0;
      snap_grant  <= 1'b0;
      snap_cyc    <= 32'd0;
    end else begin
      if (done)
        soa_done_seen <= 1'b1;
      if (start_fwd)
        start_fwd_seen <= 1'b1;
      if (wdma_go)
        wdma_go_seen <= 1'b1;
      if (!destwait_seen && (tile_dst == 3'd4)) begin
        destwait_seen <= 1'b1;
        snap_dst    <= tile_dst;
        snap_drain  <= p_drain;
        snap_fifo   <= p_fifo;
        snap_rvalid <= p_rvalid;
        snap_tr     <= p_tr;
        snap_idle   <= r_path_idle;
        snap_own    <= wdma_owner;
        snap_grant  <= wdma_owner_grant;
        snap_cyc    <= snap_cyc;
      end else if (!destwait_seen)
        snap_cyc <= snap_cyc + 32'd1;
    end
  end

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = 32'hDDFE_0000 + nid;
    return {c32, c32};
  endfunction

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

  task automatic dump_row(input string phase_s);
    $display("PROBE t=%0t phase=%s dst=%0d drain=%0b fifo=%0d rvalid=%0b tr=%0d idle=%0b own=%0b grant=%0b go=%0b busy=%0b rready=%0b rleft=%0d miss=%0b reqs1=%0b bst=%0d stall=%0b soa_done=%0b run=%0b fwd=%0b core_busy=%0b phase=%0d gv=%0d",
      $time, phase_s, tile_dst, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle,
      wdma_owner, wdma_owner_grant, wdma_go, wdma_busy, wdma_r_ready, wdma_r_left,
      tile_miss, tile_req_s1, tile_bst, w_stall, done, running, start_fwd, core_busy,
      phase, gv_count);
    $fdisplay(pf, "%0t,%s,%0d,%0b,%0d,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0d,%0b,%0b,%0d",
      $time, phase_s, tile_dst, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle,
      wdma_owner, wdma_owner_grant, wdma_go, wdma_busy, wdma_r_left, done, core_busy, phase);
  endtask

  function automatic int unsigned popcount4(input logic [3:0] m);
    return m[0] + m[1] + m[2] + m[3];
  endfunction

  function automatic string wire_of(input logic [3:0] m);
    if (m == 4'b0001) return "r_drain_hold";
    if (m == 4'b0010) return "fifo_cnt";
    if (m == 4'b0100) return "m_axi_rvalid";
    if (m == 4'b1000) return "tr_cnt";
    return "AMBIGUOUS";
  endfunction

  initial begin
    int unsigned timeout;
    logic [3:0] mask_u;
    int unsigned n_hot;
    string verdict_class, wire_named;
    bit term_d, term_f, term_v, term_t;

    pf = $fopen("probe_table.csv", "w");
    if (pf == 0) begin
      $display("E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,phase,tile_dst,r_drain_hold,fifo_cnt,m_axi_rvalid,tr_cnt,r_path_idle,wdma_owner,wdma_owner_grant,wdma_go,wdma_busy,r_left,soa_done,core_busy,lm_phase");

    dut_rst_n = 1'b0;
    stub_rst_n = 1'b0;
    start = 1'b0;
    do_lm = 1'b1;
    poison = 1'b0;
    mem_we = 1'b0;
    mem_addr = 20'd0;
    mem_wdata = 8'sd0;
    burst = 5'd16;
    outstanding = 4'd8;
    base_node = 32'd0;
    total_recs = 32'(TOTAL);
    awvalid = 1'b0; wvalid = 1'b0; bready = 1'b0; wlast = 1'b0;
    awid = 0; awaddr = 0; awlen = 0; awsize = 3'd4; awburst = 2'b01;
    wdata = 0; wstrb = 16'hFFFF;

    $display("E2R-RPATH-IDLE-CXSIM-DESTWAIT-00 START");
    $display("VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 WDMA_RESPONDER=hold_busy");
    $display("PREREG_UNKNOWN: which AND term is 1 at first legal TILE_DST==4");
    $display("PREREG_H_CANDIDATE: m_axi_rvalid leftover holds idle=0");
    $display("PREREG_H_RIVAL: fifo_cnt/tr_cnt leftover or dest-wait idle=1 (NONE)");
    $display("PREREG_FALSIFIER: FAIL_NO_DESTWAIT or force dst or more than one term (SET)");
    $display("PREREG_UNIT: first dest-wait occupancy after one query start");
    $display("FORBIDDEN: force TILE_DST/dst; assign r_path_idle=1; C-FIX; board");

    preload_soa_planes(N_PRE);
    repeat (10) @(posedge clk);
    stub_rst_n = 1'b1;
    dut_rst_n = 1'b1;
    repeat (50) @(posedge clk);
    dump_row("RESET");

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
    dump_row("OWNER_READY");

    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    $display("SOA_QUERY_START t=%0t do_lm=%0b", $time, do_lm);

    timeout = 0;
    while (!destwait_seen && timeout < DESTWAIT_TO) begin
      @(posedge clk);
      timeout = timeout + 1;
      if (timeout == 1)
        dump_row("POST_START_1");
      if (done && !soa_done_seen)
        dump_row("SOA_DONE");
      if (start_fwd && !start_fwd_seen)
        dump_row("START_FWD");
      if (wdma_go && !wdma_go_seen)
        dump_row("WDMA_GO");
      if ((timeout % HB_EVERY) == 0)
        dump_row("HB");
    end

    if (destwait_seen) begin
      @(posedge clk);
      dump_row("FIRST_DESTWAIT");
    end else
      dump_row("LIMIT_NO_DESTWAIT");

    term_d = snap_drain;
    term_f = (snap_fifo != 3'd0);
    term_v = snap_rvalid;
    term_t = (snap_tr != 5'd0);
    mask_u = {term_t, term_v, term_f, term_d};
    n_hot = popcount4(mask_u);

    if (!destwait_seen) begin
      verdict_class = "FAIL_NO_DESTWAIT";
      wire_named = "NONE";
    end else if (n_hot == 0) begin
      verdict_class = "NONE";
      wire_named = "NONE";
    end else if (n_hot == 1) begin
      verdict_class = "ONE";
      wire_named = wire_of(mask_u);
    end else begin
      verdict_class = "SET";
      wire_named = wire_of(mask_u);
    end

    $display("REACHED_DESTWAIT=%0b FIRST_TILE_DST=%0d LIVE_TILE_DST=%0d",
      destwait_seen, snap_dst, tile_dst);
    $display("SNAP destwait_cyc=%0d drain=%0b fifo=%0d rvalid=%0b tr=%0d idle=%0b own=%0b grant=%0b",
      snap_cyc, snap_drain, snap_fifo, snap_rvalid, snap_tr, snap_idle, snap_own, snap_grant);
    $display("SOA_DONE_SEEN=%0b START_FWD_SEEN=%0b CORE_BUSY=%0b PHASE=%0d GV=%0d BEATS=%0d",
      soa_done_seen, start_fwd_seen, core_busy, phase, gv_count, axi_beats);
    $display("WDMA hold busy=%0b done=%0b rvalid=%0b rleft=%0d owner=%0b",
      wdma_busy, wdma_done, wdma_r_valid, wdma_r_left, wdma_owner);
    $display("AND_MASK drain,fifo,rvalid,tr = %0b%0b%0b%0b n_hot=%0d",
      term_d, term_f, term_v, term_t, n_hot);
    $display("WIRE_THAT_HOLDS_IDLE_0=%s", wire_named);
    $display("VERDICT_CLASS=%s", verdict_class);
    $display("C_FIX=NONE");
    $display("C_FIX_CONSTITUENT=NONE");
    $display("EXISTENCE=not_claimed");
    $display("BOARD_PASS=not_claimed");
    $fclose(pf);

    if (!destwait_seen) begin
      $display("XSIM=FAIL_NO_DESTWAIT");
      $display("E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_FAIL_NO_DESTWAIT dst=%0d bst=%0d miss=%0b reqs1=%0b go=%0b busy=%0b soa=%0b fwd=%0b",
        tile_dst, tile_bst, tile_miss, tile_req_s1, wdma_go, wdma_busy, soa_done_seen, start_fwd_seen);
      $finish;
    end

    $display("XSIM=PASS");
    $display("E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_XSIM_PASS verdict=%s wire=%s c_fix=NONE idle=%0b n_hot=%0d dst=%0d",
      verdict_class, wire_named, snap_idle, n_hot, snap_dst);
    $finish;
  end

  initial begin
    #200ms;
    $display("WALL_LIMIT");
    $display("XSIM=LIMIT");
    $display("E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_FAIL_NO_DESTWAIT reason=wall dst=%0d", tile_dst);
    $finish;
  end
endmodule
