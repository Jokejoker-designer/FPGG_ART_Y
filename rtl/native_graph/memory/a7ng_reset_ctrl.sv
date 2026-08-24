// a7ng_reset_ctrl.sv — logical reset FSM (QUERY / SESSION / TRAIN)
// HARD scrub deferred (not this gate). Never claims LM-06 wipe.
// Law: a7ng-reset-ctrl-v0. RESET plan §§5–7, §11 (invalidate path only).
`timescale 1ns / 1ps

module a7ng_reset_ctrl (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       reset_req_i,
  // 0=QUERY 1=SESSION 2=TRAIN 3=HARD(unsupported → error this gate)
  input  logic [1:0] reset_level_i,
  input  logic       verify_pass_i,
  input  logic       verify_fail_i,
  output logic       reset_busy_o,
  output logic       reset_done_o,
  output logic       reset_error_o,
  output logic       bump_query_o,
  output logic       bump_path_o,
  output logic       bump_train_o,
  output logic       ptr_invalidate_o,
  output logic       verify_start_o,
  output logic [1:0] last_level_o,
  // PERFMON-style (off critical path)
  output logic [31:0] reset_count_query_o,
  output logic [31:0] reset_count_session_o,
  output logic [31:0] reset_count_train_o,
  output logic [31:0] reset_cycles_last_o
);
  localparam logic [1:0] LVL_QUERY   = 2'd0;
  localparam logic [1:0] LVL_SESSION = 2'd1;
  localparam logic [1:0] LVL_TRAIN   = 2'd2;
  localparam logic [1:0] LVL_HARD    = 2'd3;

  typedef enum logic [3:0] {
    RST_IDLE,
    RST_BLOCK_INPUT,
    RST_INVALIDATE,
    RST_VERIFY,
    RST_DONE,
    RST_ERROR
  } rst_state_t;

  rst_state_t state;
  logic [1:0] level_r;
  logic [31:0] cyc_acc;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state                 <= RST_IDLE;
      level_r               <= LVL_QUERY;
      reset_busy_o          <= 1'b0;
      reset_done_o          <= 1'b0;
      reset_error_o         <= 1'b0;
      bump_query_o          <= 1'b0;
      bump_path_o           <= 1'b0;
      bump_train_o          <= 1'b0;
      ptr_invalidate_o      <= 1'b0;
      verify_start_o        <= 1'b0;
      last_level_o          <= LVL_QUERY;
      reset_count_query_o   <= 32'd0;
      reset_count_session_o <= 32'd0;
      reset_count_train_o   <= 32'd0;
      reset_cycles_last_o   <= 32'd0;
      cyc_acc               <= 32'd0;
    end else begin
      bump_query_o     <= 1'b0;
      bump_path_o      <= 1'b0;
      bump_train_o     <= 1'b0;
      ptr_invalidate_o <= 1'b0;
      verify_start_o   <= 1'b0;
      reset_done_o     <= 1'b0;

      unique case (state)
        RST_IDLE: begin
          reset_busy_o <= 1'b0;
          // error sticky until a legal (non-HARD) reset completes
          if (reset_req_i) begin
            level_r      <= reset_level_i;
            last_level_o <= reset_level_i;
            cyc_acc      <= 32'd0;
            reset_busy_o <= 1'b1;
            if (reset_level_i == LVL_HARD)
              state <= RST_ERROR;
            else begin
              reset_error_o <= 1'b0;
              state <= RST_BLOCK_INPUT;
            end
          end
        end

        RST_BLOCK_INPUT: begin
          cyc_acc <= cyc_acc + 32'd1;
          state   <= RST_INVALIDATE;
        end

        RST_INVALIDATE: begin
          cyc_acc          <= cyc_acc + 32'd1;
          ptr_invalidate_o <= 1'b1;
          bump_query_o     <= 1'b1;
          bump_path_o      <= 1'b1;
          if (level_r == LVL_TRAIN) begin
            bump_train_o <= 1'b1;
            reset_count_train_o <= reset_count_train_o + 32'd1;
          end else if (level_r == LVL_SESSION) begin
            reset_count_session_o <= reset_count_session_o + 32'd1;
          end else begin
            reset_count_query_o <= reset_count_query_o + 32'd1;
          end
          state <= RST_VERIFY;
        end

        RST_VERIFY: begin
          cyc_acc        <= cyc_acc + 32'd1;
          verify_start_o <= 1'b1;
          if (verify_fail_i) begin
            state <= RST_ERROR;
          end else if (verify_pass_i) begin
            reset_cycles_last_o <= cyc_acc + 32'd1;
            state <= RST_DONE;
          end
        end

        RST_DONE: begin
          reset_busy_o <= 1'b0;
          reset_done_o <= 1'b1;
          state        <= RST_IDLE;
        end

        RST_ERROR: begin
          reset_busy_o  <= 1'b0;
          reset_error_o <= 1'b1;
          // Stay until new req clears via idle pulse: auto return next cycle
          state <= RST_IDLE;
        end

        default: state <= RST_IDLE;
      endcase
    end
  end
endmodule
