// arty_a7_ng_lm06_ua_soc_top.sv — lm06_ua_core: SoC + weight fabric + act u_a
// CONTROL weight-cut SoC D61BA6D4… retained (do not overwrite). New bit only.
// Does NOT overwrite frozen LM-06 / 01R / 02M / A0.3 release bits.
// ONE unknown: can frozen-law act_ram128k16 u_a fit with weight tiles WNS>=0?
// LIMIT retained: TinyGPT core / DSP path ABSENT (HS-22 full law still OPEN).
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module arty_a7_ng_lm06_ua_soc_top (
  input  logic        CLK100MHZ,
  input  logic [3:0]  sw,
  input  logic [3:0]  btn,
  output logic [3:0]  led,
  input  logic        uart_txd_in,
  output logic        uart_rxd_out,
  output logic [13:0] ddr3_addr,
  output logic [2:0]  ddr3_ba,
  output logic        ddr3_cas_n,
  output logic [0:0]  ddr3_ck_n,
  output logic [0:0]  ddr3_ck_p,
  output logic [0:0]  ddr3_cke,
  output logic [0:0]  ddr3_cs_n,
  output logic        ddr3_ras_n,
  output logic        ddr3_reset_n,
  output logic        ddr3_we_n,
  inout  logic [15:0] ddr3_dq,
  inout  logic [1:0]  ddr3_dqs_n,
  inout  logic [1:0]  ddr3_dqs_p,
  output logic [1:0]  ddr3_dm,
  output logic [0:0]  ddr3_odt
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;
  import a7lm06_pkg::*;

  logic clk166, clk200, clk_locked, btn0_166;
  logic ui_clk, ui_rst, calib, mig_mmcm;
  logic [23:0] mig_rst_hold;
  logic mig_rst_n;

  clk_arty_ddr u_clk (
    .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
  );
  sync_bits #(.WIDTH(1)) u_b0_166 (
    .clk(clk166), .rst_n(clk_locked), .async_in(btn[0]), .sync_out(btn0_166)
  );

  always_ff @(posedge clk166 or negedge clk_locked) begin
    if (!clk_locked) begin
      mig_rst_hold <= 24'hFF_FFFF;
      mig_rst_n <= 1'b0;
    end else if (btn0_166) begin
      mig_rst_hold <= 24'hFF_FFFF;
      mig_rst_n <= 1'b0;
    end else if (mig_rst_hold != 24'd0) begin
      mig_rst_hold <= mig_rst_hold - 24'd1;
      mig_rst_n <= 1'b0;
    end else
      mig_rst_n <= 1'b1;
  end

  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wlast, wvalid, wready, bvalid, bready;
  logic arvalid, arready, rlast, rvalid, rready;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  logic seed_active;
  logic [3:0]  s_arid; logic [27:0] s_araddr; logic [7:0] s_arlen;
  logic [2:0]  s_arsize; logic [1:0] s_arburst; logic s_arvalid, s_rready;
  logic [3:0]  w_awid; logic [27:0] w_awaddr; logic [7:0] w_awlen;
  logic [2:0]  w_awsize; logic [1:0] w_awburst; logic w_awvalid, w_wvalid, w_wlast, w_bready;
  logic [127:0] w_wdata; logic [15:0] w_wstrb;

  assign arid    = seed_active ? 4'd0 : s_arid;
  assign araddr  = seed_active ? 28'd0 : s_araddr;
  assign arlen   = seed_active ? 8'd0 : s_arlen;
  assign arsize  = seed_active ? 3'd4 : s_arsize;
  assign arburst = seed_active ? 2'b01 : s_arburst;
  assign arvalid = seed_active ? 1'b0 : s_arvalid;
  assign rready  = seed_active ? 1'b0 : s_rready;

  assign awid    = seed_active ? w_awid : 4'd0;
  assign awaddr  = seed_active ? w_awaddr : 28'd0;
  assign awlen   = seed_active ? w_awlen : 8'd0;
  assign awsize  = seed_active ? w_awsize : 3'd4;
  assign awburst = seed_active ? w_awburst : 2'b01;
  assign awvalid = seed_active ? w_awvalid : 1'b0;
  assign wdata   = seed_active ? w_wdata : 128'd0;
  assign wstrb   = seed_active ? w_wstrb : 16'h0;
  assign wlast   = seed_active ? w_wlast : 1'b0;
  assign wvalid  = seed_active ? w_wvalid : 1'b0;
  assign bready  = seed_active ? w_bready : 1'b1;

  mig_native_wrap u_mig (
    .sys_clk_i(clk166), .clk_ref_i(clk200), .sys_rst_n(mig_rst_n),
    .ui_clk(ui_clk), .ui_rst(ui_rst), .init_calib_complete(calib), .mmcm_locked(mig_mmcm),
    .ddr3_addr(ddr3_addr), .ddr3_ba(ddr3_ba), .ddr3_cas_n(ddr3_cas_n),
    .ddr3_ck_n(ddr3_ck_n), .ddr3_ck_p(ddr3_ck_p), .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n), .ddr3_ras_n(ddr3_ras_n), .ddr3_reset_n(ddr3_reset_n),
    .ddr3_we_n(ddr3_we_n), .ddr3_dq(ddr3_dq), .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p), .ddr3_dm(ddr3_dm), .ddr3_odt(ddr3_odt),
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

  logic ui_rst_n;
  assign ui_rst_n = ~ui_rst & calib;

  typedef enum logic [2:0] {SD_IDLE, SD_AW, SD_W, SD_B, SD_NEXT, SD_DONE} sd_t;
  sd_t sd;
  logic [7:0] seed_i;
  localparam logic [7:0] SEED_N = 8'd16;

  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n) begin
      sd <= SD_IDLE;
      seed_i <= 8'd0;
      seed_active <= 1'b1;
      w_awvalid <= 1'b0;
      w_wvalid <= 1'b0;
      w_wlast <= 1'b0;
      w_bready <= 1'b1;
      w_awid <= 4'd0;
      w_awlen <= 8'd0;
      w_awsize <= 3'd4;
      w_awburst <= 2'b01;
      w_wstrb <= 16'hFFFF;
      w_awaddr <= '0;
      w_wdata <= '0;
    end else begin
      unique case (sd)
        SD_IDLE: begin
          seed_active <= 1'b1;
          w_awaddr <= a7ng_node_byte_addr(NG_DDR_NODE_BASE, {24'd0, seed_i});
          w_wdata  <= {64'h0, 32'hA700_0000 + {24'd0, seed_i}, {24'd0, seed_i}};
          w_awvalid <= 1'b1;
          sd <= SD_AW;
        end
        SD_AW: if (w_awvalid && awready) begin
          w_awvalid <= 1'b0;
          w_wvalid <= 1'b1;
          w_wlast <= 1'b1;
          sd <= SD_W;
        end
        SD_W: if (w_wvalid && wready) begin
          w_wvalid <= 1'b0;
          w_wlast <= 1'b0;
          sd <= SD_B;
        end
        SD_B: if (bvalid) begin
          sd <= SD_NEXT;
        end
        SD_NEXT: begin
          if (seed_i == SEED_N - 8'd1) begin
            seed_active <= 1'b0;
            sd <= SD_DONE;
          end else begin
            seed_i <= seed_i + 8'd1;
            sd <= SD_IDLE;
          end
        end
        SD_DONE: seed_active <= 1'b0;
        default: sd <= SD_IDLE;
      endcase
    end
  end

  logic query, busy, done, hit;
  logic [31:0] nid, hits, misses, cands, bytes, bursts;
  logic [63:0] dout;
  logic [3:0] q_idx;
  typedef enum logic [1:0] {Q_WAIT, Q_ISSUE, Q_WAIT_DONE, Q_NEXT} q_t;
  q_t qs;
  logic smoke_pass;
  // smoke_done: sequence finished (pass OR fail) OR watchdog — NOT smoke_pass.
  // Board FAIL D2C6CF4B: mig_calib=1 but smoke metrics never passed → grant_lm never armed.
  logic smoke_done;
  logic [23:0] smoke_watch;

  a7ng_shard_fetch u_fetch (
    .clk(ui_clk), .rst_n(ui_rst_n && (sd == SD_DONE)),
    .query_i(query), .node_id_i(nid),
    .busy_o(busy), .done_o(done), .hit_o(hit), .data_o(dout),
    .hits_o(hits), .misses_o(misses),
    .candidates_o(cands), .ddr_read_bytes_o(bytes), .ddr_bursts_o(bursts),
    .m_axi_arid(s_arid), .m_axi_araddr(s_araddr), .m_axi_arlen(s_arlen),
    .m_axi_arsize(s_arsize), .m_axi_arburst(s_arburst),
    .m_axi_arvalid(s_arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(s_rready)
  );

  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n || sd != SD_DONE) begin
      qs <= Q_WAIT;
      query <= 1'b0;
      q_idx <= 4'd0;
      nid <= 32'd0;
      smoke_pass <= 1'b0;
      smoke_done <= 1'b0;
      smoke_watch <= 24'd0;
    end else begin
      query <= 1'b0;
      unique case (qs)
        Q_WAIT: if (!smoke_done) qs <= Q_ISSUE;
        Q_ISSUE: begin
          unique case (q_idx)
            4'd0: nid <= 32'd7;
            4'd1: nid <= 32'd7;
            default: nid <= 32'd9;
          endcase
          query <= 1'b1;
          qs <= Q_WAIT_DONE;
        end
        Q_WAIT_DONE: if (done) qs <= Q_NEXT;
        Q_NEXT: begin
          if (q_idx == 4'd2) begin
            smoke_pass <= (bytes == 32'd32) && (cands == 32'd3) && (hits >= 32'd1);
            smoke_done <= 1'b1;
            qs <= Q_WAIT;
            q_idx <= 4'd3;
          end else if (q_idx < 4'd3) begin
            q_idx <= q_idx + 4'd1;
            qs <= Q_ISSUE;
          end
        end
        default: qs <= Q_WAIT;
      endcase
      // Watchdog: if DDR smoke hangs (no done), still hand fabric to LM for wt∧act sticky.
      if (!smoke_done) begin
        if (smoke_watch == 24'hFFFFFF)
          smoke_done <= 1'b1;
        else
          smoke_watch <= smoke_watch + 24'd1;
      end
    end
  end

  // ---- LM / graph exclusive arbitration ----
  // UNKNOWN fix: LM grant must NOT depend on DDR smoke_pass OR seed SD_DONE.
  // Prior FAIL: smoke never passed → grant_lm never → sticky never; seed hang would
  // also hold smoke FSM in reset (sd != SD_DONE). Graph smoke remains best-effort.
  logic req_graph, req_lm, grant_graph, grant_lm;
  logic owner_g, owner_l, dual_err;
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      req_graph <= 1'b0;
      req_lm    <= 1'b0;
    end else begin
      req_graph <= 1'b0;
      req_lm    <= 1'b1;
    end
  end
  a7ng_lm_graph_arb u_arb (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .req_graph_i(req_graph), .req_lm_i(req_lm),
    .grant_graph_o(grant_graph), .grant_lm_o(grant_lm),
    .owner_is_graph_o(owner_g), .owner_is_lm_o(owner_l),
    .dual_owner_err_o(dual_err)
  );

  // ---- 16 PE scorer kept in fabric ----
  logic [NG_LANES-1:0] lv, lv_o;
  node_id_t cid [NG_LANES];
  score_terms_t terms [NG_LANES];
  score_t scores [NG_LANES];
  node_id_t cid_o [NG_LANES];
  logic [7:0] tick;
  logic [15:0] score_or;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) tick <= 8'd0;
    else tick <= tick + 8'd1;
  end
  assign lv = (tick[3:0] == 4'd0) ? {NG_LANES{1'b1}} : '0;

  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_drv
      always_ff @(posedge ui_clk or negedge ui_rst_n) begin
        if (!ui_rst_n) begin
          cid[gi] <= '0;
          terms[gi] <= '0;
        end else begin
          cid[gi] <= node_id_t'(gi + tick);
          terms[gi].entity_match <= term_t'(8'd10);
          terms[gi].intent_match <= term_t'(8'd5);
          terms[gi].relation_match <= term_t'(sw);
          terms[gi].context_match <= term_t'(8'd1);
          terms[gi].path_confidence <= term_t'(dout[7:0]);
          terms[gi].learned_prior <= term_t'(8'd0);
          terms[gi].contradiction_penalty <= term_t'(8'd0);
        end
      end
    end
  endgenerate

  (* DONT_TOUCH = "true", keep_hierarchy = "yes" *)
  a7ng_scorer_array u_sc (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .valid_i(lv), .cand_id_i(cid), .terms_i(terms),
    .valid_o(lv_o), .cand_id_o(cid_o), .score_o(scores)
  );

  always_comb begin
    score_or = 16'd0;
    for (int i = 0; i < NG_LANES; i++) score_or = score_or | scores[i];
  end

  // ---- LM-06 weight fabric (frozen law modules; NEW SoC bit only) ----
  logic signed [7:0] wt_ra, wt_rb, wt_wd;
  logic wt_we, wt_stall, wt_dirty, wt_dma_owner;
  logic [2:0] wt_cached;
  logic [19:0] wt_addr_a, wt_addr_b;
  logic wt_seen, act_seen, lm_path_sticky;
  logic compose_busy, tok_v, compose_done, compose_active;
  logic [7:0] tok;
  logic lm_path_active;

  // Act scratch (frozen-law act_ram128k16) — named u_a in hierarchy
  logic        act_we;
  logic [16:0] act_addr_a, act_addr_b;
  logic signed [15:0] act_wd, act_ra, act_rb;
  logic [7:0]  act_keep;
  // Fixed-addr write→read sticky (not tick-coupled expect). Holds addr across latency.
  typedef enum logic [1:0] {EV_WR, EV_WAIT, EV_RD, EV_HOLD} ev_t;
  ev_t ev_st;
  localparam logic [19:0] EV_WT_ADDR = 20'd32;
  localparam logic [16:0] EV_ACT_ADDR = 17'd32;
  localparam logic signed [7:0]  EV_WT_PAT  = 8'shA5;
  localparam logic signed [15:0] EV_ACT_PAT = 16'sh5A5A;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      wt_we     <= 1'b0;
      wt_addr_a <= EV_WT_ADDR;
      wt_addr_b <= EV_WT_ADDR ^ 20'd1;
      wt_wd     <= EV_WT_PAT;
      wt_seen   <= 1'b0;
      act_we    <= 1'b0;
      act_addr_a <= EV_ACT_ADDR;
      act_addr_b <= EV_ACT_ADDR ^ 17'd1;
      act_wd    <= EV_ACT_PAT;
      act_seen  <= 1'b0;
      act_keep  <= 8'd0;
      lm_path_sticky <= 1'b0;
      ev_st <= EV_WR;
    end else if (grant_lm) begin
      wt_addr_b <= EV_WT_ADDR ^ 20'd1;
      act_addr_b <= EV_ACT_ADDR ^ 17'd1;
      act_keep <= act_ra[7:0] ^ act_rb[7:0] ^ wt_ra[7:0];
      unique case (ev_st)
        EV_WR: begin
          wt_we     <= 1'b1;
          wt_addr_a <= EV_WT_ADDR;
          wt_wd     <= EV_WT_PAT;
          act_we    <= 1'b1;
          act_addr_a <= EV_ACT_ADDR;
          act_wd    <= EV_ACT_PAT;
          ev_st <= EV_WAIT;
        end
        EV_WAIT: begin
          // Keep addr stable; drop WE so registered BRAM presents written data next beat
          wt_we  <= 1'b0;
          act_we <= 1'b0;
          wt_addr_a <= EV_WT_ADDR;
          act_addr_a <= EV_ACT_ADDR;
          ev_st <= EV_RD;
        end
        EV_RD: begin
          wt_we  <= 1'b0;
          act_we <= 1'b0;
          wt_addr_a <= EV_WT_ADDR;
          act_addr_a <= EV_ACT_ADDR;
          if (wt_ra == EV_WT_PAT)
            wt_seen <= 1'b1;
          if (act_ra == EV_ACT_PAT)
            act_seen <= 1'b1;
          ev_st <= EV_HOLD;
        end
        EV_HOLD: begin
          wt_we  <= 1'b0;
          act_we <= 1'b0;
          // Retry if first pass missed (startup / tile idle settle)
          if (wt_seen && act_seen)
            lm_path_sticky <= 1'b1;
          else
            ev_st <= EV_WR;
        end
        default: ev_st <= EV_WR;
      endcase
    end else begin
      wt_we  <= 1'b0;
      act_we <= 1'b0;
    end
  end

  (* keep_hierarchy = "yes", DONT_TOUCH = "true" *)
  act_ram128k16 u_a (
    .clk(ui_clk),
    .we_a(act_we && grant_lm),
    .addr_a(act_addr_a),
    .wdata_a(act_wd),
    .rdata_a(act_ra),
    .addr_b(act_addr_b),
    .rdata_b(act_rb)
  );

  (* keep_hierarchy = "yes", DONT_TOUCH = "true" *)
  weight_tile803k #(.SIM_FULL(1'b0)) u_lm06_wtile (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .clk_dma(ui_clk), .rst_dma_n(ui_rst_n),
    .we_a(wt_we && grant_lm), .addr_a(wt_addr_a), .wdata_a(wt_wd),
    .rdata_a(wt_ra), .addr_b(wt_addr_b), .rdata_b(wt_rb),
    .stall(wt_stall), .cached_rg(wt_cached), .dirty(wt_dirty),
    .dma_owner(wt_dma_owner),
    .dma_go(), .dma_wr(), .dma_addr(), .dma_bytes(),
    .dma_busy(1'b0), .dma_done(1'b0),
    .dma_w_valid(), .dma_w_ready(1'b0), .dma_w_data(),
    .dma_r_valid(1'b0), .dma_r_ready(), .dma_r_data(128'd0),
    .dbg_bst(), .dbg_dst(), .dbg_cur_rg(), .dbg_miss(), .dbg_dirty(), .dbg_req()
  );

  logic        pp_wr_en, pp_wr_bank, pp_rd_bank;
  logic [7:0]  pp_wr_k, pp_rd_k;
  logic [2:0]  pp_wr_chunk;
  logic [127:0] pp_wr_data;
  logic [1023:0] pp_rd_data;
  logic [7:0] pp_keep;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      pp_wr_en <= 1'b0;
      pp_wr_bank <= 1'b0;
      pp_rd_bank <= 1'b0;
      pp_wr_k <= 8'd0;
      pp_rd_k <= 8'd0;
      pp_wr_chunk <= 3'd0;
      pp_wr_data <= 128'd0;
      pp_keep <= 8'd0;
    end else if (grant_lm) begin
      pp_wr_en <= tick[1];
      pp_wr_bank <= tick[2];
      pp_rd_bank <= tick[3];
      pp_wr_k <= tick;
      pp_rd_k <= tick;
      pp_wr_chunk <= tick[2:0];
      pp_wr_data <= {16{tick}};
      pp_keep <= pp_rd_data[7:0] ^ pp_rd_data[15:8] ^ wt_rb[7:0];
    end else begin
      pp_wr_en <= 1'b0;
      pp_keep <= 8'd0;
    end
  end

  (* keep_hierarchy = "yes", DONT_TOUCH = "true" *)
  tile_weight_pingpong u_lm06_wpp (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .wr_en(pp_wr_en), .wr_bank(pp_wr_bank), .wr_k(pp_wr_k),
    .wr_chunk(pp_wr_chunk), .wr_data(pp_wr_data),
    .rd_bank(pp_rd_bank), .rd_k(pp_rd_k), .rd_data(pp_rd_data)
  );

  // Evidence compose on LM grant (not gated on DDR smoke_pass)
  a7ng_evidence_compose u_compose (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .start_i(grant_lm && (tick[5:0] == 6'd0)),
    .evid_id0_i(cid_o[0]), .evid_id1_i(cid_o[1]), .evid_id2_i(cid_o[2]),
    .entity_i(8'h41 ^ act_keep), .intent_i(8'h49 ^ pp_keep ^ act_keep),
    .busy_o(compose_busy), .tok_valid_o(tok_v), .tok_o(tok),
    .done_o(compose_done), .lm_path_active_o(compose_active)
  );

  // Observable lm_path ≠ 0 only after weight+act BRAM readback (not hardwired 1)
  assign lm_path_active = lm_path_sticky | (compose_active & lm_path_sticky);

  // ---- UART exam stub on 100 MHz ----
  logic exam_mode;
  logic [7:0] last_cmd, status_byte;
  logic pe_alive_100, calib_100, lm_path_100;
  logic [3:0] pe_nib_100;
  sync_bits #(.WIDTH(7)) u_uart_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({score_or[3:0], lm_path_active, calib, |lv_o}),
    .sync_out({pe_nib_100, lm_path_100, calib_100, pe_alive_100})
  );
  a7ng_exam_uart_stub #(.CLK_HZ(100_000_000), .BAUD(115200)) u_exam (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .uart_rx(uart_txd_in), .uart_tx(uart_rxd_out),
    .pe_alive_i(pe_alive_100), .mig_calib_i(calib_100), .lm_path_i(lm_path_100),
    .pe_nibble_i(pe_nib_100),
    .exam_mode_o(exam_mode), .last_cmd_o(last_cmd), .status_byte_o(status_byte)
  );

  logic calib_s, seed_s, pass_s, pe_s;
  sync_bits #(.WIDTH(4)) u_led (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({|score_or ^ dual_err ^ wt_stall ^ |pp_keep ^ |act_keep ^ act_seen,
               smoke_pass, (sd == SD_DONE), calib}),
    .sync_out({pe_s, pass_s, seed_s, calib_s})
  );
  assign led = {pe_s, pass_s, seed_s, calib_s} ^ {exam_mode, status_byte[2:0]}
               ^ {lm_path_100, wt_cached};
endmodule
