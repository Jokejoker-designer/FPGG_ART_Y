// a7ng_learn_key_class_context_v1.sv
// OWNER_LOCK: LEARNED_STATE_IDENTITY = TYPE_CLASS × QUERY_CONTEXT
// LAW = LEARN_KEY_CLASS_CONTEXT_V1
// FPGA-only. No raw NID. No host-constructed target. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_learn_key_class_context_v1 (
  input  logic [15:0] class_id_i,
  input  logic        q_ev_i,
  input  logic        q_iv_i,
  input  logic        q_rv_i,
  input  logic        q_xv_i,
  input  logic [7:0]  q_eid_i,
  input  logic [7:0]  q_iid_i,
  input  logic [7:0]  q_rid_i,
  input  logic [7:0]  q_xid_i,
  output logic [31:0] subj_o,
  output logic [7:0]  rel_o,
  output logic [31:0] obj_o
);
  localparam logic [15:0] TC_PREFIX = 16'h5443; // 'T''C' — reserved namespace

  assign subj_o = {TC_PREFIX, class_id_i};
  assign rel_o  = {4'b0000, q_xv_i, q_rv_i, q_iv_i, q_ev_i};
  assign obj_o  = {q_eid_i, q_iid_i, q_rid_i, q_xid_i};
endmodule
