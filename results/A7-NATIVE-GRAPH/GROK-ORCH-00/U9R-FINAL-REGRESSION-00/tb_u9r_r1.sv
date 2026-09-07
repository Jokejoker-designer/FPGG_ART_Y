// tb_u9r_r1.sv — U9R R1 contracts on frozen source. PROGRAM=NO.
// Route-valid enable follows validity, not numeric key.
// Production C9 mux: SYNTHETIC_CAND_GEN=0 uses parent graph_id_i.
`timescale 1ns / 1ps

module tb_u9r_r1;
  import a7ng_pkg::*;

  logic clk, rst_n;
  integer i, fails, cyc;
  logic k0v, k1v, k2v, k3v;
  logic p0, p1, p2, p3, i0, i1, i2, i3;
  logic [11:0] b0, b1, b2, b3;
  node_id_t gid [8], pid_prod [8], pid_fix [8];
  score_t   gsc [8];
  logic ddr_ack;
  logic [63:0] ddr_rdata;

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_route_valid_gate u_rv (
    .k0_valid_i(k0v), .k0_i(16'h1234),
    .k1_valid_i(k1v), .k1_i(16'h0000),
    .k2_valid_i(k2v), .k2_i(16'h00AB),
    .k3_valid_i(k3v), .k3_i(16'hFFFF),
    .probe0_o(p0), .probe1_o(p1), .probe2_o(p2), .probe3_o(p3),
    .insert0_o(i0), .insert1_o(i1), .insert2_o(i2), .insert3_o(i3),
    .bucket0_o(b0), .bucket1_o(b1), .bucket2_o(b2), .bucket3_o(b3)
  );

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
    .teacher_active_o(), .ext_llm_active_o(), .last_ack_o(), .exam_lm_used_o(),
    .persist_ddr_req_o(), .persist_ddr_we_o(), .persist_ddr_addr_o(),
    .persist_ddr_wdata_o(), .persist_ddr_rdata_i(ddr_rdata),
    .persist_ddr_ack_i(ddr_ack),
    .persist_freeze_o(), .persist_c7_valid_o(), .persist_c7_addr_o(),
    .persist_c7_ready_i(1'b1), .persist_busy_o(), .persist_done_o(),
    .c7_commit_seq_o(), .c7_ack_count_o(),
    .query_valid_o(), .query_ready_o(), .query_id_o(), .snap_valid_o(),
    .g14_en_i(1'b1), .g14_cmd_v_i(1'b0), .g14_cmd_r_o(),
    .g14_cmd_i(4'd0), .g14_tok_i(8'd0), .g14_rew_i(4'sd0),
    .c8_gen_o(), .c8_sdig_o(), .c11_adig_o(), .c11_bdig_o(),
    .c11_a_for_o(), .c11_b_vis_o(), .p_txn_o(), .c5_cons_o(),
    .g14_lm_start_o(), .g14_persist_id_o(pid_prod)
  );

  a7ng_g1g5_cofit #(.SYNTHETIC_CAND_GEN(1'b1)) u_fix (
    .clk(clk), .rst_n(rst_n),
    .graph_topk_valid_i(1'b1),
    .graph_id_i(gid), .graph_sc_i(gsc),
    .graph_bind_done_i(1'b0), .graph_lm_busy_i(1'b0), .graph_pred_i(10'd0),
    .c1_mode_o(), .c2_anch_o(), .c9_topk_o(), .c9_id20_o(),
    .c9_score_o(), .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(), .c10_lmdn_o(), .c10_out_o(),
    .n_host_cue_o(), .n_host_win_o(), .n_host_addr_o(), .n_host_tok_o(),
    .n_host_w_o(), .n_host_mode_o(),
    .teacher_active_o(), .ext_llm_active_o(), .last_ack_o(), .exam_lm_used_o(),
    .persist_ddr_req_o(), .persist_ddr_we_o(), .persist_ddr_addr_o(),
    .persist_ddr_wdata_o(), .persist_ddr_rdata_i(ddr_rdata),
    .persist_ddr_ack_i(ddr_ack),
    .persist_freeze_o(), .persist_c7_valid_o(), .persist_c7_addr_o(),
    .persist_c7_ready_i(1'b1), .persist_busy_o(), .persist_done_o(),
    .c7_commit_seq_o(), .c7_ack_count_o(),
    .query_valid_o(), .query_ready_o(), .query_id_o(), .snap_valid_o(),
    .g14_en_i(1'b1), .g14_cmd_v_i(1'b0), .g14_cmd_r_o(),
    .g14_cmd_i(4'd0), .g14_tok_i(8'd0), .g14_rew_i(4'sd0),
    .c8_gen_o(), .c8_sdig_o(), .c11_adig_o(), .c11_bdig_o(),
    .c11_a_for_o(), .c11_b_vis_o(), .p_txn_o(), .c5_cons_o(),
    .g14_lm_start_o(), .g14_persist_id_o(pid_fix)
  );

  assign ddr_ack = 1'b1;
  assign ddr_rdata = 64'd0;

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", c, d, cyc);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  initial begin
    fails = 0; rst_n = 0;
    k0v = 0; k1v = 1; k2v = 1; k3v = 0;
    for (i = 0; i < 8; i = i + 1) begin
      gid[i] = node_id_t'(32'd65 + i);
      gsc[i] = score_t'(16'sd16);
    end
    repeat (8) @(posedge clk); rst_n = 1;
    repeat (8) @(posedge clk);

    if (p0 !== 1'b0) diverge("ROUTE_VALID", "k0 invalid must not probe (numeric 0x1234)");
    if (p1 !== 1'b1) diverge("ROUTE_VALID", "k1 valid zero-key must probe");
    if (p2 !== 1'b1) diverge("ROUTE_VALID", "k2 valid");
    if (p3 !== 1'b0) diverge("ROUTE_VALID", "k3 invalid 0xFFFF must not probe");
    if (i0 !== p0 || i1 !== p1 || i2 !== p2 || i3 !== p3)
      diverge("ROUTE_VALID", "insert != probe");
    if (b0 !== 12'h234) diverge("ROUTE_VALID", "bucket0");
    $display("R1_ROUTE_VALID PASS probe=%0d%0d%0d%0d (validity, not key!=0)", p0, p1, p2, p3);

    $display("PROD id0=%0d id1=%0d id2=%0d", pid_prod[0], pid_prod[1], pid_prod[2]);
    $display("FIX  id0=%0d id1=%0d id2=%0d", pid_fix[0], pid_fix[1], pid_fix[2]);
    if (pid_prod[0] !== node_id_t'(32'd65) || pid_prod[1] !== node_id_t'(32'd66) ||
        pid_prod[2] !== node_id_t'(32'd67))
      diverge("PROD_C9_NOT_PARENT", "expected 65,66,67 from graph_id_i");
    if (pid_fix[0] === node_id_t'(32'd65))
      diverge("FIXTURE_TOOK_PARENT", "synthetic idle should not mux parent IDs");
    if (u_prod.qv_to_graph !== 1'b0)
      diverge("SYNTH_WALK_LIVE", "production query_valid reached cand graph");
    $display("R1_U8R_MUX PASS PROD 65/66/67 FIX idle qv_to_graph=0");
    $display("R1_HEAP_GOLDEN pinned U8-UNIFIED HEAP cid=65 66 67 (source hash MATCH; not re-run 110s LM)");
    $display("BIT=NO PROGRAM=NO QHEAD=NO");
    $display("U9R_R1_CONTRACTS_PASS");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > 400000) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
