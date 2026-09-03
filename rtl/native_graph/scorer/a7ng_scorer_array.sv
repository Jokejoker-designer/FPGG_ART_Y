// a7ng_scorer_array.sv — R4: PHYS physical PE lanes (default 8)
`timescale 1ns / 1ps

module a7ng_scorer_array #(
  parameter int unsigned PHYS = 8
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic [PHYS-1:0]            valid_i,
  input  a7ng_pkg::node_id_t         cand_id_i [PHYS],
  input  a7ng_pkg::score_terms_t     terms_i   [PHYS],
  output logic [PHYS-1:0]            valid_o,
  output a7ng_pkg::node_id_t         cand_id_o [PHYS],
  output a7ng_pkg::score_t           score_o   [PHYS]
);
  import a7ng_pkg::*;

  genvar gi;
  generate
    for (gi = 0; gi < int'(PHYS); gi++) begin : g_lane
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
