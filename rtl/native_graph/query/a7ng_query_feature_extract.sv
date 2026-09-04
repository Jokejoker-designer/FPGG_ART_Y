// a7ng_query_feature_extract.sv — U3Q-QUERY-REPRESENTATION-AUTHORITY-00
// Law: qfe-v1-crc16-mix-00
// FPGA-owned keys from raw 8-bit tokens. No host hash/shard/bucket/winner/address.
// PROGRAM=NO.
`timescale 1ns / 1ps
`include "a7ng_gate14_crc.svh"

module a7ng_query_feature_extract #(
  parameter int unsigned MAX_TOK = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  output logic        busy_o,
  output logic        valid_o,
  output logic [7:0]  tok_count_o,
  output logic [7:0]  tok_xor_o,
  output logic [15:0] tok_sum_o,
  output logic [15:0] crc_o,
  output logic [7:0]  first_tok_o,
  output logic [7:0]  last_tok_o,
  output logic [15:0] k0_o,
  output logic [15:0] k1_o,
  output logic [15:0] k2_o,
  output logic [15:0] k3_o
);
  logic        have;
  logic [7:0]  ntok, txor, first_t, last_t;
  logic [15:0] tsum, crc;

  assign tok_ready_o = rst_n && !busy_o && !valid_o && (ntok < MAX_TOK[7:0]);
  assign busy_o      = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      have <= 1'b0;
      ntok <= 8'd0;
      txor <= 8'd0;
      tsum <= 16'd0;
      crc  <= 16'hFFFF;
      first_t <= 8'd0;
      last_t  <= 8'd0;
      valid_o <= 1'b0;
      tok_count_o <= 8'd0;
      tok_xor_o   <= 8'd0;
      tok_sum_o   <= 16'd0;
      crc_o       <= 16'd0;
      first_tok_o <= 8'd0;
      last_tok_o  <= 8'd0;
      k0_o <= 16'd0; k1_o <= 16'd0; k2_o <= 16'd0; k3_o <= 16'd0;
    end else begin
      valid_o <= 1'b0;
      if (tok_valid_i && tok_ready_o) begin
        if (!have) first_t <= tok_i;
        have   <= 1'b1;
        last_t <= tok_i;
        ntok   <= ntok + 8'd1;
        txor   <= txor ^ tok_i;
        tsum   <= tsum + {8'd0, tok_i};
        crc    <= crc16_byte(crc, tok_i);
      end else if (fire_i && have) begin
        tok_count_o <= ntok;
        tok_xor_o   <= txor;
        tok_sum_o   <= tsum;
        crc_o       <= crc;
        first_tok_o <= first_t;
        last_tok_o  <= last_t;
        k0_o <= crc;
        k1_o <= crc ^ {txor, first_t};
        k2_o <= {tsum[7:0], txor} ^ {last_t, first_t};
        k3_o <= {ntok, txor} ^ crc;
        valid_o <= 1'b1;
        have <= 1'b0;
        ntok <= 8'd0;
        txor <= 8'd0;
        tsum <= 16'd0;
        crc  <= 16'hFFFF;
        first_t <= 8'd0;
        last_t  <= 8'd0;
      end
    end
  end
endmodule
