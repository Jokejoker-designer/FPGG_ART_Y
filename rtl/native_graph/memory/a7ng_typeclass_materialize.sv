// a7ng_typeclass_materialize.sv — U6 CLASS_ID → frozen TYPE_CLASS row.
// NOT a raw-NID LUT. CLASS_ID is not NID. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_typeclass_materialize (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        go_i,
  input  logic [15:0] class_id_i,
  input  logic        poison_en_i,
  input  logic [15:0] poison_class_id_i,
  input  logic [7:0]  poison_eid_i,
  output logic        hit_o,
  output logic [15:0] class_id_o,
  output logic [7:0]  eid_o,
  output logic [7:0]  iid_o,
  output logic [7:0]  rid_o,
  output logic [7:0]  xid_o,
  output logic [15:0] member_ptr_o,
  output logic [15:0] member_count_o
);
  `include "typeclass_table.svh"

  logic        hit_c;
  logic [15:0] idx;
  logic [7:0]  e_c, i_c, r_c, x_c;
  logic [15:0] p_c, n_c, id_c;

  always_comb begin
    hit_c = 1'b0;
    e_c = 8'd0; i_c = 8'd0; r_c = 8'd0; x_c = 8'd0;
    p_c = 16'd0; n_c = 16'd0; id_c = 16'd0;
    idx = 16'd0;
    if ((class_id_i >= 16'd1) && (class_id_i <= 16'(TC_N))) begin
      idx = class_id_i - 16'd1;
      if (TC_ID[idx] == class_id_i) begin
        hit_c = 1'b1;
        id_c  = TC_ID[idx];
        e_c   = TC_EID[idx];
        i_c   = TC_IID[idx];
        r_c   = TC_RID[idx];
        x_c   = TC_XID[idx];
        p_c   = TC_MPTR[idx];
        n_c   = TC_MCNT[idx];
      end
    end
    if (poison_en_i && (class_id_i == poison_class_id_i) && hit_c)
      e_c = poison_eid_i;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hit_o <= 1'b0;
      class_id_o <= 16'd0;
      eid_o <= 8'd0; iid_o <= 8'd0; rid_o <= 8'd0; xid_o <= 8'd0;
      member_ptr_o <= 16'd0; member_count_o <= 16'd0;
    end else if (go_i) begin
      hit_o <= hit_c;
      class_id_o <= id_c;
      eid_o <= e_c; iid_o <= i_c; rid_o <= r_c; xid_o <= x_c;
      member_ptr_o <= p_c; member_count_o <= n_c;
    end
  end
endmodule
