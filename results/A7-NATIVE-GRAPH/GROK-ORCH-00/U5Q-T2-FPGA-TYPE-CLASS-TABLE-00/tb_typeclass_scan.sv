// tb_typeclass_scan.sv — U5Q-T2. PROGRAM=NO. U7A=CLOSED.
`timescale 1ns / 1ps

module tb_typeclass_scan;
  import a7ng_pkg::*;
  `include "typeclass_table.svh"

  logic clk, rst_n, go, qr, cv, cr, done, ovf;
  logic [7:0] qe, qi, qr8, qx;
  logic ev, iv, rv, xv;
  logic [15:0] cid, n_emit, n_trunc;
  integer qn, i, tmo, got, stall_n, bi;
  logic [15:0] got_id [0:63];

  a7ng_typeclass_scan #(.CAND_CAP(64)) dut (
    .clk(clk), .rst_n(rst_n),
    .q_go_i(go), .q_ready_o(qr),
    .q_eid_i(qe), .q_iid_i(qi), .q_rid_i(qr8), .q_xid_i(qx),
    .q_ev_i(ev), .q_iv_i(iv), .q_rv_i(rv), .q_xv_i(xv),
    .cand_v_o(cv), .cand_ready_i(cr), .cand_id_o(cid),
    .q_done_o(done), .q_overflow_o(ovf),
    .n_emit_o(n_emit), .n_trunc_o(n_trunc)
  );

  logic go8, qr8r, cv8, cr8, done8, ovf8;
  logic [15:0] cid8, e8, t8;
  a7ng_typeclass_scan #(.CAND_CAP(8)) u_cap8 (
    .clk(clk), .rst_n(rst_n),
    .q_go_i(go8), .q_ready_o(qr8r),
    .q_eid_i(qe), .q_iid_i(qi), .q_rid_i(qr8), .q_xid_i(qx),
    .q_ev_i(ev), .q_iv_i(iv), .q_rv_i(rv), .q_xv_i(xv),
    .cand_v_o(cv8), .cand_ready_i(cr8), .cand_id_o(cid8),
    .q_done_o(done8), .q_overflow_o(ovf8),
    .n_emit_o(e8), .n_trunc_o(t8)
  );

  // QSE for CUT A
  logic tok_v, tok_r, fire, retire, qse_v;
  logic [7:0] tok, se, si, sr, sx;
  logic [15:0] k0, k1, k2, k3, n_host;
  logic v0, v1, v2, v3;
  logic [63:0] dummy64;
  logic [15:0] dummy16;
  a7ng_query_struct_extract u_qse (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .busy_o(), .accepted_o(), .valid_o(qse_v),
    .entity_id_o(se), .intent_id_o(si), .relation_id_o(sr), .context_id_o(sx),
    .entity_cue_o(dummy64), .intent_cue_o(), .relation_cue_o(), .context_cue_o(),
    .crc16_dbg_o(dummy16), .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3),
    .k0_valid_o(v0), .k1_valid_o(v1), .k2_valid_o(v2), .k3_valid_o(v3),
    .n_host_entity_o(n_host), .n_host_intent_o(), .n_host_hash_o(),
    .n_host_shard_o(), .n_host_bucket_o(), .n_host_cand_o(),
    .n_host_winner_o(), .n_host_addr_o(), .n_host_relpath_o(),
    .n_host_next_o(), .n_host_answer_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
      #20 $finish;
    end
  endtask

  task automatic run_q(input int q, input bit stall);
    begin
      while (!qr) @(posedge clk);
      got = 0;
      @(posedge clk);
      qe <= TC_QE[q]; qi <= TC_QI[q]; qr8 <= TC_QR[q]; qx <= TC_QX[q];
      ev <= TC_EV[q]; iv <= TC_IV[q]; rv <= TC_RV[q]; xv <= TC_XV[q];
      go <= 1; cr <= 1;
      @(posedge clk); go <= 0;
      tmo = 0;
      while (!done) begin
        @(posedge clk);
        if (stall) cr <= ~cr;
        else cr <= 1'b1;
        if (cv && cr) begin
          if (got >= 64) diverge("DUP_OR_OVERFLOW", "too many emits");
          got_id[got] = cid;
          got = got + 1;
        end
        tmo = tmo + 1;
        if (tmo > 20000) diverge("EARLY_DONE", "timeout");
      end
      @(posedge clk);
      if (n_host != 0) diverge("HOST_SEMANTIC_LEAK", "n_host");
      if (n_emit != 16'(TC_NEXP[q]))
        diverge("CAND_COUNT", $sformatf("q=%0d act=%0d exp=%0d", q, n_emit, TC_NEXP[q]));
      if (got != TC_NEXP[q])
        diverge("CAND_COUNT", $sformatf("got=%0d exp=%0d", got, TC_NEXP[q]));
      if (TC_NEXP[q] == 0 && ovf) diverge("OVERFLOW", "no-answer ovf");
      if (TC_NEXP[q] != 0 && ovf) diverge("OVERFLOW", "cap64 should not ovf T1");
      for (i = 0; i < TC_NEXP[q]; i = i + 1) begin
        if (got_id[i] !== TC_EXP[q*TC_MAXH + i])
          diverge("CLASS_ID_MISMATCH",
            $sformatf("q=%0d i=%0d act=%0d exp=%0d", q, i, got_id[i], TC_EXP[q*TC_MAXH+i]));
        if (got_id[i] > 16'd255 && q == 0)
          ; // chiller ids start 57
      end
      $display("Q%0d n=%0d top0=%0d ovf=%0d", q, n_emit, (got?got_id[0]:0), ovf);
    end
  endtask

  initial begin
    rst_n = 0; go = 0; cr = 1; go8 = 0; cr8 = 1;
    tok_v = 0; tok = 0; fire = 0; retire = 0;
    qe = 0; qi = 0; qr8 = 0; qx = 0; ev = 0; iv = 0; rv = 0; xv = 0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    if (TC_ID[0] != 16'd1) diverge("TABLE", "first CLASS_ID");
    if (TC_ID[TC_N-1] != 16'd443) diverge("TABLE", "last CLASS_ID");
    if (TC_ID[255] < 16'd256) diverge("HIGH_ID", "class 256 missing");

    // CUT C/D T1 confirmation (poke fields = T1 host)
    for (qn = 0; qn < TC_NQ; qn = qn + 1)
      run_q(qn, 1'b0);

    // stalls
    run_q(0, 1'b1);

    // high CLASS_ID present in relation_mismatch (q index 10)
    run_q(10, 1'b0);
    begin : high_id
      integer hi;
      hi = 0;
      for (i = 0; i < got; i = i + 1)
        if (got_id[i] > 16'd255) hi = 1;
      if (!hi) diverge("HIGH_ID", "expected class_id>255 in duct query");
    end

    // overflow protocol CAND_CAP=8 on leak_check (47 hits) — q=8
    while (!qr8r) @(posedge clk);
    qe <= TC_QE[8]; qi <= TC_QI[8]; qr8 <= TC_QR[8]; qx <= TC_QX[8];
    ev <= TC_EV[8]; iv <= TC_IV[8]; rv <= TC_RV[8]; xv <= TC_XV[8];
    @(posedge clk); go8 <= 1; cr8 <= 1;
    @(posedge clk); go8 <= 0;
    tmo = 0;
    while (!done8) begin
      @(posedge clk);
      tmo = tmo + 1;
      if (tmo > 20000) diverge("EARLY_DONE", "cap8 timeout");
    end
    @(posedge clk);
    if (!ovf8) diverge("OVERFLOW", "cap8 leak_check must ovf");
    if (e8 != 16'd8) diverge("OVERFLOW", $sformatf("emit=%0d", e8));
    if (t8 == 0) diverge("OVERFLOW", "trunc=0");
    $display("OVF_CAP8 emit=%0d trunc=%0d", e8, t8);

    // reset mid-scan
    while (!qr) @(posedge clk);
    qe <= TC_QE[0]; qi <= TC_QI[0]; qr8 <= TC_QR[0]; qx <= TC_QX[0];
    ev <= 1; iv <= 0; rv <= 0; xv <= 0;
    @(posedge clk); go <= 1; @(posedge clk); go <= 0;
    repeat (20) @(posedge clk);
    rst_n <= 0; repeat (4) @(posedge clk); rst_n <= 1;
    repeat (4) @(posedge clk);
    if (!qr) diverge("RESET", "not idle after rst");
    run_q(0, 1'b0);

    // CUT A: QSE chiller (q0) fields then scan
    while (!qr) @(posedge clk);
    retire <= 1; @(posedge clk); retire <= 0;
    for (bi = 0; bi < TC_QLEN[0]; bi = bi + 1) begin
      @(posedge clk); tok_v <= 1; tok <= TC_QBYTES[0][8*bi +: 8];
      @(posedge clk); tok_v <= 0;
    end
    @(posedge clk); fire <= 1; @(posedge clk); fire <= 0;
    tmo = 0;
    while (!qse_v && tmo < 2000) begin @(posedge clk); tmo = tmo + 1; end
    if (se !== TC_QE[0] || si !== TC_QI[0] || sr !== TC_QR[0] || sx !== TC_QX[0])
      diverge("QSE_FIELDS", $sformatf("se=%0d si=%0d", se, si));
    qe <= se; qi <= si; qr8 <= sr; qx <= sx;
    ev <= (se != 0); iv <= (si != 0); rv <= (sr != 0); xv <= (sx != 0);
    run_q(0, 1'b0);

    $display("U5Q_T2_TYPECLASS_TABLE_PASS");
    $display("CLAIM=FPGA RTL implements frozen TYPE_CLASS catalog and masked-conjunctive law bit-exactly in XSim");
    $display("NOT_CLAIMED=NLU,U6_typeclass_integrate,U7,LM,board,GATE14");
    #20 $finish;
  end
endmodule
