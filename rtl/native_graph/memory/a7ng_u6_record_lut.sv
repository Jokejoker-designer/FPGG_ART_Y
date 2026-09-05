// a7ng_u6_record_lut.sv — U6-UNIFIED-RETRIEVAL-00
// Preloaded FPGA record table. Exact 20-bit ID compare. No 16-bit alias.
// PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_u6_record_lut #(
  parameter int unsigned N = 128
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        go_i,
  input  logic [19:0] id_i,
  output logic        hit_o,
  output logic [7:0]  ent_o,
  output logic [7:0]  int_o,
  output logic [7:0]  rel_o,
  output logic [7:0]  ctx_o,
  output logic        use_st_o,
  output a7ng_pkg::term_t te_o,
  output a7ng_pkg::term_t ti_o,
  output a7ng_pkg::term_t tr_o,
  output a7ng_pkg::term_t tc_o,
  output a7ng_pkg::term_t tp_o,
  output a7ng_pkg::term_t tpr_o,
  output a7ng_pkg::term_t tpe_o
);
  import a7ng_pkg::*;
  `include "u6_lut.svh"

  integer i;
  logic        hit_c, ust_c;
  logic [7:0]  e_c, n_c, r_c, x_c;
  term_t te_c, ti_c, tr_c, tc_c, tp_c, tpr_c, tpe_c;

  always_comb begin
    hit_c = 1'b0;
    e_c = 8'd0; n_c = 8'd0; r_c = 8'd0; x_c = 8'd0;
    ust_c = 1'b0;
    te_c = '0; ti_c = '0; tr_c = '0; tc_c = '0;
    tp_c = '0; tpr_c = '0; tpe_c = '0;
    for (i = 0; i < N; i = i + 1) begin
      if ((i < G_LUT_N) && G_LUT_OCC[i] && (G_LUT_ID[i] == id_i)) begin
        hit_c = 1'b1;
        e_c = G_LUT_ENT[i]; n_c = G_LUT_INT[i];
        r_c = G_LUT_REL[i]; x_c = G_LUT_CTX[i];
        ust_c = G_LUT_UST[i];
        te_c = G_LUT_TE[i]; ti_c = G_LUT_TI[i];
        tr_c = G_LUT_TR[i]; tc_c = G_LUT_TC[i];
        tp_c = G_LUT_TP[i]; tpr_c = G_LUT_TPR[i];
        tpe_c = G_LUT_TPE[i];
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hit_o <= 1'b0;
      ent_o <= 8'd0; int_o <= 8'd0; rel_o <= 8'd0; ctx_o <= 8'd0;
      use_st_o <= 1'b0;
      te_o <= '0; ti_o <= '0; tr_o <= '0; tc_o <= '0;
      tp_o <= '0; tpr_o <= '0; tpe_o <= '0;
    end else if (go_i) begin
      hit_o <= hit_c;
      ent_o <= e_c; int_o <= n_c; rel_o <= r_c; ctx_o <= x_c;
      use_st_o <= ust_c;
      te_o <= te_c; ti_o <= ti_c; tr_o <= tr_c; tc_o <= tc_c;
      tp_o <= tp_c; tpr_o <= tpr_c; tpe_o <= tpe_c;
    end
  end
endmodule
