// a7ng_local_learn.sv — NG-05 FPGA-owned signed prior update (law: a7ng-learn-v0)
// Host may send reward only; never injects updated weights. Reset clears learned state.
`timescale 1ns / 1ps

module a7ng_local_learn #(
  parameter int unsigned DEPTH = 64,
  parameter int unsigned AW    = 6
) (
  input  logic               clk,
  input  logic               rst_n,
  input  logic               learn_en_i,   // 0 in BLIND_EXAM / FREEZE
  input  logic               freeze_i,     // 1 blocks updates
  input  logic               forget_i,     // wipe all priors
  input  logic               upd_i,
  input  logic [AW-1:0]      idx_i,
  input  logic signed [3:0]  reward_i,     // −3..+3
  input  logic               rd_i,
  input  logic [AW-1:0]      rd_idx_i,
  output logic signed [7:0]  prior_o,
  output logic               updated_o,
  output logic [15:0]        update_count_o
);
  logic signed [7:0] prior [DEPTH];
  integer i;

  function automatic logic signed [7:0] sat8(input logic signed [8:0] x);
    if (x > 9'sd127)  return 8'sd127;
    if (x < -9'sd128) return -8'sd128;
    return x[7:0];
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < DEPTH; i = i + 1) prior[i] <= 8'sd0;
      prior_o <= 8'sd0;
      updated_o <= 1'b0;
      update_count_o <= 16'd0;
    end else begin
      updated_o <= 1'b0;

      if (forget_i) begin
        for (i = 0; i < DEPTH; i = i + 1) prior[i] <= 8'sd0;
        update_count_o <= 16'd0;
      end else if (upd_i && learn_en_i && !freeze_i) begin
        // FPGA computes W ← sat(W + reward); host cannot write prior_*
        prior[idx_i] <= sat8($signed({prior[idx_i][7], prior[idx_i]}) + $signed({{5{reward_i[3]}}, reward_i}));
        updated_o <= 1'b1;
        update_count_o <= update_count_o + 16'd1;
      end

      if (rd_i)
        prior_o <= prior[rd_idx_i];
    end
  end
endmodule
