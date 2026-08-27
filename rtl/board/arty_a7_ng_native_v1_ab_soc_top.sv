// arty_a7_ng_native_v1_ab_soc_top.sv — E2 existence board (Native V1 A+B + MIG)
// Does NOT overwrite frozen LM/EAM bits. Narrow existence gate only.
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module arty_a7_ng_native_v1_ab_soc_top (
  input  logic        CLK100MHZ,
  input  logic [3:0]  sw,
  input  logic [3:0]  btn,
  output logic [3:0]  led,
  input  logic        uart_txd_in,
  output logic        uart_rxd_out,
  // Arty QSPI flash (T2-SPI wmem loader)
  output logic        qspi_cs_n,
  output logic        qspi_sck,
  output logic        qspi_mosi,
  input  logic        qspi_miso,
  output logic        qspi_dq2,
  output logic        qspi_dq3,
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

  localparam int TOTAL = 64;

  logic clk166, clk200, clk_locked, btn0_166, core_clk, core_pll_locked, core_rst_n;
  logic ui_clk, ui_rst, calib, mig_mmcm;
  logic [23:0] mig_rst_hold;
  logic mig_rst_n;
  logic ui_rst_n;
  logic calib_core, boot_done_core, wmem_done_core;
  logic boot_busy, boot_done, wmem_busy, wmem_done, wmem_start;
  logic [31:0] wmem_bytes_wr;
  logic soa_phase, wmem_phase;
  logic [3:0]  w_awid; logic [27:0] w_awaddr; logic [7:0] w_awlen;
  logic [2:0]  w_awsize; logic [1:0] w_awburst; logic w_awvalid, w_wvalid, w_wlast, w_bready;
  logic [127:0] w_wdata; logic [15:0] w_wstrb;

  clk_arty_ddr u_clk (
    .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
  );
  clk_core_12p5 u_core_pll (
    .clk100(CLK100MHZ), .rst(btn[0]), .clk_core(core_clk), .locked(core_pll_locked)
  );
  sync_bits #(.WIDTH(3)) u_boot_core_sync (
    .clk(core_clk), .rst_n(core_pll_locked),
    .async_in({wmem_done, boot_done, calib}),
    .sync_out({wmem_done_core, boot_done_core, calib_core})
  );
  // Boot firewall: core_start = mig_calib && wmem_load_done && soa_load_done
  assign core_rst_n = core_pll_locked && calib_core && boot_done_core && wmem_done_core;
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
    end else mig_rst_n <= 1'b1;
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

  logic boot_active, core_hold, boot_start;
  logic wdma_owner, wdma_owner_grant, wdma_owner_ui, wdma_go, wdma_wr, wdma_w_valid, wdma_w_ready, wdma_r_valid, wdma_r_ready;
  logic [27:0] wdma_addr;
  logic [31:0] wdma_bytes;
  logic [127:0] wdma_w_data, wdma_r_data;
  logic wdma_busy, wdma_done;
  logic wdma_dbg_sdone, wdma_dbg_mdone, wdma_dbg_busy_hold; // F1t
  logic wdma_dbg_sgo; // F1u: sticky s_go from CDC
  logic wdma_dbg_mgo; // F1v: sticky m_go from CDC
  logic wdma_dbg_sbusy_pend, wdma_dbg_cmd_empty_mgo, wdma_dbg_cmd_rd; // F1B2
  logic [1:0] wdma_dbg_cmd_st; // F1B2
  logic [2:0] wdma_dbg_st; // F1u: ddr_tile_dma FSM state
  logic [2:0] dbg_tile_dst; // dest FSM (wired to CDC BFIX-00; driven by u_ab)
  logic dma_go, dma_wr, s_dma_busy, s_dma_done, dma_w_ready, dma_r_valid;
  logic [27:0] dma_addr;
  logic [31:0] dma_bytes;
  logic [127:0] dma_w_data, dma_r_data;
  logic dma_w_valid, dma_r_ready;
  logic [3:0]  b_awid; logic [27:0] b_awaddr; logic [7:0] b_awlen;
  logic [2:0]  b_awsize; logic [1:0] b_awburst; logic b_awvalid, b_wvalid, b_wlast, b_bready;
  logic [127:0] b_wdata; logic [15:0] b_wstrb;
  logic [3:0]  c_arid; logic [27:0] c_araddr; logic [7:0] c_arlen;
  logic [2:0]  c_arsize; logic [1:0] c_arburst; logic c_arvalid, c_arready;
  logic [3:0]  c_rid; logic [127:0] c_rdata; logic [1:0] c_rresp;
  logic        c_rlast, c_rvalid, c_rready;

  logic [3:0]  d_awid, d_arid;
  logic [27:0] d_awaddr, d_araddr;
  logic [7:0]  d_awlen, d_arlen;
  logic [2:0]  d_awsize, d_arsize;
  logic [1:0]  d_awburst, d_arburst;
  logic        d_awvalid, d_wvalid, d_wlast, d_bready, d_arvalid, d_rready;
  logic [127:0] d_wdata;
  logic [15:0] d_wstrb;
  logic dma_under, axi_berr, axi_rerr;

  // B1 E2R-B1-RPATH-00: registered WDMA ownership toward MIG AR/R mux.
  // Grant only while query/CDC R-path is idle; release when LM drops owner.
  // Prevents reverse dual-drive (CDC AR outstanding → WDMA steals rready).
  a7ng_wdma_cdc u_wdma_cdc (
    .m_clk(core_clk), .m_rst_n(core_rst_n),
    .m_owner(wdma_owner_grant), .m_go(wdma_go), .m_wr(wdma_wr),
    .m_addr(wdma_addr), .m_bytes(wdma_bytes),
    .m_w_valid(wdma_w_valid), .m_w_ready(wdma_w_ready), .m_w_data(wdma_w_data),
    .m_r_valid(wdma_r_valid), .m_r_ready(wdma_r_ready), .m_r_data(wdma_r_data),
    .m_busy(wdma_busy), .m_done(wdma_done),
    .dbg_s_done_sticky(wdma_dbg_sdone), .dbg_m_done_sticky(wdma_dbg_mdone),
    .dbg_busy_hold(wdma_dbg_busy_hold), .dbg_s_go_sticky(wdma_dbg_sgo),
    .dbg_m_go_sticky(wdma_dbg_mgo),
    .dbg_sbusy_pend(wdma_dbg_sbusy_pend), .dbg_cmd_st(wdma_dbg_cmd_st),
    .dbg_cmd_empty_mgo(wdma_dbg_cmd_empty_mgo), .dbg_cmd_rd_sticky(wdma_dbg_cmd_rd),
    .s_clk(ui_clk), .s_rst_n(ui_rst_n),
    .s_owner(wdma_owner_ui),
    .s_go(dma_go), .s_wr(dma_wr), .s_addr(dma_addr), .s_bytes(dma_bytes),
    .s_w_valid(dma_w_valid), .s_w_ready(dma_w_ready), .s_w_data(dma_w_data),
    .s_r_valid(dma_r_valid), .s_r_ready(dma_r_ready), .s_r_data(dma_r_data),
    .s_busy(s_dma_busy), .s_done(s_dma_done),
    .m_tile_dst(dbg_tile_dst),
    .s_dma_idle(wdma_dbg_st == 3'd0)
  );

  logic [3:0]  cdc_arid;
  logic [27:0] cdc_araddr;
  logic [7:0]  cdc_arlen;
  logic [2:0]  cdc_arsize;
  logic [1:0]  cdc_arburst;
  logic        cdc_arvalid, cdc_arready;
  logic [3:0]  cdc_rid;
  logic [127:0] cdc_rdata;
  logic [1:0]  cdc_rresp;
  logic        cdc_rlast, cdc_rvalid;
  logic        cdc_rready;
  logic        cdc_r_ne; // D3: CDC R FIFO not empty / beat toward core
  logic        cdc_ar_ne; // E3: CDC AR FIFO / hold toward mux
  logic        cdc_ar_hold;
  logic        cdc_ar_empty; // F1j: registered AR FIFO empty (s_clk)

  assign arvalid = boot_active ? 1'b0 : (wdma_owner_ui ? d_arvalid : cdc_arvalid);
  assign arid    = boot_active ? 4'd0 : (wdma_owner_ui ? d_arid : cdc_arid);
  assign araddr  = boot_active ? 28'd0 : (wdma_owner_ui ? d_araddr : cdc_araddr);
  assign arlen   = boot_active ? 8'd0 : (wdma_owner_ui ? d_arlen : cdc_arlen);
  assign arsize  = boot_active ? 3'd4 : (wdma_owner_ui ? d_arsize : cdc_arsize);
  assign arburst = boot_active ? 2'b01 : (wdma_owner_ui ? d_arburst : cdc_arburst);
  assign rready  = boot_active ? 1'b1 : (wdma_owner_ui ? d_rready : cdc_rready);

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
  assign cdc_arready = !boot_active && !wdma_owner_ui && arready;
  assign cdc_rid     = rid;
  assign cdc_rdata   = rdata;
  assign cdc_rresp   = rresp;
  assign cdc_rlast   = rlast;
  assign cdc_rvalid  = rvalid;

  assign awid    = soa_phase ? b_awid : (wmem_phase ? w_awid : d_awid);
  assign awaddr  = soa_phase ? b_awaddr : (wmem_phase ? w_awaddr : d_awaddr);
  assign awlen   = soa_phase ? b_awlen : (wmem_phase ? w_awlen : d_awlen);
  assign awsize  = soa_phase ? b_awsize : (wmem_phase ? w_awsize : d_awsize);
  assign awburst = soa_phase ? b_awburst : (wmem_phase ? w_awburst : d_awburst);
  assign awvalid = soa_phase ? b_awvalid : (wmem_phase ? w_awvalid : (wdma_owner_ui ? d_awvalid : 1'b0));
  assign wdata   = soa_phase ? b_wdata : (wmem_phase ? w_wdata : d_wdata);
  assign wstrb   = soa_phase ? b_wstrb : (wmem_phase ? w_wstrb : d_wstrb);
  assign wlast   = soa_phase ? b_wlast : (wmem_phase ? w_wlast : d_wlast);
  assign wvalid  = soa_phase ? b_wvalid : (wmem_phase ? w_wvalid : (wdma_owner_ui ? d_wvalid : 1'b0));
  assign bready  = soa_phase ? b_bready : (wmem_phase ? w_bready : d_bready);
  assign boot_active = soa_phase | wmem_phase;

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

  assign ui_rst_n = ~ui_rst & calib;

  ddr_tile_dma u_wdma (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .go(dma_go), .wr(dma_wr), .addr(dma_addr), .bytes(dma_bytes),
    .busy(s_dma_busy), .done(s_dma_done), .underflow(dma_under),
    .axi_berr(axi_berr), .axi_rerr(axi_rerr),
    .w_valid(dma_w_valid), .w_ready(dma_w_ready), .w_data(dma_w_data),
    .r_valid(dma_r_valid), .r_ready(dma_r_ready), .r_data(dma_r_data),
    .m_axi_awid(d_awid), .m_axi_awaddr(d_awaddr), .m_axi_awlen(d_awlen),
    .m_axi_awsize(d_awsize), .m_axi_awburst(d_awburst),
    .m_axi_awvalid(d_awvalid), .m_axi_awready(awready),
    .m_axi_wdata(d_wdata), .m_axi_wstrb(d_wstrb), .m_axi_wlast(d_wlast),
    .m_axi_wvalid(d_wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(d_bready),
    .m_axi_arid(d_arid), .m_axi_araddr(d_araddr), .m_axi_arlen(d_arlen),
    .m_axi_arsize(d_arsize), .m_axi_arburst(d_arburst),
    .m_axi_arvalid(d_arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(d_rready),
    .dbg_st(wdma_dbg_st)
  );

  a7ng_ddr_soa_boot u_boot (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .start_i(boot_start),
    .busy_o(boot_busy), .done_o(boot_done),
    .m_axi_awid(b_awid), .m_axi_awaddr(b_awaddr), .m_axi_awlen(b_awlen),
    .m_axi_awsize(b_awsize), .m_axi_awburst(b_awburst),
    .m_axi_awvalid(b_awvalid), .m_axi_awready(awready),
    .m_axi_wdata(b_wdata), .m_axi_wstrb(b_wstrb), .m_axi_wlast(b_wlast),
    .m_axi_wvalid(b_wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(b_bready)
  );

  a7ng_ddr_wmem_boot u_wmem_boot (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .start_i(wmem_start),
    .busy_o(wmem_busy), .done_o(wmem_done), .bytes_written_o(wmem_bytes_wr),
    .qspi_cs_n(qspi_cs_n), .qspi_sck(qspi_sck), .qspi_mosi(qspi_mosi),
    .qspi_miso(qspi_miso), .qspi_dq2(qspi_dq2), .qspi_dq3(qspi_dq3),
    .m_axi_awid(w_awid), .m_axi_awaddr(w_awaddr), .m_axi_awlen(w_awlen),
    .m_axi_awsize(w_awsize), .m_axi_awburst(w_awburst),
    .m_axi_awvalid(w_awvalid), .m_axi_awready(awready),
    .m_axi_wdata(w_wdata), .m_axi_wstrb(w_wstrb), .m_axi_wlast(w_wlast),
    .m_axi_wvalid(w_wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(w_bready)
  );

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      soa_phase <= 1'b0;
      wmem_phase <= 1'b1;
    end else begin
      // Order: MIG calib → WMEM → SOA → CORE (matches Gate 3 telemetry)
      if (wmem_done && !boot_done) begin
        wmem_phase <= 1'b0;
        soa_phase <= 1'b1;
      end
      if (boot_done)
        soa_phase <= 1'b0;
    end
  end

  // boot_active driven by assign (soa_phase | wmem_phase)

  logic start_q, do_lm, cons_ready;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node, total_recs;
  logic soa_done, soa_running, owner_ready, r_path_idle, bind_done, final_accept;
  logic core_busy, dual_err;
  logic topk_valid, ctx_we, start_fwd;
  logic [31:0] axi_bytes, axi_beats, axi_bursts, st_beats;
  logic [9:0] pred;
  logic [7:0] phase;
  logic [31:0] fpga_nt_valid;
  logic lm06_active;
  // Sticky post-CORE stage bits (core domain) — DUT events only, no host poke.
  // D1 mid-query: SOA_RUN / AR_BEAT / R_BEAT / R_BUSY / R_IDLE before SOA_Q.
  // D3 R-path probe: RV_SEEN / RREADY1 / RID_OK / RID_BAD / OUTST (+ MIG_RV / CDC_NE).
  // E1 MIG-AR probe: MIG_AR / OWN_WDMA / CDC_AR / MUX_CDC (ui sticky after Q_GO).
  // E3 CDC-AR probe: CDC_M_ARF / CDC_S_ARV / CDC_S_ARR / CDC_S_ARF / CDC_HOLD.
  // F1g: M_RST_LO / S_RST_LO (post-Q_GO rst glitch sticky in CLK100MHZ).
  logic sticky_owner, sticky_qgo, sticky_soarun, sticky_ar, sticky_rbeat;
  logic sticky_rbusy, sticky_ridle, sticky_soaq, sticky_topk;
  logic sticky_accept, sticky_pack, sticky_bind, sticky_fwd, sticky_lm;
  logic sticky_bind_busy, sticky_pred_nz, sticky_core_done; // F1l probe
  logic sticky_wdma_busy, sticky_wdma_done, sticky_core_busy; // F1m probe
  logic w_stall; // F1n from tiny_gpt803k via ab_core
  logic sticky_w_stall; // F1n probe
  logic [7:0] latched_phase; // F1n: phase while core_busy
  logic dbg_tile_miss; // F1o from tiny_gpt803k via ab_core
  logic [3:0] dbg_tile_bst;
  logic sticky_tile_miss; // F1o probe
  logic [2:0] latched_tile_dst; // F1o: dma dst while core_busy
  logic [3:0] latched_tile_bst; // F1p: bank bst while core_busy
  logic latched_tile_req; // F1q: req_s[1] while core_busy
  logic latched_tile_dma_busy, latched_tile_dma_own; // F1q: dma gate signals
  logic latched_s_dma_busy, latched_wdma_owner_ui; // F1r: ui-domain dma busy/owner
  logic latched_wdma_busy_f1r; // F1r: core wdma_busy at core_busy
  logic latched_sdone_f1t, latched_mdone_f1t, latched_busy_hold_f1t; // F1t: CDC done probes
  logic [2:0] latched_dma_st_f1u; // F1u: ddr_tile_dma FSM latched at core_busy
  logic latched_sgo_f1u; // F1u: sticky s_go latched at core_busy
  logic latched_wdma_own_f1v, latched_wdma_grant_f1v, latched_rpath_idle_f1v, latched_mgo_f1v; // F1v
  logic dbg_tile_req_s1; // F1q from tiny_gpt803k via ab_core
  logic sticky_rvseen, sticky_rready1, sticky_rid_ok, sticky_rid_bad, sticky_outst;
  logic sticky_cdc_ne;
  logic sticky_cdc_marf; // core: c_arvalid∧c_arready after Q_GO
  logic bind_busy, core_done;
  logic [3:0] last_arid;
  logic [4:0] ar_outst_cnt;
  node_id_t poison_id [8];

  assign cons_ready = 1'b1;
  assign do_lm = 1'b1;

  genvar gi;
  generate
    for (gi = 0; gi < 8; gi++) begin : g_pz
      assign poison_id[gi] = 32'd255;
    end
  endgenerate


  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      boot_start <= 1'b0;
      wmem_start <= 1'b0;
    end else begin
      // WMEM first after calib
      if (calib && !wmem_done && !wmem_busy)
        wmem_start <= 1'b1;
      else if (wmem_busy)
        wmem_start <= 1'b0;

      // SOA after WMEM
      if (wmem_done && !boot_done && !boot_busy)
        boot_start <= 1'b1;
      else if (boot_busy)
        boot_start <= 1'b0;
    end
  end

  typedef enum logic [2:0] {QS_IDLE, QS_WAIT_OWN, QS_START, QS_WAIT_SOA, QS_HOLD, QS_WAIT_BIND, QS_DONE} qs_t;
  qs_t qs;

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      qs <= QS_IDLE;
      start_q <= 1'b0;
      core_hold <= 1'b0;
      burst <= 5'd16;
      outstanding <= 4'd4;
      base_node <= 32'd0;
      total_recs <= 32'(TOTAL);
      fpga_nt_valid <= 32'd0;
      sticky_owner  <= 1'b0;
      sticky_qgo    <= 1'b0;
      sticky_soarun <= 1'b0;
      sticky_ar     <= 1'b0;
      sticky_rbeat  <= 1'b0;
      sticky_rbusy  <= 1'b0;
      sticky_ridle  <= 1'b0;
      sticky_soaq   <= 1'b0;
      sticky_topk   <= 1'b0;
      sticky_accept <= 1'b0;
      sticky_pack   <= 1'b0;
      sticky_bind   <= 1'b0;
      sticky_fwd    <= 1'b0;
      sticky_lm     <= 1'b0;
      sticky_bind_busy <= 1'b0;
      sticky_pred_nz   <= 1'b0;
      sticky_core_done <= 1'b0;
      sticky_wdma_busy <= 1'b0;
      sticky_wdma_done <= 1'b0;
      sticky_core_busy <= 1'b0;
      sticky_w_stall   <= 1'b0;
      latched_phase    <= 8'd0;
      sticky_tile_miss <= 1'b0;
      latched_tile_dst <= 3'd0;
      latched_tile_bst <= 4'd0;
      latched_tile_req <= 1'b0;
      latched_tile_dma_busy <= 1'b0;
      latched_tile_dma_own <= 1'b0;
      latched_s_dma_busy <= 1'b0;
      latched_wdma_owner_ui <= 1'b0;
      latched_wdma_busy_f1r <= 1'b0;
      latched_sdone_f1t <= 1'b0;
      latched_mdone_f1t <= 1'b0;
      latched_busy_hold_f1t <= 1'b0;
      latched_dma_st_f1u <= 3'd0;
      latched_sgo_f1u <= 1'b0;
      latched_wdma_own_f1v <= 1'b0;
      latched_wdma_grant_f1v <= 1'b0;
      latched_rpath_idle_f1v <= 1'b0;
      latched_mgo_f1v <= 1'b0;
      sticky_rvseen <= 1'b0;
      sticky_rready1<= 1'b0;
      sticky_rid_ok <= 1'b0;
      sticky_rid_bad<= 1'b0;
      sticky_outst  <= 1'b0;
      sticky_cdc_ne <= 1'b0;
      sticky_cdc_marf <= 1'b0;
      last_arid     <= 4'd0;
      ar_outst_cnt  <= 5'd0;
    end else begin
      start_q <= 1'b0;
      unique case (qs)
        QS_IDLE: if (boot_done_core) qs <= QS_WAIT_OWN;
        QS_WAIT_OWN: begin
          if (owner_ready) qs <= QS_START;
        end
        QS_START: begin
          start_q <= 1'b1;
          qs <= QS_WAIT_SOA;
        end
        QS_WAIT_SOA: if (soa_done) begin
          core_hold <= 1'b1;
          qs <= QS_HOLD;
        end
        QS_HOLD: if (final_accept) qs <= QS_WAIT_BIND;
        QS_WAIT_BIND: begin
          if (bind_done) begin
            fpga_nt_valid <= 32'd1;
            qs <= QS_DONE;
          end
        end
        QS_DONE: qs <= QS_DONE;
        default: qs <= QS_IDLE;
      endcase
      if (pred != 10'd0 && bind_done)
        fpga_nt_valid <= fpga_nt_valid + 32'd1;

      // A+ heartbeats: sticky DUT status between CORE_START and PRED
      if (owner_ready) sticky_owner <= 1'b1;
      if (start_q || (qs == QS_WAIT_SOA) || (qs == QS_HOLD) ||
          (qs == QS_WAIT_BIND) || (qs == QS_DONE))
        sticky_qgo <= 1'b1;
      // D1: mid-query SOA/AXI sticky (after Q_GO only — real DUT bits)
      if (sticky_qgo && soa_running) sticky_soarun <= 1'b1;
      if (sticky_qgo && c_arvalid && c_arready) sticky_ar <= 1'b1;
      if (sticky_qgo && c_arvalid && c_arready) sticky_cdc_marf <= 1'b1;
      if (sticky_qgo && c_rvalid && c_rready) sticky_rbeat <= 1'b1;
      if (sticky_qgo && !r_path_idle) sticky_rbusy <= 1'b1;
      if (sticky_qgo && r_path_idle) sticky_ridle <= 1'b1;
      // D3: finer R-path sticky (real DUT bits; no B1 re-patch)
      if (sticky_qgo && c_rvalid) sticky_rvseen <= 1'b1;
      if (sticky_qgo && sticky_ar && c_rready) sticky_rready1 <= 1'b1;
      if (sticky_qgo && c_arvalid && c_arready) last_arid <= c_arid;
      if (sticky_qgo && c_rvalid) begin
        if (c_rid == last_arid) sticky_rid_ok <= 1'b1;
        else sticky_rid_bad <= 1'b1;
      end
      // Local outstanding AR count (core AR/RLAST handshakes)
      if (sticky_qgo && c_arvalid && c_arready &&
          !(c_rvalid && c_rready && c_rlast)) begin
        if (ar_outst_cnt != 5'd31) ar_outst_cnt <= ar_outst_cnt + 5'd1;
      end else if (sticky_qgo && c_rvalid && c_rready && c_rlast &&
                   !(c_arvalid && c_arready)) begin
        if (ar_outst_cnt != 5'd0) ar_outst_cnt <= ar_outst_cnt - 5'd1;
      end
      if (sticky_ar && (ar_outst_cnt != 5'd0)) sticky_outst <= 1'b1;
      if (sticky_qgo && cdc_r_ne) sticky_cdc_ne <= 1'b1;
      if (soa_done && sticky_qgo) sticky_soaq <= 1'b1;
      if (topk_valid) sticky_topk <= 1'b1;
      if (final_accept) sticky_accept <= 1'b1;
      if (ctx_we) sticky_pack <= 1'b1;
      if (bind_done) sticky_bind <= 1'b1;
      if (start_fwd || (st_beats != 32'd0)) sticky_fwd <= 1'b1;
      if (bind_done || core_busy || (st_beats != 32'd0)) sticky_lm <= 1'b1;
      // F1l: bind/pred/core_done probes (after Q_GO; no CDC/core functional change)
      if (sticky_qgo && bind_busy) sticky_bind_busy <= 1'b1;
      if (sticky_qgo && (pred != 10'd0)) sticky_pred_nz <= 1'b1;
      if (sticky_qgo && core_done) sticky_core_done <= 1'b1;
      // F1m: WDMA/core_busy probes (after Q_GO / FWD preference; sticky+UART only)
      if (sticky_qgo && (sticky_fwd || start_fwd) && wdma_busy) sticky_wdma_busy <= 1'b1;
      if (sticky_qgo && (sticky_fwd || start_fwd) && wdma_done) sticky_wdma_done <= 1'b1;
      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) sticky_core_busy <= 1'b1;
      // F1n: W_STALL sticky + latched phase (after Q_GO/FWD; sticky+UART only)
      if (sticky_qgo && (sticky_fwd || start_fwd) && w_stall) sticky_w_stall <= 1'b1;
      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) latched_phase <= phase;
      // F1o: TILE_MISS sticky + latched dst (after CORE_BUSY; sticky+UART only)
      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy && dbg_tile_miss)
        sticky_tile_miss <= 1'b1;
      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) begin
        latched_tile_dst <= dbg_tile_dst;
        latched_tile_bst <= dbg_tile_bst;
        latched_tile_req <= dbg_tile_req_s1;
        latched_tile_dma_busy <= wdma_busy;
        latched_tile_dma_own <= wdma_owner;
        latched_wdma_busy_f1r <= wdma_busy;
        latched_mdone_f1t <= wdma_dbg_mdone;
        latched_busy_hold_f1t <= wdma_dbg_busy_hold;
        latched_wdma_own_f1v <= wdma_owner;
        latched_wdma_grant_f1v <= wdma_owner_grant;
        latched_rpath_idle_f1v <= r_path_idle;
        latched_mgo_f1v <= wdma_dbg_mgo;
      end
    end
  end

  assign lm06_active = bind_done | core_busy | (st_beats != 32'd0);

  a7ng_native_v1_ab_core #(
    .SIM_FULL(1'b0),
    .WAVE(16),
    .MAX_CANDS(TOTAL)
  ) u_ab (
    .clk(core_clk), .rst_n(core_rst_n),
    .clk_dma(core_clk), .rst_dma_n(core_rst_n),
    .wdma_owner(wdma_owner), .wdma_go(wdma_go), .wdma_wr(wdma_wr),
    .wdma_addr(wdma_addr), .wdma_bytes(wdma_bytes),
    .wdma_busy(wdma_busy), .wdma_done(wdma_done),
    .wdma_w_valid(wdma_w_valid), .wdma_w_ready(wdma_w_ready), .wdma_w_data(wdma_w_data),
    .wdma_r_valid(wdma_r_valid), .wdma_r_ready(wdma_r_ready), .wdma_r_data(wdma_r_data),
    .start_query_i(start_q), .do_lm_i(do_lm),
    .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs),
    .cons_ready_i(cons_ready),
    .q_query_cue_i(64'hA5A5_0F0F_1234_5678),
    .q_intent_cue_i(64'h1111_2222_3333_4444),
    .q_relation_cue_i(64'h0F1E_2D3C_4B5A_6978),
    .q_context_cue_i(64'hDEAD_BEEF_CAFE_0001),
    .q_path_cue_i(64'h00FF_00FF_00FF_00FF),
    .poison_i(1'b1), .poison_id_i(poison_id),
    .mem_we(1'b0), .mem_addr(20'd0), .mem_wdata(8'sd0), .mem_rdata(),
    .soa_done_o(soa_done), .soa_running_o(soa_running),
    .axi_read_bytes_o(axi_bytes), .axi_read_beats_o(axi_beats), .axi_read_bursts_o(axi_bursts),
    .soa_id_beats_o(), .soa_cue_beats_o(), .soa_prior_beats_o(),
    .waves_o(), .cand_delivered_o(),
    .topk_batches_o(), .topk_valid_o(topk_valid), .topk_score_o(), .topk_id_o(),
    .gv_count_o(), .grant_graph_o(), .grant_lm_o(), .dual_owner_err_o(dual_err),
    .bind_busy_o(bind_busy), .bind_done_o(bind_done),
    .ctx_we_o(ctx_we), .ctx_pack_o(), .start_fwd_o(start_fwd), .capture_valid_o(),
    .ctx_we_beats_o(), .start_fwd_beats_o(st_beats),
    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred), .phase_o(phase),
    .w_stall_o(w_stall),
    .dbg_tile_miss_o(dbg_tile_miss), .dbg_tile_bst_o(dbg_tile_bst), .dbg_tile_dst_o(dbg_tile_dst),
    .dbg_tile_req_s1_o(dbg_tile_req_s1),
    .final_accept_o(final_accept),
    .m_axi_arid(c_arid), .m_axi_araddr(c_araddr), .m_axi_arlen(c_arlen),
    .m_axi_arsize(c_arsize), .m_axi_arburst(c_arburst),
    .m_axi_arvalid(c_arvalid), .m_axi_arready(c_arready),
    .m_axi_rid(c_rid), .m_axi_rdata(c_rdata), .m_axi_rresp(c_rresp),
    .m_axi_rlast(c_rlast), .m_axi_rvalid(c_rvalid), .m_axi_rready(c_rready),
    .owner_ready_o(owner_ready),
    .r_path_idle_o(r_path_idle)
  );

  // B1: do not assert WDMA mux ownership while r_path_idle==0 (query R busy).
  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n)
      wdma_owner_grant <= 1'b0;
    else if (!wdma_owner)
      wdma_owner_grant <= 1'b0;
    else if (r_path_idle)
      wdma_owner_grant <= 1'b1;
    // else: LM requests owner but R-path busy → hold (no 0→1 grant mid-query)
  end

  // F1r: latch ui-domain dma busy/owner while core_busy (ui_clk)
  logic core_busy_ui;
  sync_bits #(.WIDTH(1)) u_core_busy_ui_sync (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .async_in(core_busy),
    .sync_out(core_busy_ui)
  );

  // D3: MIG-side RVALID sticky (ui domain) — query owns mux, not boot/WDMA.
  // E1: MIG AR accept + WDMA/CDC mux ownership after Q_GO (ui domain).
  // E3: CDC slave AR valid/ready/fire + AR FIFO/hold occupancy after Q_GO.
  logic sticky_qgo_ui, sticky_migrv;
  logic sticky_migar, sticky_ownwdma, sticky_cdcar, sticky_muxcdc;
  (* DONT_TOUCH = "TRUE" *) logic sticky_cdc_sarv, sticky_cdc_sarr, sticky_cdc_sarf, sticky_cdc_hold;
  logic sticky_ar_fifo_ne; // F1j: AR FIFO not empty after Q_GO (ui domain)
  logic cdc_arready_r;
  sync_bits #(.WIDTH(1)) u_qgo_ui_sync (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .async_in(sticky_qgo),
    .sync_out(sticky_qgo_ui)
  );
  // F1r/F1t/F1u: latch ui-domain dma probes while core_busy
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      latched_s_dma_busy <= 1'b0;
      latched_wdma_owner_ui <= 1'b0;
      latched_sdone_f1t <= 1'b0;
      latched_dma_st_f1u <= 3'd0;
      latched_sgo_f1u <= 1'b0;
    end else if (sticky_qgo_ui && core_busy_ui) begin
      latched_s_dma_busy <= s_dma_busy;
      latched_wdma_owner_ui <= wdma_owner_ui;
      latched_sdone_f1t <= wdma_dbg_sdone;
      latched_dma_st_f1u <= wdma_dbg_st;
      latched_sgo_f1u <= wdma_dbg_sgo;
    end
  end
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      sticky_migrv   <= 1'b0;
      sticky_migar   <= 1'b0;
      sticky_ownwdma <= 1'b0;
      sticky_cdcar   <= 1'b0;
      sticky_muxcdc  <= 1'b0;
      sticky_cdc_sarv <= 1'b0;
      sticky_cdc_sarr <= 1'b0;
      sticky_cdc_sarf <= 1'b0;
      sticky_cdc_hold <= 1'b0;
      sticky_ar_fifo_ne <= 1'b0;
      cdc_arready_r   <= 1'b0;
    end else begin
      cdc_arready_r <= cdc_arready;
      if (sticky_qgo_ui) begin
        if (!boot_active && !wdma_owner_ui && rvalid)
          sticky_migrv <= 1'b1;
        // MIG slave saw arvalid∧arready (real UI pin into MIG)
        if (arvalid && arready)
          sticky_migar <= 1'b1;
        // WDMA owned mux anytime after Q_GO
        if (wdma_owner_ui)
          sticky_ownwdma <= 1'b1;
        // CDC presenting s_axi_arvalid toward mux/MIG
        if (cdc_arvalid)
          sticky_cdcar <= 1'b1;
        // Mux selecting CDC (not WDMA/boot) when MIG AR handshake fires
        if (arvalid && arready && !boot_active && !wdma_owner_ui)
          sticky_muxcdc <= 1'b1;
        // E3: slave-side CDC AR probes (registered sources only)
        if (cdc_arvalid)
          sticky_cdc_sarv <= 1'b1;
        if (cdc_arready_r)
          sticky_cdc_sarr <= 1'b1;
        if (cdc_arvalid && cdc_arready_r)
          sticky_cdc_sarf <= 1'b1;
        if (cdc_ar_ne || cdc_ar_hold)
          sticky_cdc_hold <= 1'b1;
        // F1j: raw AR FIFO occupancy (registered empty, inverted)
        if (!cdc_ar_empty)
          sticky_ar_fifo_ne <= 1'b1;
      end
    end
  end

  // UART heartbeats on 100 MHz — paced LOAD/WAIT_BUSY/WAIT_IDLE (r3).
  // Order: BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START →
  //        OWNER_RDY → Q_GO → SOA_RUN → AR_BEAT → R_BEAT → R_BUSY → R_IDLE →
  //        RV_SEEN → RREADY1 → RID_OK → RID_BAD → OUTST → MIG_RV → CDC_NE →
  //        MIG_AR → OWN_WDMA → CDC_AR → MUX_CDC →
  //        CDC_M_ARF → CDC_S_ARV → CDC_S_ARR → AR_FIFO_NE → M_RST_LO → S_RST_LO →
  //        CDC_S_ARF → CDC_HOLD →
  //        SOA_Q → TOPK → ACCEPT → PACK → BIND → FWD → LM →
  //        BIND_BUSY → WDMA_BUSY → WDMA_DONE → CORE_BUSY → PRED_NZ → CORE_DONE → PRED
  logic calib_100, boot_100, bind_100, wmem_100, core_live_100, lm_100;
  logic boot_ui_100, calib_ui_100, bind_core_100, soa_core_100;
  logic owner_100, qgo_100, soarun_100, ar_100, rbeat_100, rbusy_100, ridle_100;
  logic rvseen_100, rready1_100, ridok_100, ridbad_100, outst_100, migrv_100, cdcne_100;
  logic migar_100, ownwdma_100, cdcar_100, muxcdc_100;
  logic cdc_marf_100, cdc_sarv_100, cdc_sarr_100, cdc_sarf_100, cdc_hold_100;
  logic ar_fifo_ne_100;
  logic soaq_100, topk_100, accept_100, pack_100, fwd_100;
  logic bind_busy_100, pred_nz_100, core_done_100; // F1l
  logic wdma_busy_100, wdma_done_100, core_busy_100; // F1m
  logic w_stall_100, phase_valid_100; // F1n
  logic [7:0] phase_100; // F1n latched phase
  logic tile_miss_100, tile_dst_valid_100, tile_bst_valid_100; // F1o/F1p
  logic [2:0] tile_dst_100; // F1o latched tile dma dst
  logic [3:0] tile_bst_100; // F1p latched tile bank bst
  logic tile_req_valid_100; // F1q
  logic tile_req_100, tile_dma_busy_lat_100, tile_dma_own_lat_100;
  logic [9:0] pred_100;
  logic [31:0] axi_b_100;
  // F1g: rst probe sticky survives ui/core async reset (CLK100MHZ / clk_locked only).
  logic core_rst_n_100, ui_rst_n_100;
  logic sticky_qgo_seen_100, sticky_m_rst_lo_100, sticky_s_rst_lo_100;

  sync_bits #(.WIDTH(47)) u_stat_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({axi_bytes[18:0], pred, sticky_bind, boot_done_core, calib_core}),
    .sync_out({axi_b_100[18:0], pred_100, bind_100, boot_100, calib_100})
  );
  sync_bits #(.WIDTH(4)) u_led_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_bind, boot_done, calib, soa_done}),
    .sync_out({bind_core_100, boot_ui_100, calib_ui_100, soa_core_100})
  );
  // Single-bit CDC only (no combo on ui/core before sync — avoids unsafe CDC).
  sync_bits #(.WIDTH(1)) u_wmem_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(wmem_done),
    .sync_out(wmem_100)
  );
  sync_bits #(.WIDTH(1)) u_lm_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_lm),
    .sync_out(lm_100)
  );
  // F1l: BIND_BUSY / PRED_NZ / CORE_DONE sticky → UART (after LM)
  sync_bits #(.WIDTH(3)) u_f1l_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_core_done, sticky_pred_nz, sticky_bind_busy}),
    .sync_out({core_done_100, pred_nz_100, bind_busy_100})
  );
  // F1m: WDMA_BUSY / WDMA_DONE / CORE_BUSY sticky → UART (after BIND_BUSY)
  sync_bits #(.WIDTH(3)) u_f1m_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_core_busy, sticky_wdma_done, sticky_wdma_busy}),
    .sync_out({core_busy_100, wdma_done_100, wdma_busy_100})
  );
  // F1n: W_STALL sticky + latched PHASE → UART (after CORE_BUSY)
  sync_bits #(.WIDTH(1)) u_f1n_wstall_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_w_stall),
    .sync_out(w_stall_100)
  );
  sync_bits #(.WIDTH(1)) u_f1n_phase_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(phase_valid_100)
  );
  sync_bits #(.WIDTH(8)) u_f1n_phase_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(latched_phase),
    .sync_out(phase_100)
  );
  // F1o: TILE_MISS sticky + latched TILE_DST → UART (after CORE_BUSY)
  sync_bits #(.WIDTH(1)) u_f1o_tile_miss_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_tile_miss),
    .sync_out(tile_miss_100)
  );
  sync_bits #(.WIDTH(1)) u_f1o_tile_dst_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(tile_dst_valid_100)
  );
  sync_bits #(.WIDTH(3)) u_f1o_tile_dst_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(latched_tile_dst),
    .sync_out(tile_dst_100)
  );
  // F1p: TILE_BST sticky + latched bank bst → UART (after TILE_DST)
  sync_bits #(.WIDTH(1)) u_f1p_tile_bst_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(tile_bst_valid_100)
  );
  sync_bits #(.WIDTH(4)) u_f1p_tile_bst_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(latched_tile_bst),
    .sync_out(tile_bst_100)
  );
  // F1q: TILE_REQ / TILE_DMA_BUSY / TILE_DMA_OWN → UART (after TILE_BST)
  sync_bits #(.WIDTH(1)) u_f1q_tile_req_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(tile_req_valid_100)
  );
  sync_bits #(.WIDTH(3)) u_f1q_tile_dma_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_tile_dma_own, latched_tile_dma_busy, latched_tile_req}),
    .sync_out({tile_dma_own_lat_100, tile_dma_busy_lat_100, tile_req_100})
  );
  // F1r: SDMA_BUSY / WDMA_BUSY / WDMA_OWN_UI latched → UART (after TILE_REQ)
  logic sdma_busy_lat_100, wdma_busy_lat_100, wdma_own_ui_lat_100;
  sync_bits #(.WIDTH(3)) u_f1r_dma_src_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_wdma_owner_ui, latched_wdma_busy_f1r, latched_s_dma_busy}),
    .sync_out({wdma_own_ui_lat_100, wdma_busy_lat_100, sdma_busy_lat_100})
  );
  // F1t: SDONE / MDONE / BUSY_HOLD latched → UART (after TILE_DMA_OWN)
  logic sdone_lat_100, mdone_lat_100, busy_hold_lat_100;
  sync_bits #(.WIDTH(3)) u_f1t_done_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_busy_hold_f1t, latched_mdone_f1t, latched_sdone_f1t}),
    .sync_out({busy_hold_lat_100, mdone_lat_100, sdone_lat_100})
  );
  // F1u: DMA_ST / SGO latched → UART (after BUSY_HOLD)
  logic [2:0] dma_st_lat_100;
  logic sgo_lat_100;
  sync_bits #(.WIDTH(4)) u_f1u_fsm_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_sgo_f1u, latched_dma_st_f1u}),
    .sync_out({sgo_lat_100, dma_st_lat_100})
  );
  // F1v: WDMA_OWNER / WDMA_GRANT / RPATH_IDLE / MGO latched → UART (after SGO)
  logic wdma_own_f1v_100, wdma_grant_f1v_100, rpath_idle_f1v_100, mgo_f1v_100;
  sync_bits #(.WIDTH(4)) u_f1v_owner_grant_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_mgo_f1v, latched_rpath_idle_f1v, latched_wdma_grant_f1v, latched_wdma_own_f1v}),
    .sync_out({mgo_f1v_100, rpath_idle_f1v_100, wdma_grant_f1v_100, wdma_own_f1v_100})
  );
  // F1B2: CMD_EMPTY / SBUSY_PEND / CMD_ST / CMD_RD stickies → UART (after MGO)
  logic sbusy_pend_100, cmd_empty_mgo_100, cmd_rd_100;
  logic [1:0] cmd_st_100;
  sync_bits #(.WIDTH(5)) u_f1b2_cmd_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({wdma_dbg_cmd_rd, wdma_dbg_cmd_empty_mgo, wdma_dbg_cmd_st, wdma_dbg_sbusy_pend}),
    .sync_out({cmd_rd_100, cmd_empty_mgo_100, cmd_st_100, sbusy_pend_100})
  );
  sync_bits #(.WIDTH(12)) u_post_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_fwd, sticky_pack, sticky_accept, sticky_topk, sticky_soaq,
               sticky_ridle, sticky_rbusy, sticky_rbeat, sticky_ar, sticky_soarun,
               sticky_qgo, sticky_owner}),
    .sync_out({fwd_100, pack_100, accept_100, topk_100, soaq_100,
               ridle_100, rbusy_100, rbeat_100, ar_100, soarun_100,
               qgo_100, owner_100})
  );
  sync_bits #(.WIDTH(7)) u_d3_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_cdc_ne, sticky_migrv, sticky_outst, sticky_rid_bad,
               sticky_rid_ok, sticky_rready1, sticky_rvseen}),
    .sync_out({cdcne_100, migrv_100, outst_100, ridbad_100,
               ridok_100, rready1_100, rvseen_100})
  );
  sync_bits #(.WIDTH(4)) u_e1_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_muxcdc, sticky_cdcar, sticky_ownwdma, sticky_migar}),
    .sync_out({muxcdc_100, cdcar_100, ownwdma_100, migar_100})
  );
  sync_bits #(.WIDTH(1)) u_e3_marf_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_cdc_marf),
    .sync_out(cdc_marf_100)
  );
  sync_bits #(.WIDTH(4)) u_e3_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_cdc_hold, sticky_cdc_sarf, sticky_cdc_sarr, sticky_cdc_sarv}),
    .sync_out({cdc_hold_100, cdc_sarf_100, cdc_sarr_100, cdc_sarv_100})
  );
  sync_bits #(.WIDTH(1)) u_f1j_ar_fifo_ne_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_ar_fifo_ne),
    .sync_out(ar_fifo_ne_100)
  );
  // F1g: register rst in native domain first (combo ui_rst_n caused unsafe CDC),
  // then sync into CLK100MHZ; latch LO after Q_GO in a domain that survives ui/core rst.
  logic core_rst_n_q, ui_rst_n_q;
  always_ff @(posedge core_clk) core_rst_n_q <= core_rst_n;
  always_ff @(posedge ui_clk) ui_rst_n_q <= ui_rst_n;
  sync_bits #(.WIDTH(1)) u_core_rst_100_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(core_rst_n_q),
    .sync_out(core_rst_n_100)
  );
  sync_bits #(.WIDTH(1)) u_ui_rst_100_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(ui_rst_n_q),
    .sync_out(ui_rst_n_100)
  );
  always_ff @(posedge CLK100MHZ) begin
    if (!clk_locked) begin
      sticky_qgo_seen_100 <= 1'b0;
      sticky_m_rst_lo_100 <= 1'b0;
      sticky_s_rst_lo_100 <= 1'b0;
    end else begin
      if (qgo_100)
        sticky_qgo_seen_100 <= 1'b1;
      // sticky_qgo_seen survives async clear of sticky_qgo when core_rst_n falls
      if (sticky_qgo_seen_100 && !core_rst_n_100)
        sticky_m_rst_lo_100 <= 1'b1;
      if (sticky_qgo_seen_100 && !ui_rst_n_100)
        sticky_s_rst_lo_100 <= 1'b1;
    end
  end
  // CORE_START after all three boot legs, computed in 100 MHz domain (safe).
  assign core_live_100 = calib_ui_100 && wmem_100 && boot_ui_100;
  assign axi_b_100[31:19] = '0;

  logic [7:0] tx_data;
  logic tx_start, tx_busy;
  logic [6:0] tx_i;
  logic [5:0] tx_len;
  // msg_sel: 0 BOOT … 37 LM … 38 BIND_BUSY … 39 WDMA_BUSY … 40 WDMA_DONE …
  //          41 CORE_BUSY … 42 TILE_MISS … 43 TILE_DST=H … 44 TILE_BST=H …
  //          45 TILE_REQ=H … 46 SDMA_BUSY=H … 47 WDMA_BUSY=H … 48 WDMA_OWN_UI=H …
  //          49 TILE_DMA_BUSY=H … 50 TILE_DMA_OWN=H …
  //          51 W_STALL … 52 PHASE=HH … 53 PRED_NZ … 54 CORE_DONE … 55 PRED
  //          56 SDONE=H … 57 MDONE=H … 58 BUSY_HOLD=H … 59 DMA_ST=H … 60 SGO=H
  //          61 WDMA_OWNER=H … 62 WDMA_GRANT=H … 63 RPATH_IDLE=H … 64 MGO=H
  //          65 CMD_EMPTY=H … 66 SBUSY_PEND=H … 67 CMD_ST=H … 68 CMD_RD=H
  logic [6:0] msg_sel;
  logic [68:0] sent_mask; // sticky: bit i set after message i completed
  logic [3:0] led_sticky;
  logic saw_busy;
  // LOAD pulses start; WAIT_BUSY until uart_tx latches; WAIT_IDLE until byte done.
  typedef enum logic [2:0] {
    UT_IDLE, UT_LOAD, UT_WAIT_BUSY, UT_WAIT_IDLE, UT_NL_LOAD, UT_NL_BUSY, UT_NL_IDLE, UT_DONE
  } ut_t;
  ut_t ut;

  uart_tx #(.CLK_HZ(100_000_000), .BAUD(115200)) u_tx (
    .clk(CLK100MHZ), .rst_n(clk_locked), .start(tx_start), .data(tx_data),
    .tx(uart_rxd_out), .busy(tx_busy)
  );

  // ROM: fixed ASCII lines (PRED uses decimal digits from pred_100 — F2).
  function automatic logic [7:0] hex_nib(input logic [3:0] n);
    return (n < 4'd10) ? (8'h30 + 8'(n)) : (8'h41 + 8'(n - 4'd10));
  endfunction

  function automatic logic [7:0] hb_char(input logic [6:0] sel, input logic [6:0] i);
    unique case (sel)
      6'd0: unique case (i) // BOOT
        6'd0: return "B"; 6'd1: return "O"; 6'd2: return "O"; 6'd3: return "T";
        default: return 8'h00;
      endcase
      6'd1: unique case (i) // MIG_OK
        6'd0: return "M"; 6'd1: return "I"; 6'd2: return "G"; 6'd3: return "_";
        6'd4: return "O"; 6'd5: return "K";
        default: return 8'h00;
      endcase
      6'd2: unique case (i) // WMEM_OK
        6'd0: return "W"; 6'd1: return "M"; 6'd2: return "E"; 6'd3: return "M";
        6'd4: return "_"; 6'd5: return "O"; 6'd6: return "K";
        default: return 8'h00;
      endcase
      6'd3: unique case (i) // SOA_OK (boot SOA)
        6'd0: return "S"; 6'd1: return "O"; 6'd2: return "A"; 6'd3: return "_";
        6'd4: return "O"; 6'd5: return "K";
        default: return 8'h00;
      endcase
      6'd4: unique case (i) // CORE_START
        6'd0: return "C"; 6'd1: return "O"; 6'd2: return "R"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "S"; 6'd6: return "T"; 6'd7: return "A";
        6'd8: return "R"; 6'd9: return "T";
        default: return 8'h00;
      endcase
      6'd5: unique case (i) // OWNER_RDY
        6'd0: return "O"; 6'd1: return "W"; 6'd2: return "N"; 6'd3: return "E";
        6'd4: return "R"; 6'd5: return "_"; 6'd6: return "R"; 6'd7: return "D";
        6'd8: return "Y";
        default: return 8'h00;
      endcase
      6'd6: unique case (i) // Q_GO
        6'd0: return "Q"; 6'd1: return "_"; 6'd2: return "G"; 6'd3: return "O";
        default: return 8'h00;
      endcase
      6'd7: unique case (i) // SOA_RUN
        6'd0: return "S"; 6'd1: return "O"; 6'd2: return "A"; 6'd3: return "_";
        6'd4: return "R"; 6'd5: return "U"; 6'd6: return "N";
        default: return 8'h00;
      endcase
      6'd8: unique case (i) // AR_BEAT
        6'd0: return "A"; 6'd1: return "R"; 6'd2: return "_"; 6'd3: return "B";
        6'd4: return "E"; 6'd5: return "A"; 6'd6: return "T";
        default: return 8'h00;
      endcase
      6'd9: unique case (i) // R_BEAT
        6'd0: return "R"; 6'd1: return "_"; 6'd2: return "B"; 6'd3: return "E";
        6'd4: return "A"; 6'd5: return "T";
        default: return 8'h00;
      endcase
      6'd10: unique case (i) // R_BUSY
        6'd0: return "R"; 6'd1: return "_"; 6'd2: return "B"; 6'd3: return "U";
        6'd4: return "S"; 6'd5: return "Y";
        default: return 8'h00;
      endcase
      6'd11: unique case (i) // R_IDLE
        6'd0: return "R"; 6'd1: return "_"; 6'd2: return "I"; 6'd3: return "D";
        6'd4: return "L"; 6'd5: return "E";
        default: return 8'h00;
      endcase
      6'd12: unique case (i) // RV_SEEN
        6'd0: return "R"; 6'd1: return "V"; 6'd2: return "_"; 6'd3: return "S";
        6'd4: return "E"; 6'd5: return "E"; 6'd6: return "N";
        default: return 8'h00;
      endcase
      6'd13: unique case (i) // RREADY1
        6'd0: return "R"; 6'd1: return "R"; 6'd2: return "E"; 6'd3: return "A";
        6'd4: return "D"; 6'd5: return "Y"; 6'd6: return "1";
        default: return 8'h00;
      endcase
      6'd14: unique case (i) // RID_OK
        6'd0: return "R"; 6'd1: return "I"; 6'd2: return "D"; 6'd3: return "_";
        6'd4: return "O"; 6'd5: return "K";
        default: return 8'h00;
      endcase
      6'd15: unique case (i) // RID_BAD
        6'd0: return "R"; 6'd1: return "I"; 6'd2: return "D"; 6'd3: return "_";
        6'd4: return "B"; 6'd5: return "A"; 6'd6: return "D";
        default: return 8'h00;
      endcase
      6'd16: unique case (i) // OUTST
        6'd0: return "O"; 6'd1: return "U"; 6'd2: return "T"; 6'd3: return "S";
        6'd4: return "T";
        default: return 8'h00;
      endcase
      6'd17: unique case (i) // MIG_RV
        6'd0: return "M"; 6'd1: return "I"; 6'd2: return "G"; 6'd3: return "_";
        6'd4: return "R"; 6'd5: return "V";
        default: return 8'h00;
      endcase
      6'd18: unique case (i) // CDC_NE
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "N"; 6'd5: return "E";
        default: return 8'h00;
      endcase
      6'd19: unique case (i) // MIG_AR
        6'd0: return "M"; 6'd1: return "I"; 6'd2: return "G"; 6'd3: return "_";
        6'd4: return "A"; 6'd5: return "R";
        default: return 8'h00;
      endcase
      6'd20: unique case (i) // OWN_WDMA
        6'd0: return "O"; 6'd1: return "W"; 6'd2: return "N"; 6'd3: return "_";
        6'd4: return "W"; 6'd5: return "D"; 6'd6: return "M"; 6'd7: return "A";
        default: return 8'h00;
      endcase
      6'd21: unique case (i) // CDC_AR
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "A"; 6'd5: return "R";
        default: return 8'h00;
      endcase
      6'd22: unique case (i) // MUX_CDC
        6'd0: return "M"; 6'd1: return "U"; 6'd2: return "X"; 6'd3: return "_";
        6'd4: return "C"; 6'd5: return "D"; 6'd6: return "C";
        default: return 8'h00;
      endcase
      6'd23: unique case (i) // CDC_M_ARF
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "M"; 6'd5: return "_"; 6'd6: return "A"; 6'd7: return "R";
        6'd8: return "F";
        default: return 8'h00;
      endcase
      6'd24: unique case (i) // CDC_S_ARV
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "S"; 6'd5: return "_"; 6'd6: return "A"; 6'd7: return "R";
        6'd8: return "V";
        default: return 8'h00;
      endcase
      6'd25: unique case (i) // CDC_S_ARR
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "S"; 6'd5: return "_"; 6'd6: return "A"; 6'd7: return "R";
        6'd8: return "R";
        default: return 8'h00;
      endcase
      6'd26: unique case (i) // AR_FIFO_NE (F1j)
        6'd0: return "A"; 6'd1: return "R"; 6'd2: return "_"; 6'd3: return "F";
        6'd4: return "I"; 6'd5: return "F"; 6'd6: return "F"; 6'd7: return "O";
        6'd8: return "_"; 6'd9: return "N"; 6'd10: return "E";
        default: return 8'h00;
      endcase
      6'd27: unique case (i) // M_RST_LO (F1g)
        6'd0: return "M"; 6'd1: return "_"; 6'd2: return "R"; 6'd3: return "S";
        6'd4: return "T"; 6'd5: return "_"; 6'd6: return "L"; 6'd7: return "O";
        default: return 8'h00;
      endcase
      6'd28: unique case (i) // S_RST_LO (F1g)
        6'd0: return "S"; 6'd1: return "_"; 6'd2: return "R"; 6'd3: return "S";
        6'd4: return "T"; 6'd5: return "_"; 6'd6: return "L"; 6'd7: return "O";
        default: return 8'h00;
      endcase
      6'd29: unique case (i) // CDC_S_ARF
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "S"; 6'd5: return "_"; 6'd6: return "A"; 6'd7: return "R";
        6'd8: return "F";
        default: return 8'h00;
      endcase
      6'd30: unique case (i) // CDC_HOLD
        6'd0: return "C"; 6'd1: return "D"; 6'd2: return "C"; 6'd3: return "_";
        6'd4: return "H"; 6'd5: return "O"; 6'd6: return "L"; 6'd7: return "D";
        default: return 8'h00;
      endcase
      6'd31: unique case (i) // SOA_Q (query SOA done)
        6'd0: return "S"; 6'd1: return "O"; 6'd2: return "A"; 6'd3: return "_";
        6'd4: return "Q";
        default: return 8'h00;
      endcase
      6'd32: unique case (i) // TOPK
        6'd0: return "T"; 6'd1: return "O"; 6'd2: return "P"; 6'd3: return "K";
        default: return 8'h00;
      endcase
      6'd33: unique case (i) // ACCEPT
        6'd0: return "A"; 6'd1: return "C"; 6'd2: return "C"; 6'd3: return "E";
        6'd4: return "P"; 6'd5: return "T";
        default: return 8'h00;
      endcase
      6'd34: unique case (i) // PACK
        6'd0: return "P"; 6'd1: return "A"; 6'd2: return "C"; 6'd3: return "K";
        default: return 8'h00;
      endcase
      6'd35: unique case (i) // BIND
        6'd0: return "B"; 6'd1: return "I"; 6'd2: return "N"; 6'd3: return "D";
        default: return 8'h00;
      endcase
      6'd36: unique case (i) // FWD
        6'd0: return "F"; 6'd1: return "W"; 6'd2: return "D";
        default: return 8'h00;
      endcase
      6'd37: unique case (i) // LM
        6'd0: return "L"; 6'd1: return "M";
        default: return 8'h00;
      endcase
      6'd38: unique case (i) // BIND_BUSY (F1l)
        6'd0: return "B"; 6'd1: return "I"; 6'd2: return "N"; 6'd3: return "D";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y";
        default: return 8'h00;
      endcase
      6'd39: unique case (i) // WDMA_BUSY (F1m)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y";
        default: return 8'h00;
      endcase
      6'd40: unique case (i) // WDMA_DONE (F1m)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "O"; 6'd7: return "N";
        6'd8: return "E";
        default: return 8'h00;
      endcase
      6'd41: unique case (i) // CORE_BUSY (F1m)
        6'd0: return "C"; 6'd1: return "O"; 6'd2: return "R"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y";
        default: return 8'h00;
      endcase
      6'd42: unique case (i) // TILE_MISS (F1o)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "M"; 6'd6: return "I"; 6'd7: return "S";
        6'd8: return "S";
        default: return 8'h00;
      endcase
      6'd43: unique case (i) // TILE_DST=H (F1o dma FSM)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "S"; 6'd7: return "T";
        6'd8: return "=";
        6'd9: return hex_nib({1'b0, tile_dst_100});
        default: return 8'h00;
      endcase
      6'd44: unique case (i) // TILE_BST=H (F1p bank FSM)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "S"; 6'd7: return "T";
        6'd8: return "=";
        6'd9: return hex_nib(tile_bst_100);
        default: return 8'h00;
      endcase
      6'd45: unique case (i) // TILE_REQ=H (F1q req_s[1])
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "R"; 6'd6: return "E"; 6'd7: return "Q";
        6'd8: return "=";
        6'd9: return hex_nib({3'b0, tile_req_100});
        default: return 8'h00;
      endcase
      6'd46: unique case (i) // SDMA_BUSY=H (F1r s_dma_busy ui)
        6'd0: return "S"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, sdma_busy_lat_100});
        default: return 8'h00;
      endcase
      6'd47: unique case (i) // WDMA_BUSY=H (F1r wdma_busy core latched)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, wdma_busy_lat_100});
        default: return 8'h00;
      endcase
      6'd48: unique case (i) // WDMA_OWN_UI=H (F1r wdma_owner_ui ui)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "O"; 6'd6: return "W"; 6'd7: return "N";
        6'd8: return "_"; 6'd9: return "U"; 6'd10: return "I"; 6'd11: return "=";
        6'd12: return hex_nib({3'b0, wdma_own_ui_lat_100});
        default: return 8'h00;
      endcase
      6'd49: unique case (i) // TILE_DMA_BUSY=H (F1q)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "M"; 6'd7: return "A";
        6'd8: return "_"; 6'd9: return "B"; 6'd10: return "U"; 6'd11: return "S";
        6'd12: return "Y"; 6'd13: return "=";
        6'd14: return hex_nib({3'b0, tile_dma_busy_lat_100});
        default: return 8'h00;
      endcase
      6'd50: unique case (i) // TILE_DMA_OWN=H (F1q dma_owner)
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "M"; 6'd7: return "A";
        6'd8: return "_"; 6'd9: return "O"; 6'd10: return "W"; 6'd11: return "N";
        6'd12: return "=";
        6'd13: return hex_nib({3'b0, tile_dma_own_lat_100});
        default: return 8'h00;
      endcase
      6'd51: unique case (i) // W_STALL (F1n)
        6'd0: return "W"; 6'd1: return "_"; 6'd2: return "S"; 6'd3: return "T";
        6'd4: return "A"; 6'd5: return "L"; 6'd6: return "L";
        default: return 8'h00;
      endcase
      6'd52: unique case (i) // PHASE=HH (F1n)
        6'd0: return "P"; 6'd1: return "H"; 6'd2: return "A"; 6'd3: return "S";
        6'd4: return "E"; 6'd5: return "=";
        6'd6: return hex_nib(phase_100[7:4]);
        6'd7: return hex_nib(phase_100[3:0]);
        default: return 8'h00;
      endcase
      6'd53: unique case (i) // PRED_NZ (F1l)
        6'd0: return "P"; 6'd1: return "R"; 6'd2: return "E"; 6'd3: return "D";
        6'd4: return "_"; 6'd5: return "N"; 6'd6: return "Z";
        default: return 8'h00;
      endcase
      6'd54: unique case (i) // CORE_DONE (F1l)
        6'd0: return "C"; 6'd1: return "O"; 6'd2: return "R"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "O"; 6'd7: return "N";
        6'd8: return "E";
        default: return 8'h00;
      endcase
      6'd55: unique case (i) // NATIVE_V1_EXIST_ROW,pred=DDD  (F2 decimal)
        6'd0: return "N"; 6'd1: return "A"; 6'd2: return "T"; 6'd3: return "I";
        6'd4: return "V"; 6'd5: return "E"; 6'd6: return "_"; 6'd7: return "V";
        6'd8: return "1"; 6'd9: return "_"; 6'd10: return "E"; 6'd11: return "X";
        6'd12: return "I"; 6'd13: return "S"; 6'd14: return "T"; 6'd15: return "_";
        6'd16: return "R"; 6'd17: return "O"; 6'd18: return "W"; 6'd19: return ",";
        6'd20: return "p"; 6'd21: return "r"; 6'd22: return "e"; 6'd23: return "d";
        6'd24: return "=";
        6'd25: return "0" + 8'(pred_100 / 10'd100);
        6'd26: return "0" + 8'((pred_100 / 10'd10) % 10'd10);
        6'd27: return "0" + 8'(pred_100 % 10'd10);
        default: return 8'h00;
      endcase
      6'd56: unique case (i) // SDONE=H (F1t s_done sticky latched)
        6'd0: return "S"; 6'd1: return "D"; 6'd2: return "O"; 6'd3: return "N";
        6'd4: return "E"; 6'd5: return "=";
        6'd6: return hex_nib({3'b0, sdone_lat_100});
        default: return 8'h00;
      endcase
      6'd57: unique case (i) // MDONE=H (F1t m_done sticky latched)
        6'd0: return "M"; 6'd1: return "D"; 6'd2: return "O"; 6'd3: return "N";
        6'd4: return "E"; 6'd5: return "=";
        6'd6: return hex_nib({3'b0, mdone_lat_100});
        default: return 8'h00;
      endcase
      6'd58: unique case (i) // BUSY_HOLD=H (F1t busy_hold latched)
        6'd0: return "B"; 6'd1: return "U"; 6'd2: return "S"; 6'd3: return "Y";
        6'd4: return "_"; 6'd5: return "H"; 6'd6: return "O"; 6'd7: return "L";
        6'd8: return "D"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, busy_hold_lat_100});
        default: return 8'h00;
      endcase
      6'd59: unique case (i) // DMA_ST=H (F1u ddr_tile_dma FSM latched)
        6'd0: return "D"; 6'd1: return "M"; 6'd2: return "A"; 6'd3: return "_";
        6'd4: return "S"; 6'd5: return "T"; 6'd6: return "=";
        6'd7: return hex_nib(dma_st_lat_100);
        default: return 8'h00;
      endcase
      6'd60: unique case (i) // SGO=H (F1u sticky s_go latched)
        6'd0: return "S"; 6'd1: return "G"; 6'd2: return "O"; 6'd3: return "=";
        6'd4: return hex_nib({3'b0, sgo_lat_100});
        default: return 8'h00;
      endcase
      6'd61: unique case (i) // WDMA_OWNER=H (F1v wdma_owner core latched)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "O"; 6'd6: return "W"; 6'd7: return "N";
        6'd8: return "E"; 6'd9: return "R"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, wdma_own_f1v_100});
        default: return 8'h00;
      endcase
      6'd62: unique case (i) // WDMA_GRANT=H (F1v wdma_owner_grant latched)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "G"; 6'd6: return "R"; 6'd7: return "A";
        6'd8: return "N"; 6'd9: return "T"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, wdma_grant_f1v_100});
        default: return 8'h00;
      endcase
      6'd63: unique case (i) // RPATH_IDLE=H (F1v r_path_idle latched)
        6'd0: return "R"; 6'd1: return "P"; 6'd2: return "A"; 6'd3: return "T";
        6'd4: return "H"; 6'd5: return "_"; 6'd6: return "I"; 6'd7: return "D";
        6'd8: return "L"; 6'd9: return "E"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, rpath_idle_f1v_100});
        default: return 8'h00;
      endcase
      // F1w: MUST be 7'd64 — 6'd64 truncates to 0 (Synth 8-10929) and aliases BOOT
      7'd64: unique case (i) // MGO=H (F1v sticky m_go latched)
        6'd0: return "M"; 6'd1: return "G"; 6'd2: return "O"; 6'd3: return "=";
        6'd4: return hex_nib({3'b0, mgo_f1v_100});
        default: return 8'h00;
      endcase
      7'd65: unique case (i) // CMD_EMPTY=H (F1B2 after MGO)
        6'd0: return "C"; 6'd1: return "M"; 6'd2: return "D"; 6'd3: return "_";
        6'd4: return "E"; 6'd5: return "M"; 6'd6: return "P"; 6'd7: return "T";
        6'd8: return "Y"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, cmd_empty_mgo_100});
        default: return 8'h00;
      endcase
      7'd66: unique case (i) // SBUSY_PEND=H (F1B2 s_busy while !cmd_empty)
        6'd0: return "S"; 6'd1: return "B"; 6'd2: return "U"; 6'd3: return "S";
        6'd4: return "Y"; 6'd5: return "_"; 6'd6: return "P"; 6'd7: return "E";
        6'd8: return "N"; 6'd9: return "D"; 6'd10: return "=";
        6'd11: return hex_nib({3'b0, sbusy_pend_100});
        default: return 8'h00;
      endcase
      7'd67: unique case (i) // CMD_ST=H (F1B2 cmd_st latched while !cmd_empty)
        6'd0: return "C"; 6'd1: return "M"; 6'd2: return "D"; 6'd3: return "_";
        6'd4: return "S"; 6'd5: return "T"; 6'd6: return "=";
        6'd7: return hex_nib({2'b0, cmd_st_100});
        default: return 8'h00;
      endcase
      7'd68: unique case (i) // CMD_RD=H (F1B2 cmd_rd_en sticky)
        6'd0: return "C"; 6'd1: return "M"; 6'd2: return "D"; 6'd3: return "_";
        6'd4: return "R"; 6'd5: return "D"; 6'd6: return "=";
        6'd7: return hex_nib({3'b0, cmd_rd_100});
        default: return 8'h00;
      endcase
      default: return 8'h00;
    endcase
  endfunction

  function automatic logic [5:0] hb_len(input logic [6:0] sel);
    unique case (sel)
      6'd0:  return 7'd4;   // BOOT
      6'd1:  return 7'd6;   // MIG_OK
      6'd2:  return 7'd7;   // WMEM_OK
      6'd3:  return 7'd6;   // SOA_OK
      6'd4:  return 7'd10;  // CORE_START
      6'd5:  return 7'd9;   // OWNER_RDY
      6'd6:  return 7'd4;   // Q_GO
      6'd7:  return 7'd7;   // SOA_RUN
      6'd8:  return 7'd7;   // AR_BEAT
      6'd9:  return 7'd6;   // R_BEAT
      6'd10: return 7'd6;   // R_BUSY
      6'd11: return 7'd6;   // R_IDLE
      6'd12: return 7'd7;   // RV_SEEN
      6'd13: return 7'd7;   // RREADY1
      6'd14: return 7'd6;   // RID_OK
      6'd15: return 7'd7;   // RID_BAD
      6'd16: return 7'd5;   // OUTST
      6'd17: return 7'd6;   // MIG_RV
      6'd18: return 7'd6;   // CDC_NE
      6'd19: return 7'd6;   // MIG_AR
      6'd20: return 7'd8;   // OWN_WDMA
      6'd21: return 7'd6;   // CDC_AR
      6'd22: return 7'd7;   // MUX_CDC
      6'd23: return 7'd9;   // CDC_M_ARF
      6'd24: return 7'd9;   // CDC_S_ARV
      6'd25: return 7'd9;   // CDC_S_ARR
      6'd26: return 7'd11;  // AR_FIFO_NE
      6'd27: return 7'd8;   // M_RST_LO
      6'd28: return 7'd8;   // S_RST_LO
      6'd29: return 7'd9;   // CDC_S_ARF
      6'd30: return 7'd8;   // CDC_HOLD
      6'd31: return 7'd5;   // SOA_Q
      6'd32: return 7'd4;   // TOPK
      6'd33: return 7'd6;   // ACCEPT
      6'd34: return 7'd4;   // PACK
      6'd35: return 7'd4;   // BIND
      6'd36: return 7'd3;   // FWD
      6'd37: return 7'd2;   // LM
      6'd38: return 7'd9;   // BIND_BUSY
      6'd39: return 7'd9;   // WDMA_BUSY
      6'd40: return 7'd9;   // WDMA_DONE
      6'd41: return 7'd9;   // CORE_BUSY
      6'd42: return 7'd9;   // TILE_MISS
      6'd43: return 7'd10;  // TILE_DST=H
      6'd44: return 7'd10;  // TILE_BST=H
      6'd45: return 7'd10;  // TILE_REQ=H
      6'd46: return 7'd11;  // SDMA_BUSY=H
      6'd47: return 7'd11;  // WDMA_BUSY=H
      6'd48: return 7'd13;  // WDMA_OWN_UI=H
      6'd49: return 7'd15;  // TILE_DMA_BUSY=H
      6'd50: return 7'd14;  // TILE_DMA_OWN=H
      6'd51: return 7'd7;   // W_STALL
      6'd52: return 7'd8;   // PHASE=HH
      6'd53: return 7'd7;   // PRED_NZ
      6'd54: return 7'd9;   // CORE_DONE
      6'd55: return 7'd28;  // PRED row
      6'd56: return 7'd7;   // SDONE=H
      6'd57: return 7'd7;   // MDONE=H
      6'd58: return 7'd11;  // BUSY_HOLD=H
      6'd59: return 7'd8;   // DMA_ST=H
      6'd60: return 7'd5;   // SGO=H
      6'd61: return 7'd12;  // WDMA_OWNER=H
      6'd62: return 7'd12;  // WDMA_GRANT=H
      6'd63: return 7'd12;  // RPATH_IDLE=H
      7'd64: return 7'd5;   // MGO=H (F1w: 7'd — 6'd64 truncates to BOOT)
      7'd65: return 7'd11;  // CMD_EMPTY=H
      7'd66: return 7'd12;  // SBUSY_PEND=H
      7'd67: return 7'd8;   // CMD_ST=H
      7'd68: return 7'd8;   // CMD_RD=H
      default: return 7'd28; // PRED row
    endcase
  endfunction

  // Next unsent stage whose condition is true (priority low→high).
  function automatic logic [6:0] hb_next(
      input logic [68:0] mask,
      input logic mig_ok, wmem_ok, soa_ok, core_ok,
      input logic owner_ok, qgo_ok, soarun_ok, ar_ok, rbeat_ok,
      input logic rbusy_ok, ridle_ok,
      input logic rvseen_ok, rready1_ok, ridok_ok, ridbad_ok, outst_ok,
      input logic migrv_ok, cdcne_ok,
      input logic migar_ok, ownwdma_ok, cdcar_ok, muxcdc_ok,
      input logic cdc_marf_ok, cdc_sarv_ok, cdc_sarr_ok,
      input logic ar_fifo_ne_ok,
      input logic m_rst_lo_ok, s_rst_lo_ok,
      input logic cdc_sarf_ok, cdc_hold_ok,
      input logic soaq_ok, topk_ok, accept_ok,
      input logic pack_ok, bind_ok, fwd_ok, lm_ok,
      input logic bind_busy_ok, wdma_busy_ok, wdma_done_ok, core_busy_ok,
      input logic tile_miss_ok, tile_dst_ok, tile_bst_ok,
      input logic tile_req_ok, sdma_busy_ok, wdma_busy_lat_ok, wdma_own_ui_ok,
      input logic tile_dma_busy_ok, tile_dma_own_ok,
      input logic sdone_ok, mdone_ok, busy_hold_ok,
      input logic dma_st_ok, sgo_ok,
      input logic wdma_own_f1v_ok, wdma_grant_f1v_ok, rpath_idle_f1v_ok, mgo_f1v_ok,
      input logic cmd_empty_ok, sbusy_pend_ok, cmd_st_ok, cmd_rd_ok,
      input logic w_stall_ok, phase_ok,
      input logic pred_nz_ok, core_done_ok, pred_ok
  );
    if (!mask[0])  return 7'd0;
    if (mig_ok     && !mask[1])  return 7'd1;
    if (wmem_ok    && !mask[2])  return 7'd2;
    if (soa_ok     && !mask[3])  return 7'd3;
    if (core_ok    && !mask[4])  return 7'd4;
    if (owner_ok   && !mask[5])  return 7'd5;
    if (qgo_ok     && !mask[6])  return 7'd6;
    if (soarun_ok  && !mask[7])  return 7'd7;
    if (ar_ok      && !mask[8])  return 7'd8;
    if (rbeat_ok   && !mask[9])  return 7'd9;
    if (rbusy_ok   && !mask[10]) return 7'd10;
    if (ridle_ok   && !mask[11]) return 7'd11;
    if (rvseen_ok  && !mask[12]) return 7'd12;
    if (rready1_ok && !mask[13]) return 7'd13;
    if (ridok_ok   && !mask[14]) return 7'd14;
    if (ridbad_ok  && !mask[15]) return 7'd15;
    if (outst_ok   && !mask[16]) return 7'd16;
    if (migrv_ok   && !mask[17]) return 7'd17;
    if (cdcne_ok   && !mask[18]) return 7'd18;
    if (migar_ok   && !mask[19]) return 7'd19;
    if (ownwdma_ok && !mask[20]) return 7'd20;
    if (cdcar_ok   && !mask[21]) return 7'd21;
    if (muxcdc_ok  && !mask[22]) return 7'd22;
    if (cdc_marf_ok && !mask[23]) return 7'd23;
    if (cdc_sarv_ok && !mask[24]) return 7'd24;
    if (cdc_sarr_ok && !mask[25]) return 7'd25;
    if (ar_fifo_ne_ok && !mask[26]) return 7'd26;
    if (m_rst_lo_ok && !mask[27]) return 7'd27;
    if (s_rst_lo_ok && !mask[28]) return 7'd28;
    if (cdc_sarf_ok && !mask[29]) return 7'd29;
    if (cdc_hold_ok && !mask[30]) return 7'd30;
    if (soaq_ok    && !mask[31]) return 7'd31;
    if (topk_ok    && !mask[32]) return 7'd32;
    if (accept_ok  && !mask[33]) return 7'd33;
    if (pack_ok    && !mask[34]) return 7'd34;
    if (bind_ok    && !mask[35]) return 7'd35;
    if (fwd_ok     && !mask[36]) return 7'd36;
    if (lm_ok      && !mask[37]) return 7'd37;
    if (bind_busy_ok && !mask[38]) return 7'd38;
    if (wdma_busy_ok && !mask[39]) return 7'd39;
    if (wdma_done_ok && !mask[40]) return 7'd40;
    if (core_busy_ok && !mask[41]) return 7'd41;
    if (tile_miss_ok && !mask[42]) return 7'd42;
    if (tile_dst_ok  && !mask[43]) return 7'd43;
    if (tile_bst_ok  && !mask[44]) return 7'd44;
    if (tile_req_ok  && !mask[45]) return 7'd45;
    if (sdma_busy_ok && !mask[46]) return 7'd46;
    if (wdma_busy_lat_ok && !mask[47]) return 7'd47;
    if (wdma_own_ui_ok && !mask[48]) return 7'd48;
    if (tile_dma_busy_ok && !mask[49]) return 7'd49;
    if (tile_dma_own_ok  && !mask[50]) return 7'd50;
    if (sdone_ok         && !mask[56]) return 7'd56;
    if (mdone_ok         && !mask[57]) return 7'd57;
    if (busy_hold_ok     && !mask[58]) return 7'd58;
    if (dma_st_ok        && !mask[59]) return 7'd59;
    if (sgo_ok           && !mask[60]) return 7'd60;
    if (wdma_own_f1v_ok  && !mask[61]) return 7'd61;
    if (wdma_grant_f1v_ok && !mask[62]) return 7'd62;
    if (rpath_idle_f1v_ok && !mask[63]) return 7'd63;
    if (mgo_f1v_ok       && !mask[64]) return 7'd64;
    if (cmd_empty_ok     && !mask[65]) return 7'd65;
    if (sbusy_pend_ok    && !mask[66]) return 7'd66;
    if (cmd_st_ok        && !mask[67]) return 7'd67;
    if (cmd_rd_ok        && !mask[68]) return 7'd68;
    if (w_stall_ok && !mask[51]) return 7'd51;
    if (phase_ok   && !mask[52]) return 7'd52;
    if (pred_nz_ok && !mask[53]) return 7'd53;
    if (core_done_ok && !mask[54]) return 7'd54;
    if (pred_ok    && !mask[55]) return 7'd55;
    return 7'd0;
  endfunction

  logic pred_ready;
  logic have_pending;
  logic [6:0] nxt_sel;
  assign pred_ready = bind_100 && (pred_100 != 10'd0);
  assign nxt_sel = hb_next(sent_mask, calib_100, wmem_100, boot_ui_100, core_live_100,
                           owner_100, qgo_100, soarun_100, ar_100, rbeat_100,
                           rbusy_100, ridle_100,
                           rvseen_100, rready1_100, ridok_100, ridbad_100, outst_100,
                           migrv_100, cdcne_100,
                           migar_100, ownwdma_100, cdcar_100, muxcdc_100,
                           cdc_marf_100, cdc_sarv_100, cdc_sarr_100,
                           ar_fifo_ne_100,
                           sticky_m_rst_lo_100, sticky_s_rst_lo_100,
                           cdc_sarf_100, cdc_hold_100,
                           soaq_100, topk_100, accept_100,
                           pack_100, bind_100, fwd_100, lm_100,
                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,
                           tile_miss_100, tile_dst_valid_100, tile_bst_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           mgo_f1v_100, mgo_f1v_100, mgo_f1v_100, mgo_f1v_100,
                           w_stall_100, phase_valid_100,
                           pred_nz_100, core_done_100, pred_ready);
  assign have_pending =
      (!sent_mask[0]) ||
      (calib_100     && !sent_mask[1]) ||
      (wmem_100      && !sent_mask[2]) ||
      (boot_ui_100   && !sent_mask[3]) ||
      (core_live_100 && !sent_mask[4]) ||
      (owner_100     && !sent_mask[5]) ||
      (qgo_100       && !sent_mask[6]) ||
      (soarun_100    && !sent_mask[7]) ||
      (ar_100        && !sent_mask[8]) ||
      (rbeat_100     && !sent_mask[9]) ||
      (rbusy_100     && !sent_mask[10]) ||
      (ridle_100     && !sent_mask[11]) ||
      (rvseen_100    && !sent_mask[12]) ||
      (rready1_100   && !sent_mask[13]) ||
      (ridok_100     && !sent_mask[14]) ||
      (ridbad_100    && !sent_mask[15]) ||
      (outst_100     && !sent_mask[16]) ||
      (migrv_100     && !sent_mask[17]) ||
      (cdcne_100     && !sent_mask[18]) ||
      (migar_100     && !sent_mask[19]) ||
      (ownwdma_100   && !sent_mask[20]) ||
      (cdcar_100     && !sent_mask[21]) ||
      (muxcdc_100    && !sent_mask[22]) ||
      (cdc_marf_100  && !sent_mask[23]) ||
      (cdc_sarv_100  && !sent_mask[24]) ||
      (cdc_sarr_100  && !sent_mask[25]) ||
      (ar_fifo_ne_100 && !sent_mask[26]) ||
      (sticky_m_rst_lo_100 && !sent_mask[27]) ||
      (sticky_s_rst_lo_100 && !sent_mask[28]) ||
      (cdc_sarf_100  && !sent_mask[29]) ||
      (cdc_hold_100  && !sent_mask[30]) ||
      (soaq_100      && !sent_mask[31]) ||
      (topk_100      && !sent_mask[32]) ||
      (accept_100    && !sent_mask[33]) ||
      (pack_100      && !sent_mask[34]) ||
      (bind_100      && !sent_mask[35]) ||
      (fwd_100       && !sent_mask[36]) ||
      (lm_100        && !sent_mask[37]) ||
      (bind_busy_100 && !sent_mask[38]) ||
      (wdma_busy_100 && !sent_mask[39]) ||
      (wdma_done_100 && !sent_mask[40]) ||
      (core_busy_100 && !sent_mask[41]) ||
      (tile_miss_100 && !sent_mask[42]) ||
      (tile_dst_valid_100 && !sent_mask[43]) ||
      (tile_bst_valid_100 && !sent_mask[44]) ||
      (tile_req_valid_100 && !sent_mask[45]) ||
      (tile_req_valid_100 && !sent_mask[46]) ||
      (tile_req_valid_100 && !sent_mask[47]) ||
      (tile_req_valid_100 && !sent_mask[48]) ||
      (tile_req_valid_100 && !sent_mask[49]) ||
      (tile_req_valid_100 && !sent_mask[50]) ||
      (tile_req_valid_100 && !sent_mask[56]) ||
      (tile_req_valid_100 && !sent_mask[57]) ||
      (tile_req_valid_100 && !sent_mask[58]) ||
      (tile_req_valid_100 && !sent_mask[59]) ||
      (tile_req_valid_100 && !sent_mask[60]) ||
      (tile_req_valid_100 && !sent_mask[61]) ||
      (tile_req_valid_100 && !sent_mask[62]) ||
      (tile_req_valid_100 && !sent_mask[63]) ||
      (tile_req_valid_100 && !sent_mask[64]) ||
      (mgo_f1v_100   && !sent_mask[65]) ||
      (mgo_f1v_100   && !sent_mask[66]) ||
      (mgo_f1v_100   && !sent_mask[67]) ||
      (mgo_f1v_100   && !sent_mask[68]) ||
      (w_stall_100   && !sent_mask[51]) ||
      (phase_valid_100 && !sent_mask[52]) ||
      (pred_nz_100   && !sent_mask[53]) ||
      (core_done_100 && !sent_mask[54]) ||
      (pred_ready    && !sent_mask[55]);

  always_ff @(posedge CLK100MHZ) begin
    if (!clk_locked) begin
      ut <= UT_IDLE;
      tx_start <= 1'b0;
      tx_data <= 8'd0;
      tx_i <= 7'd0;
      tx_len <= 6'd0;
      msg_sel <= 6'd0;
      sent_mask <= 69'd0;
      led_sticky <= 4'd0;
      saw_busy <= 1'b0;
    end else begin
      tx_start <= 1'b0;
      // Sticky LEDs: bit0=MIG,1=WMEM,2=SOA/CORE,3=BIND
      if (calib_100) led_sticky[0] <= 1'b1;
      if (wmem_100)  led_sticky[1] <= 1'b1;
      if (boot_ui_100 || core_live_100) led_sticky[2] <= 1'b1;
      if (bind_100)  led_sticky[3] <= 1'b1;

      unique case (ut)
        UT_IDLE: begin
          saw_busy <= 1'b0;
          // F1w: refuse BOOT retransmit when mask[0] already set (hb_next fallback=0)
          if (have_pending && !tx_busy && (nxt_sel != 7'd0 || !sent_mask[0])) begin
            msg_sel <= nxt_sel;
            tx_i <= 7'd0;
            tx_len <= hb_len(nxt_sel);
            ut <= UT_LOAD;
          end else if (&sent_mask[68:0]) begin
            ut <= UT_DONE;
          end
        end
        UT_LOAD: begin
          tx_data <= hb_char(msg_sel, tx_i);
          tx_start <= 1'b1;
          saw_busy <= 1'b0;
          ut <= UT_WAIT_BUSY;
        end
        UT_WAIT_BUSY: begin
          if (tx_busy) begin
            saw_busy <= 1'b1;
            ut <= UT_WAIT_IDLE;
          end
        end
        UT_WAIT_IDLE: begin
          if (!tx_busy) begin
            if (tx_i + 7'd1 >= tx_len)
              ut <= UT_NL_LOAD;
            else begin
              tx_i <= tx_i + 7'd1;
              ut <= UT_LOAD;
            end
          end
        end
        UT_NL_LOAD: begin
          tx_data <= 8'h0A;
          tx_start <= 1'b1;
          saw_busy <= 1'b0;
          ut <= UT_NL_BUSY;
        end
        UT_NL_BUSY: begin
          if (tx_busy) begin
            saw_busy <= 1'b1;
            ut <= UT_NL_IDLE;
          end
        end
        UT_NL_IDLE: begin
          if (!tx_busy) begin
            sent_mask[msg_sel] <= 1'b1;
            ut <= UT_IDLE;
          end
        end
        UT_DONE: ut <= UT_DONE;
        default: ut <= UT_IDLE;
      endcase
    end
  end

  logic unused_rx;
  logic unused_tie;
  assign unused_rx = uart_txd_in;
  assign unused_tie = |{boot_100, soa_core_100, bind_core_100, axi_b_100, dual_err, lm06_active};
  assign led = led_sticky ^ sw;
endmodule
