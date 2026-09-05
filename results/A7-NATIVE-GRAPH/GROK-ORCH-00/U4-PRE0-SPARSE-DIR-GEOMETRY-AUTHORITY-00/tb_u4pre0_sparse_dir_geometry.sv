// tb_u4pre0_sparse_dir_geometry.sv
// U4-PRE0: P4_4k_h64 geometry authority. PROGRAM=NO. U4-MEM02 STOPPED.
`timescale 1ns / 1ps

module tb_u4pre0_sparse_dir_geometry;
  import a7ng_pkg::*;
  `include "golden_addr.svh"

  localparam int unsigned ID_W = 20;
  localparam int unsigned CAND_CAP = 64;
  localparam int unsigned N_BUCKETS = 4096;
  localparam int unsigned N_TABLES = 4;
  localparam int unsigned ENTRY_BYTES = 16;
  localparam int unsigned TABLE_BYTES = 65536;
  localparam logic [27:0] POST_HEAP = NG_DDR_INDEX_BASE + 28'h0004_0000;
  localparam int unsigned MEM_DEPTH = 32768;

  logic clk, rst_n;
  logic [15:0] live_epoch;
  logic q_v, q_ready, cand_v, cand_ready, q_done, q_ovf;
  logic [15:0] k0, k1, k2, k3, n_emit, n_dup, n_trunc, n_dir, n_post;
  logic v0, v1, v2, v3;
  logic [3:0] pmask;
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

  integer fail, n_got, n_ar, i, t, b, qi, timeout;
  logic [ID_W-1:0] got [0:127];
  logic [27:0] ar_log [0:31];
  logic [27:0] a0, a1, expect_a;
  logic [27:0] prev_a;

  a7ng_axi_mem_model #(.DEPTH_WORDS(MEM_DEPTH)) u_mem (
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
    .q_v(q_v), .q_ready(q_ready),
    .k0_i(k0), .k1_i(k1), .k2_i(k2), .k3_i(k3),
    .k0_valid_i(v0), .k1_valid_i(v1), .k2_valid_i(v2), .k3_valid_i(v3),
    .cand_v(cand_v), .cand_ready(cand_ready), .cand_id(cand_id),
    .q_done(q_done), .q_overflow_o(q_ovf),
    .n_emit_o(n_emit), .n_dup_o(n_dup), .n_trunc_o(n_trunc),
    .n_dir_ar_o(n_dir), .n_post_ar_o(n_post), .probed_mask_o(pmask),
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

  function automatic logic [27:0] law_addr(input int tt, input logic [15:0] kk);
    return NG_DDR_INDEX_BASE + (28'(tt) * 28'(TABLE_BYTES))
         + (28'(kk[11:0]) * 28'(ENTRY_BYTES));
  endfunction

  function automatic logic [127:0] dir_pack(
    input logic [27:0] base,
    input logic [15:0] count,
    input logic        ovf,
    input logic [15:0] ep
  );
    dir_pack = {48'd0, ep, 15'd0, ovf, count, 4'd0, base};
  endfunction

  task automatic diverge(input string why);
    begin
      $display("FIRST_DIVERGENCE %s", why);
      fail = fail + 1;
      #20 $finish;
    end
  endtask

  task automatic run_q(
    input logic [15:0] kk0, input logic vv0,
    input logic [15:0] kk1, input logic vv1,
    input logic [15:0] kk2, input logic vv2,
    input logic [15:0] kk3, input logic vv3
  );
    begin
      n_got = 0;
      n_ar = 0;
      k0 = kk0; k1 = kk1; k2 = kk2; k3 = kk3;
      v0 = vv0; v1 = vv1; v2 = vv2; v3 = vv3;
      cand_ready = 1'b1;
      @(posedge clk);
      while (!q_ready) @(posedge clk);
      q_v <= 1'b1;
      @(posedge clk);
      q_v <= 1'b0;
      timeout = 0;
      while (!q_done) begin
        @(posedge clk);
        if (arvalid && arready) begin
          ar_log[n_ar] = araddr;
          n_ar = n_ar + 1;
        end
        if (cand_v && cand_ready) begin
          got[n_got] = cand_id;
          n_got = n_got + 1;
        end
        timeout = timeout + 1;
        if (timeout > 20000)
          diverge("Q_DONE_TIMEOUT");
      end
      @(posedge clk);
    end
  endtask

  initial begin
    fail = 0;
    rst_n = 0; q_v = 0; cand_ready = 1;
    k0 = 0; k1 = 0; k2 = 0; k3 = 0;
    v0 = 0; v1 = 0; v2 = 0; v3 = 0;
    live_epoch = 16'd7;
    n_ar = 0; n_got = 0;
    for (i = 0; i < MEM_DEPTH; i = i + 1)
      u_mem.mem[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    if (N_BUCKETS != 4096) diverge("N_BUCKETS_NOT_4096");
    if (CAND_CAP != 64) diverge("CAND_CAP_NOT_64");
    if (TABLE_BYTES != 65536) diverge("TABLE_BYTES");
    if (G_T0_BASE !== NG_DDR_INDEX_BASE) diverge("T0_BASE");
    if (G_T1_BASE !== NG_DDR_INDEX_BASE + 28'h10000) diverge("T1_BASE");
    if (G_T2_BASE !== NG_DDR_INDEX_BASE + 28'h20000) diverge("T2_BASE");
    if (G_T3_BASE !== NG_DDR_INDEX_BASE + 28'h30000) diverge("T3_BASE");

    // ---- Formula: disjoint tables, unique 12-bit buckets ----
    prev_a = 28'h0;
    for (t = 0; t < N_TABLES; t = t + 1) begin
      a0 = law_addr(t, 16'h0000);
      a1 = law_addr(t, 16'h0FFF);
      if (a0 !== (NG_DDR_INDEX_BASE + (28'(t) * 28'h10000)))
        diverge("TABLE_BASE_MISMATCH");
      if ((a1 - a0) !== 28'h0FFF0)
        diverge("BUCKET_SPAN");
      if (t > 0 && a0 <= prev_a)
        diverge("TABLE_RANGE_OVERLAP");
      prev_a = a1;
      for (b = 0; b < 16; b = b + 1) begin
        if (law_addr(t, 16'(b) + 16'd1) - law_addr(t, 16'(b)) !== 28'd16)
          diverge("BUCKET_STEP");
      end
    end
    $display("CASE_RANGE disjoint T0..T3 last=%h", prev_a);

    // ---- Exact k0..k3, no XOR synth ----
    run_q(G_MAP_K[0], 1'b1, G_MAP_K[1], 1'b1, G_MAP_K[2], 1'b1, G_MAP_K[3], 1'b1);
    if (n_dir != 16'd4) diverge("MAP_DIR_AR_COUNT");
    if (n_post != 16'd0) diverge("MAP_POST_AR_NONEMPTY");
    if (pmask !== 4'b1111) diverge("MAP_PROBED_MASK");
    if (n_emit != 16'd0) diverge("MAP_EMIT");
    for (t = 0; t < 4; t = t + 1) begin
      if (ar_log[t] !== G_MAP_A[t])
        diverge("MAP_DIR_ADDR");
    end
    if (ar_log[2] === G_XOR_FAKE_T2)
      diverge("SYNTHETIC_XOR_T2_STILL_PRESENT");
    if (ar_log[2] === law_addr(2, G_MAP_K[0] ^ G_MAP_K[1] ^ 16'd2))
      diverge("SYNTHETIC_XOR_KEY_OF");
    $display("CASE_MAP exact T2=%h xor_fake=%h", ar_log[2], G_XOR_FAKE_T2);

    // ---- Alias: low-4 collide, 12-bit distinct ----
    if (G_OLD16_001 !== G_OLD16_011)
      diverge("OLD16_ALIAS_FIXTURE");
    for (qi = 0; qi < G_N_ALIAS; qi = qi + 1) begin
      run_q(G_ALIAS_K[qi], 1'b1, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
      if (n_dir != 16'd1) diverge("ALIAS_DIR_COUNT");
      if (pmask !== 4'b0001) diverge("ALIAS_MASK");
      if (ar_log[0] !== G_ALIAS_A[qi])
        diverge("ALIAS_ADDR");
      if (ar_log[0] === G_OLD16_001 && G_ALIAS_K[qi] === 16'h0011)
        diverge("OLD16_ALIAS_NOT_ELIMINATED");
      $display("CASE_ALIAS k=%h ar=%h old16_001=%h", G_ALIAS_K[qi], ar_log[0], G_OLD16_001);
    end
    run_q(16'h0001, 1'b1, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
    a0 = ar_log[0];
    run_q(16'h0011, 1'b1, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
    a1 = ar_log[0];
    if (a0 === a1) diverge("0x001_0x011_STILL_ALIAS");
    if (a0 !== G_ALIAS_A[0] || a1 !== G_ALIAS_A[1])
      diverge("ALIAS_PAIR_ADDR");
    $display("CASE_ALIAS_PAIR 001=%h 011=%h", a0, a1);

    // ---- Validity ----
    run_q(16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
    if (n_dir != 16'd0) diverge("V0_K0_DIR_AR");
    if (n_emit != 16'd0) diverge("V0_K0_EMIT");
    if (pmask !== 4'b0000) diverge("V0_K0_MASK");
    $display("CASE_V0_K0 dir=%0d emit=%0d", n_dir, n_emit);

    run_q(16'd0, 1'b0, 16'd0, 1'b0, 16'h00A7, 1'b0, 16'd0, 1'b0);
    if (n_dir != 16'd0) diverge("V0_KNZ_PROBED — used key!=0 as valid");
    if (pmask !== 4'b0000) diverge("V0_KNZ_MASK");
    $display("CASE_V0_KNZ dir=%0d", n_dir);

    run_q(16'd0, 1'b0, 16'd0, 1'b0, 16'h0000, 1'b1, 16'd0, 1'b0);
    if (n_dir != 16'd1) diverge("V1_K0_NO_PROBE");
    if (pmask !== 4'b0100) diverge("V1_K0_MASK");
    if (ar_log[0] !== G_T2_BASE) diverge("V1_K0_NOT_BUCKET0");
    $display("CASE_V1_K0 ar=%h", ar_log[0]);

    run_q(16'd0, 1'b0, 16'd0, 1'b0, 16'h0123, 1'b1, 16'd0, 1'b0);
    expect_a = G_T2_BASE + (28'h0123 * 28'd16);
    if (n_dir != 16'd1) diverge("V1_KNZ_DIR_COUNT");
    if (ar_log[0] !== expect_a) diverge("V1_KNZ_ADDR");
    $display("CASE_V1_KNZ ar=%h", ar_log[0]);

    // ---- Fully unknown ----
    run_q(16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
    if (n_dir != 16'd0) diverge("UNKNOWN_FULL_SCAN");
    if (n_post != 16'd0) diverge("UNKNOWN_POST");
    if (n_emit != 16'd0) diverge("UNKNOWN_CAND");
    if (n_got != 0) diverge("UNKNOWN_STREAM");
    if (pmask !== 4'b0000) diverge("UNKNOWN_MASK");
    $display("CASE_UNKNOWN dir=%0d emit=%0d done=1", n_dir, n_emit);

    // ---- CAND_CAP bound, no full scan of 4096 buckets ----
    u_mem.mem[word_of(law_addr(0, 16'h0002))] =
      dir_pack(POST_HEAP, 16'd80, 1'b0, 16'd7);
    for (i = 0; i < 20; i = i + 1) begin
      u_mem.mem[word_of(POST_HEAP + (28'(i) << 4))] = {
        32'(i * 4 + 4), 32'(i * 4 + 3), 32'(i * 4 + 2), 32'(i * 4 + 1)
      };
    end
    run_q(16'h0002, 1'b1, 16'd0, 1'b0, 16'd0, 1'b0, 16'd0, 1'b0);
    if (n_dir != 16'd1) diverge("CAP_DIR_NOT_ONE — hidden full scan?");
    if (n_dir >= 16'(N_BUCKETS)) diverge("CAP_FULL_BUCKET_SCAN");
    if (n_emit != 16'd64) diverge("CAP_EMIT");
    if (n_trunc != 16'd16) diverge("CAP_TRUNC");
    if (n_got != 64) diverge("CAP_GOT");
    if (n_dup != 16'd0) diverge("CAP_DUP");
    $display("CASE_CAP emit=%0d trunc=%0d dir=%0d", n_emit, n_trunc, n_dir);

    $display("U4_PRE0_SPARSE_DIR_GEOMETRY_PASS");
    $display("ROUTER_TO_AXI_GEOMETRY_COMPATIBILITY=PASS");
    $display("U4_SEMANTIC=NO");
    #20 $finish;
  end
endmodule
