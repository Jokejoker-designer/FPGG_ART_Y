// tb_a7ng_late_materialize.sv — graph_late_materialize_00 XSim
// Marker: A7NG_LATE_MAT_XSIM_PASS
`timescale 1ns / 1ps

module tb_a7ng_late_materialize;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int unsigned K = 8;

  logic clk, rst_n, commit, busy, done;
  logic [K-1:0] mask;
  node_id_t id [K];
  logic beat_v, beat_last, early_fault;
  logic [2:0] beat_idx;
  node_id_t beat_id;
  logic [127:0] beat_data;
  logic [15:0] n_fetch, n_skip;
  logic [31:0] bytes, beats;

  logic [3:0] arid, rid;
  logic [27:0] araddr;
  logic [7:0] arlen;
  logic [2:0] arsize;
  logic [1:0] arburst, rresp;
  logic arvalid, arready, rlast, rvalid, rready;
  logic [127:0] rdata;
  logic awready, wready, bvalid;
  logic [3:0] bid;
  logic [1:0] bresp;

  integer ar_before_commit;
  integer fails;
  integer seen_fetch;

  a7ng_late_materialize #(.K(K)) dut (
    .clk(clk), .rst_n(rst_n),
    .commit_i(commit), .valid_mask_i(mask), .id_i(id),
    .busy_o(busy), .done_o(done),
    .beat_valid_o(beat_v), .beat_last_o(beat_last),
    .beat_idx_o(beat_idx), .beat_id_o(beat_id), .beat_data_o(beat_data),
    .n_fetch_o(n_fetch), .n_skip_o(n_skip),
    .payload_bytes_o(bytes), .ar_beats_o(beats),
    .early_ar_fault_o(early_fault),
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

  always @(posedge clk) begin
    if (rst_n && arvalid && (dut.st == dut.ST_IDLE))
      ar_before_commit <= ar_before_commit + 1;
  end

  task automatic pulse_commit;
    begin
      @(negedge clk);
      commit = 1;
      @(posedge clk); #1;
      commit = 0;
    end
  endtask

  integer i;
  initial begin
    fails = 0;
    ar_before_commit = 0;
    seen_fetch = 0;
    rst_n = 0; commit = 0; mask = '0;
    for (i = 0; i < K; i = i + 1) id[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    // No AR in idle
    repeat (8) @(posedge clk);
    if (arvalid !== 1'b0) begin
      $display("FAIL AR while idle");
      fails = fails + 1;
    end

    // 3 survivors, 5 losers. Late-mat bytes = 3*16 = 48. Early-mat would be 8*16=128.
    mask = 8'b0010_1101; // idx 0,2,3,5 → wait: 00101101 = 0,2,3,5? bits 0,2,3,5 = 4 valids
    // Use exactly 3: bits 0, 2, 5
    mask = 8'b0010_0101; // 0, 2, 5
    id[0] = 32'd3;
    id[1] = 32'd99; // invalid — must not fetch
    id[2] = 32'd7;
    id[3] = 32'd11;
    id[4] = 32'd13;
    id[5] = 32'd21;
    id[6] = 32'd22;
    id[7] = 32'd23;

    pulse_commit;
    wait (done);
    @(posedge clk);

    if (n_fetch !== 16'd3) begin
      $display("FAIL n_fetch=%0d want 3", n_fetch);
      fails = fails + 1;
    end
    if (n_skip !== 16'd5) begin
      $display("FAIL n_skip=%0d want 5", n_skip);
      fails = fails + 1;
    end
    if (bytes !== 32'd48) begin
      $display("FAIL bytes=%0d want 48 (late) not 128 (early)", bytes);
      fails = fails + 1;
    end
    if (beats !== 32'd3) begin
      $display("FAIL ar_beats=%0d want 3", beats);
      fails = fails + 1;
    end
    if (early_fault !== 1'b0 || ar_before_commit !== 0) begin
      $display("FAIL early AR fault=%0d count=%0d", early_fault, ar_before_commit);
      fails = fails + 1;
    end

    // FPGA-owned address of last survivor (id 21) — sampled after done, AR already dropped.
    // Recompute expected and compare via schema helper.
    if (a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'd21) !==
        (NG_DDR_NODE_BASE + {24'd21, 4'b0000})) begin
      $display("FAIL schema stride");
      fails = fails + 1;
    end

    // Empty mask: no fetch, 8 skips, 0 bytes (replication of same unknown).
    mask = 8'b0000_0000;
    pulse_commit;
    wait (done);
    @(posedge clk);
    if (n_fetch !== 16'd0 || n_skip !== 16'd8 || bytes !== 32'd0) begin
      $display("FAIL empty: fetch=%0d skip=%0d bytes=%0d", n_fetch, n_skip, bytes);
      fails = fails + 1;
    end

    // Full K: late == early = 128 B, 0 skips.
    mask = 8'hFF;
    for (i = 0; i < K; i = i + 1) id[i] = 32'(i + 1);
    pulse_commit;
    wait (done);
    @(posedge clk);
    if (n_fetch !== 16'd8 || n_skip !== 16'd0 || bytes !== 32'd128) begin
      $display("FAIL full: fetch=%0d skip=%0d bytes=%0d", n_fetch, n_skip, bytes);
      fails = fails + 1;
    end

    if (fails == 0) begin
      $display("A7NG_LATE_MAT_XSIM_PASS");
      $display("payload_bytes=%0d n_fetch=%0d n_skip=%0d (losers not fetched)", bytes, n_fetch, n_skip);
    end else begin
      $display("A7NG_LATE_MAT_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
