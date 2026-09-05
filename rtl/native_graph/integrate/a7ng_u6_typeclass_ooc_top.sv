// a7ng_u6_typeclass_ooc_top.sv — OOC wrapper. BIT=NO. poison/stall tied off.
`timescale 1ns / 1ps

module a7ng_u6_typeclass_ooc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  input  logic        poke_i,
  input  logic        poke_go_i,
  input  logic [7:0]  poke_ent_i,
  input  logic [7:0]  poke_int_i,
  input  logic [7:0]  poke_rel_i,
  input  logic [7:0]  poke_ctx_i,
  input  logic        poke_ev_i,
  input  logic        poke_iv_i,
  input  logic        poke_rv_i,
  input  logic        poke_xv_i,
  output logic        done_o,
  output logic        retrieval_overflow_o,
  output logic [15:0] retrieval_trunc_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_scored_o,
  output logic [15:0] topk_class_id_0,
  output logic [15:0] topk_class_id_1,
  output logic signed [15:0] topk_sc_0
);
  import a7ng_pkg::*;
  node_id_t topk_id [8];
  logic [15:0] topk_cid [8];
  score_t topk_sc [8];

  a7ng_u6_typeclass_retrieval #(.CAND_CAP(64), .K(8)) u_u6 (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_valid_i), .tok_ready_o(tok_ready_o), .tok_i(tok_i),
    .fire_i(fire_i), .retire_i(retire_i),
    .qse_valid_o(), .q_ent_o(), .q_int_o(), .q_rel_o(), .q_ctx_o(),
    .n_host_or_o(),
    .poke_i(poke_i), .poke_go_i(poke_go_i),
    .poke_ent_i(poke_ent_i), .poke_int_i(poke_int_i),
    .poke_rel_i(poke_rel_i), .poke_ctx_i(poke_ctx_i),
    .poke_ev_i(poke_ev_i), .poke_iv_i(poke_iv_i),
    .poke_rv_i(poke_rv_i), .poke_xv_i(poke_xv_i),
    .stall_scan_i(1'b0), .stall_heap_i(1'b0),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .done_o(done_o), .retrieval_overflow_o(retrieval_overflow_o),
    .retrieval_trunc_o(retrieval_trunc_o),
    .n_emit_o(n_emit_o), .n_scored_o(n_scored_o),
    .topk_id_o(topk_id), .topk_class_id_o(topk_cid), .topk_sc_o(topk_sc),
    .dbg_st_o(), .dbg_scan_v_o(), .dbg_scan_id_o(),
    .dbg_mat_v_o(), .dbg_mat_id_o(),
    .dbg_mat_eid_o(), .dbg_mat_iid_o(), .dbg_mat_rid_o(), .dbg_mat_xid_o(),
    .dbg_mat_ptr_o(), .dbg_mat_cnt_o(),
    .dbg_sc_v_o(), .dbg_sc_o(), .dbg_te_o(), .dbg_ti_o(), .dbg_tr_o(), .dbg_tc_o()
  );

  assign topk_class_id_0 = topk_cid[0];
  assign topk_class_id_1 = topk_cid[1];
  assign topk_sc_0 = topk_sc[0];
endmodule
