// P2-G1G5-FULLCHIP-MIG-PERSIST-01 collision. PROGRAM=NO.
// Persist AXI vs dummy graph AR (NODE) vs dummy LM AW (WMEM). One-hot mux.
`timescale 1ns / 1ps

module tb_a7ng_persist_axi_collision;
  import a7ng_pkg::*;
  localparam logic [27:0] WBASE = 28'h0010_0000;

  logic clk, rst_n;
  integer fails, dual, i;

  logic p_req, p_grant, p_idle;
  logic g_arvalid, g_arready, l_awvalid, l_awready;
  logic [27:0] g_araddr, l_awaddr;
  logic mux_p, mux_g, mux_l;
  logic [27:0] seen_p_aw, seen_g_ar, seen_l_aw;

  // dummy persist write request
  logic ddr_req, ddr_we, ddr_ack, freeze, c7v, c7rdy;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [31:0] c7a, wrok, wrerr, rdok, rderr, bwr, brd;
  logic [15:0] fzdrop;
  logic regerr;
  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic arvalid, arready, rvalid, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  a7ng_persist_axi_bridge u_br (
    .core_clk(clk), .core_rst_n(rst_n),
    .ddr_req_i(ddr_req), .ddr_we_i(ddr_we), .ddr_addr_i(ddr_addr),
    .ddr_wdata_i(ddr_wdata), .ddr_rdata_o(ddr_rdata), .ddr_ack_o(ddr_ack),
    .freeze_i(freeze), .c7_valid_i(c7v), .c7_addr_i(c7a), .c7_ready_o(c7rdy),
    .ui_clk(clk), .ui_rst_n(rst_n), .grant_i(p_grant), .req_o(p_req), .idle_o(p_idle),
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
    .clk(clk), .rst_n(rst_n),
    .stall_aw_i(4'd1), .stall_w_i(4'd0), .stall_ar_i(4'd1),
    .stall_r_i(4'd0), .stall_b_i(4'd0),
    .inj_bresp_i(1'b0), .inj_rresp_i(1'b0), .inj_no_rlast_i(1'b0),
    .saw_bresp_err_o(), .saw_rresp_err_o(), .saw_no_rlast_o(),
    .aw_count_o(), .ar_count_o(), .region_violation_o(),
    .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
    .s_axi_awsize(awsize), .s_axi_awburst(awburst),
    .s_axi_awvalid(awvalid && p_grant), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
    .s_axi_wvalid(wvalid && p_grant), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid && p_grant), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  assign mux_p = p_grant;
  assign mux_g = g_arvalid && !p_grant;
  assign mux_l = l_awvalid && !p_grant && !mux_g;
  assign dual = (mux_p && mux_g) || (mux_p && mux_l) || (mux_g && mux_l);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) p_grant <= 1'b0;
    else if (p_req && !g_arvalid && !l_awvalid) p_grant <= 1'b1;
    else if (p_grant && p_idle && !p_req) p_grant <= 1'b0;
  end

  initial clk = 0;
  always #40 clk = ~clk;

  initial begin
    #2000000; $display("FAIL collision timeout"); $finish;
  end

  always @(posedge clk) if (rst_n && dual) begin
    $display("FAIL dual-drive P=%0d G=%0d L=%0d", mux_p, mux_g, mux_l);
    fails = fails + 1;
  end

  always @(posedge clk) begin
    if (rst_n && awvalid && p_grant) begin
      if (awaddr < NG_DDR_PRIOR_BASE || awaddr >= NG_DDR_PRIOR_BASE + 28'h200)
        begin $display("FAIL persist AW out of region %h", awaddr); fails++; end
      seen_p_aw <= awaddr;
    end
    if (rst_n && g_arvalid && mux_g) begin
      if (g_araddr < NG_DDR_NODE_BASE || g_araddr >= NG_DDR_CUE64_BASE)
        begin $display("FAIL graph AR out of node %h", g_araddr); fails++; end
      seen_g_ar <= g_araddr;
    end
    if (rst_n && l_awvalid && mux_l) begin
      if (l_awaddr < WBASE || l_awaddr >= NG_DDR_NODE_BASE)
        begin $display("FAIL LM AW out of wmem %h", l_awaddr); fails++; end
      seen_l_aw <= l_awaddr;
    end
  end

  initial begin
    fails = 0; rst_n = 0; freeze = 0; c7v = 0; c7a = 0;
    ddr_req = 0; ddr_we = 0; ddr_addr = 0; ddr_wdata = 0;
    g_arvalid = 0; g_araddr = NG_DDR_NODE_BASE;
    l_awvalid = 0; l_awaddr = WBASE;
    seen_p_aw = 0; seen_g_ar = 0; seen_l_aw = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    // graph AR while persist idle
    g_arvalid = 1; g_araddr = NG_DDR_NODE_BASE + 28'h10;
    repeat (6) @(posedge clk);
    g_arvalid = 0;

    // LM AW
    l_awvalid = 1; l_awaddr = WBASE + 28'h40;
    repeat (6) @(posedge clk);
    l_awvalid = 0;

    // persist write, graph tries at the same time — persist waits until graph drops, then owns
    g_arvalid = 1;
    ddr_we = 1; ddr_addr = 5'd3; ddr_wdata = 64'h1111_2222_3333_4444;
    @(negedge clk); ddr_req = 1;
    repeat (8) @(posedge clk);
    if (p_grant && g_arvalid) begin
      $display("FAIL persist granted while graph AR live"); fails++;
    end
    g_arvalid = 0;
    i = 0;
    while (!ddr_ack && i < 400) begin @(posedge clk); i++; end
    if (!ddr_ack) begin $display("FAIL persist write no ack"); fails++; end
    @(negedge clk); ddr_req = 0; ddr_we = 0;
    repeat (10) @(posedge clk);

    // persist read
    ddr_we = 0; ddr_addr = 5'd3;
    @(negedge clk); ddr_req = 1;
    i = 0;
    while (!ddr_ack && i < 400) begin @(posedge clk); i++; end
    if (!ddr_ack) begin $display("FAIL persist read no ack"); fails++; end
    if (ddr_rdata[63:0] !== 64'h1111_2222_3333_4444)
      begin $display("FAIL conservation rdata %h", ddr_rdata); fails++; end
    @(negedge clk); ddr_req = 0;
    repeat (8) @(posedge clk);

    if (regerr) begin $display("FAIL region_err"); fails++; end
    if (seen_p_aw == 0) begin $display("FAIL no persist AW seen"); fails++; end
    if (seen_g_ar == 0) begin $display("FAIL no graph AR seen"); fails++; end
    if (seen_l_aw == 0) begin $display("FAIL no LM AW seen"); fails++; end

    if (fails == 0)
      $display("PERSIST_AXI_COLLISION_XSIM_PASS fails=0 dual=0");
    else
      $display("PERSIST_AXI_COLLISION_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
