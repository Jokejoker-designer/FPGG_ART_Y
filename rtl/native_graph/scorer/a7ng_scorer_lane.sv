// a7ng_scorer_lane.sv — 2-stage PE lane (NG-01)
// II = 1 after fill; latency = 2 cycles. Fixed-point saturating compose.
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module a7ng_scorer_lane (
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    valid_i,
  input  a7ng_pkg::node_id_t      cand_id_i,
  input  a7ng_pkg::score_terms_t  terms_i,
  output logic                    valid_o,
  output a7ng_pkg::node_id_t      cand_id_o,
  output a7ng_pkg::score_t        score_o
);
  import a7ng_pkg::*;

  logic               valid_d1;
  node_id_t           id_d1;
  score_t             partial_d1;
  score_terms_t       terms_d1;

  // Stage 1: entity+intent+relation+context
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_d1   <= 1'b0;
      id_d1      <= '0;
      terms_d1   <= '0;
      partial_d1 <= '0;
    end else begin
      valid_d1 <= valid_i;
      id_d1    <= cand_id_i;
      terms_d1 <= terms_i;
      if (valid_i) begin
        partial_d1 <= sat_add16(
            sat_add16(sext_term(terms_i.entity_match), sext_term(terms_i.intent_match)),
            sat_add16(sext_term(terms_i.relation_match), sext_term(terms_i.context_match))
        );
      end
    end
  end

  // Stage 2: +path +prior -penalty
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_o   <= 1'b0;
      cand_id_o <= '0;
      score_o   <= '0;
    end else begin
      valid_o   <= valid_d1;
      cand_id_o <= id_d1;
      if (valid_d1) begin
        score_o <= sat_add16(
            sat_add16(partial_d1, sext_term(terms_d1.path_confidence)),
            sat_add16(sext_term(terms_d1.learned_prior), -sext_term(terms_d1.contradiction_penalty))
        );
      end
    end
  end
endmodule
