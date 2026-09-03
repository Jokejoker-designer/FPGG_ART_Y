// tb_a7ng_c12_host_obs.sv — C12 samples live host_* wires, not UART-hardcoded 0.
`timescale 1ns / 1ps

module tb_a7ng_c12_host_obs;
  logic clk, rst_n;
  logic [63:0] cue;
  logic [31:0] win, addr;
  logic [9:0]  nxt;
  logic        wren;
  logic [3:0]  hmode;
  logic        teacher, extllm;
  logic [15:0] ncue, nwin, naddr, ntok, nw, nmode;
  logic cmd_v, cmd_r;
  logic p_learn, p_freeze;

  a7ng_gate14_c9_glue dut (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(cmd_v), .cmd_ready_o(cmd_r),
    .cmd_i(4'd0), .tok_i(8'd0), .reward_i(4'sd0),
    .host_cue_i(cue), .host_winner_i(win), .host_addr_i(addr),
    .host_next_i(nxt), .host_wren_i(wren), .host_mode_i(hmode),
    .p_learn_o(p_learn), .p_freeze_o(p_freeze),
    .p_qvalid_o(), .p_qready_i(1'b1), .p_qid_o(),
    .p_snap_v_i(1'b0), .p_snap_r_o(),
    .p_topk_id_i('{default: '0}), .p_topk_sc_i('{default: '0}),
    .p_evs_i(32'd0), .p_evr_i(8'd0), .p_evo_i(32'd0),
    .p_pending_i(1'b0), .p_txn_i(16'd0),
    .p_rew_v_o(), .p_rew_o(), .p_echo_v_o(), .p_echo_o(),
    .p_ack_v_i(1'b0), .p_ack_i(3'd0), .p_c7_i(1'b0),
    .p_flush_o(), .p_reload_o(), .p_kill_o(), .p_trst_o(), .p_busy_i(1'b0),
    .lm_start_o(), .lm_busy_i(1'b0), .lm_done_i(1'b0), .lm_pred_i(10'd0),
    .c1_mode_o(), .c2_anch_o(), .c9_topk_o(), .c9_score_o(),
    .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(), .c10_lmdn_o(), .c10_out_o(),
    .n_host_cue_o(ncue), .n_host_win_o(nwin), .n_host_addr_o(naddr),
    .n_host_tok_o(ntok), .n_host_w_o(nw), .n_host_mode_o(nmode),
    .teacher_active_o(teacher), .ext_llm_active_o(extllm),
    .last_ack_o(), .exam_lm_used_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails;
  initial begin
    fails = 0;
    cue = 0; win = 0; addr = 0; nxt = 0; wren = 0; hmode = 0; cmd_v = 0;
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    repeat (4) @(posedge clk);
    if (teacher !== 1'b0 || extllm !== 1'b0) begin
      $display("FAIL idle teacher/ext not 0"); fails++;
    end
    if (ncue !== 0) begin $display("FAIL idle n_cue"); fails++; end

    @(negedge clk); cue = 64'h1;
    @(posedge clk);
    if (teacher !== 1'b1) begin $display("FAIL teacher_active live"); fails++; end
    @(posedge clk);
    if (ncue == 16'd0) begin $display("FAIL n_cue not live increment"); fails++; end
    @(negedge clk); cue = 0;
    @(posedge clk);
    if (teacher !== 1'b0) begin $display("FAIL teacher drop"); fails++; end

    @(negedge clk); nxt = 10'd3;
    @(posedge clk);
    if (extllm !== 1'b1) begin $display("FAIL ext_llm live"); fails++; end
    @(posedge clk);
    if (ntok == 16'd0) begin $display("FAIL n_next not live"); fails++; end
    @(negedge clk); nxt = 0; wren = 1;
    @(posedge clk);
    if (extllm !== 1'b1) begin $display("FAIL ext_llm wren"); fails++; end
    @(posedge clk);
    if (nw == 16'd0) begin $display("FAIL n_wren not live"); fails++; end
    @(negedge clk); wren = 0;

    if (fails == 0) $display("C12_HOST_OBS_XSIM_PASS fails=0");
    else $display("C12_HOST_OBS_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
