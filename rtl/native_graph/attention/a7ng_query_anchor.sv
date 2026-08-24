// a7ng_query_anchor.sv — NG-07 native ENTITY/INTENT/CONTEXT (law: a7ng-anchor-v0)
// FPGA derives anchors from token cues. Blind exam: host must not supply these fields.
`timescale 1ns / 1ps

module a7ng_query_anchor (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        fire_i,
  // compact cue bag (FPGA-owned tokenizer stub): keyword hits
  input  logic        cue_fpga_i,
  input  logic        cue_cpu_i,
  input  logic        cue_what_i,     // DEFINE
  input  logic        cue_how_i,      // MECHANISM
  input  logic        cue_vs_i,       // COMPARE
  input  logic        cue_hw_i,       // HARDWARE context
  // TRAIN-only teacher override (must be 0 in BLIND_EXAM)
  input  logic        teacher_override_i,
  input  logic [7:0]  teacher_entity_i,
  input  logic [7:0]  teacher_intent_i,
  input  logic [7:0]  teacher_context_i,
  output logic [7:0]  entity_o,
  output logic [7:0]  intent_o,
  output logic [7:0]  context_o,
  output logic        valid_o
);
  // Enum codes (stable integers for golden)
  localparam logic [7:0] ENT_NONE = 8'd0;
  localparam logic [7:0] ENT_FPGA = 8'd1;
  localparam logic [7:0] ENT_CPU  = 8'd2;
  localparam logic [7:0] ENT_BOTH = 8'd3;
  localparam logic [7:0] INT_NONE = 8'd0;
  localparam logic [7:0] INT_DEF  = 8'd1;
  localparam logic [7:0] INT_MECH = 8'd2;
  localparam logic [7:0] INT_CMP  = 8'd3;
  localparam logic [7:0] CTX_NONE = 8'd0;
  localparam logic [7:0] CTX_HW   = 8'd1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      entity_o  <= ENT_NONE;
      intent_o  <= INT_NONE;
      context_o <= CTX_NONE;
      valid_o   <= 1'b0;
    end else begin
      valid_o <= 1'b0;
      if (fire_i) begin
        valid_o <= 1'b1;
        if (teacher_override_i) begin
          entity_o  <= teacher_entity_i;
          intent_o  <= teacher_intent_i;
          context_o <= teacher_context_i;
        end else begin
          // native derivation
          if (cue_fpga_i && cue_cpu_i) entity_o <= ENT_BOTH;
          else if (cue_fpga_i)         entity_o <= ENT_FPGA;
          else if (cue_cpu_i)          entity_o <= ENT_CPU;
          else                         entity_o <= ENT_NONE;

          if (cue_vs_i)       intent_o <= INT_CMP;
          else if (cue_how_i) intent_o <= INT_MECH;
          else if (cue_what_i)intent_o <= INT_DEF;
          else                intent_o <= INT_NONE;

          context_o <= cue_hw_i ? CTX_HW : CTX_NONE;
        end
      end
    end
  end
endmodule
