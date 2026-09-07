// tb_u9r_r8.sv — U9R R8 negative tests: forbidden UART + host-cue injection.
// Constant-zero n_host_* is not leakage proof. PROGRAM=NO. Cycle watchdog.
`timescale 1ns / 1ps

module tb_u9r_r8;
  import a7ng_pkg::*;
  localparam int unsigned WATCH_CYC = 400000;

  logic clk, rst_n, byte_v, cmd_v, cmd_r;
  logic [7:0] byte_i, typ, tok, rj_ver, rj_len, rj_crc, rj_typ, rj_dup, rj_busy;
  logic [15:0] seq, echo;
  logic signed [3:0] rew;
  integer cyc, fails, i;

  logic [63:0] host_cue;
  logic [31:0] host_win, host_addr;
  logic [9:0] host_next;
  logic host_wren;
  logic [3:0] host_mode;
  logic [15:0] n_cue, n_win, n_addr, n_tokc, n_w, n_mode;
  node_id_t ids [8];
  score_t scs [8];

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_gate14_uart_cmd_rx u_rx (
    .clk(clk), .rst_n(rst_n),
    .byte_i(byte_i), .byte_v_i(byte_v),
    .cmd_valid_o(cmd_v), .cmd_ready_i(cmd_r),
    .cmd_type_o(typ), .cmd_seq_o(seq), .tok_o(tok), .rew_o(rew), .echo_o(echo),
    .rj_ver(rj_ver), .rj_len(rj_len), .rj_crc(rj_crc), .rj_typ(rj_typ),
    .rj_dup(rj_dup), .rj_busy(rj_busy)
  );
  assign cmd_r = 1'b1;

  a7ng_gate14_c9_glue u_glue (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(1'b0), .cmd_ready_o(), .cmd_i(4'd0), .tok_i(8'd0), .reward_i(4'sd0),
    .host_cue_i(host_cue), .host_winner_i(host_win), .host_addr_i(host_addr),
    .host_next_i(host_next), .host_wren_i(host_wren), .host_mode_i(host_mode),
    .p_learn_o(), .p_freeze_o(), .p_qvalid_o(), .p_qready_i(1'b1), .p_qid_o(),
    .p_snap_v_i(1'b0), .p_snap_r_o(), .p_topk_id_i(ids), .p_topk_sc_i(scs),
    .p_evs_i(32'd0), .p_evr_i(8'd0), .p_evo_i(32'd0),
    .p_pending_i(1'b0), .p_txn_i(16'd0),
    .p_rew_v_o(), .p_rew_o(), .p_echo_v_o(), .p_echo_o(),
    .p_ack_v_i(1'b0), .p_ack_i(3'd0), .p_c7_i(1'b0),
    .p_flush_o(), .p_reload_o(), .p_kill_o(), .p_trst_o(), .p_busy_i(1'b0),
    .lm_start_o(), .lm_busy_i(1'b0), .lm_done_i(1'b0), .lm_pred_i(10'd0),
    .c1_mode_o(), .c2_anch_o(), .c9_topk_o(), .c9_id20_o(), .c9_score_o(),
    .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(), .c10_lmdn_o(), .c10_out_o(),
    .n_host_cue_o(n_cue), .n_host_win_o(n_win), .n_host_addr_o(n_addr),
    .n_host_tok_o(n_tokc), .n_host_w_o(n_w), .n_host_mode_o(n_mode),
    .teacher_active_o(), .ext_llm_active_o(), .last_ack_o(), .exam_lm_used_o()
  );

  `include "a7ng_gate14_crc.svh"

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", c, d, cyc);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  task automatic send_raw(input logic [7:0] t, input logic [15:0] s, input logic [15:0] crc_force, input logic use_force);
    logic [15:0] crc;
    begin
      crc = 16'hFFFF;
      crc = crc16_byte(crc, 8'h01);
      crc = crc16_byte(crc, t);
      crc = crc16_byte(crc, s[7:0]);
      crc = crc16_byte(crc, s[15:8]);
      crc = crc16_byte(crc, 8'h00);
      crc = crc16_byte(crc, 8'h00);
      if (use_force) crc = crc_force;
      @(negedge clk); byte_v = 1; byte_i = 8'hA7; @(posedge clk);
      @(negedge clk); byte_i = 8'h14; @(posedge clk);
      @(negedge clk); byte_i = 8'h01; @(posedge clk);
      @(negedge clk); byte_i = t; @(posedge clk);
      @(negedge clk); byte_i = s[7:0]; @(posedge clk);
      @(negedge clk); byte_i = s[15:8]; @(posedge clk);
      @(negedge clk); byte_i = 8'h00; @(posedge clk);
      @(negedge clk); byte_i = 8'h00; @(posedge clk);
      @(negedge clk); byte_i = crc[7:0]; @(posedge clk);
      @(negedge clk); byte_i = crc[15:8]; @(posedge clk);
      @(negedge clk); byte_v = 0;
      repeat (4) @(posedge clk);
    end
  endtask

  initial begin
    fails = 0; rst_n = 0; byte_v = 0; byte_i = 0;
    host_cue = 0; host_win = 0; host_addr = 0; host_next = 0; host_wren = 0; host_mode = 0;
    for (i = 0; i < 8; i = i + 1) begin
      ids[i] = node_id_t'(32'd0);
      scs[i] = score_t'(16'sd0);
    end
    repeat (8) @(posedge clk); rst_n = 1;
    repeat (4) @(posedge clk);

    send_raw(8'h04, 16'd1, 16'hDEAD, 1'b1);
    $display("R8_BAD_CRC rj_crc=%0d rj_typ=%0d cmd_v=%0d", rj_crc, rj_typ, cmd_v);
    if (rj_crc === 8'd0) diverge("NEG_CRC", "corrupt CRC must increment rj_crc");

    send_raw(8'hFE, 16'd2, 16'h0000, 1'b0);
    $display("R8_BAD_TYP rj_typ=%0d rj_crc=%0d cmd_v=%0d", rj_typ, rj_crc, cmd_v);
    if (rj_typ === 8'd0) diverge("NEG_TYP", "illegal type 0xFE must increment rj_typ");

    if (n_cue !== 16'd0) diverge("HOST_BASELINE", "n_host_cue not zero before inject");
    host_cue = 64'h1;
    repeat (4) @(posedge clk);
    $display("R8_HOST_INJECT n_cue=%0d n_win=%0d n_w=%0d", n_cue, n_win, n_w);
    if (n_cue === 16'd0)
      diverge("NEG_HOST_COUNTER", "host_cue injection must increment n_host_cue");
    host_cue = 64'd0;
    $display("R8_HARNESS_CATCHES forbidden UART + host ingress");
    $display("U9R_R8_NEGATIVE_PASS");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > WATCH_CYC) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
