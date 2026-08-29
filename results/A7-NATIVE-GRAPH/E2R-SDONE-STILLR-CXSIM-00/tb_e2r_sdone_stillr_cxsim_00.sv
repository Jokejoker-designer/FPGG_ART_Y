// E2R-SDONE-STILLR-CXSIM-00 — still-in-R at first dest=4, then complete
// Vehicle: copy of E2R-SDONE-CXSIM-00 ROSE (SIM_FULL=0 + CDC + B1 + mux
// + shared stub + s_dma_idle=1'b0). ROSE CONTROL SHA DF55ACF4… finished
// the first burst before dest=4 (snap w_st=0, sticky already 1).
// ONE TB CHANGE: do NOT pulse s_done / clear busy until AFTER first dest=4
// is latched (keep W_R + busy through that snap), THEN complete.
// Do NOT complete before dest=4 (ROSE / FALSIFIER).
// Do NOT hold busy forever after dest=4 (MUX / FALSIFIER).
// UNKNOWN: at first dest=4 while responder still in-R/busy (complete AFTER
// snap), is dbg_s_done_sticky 0 or 1?
// Do not force dst / TILE_DST. Do not assign r_path_idle. Do not apply C-FIX.
// Do not retie s_dma_idle. Do not instantiate soc_top or MIG. XSim ≠ board.
`timescale 1ns/1ps

module tb_e2r_sdone_stillr_cxsim_00;
  import a7ng_pkg::*;

  localparam realtime CORE_HALF = 40.0; // 80 ns → 12.5 MHz
  localparam realtime UI_HALF   = 5.0;  // 10 ns → 100 MHz
  localparam int TOTAL = 64;
  localparam int N_PRE = 64;
  localparam int unsigned DESTWAIT_TO = 250000;
  localparam int unsigned HB_EVERY = 2000;
  localparam int unsigned SETTLE_CYC = 128;
  localparam int unsigned DONE_WATCH_CYC = 8192;

  logic core_clk = 1'b0;
  logic ui_clk   = 1'b0;
  logic core_rst_n;
  logic ui_rst_n;
  always #(CORE_HALF) core_clk = ~core_clk;
  always #(UI_HALF)   ui_clk   = ~ui_clk;

  // Core-side AXI (DUT ↔ CDC master)
  logic [3:0]  c_arid, c_rid;
  logic [27:0] c_araddr;
  logic [7:0]  c_arlen;
  logic [2:0]  c_arsize;
  logic [1:0]  c_arburst, c_rresp;
  logic        c_arvalid, c_arready;
  logic [127:0] c_rdata;
  logic        c_rlast, c_rvalid, c_rready;

  // CDC slave toward mux
  logic [3:0]  cdc_arid, cdc_rid;
  logic [27:0] cdc_araddr;
  logic [7:0]  cdc_arlen;
  logic [2:0]  cdc_arsize;
  logic [1:0]  cdc_arburst, cdc_rresp;
  logic        cdc_arvalid, cdc_arready;
  logic [127:0] cdc_rdata;
  logic        cdc_rlast, cdc_rvalid, cdc_rready;
  logic        cdc_r_ne, cdc_ar_ne, cdc_ar_hold, cdc_ar_empty;

  // Shared stub / mux AXI (ui)
  logic [3:0]  arid, rid;
  logic [27:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst, rresp;
  logic        arvalid, arready;
  logic [127:0] rdata;
  logic        rlast, rvalid, rready;
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

  // WDMA AXI (d_*) — same stub R bus, not a private responder port
  logic [3:0]  d_arid;
  logic [27:0] d_araddr;
  logic [7:0]  d_arlen;
  logic [2:0]  d_arsize;
  logic [1:0]  d_arburst;
  logic        d_arvalid, d_rready;

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
  logic wdma_owner_ui;
  logic dma_go, dma_wr;
  logic [27:0] dma_addr;
  logic [31:0] dma_bytes;
  logic dma_w_valid, dma_w_ready;
  logic [127:0] dma_w_data;
  logic dma_r_valid, dma_r_ready;
  logic [127:0] dma_r_data;
  logic s_dma_busy, s_dma_done;
  logic dbg_s_done_sticky, dbg_m_done_sticky, dbg_busy_hold;
  logic dbg_s_go_sticky, dbg_m_go_sticky;
  logic dbg_sbusy_pend, dbg_cmd_empty_mgo, dbg_cmd_rd_sticky;
  logic [1:0] dbg_cmd_st;
  logic s_go_ever_s;
  logic s_done_ever_s;
  logic dest4_ui_m, dest4_seen_ui;

  assign cons_ready = 1'b1;

  a7ng_native_v1_ab_core #(.SIM_FULL(1'b0), .WAVE(16), .MAX_CANDS(TOTAL)) dut (
    .clk(core_clk), .rst_n(core_rst_n),
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
    .m_axi_arid(c_arid), .m_axi_araddr(c_araddr), .m_axi_arlen(c_arlen),
    .m_axi_arsize(c_arsize), .m_axi_arburst(c_arburst),
    .m_axi_arvalid(c_arvalid), .m_axi_arready(c_arready),
    .m_axi_rid(c_rid), .m_axi_rdata(c_rdata), .m_axi_rresp(c_rresp),
    .m_axi_rlast(c_rlast), .m_axi_rvalid(c_rvalid), .m_axi_rready(c_rready),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(r_path_idle),
    .wdma_owner(wdma_owner), .wdma_go(wdma_go), .wdma_wr(wdma_wr),
    .wdma_addr(wdma_addr), .wdma_bytes(wdma_bytes),
    .wdma_busy(wdma_busy), .wdma_done(wdma_done),
    .wdma_w_valid(wdma_w_valid), .wdma_w_ready(wdma_w_ready), .wdma_w_data(wdma_w_data),
    .wdma_r_valid(wdma_r_valid), .wdma_r_ready(wdma_r_ready), .wdma_r_data(wdma_r_data)
  );

  a7ng_axi_read_cdc u_axi_cdc (
    .m_clk(core_clk), .m_rst_n(core_rst_n),
    .m_axi_arid(c_arid), .m_axi_araddr(c_araddr), .m_axi_arlen(c_arlen),
    .m_axi_arsize(c_arsize), .m_axi_arburst(c_arburst),
    .m_axi_arvalid(c_arvalid), .m_axi_arready(c_arready),
    .m_axi_rid(c_rid), .m_axi_rdata(c_rdata), .m_axi_rresp(c_rresp),
    .m_axi_rlast(c_rlast), .m_axi_rvalid(c_rvalid), .m_axi_rready(c_rready),
    .s_clk(ui_clk), .s_rst_n(ui_rst_n),
    .s_axi_arid(cdc_arid), .s_axi_araddr(cdc_araddr), .s_axi_arlen(cdc_arlen),
    .s_axi_arsize(cdc_arsize), .s_axi_arburst(cdc_arburst),
    .s_axi_arvalid(cdc_arvalid), .s_axi_arready(cdc_arready),
    .s_axi_rid(cdc_rid), .s_axi_rdata(cdc_rdata), .s_axi_rresp(cdc_rresp),
    .s_axi_rlast(cdc_rlast), .s_axi_rvalid(cdc_rvalid), .s_axi_rready(cdc_rready),
    .dbg_r_ne_o(cdc_r_ne),
    .dbg_ar_ne_o(cdc_ar_ne),
    .dbg_ar_hold_o(cdc_ar_hold),
    .dbg_ar_empty_o(cdc_ar_empty)
  );

  // SoC mux copy (arty_a7_ng_native_v1_ab_soc_top.sv ~170–201). TB-only.
  // boot_active=0 (no soa_boot / wmem). Do not edit SoC.
  assign arvalid = wdma_owner_ui ? d_arvalid : cdc_arvalid;
  assign arid    = wdma_owner_ui ? d_arid    : cdc_arid;
  assign araddr  = wdma_owner_ui ? d_araddr  : cdc_araddr;
  assign arlen   = wdma_owner_ui ? d_arlen   : cdc_arlen;
  assign arsize  = wdma_owner_ui ? d_arsize  : cdc_arsize;
  assign arburst = wdma_owner_ui ? d_arburst : cdc_arburst;
  assign rready  = wdma_owner_ui ? d_rready  : cdc_rready;
  assign cdc_arready = !wdma_owner_ui && arready;
  assign cdc_rid     = rid;
  assign cdc_rdata   = rdata;
  assign cdc_rresp   = rresp;
  assign cdc_rlast   = rlast;
  assign cdc_rvalid  = rvalid; // UNGATED — the mux unknown

  a7ng_axi_soa_mem_stub u_mem (
    .clk(ui_clk), .rst_n(ui_rst_n),
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

  // Hierarchical READ of SOA bridge AND terms. Not a force.
  // m_axi_rvalid = c_rvalid (CDC master toward bridge), not stub rvalid.
  wire        p_drain  = dut.u_soa.u_br.r_drain_hold;
  wire [2:0]  p_fifo   = dut.u_soa.u_br.fifo_cnt[2:0];
  wire [4:0]  p_tr     = dut.u_soa.u_br.tr_cnt[4:0];
  wire        p_rvalid = c_rvalid;

  // TB replica of SoC B1 grant law — metric + mux grant source. Not a product C-FIX.
  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n)
      wdma_owner_grant <= 1'b0;
    else if (!wdma_owner)
      wdma_owner_grant <= 1'b0;
    else if (r_path_idle)
      wdma_owner_grant <= 1'b1;
  end

  a7ng_wdma_cdc u_wdma_cdc (
    .m_clk(core_clk), .m_rst_n(core_rst_n),
    .m_owner(wdma_owner_grant), .m_go(wdma_go), .m_wr(wdma_wr),
    .m_addr(wdma_addr), .m_bytes(wdma_bytes),
    .m_w_valid(wdma_w_valid), .m_w_ready(wdma_w_ready), .m_w_data(wdma_w_data),
    .m_r_valid(wdma_r_valid), .m_r_ready(wdma_r_ready), .m_r_data(wdma_r_data),
    .m_busy(wdma_busy), .m_done(wdma_done),
    .dbg_s_done_sticky(dbg_s_done_sticky), .dbg_m_done_sticky(dbg_m_done_sticky),
    .dbg_busy_hold(dbg_busy_hold), .dbg_s_go_sticky(dbg_s_go_sticky),
    .dbg_m_go_sticky(dbg_m_go_sticky),
    .dbg_sbusy_pend(dbg_sbusy_pend), .dbg_cmd_st(dbg_cmd_st),
    .dbg_cmd_empty_mgo(dbg_cmd_empty_mgo), .dbg_cmd_rd_sticky(dbg_cmd_rd_sticky),
    .s_clk(ui_clk), .s_rst_n(ui_rst_n),
    .s_owner(wdma_owner_ui),
    .s_go(dma_go), .s_wr(dma_wr), .s_addr(dma_addr), .s_bytes(dma_bytes),
    .s_w_valid(dma_w_valid), .s_w_ready(dma_w_ready), .s_w_data(dma_w_data),
    .s_r_valid(dma_r_valid), .s_r_ready(dma_r_ready), .s_r_data(dma_r_data),
    .s_busy(s_dma_busy), .s_done(s_dma_done),
    .m_tile_dst(tile_dst),
    .s_dma_idle(1'b0)
  );

  assign dma_w_ready = 1'b1;

  // Legal WDMA on the shared stub R bus: go → busy, 8 AXI R beats, then
  // KEEP W_R + busy until first dest=4 is latched, THEN pulse s_done and
  // clear s_busy. Completing before dest=4 is the ROSE FALSIFIER.
  // Holding forever after dest=4 is the MUX FALSIFIER.
  // Handshake matches ddr_tile_dma: r_valid=(st==R)&&rvalid; rready=(st==R)&&s_r_ready.
  typedef enum logic [2:0] {
    W_IDLE    = 3'd0,
    W_WAITOWN = 3'd1,
    W_AR      = 3'd2,
    W_R       = 3'd3,
    W_HOLD    = 3'd4
  } w_st_t;
  w_st_t       w_st;
  logic [3:0]  wdma_r_left;
  logic [27:0] w_araddr_r;

  assign dma_r_valid = (w_st == W_R) && (wdma_r_left != 4'd0) && rvalid && wdma_owner_ui;
  assign dma_r_data  = rdata;
  assign d_rready    = (w_st == W_R) && (wdma_r_left != 4'd0) && dma_r_ready;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      w_st        <= W_IDLE;
      s_dma_busy  <= 1'b0;
      s_dma_done  <= 1'b0;
      d_arid      <= 4'hD;
      d_araddr    <= 28'd0;
      d_arlen     <= 8'd7;
      d_arsize    <= 3'd4;
      d_arburst   <= 2'b01;
      d_arvalid   <= 1'b0;
      wdma_r_left <= 4'd0;
      w_araddr_r  <= 28'd0;
    end else begin
      s_dma_done <= 1'b0;
      unique case (w_st)
        W_IDLE: begin
          d_arvalid <= 1'b0;
          if (dma_go) begin
            s_dma_busy  <= 1'b1;
            wdma_r_left <= 4'd8;
            w_araddr_r  <= dma_addr;
            w_st        <= W_WAITOWN;
          end
        end
        W_WAITOWN: begin
          if (wdma_owner_ui) begin
            d_arid    <= 4'hD;
            d_araddr  <= w_araddr_r;
            d_arlen   <= 8'd7;
            d_arsize  <= 3'd4;
            d_arburst <= 2'b01;
            d_arvalid <= 1'b1;
            w_st      <= W_AR;
          end
        end
        W_AR: begin
          if (d_arvalid && arready && wdma_owner_ui) begin
            d_arvalid <= 1'b0;
            w_st      <= W_R;
          end else if (!wdma_owner_ui)
            d_arvalid <= 1'b0;
          else
            d_arvalid <= 1'b1;
        end
        W_R: begin
          d_arvalid <= 1'b0;
          if (rvalid && d_rready && wdma_owner_ui) begin
            if ((wdma_r_left == 4'd1) || rlast) begin
              wdma_r_left <= 4'd0;
              if (dest4_seen_ui)
                w_st <= W_HOLD;
            end else
              wdma_r_left <= wdma_r_left - 4'd1;
          end else if ((wdma_r_left == 4'd0) && dest4_seen_ui)
            w_st <= W_HOLD;
        end
        W_HOLD: begin
          d_arvalid  <= 1'b0;
          s_dma_busy <= 1'b0;
          s_dma_done <= 1'b1;
          w_st       <= W_IDLE;
        end
        default: w_st <= W_IDLE;
      endcase
    end
  end

  logic owner_ui_m, owner_ui_m2;
  logic stub_rv_m, stub_rv_m2;
  logic cdc_rv_m, cdc_rv_m2;
  logic sgo_st_m, sgo_st_m2;
  logic sgo_ever_m, sgo_ever_m2;
  logic sbusy_m, sbusy_m2;
  logic cmdrd_m, cmdrd_m2;
  logic cmdempty_m, cmdempty_m2;
  logic [1:0] cmdst_m, cmdst_m2;
  logic sdone_st_m, sdone_st_m2;
  logic sdone_ever_m, sdone_ever_m2;
  logic mdone_st_m, mdone_st_m2;
  logic sbusy_dma_m, sbusy_dma_m2;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      s_go_ever_s   <= 1'b0;
      s_done_ever_s <= 1'b0;
    end else begin
      if (dma_go)
        s_go_ever_s <= 1'b1;
      if (s_dma_done)
        s_done_ever_s <= 1'b1;
    end
  end

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      owner_ui_m  <= 1'b0;
      owner_ui_m2 <= 1'b0;
      stub_rv_m   <= 1'b0;
      stub_rv_m2  <= 1'b0;
      cdc_rv_m    <= 1'b0;
      cdc_rv_m2   <= 1'b0;
      sgo_st_m    <= 1'b0;
      sgo_st_m2   <= 1'b0;
      sgo_ever_m  <= 1'b0;
      sgo_ever_m2 <= 1'b0;
      sbusy_m     <= 1'b0;
      sbusy_m2    <= 1'b0;
      cmdrd_m     <= 1'b0;
      cmdrd_m2    <= 1'b0;
      cmdempty_m  <= 1'b0;
      cmdempty_m2 <= 1'b0;
      cmdst_m      <= 2'd0;
      cmdst_m2     <= 2'd0;
      sdone_st_m   <= 1'b0;
      sdone_st_m2  <= 1'b0;
      sdone_ever_m <= 1'b0;
      sdone_ever_m2<= 1'b0;
      mdone_st_m   <= 1'b0;
      mdone_st_m2  <= 1'b0;
      sbusy_dma_m  <= 1'b0;
      sbusy_dma_m2 <= 1'b0;
    end else begin
      owner_ui_m  <= wdma_owner_ui;
      owner_ui_m2 <= owner_ui_m;
      stub_rv_m   <= rvalid;
      stub_rv_m2  <= stub_rv_m;
      cdc_rv_m    <= cdc_rvalid;
      cdc_rv_m2   <= cdc_rv_m;
      sgo_st_m    <= dbg_s_go_sticky;
      sgo_st_m2   <= sgo_st_m;
      sgo_ever_m  <= s_go_ever_s;
      sgo_ever_m2 <= sgo_ever_m;
      sbusy_m     <= dbg_sbusy_pend;
      sbusy_m2    <= sbusy_m;
      cmdrd_m     <= dbg_cmd_rd_sticky;
      cmdrd_m2    <= cmdrd_m;
      cmdempty_m  <= dbg_cmd_empty_mgo;
      cmdempty_m2 <= cmdempty_m;
      cmdst_m     <= dbg_cmd_st;
      cmdst_m2    <= cmdst_m;
      sdone_st_m   <= dbg_s_done_sticky;
      sdone_st_m2  <= sdone_st_m;
      sdone_ever_m <= s_done_ever_s;
      sdone_ever_m2<= sdone_ever_m;
      mdone_st_m   <= dbg_m_done_sticky;
      mdone_st_m2  <= mdone_st_m;
      sbusy_dma_m  <= s_dma_busy;
      sbusy_dma_m2 <= sbusy_dma_m;
    end
  end

  bit destwait_seen;
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      dest4_ui_m    <= 1'b0;
      dest4_seen_ui <= 1'b0;
    end else begin
      dest4_ui_m    <= destwait_seen;
      dest4_seen_ui <= dest4_ui_m;
    end
  end
  bit soa_done_seen;
  bit start_fwd_seen;
  bit wdma_go_seen;
  bit grant_rose_latched;
  logic [2:0]  snap_dst;
  logic        snap_drain, snap_rvalid, snap_idle, snap_own, snap_grant;
  logic        snap_owner_ui, snap_cdc_rv, snap_stub_rv, snap_grant_rose;
  logic [2:0]  snap_fifo;
  logic [4:0]  snap_tr;
  logic [31:0] snap_cyc;
  logic        snap_sgo_st, snap_mgo_st, snap_sgo_ever, snap_sbusy, snap_cmdrd;
  logic        snap_cmdempty;
  logic [1:0]  snap_cmdst;
  logic        snap_sdone_st, snap_sdone_ever, snap_mdone_st, snap_sbusy_dma, snap_mbusy;
  logic [2:0]  snap_wst;
  logic        end_sgo_st, end_mgo_st, end_sgo_ever, end_sbusy, end_cmdrd;
  logic        end_idle, end_grant;
  logic [1:0]  end_cmdst;
  logic [2:0]  end_dst, end_fifo;
  logic        end_sdone_st, end_sdone_ever, end_mdone_st, end_sbusy_dma, end_mbusy;
  logic [2:0]  end_wst;
  integer      pf;

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      destwait_seen      <= 1'b0;
      soa_done_seen      <= 1'b0;
      start_fwd_seen     <= 1'b0;
      wdma_go_seen       <= 1'b0;
      grant_rose_latched <= 1'b0;
      snap_dst       <= 3'd0;
      snap_drain     <= 1'b0;
      snap_fifo      <= 3'd0;
      snap_rvalid    <= 1'b0;
      snap_tr        <= 5'd0;
      snap_idle      <= 1'b0;
      snap_own       <= 1'b0;
      snap_grant     <= 1'b0;
      snap_owner_ui  <= 1'b0;
      snap_cdc_rv    <= 1'b0;
      snap_stub_rv   <= 1'b0;
      snap_grant_rose<= 1'b0;
      snap_cyc       <= 32'd0;
      snap_sgo_st    <= 1'b0;
      snap_mgo_st    <= 1'b0;
      snap_sgo_ever  <= 1'b0;
      snap_sbusy     <= 1'b0;
      snap_cmdrd     <= 1'b0;
      snap_cmdempty  <= 1'b0;
      snap_cmdst     <= 2'd0;
      snap_sdone_st  <= 1'b0;
      snap_sdone_ever<= 1'b0;
      snap_mdone_st  <= 1'b0;
      snap_sbusy_dma <= 1'b0;
      snap_mbusy     <= 1'b0;
      snap_wst       <= 3'd0;
    end else begin
      if (wdma_owner_grant)
        grant_rose_latched <= 1'b1;
      if (done)
        soa_done_seen <= 1'b1;
      if (start_fwd)
        start_fwd_seen <= 1'b1;
      if (wdma_go)
        wdma_go_seen <= 1'b1;
      if (!destwait_seen && (tile_dst == 3'd4)) begin
        destwait_seen   <= 1'b1;
        snap_dst        <= tile_dst;
        snap_drain      <= p_drain;
        snap_fifo       <= p_fifo;
        snap_rvalid     <= p_rvalid;
        snap_tr         <= p_tr;
        snap_idle       <= r_path_idle;
        snap_own        <= wdma_owner;
        snap_grant      <= wdma_owner_grant;
        snap_owner_ui   <= owner_ui_m2;
        snap_cdc_rv     <= cdc_rv_m2;
        snap_stub_rv    <= stub_rv_m2;
        snap_grant_rose <= grant_rose_latched | wdma_owner_grant;
        snap_cyc        <= snap_cyc;
        snap_sgo_st     <= sgo_st_m2 | dbg_s_go_sticky;
        snap_mgo_st     <= dbg_m_go_sticky;
        snap_sgo_ever   <= sgo_ever_m2 | s_go_ever_s;
        snap_sbusy      <= sbusy_m2;
        snap_cmdrd      <= cmdrd_m2;
        snap_cmdempty   <= cmdempty_m2;
        snap_cmdst      <= cmdst_m2;
        snap_sdone_st   <= sdone_st_m2 | dbg_s_done_sticky;
        snap_sdone_ever <= sdone_ever_m2 | s_done_ever_s;
        snap_mdone_st   <= mdone_st_m2 | dbg_m_done_sticky;
        snap_sbusy_dma  <= sbusy_dma_m2 | s_dma_busy;
        snap_mbusy      <= wdma_busy;
        snap_wst        <= w_st;
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
    $display("PROBE t=%0t phase=%s dst=%0d drain=%0b fifo=%0d c_rvalid=%0b tr=%0d idle=%0b own=%0b grant=%0b own_ui=%0b cdc_rv=%0b stub_rv=%0b m_go=%0b s_go=%0b sgo_st=%0b mgo_st=%0b sgo_ever=%0b s_done=%0b sdone_st=%0b mdone_st=%0b sdone_ever=%0b cmd_st=%0d sbusy_pend=%0b s_busy=%0b m_busy=%0b cmd_rd=%0b cmd_empty_mgo=%0b rleft=%0d wst=%0d miss=%0b reqs1=%0b bst=%0d soa_done=%0b fwd=%0b core_busy=%0b phase=%0d gv=%0d",
      $time, phase_s, tile_dst, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle,
      wdma_owner, wdma_owner_grant, wdma_owner_ui, cdc_rvalid, rvalid,
      wdma_go, dma_go, dbg_s_go_sticky, dbg_m_go_sticky, s_go_ever_s,
      s_dma_done, dbg_s_done_sticky, dbg_m_done_sticky, s_done_ever_s,
      dbg_cmd_st, dbg_sbusy_pend, s_dma_busy, wdma_busy, dbg_cmd_rd_sticky, dbg_cmd_empty_mgo,
      wdma_r_left, w_st,
      tile_miss, tile_req_s1, tile_bst, done, start_fwd, core_busy,
      phase, gv_count);
    $fdisplay(pf, "%0t,%s,%0d,%0b,%0d,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0d,%0b,%0b,%0b,%0b,%0d,%0d",
      $time, phase_s, tile_dst, p_drain, p_fifo, p_rvalid, p_tr, r_path_idle,
      wdma_owner, wdma_owner_grant, wdma_owner_ui,
      wdma_go, dma_go, dbg_s_go_sticky, dbg_m_go_sticky, s_go_ever_s,
      s_dma_done, dbg_s_done_sticky, dbg_m_done_sticky, s_done_ever_s,
      dbg_cmd_st, dbg_sbusy_pend, s_dma_busy, wdma_busy,
      done, phase, w_st);
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
      $display("E2R_SDONE_STILLR_CXSIM_00_XSIM_FAIL reason=probe_fopen");
      $fatal(1);
    end
    $fdisplay(pf, "t_ns,phase,tile_dst,r_drain_hold,fifo_cnt,m_axi_rvalid,tr_cnt,r_path_idle,wdma_owner,wdma_owner_grant,wdma_owner_ui,m_go,s_go,sgo_sticky,mgo_sticky,sgo_ever,s_done,sdone_sticky,mdone_sticky,sdone_ever,cmd_st,sbusy_pend,s_busy,wdma_busy,soa_done,lm_phase,w_st");

    core_rst_n = 1'b0;
    ui_rst_n = 1'b0;
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

    $display("E2R-SDONE-STILLR-CXSIM-00 START");
    $display("VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA STILLR_THEN_COMPLETE s_dma_idle=0");
    $display("PREREG_UNKNOWN: at first dest=4 while responder still in-R/busy (complete AFTER snap), is dbg_s_done_sticky 0 or 1");
    $display("PREREG_H_CANDIDATE: SNAP_DONE0 sticky=0 at dest=4 while in-R");
    $display("PREREG_H_RIVAL: SNAP_DONE1 sticky=1 at dest=4 even while current burst in-R");
    $display("PREREG_FALSIFIER: complete before dest=4 (ROSE); hold forever (MUX); C-FIX; A2; LiteScope; soc_top+MIG; force dest");
    $display("PREREG_UNIT: one query; first dest=4 snap; after-complete sticky is secondary");
    $display("FORBIDDEN: complete before dest=4; hold busy forever; force TILE_DST/dst; assign r_path_idle=1; C-FIX; soc_top; MIG; board; retie s_dma_idle");

    preload_soa_planes(N_PRE);
    repeat (20) @(posedge ui_clk);
    ui_rst_n = 1'b1;
    repeat (20) @(posedge ui_clk);
    repeat (8) @(posedge core_clk);
    core_rst_n = 1'b1;
    repeat (50) @(posedge core_clk);
    dump_row("RESET");

    begin
      int ow;
      ow = 0;
      while (!owner_ready && ow < 500_000) begin
        @(posedge core_clk);
        ow = ow + 1;
      end
      if (owner_ready !== 1'b1)
        $display("SOA_OWNER_READY_TIMEOUT");
      else
        $display("SOA_OWNER_READY ok cycles=%0d", ow);
    end
    dump_row("OWNER_READY");

    @(negedge core_clk);
    start = 1'b1;
    @(negedge core_clk);
    start = 1'b0;
    $display("SOA_QUERY_START t=%0t do_lm=%0b", $time, do_lm);

    timeout = 0;
    while (!destwait_seen && timeout < DESTWAIT_TO) begin
      @(posedge core_clk);
      timeout = timeout + 1;
      if (timeout == 1)
        dump_row("POST_START_1");
      if (done && !soa_done_seen)
        dump_row("SOA_DONE");
      if (start_fwd && !start_fwd_seen)
        dump_row("START_FWD");
      if (wdma_go && !wdma_go_seen)
        dump_row("WDMA_GO");
      if (s_dma_done && !s_done_ever_s)
        dump_row("S_DONE_PULSE");
      if ((timeout % HB_EVERY) == 0)
        dump_row("HB");
    end

    if (destwait_seen) begin
      @(posedge core_clk);
      dump_row("FIRST_DESTWAIT");
      begin
        int unsigned si;
        for (si = 0; si < SETTLE_CYC; si++)
          @(posedge core_clk);
      end
      dump_row("END_SETTLE");
      begin
        int unsigned dw;
        dw = 0;
        while (!s_done_ever_s && !dbg_s_done_sticky && (dw < DONE_WATCH_CYC)) begin
          @(posedge core_clk);
          dw = dw + 1;
          if ((dw % HB_EVERY) == 0)
            dump_row("DONE_WATCH_HB");
        end
        if (s_done_ever_s || dbg_s_done_sticky)
          dump_row("DONE_WATCH_HIT");
        else
          dump_row("DONE_WATCH_MISS");
      end
      end_dst        = tile_dst;
      end_fifo       = p_fifo;
      end_idle       = r_path_idle;
      end_grant      = wdma_owner_grant;
      end_sgo_st     = sgo_st_m2 | dbg_s_go_sticky;
      end_mgo_st     = dbg_m_go_sticky;
      end_sgo_ever   = sgo_ever_m2 | s_go_ever_s;
      end_sbusy      = sbusy_m2;
      end_cmdrd      = cmdrd_m2;
      end_cmdst      = cmdst_m2;
      end_sdone_st   = sdone_st_m2 | dbg_s_done_sticky;
      end_sdone_ever = sdone_ever_m2 | s_done_ever_s;
      end_mdone_st   = mdone_st_m2 | dbg_m_done_sticky;
      end_sbusy_dma  = sbusy_dma_m2 | s_dma_busy;
      end_mbusy      = wdma_busy;
      end_wst        = w_st;
      dump_row("END_WATCH");
    end else begin
      end_dst        = tile_dst;
      end_fifo       = p_fifo;
      end_idle       = r_path_idle;
      end_grant      = wdma_owner_grant;
      end_sgo_st     = sgo_st_m2 | dbg_s_go_sticky;
      end_mgo_st     = dbg_m_go_sticky;
      end_sgo_ever   = sgo_ever_m2 | s_go_ever_s;
      end_sbusy      = sbusy_m2;
      end_cmdrd      = cmdrd_m2;
      end_cmdst      = cmdst_m2;
      end_sdone_st   = sdone_st_m2 | dbg_s_done_sticky;
      end_sdone_ever = sdone_ever_m2 | s_done_ever_s;
      end_mdone_st   = mdone_st_m2 | dbg_m_done_sticky;
      end_sbusy_dma  = sbusy_dma_m2 | s_dma_busy;
      end_mbusy      = wdma_busy;
      end_wst        = w_st;
      dump_row("LIMIT_NO_DESTWAIT");
    end

    term_d = snap_drain;
    term_f = (snap_fifo != 3'd0);
    term_v = snap_rvalid;
    term_t = (snap_tr != 5'd0);
    mask_u = {term_t, term_v, term_f, term_d};
    n_hot = popcount4(mask_u);

    if (!destwait_seen)
      verdict_class = "FAIL_NO_DESTWAIT";
    else if (!((snap_wst == W_R) && snap_sbusy_dma))
      verdict_class = "FAIL_NOT_IN_R";
    else if (snap_sdone_st)
      verdict_class = "SNAP_DONE1";
    else
      verdict_class = "SNAP_DONE0";

    wire_named = wire_of(mask_u);

    $display("REACHED_DESTWAIT=%0b FIRST_TILE_DST=%0d LIVE_TILE_DST=%0d",
      destwait_seen, snap_dst, tile_dst);
    $display("SNAP destwait_cyc=%0d drain=%0b fifo=%0d c_rvalid=%0b tr=%0d idle=%0b own=%0b grant=%0b own_ui=%0b cdc_rv=%0b stub_rv=%0b",
      snap_cyc, snap_drain, snap_fifo, snap_rvalid, snap_tr, snap_idle, snap_own, snap_grant,
      snap_owner_ui, snap_cdc_rv, snap_stub_rv);
    $display("SNAP_SGO sgo_st=%0b mgo_st=%0b sgo_ever=%0b cmd_st=%0d sbusy_pend=%0b cmd_rd=%0b cmd_empty_mgo=%0b",
      snap_sgo_st, snap_mgo_st, snap_sgo_ever, snap_cmdst, snap_sbusy, snap_cmdrd, snap_cmdempty);
    $display("SNAP_SDONE sdone_st=%0b mdone_st=%0b sdone_ever=%0b s_busy=%0b m_busy=%0b wst=%0d",
      snap_sdone_st, snap_mdone_st, snap_sdone_ever, snap_sbusy_dma, snap_mbusy, snap_wst);
    $display("END_SGO dst=%0d fifo=%0d idle=%0b grant=%0b sgo_st=%0b mgo_st=%0b sgo_ever=%0b cmd_st=%0d sbusy_pend=%0b cmd_rd=%0b",
      end_dst, end_fifo, end_idle, end_grant, end_sgo_st, end_mgo_st, end_sgo_ever, end_cmdst, end_sbusy, end_cmdrd);
    $display("END_SDONE sdone_st=%0b mdone_st=%0b sdone_ever=%0b s_busy=%0b m_busy=%0b wst=%0d",
      end_sdone_st, end_mdone_st, end_sdone_ever, end_sbusy_dma, end_mbusy, end_wst);
    $display("GRANT_ROSE_BEFORE_DESTWAIT=%0b", snap_grant_rose);
    $display("SOA_DONE_SEEN=%0b START_FWD_SEEN=%0b CORE_BUSY=%0b PHASE=%0d GV=%0d BEATS=%0d",
      soa_done_seen, start_fwd_seen, core_busy, phase, gv_count, axi_beats);
    $display("WDMA completable busy=%0b done=%0b rvalid=%0b rleft=%0d owner=%0b own_ui=%0b s_dma_idle=0 wst=%0d",
      wdma_busy, wdma_done, wdma_r_valid, wdma_r_left, wdma_owner, wdma_owner_ui, w_st);
    $display("AND_MASK drain,fifo,rvalid,tr = %0b%0b%0b%0b n_hot=%0d leftover_ctrl=%s",
      term_d, term_f, term_v, term_t, n_hot, wire_named);
    $display("SGO_STICKY_AT_DEST4=%0b", snap_sgo_st);
    $display("SGO_STICKY_END=%0b", end_sgo_st);
    $display("SGO_EVER=%0b", snap_sgo_ever | end_sgo_ever);
    $display("S_DONE_EVER=%0b", snap_sdone_ever | end_sdone_ever);
    $display("S_DONE_STICKY_AT_DEST4=%0b", snap_sdone_st);
    $display("S_DONE_STICKY_END=%0b", end_sdone_st);
    $display("M_DONE_STICKY=%0b", snap_mdone_st | end_mdone_st);
    $display("BUSY_AT_DEST4 s_busy=%0b m_busy=%0b", snap_sbusy_dma, snap_mbusy);
    $display("BUSY_AT_END s_busy=%0b m_busy=%0b", end_sbusy_dma, end_mbusy);
    $display("IN_R_AT_SNAP=%0b", destwait_seen && (snap_wst == W_R) && snap_sbusy_dma);
    $display("S_DONE_AFTER_COMPLETE=%0b", end_sdone_st | end_sdone_ever);
    $display("DEST4=%0b", destwait_seen && (snap_dst == 3'd4));
    $display("CLASS=%s", verdict_class);
    $display("C_FIX=NONE");
    $display("C_FIX_CONSTITUENT=NONE");
    $display("EXISTENCE=not_claimed");
    $display("BOARD_PASS=not_claimed");
    $fclose(pf);

    if (!destwait_seen) begin
      $display("XSIM=FAIL_NO_DESTWAIT");
      $display("E2R_SDONE_STILLR_CXSIM_00_FAIL_NO_DESTWAIT dst=%0d bst=%0d miss=%0b reqs1=%0b m_go=%0b s_go=%0b sgo_st=%0b sdone_st=%0b sdone_ever=%0b busy=%0b soa=%0b fwd=%0b grant=%0b",
        tile_dst, tile_bst, tile_miss, tile_req_s1, wdma_go, dma_go, dbg_s_go_sticky,
        dbg_s_done_sticky, s_done_ever_s, wdma_busy, soa_done_seen, start_fwd_seen, wdma_owner_grant);
      $finish;
    end

    if ((verdict_class == "SNAP_DONE0") || (verdict_class == "SNAP_DONE1")) begin
      $display("XSIM=PASS");
      $display("E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS class=%s c_fix=NONE dst=%0d grant=%0b idle=%0b fifo=%0d c_rvalid=%0b in_r=%0b sgo_ever=%0b sdone_st_dest4=%0b sdone_after_complete=%0b s_busy_dest4=%0b s_busy_end=%0b wst_snap=%0d",
        verdict_class, snap_dst, snap_grant, snap_idle, snap_fifo, snap_rvalid,
        (snap_wst == W_R) && snap_sbusy_dma, snap_sgo_ever | end_sgo_ever,
        snap_sdone_st, end_sdone_st | end_sdone_ever, snap_sbusy_dma, end_sbusy_dma, snap_wst);
    end else begin
      $display("XSIM=NO_PASS");
      $display("E2R_SDONE_STILLR_CXSIM_00_NO_PASS class=%s sdone_st_dest4=%0b sdone_after_complete=%0b in_r=%0b wst_snap=%0d s_busy=%0b sgo_ever=%0b",
        verdict_class, snap_sdone_st, end_sdone_st | end_sdone_ever,
        (snap_wst == W_R) && snap_sbusy_dma, snap_wst, snap_sbusy_dma,
        snap_sgo_ever | end_sgo_ever);
    end
    $finish;
  end

  initial begin
    #2000ms;
    $display("WALL_LIMIT");
    $display("XSIM=LIMIT");
    $display("E2R_SDONE_STILLR_CXSIM_00_FAIL_NO_DESTWAIT reason=wall dst=%0d sgo_st=%0b sdone_st=%0b",
      tile_dst, dbg_s_go_sticky, dbg_s_done_sticky);
    $finish;
  end
endmodule
