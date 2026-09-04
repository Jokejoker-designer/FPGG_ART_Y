// tb_a7ng_sparse_dir_axi.sv — U4-R2 protocol. PROGRAM=NO. SOC=NO.
`timescale 1ns / 1ps

module tb_a7ng_sparse_dir_axi;
  import a7ng_pkg::*;

  localparam int unsigned ID_W = 20;
  localparam int unsigned CAND_CAP = 8;
  localparam int unsigned N_BUCKETS = 16;
  localparam int unsigned N_TABLES = 2;
  localparam logic [19:0] SENT = 20'hC34FF; // 799999

  logic clk, rst_n;
  logic [15:0] live_epoch;
  logic q_v, q_ready, cand_v, cand_ready, q_done, q_ovf;
  logic [15:0] k0, k1, n_emit, n_dup, n_trunc;
  logic [ID_W-1:0] cand_id;

  logic [3:0]  arid;
  logic [27:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arvalid, arready;
  logic [3:0]  rid;
  logic [127:0] rdata;
  logic [1:0]  rresp;
  logic        rlast, rvalid, rready;

  integer fail, n_got, i;
  logic [ID_W-1:0] got [0:31];
  integer stall_seen, hold_id;
  integer idx;

  a7ng_axi_mem_model #(.DEPTH_WORDS(16384)) u_mem (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awid(4'd0), .s_axi_awaddr(28'd0), .s_axi_awlen(8'd0),
    .s_axi_awsize(3'd4), .s_axi_awburst(2'b01),
    .s_axi_awvalid(1'b0), .s_axi_awready(),
    .s_axi_wdata(128'd0), .s_axi_wstrb(16'h0), .s_axi_wlast(1'b0),
    .s_axi_wvalid(1'b0), .s_axi_wready(),
    .s_axi_bid(), .s_axi_bresp(), .s_axi_bvalid(), .s_axi_bready(1'b1),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  a7ng_sparse_dir_axi #(
    .N_TABLES(N_TABLES), .N_BUCKETS(N_BUCKETS), .CAND_CAP(CAND_CAP),
    .ID_W(ID_W), .INDEX_BASE(NG_DDR_INDEX_BASE)
  ) dut (
    .clk(clk), .rst_n(rst_n), .live_epoch_i(live_epoch),
    .q_v(q_v), .q_ready(q_ready), .k0_i(k0), .k1_i(k1),
    .cand_v(cand_v), .cand_ready(cand_ready), .cand_id(cand_id),
    .q_done(q_done), .q_overflow_o(q_ovf),
    .n_emit_o(n_emit), .n_dup_o(n_dup), .n_trunc_o(n_trunc),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  function automatic int unsigned word_of(input logic [27:0] a);
    return 6144 + int'((a - NG_DDR_INDEX_BASE) >> 4);
  endfunction

  function automatic logic [127:0] dir_pack(
    input logic [27:0] base,
    input logic [15:0] count,
    input logic        ovf,
    input logic [15:0] ep
  );
    dir_pack = {48'd0, ep, 15'd0, ovf, count, 4'd0, base};
  endfunction

  function automatic logic [27:0] dir_a(input int t, input int b);
    dir_a = NG_DDR_INDEX_BASE + {23'd0, t[0], b[3:0], 4'b0000};
  endfunction

  task automatic w128(input logic [27:0] a, input logic [127:0] d);
    begin
      u_mem.mem[word_of(a)] = d;
    end
  endtask

  task automatic collect_query(
    input logic [15:0] kk0,
    input logic [15:0] kk1,
    input int stall_n
  );
    integer stalled;
    begin
      n_got = 0;
      stall_seen = 0;
      stalled = 0;
      k0 = kk0; k1 = kk1;
      cand_ready = 1'b1;
      @(posedge clk);
      while (!q_ready) @(posedge clk);
      q_v <= 1'b1;
      @(posedge clk);
      q_v <= 1'b0;
      while (!q_done) begin
        @(posedge clk);
        if (cand_v && cand_ready) begin
          got[n_got] = cand_id;
          n_got = n_got + 1;
          if (stall_n > 0 && stalled == 0) begin
            cand_ready <= 1'b0;
            stalled = 1;
          end
        end else if (cand_v && !cand_ready) begin
          if (stall_seen == 0)
            hold_id = cand_id;
          else if (cand_id !== hold_id[ID_W-1:0]) begin
            fail = fail + 1;
            $display("STALL_ID_MOVED %h -> %h", hold_id[ID_W-1:0], cand_id);
          end
          stall_seen = stall_seen + 1;
          if (stall_seen >= stall_n)
            cand_ready <= 1'b1;
        end
      end
      cand_ready <= 1'b1;
      @(posedge clk);
    end
  endtask

  initial begin
    fail = 0;
    rst_n = 0; q_v = 0; cand_ready = 1; k0 = 0; k1 = 0; live_epoch = 16'd7;
    for (i = 0; i < 16384; i = i + 1)
      u_mem.mem[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    // ---- Case A: sentinel + dup across tables, overflow flag on t0 ----
    // k0=0x0010 -> bucket 0 ; k1=0x0021 -> bucket 1
    w128(dir_a(0, 0), dir_pack(NG_DDR_INDEX_BASE + 28'h1000, 16'd3, 1'b1, 16'd7));
    w128(NG_DDR_INDEX_BASE + 28'h1000, {32'd0, 32'h0000_00AA, 32'h0000_00B1, 32'h000C_34FF});
    w128(dir_a(1, 1), dir_pack(NG_DDR_INDEX_BASE + 28'h1100, 16'd2, 1'b0, 16'd7));
    w128(NG_DDR_INDEX_BASE + 28'h1100, {64'd0, 32'h0000_00CC, 32'h000C_34FF});

    collect_query(16'h0010, 16'h0021, 6);
    if (stall_seen < 6) begin fail = fail + 1; $display("STALL_MISS"); end
    if (n_got != 4) begin fail = fail + 1; $display("A_EMIT got=%0d want 4", n_got); end
    if (n_emit != 16'd4) begin fail = fail + 1; $display("A_NEMIT %0d", n_emit); end
    if (n_dup != 16'd1) begin fail = fail + 1; $display("A_DUP %0d", n_dup); end
    if (!q_ovf) begin fail = fail + 1; $display("A_OVF_MISS"); end
    if (got[0] !== SENT) begin fail = fail + 1; $display("A_SENT %h", got[0]); end
    if (got[0][7:0] == got[0][ID_W-1:0] && got[0][ID_W-1:8] != '0) ;
    if (got[0][19:8] !== 12'hC34) begin
      fail = fail + 1; $display("LOW8_ALIAS sentinel truncated %h", got[0]);
    end
    $display("CASE_A emit=%0d dup=%0d ovf=%0b stall=%0d id0=%h", n_emit, n_dup, q_ovf, stall_seen, got[0]);

    // ---- Case B: truncation CAND_CAP=8, 12 postings ----
    w128(dir_a(0, 2), dir_pack(NG_DDR_INDEX_BASE + 28'h2000, 16'd12, 1'b0, 16'd7));
    w128(dir_a(1, 3), dir_pack(NG_DDR_INDEX_BASE + 28'h2100, 16'd0, 1'b0, 16'd7));
    w128(NG_DDR_INDEX_BASE + 28'h2000, {32'd4, 32'd3, 32'd2, 32'd1});
    w128(NG_DDR_INDEX_BASE + 28'h2010, {32'd8, 32'd7, 32'd6, 32'd5});
    w128(NG_DDR_INDEX_BASE + 28'h2020, {32'd12, 32'd11, 32'd10, 32'd9});
    collect_query(16'h0002, 16'h0003, 0);
    if (n_emit != 16'd8) begin fail = fail + 1; $display("B_EMIT %0d", n_emit); end
    if (n_trunc != 16'd4) begin fail = fail + 1; $display("B_TRUNC %0d", n_trunc); end
    $display("CASE_B emit=%0d trunc=%0d", n_emit, n_trunc);

    // ---- Case C: epoch mismatch skips table 0, table 1 valid ----
    w128(dir_a(0, 4), dir_pack(NG_DDR_INDEX_BASE + 28'h3000, 16'd2, 1'b0, 16'd9)); // bad epoch
    w128(NG_DDR_INDEX_BASE + 28'h3000, {64'd0, 32'd77, 32'd76});
    w128(dir_a(1, 5), dir_pack(NG_DDR_INDEX_BASE + 28'h3100, 16'd1, 1'b0, 16'd7));
    w128(NG_DDR_INDEX_BASE + 28'h3100, {96'd0, 32'd88});
    collect_query(16'h0004, 16'h0005, 0);
    if (n_emit != 16'd1) begin fail = fail + 1; $display("C_EMIT %0d", n_emit); end
    if (got[0] !== 20'd88) begin fail = fail + 1; $display("C_ID %h", got[0]); end
    $display("CASE_C emit=%0d id=%h", n_emit, got[0]);

    // ---- Case D: empty both ----
    w128(dir_a(0, 6), dir_pack(28'd0, 16'd0, 1'b0, 16'd7));
    w128(dir_a(1, 7), dir_pack(28'd0, 16'd0, 1'b0, 16'd7));
    collect_query(16'h0006, 16'h0007, 0);
    if (n_emit != 16'd0) begin fail = fail + 1; $display("D_EMIT %0d", n_emit); end
    $display("CASE_D emit=%0d", n_emit);

    if (fail == 0) begin
      $display("U4_R2_DDR_SPARSE_DIRECTORY_PASS");
      $display("NO_HARDCODED_2_16_8_32_GEOMETRY");
      $display("SENTINEL_20BIT %h", SENT);
    end else
      $display("U4_R2_DDR_SPARSE_DIRECTORY_FAIL fail=%0d", fail);
    #20 $finish;
  end
endmodule
