// a7ng_termgen_lane.sv — TermGen PE (law: a7ng-termgen-v0)
// Emits all four feature families + prior/contradiction from 64-bit HDC cues.
// II = 1 after fill; latency = 2 cycles; DSP = 0 (XOR / rotate / popcount).
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module a7ng_termgen_lane (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     valid_i,
  input  a7ng_pkg::node_id_t       cand_id_i,
  input  a7ng_pkg::termgen_cues_t  cues_i,
  output logic                     valid_o,
  output a7ng_pkg::node_id_t       cand_id_o,
  output a7ng_pkg::score_terms_t   terms_o
);
  import a7ng_pkg::*;

  // Stage 1: BIND / PERMUTE / XOR diffs (HDC primitives)
  logic               valid_d1;
  node_id_t           id_d1;
  cue_t               xor_entity_d1;
  cue_t               xor_intent_d1;
  cue_t               xor_relation_d1;
  cue_t               xor_context_d1;
  cue_t               xor_path_d1;
  cue_t               xor_contra_d1;
  term_t              prior_d1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_d1         <= 1'b0;
      id_d1            <= '0;
      xor_entity_d1    <= '0;
      xor_intent_d1    <= '0;
      xor_relation_d1  <= '0;
      xor_context_d1   <= '0;
      xor_path_d1      <= '0;
      xor_contra_d1    <= '0;
      prior_d1         <= '0;
    end else begin
      valid_d1 <= valid_i;
      id_d1    <= cand_id_i;
      prior_d1 <= cues_i.learned_prior;
      if (valid_i) begin
        xor_entity_d1   <= cues_i.query_cue ^ cues_i.node_cue;
        xor_intent_d1   <= cues_i.intent_cue ^ ng_rotl16(cues_i.node_cue);
        // BIND: query ⊕ ROTL1(relation) vs node (relation participates; dual-side BIND cancels)
        xor_relation_d1 <= (cues_i.query_cue ^ ng_rotl1(cues_i.relation_cue)) ^ cues_i.node_cue;
        xor_context_d1  <= cues_i.context_cue ^ ng_rotl32(cues_i.node_cue);
        xor_path_d1     <= cues_i.path_cue ^ ng_rotl8(cues_i.query_cue ^ cues_i.node_cue);
        xor_contra_d1   <= (cues_i.query_cue ^ cues_i.node_cue) & cues_i.path_cue;
      end
    end
  end

  // Stage 2: SIMILARITY = 64 - popcount; contradiction = pop >> 1
  logic [6:0] pop_entity;
  logic [6:0] pop_intent;
  logic [6:0] pop_relation;
  logic [6:0] pop_context;
  logic [6:0] pop_path;
  logic [6:0] pop_contra;

  always_comb begin
    pop_entity   = ng_pop64(xor_entity_d1);
    pop_intent   = ng_pop64(xor_intent_d1);
    pop_relation = ng_pop64(xor_relation_d1);
    pop_context  = ng_pop64(xor_context_d1);
    pop_path     = ng_pop64(xor_path_d1);
    pop_contra   = ng_pop64(xor_contra_d1);
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_o   <= 1'b0;
      cand_id_o <= '0;
      terms_o   <= '0;
    end else begin
      valid_o   <= valid_d1;
      cand_id_o <= id_d1;
      if (valid_d1) begin
        terms_o.entity_match          <= term_t'(8'd64 - {1'b0, pop_entity});
        terms_o.intent_match          <= term_t'(8'd64 - {1'b0, pop_intent});
        terms_o.relation_match        <= term_t'(8'd64 - {1'b0, pop_relation});
        terms_o.context_match         <= term_t'(8'd64 - {1'b0, pop_context});
        terms_o.path_confidence       <= term_t'(8'd64 - {1'b0, pop_path});
        terms_o.learned_prior         <= prior_d1;
        terms_o.contradiction_penalty <= term_t'({1'b0, pop_contra[6:1]});
      end
    end
  end
endmodule
