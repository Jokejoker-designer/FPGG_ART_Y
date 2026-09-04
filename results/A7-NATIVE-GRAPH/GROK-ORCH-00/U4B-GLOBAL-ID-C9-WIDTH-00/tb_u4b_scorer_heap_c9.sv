// tb_u4b_scorer_heap_c9.sv — 20-bit ID through scorer, Global TopK, C9 glue.
// UART C9 64-bit pack stays diagnostic. PROGRAM=NO. Oracle HOLD.
`timescale 1ns / 1ps

module tb_u4b_scorer_heap_c9;
  import a7ng_pkg::*;
  logic clk, rst_n;
  integer fail, i;

  logic sc_v_i, sc_v_o;
  node_id_t sc_id_i, sc_id_o;
  score_terms_t terms;
  score_t sc_s_o;

  logic tk_v_i, tk_v_o;
  logic [15:0] tk_mask;
  score_t tk_s_i [16], tk_s_o [8];
  node_id_t tk_id_i [16], tk_id_o [8];

  node_id_t glue_ids [8];
  score_t   glue_sc  [8];
  logic [63:0]  c9_8;
  logic [159:0] c9_20;
  logic [127:0] c9_sc;

  a7ng_scorer_lane u_sc (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_v_i), .cand_id_i(sc_id_i), .terms_i(terms),
    .valid_o(sc_v_o), .cand_id_o(sc_id_o), .score_o(sc_s_o)
  );

  a7ng_topk #(.N(16), .K(8)) u_tk (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tk_v_i), .valid_mask_i(tk_mask),
    .score_i(tk_s_i), .id_i(tk_id_i),
    .valid_o(tk_v_o), .score_o(tk_s_o), .id_o(tk_id_o)
  );

  a7ng_gate14_c9_glue u_glue (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(1'b0), .cmd_ready_o(), .cmd_i(4'd0), .tok_i(8'd0), .reward_i(4'd0),
    .host_cue_i(64'd0), .host_winner_i(32'd0), .host_addr_i(32'd0),
    .host_next_i(10'd0), .host_wren_i(1'b0), .host_mode_i(4'd0),
    .p_learn_o(), .p_freeze_o(), .p_qvalid_o(), .p_qready_i(1'b1), .p_qid_o(),
    .p_snap_v_i(1'b0), .p_snap_r_o(),
    .p_topk_id_i(glue_ids), .p_topk_sc_i(glue_sc),
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

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    fail = 0;
    rst_n = 0; sc_v_i = 0; tk_v_i = 0; tk_mask = 16'd0;
    terms = '0; sc_id_i = '0;
    for (i = 0; i < 16; i = i + 1) begin tk_s_i[i] = '0; tk_id_i[i] = '0; end
    for (i = 0; i < 8; i = i + 1) begin glue_ids[i] = '0; glue_sc[i] = '0; end
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // --- scorer preserves 20-bit sentinel ---
    terms = '0;
    terms.entity_match = 8'sd40;
    sc_id_i = {12'd0, NG_ID_SENTINEL_20};
    sc_v_i = 1'b1;
    @(posedge clk);
    sc_v_i = 1'b0;
    repeat (4) @(posedge clk);
    if (sc_id_o[19:0] !== NG_ID_SENTINEL_20) begin
      fail = fail + 1; $display("SCORER_ID %h", sc_id_o);
    end

    // --- global TopK 16->8: sentinel best ---
    tk_mask = 16'h0007;
    tk_id_i[0] = 32'd1;           tk_s_i[0] = 16'sd10;
    tk_id_i[1] = {12'd0, NG_ID_SENTINEL_20}; tk_s_i[1] = 16'sd99;
    tk_id_i[2] = 32'd2;           tk_s_i[2] = 16'sd20;
    @(posedge clk);
    tk_v_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    if (!tk_v_o) begin fail = fail + 1; $display("TOPK_NO_VALID"); end
    $display("TOPK_DBG v=%0b id0=%h id1=%h", tk_v_o, tk_id_o[0], tk_id_o[1]);
    tk_v_i = 1'b0;
    if (tk_id_o[0][19:0] !== NG_ID_SENTINEL_20) begin
      fail = fail + 1; $display("TOPK_ID %h", tk_id_o[0]);
    end
    if ((tk_id_o[0][19:8] != 12'd0) && (tk_id_o[0][19:0] === {12'd0, tk_id_o[0][7:0]})) begin
      fail = fail + 1; $display("TOPK_LOW8_ALIAS");
    end

    for (i = 0; i < 8; i = i + 1) begin
      glue_ids[i] = tk_id_o[i];
      glue_sc[i]  = tk_s_o[i];
    end
    #1;
    if (c9_20[19:0] !== NG_ID_SENTINEL_20) begin
      fail = fail + 1; $display("C9_20 %h", c9_20[19:0]);
    end
    if (c9_8[7:0] !== 8'hFF) begin
      fail = fail + 1; $display("C9_DIAG %h", c9_8[7:0]);
    end
    if (c9_20[19:0] === {12'd0, c9_8[7:0]}) begin
      fail = fail + 1; $display("C9_LIVE_COLLAPSED");
    end
    if (fail == 0) $display("U4B_SCORER_HEAP_C9_PASS sentinel=C34FF");
    else $display("U4B_SCORER_HEAP_C9_FAIL fail=%0d", fail);
    #20 $finish;
  end
endmodule
