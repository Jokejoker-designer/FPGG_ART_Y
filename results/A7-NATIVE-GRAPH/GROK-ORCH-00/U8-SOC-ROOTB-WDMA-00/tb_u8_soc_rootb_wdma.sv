// tb_u8_soc_rootb_wdma.sv — U8-SOC-ROOTB-WDMA-00
// SoC-reachable persist (store + persist_axi_bridge) and WDMA (cdc + ddr_tile_dma).
// No SoC top, no MIG, no persist_gen_fast, C7 not treated as commit.
// PROGRAM=NO. Cycle watchdog. Stop at first divergence.
`timescale 1ns / 1ps

module tb_u8_soc_rootb_wdma;
  import a7ng_pkg::*;
  `define CLK_HALF_NS 5
  localparam int unsigned WATCH_CYC = 2000000;
  localparam int unsigned FLUSH_BEATS = 65; // header + 32 slots * 2

  // ---- persist clocks: core 100 MHz, ui 125 MHz (SoC-like dual domain) ----
  logic core_clk, ui_clk, core_rst_n, ui_rst_n;
  initial core_clk = 1'b0;
  always #(`CLK_HALF_NS) core_clk = ~core_clk;
  initial begin
    ui_clk = 1'b0;
    #3;
    forever #4 ui_clk = ~ui_clk;
  end

  integer cyc;
  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  // persist store
  logic learn, freeze, flush, reload, kill, trst;
  logic pbusy, pdone, pnak, boot_done;
  logic [31:0] live_gen;
  logic [63:0] sdig;
  logic wrap_im;
  logic upd_v, upd_r;
  logic [31:0] us, uo;
  logic [7:0]  ur;
  logic signed [3:0] urew;
  logic uk;
  logic lk_go, lk_busy, lk_done, lk_hit;
  logic [31:0] ls, lo;
  logic [7:0]  lr;
  logic signed [7:0] lk_pri, lk_pen;
  logic c7v;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic grant, req, idle, grant_block;
  logic [3:0] stall_aw, stall_w, stall_ar, stall_r, stall_b;
  logic [31:0] awc, arc, bok, wrok, wrerr, rdok, rderr, bwr, brd;
  logic regerr, region_v;
  logic [15:0] fzdrop;

  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic arvalid, arready, rvalid, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  integer n_pdone, n_pnak, n_ram_we, n_c7ack;
  logic pdone_d, pnak_d, ram_we_d, c7v_d;
  logic saw_done, saw_nak;
  integer tmo, i;
  logic [31:0] awc0, bok0, wrok0;

  wire ram_we_w = u_st.ram_we;

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(core_clk), .rst_n(core_rst_n),
    .learn_i(learn), .freeze_i(freeze),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .live_gen_o(live_gen), .sdig_o(sdig), .wrap_imminent_o(wrap_im),
    .upd_valid_i(upd_v), .upd_ready_o(upd_r),
    .upd_subj_i(us), .upd_rel_i(ur), .upd_obj_i(uo),
    .upd_rew_i(urew), .upd_contra_i(uk),
    .lk_go_i(lk_go), .lk_subj_i(ls), .lk_rel_i(lr), .lk_obj_i(lo),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(1'b1),
    .c7_addr_o(c7a), .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  // SoC wiring: persist_axi_bridge, c7_valid_i tied 0 (C7 observe-only).
  a7ng_persist_axi_bridge u_br (
    .core_clk(core_clk), .core_rst_n(core_rst_n),
    .ddr_req_i(ddr_req), .ddr_we_i(ddr_we), .ddr_addr_i(ddr_addr),
    .ddr_wdata_i(ddr_wdata), .ddr_rdata_o(ddr_rdata), .ddr_ack_o(ddr_ack),
    .freeze_i(freeze),
    .c7_valid_i(1'b0), .c7_addr_i(32'd0), .c7_ready_o(),
    .ui_clk(ui_clk), .ui_rst_n(ui_rst_n),
    .grant_i(grant), .req_o(req), .idle_o(idle),
    .m_axi_awid(awid), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen),
    .m_axi_awsize(awsize), .m_axi_awburst(awburst),
    .m_axi_awvalid(awvalid), .m_axi_awready(awready),
    .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
    .m_axi_wvalid(wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready),
    .wr_ok_o(wrok), .wr_err_o(wrerr), .rd_ok_o(rdok), .rd_err_o(rderr),
    .bytes_wr_o(bwr), .bytes_rd_o(brd), .region_err_o(regerr), .freeze_drop_o(fzdrop)
  );

  tb_u8_persist_axi_mem u_mem (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .stall_aw_i(stall_aw), .stall_w_i(stall_w), .stall_ar_i(stall_ar),
    .stall_r_i(stall_r), .stall_b_i(stall_b),
    .aw_count_o(awc), .ar_count_o(arc), .b_ok_o(bok),
    .region_violation_o(region_v),
    .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
    .s_axi_awsize(awsize), .s_axi_awburst(awburst),
    .s_axi_awvalid(awvalid && grant), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
    .s_axi_wvalid(wvalid && grant), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid && grant), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  // persist_owner_ui analog: grant while req, drop when idle && !req. stall = grant_block.
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n)
      grant <= 1'b0;
    else if (req && !grant && !grant_block)
      grant <= 1'b1;
    else if (grant && idle && !req)
      grant <= 1'b0;
  end

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      n_pdone <= 0; n_pnak <= 0; n_ram_we <= 0; n_c7ack <= 0;
      pdone_d <= 0; pnak_d <= 0; ram_we_d <= 0; c7v_d <= 0;
    end else begin
      if (pdone && !pdone_d) n_pdone <= n_pdone + 1;
      if (pnak && !pnak_d) n_pnak <= n_pnak + 1;
      if (ram_we_w && !ram_we_d) n_ram_we <= n_ram_we + 1;
      if (c7v && !c7v_d) n_c7ack <= n_c7ack + 1;
      pdone_d <= pdone;
      pnak_d <= pnak;
      ram_we_d <= ram_we_w;
      c7v_d <= c7v;
    end
  end

  // ---- WDMA slice ----
  logic m_owner, m_go, m_go_ready, m_wr;
  logic [27:0] m_addr;
  logic [31:0] m_bytes;
  logic m_w_valid, m_w_ready;
  logic [127:0] m_w_data;
  logic m_r_valid, m_r_ready;
  logic [127:0] m_r_data;
  logic m_busy, m_done;
  logic s_owner, s_go, s_wr;
  logic [27:0] s_addr;
  logic [31:0] s_bytes;
  logic s_w_valid, s_w_ready;
  logic [127:0] s_w_data;
  logic s_r_valid, s_r_ready;
  logic [127:0] s_r_data;
  logic s_busy, s_done;
  logic dma_busy, dma_done, dma_under, axi_berr, axi_rerr;
  logic [2:0] dma_st;
  logic d_awvalid, d_awready, d_wvalid, d_wready, d_wlast, d_bvalid, d_bready;
  logic d_arvalid, d_arready, d_rvalid, d_rready, d_rlast;
  logic [27:0] d_awaddr, d_araddr;
  logic [7:0] d_awlen, d_arlen;
  logic [127:0] d_wdata, d_rdata;
  logic [15:0] d_wstrb;
  integer cmd_wr_count, s_go_count, wdma_b_ok, m_done_count;
  integer g_cmd0, g_sgo0, g_done0, g_bok0;
  logic cmd_wr_d, s_go_d, m_done_d;

  wire cmd_wr_en         = u_cdc.cmd_wr_en;
  wire cmd_hold_valid    = u_cdc.cmd_hold_valid;
  wire cmd_hold_overflow = u_cdc.cmd_hold_overflow;
  wire cmd_empty         = u_cdc.cmd_empty;

  a7ng_wdma_cdc u_cdc (
    .m_clk(core_clk), .m_rst_n(core_rst_n),
    .m_owner(m_owner), .m_go(m_go), .m_go_ready(m_go_ready), .m_wr(m_wr),
    .m_addr(m_addr), .m_bytes(m_bytes),
    .m_w_valid(m_w_valid), .m_w_ready(m_w_ready), .m_w_data(m_w_data),
    .m_r_valid(m_r_valid), .m_r_ready(m_r_ready), .m_r_data(m_r_data),
    .m_busy(m_busy), .m_done(m_done),
    .dbg_s_done_sticky(), .dbg_m_done_sticky(), .dbg_busy_hold(),
    .dbg_s_go_sticky(), .dbg_m_go_sticky(), .dbg_sbusy_pend(),
    .dbg_cmd_st(), .dbg_cmd_empty_mgo(), .dbg_cmd_rd_sticky(),
    .s_clk(ui_clk), .s_rst_n(ui_rst_n),
    .s_owner(s_owner),
    .s_go(s_go), .s_wr(s_wr), .s_addr(s_addr), .s_bytes(s_bytes),
    .s_w_valid(s_w_valid), .s_w_ready(s_w_ready), .s_w_data(s_w_data),
    .s_r_valid(s_r_valid), .s_r_ready(s_r_ready), .s_r_data(s_r_data),
    .s_busy(s_busy), .s_done(s_done),
    .m_tile_dst(3'd0),
    .s_dma_idle(dma_st == 3'd0)
  );

  ddr_tile_dma u_dma (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .go(s_go), .wr(s_wr), .addr(s_addr), .bytes(s_bytes),
    .busy(dma_busy), .done(dma_done), .underflow(dma_under),
    .axi_berr(axi_berr), .axi_rerr(axi_rerr),
    .w_valid(s_w_valid), .w_ready(s_w_ready), .w_data(s_w_data),
    .r_valid(s_r_valid), .r_ready(s_r_ready), .r_data(s_r_data),
    .m_axi_awid(), .m_axi_awaddr(d_awaddr), .m_axi_awlen(d_awlen),
    .m_axi_awsize(), .m_axi_awburst(),
    .m_axi_awvalid(d_awvalid), .m_axi_awready(d_awready),
    .m_axi_wdata(d_wdata), .m_axi_wstrb(d_wstrb), .m_axi_wlast(d_wlast),
    .m_axi_wvalid(d_wvalid), .m_axi_wready(d_wready),
    .m_axi_bid(4'd0), .m_axi_bresp(2'b00), .m_axi_bvalid(d_bvalid), .m_axi_bready(d_bready),
    .m_axi_arid(), .m_axi_araddr(d_araddr), .m_axi_arlen(d_arlen),
    .m_axi_arsize(), .m_axi_arburst(),
    .m_axi_arvalid(d_arvalid), .m_axi_arready(d_arready),
    .m_axi_rid(4'd0), .m_axi_rdata(d_rdata), .m_axi_rresp(2'b00),
    .m_axi_rlast(d_rlast), .m_axi_rvalid(d_rvalid), .m_axi_rready(d_rready),
    .dbg_st(dma_st)
  );

  assign s_busy = dma_busy;
  assign s_done = dma_done;
  assign d_rdata = 128'hA5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5;
  assign m_r_ready = 1'b1;

  // WDMA AXI slave: always-ready write/read, B/R after handshake. Counts B OK.
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      d_awready <= 1'b1; d_wready <= 1'b1; d_bvalid <= 1'b0;
      d_arready <= 1'b1; d_rvalid <= 1'b0; d_rlast <= 1'b0;
      wdma_b_ok <= 0;
    end else begin
      d_awready <= 1'b1;
      d_wready  <= 1'b1;
      d_arready <= 1'b1;
      if (d_wvalid && d_wready && d_wlast)
        d_bvalid <= 1'b1;
      if (d_bvalid && d_bready) begin
        d_bvalid <= 1'b0;
        wdma_b_ok <= wdma_b_ok + 1;
      end
      if (d_arvalid && d_arready) begin
        d_rvalid <= 1'b1;
        d_rlast  <= 1'b1;
      end
      if (d_rvalid && d_rready) begin
        d_rvalid <= 1'b0;
        d_rlast  <= 1'b0;
      end
    end
  end

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      cmd_wr_count <= 0; m_done_count <= 0;
      cmd_wr_d <= 0; m_done_d <= 0;
    end else begin
      if (cmd_wr_en && !cmd_wr_d) cmd_wr_count <= cmd_wr_count + 1;
      if (m_done && !m_done_d) m_done_count <= m_done_count + 1;
      cmd_wr_d <= cmd_wr_en;
      m_done_d <= m_done;
    end
  end
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      s_go_count <= 0; s_go_d <= 0;
    end else begin
      if (s_go && !s_go_d) s_go_count <= s_go_count + 1;
      s_go_d <= s_go;
    end
  end

  task automatic diverge(input string cls, input string det);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", cls, det, cyc);
      #20 $finish;
    end
  endtask

  task automatic wait_idle_p(input int lim);
    begin
      tmo = 0;
      while ((pbusy || !boot_done || !idle) && tmo < lim) begin
        @(posedge core_clk); tmo++;
      end
      if (tmo >= lim) diverge("TIMEOUT", "persist idle/boot");
    end
  endtask

  task automatic wait_boot;
    begin
      tmo = 0;
      while (!boot_done && tmo < 40000) begin @(posedge core_clk); tmo++; end
      if (!boot_done) diverge("TIMEOUT", "boot_done");
      wait_idle_p(40000);
    end
  endtask

  task automatic issue_upd(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while (!upd_r && tmo < 8000) begin @(posedge core_clk); tmo++; end
      if (!upd_r) diverge("TIMEOUT", "upd_ready");
      @(negedge core_clk);
      us = s; ur = 8'd1; uo = o; urew = 4'sd1; uk = 1'b0; upd_v = 1'b1;
      @(posedge core_clk); @(negedge core_clk); upd_v = 1'b0;
      saw_done = 0; saw_nak = 0;
      tmo = 0;
      while (!saw_done && !saw_nak && tmo < 8000) begin
        @(posedge core_clk);
        if (pdone) saw_done = 1;
        if (pnak) saw_nak = 1;
        tmo++;
      end
      if (!saw_done && !saw_nak) diverge("TIMEOUT", "upd done/nak");
      @(posedge core_clk);
    end
  endtask

  task automatic do_lk(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while ((pbusy || lk_busy) && tmo < 8000) begin @(posedge core_clk); tmo++; end
      @(negedge core_clk); ls = s; lr = 8'd1; lo = o; lk_go = 1'b1;
      @(posedge core_clk); @(negedge core_clk); lk_go = 1'b0;
      tmo = 0;
      while (!lk_done && tmo < 8000) begin @(posedge core_clk); tmo++; end
      if (!lk_done) diverge("TIMEOUT", "lookup");
      @(posedge core_clk);
    end
  endtask

  task automatic pulse_flush;
    begin
      @(negedge core_clk); flush = 1'b1;
      @(posedge core_clk); @(negedge core_clk); flush = 1'b0;
      tmo = 0;
      while (pbusy && tmo < 80000) begin @(posedge core_clk); tmo++; end
      if (pbusy) diverge("TIMEOUT", "flush busy");
      tmo = 0;
      while (!idle && tmo < 8000) begin @(posedge ui_clk); tmo++; end
    end
  endtask

  task automatic pulse_reload;
    begin
      @(negedge core_clk); reload = 1'b1;
      @(posedge core_clk); @(negedge core_clk); reload = 1'b0;
      wait_boot();
    end
  endtask

  task automatic pulse_kill;
    begin
      @(negedge core_clk); kill = 1'b1;
      @(posedge core_clk); @(negedge core_clk); kill = 1'b0;
      @(posedge core_clk);
    end
  endtask

  // Dest-like producer: wait CDC m_go_ready, one-cycle m_go (weight_tile803k D_GO).
  task automatic dest_pulse_go;
    begin
      tmo = 0;
      while (!m_go_ready && tmo < 8000) begin @(posedge core_clk); tmo++; end
      if (!m_go_ready) diverge("TIMEOUT", "m_go_ready");
      @(negedge core_clk); m_go = 1'b1;
      @(posedge core_clk); @(negedge core_clk); m_go = 1'b0;
    end
  endtask

  initial begin
    tmo = 0;
    while (tmo < WATCH_CYC) begin @(posedge core_clk); tmo++; end
    $display("FAIL cycle watchdog cyc=%0d", cyc);
    $finish;
  end

  initial begin
    core_rst_n = 0; ui_rst_n = 0;
    learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; uk = 0; urew = 0; us = 0; uo = 0; ur = 1; lk_go = 0;
    grant_block = 0;
    stall_aw = 4'd2; stall_w = 4'd1; stall_ar = 4'd2; stall_r = 4'd1; stall_b = 4'd3;
    m_owner = 0; m_go = 0; m_wr = 1; m_addr = 28'h000_2000; m_bytes = 32'd16;
    m_w_valid = 0; m_w_data = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
    $display("U8-SOC-ROOTB-WDMA-00 START");

    repeat (8) @(posedge ui_clk);
    ui_rst_n = 1;
    repeat (4) @(posedge core_clk);
    core_rst_n = 1;

    // CASE A: stall grant during boot (AXI read header / CLR)
    grant_block = 1;
    tmo = 0;
    while (!req && tmo < 4000) begin @(posedge ui_clk); tmo++; end
    if (!req) diverge("TIMEOUT", "boot persist req");
    $display("CASE_A_STALL_GRANT req=1 grant=0 cyc=%0d", cyc);
    repeat (40) @(posedge ui_clk);
    if (awc != 0 && grant == 0)
      diverge("FALSE_COMMIT", "AXI while grant blocked");
    grant_block = 0;
    wait_boot();
    $display("CASE_A_BOOT_STALL PASS boot_done=1 wr_ok=%0d rd_ok=%0d aw=%0d ar=%0d",
             wrok, rdok, awc, arc);

    // CASE B: 3 BRAM updates — persist_done ⇔ commit_seq/ack_count, no AXI write
    awc0 = awc; bok0 = bok; wrok0 = wrok;
    for (i = 0; i < 3; i++) begin
      issue_upd(32'hA000 + i, 32'hB000 + i);
      if (!saw_done) diverge("ACK_WITHOUT_COMMIT", "fill3 must persist_done");
      if (saw_nak) diverge("FALSE_NAK", "fill3");
    end
    if (c7seq !== 16'd3 || c7cnt !== 16'd3)
      diverge("ACK_COUNT_WITHOUT_COMMIT", "seq/ack != 3");
    if (awc !== awc0 || bok !== bok0)
      diverge("FALSE_DDR_COMMIT", "P_UPD must not AXI-write");
    $display("CASE_B_UPD_ACK_EQ_COMMIT PASS seq=%0d ack=%0d pdone=%0d axi_aw=%0d",
             c7seq, c7cnt, n_pdone, awc);

    // CASE C: store-full overflow (eviction/capacity) — 33rd NAK, no seq bump
    for (i = 3; i < 32; i++) begin
      issue_upd(32'hA000 + i, 32'hB000 + i);
      if (!saw_done) diverge("EXISTING_KEY_UPDATE_REGRESSION", "fill32");
    end
    issue_upd(32'hA000 + 32, 32'hB000 + 32);
    $display("CASE_C_STORE_FULL done=%0d nak=%0d seq=%0d ack=%0d",
             saw_done, saw_nak, c7seq, c7cnt);
    if (saw_done) diverge("PERSIST_DONE_WITHOUT_COMMIT", "33rd");
    if (!saw_nak) diverge("INTERFACE_EVIDENCE_GAP", "33rd must NAK");
    if (c7seq !== 16'd32 || c7cnt !== 16'd32)
      diverge("COMMIT_SEQ_WITHOUT_WRITE", "store-full");
    do_lk(32'hA000 + 32, 32'hB000 + 32);
    if (lk_hit) diverge("FALSE_COMMIT_SIGNAL", "33rd hit");
    $display("CASE_C_OVERFLOW_NAK PASS");

    // CASE D: FLUSH with AXI stall — one persist_done, BRESP count == beats
    awc0 = awc; bok0 = bok; wrok0 = wrok;
    stall_aw = 4'd3; stall_b = 4'd4;
    pulse_flush();
    $display("CASE_D_FLUSH_STALL done_delta=%0d aw_delta=%0d b_ok_delta=%0d wr_ok_delta=%0d",
             n_pdone, awc - awc0, bok - bok0, wrok - wrok0);
    if ((awc - awc0) !== FLUSH_BEATS)
      diverge("FLUSH_BEAT_MISMATCH", "aw != 65");
    if ((bok - bok0) !== FLUSH_BEATS)
      diverge("ACK_WITHOUT_COMMIT", "BRESP != AW");
    if ((wrok - wrok0) !== FLUSH_BEATS)
      diverge("ACK_WITHOUT_COMMIT", "wr_ok != 65");
    if (region_v || regerr)
      diverge("REGION", "flush AXI");
    $display("CASE_D_FLUSH_STALL PASS beats=%0d", FLUSH_BEATS);

    // CASE E: kill + reload through AXI — ranking/identity restore
    pulse_kill();
    do_lk(32'hA000, 32'hB000);
    if (lk_hit) diverge("KILL_NOT_CLEARED", "hit after kill");
    pulse_reload();
    for (i = 0; i < 3; i++) begin
      do_lk(32'hA000 + i, 32'hB000 + i);
      if (!lk_hit) diverge("FLUSH_RELOAD_MISMATCH", "miss after reload");
    end
    do_lk(32'hA000 + 32, 32'hB000 + 32);
    if (lk_hit) diverge("FLUSH_RELOAD_MISMATCH", "33rd appeared");
    $display("CASE_E_FLUSH_RELOAD PASS");

    // CASE G: WDMA delayed grant, dest-like pulse, 128 B (DMA min burst).
    g_cmd0 = cmd_wr_count; g_sgo0 = s_go_count; g_done0 = m_done_count; g_bok0 = wdma_b_ok;
    m_owner = 1'b0; m_wr = 1'b1; m_addr = 28'h000_2000; m_bytes = 32'd128;
    dest_pulse_go();
    tmo = 0;
    while (!cmd_hold_valid && tmo < 64) begin @(posedge core_clk); tmo++; end
    if (!cmd_hold_valid) diverge("TIMEOUT", "wdma hold");
    if (m_go_ready) diverge("READY_WHILE_HOLD", "m_go_ready must drop");
    repeat (8) @(posedge core_clk);
    if ((cmd_wr_count - g_cmd0) != 0) diverge("UNOWNED_CMD", "write before grant");
    m_owner = 1'b1;
    m_w_valid = 1'b1;
    tmo = 0;
    while ((m_done_count - g_done0) == 0 && tmo < 8000) begin
      @(posedge core_clk); tmo++;
    end
    m_w_valid = 1'b0;
    $display("CASE_G_WDMA_STALL cmd_wr=%0d s_go=%0d m_done=%0d b_ok=%0d ovf=%0d dma_st=%0d under=%0d ready=%0d",
             cmd_wr_count - g_cmd0, s_go_count - g_sgo0, m_done_count - g_done0,
             wdma_b_ok - g_bok0, cmd_hold_overflow, dma_st, dma_under, m_go_ready);
    if ((cmd_wr_count - g_cmd0) !== 1) diverge("WDMA_CMD_COUNT", "expect 1");
    if ((s_go_count - g_sgo0) !== 1) diverge("WDMA_S_GO_COUNT", "expect 1");
    if ((m_done_count - g_done0) !== 1) diverge("WDMA_DONE_COUNT", "expect 1");
    if ((wdma_b_ok - g_bok0) !== 1)
      diverge("WDMA_ACK_NE_COMMIT", "m_done vs BRESP");
    $display("CASE_G_WDMA_STALL PASS ACK=1 BRESP=1");
    m_owner = 1'b0;
    tmo = 0;
    while ((cmd_hold_valid || (dma_st != 3'd0)) && tmo < 4000) begin
      @(posedge core_clk); tmo++;
    end

    // CASE H: dest-like wait on m_go_ready. Unowned first GO occupies hold;
    // producer must not pulse while !ready (no silent drop). Grant, then
    // second GO after ready; both commit.
    g_cmd0 = cmd_wr_count; g_sgo0 = s_go_count; g_done0 = m_done_count; g_bok0 = wdma_b_ok;
    m_owner = 1'b0; m_wr = 1'b1; m_addr = 28'h000_2000; m_bytes = 32'd128;
    dest_pulse_go();
    tmo = 0;
    while (!cmd_hold_valid && tmo < 64) begin @(posedge core_clk); tmo++; end
    if (!cmd_hold_valid) diverge("TIMEOUT", "h hold");
    if (m_go_ready) diverge("READY_WHILE_HOLD", "H first");
    repeat (8) @(posedge core_clk);
    if (m_go_ready || cmd_hold_overflow)
      diverge("WDMA_SILENT_DROP", "ready or overflow while dest waited");
    $display("CASE_H_BACKPRESSURE ready=0 hold=1 ovf=%0d", cmd_hold_overflow);
    m_owner = 1'b1;
    m_w_valid = 1'b1;
    m_addr = 28'h000_3000;
    dest_pulse_go();
    tmo = 0;
    while ((m_done_count - g_done0) < 2 && tmo < 8000) begin
      @(posedge core_clk); tmo++;
    end
    m_w_valid = 1'b0;
    $display("CASE_H_WDMA_READY_WAIT ovf=%0d cmd_wr=%0d s_go=%0d m_done=%0d b_ok=%0d",
             cmd_hold_overflow, cmd_wr_count - g_cmd0, s_go_count - g_sgo0,
             m_done_count - g_done0, wdma_b_ok - g_bok0);
    if (cmd_hold_overflow)
      diverge("WDMA_SILENT_DROP", "cmd_hold_overflow after dest wait");
    if ((cmd_wr_count - g_cmd0) !== 2) diverge("WDMA_CMD_COUNT", "H expect 2");
    if ((s_go_count - g_sgo0) !== 2) diverge("WDMA_S_GO_COUNT", "H expect 2");
    if ((m_done_count - g_done0) !== 2) diverge("WDMA_DONE_COUNT", "H expect 2");
    if ((wdma_b_ok - g_bok0) !== 2)
      diverge("WDMA_ACK_NE_COMMIT", "H m_done vs BRESP");
    $display("CASE_H_WDMA_READY_WAIT PASS ACK=2 BRESP=2 ovf=0");
    m_owner = 1'b0;
    tmo = 0;
    while ((cmd_hold_valid || (dma_st != 3'd0)) && tmo < 4000) begin
      @(posedge core_clk); tmo++;
    end

    // CASE I: mid-txn reset on the same WDMA path. In-flight GO, both-domain
    // rst, no leftover hold/overflow, one post-rst commit.
    m_owner = 1'b1; m_wr = 1'b1; m_addr = 28'h000_4000; m_bytes = 32'd128;
    m_w_valid = 1'b1;
    dest_pulse_go();
    tmo = 0;
    while ((dma_st == 3'd0) && tmo < 4000) begin @(posedge ui_clk); tmo++; end
    if (dma_st == 3'd0) diverge("TIMEOUT", "I in-flight");
    $display("CASE_I_MID_RST dma_st=%0d hold=%0d cmd_wr=%0d",
             dma_st, cmd_hold_valid, cmd_wr_count);
    core_rst_n = 1'b0; ui_rst_n = 1'b0;
    m_go = 1'b0; m_owner = 1'b0; m_w_valid = 1'b0;
    repeat (16) @(posedge core_clk);
    repeat (16) @(posedge ui_clk);
    ui_rst_n = 1'b1;
    repeat (8) @(posedge core_clk);
    core_rst_n = 1'b1;
    repeat (64) @(posedge core_clk);
    repeat (80) @(posedge ui_clk);
    $display("CASE_I_AFTER_RST hold=%0d ovf=%0d dma_st=%0d ready=%0d",
             cmd_hold_valid, cmd_hold_overflow, dma_st, m_go_ready);
    if (cmd_hold_valid) diverge("GHOST_HOLD", "hold after rst");
    if (cmd_hold_overflow) diverge("GHOST_OVERFLOW", "ovf after rst");
    if (dma_st != 3'd0) diverge("GHOST_DMA", "dma_st after rst");
    if (!m_go_ready) diverge("READY_AFTER_RST", "m_go_ready");
    g_cmd0 = cmd_wr_count; g_sgo0 = s_go_count; g_done0 = m_done_count; g_bok0 = wdma_b_ok;
    m_owner = 1'b1; m_addr = 28'h000_5000; m_bytes = 32'd128;
    m_w_valid = 1'b1;
    dest_pulse_go();
    tmo = 0;
    while ((m_done_count - g_done0) == 0 && tmo < 8000) begin
      @(posedge core_clk); tmo++;
    end
    m_w_valid = 1'b0;
    $display("CASE_I_POST_RST cmd_wr=%0d s_go=%0d m_done=%0d b_ok=%0d ovf=%0d",
             cmd_wr_count - g_cmd0, s_go_count - g_sgo0, m_done_count - g_done0,
             wdma_b_ok - g_bok0, cmd_hold_overflow);
    if ((cmd_wr_count - g_cmd0) !== 1) diverge("WDMA_CMD_COUNT", "I expect 1");
    if ((s_go_count - g_sgo0) !== 1) diverge("WDMA_S_GO_COUNT", "I expect 1");
    if ((m_done_count - g_done0) !== 1) diverge("WDMA_DONE_COUNT", "I expect 1");
    if ((wdma_b_ok - g_bok0) !== 1)
      diverge("WDMA_ACK_NE_COMMIT", "I m_done vs BRESP");
    if (cmd_hold_overflow) diverge("WDMA_SILENT_DROP", "I overflow");
    $display("CASE_I_MID_TXN_RESET PASS ACK=1 BRESP=1");

    $display("U8_SOC_ROOTB_WDMA_PASS");
    #20 $finish;
  end
endmodule
