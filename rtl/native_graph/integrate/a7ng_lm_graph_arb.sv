// a7ng_lm_graph_arb.sv — exclusive LM vs graph owner for integrate_fit SoC
// Dual-owner write forbidden (owner_is_lm && owner_is_graph unreachable).
// Full LM-06 weight fabric is NOT instantiated here (HS-11); this is the grant path.
`timescale 1ns / 1ps

module a7ng_lm_graph_arb (
  input  logic clk,
  input  logic rst_n,
  input  logic req_graph_i,
  input  logic req_lm_i,
  output logic grant_graph_o,
  output logic grant_lm_o,
  output logic owner_is_graph_o,
  output logic owner_is_lm_o,
  output logic dual_owner_err_o
);
  typedef enum logic [1:0] {OWN_HOLD, OWN_GRAPH, OWN_LM} own_t;
  own_t own;

  assign owner_is_graph_o = (own == OWN_GRAPH);
  assign owner_is_lm_o    = (own == OWN_LM);
  assign dual_owner_err_o = owner_is_graph_o && owner_is_lm_o; // unreachable by construction
  assign grant_graph_o    = owner_is_graph_o;
  assign grant_lm_o       = owner_is_lm_o;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      own <= OWN_HOLD;
    end else begin
      unique case (own)
        OWN_HOLD: begin
          if (req_graph_i && !req_lm_i) own <= OWN_GRAPH;
          else if (req_lm_i && !req_graph_i) own <= OWN_LM;
          else if (req_graph_i && req_lm_i) own <= OWN_GRAPH; // graph wins tie
        end
        OWN_GRAPH: if (!req_graph_i) own <= OWN_HOLD;
        OWN_LM:    if (!req_lm_i)    own <= OWN_HOLD;
        default: own <= OWN_HOLD;
      endcase
    end
  end
endmodule
