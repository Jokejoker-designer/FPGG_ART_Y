// a7ng_scorer_array.sv — 16 physical lanes (NG-01 first target)
`timescale 1ns / 1ps

module a7ng_scorer_array (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic [a7ng_pkg::NG_LANES-1:0] valid_i,
  input  a7ng_pkg::node_id_t         cand_id_i [a7ng_pkg::NG_LANES],
  input  a7ng_pkg::score_terms_t     terms_i   [a7ng_pkg::NG_LANES],
  output logic [a7ng_pkg::NG_LANES-1:0] valid_o,
  output a7ng_pkg::node_id_t         cand_id_o [a7ng_pkg::NG_LANES],
  output a7ng_pkg::score_t           score_o   [a7ng_pkg::NG_LANES]
);
  import a7ng_pkg::*;

  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_lane
      a7ng_scorer_lane u_lane (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_i  (valid_i[gi]),
        .cand_id_i(cand_id_i[gi]),
        .terms_i  (terms_i[gi]),
        .valid_o  (valid_o[gi]),
        .cand_id_o(cand_id_o[gi]),
        .score_o  (score_o[gi])
      );
    end
  endgenerate
endmodule
