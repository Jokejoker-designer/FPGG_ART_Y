// a7ng_typeclass_ooc_top.sv — OOC wrapper. BIT=NO.
`timescale 1ns / 1ps
module a7ng_typeclass_ooc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        q_go_i,
  output logic        q_ready_o,
  input  logic [7:0]  q_eid_i,
  input  logic [7:0]  q_iid_i,
  input  logic [7:0]  q_rid_i,
  input  logic [7:0]  q_xid_i,
  input  logic        q_ev_i,
  input  logic        q_iv_i,
  input  logic        q_rv_i,
  input  logic        q_xv_i,
  output logic        cand_v_o,
  input  logic        cand_ready_i,
  output logic [15:0] cand_id_o,
  output logic        q_done_o,
  output logic        q_overflow_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_trunc_o
);
  a7ng_typeclass_scan u_tc (
    .clk(clk), .rst_n(rst_n),
    .q_go_i(q_go_i), .q_ready_o(q_ready_o),
    .q_eid_i(q_eid_i), .q_iid_i(q_iid_i), .q_rid_i(q_rid_i), .q_xid_i(q_xid_i),
    .q_ev_i(q_ev_i), .q_iv_i(q_iv_i), .q_rv_i(q_rv_i), .q_xv_i(q_xv_i),
    .cand_v_o(cand_v_o), .cand_ready_i(cand_ready_i), .cand_id_o(cand_id_o),
    .q_done_o(q_done_o), .q_overflow_o(q_overflow_o),
    .n_emit_o(n_emit_o), .n_trunc_o(n_trunc_o)
  );
endmodule
