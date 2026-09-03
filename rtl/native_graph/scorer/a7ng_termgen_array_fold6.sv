// a7ng_termgen_array_fold6.sv — R4: PHYS physical folded TermGen lanes (default 8)
`timescale 1ns / 1ps

module a7ng_termgen_array_fold6 #(
  parameter int unsigned PHYS = 8
) (
  input  logic                clk,
  input  logic                rst_n,
  input  logic [PHYS-1:0]     valid_i,
  output logic                ready_o,
  input  a7ng_pkg::node_id_t  cand_id_i [PHYS],
  input  a7ng_pkg::termgen_cues_t cues_i [PHYS],
  output logic [PHYS-1:0]     valid_o,
  input  logic                ready_i,
  output a7ng_pkg::node_id_t  cand_id_o [PHYS],
  output a7ng_pkg::score_terms_t terms_o [PHYS]
);
  import a7ng_pkg::*;
  logic [PHYS-1:0] lane_ready;
  assign ready_o = &lane_ready;

  genvar gi;
  generate
    for (gi = 0; gi < int'(PHYS); gi++) begin : g_tg
      a7ng_termgen_lane_fold6 u_tg (
        .clk(clk), .rst_n(rst_n),
        .valid_i(valid_i[gi]), .ready_o(lane_ready[gi]),
        .cand_id_i(cand_id_i[gi]), .cues_i(cues_i[gi]),
        .valid_o(valid_o[gi]), .ready_i(ready_i),
        .cand_id_o(cand_id_o[gi]), .terms_o(terms_o[gi])
      );
    end
  endgenerate
endmodule
