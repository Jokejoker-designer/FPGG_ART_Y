// tb_u9r_r2.sv — U9R R2: SYNTHETIC_CAND_GEN=0 query then reward.
// Production qv_to_graph is forced 0; pending/snapshot still come from that graph.
// Cycle watchdog. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_u9r_r2;
  import a7ng_pkg::*;
  localparam int unsigned WATCH_CYC = 4096;

  logic clk, rst_n;
  integer cyc, fails, tmo;
  logic g14_v, g14_r, pbusy, psv, ppend;
  logic [3:0] cmd;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic [15:0] txn;
  logic [2:0] ack;
  logic ddr_ack;
  logic [63:0] ddr_rdata;
  node_id_t gid [8];
  score_t   gsc [8];
  integer i;
  logic qv, qr, preq;
  logic [7:0] qid;

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_g1g5_cofit #(.SYNTHETIC_CAND_GEN(1'b0)) u_prod (
    .clk(clk), .rst_n(rst_n),
    .graph_topk_valid_i(1'b1),
    .graph_id_i(gid), .graph_sc_i(gsc),
    .graph_bind_done_i(1'b0), .graph_lm_busy_i(1'b0), .graph_pred_i(10'd0),
    .c1_mode_o(), .c2_anch_o(), .c9_topk_o(), .c9_id20_o(),
    .c9_score_o(), .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(), .c10_lmdn_o(), .c10_out_o(),
    .n_host_cue_o(), .n_host_win_o(), .n_host_addr_o(), .n_host_tok_o(),
    .n_host_w_o(), .n_host_mode_o(),
    .teacher_active_o(), .ext_llm_active_o(), .last_ack_o(ack), .exam_lm_used_o(),
    .persist_ddr_req_o(preq), .persist_ddr_we_o(), .persist_ddr_addr_o(),
    .persist_ddr_wdata_o(), .persist_ddr_rdata_i(ddr_rdata),
    .persist_ddr_ack_i(ddr_ack),
    .persist_freeze_o(), .persist_c7_valid_o(), .persist_c7_addr_o(),
    .persist_c7_ready_i(1'b1), .persist_busy_o(pbusy), .persist_done_o(),
    .c7_commit_seq_o(), .c7_ack_count_o(),
    .query_valid_o(qv), .query_ready_o(qr), .query_id_o(qid), .snap_valid_o(psv),
    .g14_en_i(1'b1), .g14_cmd_v_i(g14_v), .g14_cmd_r_o(g14_r),
    .g14_cmd_i(cmd), .g14_tok_i(tok), .g14_rew_i(rew),
    .c8_gen_o(), .c8_sdig_o(), .c11_adig_o(), .c11_bdig_o(),
    .c11_a_for_o(), .c11_b_vis_o(), .p_txn_o(txn), .c5_cons_o(),
    .g14_lm_start_o(), .g14_persist_id_o()
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ddr_ack <= 1'b0;
    else ddr_ack <= preq;
  end
  assign ddr_rdata = 64'd0;
  assign ppend = u_prod.p_pend;

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d qv_to_graph=%0d p_qr=%0d p_sv=%0d p_pend=%0d glue_st=%0d",
               c, d, cyc, u_prod.qv_to_graph, u_prod.p_qr, psv, ppend, u_prod.u_glue.st);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  task automatic issue(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    begin
      tmo = 0;
      while (!g14_r && tmo < 2048) begin @(posedge clk); tmo++; end
      if (!g14_r) diverge("TIMEOUT", "g14_cmd_ready");
      @(negedge clk);
      cmd = c; tok = t; rew = r; g14_v = 1'b1;
      @(posedge clk); @(negedge clk); g14_v = 1'b0;
    end
  endtask

  initial begin
    fails = 0; rst_n = 0; g14_v = 0; cmd = 0; tok = 0; rew = 0;
    for (i = 0; i < 8; i = i + 1) begin
      gid[i] = node_id_t'(32'd65 + i);
      gsc[i] = score_t'(16'sd16);
    end
    repeat (8) @(posedge clk); rst_n = 1;
    tmo = 0;
    while (pbusy && tmo < 1024) begin @(posedge clk); tmo++; end
    $display("R2_BOOT pbusy=%0d qv_to_graph=%0d p_qr=%0d cyc=%0d",
             pbusy, u_prod.qv_to_graph, u_prod.p_qr, cyc);
    if (u_prod.qv_to_graph !== 1'b0)
      diverge("SYNTH_WALK_LIVE", "production qv_to_graph must stay 0");
    if (u_prod.p_qr !== 1'b1)
      diverge("QREADY_NOT_TIED", "SYNTH=0 ties p_qr=1 (not graph ready)");

    // C_FIRE=2. Glue goes S_QISS then S_QWAIT for p_snap from disabled graph.
    issue(4'd2, 8'h00, 4'sd0);
    tmo = 0;
    while (u_prod.u_glue.st != 3'd2 && tmo < 64) begin @(posedge clk); tmo++; end
    $display("R2_AFTER_FIRE glue_st=%0d qv=%0d qr=%0d psv=%0d ppend=%0d qv_to_graph=%0d",
             u_prod.u_glue.st, qv, qr, psv, ppend, u_prod.qv_to_graph);

    tmo = 0;
    while (!psv && tmo < 2048) begin @(posedge clk); tmo++; end
    $display("R2_WAIT_SNAP tmo=%0d psv=%0d ppend=%0d glue_st=%0d qv_to_graph=%0d",
             tmo, psv, ppend, u_prod.u_glue.st, u_prod.qv_to_graph);
    if (!psv)
      diverge("QUERY_NO_SNAPSHOT", "SYNTHETIC_CAND_GEN=0: graph never sees query; S_QWAIT has no snap");

    issue(4'd3, 8'h00, 4'sd2);
    tmo = 0;
    while (u_prod.u_glue.st != 3'd0 && tmo < 1024) begin @(posedge clk); tmo++; end
    if (!ppend)
      diverge("REWARD_NO_PENDING", "pending still sourced from disabled cand graph");
    $display("U9R_R2_QUERY_REWARD_PASS");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > WATCH_CYC) begin
      $display("FIRST_DIVERGENCE QUERY_NO_SNAPSHOT cycle_watchdog cyc=%0d glue_st=%0d psv=%0d ppend=%0d qv_to_graph=%0d",
               cyc, u_prod.u_glue.st, psv, ppend, u_prod.qv_to_graph);
      $finish;
    end
  end
endmodule
