// a7ng_intent_shift.sv — NG-09 same entity, intent shifts ranking prior (law: a7ng-intent-v0)
`timescale 1ns / 1ps

module a7ng_intent_shift (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        fire_i,
  input  logic [7:0]  entity_i,   // 1=FPGA
  input  logic [7:0]  intent_i,   // 1=DEF 2=MECH 3=CMP 4=CAUSE 5=PART
  input  logic [7:0]  cand_tag_i, // candidate type tag matching intents
  output logic signed [15:0] prior_o,
  output logic        valid_o
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prior_o <= 16'sd0;
      valid_o <= 1'b0;
    end else begin
      valid_o <= 1'b0;
      if (fire_i) begin
        valid_o <= 1'b1;
        if (entity_i == 8'd1 && cand_tag_i == intent_i)
          prior_o <= 16'sd100; // matching intent boost
        else if (entity_i == 8'd1 && cand_tag_i != intent_i)
          prior_o <= -16'sd20; // same entity wrong intent demote
        else
          prior_o <= 16'sd0;
      end
    end
  end
endmodule
