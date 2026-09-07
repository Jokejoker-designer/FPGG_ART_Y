// tb_u6_unified_retrieval.sv — U6. PROGRAM=NO. U7A=CLOSED.
`timescale 1ns / 1ps

module tb_u6_unified_retrieval;
  import a7ng_pkg::*;
  `include "u6_lut.svh"

  localparam int unsigned MEM_DEPTH = 32768;
  localparam int K = 8;

  logic clk, rst_n, tok_v, tok_r, fire, retire;
  logic qse_v, v0, v1, v2, v3, poke, poke_go;
  logic [7:0] tok, qe, qi, qr, qx, pe, pi, pr, px;
  logic [15:0] k0, k1, k2, k3, pk0, pk1, pk2, pk3, n_host, n_emit, n_dup, n_trunc, n_scored;
  logic pv0, pv1, pv2, pv3, done, ovf;
  logic [15:0] live_epoch;
  node_id_t top_id [K];
  score_t   top_sc [K];

  logic [3:0] arid; logic [27:0] araddr; logic [7:0] arlen;
  logic [2:0] arsize; logic [1:0] arburst; logic arvalid, arready;
  logic [3:0] rid; logic [127:0] rdata; logic [1:0] rresp;
  logic rlast, rvalid, rready;

  integer qn, bi, i, timeout, n_poi, pj;
  logic [127:0] poi_save [0:7];
  integer poi_idx [0:7];
  logic leg_qv;
  localparam logic [127:0] CHILLER_POST =
      128'h00000003_00000002_00000001_00000000;
  localparam logic [127:0] POISON_POST =
      128'h000ABCDE_000ABCDE_000ABCDE_000ABCDE;

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

  a7ng_unified_retrieval dut (
    .clk(clk), .rst_n(rst_n), .live_epoch_i(live_epoch),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .qse_valid_o(qse_v), .q_ent_o(qe), .q_int_o(qi), .q_rel_o(qr), .q_ctx_o(qx),
    .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3),
    .v0_o(v0), .v1_o(v1), .v2_o(v2), .v3_o(v3),
    .n_host_or_o(n_host),
    .poke_i(poke), .poke_go_i(poke_go),
    .poke_k0_i(pk0), .poke_k1_i(pk1), .poke_k2_i(pk2), .poke_k3_i(pk3),
    .poke_v0_i(pv0), .poke_v1_i(pv1), .poke_v2_i(pv2), .poke_v3_i(pv3),
    .poke_ent_i(pe), .poke_int_i(pi), .poke_rel_i(pr), .poke_ctx_i(px),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready),
    .done_o(done), .retrieval_overflow_o(ovf), .retrieval_trunc_o(n_trunc),
    .n_emit_o(n_emit), .n_dup_o(n_dup),
    .topk_id_o(top_id), .topk_sc_o(top_sc), .n_scored_o(n_scored)
  );

  // Disconnected legacy graph — must not feed U6 Top-K.
  logic g_qr, g_snap; logic [7:0] g_qid;
  node_id_t g_id [8]; score_t g_sc [8];
  a7ng_learned_prior_graph u_legacy (
    .clk(clk), .rst_n(rst_n), .learn_i(1'b0), .freeze_i(1'b1),
    .query_valid_i(leg_qv), .query_ready_o(g_qr), .query_id_i(8'd2),
    .snap_valid_o(g_snap), .snap_ready_i(1'b1),
    .topk_id_o(g_id), .topk_score_o(g_sc),
    .c3_pack_o(), .c9_pack_o(), .pending_o(), .txn_o(),
    .reward_valid_i(1'b0), .reward_i(4'sd0), .txn_echo_valid_i(1'b0), .txn_echo_i(16'd0),
    .reward_ready_o(), .ack_valid_o(), .ack_o(), .c5_consume_o(),
    .c7_ack_valid_o(), .c7_ack_ready_i(1'b1), .c7_addr_o(), .c7_commit_seq_o(), .c7_ack_count_o(),
    .c8_gen_o(), .c8_sdig_o(),
    .flush_i(1'b0), .reload_i(1'b0), .bram_kill_i(1'b0), .train_reset_i(1'b0),
    .persist_busy_o(), .persist_done_o(),
    .ddr_req_o(), .ddr_we_o(), .ddr_addr_o(), .ddr_wdata_o(),
    .ddr_rdata_i(64'd0), .ddr_ack_i(1'b0)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
      #20 $finish;
    end
  endtask

  task automatic wait_done;
    begin
      timeout = 0;
      while (!done) begin
        @(posedge clk);
        timeout = timeout + 1;
        if (timeout > 200000) diverge("EARLY_DONE", "timeout waiting done");
      end
      @(posedge clk);
    end
  endtask

  task automatic check_q(input int q);
    integer s;
    begin
      if (n_host != 0) diverge("HOST_SEMANTIC_LEAK", $sformatf("q=%0d", q));
      if (n_trunc != G_NTRUNC[q])
        diverge("OVERFLOW_STATUS_LOST", $sformatf("trunc act=%0d exp=%0d", n_trunc, G_NTRUNC[q]));
      if (ovf !== G_OVF[q] && G_NTRUNC[q] != 0 && !ovf)
        diverge("OVERFLOW_STATUS_LOST", "trunc without ovf");
      if (n_scored != G_NCAND[q] && G_MODE[q] != 0)
        ; // poke scored == ncand
      if (n_scored != 16'(G_NCAND[q]))
        diverge("CANDIDATE_ID_MISMATCH", $sformatf("n_scored=%0d ncand=%0d", n_scored, G_NCAND[q]));
      for (s = 0; s < K; s = s + 1) begin
        if (top_id[s] !== G_TKID[q*K + s])
          diverge("TOPK_MISMATCH", $sformatf("q=%0d s=%0d id act=%h exp=%h", q, s, top_id[s], G_TKID[q*K+s]));
        if (top_sc[s] !== G_TKSC[q*K + s])
          diverge("FINAL_SCORE_MISMATCH", $sformatf("q=%0d s=%0d sc act=%0d exp=%0d", q, s, $signed(top_sc[s]), $signed(G_TKSC[q*K+s])));
      end
      $display("Q%0d %0s ncand=%0d trunc=%0d ovf=%0d top0=%h sc0=%0d",
        q, (G_MODE[q] ? "POKE" : "QSE"), n_scored, n_trunc, ovf, top_id[0], $signed(top_sc[0]));
    end
  endtask

  task automatic fire_q0;
    begin
      poke = 0;
      while (done) @(posedge clk);
      for (bi = 0; bi < G_LEN[0]; bi = bi + 1) begin
        @(posedge clk); tok_v <= 1; tok <= G_BYTES[0][8*bi +: 8];
        @(posedge clk);
        if (!tok_r) diverge("PIPELINE_ALIGNMENT_ERROR", "tok q0");
        tok_v <= 0;
      end
      @(posedge clk); fire <= 1;
      @(posedge clk); fire <= 0;
      wait_done();
    end
  endtask

  task automatic retire_q;
    begin
      @(posedge clk); retire <= 1;
      @(posedge clk); retire <= 0;
      @(posedge clk);
    end
  endtask

  initial begin
    rst_n = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    poke = 0; poke_go = 0; live_epoch = 16'd7; leg_qv = 0;
    pk0 = 0; pk1 = 0; pk2 = 0; pk3 = 0;
    pv0 = 0; pv1 = 0; pv2 = 0; pv3 = 0;
    pe = 0; pi = 0; pr = 0; px = 0;
    for (i = 0; i < MEM_DEPTH; i = i + 1) u_mem.mem[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (8) @(posedge clk);
    for (i = 0; i < G_N_WR; i = i + 1)
      u_mem.mem[G_WR_I[i]] = G_WR_D[i];

    for (qn = 0; qn < G_N_Q; qn = qn + 1) begin
      if (G_MODE[qn] == 0) begin
        poke = 0;
        for (bi = 0; bi < G_LEN[qn]; bi = bi + 1) begin
          @(posedge clk); tok_v <= 1; tok <= G_BYTES[qn][8*bi +: 8];
          @(posedge clk);
          if (!tok_r) diverge("KEY_MISMATCH", "tok");
          tok_v <= 0;
        end
        @(posedge clk); fire <= 1;
        @(posedge clk); fire <= 0;
        wait_done();
        if (k0 !== G_K0[qn] || k1 !== G_K1[qn] || k2 !== G_K2[qn] || k3 !== G_K3[qn])
          diverge("KEY_MISMATCH", $sformatf("q=%0d", qn));
        if (v0 !== G_V0[qn] || v1 !== G_V1[qn] || v2 !== G_V2[qn] || v3 !== G_V3[qn])
          diverge("VALIDITY_MISMATCH", $sformatf("q=%0d", qn));
        check_q(qn);
        @(posedge clk); retire <= 1;
        @(posedge clk); retire <= 0;
        @(posedge clk);
      end else begin
        poke = 1;
        pk0 = G_K0[qn]; pk1 = G_K1[qn]; pk2 = G_K2[qn]; pk3 = G_K3[qn];
        pv0 = G_V0[qn]; pv1 = G_V1[qn]; pv2 = G_V2[qn]; pv3 = G_V3[qn];
        pe = G_ENT[qn]; pi = G_INT[qn]; pr = G_REL[qn]; px = G_CTX[qn];
        @(posedge clk); poke_go <= 1;
        @(posedge clk); poke_go <= 0;
        wait_done();
        check_q(qn);
        poke = 0;
        @(posedge clk);
      end
    end

    // FALSIFIER A — enable disconnected legacy generator; TopK must hold.
    @(posedge clk);
    if (g_qr) begin
      leg_qv <= 1'b1;
      @(posedge clk);
      leg_qv <= 1'b0;
    end
    fire_q0();
    for (i = 0; i < K; i = i + 1) begin
      if (top_id[i] !== G_TKID[i] || top_sc[i] !== G_TKSC[i])
        diverge("LEGACY_PATH_CAUSAL", "legacy query_valid changed TopK");
    end
    $display("POISON_LEGACY_HOLD top0=%h", top_id[0]);
    retire_q();

    // FALSIFIER B — chiller walks T0 and T2 with the SAME 4 IDs.
    // Poisoning one copy cannot change Top-4; poison every identical posting beat.
    n_poi = 0;
    for (i = 0; i < G_N_WR; i = i + 1) begin
      if (u_mem.mem[G_WR_I[i]] === CHILLER_POST) begin
        if (n_poi > 7) diverge("LEGACY_PATH_CAUSAL", "too many chiller postings");
        poi_idx[n_poi] = G_WR_I[i];
        poi_save[n_poi] = u_mem.mem[G_WR_I[i]];
        u_mem.mem[G_WR_I[i]] = POISON_POST;
        n_poi = n_poi + 1;
      end
    end
    if (n_poi == 0)
      diverge("LEGACY_PATH_CAUSAL", "no chiller AXI posting beat found");
    fire_q0();
    if (top_id[0] === G_TKID[0] && top_id[1] === G_TKID[1] &&
        top_id[2] === G_TKID[2] && top_id[3] === G_TKID[3])
      diverge("LEGACY_PATH_CAUSAL", "poison AXI did not change TopK");
    $display("POISON_AXI n=%0d top0=%h (was %h)", n_poi, top_id[0], G_TKID[0]);
    for (pj = 0; pj < n_poi; pj = pj + 1)
      u_mem.mem[poi_idx[pj]] = poi_save[pj];
    retire_q();

    $display("U6_UNIFIED_RETRIEVAL_PASS");
    $display("CLAIM=FPGA sparse retrieval is the single authoritative source feeding production scorer and exact Top-K");
    $display("NOT_CLAIMED=NLU,800k_quality,U7,LM,board,GATE14");
    #20 $finish;
  end
endmodule
