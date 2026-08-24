`timescale 1ns / 1ps
module tb_a7ng_index_bank;
  import a7ng_pkg::*;
  logic clk, rst_n, wr, rd, flush, reload, forget, busy, done;
  logic [3:0] wid, rid;
  logic [127:0] wdata, rdata;
  logic [3:0] awid, arid, bid, rid_a;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wlast, wvalid, wready, bvalid, bready, arvalid, arready, rlast, rvalid, rready;
  logic [127:0] axw, axr;
  logic [15:0] wstrb;

  a7ng_index_bank dut (
    .clk(clk), .rst_n(rst_n), .wr_i(wr), .wr_id_i(wid), .wr_data_i(wdata),
    .rd_i(rd), .rd_id_i(rid), .rd_data_o(rdata),
    .flush_i(flush), .reload_i(reload), .forget_i(forget),
    .busy_o(busy), .done_o(done),
    .m_axi_awid(awid), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen), .m_axi_awsize(awsize), .m_axi_awburst(awburst),
    .m_axi_awvalid(awvalid), .m_axi_awready(awready),
    .m_axi_wdata(axw), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast), .m_axi_wvalid(wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen), .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid_a), .m_axi_rdata(axr), .m_axi_rresp(rresp), .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  a7ng_axi_mem_model #(.DEPTH_WORDS(8192)) mem (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen), .s_axi_awsize(awsize), .s_axi_awburst(awburst),
    .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(axw), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen), .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rid(rid_a), .s_axi_rdata(axr), .s_axi_rresp(rresp), .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  initial clk=0; always #5 clk=~clk;
  integer fails;
  initial begin
    fails=0; rst_n=0; wr=0; rd=0; flush=0; reload=0; forget=0; wid=0; rid=0; wdata=0;
    repeat(3) @(posedge clk); rst_n=1; @(posedge clk);
    @(negedge clk); wr=1; wid=4'd1; wdata=128'h1111_0000_01A0_0D01;
    @(posedge clk); #1; wr=0;
    @(negedge clk); flush=1; @(posedge clk); #1; flush=0; wait(done); @(posedge clk);
    @(negedge clk); forget=1; @(posedge clk); #1; forget=0;
    @(negedge clk); reload=1; @(posedge clk); #1; reload=0; wait(done); @(posedge clk);
    @(negedge clk); rd=1; rid=4'd1; @(posedge clk); #1; rd=0;
    if (rdata !== 128'h1111_0000_01A0_0D01) begin $display("FAIL %h", rdata); fails=fails+1; end
    if (fails==0) $display("A7NG_MEM02_IDXBANK_XSIM_PASS");
    else $display("A7NG_MEM02_IDXBANK_XSIM_FAIL");
    $finish;
  end
endmodule
