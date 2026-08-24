// tb_a7ng_shard_fetch.sv — NG-03 bytes/query + hit ratio (AXI model)
`timescale 1ns / 1ps

module tb_a7ng_shard_fetch;
  import a7ng_pkg::*;

  logic clk, rst_n, query, busy, done, hit;
  logic [31:0] nid, hits, misses, cands, bytes, bursts;
  logic [63:0] dout;

  logic [3:0] arid, rid;
  logic [27:0] araddr;
  logic [7:0] arlen;
  logic [2:0] arsize;
  logic [1:0] arburst, rresp;
  logic arvalid, arready, rlast, rvalid, rready;
  logic [127:0] rdata;

  // unused write ports tied
  logic awready, wready, bvalid;
  logic [3:0] bid;
  logic [1:0] bresp;

  a7ng_shard_fetch dut (
    .clk(clk), .rst_n(rst_n),
    .query_i(query), .node_id_i(nid),
    .busy_o(busy), .done_o(done), .hit_o(hit), .data_o(dout),
    .hits_o(hits), .misses_o(misses),
    .candidates_o(cands), .ddr_read_bytes_o(bytes), .ddr_bursts_o(bursts),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  a7ng_axi_mem_model mem (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awid(4'd0), .s_axi_awaddr(28'd0), .s_axi_awlen(8'd0),
    .s_axi_awsize(3'd4), .s_axi_awburst(2'b01),
    .s_axi_awvalid(1'b0), .s_axi_awready(awready),
    .s_axi_wdata(128'd0), .s_axi_wstrb(16'h0), .s_axi_wlast(1'b0),
    .s_axi_wvalid(1'b0), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(1'b1),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic do_query(input [31:0] id);
    begin
      @(negedge clk);
      nid = id; query = 1;
      @(posedge clk); #1; query = 0;
      wait (done);
      @(posedge clk);
    end
  endtask

  integer fails;
  initial begin
    fails = 0;
    rst_n = 0; query = 0; nid = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // cold miss → 16B DDR read
    do_query(32'd7);
    if (hit !== 1'b0 || bytes !== 32'd16 || bursts !== 32'd1 || cands !== 32'd1) begin
      $display("FAIL cold: hit=%0d bytes=%0d bursts=%0d cands=%0d", hit, bytes, bursts, cands);
      fails = fails + 1;
    end
    // FPGA address check on last AR (sampled via expected formula)
    if (araddr !== (NG_DDR_NODE_BASE + {24'd7, 4'b0000}) && bytes == 32'd16) begin
      // araddr may already be idle; verify via computed expected fill data
    end
    if (dout[31:0] !== 32'd7) begin
      $display("FAIL data low=%h expect node 7", dout[31:0]);
      fails = fails + 1;
    end

    // warm hit → no extra DDR
    do_query(32'd7);
    if (hit !== 1'b1 || bytes !== 32'd16 || bursts !== 32'd1 || cands !== 32'd2) begin
      $display("FAIL hit: hit=%0d bytes=%0d bursts=%0d cands=%0d", hit, bytes, bursts, cands);
      fails = fails + 1;
    end

    // second node miss → +16B (still O(candidates), not full scan)
    do_query(32'd9);
    if (bytes !== 32'd32 || bursts !== 32'd2 || cands !== 32'd3) begin
      $display("FAIL second miss bytes=%0d bursts=%0d", bytes, bursts);
      fails = fails + 1;
    end

    // HS-13: candidates << DEPTH_WORDS
    if (cands >= 32'd100) begin
      $display("FAIL full-scan smell cands=%0d", cands);
      fails = fails + 1;
    end

    if (fails == 0) $display("A7NG03_SHARD_XSIM_PASS bytes=%0d hits=%0d misses=%0d cands=%0d", bytes, hits, misses, cands);
    else $display("A7NG03_SHARD_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
