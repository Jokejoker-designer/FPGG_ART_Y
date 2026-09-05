// tb_u4_mem02_axi_directory.sv
// U4-MEM02: extractor → AXI dir/posting. PROGRAM=NO. U5=CLOSED.
`timescale 1ns / 1ps

module tb_u4_mem02_axi_directory;
  import a7ng_pkg::*;
  `include "query_gold.svh"

  localparam int unsigned ID_W = 20;
  localparam int unsigned CAND_CAP = 64;
  localparam int unsigned MEM_DEPTH = 32768;
  localparam logic [27:0] POST_HEAP = 28'h05040000;
  localparam logic [27:0] DIR_LO = 28'h05000000;
  localparam logic [27:0] DIR_HI = 28'h0503FFF0;

  logic clk, rst_n, tok_v, tok_r, fire, retire, busy, acc, valid;
  logic [7:0] tok, eid, iid, rid, xid;
  logic [63:0] ec, ic, rc, xc;
  logic [15:0] crc, k0, k1, k2, k3;
  logic v0, v1, v2, v3;
  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;

  logic [15:0] live_epoch;
  logic q_v, q_ready, cand_v, cand_ready, q_done, q_ovf;
  logic [15:0] wk0, wk1, wk2, wk3, n_emit, n_dup, n_trunc, n_dir, n_post;
  logic wv0, wv1, wv2, wv3;
  logic [3:0] pmask;
  logic [ID_W-1:0] cand_id;

  logic [3:0]  arid;
  logic [27:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arvalid, arready;
  logic [3:0]  ridb;
  logic [127:0] rdata;
  logic [1:0]  rresp;
  logic        rlast, rvalid, rready;

  integer qi, bi, i, fail, timeout, stall_n, stalled, stall_seen, hold_id;
  integer n_got, n_dar, n_par, n_pred, n_rbeat, n_host;
  integer post_left, exp_post_i;
  logic   track_post;
  logic [ID_W-1:0] got [0:127];
  logic [ID_W-1:0] pred [0:127];
  logic [27:0] dar [0:7];
  logic [27:0] par [0:7];
  logic [27:0] exp_dir;
  logic [27:0] exp_post;
  logic [15:0] exp_pcnt;
  integer n_exp_post;

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

  task automatic diverge(input string code, input string detail);
    begin
      $display("FIRST_DIVERGENCE %s %s", code, detail);
      fail = fail + 1;
      #20 $finish;
    end
  endtask

  function automatic logic [27:0] g_dir(input int q, input int s);
    case (s)
      0: return G_DIR0[q];
      1: return G_DIR1[q];
      2: return G_DIR2[q];
      default: return G_DIR3[q];
    endcase
  endfunction

  function automatic logic [27:0] g_post(input int q, input int s);
    case (s)
      0: return G_POST0[q];
      1: return G_POST1[q];
      2: return G_POST2[q];
      default: return G_POST3[q];
    endcase
  endfunction

  function automatic logic [15:0] g_pcnt(input int q, input int s);
    case (s)
      0: return G_PCNT0[q];
      1: return G_PCNT1[q];
      2: return G_PCNT2[q];
      default: return G_PCNT3[q];
    endcase
  endfunction

  task automatic retire_qse;
    begin
      @(posedge clk); retire <= 1'b1;
      @(posedge clk); retire <= 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic walk(input int q);
    integer lane;
    begin
      n_got = 0; n_dar = 0; n_par = 0; n_pred = 0; n_rbeat = 0;
      stall_seen = 0; stalled = 0; hold_id = 0;
      track_post = 1'b0; post_left = 0; exp_post_i = 0;
      stall_n = G_STALL[q];
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
          if (araddr >= POST_HEAP) begin
            par[n_par] = araddr;
            n_par = n_par + 1;
            track_post = 1'b1;
            // next nonzero G_PCNT
            post_left = 0;
            while (exp_post_i < 4 && g_pcnt(q, exp_post_i) == 16'd0)
              exp_post_i = exp_post_i + 1;
            if (exp_post_i < 4)
              post_left = g_pcnt(q, exp_post_i);
            exp_post_i = exp_post_i + 1;
          end else if (araddr >= DIR_LO && araddr <= DIR_HI) begin
            dar[n_dar] = araddr;
            n_dar = n_dar + 1;
            track_post = 1'b0;
          end else
            diverge("HIDDEN_FULL_SCAN", $sformatf("AR=%h outside dir/post", araddr));
        end
        if (rvalid && rready) begin
          n_rbeat = n_rbeat + 1;
          if (track_post) begin
            for (lane = 0; lane < 4; lane = lane + 1) begin
              if (post_left > 0) begin
                pred[n_pred] = rdata[32*lane +: ID_W];
                n_pred = n_pred + 1;
                post_left = post_left - 1;
              end
            end
          end
        end
        if (cand_v && cand_ready) begin
          got[n_got] = cand_id;
          n_got = n_got + 1;
          if (stall_n > 0 && stalled == 0) begin
            cand_ready <= 1'b0;
            stalled = 1;
          end
        end else if (cand_v && !cand_ready) begin
          // Hold the *presented* beat (next after handshake), not the prior ID.
          if (stall_seen == 0)
            hold_id = cand_id;
          else if (cand_id !== hold_id[ID_W-1:0])
            diverge("AXI_PROTOCOL_ERROR", "stall cand_id moved");
          stall_seen = stall_seen + 1;
          if (stall_seen >= stall_n)
            cand_ready <= 1'b1;
        end
        timeout = timeout + 1;
        if (timeout > 80000)
          diverge("AXI_PROTOCOL_ERROR", "Q_DONE_TIMEOUT");
      end
      @(posedge clk);
      cand_ready <= 1'b1;
    end
  endtask

  task automatic check_cuts(input int q);
    integer s, j;
    begin
      n_host = h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans;
      if (n_host != 0)
        diverge("HOST_SEMANTIC_LEAK", $sformatf("n_host=%0d", n_host));

      if (n_dar != G_NDIR[q])
        diverge("DIR_ADDR_MISMATCH", $sformatf("n_dir act=%0d exp=%0d", n_dar, G_NDIR[q]));
      if (n_dir != G_NDIR[q])
        diverge("DIR_ADDR_MISMATCH", $sformatf("n_dir_o act=%0d", n_dir));
      if (n_dar > 4)
        diverge("HIDDEN_FULL_SCAN", $sformatf("dir_ar=%0d", n_dar));
      for (s = 0; s < n_dar; s = s + 1) begin
        exp_dir = g_dir(q, s);
        if (dar[s] !== exp_dir)
          diverge("DIR_ADDR_MISMATCH", $sformatf("s=%0d act=%h exp=%h", s, dar[s], exp_dir));
        if (dar[s] < DIR_LO || dar[s] > DIR_HI)
          diverge("DIR_ADDR_MISMATCH", "out of T0..T3 range");
        // 4-bit alias would collide 0x001 vs 0x011; 12-bit offset must use k[11:0]
        if (dar[s][3:0] !== 4'h0)
          diverge("DIR_ADDR_MISMATCH", "not 16B aligned");
      end
      if (pmask !== G_PMASK[q])
        diverge("VALIDITY_MISMATCH", $sformatf("pmask act=%0d exp=%0d", pmask, G_PMASK[q]));

      n_exp_post = 0;
      for (s = 0; s < 4; s = s + 1)
        if (g_pcnt(q, s) != 16'd0) n_exp_post = n_exp_post + 1;
      if (n_par != n_exp_post || n_post != G_NPOST[q])
        diverge("POST_ADDR_MISMATCH", $sformatf("n_post act=%0d exp=%0d", n_par, G_NPOST[q]));
      j = 0;
      for (s = 0; s < 4; s = s + 1) begin
        if (g_pcnt(q, s) != 16'd0) begin
          exp_post = g_post(q, s);
          exp_pcnt = g_pcnt(q, s);
          if (par[j] !== exp_post)
            diverge("POST_ADDR_MISMATCH", $sformatf("j=%0d act=%h exp=%h", j, par[j], exp_post));
          j = j + 1;
        end
      end

      if (n_pred != G_NPRED[q])
        diverge("POST_COUNT_MISMATCH", $sformatf("predup act=%0d exp=%0d", n_pred, G_NPRED[q]));
      for (s = 0; s < n_pred; s = s + 1)
        if (pred[s] !== G_PRED[q*G_MAX_PRED + s])
          diverge("CANDIDATE_ID_MISMATCH", $sformatf("CUT_D s=%0d act=%h exp=%h", s, pred[s], G_PRED[q*G_MAX_PRED + s]));

      if (n_got != G_NEMIT[q] || n_emit != G_NEMIT[q])
        diverge("CAP_ERROR", $sformatf("emit act=%0d exp=%0d", n_got, G_NEMIT[q]));
      if (n_got > CAND_CAP)
        diverge("CAP_ERROR", "candidate_count>64");
      for (s = 0; s < n_got; s = s + 1) begin
        if (got[s] !== G_EMIT[q*G_MAX_EMIT + s])
          diverge("CANDIDATE_ID_MISMATCH", $sformatf("CUT_E s=%0d act=%h exp=%h", s, got[s], G_EMIT[q*G_MAX_EMIT + s]));
        for (j = 0; j < s; j = j + 1)
          if (got[j] === got[s])
            diverge("DEDUP_ERROR", $sformatf("dup id=%h", got[s]));
      end
      if (n_dup != G_NDUP[q])
        diverge("DEDUP_ERROR", $sformatf("n_dup act=%0d exp=%0d", n_dup, G_NDUP[q]));
      if (n_trunc != G_NTRUNC[q])
        diverge("CAP_ERROR", $sformatf("n_trunc act=%0d exp=%0d", n_trunc, G_NTRUNC[q]));
      if (stall_n > 0 && stall_seen < stall_n)
        diverge("AXI_PROTOCOL_ERROR", "backpressure not observed");
      $display("Q%0d %0s n_dir=%0d n_post=%0d pred=%0d emit=%0d dup=%0d trunc=%0d beats=%0d bytes=%0d",
        q, (G_MODE[q] ? "POKE" : "QSE"), n_dar, n_par, n_pred, n_got, n_dup, n_trunc,
        n_rbeat, n_rbeat * 16);
    end
  endtask

  initial begin
    fail = 0;
    rst_n = 0; q_v = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    cand_ready = 1; live_epoch = 16'd7;
    wk0 = 0; wk1 = 0; wk2 = 0; wk3 = 0;
    wv0 = 0; wv1 = 0; wv2 = 0; wv3 = 0;
    for (i = 0; i < MEM_DEPTH; i = i + 1)
      u_mem.mem[i] = '0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);
    for (i = 0; i < G_N_WR; i = i + 1)
      u_mem.mem[G_WR_I[i]] = G_WR_D[i];
    repeat (2) @(posedge clk);

    if (CAND_CAP != 64) diverge("CAP_ERROR", "CAND_CAP");

    for (qi = 0; qi < G_N_Q; qi = qi + 1) begin
      if (G_MODE[qi] == 0) begin
        for (bi = 0; bi < G_LEN[qi]; bi = bi + 1) begin
          @(posedge clk);
          tok_v <= 1'b1;
          tok   <= G_BYTES[qi][8*bi +: 8];
          @(posedge clk);
          if (!tok_r)
            diverge("KEY_MISMATCH", $sformatf("q=%0d NOT_READY", qi));
          tok_v <= 1'b0;
        end
        @(posedge clk); fire <= 1'b1;
        @(posedge clk); fire <= 1'b0;
        @(posedge clk);
        if (!valid)
          diverge("KEY_MISMATCH", $sformatf("q=%0d NO_VALID", qi));
        if (k0 !== G_K0[qi] || k1 !== G_K1[qi] || k2 !== G_K2[qi] || k3 !== G_K3[qi])
          diverge("KEY_MISMATCH", $sformatf("q=%0d k %h %h %h %h", qi, k0, k1, k2, k3));
        if (v0 !== G_V0[qi] || v1 !== G_V1[qi] || v2 !== G_V2[qi] || v3 !== G_V3[qi])
          diverge("VALIDITY_MISMATCH", $sformatf("q=%0d v %0d%0d%0d%0d", qi, v0, v1, v2, v3));
        wk0 = k0; wk1 = k1; wk2 = k2; wk3 = k3;
        wv0 = v0; wv1 = v1; wv2 = v2; wv3 = v3;
        walk(qi);
        check_cuts(qi);
        retire_qse();
      end else begin
        wk0 = G_K0[qi]; wk1 = G_K1[qi]; wk2 = G_K2[qi]; wk3 = G_K3[qi];
        wv0 = G_V0[qi]; wv1 = G_V1[qi]; wv2 = G_V2[qi]; wv3 = G_V3[qi];
        walk(qi);
        check_cuts(qi);
      end
    end

    $display("U4_MEM02_AXI_DIRECTORY_PASS");
    $display("CLAIM=FPGA-owned query features drive 4x4096 AXI sparse dir/posting and match host-golden candidate identities");
    $display("NOT_CLAIMED=800k,P4_quality,U5,board");
    #20 $finish;
  end
endmodule
