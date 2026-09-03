// P2-G1G5-FULLCHIP-MIG-PERSIST-01. PROGRAM=NO.
// G4 7 cells through AXI (B OKAY / R+RLAST OK). BRAM kill, DDR retained.
`timescale 1ns / 1ps

module tb_a7ng_persist_axi_bridge;
  import a7ng_pkg::*;
  localparam node_id_t KA = 32'h1000;
  localparam node_id_t KB = 32'h1008;

  logic clk, rst_n, learn, freeze;
  logic qv, qr, sv, sr;
  logic [7:0] qid, dig_cyc;
  node_id_t top_id [8];
  score_t   top_s  [8];
  logic [31:0] evs, evo, c7a, c8g;
  logic [7:0] evr;
  logic pending;
  logic [15:0] txn, echo;
  logic rew_v, echo_v, rew_rdy, ack_v, c5, c7v, c7rdy;
  logic signed [3:0] rew;
  logic [2:0] ack;
  logic [63:0] c8d;
  logic flush, reload, kill, trst, wimm, pbusy, pdone;
  logic ddr_req, ddr_we, ddr_ack;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic grant, req, idle, mem_rst_n;
  logic [3:0] stall_aw, stall_w, stall_ar, stall_r, stall_b;
  logic inj_b, inj_r, inj_nl;
  logic saw_b, saw_rr, saw_nl, region_v;
  logic [31:0] awc, arc, wrok, wrerr, rdok, rderr, bwr, brd;
  logic regerr;
  logic [15:0] fzdrop;

  logic [3:0] awid; logic [27:0] awaddr; logic [7:0] awlen;
  logic [2:0] awsize; logic [1:0] awburst; logic awvalid, awready;
  logic [127:0] wdata; logic [15:0] wstrb; logic wlast, wvalid, wready;
  logic [3:0] bid; logic [1:0] bresp; logic bvalid, bready;
  logic [3:0] arid; logic [27:0] araddr; logic [7:0] arlen;
  logic [2:0] arsize; logic [1:0] arburst; logic arvalid, arready;
  logic [3:0] rid; logic [127:0] rdata; logic [1:0] rresp; logic rlast, rvalid, rready;

  a7ng_persist_gen_fast #(.WRAP_LIMIT(32'd6)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .query_valid_i(qv), .query_ready_o(qr), .query_id_i(qid),
    .snap_valid_o(sv), .snap_ready_i(sr),
    .topk_id_o(top_id), .topk_score_o(top_s),
    .ev_subj_o(evs), .ev_rel_o(evr), .ev_obj_o(evo),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_o(ack),
    .c5_consume_o(c5),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(c7rdy), .c7_addr_o(c7a),
    .c8_gen_o(c8g), .c8_sdig_o(c8d), .dig_cyc_o(dig_cyc),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst), .wrap_imminent_o(wimm),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_persist_axi_bridge u_br (
    .core_clk(clk), .core_rst_n(rst_n),
    .ddr_req_i(ddr_req), .ddr_we_i(ddr_we), .ddr_addr_i(ddr_addr),
    .ddr_wdata_i(ddr_wdata), .ddr_rdata_o(ddr_rdata), .ddr_ack_o(ddr_ack),
    .freeze_i(freeze), .c7_valid_i(c7v), .c7_addr_i(c7a), .c7_ready_o(c7rdy),
    .ui_clk(clk), .ui_rst_n(rst_n), .grant_i(grant), .req_o(req), .idle_o(idle),
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

  tb_a7ng_persist_axi_mem u_mem (
    .clk(clk), .rst_n(mem_rst_n),
    .stall_aw_i(stall_aw), .stall_w_i(stall_w), .stall_ar_i(stall_ar),
    .stall_r_i(stall_r), .stall_b_i(stall_b),
    .inj_bresp_i(inj_b), .inj_rresp_i(inj_r), .inj_no_rlast_i(inj_nl),
    .saw_bresp_err_o(saw_b), .saw_rresp_err_o(saw_rr), .saw_no_rlast_o(saw_nl),
    .aw_count_o(awc), .ar_count_o(arc), .region_violation_o(region_v),
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

  initial clk = 0;
  always #40 clk = ~clk;
  // DDR beat monitor removed after FLUSH_RELOAD diagnosis.

  integer fails, i, rA, rB;
  logic signed [15:0] sA, sB;
  logic [63:0] adig, bdig, sdig0;
  logic [31:0] gen0, bwr0, brd0;

  function automatic int rank_of(input node_id_t id);
    rank_of = 0;
    for (int k = 0; k < 8; k++)
      if (top_id[k] == id) rank_of = k + 1;
  endfunction
  function automatic logic signed [15:0] score_of(input node_id_t id);
    score_of = 0;
    for (int k = 0; k < 8; k++)
      if (top_id[k] == id) score_of = top_s[k];
  endfunction

  task automatic wait_boot;
    integer g;
    begin
      g = 0;
      while ((!qr || pbusy) && g < 8000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL boot/query_ready"); fails++; end
    end
  endtask

  task automatic pulse_persist(ref logic sig);
    integer g;
    begin
      g = 0;
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      while (pbusy && g < 8000) begin @(posedge clk); g = g + 1; end
      if (pbusy) begin $display("FAIL persist busy timeout"); fails = fails + 1; end
      @(posedge clk);
    end
  endtask

  task automatic do_query(input logic [7:0] q);
    integer g;
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!sv && g < 12000) begin @(posedge clk); g++; end
      if (!sv) begin $display("FAIL no snap q=%0d", q); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic send_rew(input logic signed [3:0] r);
    integer g;
    begin
      g = 0;
      while (!pending && g < 2000) begin @(posedge clk); g++; end
      if (!pending) begin $display("FAIL no pending"); fails++; end
      @(negedge clk); rew = r; rew_v = 1; echo_v = 1; echo = txn;
      @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 ACK after reward"); fails++; end
      g = 0;
      while (c7v && g < 8000) begin @(posedge clk); g++; end
    end
  endtask

  task automatic learn_map_a;
    begin
      do_query(8'd1);
      send_rew(4'sd3);
      @(posedge clk);
      do_query(8'd2);
    end
  endtask
  task automatic learn_map_b;
    begin
      do_query(8'd5);
      send_rew(4'sd3);
      @(posedge clk);
      do_query(8'd6);
    end
  endtask

  task automatic cell_rst;
    begin
      rst_n = 0; qv = 0; rew_v = 0; echo_v = 0; freeze = 0;
      mem_rst_n = 1'b0;
      flush = 0; reload = 0; kill = 0; trst = 0;
      inj_b = 0; inj_r = 0; inj_nl = 0;
      stall_aw = 0; stall_w = 0; stall_ar = 0; stall_r = 0; stall_b = 0;
      repeat (8) @(posedge clk);
      mem_rst_n = 1'b1;
      rst_n = 1;
      wait_boot;
    end
  endtask

  initial begin
    #40000000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0; learn = 1; freeze = 0; sr = 1; grant = 1;
    qv = 0; rew_v = 0; echo_v = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    stall_aw = 0; stall_w = 0; stall_ar = 0; stall_r = 0; stall_b = 0;
    inj_b = 0; inj_r = 0; inj_nl = 0;
    rst_n = 0; mem_rst_n = 1'b0;
    repeat (6) @(posedge clk);
    mem_rst_n = 1'b1;

    cell_rst;
    learn_map_a;
    rA = rank_of(KA); sA = score_of(KA); gen0 = c8g; sdig0 = c8d;
    $display("FR A vis rank=%0d score=%0d GEN=%0d SDIG=%h", rA, sA, c8g, c8d);
    if (rA == 0 || sA <= 39 || c8g == 0 || $isunknown(c8d) || $isunknown(c8g))
      begin $display("FAIL FR A not visible"); fails++; end
    pulse_persist(flush);
    pulse_persist(kill);
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin
      $display("FAIL FR A still in BRAM after kill"); fails++;
    end
    pulse_persist(reload);
    wait_boot;
    do_query(8'd2);
    rB = rank_of(KA); sB = score_of(KA);
    $display("FR reload vis rank=%0d score=%0d GEN=%0d SDIG=%h", rB, sB, c8g, c8d);
    if (c8g != gen0 || c8g == 0 || $isunknown(c8g)) begin $display("FAIL FR GEN"); fails++; end
    if (c8d !== sdig0 || $isunknown(c8d)) begin $display("FAIL FR SDIG"); fails++; end
    if (rB == 0 || sB <= 39) begin $display("FAIL FR A lost"); fails++; end
    if (fails == 0) $display("CELL_FLUSH_RELOAD PASS");
    else $display("CELL_FLUSH_RELOAD FAIL");

    cell_rst;
    learn_map_a;
    gen0 = c8g; sdig0 = c8d; rA = rank_of(KA); sA = score_of(KA);
    do_query(8'd1);
    @(negedge clk);
    freeze = 1;
    rew = 4'sd2; rew_v = 1; echo_v = 1; echo = txn;
    @(posedge clk);
    @(negedge clk); rew_v = 0; echo_v = 0;
    begin : fz_ack
      integer ga;
      ga = 0;
      while (!ack_v && ga < 40) begin @(posedge clk); ga = ga + 1; end
      if (ack != 3'd5)
        begin $display("FAIL FZ ack=%0d want DROP=5", ack); fails++; end
    end
    begin : fz_c7
      integer gc7;
      for (gc7 = 0; gc7 < 16; gc7 = gc7 + 1) begin
        @(posedge clk);
        if (c7v) begin $display("FAIL FZ C7 write ACK under freeze"); fails++; end
        if (awvalid) begin $display("FAIL FZ AXI AW under freeze"); fails++; end
      end
    end
    do_query(8'd2);
    if (c8g != gen0 || c8d !== sdig0) begin $display("FAIL FZ C8 moved"); fails++; end
    if (rank_of(KA) != rA || score_of(KA) != sA) begin $display("FAIL FZ C9 moved"); fails++; end
    freeze = 0;
    $display("CELL_FREEZE_BLOCKS_WRITE done ack=%0d awc=%0d", ack, awc);

    cell_rst;
    learn_map_a;
    adig = c8d; gen0 = c8g;
    pulse_persist(trst);
    if (c8g != gen0 + 1 || c8g == 0) begin $display("FAIL TR GEN"); fails++; end
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin $display("FAIL TR A still visible"); fails++; end
    $display("TR GEN %0d->%0d Ascore=%0d", gen0, c8g, score_of(KA));
    $display("CELL_TRAIN_RESET_FORGETS_A done");

    cell_rst;
    learn_map_a; adig = c8d;
    pulse_persist(trst);
    learn_map_b; bdig = c8d;
    do_query(8'd6);
    rB = rank_of(KB); sB = score_of(KB);
    if (rB == 0 || sB <= 39) begin $display("FAIL B not visible rank=%0d score=%0d", rB, sB); fails++; end
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin $display("FAIL B retains A"); fails++; end
    if (adig === bdig || $isunknown(adig) || $isunknown(bdig)) begin $display("FAIL ADIG/BDIG"); fails++; end
    $display("ADIG=%h BDIG=%h Bscore=%0d Ascore_after=%0d", adig, bdig, sB, score_of(KA));
    $display("CELL_RUN_B_NE_A done");

    rst_n = 0; qv = 0; mem_rst_n = 1'b0;
    repeat (8) @(posedge clk); mem_rst_n = 1'b1; rst_n = 1; wait_boot;
    if (c8g == 0) begin $display("FAIL GEN0 live GEN=0"); fails++; end
    do_query(8'd2);
    if (score_of(KA) > 39) begin $display("FAIL GEN0 visible score=%0d", score_of(KA)); fails++; end
    $display("GEN0 GEN=%0d KAscore=%0d", c8g, score_of(KA));
    $display("CELL_GEN0_NEVER_VISIBLE done");

    cell_rst;
    learn_map_a;
    i = 0;
    while (!wimm && i < 12) begin
      pulse_persist(trst); i++;
    end
    if (!wimm) begin $display("FAIL wrap not imminent after bumps"); fails++; end
    pulse_persist(trst);
    if (c8g == 0) begin $display("FAIL wrap to GEN=0"); fails++; end
    do_query(8'd2);
    if (score_of(KA) > 39) begin $display("FAIL wrap resurrect A"); fails++; end
    $display("WRAP GEN=%0d wimm=%0b Ascore=%0d", c8g, wimm, score_of(KA));
    $display("CELL_ROOT_INVALIDATE_BEFORE_WRAP done");

    cell_rst;
    learn_map_a;
    gen0 = c8g; sdig0 = c8d;
    bwr0 = bwr; brd0 = brd;
    pulse_persist(flush);
    rst_n = 0;
    repeat (8) @(posedge clk);
    rst_n = 1; wait_boot;
    if (c8g == 0) begin $display("FAIL PWR GEN=0"); fails++; end
    do_query(8'd2);
    $display("PWR GEN=%0d (pre %0d) rank=%0d score=%0d wr=%0d rd=%0d",
             c8g, gen0, rank_of(KA), score_of(KA), bwr-bwr0, brd-brd0);
    if (c8g != gen0) begin $display("FAIL PWR GEN restore"); fails++; end
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin $display("FAIL PWR A invisible"); fails++; end
    if (rdok < 32'd16) begin $display("FAIL PWR rd_ok %0d", rdok); fails++; end
    $display("CELL_POWER_REPROGRAM_AUTHORITY done");

    // backpressure + one BRESP then retry
    cell_rst;
    stall_aw = 4'd3; stall_w = 4'd2; stall_ar = 4'd3; stall_r = 4'd2; stall_b = 4'd2;
    learn_map_a;
    @(negedge clk); inj_b = 1'b1;
    @(posedge clk); @(negedge clk); inj_b = 1'b0;
    pulse_persist(flush);
    pulse_persist(kill);
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin
      $display("FAIL BP A still in BRAM"); fails++;
    end
    pulse_persist(reload);
    wait_boot;
    do_query(8'd2);
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin
      $display("FAIL BP reload lost A"); fails++;
    end
    if (!saw_b) begin $display("FAIL expected BRESP inject"); fails++; end
    if (wrerr == 0) begin $display("FAIL wr_err not counted"); fails++; end
    stall_aw = 0; stall_w = 0; stall_ar = 0; stall_r = 0; stall_b = 0;
    $display("CELL_BACKPRESSURE_BRESP_RETRY done wrerr=%0d", wrerr);

    // RLAST miss then retry
    cell_rst;
    learn_map_a;
    pulse_persist(flush);
    pulse_persist(kill);
    @(negedge clk); inj_nl = 1'b1;
    @(posedge clk); @(negedge clk); inj_nl = 1'b0;
    pulse_persist(reload);
    wait_boot;
    do_query(8'd2);
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin
      $display("FAIL RLAST reload lost A"); fails++;
    end
    if (!saw_nl) begin $display("FAIL expected RLAST inject"); fails++; end
    if (rderr == 0) begin $display("FAIL rd_err not counted"); fails++; end
    $display("CELL_RLAST_RETRY done rderr=%0d", rderr);

    // RRESP SLVERR then retry (directive: inject BRESP/RRESP/RLAST)
    cell_rst;
    learn_map_a;
    pulse_persist(flush);
    pulse_persist(kill);
    @(negedge clk); inj_r = 1'b1;
    @(posedge clk); @(negedge clk); inj_r = 1'b0;
    pulse_persist(reload);
    wait_boot;
    do_query(8'd2);
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin
      $display("FAIL RRESP reload lost A"); fails++;
    end
    if (!saw_rr) begin $display("FAIL expected RRESP inject"); fails++; end
    if (rderr == 0) begin $display("FAIL rd_err not counted after RRESP"); fails++; end
    $display("CELL_RRESP_RETRY done rderr=%0d", rderr);

    if (region_v || regerr) begin $display("FAIL region violation"); fails++; end
    if (awc == 0 || arc == 0) begin $display("FAIL no AXI traffic"); fails++; end

    if (fails == 0)
      $display("PERSIST_AXI_MIG_XSIM_PASS fails=0 CELLS=7 BP=1 BRESP=1 RRESP=1 RLAST=1");
    else
      $display("PERSIST_AXI_MIG_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
