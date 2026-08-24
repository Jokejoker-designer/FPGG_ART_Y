// a7ng_wm00_top.sv — A7-BRAM-WM-00 glue: 256 cand / 64 frontier / Top-8 / 32 learn / 16 PE / synth DDR
// No LM-06. mem_schema_v1 records. Law: a7ng-bram-wm00-v0.
`timescale 1ns / 1ps

module a7ng_wm00_top #(
  parameter int unsigned CAND_DEPTH = 256,
  parameter int unsigned FR_DEPTH   = 64,
  parameter int unsigned LEARN_DEPTH= 32,
  parameter int unsigned N_PE       = 16,
  parameter int unsigned K_EV       = 8
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] query_epoch_i,
  input  logic        ptr_invalidate_i,
  // owner requests
  input  logic        graph_wr_req_i,
  input  logic        lm_wr_req_i,
  input  logic        reset_wr_req_i,
  // DDR → candidate fill (host stimulates FPGA-owned fetch)
  input  logic        fill_node_req_i,
  input  logic [31:0] fill_node_id_i,
  input  logic        cand_push_i,          // push last fetched node into cand (TB timing)
  input  logic [31:0] cand_parent_i,
  input  logic [15:0] cand_rel_i,
  input  logic signed [15:0] cand_score_i,
  input  logic [15:0] cand_path_epoch_i,
  input  logic [7:0]  cand_agent_i,
  // frontier
  input  logic        fr_push_i,
  input  logic [31:0] fr_node_i,
  input  logic [31:0] fr_parent_i,
  input  logic [7:0]  fr_depth_i,
  input  logic signed [15:0] fr_score_i,
  input  logic [15:0] fr_conf_i,
  input  logic [2:0]  fr_status_i,
  input  logic [15:0] fr_path_epoch_i,
  input  logic [7:0]  fr_agent_i,
  input  logic        fr_pop_i,
  // evidence insert
  input  logic        ev_insert_i,
  input  logic [31:0] ev_node_i,
  input  logic [31:0] ev_subj_i,
  input  logic [15:0] ev_rel_i,
  input  logic [31:0] ev_obj_i,
  input  logic [31:0] ev_ep_i,
  input  logic signed [15:0] ev_score_i,
  input  logic [15:0] ev_conf_i,
  input  logic [7:0]  ev_depth_i,
  input  logic        ev_clear_i,
  // learn update
  input  logic        learn_push_i,
  input  logic [31:0] learn_subj_i,
  input  logic [15:0] learn_rel_i,
  input  logic [31:0] learn_obj_i,
  input  logic signed [15:0] learn_delta_i,
  input  logic [15:0] learn_evid_i,
  input  logic signed [7:0] learn_reward_i,
  input  logic [15:0] learn_conf_i,
  input  logic        learn_drain_i,
  // PE
  input  logic [N_PE-1:0] pe_req_i,
  // gated write enable: GRAPH owner only
  output logic        write_gate_o,
  // status / telemetry
  output logic [1:0]  owner_o,
  output logic        dual_owner_err_o,
  output logic [31:0] dual_owner_count_o,
  output logic        lm_grant_o,
  output logic [15:0] cand_count_o,
  output logic [15:0] cand_auth_o,
  output logic [31:0] cand_drop_o,
  output logic        cand_ready_o,
  output logic [15:0] fr_count_o,
  output logic [31:0] fr_drop_o,
  output logic        ev_ready_o,
  output logic [K_EV-1:0] ev_valid_mask_o,
  output logic [31:0] ev_node_o [K_EV],
  output logic signed [15:0] ev_score_o [K_EV],
  output logic [15:0] ev_count_o,
  output logic [15:0] learn_count_o,
  output logic [15:0] learn_dirty_o,
  output logic [31:0] learn_drop_o,
  output logic [31:0] learn_coal_o,
  output logic        learn_drain_valid_o,
  output logic [N_PE-1:0] pe_grant_o,
  output logic [N_PE-1:0] pe_valid_o,
  output logic [31:0] pe_busy_acc_o [N_PE],
  output logic [31:0] pe_grant_count_o,
  output logic [31:0] pe_cycles_o,
  output logic [15:0] pe_active_o,
  output logic [31:0] ddr_rd_bytes_o,
  output logic [31:0] ddr_wr_bytes_o,
  output logic [31:0] ddr_rd_count_o,
  output logic [31:0] ddr_wr_count_o,
  output logic        node_beat_valid_o,
  output logic [127:0] node_beat_o,
  output logic [31:0] last_node_id_o,
  output logic [31:0] last_node_cue_o
);
  import a7ng_mem_schema_v1_pkg::*;

  logic owner_graph_ok;
  assign write_gate_o = (owner_o == 2'd0);
  assign owner_graph_ok = write_gate_o;

  a7ng_wm00_owner u_own (
    .clk(clk), .rst_n(rst_n),
    .graph_wr_req_i(graph_wr_req_i),
    .lm_wr_req_i(lm_wr_req_i),
    .reset_wr_req_i(reset_wr_req_i),
    .owner_o(owner_o),
    .dual_owner_err_o(dual_owner_err_o),
    .dual_owner_count_o(dual_owner_count_o),
    .lm_grant_o(lm_grant_o)
  );

  logic        n_valid;
  logic [127:0] n_beat;
  logic        e_valid;
  logic [255:0] e_beat;
  logic        e_wr;
  logic [31:0] e_wr_id;
  logic [255:0] e_wr_beat;

  a7ng_wm00_synth_ddr #(.N_NODES(256), .N_EDGES(256)) u_ddr (
    .clk(clk), .rst_n(rst_n),
    .node_req_i(fill_node_req_i),
    .node_id_i(fill_node_id_i),
    .node_valid_o(n_valid),
    .node_beat_o(n_beat),
    .edge_req_i(1'b0),
    .edge_id_i(32'd0),
    .edge_valid_o(e_valid),
    .edge_beat_o(e_beat),
    .edge_wr_i(e_wr),
    .edge_wr_id_i(e_wr_id),
    .edge_wr_beat_i(e_wr_beat),
    .ddr_rd_bytes_o(ddr_rd_bytes_o),
    .ddr_wr_bytes_o(ddr_wr_bytes_o),
    .ddr_rd_count_o(ddr_rd_count_o),
    .ddr_wr_count_o(ddr_wr_count_o)
  );

  logic [127:0] latched_node;
  logic [31:0]  latched_id, latched_cue;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      latched_node <= '0;
      latched_id   <= '0;
      latched_cue  <= '0;
    end else if (n_valid) begin
      latched_node <= n_beat;
      latched_id   <= n_beat[31:0];
      latched_cue  <= n_beat[95:64];
    end
  end

  assign node_beat_valid_o = n_valid;
  assign node_beat_o = n_beat;
  assign last_node_id_o  = latched_id;
  assign last_node_cue_o = latched_cue;

  // Gate pushes on GRAPH owner
  wire cand_push_g = cand_push_i && owner_graph_ok;
  wire fr_push_g   = fr_push_i && owner_graph_ok;
  wire ev_ins_g    = ev_insert_i && owner_graph_ok;
  wire learn_push_g= learn_push_i && owner_graph_ok;

  logic        cand_pop;
  logic        cand_pop_v;
  logic [31:0] cand_pop_node, cand_pop_parent, cand_pop_cue;
  logic [15:0] cand_pop_rel, cand_pop_pe;
  logic signed [15:0] cand_pop_score;
  logic [7:0]  cand_pop_agent;
  logic [$clog2(CAND_DEPTH)-1:0] peek_idx;
  logic peek_auth;
  logic [31:0] peek_node;
  logic signed [15:0] peek_score;

  assign peek_idx = '0;

  a7ng_wm00_cand_buf #(.DEPTH(CAND_DEPTH)) u_cand (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(query_epoch_i),
    .push_i(cand_push_g),
    .node_id_i(latched_id),
    .parent_id_i(cand_parent_i),
    .relation_i(cand_rel_i),
    .cue_i(latched_cue),
    .base_score_i(cand_score_i),
    .path_epoch_i(cand_path_epoch_i),
    .logical_agent_i(cand_agent_i),
    .ready_o(cand_ready_o),
    .pop_i(cand_pop),
    .pop_valid_o(cand_pop_v),
    .pop_node_o(cand_pop_node),
    .pop_parent_o(cand_pop_parent),
    .pop_relation_o(cand_pop_rel),
    .pop_cue_o(cand_pop_cue),
    .pop_score_o(cand_pop_score),
    .pop_path_epoch_o(cand_pop_pe),
    .pop_logical_agent_o(cand_pop_agent),
    .peek_idx_i(peek_idx),
    .peek_auth_o(peek_auth),
    .peek_node_o(peek_node),
    .peek_score_o(peek_score),
    .count_o(cand_count_o),
    .auth_count_o(cand_auth_o),
    .drop_count_o(cand_drop_o),
    .ptr_invalidate_i(ptr_invalidate_i)
  );

  logic fr_pop_v;
  logic [31:0] fr_pop_node;
  logic signed [15:0] fr_pop_score;
  logic [2:0] fr_pop_st;

  a7ng_wm00_frontier #(.DEPTH(FR_DEPTH)) u_fr (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(query_epoch_i),
    .push_i(fr_push_g),
    .node_id_i(fr_node_i),
    .parent_id_i(fr_parent_i),
    .depth_i(fr_depth_i),
    .score_i(fr_score_i),
    .conf_i(fr_conf_i),
    .status_i(fr_status_i),
    .path_epoch_i(fr_path_epoch_i),
    .logical_agent_i(fr_agent_i),
    .ready_o(),
    .pop_i(fr_pop_i),
    .pop_valid_o(fr_pop_v),
    .pop_node_o(fr_pop_node),
    .pop_score_o(fr_pop_score),
    .pop_status_o(fr_pop_st),
    .count_o(fr_count_o),
    .drop_count_o(fr_drop_o),
    .ptr_invalidate_i(ptr_invalidate_i)
  );

  a7ng_wm00_evidence #(.K(K_EV)) u_ev (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(query_epoch_i),
    .insert_i(ev_ins_g),
    .node_id_i(ev_node_i),
    .subject_i(ev_subj_i),
    .relation_i(ev_rel_i),
    .object_i(ev_obj_i),
    .episode_i(ev_ep_i),
    .score_i(ev_score_i),
    .conf_i(ev_conf_i),
    .path_depth_i(ev_depth_i),
    .ready_o(ev_ready_o),
    .valid_mask_o(ev_valid_mask_o),
    .node_o(ev_node_o),
    .score_o(ev_score_o),
    .count_o(ev_count_o),
    .clear_i(ev_clear_i || ptr_invalidate_i)
  );

  logic [31:0] dr_subj, dr_obj;
  logic [15:0] dr_rel;
  logic signed [15:0] dr_delta;

  a7ng_wm00_learn_upd #(.DEPTH(LEARN_DEPTH)) u_learn (
    .clk(clk), .rst_n(rst_n),
    .active_query_epoch_i(query_epoch_i),
    .push_i(learn_push_g),
    .subject_i(learn_subj_i),
    .relation_i(learn_rel_i),
    .object_i(learn_obj_i),
    .delta_i(learn_delta_i),
    .evidence_count_i(learn_evid_i),
    .teacher_reward_i(learn_reward_i),
    .native_conf_i(learn_conf_i),
    .ready_o(),
    .drain_i(learn_drain_i),
    .drain_valid_o(learn_drain_valid_o),
    .drain_subject_o(dr_subj),
    .drain_relation_o(dr_rel),
    .drain_object_o(dr_obj),
    .drain_delta_o(dr_delta),
    .count_o(learn_count_o),
    .dirty_count_o(learn_dirty_o),
    .drop_count_o(learn_drop_o),
    .coalesce_hits_o(learn_coal_o),
    .ptr_invalidate_i(ptr_invalidate_i)
  );

  // On learn drain: write EdgeRecordV1 back (FPGA-owned edge id = subject low bits)
  always_comb begin
    e_wr = learn_drain_valid_o;
    e_wr_id = dr_subj;
    e_wr_beat = '0;
    e_wr_beat[31:0]    = dr_subj;
    e_wr_beat[63:32]   = dr_obj;
    e_wr_beat[79:64]   = dr_rel;
    e_wr_beat[111:96]  = dr_delta;
    e_wr_beat[207:192] = 16'(A7NG_MEM_SCHEMA_VERSION);
  end

  a7ng_wm00_pe_iface #(.N_PE(N_PE)) u_pe (
    .clk(clk), .rst_n(rst_n),
    .cand_valid_i(cand_pop_v),
    .cand_node_i(cand_pop_node),
    .cand_score_i(cand_pop_score),
    .cand_cue_i(cand_pop_cue),
    .cand_pop_o(cand_pop),
    .pe_req_i(pe_req_i),
    .pe_grant_o(pe_grant_o),
    .pe_node_o(),
    .pe_score_o(),
    .pe_cue_o(),
    .pe_valid_o(pe_valid_o),
    .lane_busy_acc_o(pe_busy_acc_o),
    .grant_count_o(pe_grant_count_o),
    .cycles_o(pe_cycles_o),
    .active_lanes_o(pe_active_o)
  );

  // silence unused
  wire _unused = e_valid | (|e_beat) | peek_auth | (|peek_node) | (|peek_score)
               | fr_pop_v | (|fr_pop_node) | (|fr_pop_score) | (|fr_pop_st)
               | (|cand_pop_parent) | (|cand_pop_rel) | (|cand_pop_pe) | (|cand_pop_agent);
endmodule
