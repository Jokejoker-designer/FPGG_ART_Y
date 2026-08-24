// a7ng_reset_verify.sv — post-reset authority invariants (RESET plan §19)
// QUERY: auth_valid==0 + workset==0; TRAIN: learned_visible==0 (old gen not accepted).
// Physical remnants OK. LM frozen intact required always.
// Law: a7ng-reset-verify-v0.
`timescale 1ns / 1ps

module a7ng_reset_verify (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [1:0]  reset_level_i,
  input  logic [15:0] auth_valid_count_i,
  input  logic [15:0] workset_count_i,
  input  logic [15:0] learned_visible_count_i,
  // Control: LM-06 / frozen backbone must remain intact (TB/file SHA drive)
  input  logic        lm_frozen_intact_i,
  output logic        pass_o,
  output logic        fail_o,
  output logic [31:0] fail_code_o
);
  localparam logic [1:0] LVL_TRAIN = 2'd2;

  localparam logic [31:0] FAIL_AUTH   = 32'h0000_0001;
  localparam logic [31:0] FAIL_WORK   = 32'h0000_0002;
  localparam logic [31:0] FAIL_LEARN  = 32'h0000_0008;
  localparam logic [31:0] FAIL_LM     = 32'h0000_0010;

  logic [31:0] code;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pass_o      <= 1'b0;
      fail_o      <= 1'b0;
      fail_code_o <= 32'd0;
    end else begin
      pass_o <= 1'b0;
      fail_o <= 1'b0;
      if (start_i) begin
        code = 32'd0;
        if (auth_valid_count_i != 16'd0)
          code = code | FAIL_AUTH;
        if (workset_count_i != 16'd0)
          code = code | FAIL_WORK;
        // TRAIN: no learned record may remain authoritative under new generation
        if ((reset_level_i == LVL_TRAIN) &&
            (learned_visible_count_i != 16'd0))
          code = code | FAIL_LEARN;
        if (!lm_frozen_intact_i)
          code = code | FAIL_LM;
        if (code == 32'd0) begin
          pass_o      <= 1'b1;
          fail_code_o <= 32'd0;
        end else begin
          fail_o      <= 1'b1;
          fail_code_o <= code;
        end
      end
    end
  end
endmodule
