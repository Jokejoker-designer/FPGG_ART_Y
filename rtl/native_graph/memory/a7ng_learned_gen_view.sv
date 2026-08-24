// a7ng_learned_gen_view.sv — DDR/learned surrogate tagged by training_generation
// TRAIN bump makes old records non-authoritative without physical scrub (RESET §7/§17).
// Law: a7ng-reset-learned-v0. Never touches LM-06 backbone.
`timescale 1ns / 1ps

module a7ng_learned_gen_view #(
  parameter int unsigned DEPTH = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [31:0] active_training_generation_i,
  // Commit a learned binding (FPGA-owned address index)
  input  logic        commit_i,
  input  logic [31:0] node_id_i,
  input  logic [15:0] score_i,
  // Metrics
  output logic [15:0] visible_count_o,
  output logic [15:0] physical_present_count_o,
  output logic [15:0] old_generation_visible_count_o,
  // Peek for TB
  input  logic [$clog2(DEPTH)-1:0] peek_idx_i,
  output logic        peek_visible_o,
  output logic [31:0] peek_node_o,
  output logic [15:0] peek_score_o,
  output logic [31:0] peek_gen_o
);
  logic        present [DEPTH];
  logic [31:0] gen     [DEPTH];
  logic [31:0] node    [DEPTH];
  logic [15:0] score   [DEPTH];
  logic [$clog2(DEPTH)-1:0] wr_ptr;

  logic [15:0] vis_c;
  logic [15:0] phys_c;
  logic [15:0] old_c;

  always_comb begin
    vis_c  = 16'd0;
    phys_c = 16'd0;
    old_c  = 16'd0;
    for (int ci = 0; ci < DEPTH; ci++) begin
      if (present[ci]) begin
        phys_c = phys_c + 16'd1;
        if (gen[ci] == active_training_generation_i)
          vis_c = vis_c + 16'd1;
        else
          old_c = old_c + 16'd1;
      end
    end
  end

  assign visible_count_o                 = vis_c;
  assign physical_present_count_o        = phys_c;
  assign old_generation_visible_count_o  = old_c;

  assign peek_visible_o = present[peek_idx_i] &&
                          (gen[peek_idx_i] == active_training_generation_i);
  assign peek_node_o  = node[peek_idx_i];
  assign peek_score_o = score[peek_idx_i];
  assign peek_gen_o   = gen[peek_idx_i];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      for (int ri = 0; ri < DEPTH; ri++) begin
        present[ri] <= 1'b0;
        gen[ri]     <= 32'd0;
        node[ri]    <= 32'd0;
        score[ri]   <= 16'd0;
      end
    end else if (commit_i) begin
      // Logical learn: stamp with active generation. No wipe of other slots.
      present[wr_ptr] <= 1'b1;
      gen[wr_ptr]     <= active_training_generation_i;
      node[wr_ptr]    <= node_id_i;
      score[wr_ptr]   <= score_i;
      wr_ptr          <= wr_ptr + 1'b1;
    end
  end
endmodule
