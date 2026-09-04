// OOC shell for U3Q-R3 frontend. PROGRAM=NO. DSP must be 0.
`timescale 1ns / 1ps
module a7ng_query_struct_ooc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  output logic        valid_o,
  output logic [15:0] k0_o,
  output logic [15:0] k1_o,
  output logic [15:0] k2_o,
  output logic [15:0] k3_o
);
  a7ng_query_struct_extract u (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_valid_i), .tok_ready_o(tok_ready_o), .tok_i(tok_i),
    .fire_i(fire_i), .retire_i(retire_i),
    .busy_o(), .accepted_o(), .valid_o(valid_o),
    .entity_id_o(), .intent_id_o(), .relation_id_o(), .context_id_o(),
    .entity_cue_o(), .intent_cue_o(), .relation_cue_o(), .context_cue_o(),
    .crc16_dbg_o(), .k0_o(k0_o), .k1_o(k1_o), .k2_o(k2_o), .k3_o(k3_o),
    .n_host_entity_o(), .n_host_intent_o(), .n_host_hash_o(),
    .n_host_shard_o(), .n_host_bucket_o(), .n_host_cand_o(),
    .n_host_winner_o(), .n_host_addr_o(), .n_host_relpath_o(),
    .n_host_next_o(), .n_host_answer_o()
  );
endmodule
