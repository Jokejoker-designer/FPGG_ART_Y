// tb_u4b_c9_bind_width.sv — 20-bit ID through C9 glue + LM bind. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_u4b_c9_bind_width;
  import a7ng_pkg::*;
  logic clk, rst_n;
  integer fail, i;
  node_id_t ids [8];
  score_t   scs [8];
  logic [63:0]  c9_8;
  logic [159:0] c9_20;
  logic [127:0] c9_sc;
  logic [31:0]  gid [0:7];
  logic [63:0]  ctx8;
  logic [159:0] ctx20;
  logic         bsy, dn, we, sf, capv;
  logic [6:0]   cidx, cn;
  logic [9:0]   bpred;
  logic [31:0]  wbeats, sbeats;

  initial clk = 0;
  always #5 clk = ~clk;

  a7ng_gate14_c9_glue u_glue (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(1'b0), .cmd_ready_o(), .cmd_i(4'd0), .tok_i(8'd0), .reward_i(4'd0),
    .host_cue_i(64'd0), .host_winner_i(32'd0), .host_addr_i(32'd0),
    .host_next_i(10'd0), .host_wren_i(1'b0), .host_mode_i(4'd0),
    .p_learn_o(), .p_freeze_o(), .p_qvalid_o(), .p_qready_i(1'b1), .p_qid_o(),
    .p_snap_v_i(1'b0), .p_snap_r_o(),
    .p_topk_id_i(ids), .p_topk_sc_i(scs),
    .p_evs_i(32'd0), .p_evr_i(8'd0), .p_evo_i(32'd0),
    .p_pending_i(1'b0), .p_txn_i(16'd0),
    .p_rew_v_o(), .p_rew_o(), .p_echo_v_o(), .p_echo_o(),
    .p_ack_v_i(1'b0), .p_ack_i(3'd0), .p_c7_i(1'b0),
    .p_flush_o(), .p_reload_o(), .p_kill_o(), .p_trst_o(), .p_busy_i(1'b0),
    .lm_start_o(), .lm_busy_i(1'b0), .lm_done_i(1'b0), .lm_pred_i(10'd0),
    .c1_mode_o(), .c2_anch_o(),
    .c9_topk_o(c9_8), .c9_id20_o(c9_20), .c9_score_o(c9_sc),
    .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(), .c10_lmdn_o(), .c10_out_o(),
    .n_host_cue_o(), .n_host_win_o(), .n_host_addr_o(),
    .n_host_tok_o(), .n_host_w_o(), .n_host_mode_o(),
    .teacher_active_o(), .ext_llm_active_o(), .last_ack_o(), .exam_lm_used_o()
  );

  a7ng_native_ctx_bind u_bind (
    .clk(clk), .rst_n(rst_n),
    .grant_lm_i(1'b1), .start_i(1'b1), .do_start_i(1'b0),
    .global_id_i(gid),
    .core_busy_i(1'b0), .core_done_i(1'b0), .core_pred_i(10'd0),
    .busy_o(bsy), .done_o(dn),
    .ctx_we_o(we), .ctx_idx_o(cidx), .ctx_n_in_o(cn),
    .ctx_pack_o(ctx8), .ctx_pack20_o(ctx20),
    .start_fwd_o(sf), .pred_o(bpred),
    .ctx_we_beats_o(wbeats), .start_fwd_beats_o(sbeats),
    .capture_valid_o(capv)
  );

  initial begin
    fail = 0;
    rst_n = 0;
    for (i = 0; i < 8; i = i + 1) begin
      ids[i] = '0;
      scs[i] = '0;
      gid[i] = 32'd0;
    end
    ids[0] = 32'h000C_34FF;
    ids[1] = 32'h0000_00FF;
    gid[0] = 32'h000C_34FF;
    gid[1] = 32'h0000_00FF;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (6) @(posedge clk);
    if (c9_20[19:0] !== 20'hC34FF) begin fail = fail + 1; $display("C9_20 %h", c9_20[19:0]); end
    if (c9_8[7:0] !== 8'hFF) begin fail = fail + 1; $display("C9_DIAG8 %h", c9_8[7:0]); end
    if (c9_20[19:0] === {12'd0, c9_8[7:0]}) begin
      fail = fail + 1; $display("C9_LIVE_EQ_DIAG8");
    end
    if (ctx20[19:0] !== 20'hC34FF) begin fail = fail + 1; $display("CTX20 %h capv=%0b", ctx20[19:0], capv); end
    if (ctx8[7:0] !== 8'hFF) begin fail = fail + 1; $display("CTX8 %h", ctx8[7:0]); end
    if (ctx20[19:0] === {12'd0, ctx8[7:0]}) begin
      fail = fail + 1; $display("CTX_LIVE_EQ_DIAG8");
    end
    if (fail == 0) $display("U4B_C9_BIND_WIDTH_PASS sentinel=C34FF");
    else $display("U4B_C9_BIND_WIDTH_FAIL fail=%0d", fail);
    #20 $finish;
  end
endmodule
