// tb_u5_mem02_sparse_800k.sv
// U5: bounded traffic vs N + sentinel 799999. PROGRAM=NO. U6=CLOSED.
`timescale 1ns / 1ps

module tb_u5_mem02_sparse_800k;
  import a7ng_pkg::*;
  `include "u5_gold.svh"

  localparam int unsigned ID_W = 20;
  localparam int unsigned CAND_CAP = 64;
  localparam int unsigned MEM_DEPTH = 32768;
  localparam logic [27:0] POST_HEAP = 28'h05040000;
  localparam logic [27:0] T3_LO = 28'h05030000;
  localparam logic [27:0] T3_HI = 28'h0503FFF0;

  logic clk, rst_n, tok_v, tok_r, fire, retire, busy, acc, valid;
  logic [7:0] tok, eid, iid, rid, xid;
  logic [63:0] ec, ic, rc, xc;
  logic [15:0] crc, k0, k1, k2, k3;
  logic v0, v1, v2, v3;
  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;
  logic [15:0] live_epoch, wk0, wk1, wk2, wk3, n_emit, n_dup, n_trunc, n_dir, n_post;
  logic wv0, wv1, wv2, wv3, q_v, q_ready, cand_v, cand_ready, q_done, q_ovf;
  logic [3:0] pmask;
  logic [ID_W-1:0] cand_id;
  logic [3:0] arid; logic [27:0] araddr; logic [7:0] arlen;
  logic [2:0] arsize; logic [1:0] arburst; logic arvalid, arready;
  logic [3:0] ridb; logic [127:0] rdata; logic [1:0] rresp;
  logic rlast, rvalid, rready;

  integer i, bi, timeout, n_got, n_dar, n_par, n_rbeat, di;
  logic [ID_W-1:0] got [0:127];
  logic [27:0] dar [0:15];
  logic [27:0] par [0:15];

  a7ng_query_struct_extract u_qse (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .busy_o(busy), .accepted_o(acc), .valid_o(valid),
    .entity_id_o(eid), .intent_id_o(iid), .relation_id_o(rid), .context_id_o(xid),
    .entity_cue_o(ec), .intent_cue_o(ic), .relation_cue_o(rc), .context_cue_o(xc),
    .crc16_dbg_o(crc), .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3),
    .k0_valid_o(v0), .k1_valid_o(v1), .k2_valid_o(v2), .k3_valid_o(v3),
    .n_host_entity_o(h_ent), .n_host_intent_o(h_int), .n_host_hash_o(h_hash),
    .n_host_shard_o(h_sh), .n_host_bucket_o(h_bkt), .n_host_cand_o(h_cand),
    .n_host_winner_o(h_win), .n_host_addr_o(h_addr), .n_host_relpath_o(h_rel),
    .n_host_next_o(h_nxt), .n_host_answer_o(h_ans)
  );

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
    .s_axi_rid(ridb), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  a7ng_sparse_dir_axi #(
    .N_TABLES(4), .N_BUCKETS(4096), .CAND_CAP(CAND_CAP),
    .ID_W(ID_W), .INDEX_BASE(NG_DDR_INDEX_BASE)
  ) dut (
    .clk(clk), .rst_n(rst_n), .live_epoch_i(live_epoch),
    .q_v(q_v), .q_ready(q_ready),
    .k0_i(wk0), .k1_i(wk1), .k2_i(wk2), .k3_i(wk3),
    .k0_valid_i(wv0), .k1_valid_i(wv1), .k2_valid_i(wv2), .k3_valid_i(wv3),
    .cand_v(cand_v), .cand_ready(cand_ready), .cand_id(cand_id),
    .q_done(q_done), .q_overflow_o(q_ovf),
    .n_emit_o(n_emit), .n_dup_o(n_dup), .n_trunc_o(n_trunc),
    .n_dir_ar_o(n_dir), .n_post_ar_o(n_post), .probed_mask_o(pmask),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(ridb), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic diverge(input string code, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", code, d);
      #20 $finish;
    end
  endtask

  task automatic walk;
    begin
      n_got = 0; n_dar = 0; n_par = 0; n_rbeat = 0;
      cand_ready = 1'b1;
      @(posedge clk);
      while (!q_ready) @(posedge clk);
      q_v <= 1'b1; @(posedge clk); q_v <= 1'b0;
      timeout = 0;
      while (!q_done) begin
        @(posedge clk);
        if (arvalid && arready) begin
          if (araddr >= POST_HEAP) begin
            par[n_par] = araddr; n_par = n_par + 1;
          end else begin
            dar[n_dar] = araddr; n_dar = n_dar + 1;
          end
        end
        if (rvalid && rready) n_rbeat = n_rbeat + 1;
        if (cand_v && cand_ready) begin
          got[n_got] = cand_id; n_got = n_got + 1;
        end
        timeout = timeout + 1;
        if (timeout > 80000) diverge("AXI_PROTOCOL_ERROR", "timeout");
      end
      @(posedge clk);
    end
  endtask

  initial begin
    rst_n = 0; q_v = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    cand_ready = 1; live_epoch = 16'd7;
    wk0 = 0; wk1 = 0; wk2 = 0; wk3 = 0;
    wv0 = 0; wv1 = 0; wv2 = 0; wv3 = 0;
    for (i = 0; i < MEM_DEPTH; i = i + 1) u_mem.mem[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);
    for (i = 0; i < G_N_WR; i = i + 1)
      u_mem.mem[G_WR_I[i]] = G_WR_D[i];

    // ---- QSE chiller: traffic must ignore 256 T3 dummies ----
    for (bi = 0; bi < G_CH_LEN; bi = bi + 1) begin
      @(posedge clk); tok_v <= 1'b1; tok <= G_CH_BYTES[8*bi +: 8];
      @(posedge clk);
      if (!tok_r) diverge("KEY_MISMATCH", "tok not ready");
      tok_v <= 1'b0;
    end
    @(posedge clk); fire <= 1'b1;
    @(posedge clk); fire <= 1'b0;
    @(posedge clk);
    if (!valid) diverge("KEY_MISMATCH", "no valid");
    if (h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans)
      diverge("HOST_SEMANTIC_LEAK", "n_host");
    wk0 = k0; wk1 = k1; wk2 = k2; wk3 = k3;
    wv0 = v0; wv1 = v1; wv2 = v2; wv3 = v3;
    walk();
    if (n_dir != G_CH_NDIR) diverge("TRAFFIC_GROWS_WITH_N", $sformatf("dir=%0d", n_dir));
    if (n_got != G_CH_EMIT) diverge("CANDIDATE_ID_MISMATCH", $sformatf("emit=%0d", n_got));
    for (i = 0; i < n_got; i = i + 1)
      if (got[i] !== G_CH_ID[i]) diverge("CANDIDATE_ID_MISMATCH", "chiller id");
    for (i = 0; i < n_dar; i = i + 1) begin
      if (dar[i] !== G_CH_DIR[i]) diverge("DIR_ADDR_MISMATCH", "chiller dir");
      if (dar[i] >= T3_LO && dar[i] <= T3_HI)
        diverge("HIDDEN_FULL_SCAN", "probed T3 dummy");
    end
    $display("CHILLER dir=%0d post=%0d emit=%0d beats=%0d bytes=%0d (dummies ignored)",
      n_dir, n_post, n_got, n_rbeat, n_rbeat*16);
    @(posedge clk); retire <= 1; @(posedge clk); retire <= 0; @(posedge clk);

    // ---- sentinel 799999 at high posting address ----
    wk0 = G_SENT_K; wk1 = 0; wk2 = 0; wk3 = 0;
    wv0 = 1; wv1 = 0; wv2 = 0; wv3 = 0;
    walk();
    if (n_dir != 16'd1 || dar[0] !== G_SENT_DIR)
      diverge("SENTINEL_MISS", $sformatf("dir=%h", dar[0]));
    if (n_par != 1 || par[0] !== G_SENT_POST)
      diverge("SENTINEL_MISS", $sformatf("post=%h", par[0]));
    if (n_got != 1 || got[0] !== G_SENTINEL)
      diverge("SENTINEL_MISS", $sformatf("id=%h", got[0]));
    $display("SENTINEL id=%h post=%h", got[0], par[0]);

    // ---- collide 200 unique IDs → CAND_CAP ----
    wk0 = G_COL_K; wv0 = 1; wv1 = 0; wv2 = 0; wv3 = 0;
    wk1 = 0; wk2 = 0; wk3 = 0;
    walk();
    if (n_dir != 16'd1) diverge("HIDDEN_FULL_SCAN", $sformatf("col dir=%0d", n_dir));
    if (n_got != CAND_CAP) diverge("CAP_ERROR", $sformatf("emit=%0d", n_got));
    if (n_trunc != (G_COL_N - CAND_CAP))
      diverge("CAP_ERROR", $sformatf("trunc=%0d", n_trunc));
    if (n_dir >= 16'd4096) diverge("HIDDEN_FULL_SCAN", "bucket walk");
    $display("COLLIDE200 emit=%0d trunc=%0d dir=%0d beats=%0d bytes=%0d",
      n_got, n_trunc, n_dir, n_rbeat, n_rbeat*16);

    // ---- unknown ----
    wk0 = 0; wk1 = 0; wk2 = 0; wk3 = 0;
    wv0 = 0; wv1 = 0; wv2 = 0; wv3 = 0;
    walk();
    if (n_dir != 0 || n_got != 0) diverge("HIDDEN_FULL_SCAN", "unknown probed");
    $display("UNKNOWN dir=0 emit=0");

    $display("U5_MEM02_SPARSE_800K_PASS");
    $display("CLAIM=bounded AXI dir/posting vs N; sentinel 799999 fetched; no full scan");
    $display("NOT_CLAIMED=800k_DRAM_fill,U6,scorer_quality,board");
    #20 $finish;
  end
endmodule
