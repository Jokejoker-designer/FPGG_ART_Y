// tb_u6_typeclass_retrieval.sv — U6 TYPECLASS. PROGRAM=NO. U7A=CLOSED.
`timescale 1ns / 1ps

module tb_u6_typeclass_retrieval;
  import a7ng_pkg::*;
  `include "typeclass_table.svh"
  `include "u6tc_gold.svh"

  localparam int K = 8;

  logic clk, rst_n, tok_v, tok_r, fire, retire, qse_v;
  logic [7:0] tok, qe, qi, qr, qx;
  logic poke, poke_go, stall_s, stall_h, poi_en;
  logic [7:0] pe, pi, pr, px, poi_e;
  logic pev, piv, prv, pxv;
  logic [15:0] poi_cid, n_host, n_emit, n_trunc, n_scored;
  logic done, ovf;
  node_id_t top_id [K];
  logic [15:0] top_cid [K];
  score_t top_sc [K];
  logic [3:0] st;
  logic scan_v, mat_v, sc_v;
  logic [15:0] scan_id, mat_id, mat_ptr, mat_cnt;
  logic [7:0] me, mi, mr, mx;
  score_t sc_so;
  term_t te, ti, tr, tc;

  integer qn, bi, i, tmo, got, got_sc, high;
  logic [15:0] got_id [0:63];
  logic signed [15:0] got_scv [0:63];
  logic [31:0] legacy_nid;

  a7ng_u6_typeclass_retrieval #(.CAND_CAP(64), .K(K)) dut (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .qse_valid_o(qse_v), .q_ent_o(qe), .q_int_o(qi), .q_rel_o(qr), .q_ctx_o(qx),
    .n_host_or_o(n_host),
    .poke_i(poke), .poke_go_i(poke_go),
    .poke_ent_i(pe), .poke_int_i(pi), .poke_rel_i(pr), .poke_ctx_i(px),
    .poke_ev_i(pev), .poke_iv_i(piv), .poke_rv_i(prv), .poke_xv_i(pxv),
    .stall_scan_i(stall_s), .stall_heap_i(stall_h),
    .poison_en_i(poi_en), .poison_class_id_i(poi_cid), .poison_eid_i(poi_e),
    .done_o(done), .retrieval_overflow_o(ovf), .retrieval_trunc_o(n_trunc),
    .n_emit_o(n_emit), .n_scored_o(n_scored),
    .topk_id_o(top_id), .topk_class_id_o(top_cid), .topk_sc_o(top_sc),
    .dbg_st_o(st), .dbg_scan_v_o(scan_v), .dbg_scan_id_o(scan_id),
    .dbg_mat_v_o(mat_v), .dbg_mat_id_o(mat_id),
    .dbg_mat_eid_o(me), .dbg_mat_iid_o(mi), .dbg_mat_rid_o(mr), .dbg_mat_xid_o(mx),
    .dbg_mat_ptr_o(mat_ptr), .dbg_mat_cnt_o(mat_cnt),
    .dbg_sc_v_o(sc_v), .dbg_sc_o(sc_so), .dbg_te_o(te), .dbg_ti_o(ti), .dbg_tr_o(tr), .dbg_tc_o(tc)
  );

  logic done8, ovf8;
  logic [15:0] e8, t8, ns8, nh8;
  node_id_t top8_id [K];
  logic [15:0] top8_cid [K];
  score_t top8_sc [K];
  logic poke8, go8, pev8, piv8, prv8, pxv8;
  logic [7:0] pe8, pi8, pr8, px8;

  a7ng_u6_typeclass_retrieval #(.CAND_CAP(8), .K(K)) u_cap8 (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(1'b0), .tok_ready_o(), .tok_i(8'd0),
    .fire_i(1'b0), .retire_i(1'b0),
    .qse_valid_o(), .q_ent_o(), .q_int_o(), .q_rel_o(), .q_ctx_o(),
    .n_host_or_o(nh8),
    .poke_i(poke8), .poke_go_i(go8),
    .poke_ent_i(pe8), .poke_int_i(pi8), .poke_rel_i(pr8), .poke_ctx_i(px8),
    .poke_ev_i(pev8), .poke_iv_i(piv8), .poke_rv_i(prv8), .poke_xv_i(pxv8),
    .stall_scan_i(1'b0), .stall_heap_i(1'b0),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .done_o(done8), .retrieval_overflow_o(ovf8), .retrieval_trunc_o(t8),
    .n_emit_o(e8), .n_scored_o(ns8),
    .topk_id_o(top8_id), .topk_class_id_o(top8_cid), .topk_sc_o(top8_sc),
    .dbg_st_o(), .dbg_scan_v_o(), .dbg_scan_id_o(),
    .dbg_mat_v_o(), .dbg_mat_id_o(),
    .dbg_mat_eid_o(), .dbg_mat_iid_o(), .dbg_mat_rid_o(), .dbg_mat_xid_o(),
    .dbg_mat_ptr_o(), .dbg_mat_cnt_o(),
    .dbg_sc_v_o(), .dbg_sc_o(), .dbg_te_o(), .dbg_ti_o(), .dbg_tr_o(), .dbg_tc_o()
  );

  // Disconnected NID decoy — zero DUT authority.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) legacy_nid <= 32'd1;
    else if (poke && poke_go && pe == 8'hFF) legacy_nid <= 32'h00ABCDEF;
  end

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
      tmo = 0;
      while (!done) begin
        @(posedge clk);
        if (stall_s) stall_s <= ~stall_s;
        if (stall_h) stall_h <= ~stall_h;
        if (scan_v) begin
          if (got >= 64) diverge("CANDIDATE_DUP", "too many");
          got_id[got] = scan_id;
          got = got + 1;
        end
        if (mat_v) begin
          if (mat_id < 16'd1 || mat_id > 16'(TC_N))
            diverge("CLASS_MATERIALIZE_MISMATCH", "bad id");
          if (me !== TC_EID[mat_id-1] && !(poi_en && mat_id == poi_cid))
            diverge("CLASS_MATERIALIZE_MISMATCH", "eid");
          if (mi !== TC_IID[mat_id-1] || mr !== TC_RID[mat_id-1] || mx !== TC_XID[mat_id-1])
            diverge("CLASS_MATERIALIZE_MISMATCH", "iid/rid/xid");
          if (mat_ptr !== TC_MPTR[mat_id-1] || mat_cnt !== TC_MCNT[mat_id-1])
            diverge("CLASS_MATERIALIZE_MISMATCH", "ptr/cnt");
          if (top_id[0][31:16] != 16'd0) ;
        end
        if (sc_v) begin
          if (got_sc >= 64) diverge("CANDIDATE_DUP", "sc");
          got_scv[got_sc] = sc_so;
          got_sc = got_sc + 1;
        end
        tmo = tmo + 1;
        if (tmo > 200000) diverge("EARLY_DONE", "timeout");
      end
      @(posedge clk);
    end
  endtask

  task automatic check_topk(input int q);
    begin
      if (n_host != 0) diverge("HOST_SEMANTIC_LEAK", "n_host");
      if (n_emit != 16'(U6_NC[q]))
        diverge("CLASS_ID_MISMATCH", $sformatf("emit q=%0d act=%0d", q, n_emit));
      if (got != U6_NC[q])
        diverge("CLASS_ID_MISMATCH", $sformatf("got=%0d exp=%0d", got, U6_NC[q]));
      for (i = 0; i < U6_NC[q]; i = i + 1) begin
        if (got_id[i] !== U6_CAND[q*U6_MAXC + i])
          diverge("CLASS_ID_MISMATCH",
            $sformatf("q=%0d i=%0d act=%0d exp=%0d", q, i, got_id[i], U6_CAND[q*U6_MAXC+i]));
        if (got_scv[i] !== U6_CSC[q*U6_MAXC + i])
          diverge("FINAL_SCORE_MISMATCH",
            $sformatf("q=%0d i=%0d act=%0d exp=%0d", q, i, got_scv[i], U6_CSC[q*U6_MAXC+i]));
      end
      for (i = 0; i < K; i = i + 1) begin
        if (top_id[i] !== U6_TID[q*K + i])
          diverge("TOPK_MISMATCH",
            $sformatf("q=%0d i=%0d id act=%0h exp=%0h", q, i, top_id[i], U6_TID[q*K+i]));
        if (top_sc[i] !== U6_TSC[q*K + i])
          diverge("TOPK_MISMATCH",
            $sformatf("q=%0d i=%0d sc act=%0d exp=%0d", q, i, top_sc[i], U6_TSC[q*K+i]));
        if (U6_TV[q*K + i] && top_id[i][31:16] != 16'd0)
          diverge("CLASS_ID_NID_CONFUSION", "hi bits");
        if (U6_TV[q*K + i] && top_cid[i] !== top_id[i][15:0])
          diverge("CLASS_ID_ALIAS", "class_id_o");
        if (top_id[i] == legacy_nid && legacy_nid == 32'h00ABCDEF)
          diverge("LEGACY_NID_PATH_CAUSAL", "decoy id in topk");
      end
      if (U6_NC[q] == 0 && ovf) diverge("OVERFLOW_STATUS_LOST", "no-answer ovf");
      $display("Q%0d n=%0d top0=%0d sc0=%0d ovf=%0d", q, n_emit, top_cid[0], top_sc[0], ovf);
    end
  endtask

  task automatic run_qse(input int q, input bit do_stall);
    begin
      poke <= 0; poke_go <= 0; stall_s <= 0;
      got = 0; got_sc = 0;
      retire <= 1; @(posedge clk); retire <= 0;
      @(posedge clk);
      for (bi = 0; bi < U6_QLEN[q]; bi = bi + 1) begin
        @(posedge clk);
        tok_v <= 1; tok <= U6_QBYTES[q][8*bi +: 8];
        @(posedge clk); tok_v <= 0;
      end
      @(posedge clk); fire <= 1; @(posedge clk); fire <= 0;
      tmo = 0;
      while (!qse_v && tmo < 4000) begin @(posedge clk); tmo = tmo + 1; end
      if (!qse_v) diverge("QSE_FIELD_MISMATCH", "no valid");
      if (qe !== U6_QE[q] || qi !== U6_QI[q] || qr !== U6_QR[q] || qx !== U6_QX[q])
        diverge("QSE_FIELD_MISMATCH", $sformatf("q=%0d se=%0d", q, qe));
      stall_s <= do_stall;
      wait_done();
      stall_s <= 0;
      check_topk(q);
    end
  endtask

  task automatic run_poke(input logic [7:0] e, n, r, x,
                          input logic evv, ivv, rvv, xvv);
    begin
      poke <= 1; stall_s <= 0; stall_h <= 0;
      pe <= e; pi <= n; pr <= r; px <= x;
      pev <= evv; piv <= ivv; prv <= rvv; pxv <= xvv;
      got = 0; got_sc = 0;
      @(posedge clk); poke_go <= 1; @(posedge clk); poke_go <= 0;
      wait_done();
      poke <= 0;
    end
  endtask

  initial begin
    rst_n = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    poke = 0; poke_go = 0; stall_s = 0; stall_h = 0;
    poi_en = 0; poi_cid = 0; poi_e = 0;
    pe = 0; pi = 0; pr = 0; px = 0; pev = 0; piv = 0; prv = 0; pxv = 0;
    poke8 = 0; go8 = 0; pe8 = 0; pi8 = 0; pr8 = 0; px8 = 0;
    pev8 = 0; piv8 = 0; prv8 = 0; pxv8 = 0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    for (qn = 0; qn < U6_NQ; qn = qn + 1)
      run_qse(qn, 1'b0);

    high = 0;
    for (i = 0; i < K; i = i + 1)
      if (top_cid[i] > 16'd255) high = 1;
    // duct is q=10; re-run to latch
    run_qse(10, 1'b0);
    high = 0;
    for (i = 0; i < K; i = i + 1)
      if (top_cid[i] > 16'd255) high = 1;
    if (!high) diverge("CLASS_ID_MISMATCH", "CLASS_ID>255 must survive Top-K");

    // stalls on chiller (scan ready toggled)
    run_qse(0, 1'b1);
    // heap in_ready stall
    stall_h <= 1;
    run_qse(0, 1'b0);
    stall_h <= 0;

    // no-answer / empty Q_BOUND
    run_poke(8'd0, 8'd0, 8'd0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0);
    if (n_emit != 0 || n_scored != 0) diverge("CLASS_ID_MISMATCH", "empty emit");
    if (ovf) diverge("OVERFLOW_STATUS_LOST", "empty ovf");
    for (i = 0; i < K; i = i + 1) begin
      if (top_id[i] !== (U6_PAD_BASE + i))
        diverge("TOPK_MISMATCH", "empty pad");
      if (top_sc[i] !== 16'sd0) diverge("TOPK_MISMATCH", "empty sc");
    end
    $display("EMPTY n=0 pads ok");

    // exact K=8 iid=1 rid=3
    run_poke(8'd0, 8'd1, 8'd3, 8'd0, 1'b0, 1'b1, 1'b1, 1'b0);
    if (n_emit != 16'(U6_EXACT8_N)) diverge("CLASS_ID_MISMATCH", "exact8 n");
    for (i = 0; i < 8; i = i + 1) begin
      if (got_id[i] !== U6_EXACT8_ID[i]) diverge("CLASS_ID_MISMATCH", "exact8 cand");
      if (top_id[i] !== U6_EXACT8_TID[i]) diverge("TOPK_MISMATCH", "exact8 top");
      if (top_sc[i] !== U6_EXACT8_TSC[i]) diverge("TOPK_MISMATCH", "exact8 sc");
    end
    high = 0;
    for (i = 0; i < K; i = i + 1)
      if (top_cid[i] > 16'd255) high = 1;
    if (!high) diverge("CLASS_ID_MISMATCH", "exact8 high id");
    $display("EXACT8 n=8 high_id ok");

    // reset mid-scan
    poke <= 1; pe <= 8'd1; pi <= 0; pr <= 0; px <= 0;
    pev <= 1; piv <= 0; prv <= 0; pxv <= 0;
    @(posedge clk); poke_go <= 1; @(posedge clk); poke_go <= 0;
    repeat (30) @(posedge clk);
    rst_n <= 0; repeat (4) @(posedge clk); rst_n <= 1;
    repeat (8) @(posedge clk);
    poke <= 0;
    run_qse(0, 1'b0);

    // reset after accept before heap (S_SCW=5)
    poke <= 1; pe <= 8'd1; pi <= 0; pr <= 0; px <= 0;
    pev <= 1; piv <= 0; prv <= 0; pxv <= 0;
    @(posedge clk); poke_go <= 1; @(posedge clk); poke_go <= 0;
    tmo = 0;
    while (st != 4'd5 && tmo < 20000) begin @(posedge clk); tmo = tmo + 1; end
    rst_n <= 0; repeat (4) @(posedge clk); rst_n <= 1;
    repeat (8) @(posedge clk);
    poke <= 0;
    run_qse(0, 1'b0);

    // poison A: decoy NID
    poke <= 1; pe <= 8'hFF; pi <= 0; pr <= 0; px <= 0;
    pev <= 0; piv <= 0; prv <= 0; pxv <= 0;
    @(posedge clk); poke_go <= 1; @(posedge clk); poke_go <= 0;
    // empty-bound poke_go also starts a query; wait it
    wait_done();
    poke <= 0;
    if (legacy_nid !== 32'h00ABCDEF) diverge("LEGACY_NID_PATH_CAUSAL", "decoy not poisoned");
    run_qse(0, 1'b0);
    for (i = 0; i < K; i = i + 1)
      if (top_id[i] == 32'h00ABCDEF)
        diverge("LEGACY_NID_PATH_CAUSAL", "decoy in topk");
    $display("POISON_A decoy unused ok");

    // poison B: class 57 eid=99 — QSE chiller, do not compare unpoisoned gold
    poi_en <= 1; poi_cid <= 16'd57; poi_e <= 8'd99;
    poke <= 0; poke_go <= 0; stall_s <= 0; stall_h <= 0;
    got = 0; got_sc = 0;
    retire <= 1; @(posedge clk); retire <= 0;
    @(posedge clk);
    for (bi = 0; bi < U6_QLEN[0]; bi = bi + 1) begin
      @(posedge clk);
      tok_v <= 1; tok <= U6_QBYTES[0][8*bi +: 8];
      @(posedge clk); tok_v <= 0;
    end
    @(posedge clk); fire <= 1; @(posedge clk); fire <= 0;
    tmo = 0;
    while (!qse_v && tmo < 4000) begin @(posedge clk); tmo = tmo + 1; end
    wait_done();
    for (i = 0; i < K; i = i + 1) begin
      if (top_id[i] !== U6_POIB_TID[i])
        diverge("TYPECLASS_PATH_NOT_CAUSAL", $sformatf("i=%0d act=%0h exp=%0h", i, top_id[i], U6_POIB_TID[i]));
      if (top_sc[i] !== U6_POIB_TSC[i])
        diverge("TYPECLASS_PATH_NOT_CAUSAL", "score");
    end
    if (top_cid[0] == 16'd57) diverge("TYPECLASS_PATH_NOT_CAUSAL", "57 still top");
    poi_en <= 0;
    $display("POISON_B class57 dropped ok");

    // cap8 leak_check = confirm q 8
    poke8 <= 1;
    pe8 <= U6_QE[8]; pi8 <= U6_QI[8]; pr8 <= U6_QR[8]; px8 <= U6_QX[8];
    pev8 <= U6_EV[8]; piv8 <= U6_IV[8]; prv8 <= U6_RV[8]; pxv8 <= U6_XV[8];
    @(posedge clk); go8 <= 1; @(posedge clk); go8 <= 0;
    tmo = 0;
    while (!done8 && tmo < 200000) begin @(posedge clk); tmo = tmo + 1; end
    if (!done8) diverge("EARLY_DONE", "cap8");
    @(posedge clk);
    if (!ovf8) diverge("OVERFLOW_STATUS_LOST", "cap8 must ovf");
    if (e8 != 16'(U6_CAP8_N)) diverge("OVERFLOW_STATUS_LOST", "cap8 n");
    if (t8 != 16'(U6_CAP8_TRUNC)) diverge("OVERFLOW_STATUS_LOST", "cap8 trunc");
    for (i = 0; i < K; i = i + 1)
      if (top8_id[i] !== U6_CAP8_TID[i])
        diverge("TOPK_MISMATCH", "cap8 top");
    $display("CAP8 emit=%0d trunc=%0d ovf=1", e8, t8);

    $display("U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS");
    $display("CLAIM=The FPGA-owned TYPE_CLASS masked-conjunctive retrieval path is the single authoritative candidate source feeding the production scorer and exact Top-K path, with bit-exact class/materialization/score identity in XSim");
    $display("NOT_CLAIMED=NLU,learning,Q-head,LM,board,GATE14,U6_silicon");
    #20 $finish;
  end
endmodule
