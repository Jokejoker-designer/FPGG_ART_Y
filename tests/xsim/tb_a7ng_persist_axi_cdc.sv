// P2-MIG-PERSIST-CDC-CLOSURE-02 dual-clock unit. PROGRAM=NO.
// Random-phase clocks, reset skew, backpressure, exactly-once ACK, payload stable.
`timescale 1ns / 1ps

module tb_a7ng_persist_axi_cdc;
  logic core_clk, ui_clk, core_rst_n, ui_rst_n;
  integer fails, i;
  integer n_req, n_ack, n_c7, n_c7rdy;
  logic [63:0] last_wdata, last_rdata;

  logic ddr_req, ddr_we, ddr_ack, freeze, c7v, c7rdy;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [31:0] c7a, wrok, wrerr, rdok, rderr, bwr, brd;
  logic [15:0] fzdrop;
  logic grant, req, idle, regerr;
  logic [3:0] stall_aw, stall_w, stall_ar, stall_r, stall_b;
  logic inj_b, inj_r, inj_nl;

  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic arvalid, arready, rvalid, rready, rlast;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  // Coprime-ish periods; ui delayed (random phase).
  initial core_clk = 0;
  always #5 core_clk = ~core_clk;   // 100 MHz
  initial begin
    ui_clk = 0;
    #3; // phase offset
    forever #4 ui_clk = ~ui_clk;    // 125 MHz
  end

  a7ng_persist_axi_bridge u_br (
    .core_clk(core_clk), .core_rst_n(core_rst_n),
    .ddr_req_i(ddr_req), .ddr_we_i(ddr_we), .ddr_addr_i(ddr_addr),
    .ddr_wdata_i(ddr_wdata), .ddr_rdata_o(ddr_rdata), .ddr_ack_o(ddr_ack),
    .freeze_i(freeze), .c7_valid_i(c7v), .c7_addr_i(c7a), .c7_ready_o(c7rdy),
    .ui_clk(ui_clk), .ui_rst_n(ui_rst_n), .grant_i(grant), .req_o(req), .idle_o(idle),
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
    .clk(ui_clk), .rst_n(ui_rst_n),
    .stall_aw_i(stall_aw), .stall_w_i(stall_w), .stall_ar_i(stall_ar),
    .stall_r_i(stall_r), .stall_b_i(stall_b),
    .inj_bresp_i(inj_b), .inj_rresp_i(inj_r), .inj_no_rlast_i(inj_nl),
    .saw_bresp_err_o(), .saw_rresp_err_o(), .saw_no_rlast_o(),
    .aw_count_o(), .ar_count_o(), .region_violation_o(),
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

  logic ack_d, c7_d;
  always @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      ack_d <= 1'b0; c7_d <= 1'b0;
    end else begin
      if (ddr_ack && !ack_d) n_ack = n_ack + 1;
      if (c7rdy && !c7_d) n_c7rdy = n_c7rdy + 1;
      ack_d <= ddr_ack;
      c7_d <= c7rdy;
    end
  end

  task automatic wait_idle;
    integer g;
    begin
      g = 0;
      while (!idle && g < 4000) begin @(posedge ui_clk); g++; end
      if (!idle) begin $display("FAIL idle timeout"); fails++; end
      repeat (4) @(posedge core_clk);
    end
  endtask

  task automatic do_wr(input logic [4:0] sl, input logic [63:0] d);
    integer g;
    begin
      last_wdata = d;
      @(negedge core_clk);
      ddr_addr = sl; ddr_wdata = d; ddr_we = 1; ddr_req = 1;
      n_req = n_req + 1;
      g = 0;
      while (!ddr_ack && g < 4000) begin @(posedge core_clk); g++; end
      if (!ddr_ack) begin $display("FAIL wr ack slot=%0d", sl); fails++; end
      @(negedge core_clk); ddr_req = 0; ddr_we = 0;
      wait_idle;
    end
  endtask

  task automatic do_rd(input logic [4:0] sl, input logic [63:0] exp);
    integer g;
    begin
      @(negedge core_clk);
      ddr_addr = sl; ddr_we = 0; ddr_req = 1;
      n_req = n_req + 1;
      g = 0;
      while (!ddr_ack && g < 4000) begin @(posedge core_clk); g++; end
      if (!ddr_ack) begin $display("FAIL rd ack slot=%0d", sl); fails++; end
      last_rdata = ddr_rdata;
      if (ddr_rdata !== exp) begin
        $display("FAIL payload slot=%0d got=%h exp=%h", sl, ddr_rdata, exp);
        fails++;
      end
      @(negedge core_clk); ddr_req = 0;
      wait_idle;
    end
  endtask

  initial begin
    #2000000; $display("FAIL CDC TB timeout"); $finish;
  end

  initial begin
    fails = 0; n_req = 0; n_ack = 0; n_c7 = 0; n_c7rdy = 0;
    ddr_req = 0; ddr_we = 0; ddr_addr = 0; ddr_wdata = 0;
    freeze = 0; c7v = 0; c7a = 0; grant = 1;
    stall_aw = 4'd2; stall_w = 4'd1; stall_ar = 4'd2; stall_r = 4'd1; stall_b = 4'd3;
    inj_b = 0; inj_r = 0; inj_nl = 0;
    core_rst_n = 0; ui_rst_n = 0;
    // reset skew: ui releases first
    repeat (8) @(posedge ui_clk);
    ui_rst_n = 1;
    repeat (5) @(posedge core_clk);
    core_rst_n = 1;
    repeat (8) @(posedge core_clk);

    for (i = 0; i < 8; i = i + 1)
      do_wr(i[4:0], {32'hA5A50000 + i, 32'h5A5A0000 + i});
    for (i = 0; i < 8; i = i + 1)
      do_rd(i[4:0], {32'hA5A50000 + i, 32'h5A5A0000 + i});

    // freeze: write dropped, no extra ACK
    freeze = 1;
    @(negedge core_clk); ddr_we = 1; ddr_addr = 5'd9; ddr_wdata = 64'hDEAD; ddr_req = 1;
    repeat (20) @(posedge core_clk);
    if (ddr_ack) begin $display("FAIL freeze produced ACK"); fails++; end
    ddr_req = 0; ddr_we = 0; freeze = 0;
    if (fzdrop == 0) begin $display("FAIL freeze_drop=0"); fails++; end
    wait_idle;

    // C7 exactly-once
    @(negedge core_clk); c7a = 32'hC7C7; c7v = 1; n_c7 = 1;
    i = 0;
    while (!c7rdy && i < 4000) begin @(posedge core_clk); i++; end
    if (!c7rdy) begin $display("FAIL C7 ready"); fails++; end
    @(negedge core_clk); c7v = 0;
    wait_idle;

    if (n_ack != n_req) begin
      $display("FAIL exactly-once ack=%0d req=%0d", n_ack, n_req);
      fails++;
    end
    if (n_c7rdy != n_c7) begin
      $display("FAIL C7 once c7rdy=%0d c7=%0d", n_c7rdy, n_c7);
      fails++;
    end
    if (regerr) begin $display("FAIL region"); fails++; end
    if (wrok < 8 || rdok < 8) begin $display("FAIL counts wr=%0d rd=%0d", wrok, rdok); fails++; end

    if (fails == 0)
      $display("PERSIST_AXI_CDC_XSIM_PASS fails=0 req=%0d ack=%0d wr_ok=%0d rd_ok=%0d phase=3ns rst_skew=ui_first bp=1",
               n_req, n_ack, wrok, rdok);
    else
      $display("PERSIST_AXI_CDC_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
