// a7ng_termgen_ooc_top.sv — OOC shell for TermGen array @ 100 MHz (DSP check)
`timescale 1ns / 1ps

module a7ng_termgen_ooc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] valid_i,
  input  logic [31:0] cand_id_flat_i,
  input  logic [63:0] query_cue_i,
  input  logic [63:0] node_cue_i,
  input  logic [63:0] relation_cue_i,
  input  logic [63:0] intent_cue_i,
  input  logic [63:0] context_cue_i,
  input  logic [63:0] path_cue_i,
  input  logic signed [7:0] prior_i,
  output logic [15:0] valid_o,
  output logic [31:0] cand_id_flat_o,
  output logic signed [7:0] entity_o,
  output logic signed [7:0] relation_o,
  output logic signed [7:0] path_o
);
  import a7ng_pkg::*;

  node_id_t      cand_id_i [NG_LANES];
  termgen_cues_t cues_i    [NG_LANES];
  node_id_t      cand_id_o [NG_LANES];
  score_terms_t  terms_o   [NG_LANES];

  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_drive
      always_comb begin
        cand_id_i[gi] = cand_id_flat_i + node_id_t'(gi);
        cues_i[gi].query_cue     = query_cue_i ^ cue_t'(gi);
        cues_i[gi].node_cue      = node_cue_i ^ cue_t'(gi << 1);
        cues_i[gi].relation_cue  = relation_cue_i;
        cues_i[gi].intent_cue    = intent_cue_i;
        cues_i[gi].context_cue   = context_cue_i;
        cues_i[gi].path_cue      = path_cue_i;
        cues_i[gi].learned_prior = prior_i;
      end
    end
  endgenerate

  a7ng_termgen_array u_tg (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .cand_id_i(cand_id_i),
    .cues_i(cues_i),
    .valid_o(valid_o),
    .cand_id_o(cand_id_o),
    .terms_o(terms_o)
  );

  assign cand_id_flat_o = cand_id_o[0];
  assign entity_o       = terms_o[0].entity_match;
  assign relation_o     = terms_o[0].relation_match;
  assign path_o         = terms_o[0].path_confidence;
endmodule
