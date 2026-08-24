// a7ng_epoch_mgr.sv — owns query/path epoch + training_generation (RESET plan §§3–7)
// Law: a7ng-reset-epoch-v0. Logical authority only; no BRAM wipe.
`timescale 1ns / 1ps

module a7ng_epoch_mgr (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        bump_query_i,
  input  logic        bump_path_i,
  input  logic        bump_train_i,
  output logic [15:0] query_epoch_o,
  output logic [15:0] path_epoch_o,
  output logic [31:0] training_generation_o,
  // Wrap policy hooks (RESET plan §4): imminent → maintenance required
  output logic        query_wrap_imminent_o,
  output logic        train_wrap_imminent_o
);
  localparam logic [15:0] QUERY_WRAP_MARGIN = 16'd16;
  localparam logic [31:0] TRAIN_WRAP_MARGIN = 32'd256;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      query_epoch_o         <= 16'd1;
      path_epoch_o          <= 16'd1;
      training_generation_o <= 32'd1;
    end else begin
      if (bump_query_i)
        query_epoch_o <= query_epoch_o + 16'd1;
      if (bump_path_i)
        path_epoch_o <= path_epoch_o + 16'd1;
      if (bump_train_i)
        training_generation_o <= training_generation_o + 32'd1;
    end
  end

  assign query_wrap_imminent_o =
      (query_epoch_o >= (16'hFFFF - QUERY_WRAP_MARGIN));
  assign train_wrap_imminent_o =
      (training_generation_o >= (32'hFFFF_FFFF - TRAIN_WRAP_MARGIN));
endmodule
