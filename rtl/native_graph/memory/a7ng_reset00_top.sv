// a7ng_reset00_top.sv — A7-NATIVE-RESET-00 logical path glue (QUERY + TRAIN)
// Wires epoch_mgr + WM authority + learned gen view + reset_ctrl + verify.
// No HARD scrub. No LM-06 touch.
`timescale 1ns / 1ps

module a7ng_reset00_top #(
  parameter int unsigned WM_DEPTH     = 32,
  parameter int unsigned LEARNED_DEPTH = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  // Host/teacher: reset command
  input  logic        reset_req_i,
  input  logic [1:0]  reset_level_i,
  input  logic        lm_frozen_intact_i,
  // WM write
  input  logic        wm_write_i,
  input  logic [31:0] wm_node_i,
  input  logic [31:0] wm_payload_i,
  // Learned commit
  input  logic        learn_commit_i,
  input  logic [31:0] learn_node_i,
  input  logic [15:0] learn_score_i,
  // Status
  output logic        reset_busy_o,
  output logic        reset_done_o,
  output logic        reset_error_o,
  output logic [15:0] query_epoch_o,
  output logic [15:0] path_epoch_o,
  output logic [31:0] training_generation_o,
  output logic [15:0] wm_auth_valid_count_o,
  output logic [15:0] wm_physical_valid_count_o,
  output logic [15:0] wm_workset_count_o,
  output logic [15:0] learned_visible_count_o,
  output logic [15:0] learned_physical_count_o,
  output logic [15:0] learned_old_gen_physical_count_o,
  output logic        verify_pass_o,
  output logic        verify_fail_o,
  output logic [31:0] verify_fail_code_o,
  output logic [31:0] reset_cycles_last_o,
  output logic [31:0] reset_count_query_o,
  output logic [31:0] reset_count_train_o
);
  logic bump_q, bump_p, bump_t, ptr_inv, vfy_start;
  logic [1:0] last_lvl;
  logic q_wrap, t_wrap;
  logic [31:0] rst_sess_cnt;
  logic wm_peek_auth;
  logic [31:0] wm_peek_node, wm_peek_pay;
  logic [15:0] wm_old_gen_phys;
  logic learn_peek_vis;
  logic [31:0] learn_peek_node, learn_peek_gen;
  logic [15:0] learn_peek_score;

  a7ng_epoch_mgr u_epoch (
    .clk(clk), .rst_n(rst_n),
    .bump_query_i(bump_q), .bump_path_i(bump_p), .bump_train_i(bump_t),
    .query_epoch_o(query_epoch_o), .path_epoch_o(path_epoch_o),
    .training_generation_o(training_generation_o),
    .query_wrap_imminent_o(q_wrap), .train_wrap_imminent_o(t_wrap)
  );

  a7ng_wm_authority #(.DEPTH(WM_DEPTH), .DATA_W(32)) u_wm (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(query_epoch_o),
    .active_training_generation_i(training_generation_o),
    .write_i(wm_write_i), .node_id_i(wm_node_i), .payload_i(wm_payload_i),
    .ptr_invalidate_i(ptr_inv),
    .peek_idx_i({$clog2(WM_DEPTH){1'b0}}),
    .peek_auth_valid_o(wm_peek_auth),
    .peek_node_o(wm_peek_node),
    .peek_payload_o(wm_peek_pay),
    .auth_valid_count_o(wm_auth_valid_count_o),
    .physical_valid_count_o(wm_physical_valid_count_o),
    .workset_count_o(wm_workset_count_o),
    .old_generation_visible_count_o(wm_old_gen_phys)
  );

  a7ng_learned_gen_view #(.DEPTH(LEARNED_DEPTH)) u_learn (
    .clk(clk), .rst_n(rst_n),
    .active_training_generation_i(training_generation_o),
    .commit_i(learn_commit_i), .node_id_i(learn_node_i), .score_i(learn_score_i),
    .visible_count_o(learned_visible_count_o),
    .physical_present_count_o(learned_physical_count_o),
    .old_generation_visible_count_o(learned_old_gen_physical_count_o),
    .peek_idx_i({$clog2(LEARNED_DEPTH){1'b0}}),
    .peek_visible_o(learn_peek_vis),
    .peek_node_o(learn_peek_node),
    .peek_score_o(learn_peek_score),
    .peek_gen_o(learn_peek_gen)
  );

  a7ng_reset_verify u_vfy (
    .clk(clk), .rst_n(rst_n),
    .start_i(vfy_start),
    .reset_level_i(last_lvl),
    .auth_valid_count_i(wm_auth_valid_count_o),
    .workset_count_i(wm_workset_count_o),
    .learned_visible_count_i(learned_visible_count_o),
    .lm_frozen_intact_i(lm_frozen_intact_i),
    .pass_o(verify_pass_o), .fail_o(verify_fail_o), .fail_code_o(verify_fail_code_o)
  );

  a7ng_reset_ctrl u_ctrl (
    .clk(clk), .rst_n(rst_n),
    .reset_req_i(reset_req_i), .reset_level_i(reset_level_i),
    .verify_pass_i(verify_pass_o), .verify_fail_i(verify_fail_o),
    .reset_busy_o(reset_busy_o), .reset_done_o(reset_done_o),
    .reset_error_o(reset_error_o),
    .bump_query_o(bump_q), .bump_path_o(bump_p), .bump_train_o(bump_t),
    .ptr_invalidate_o(ptr_inv), .verify_start_o(vfy_start),
    .last_level_o(last_lvl),
    .reset_count_query_o(reset_count_query_o),
    .reset_count_session_o(rst_sess_cnt),
    .reset_count_train_o(reset_count_train_o),
    .reset_cycles_last_o(reset_cycles_last_o)
  );
endmodule
