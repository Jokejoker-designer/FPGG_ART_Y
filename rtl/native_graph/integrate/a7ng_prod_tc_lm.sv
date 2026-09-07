// a7ng_prod_tc_lm.sv — C02 production TYPE_CLASS path without a second LM.
// raw query → QSE → U6 → encoder V1 → lm_ctx_fwd_v1 → shared TinyGPT ports.
// CLASS_ID is ranking identity only. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_prod_tc_lm #(
  parameter int unsigned CAND_CAP = 64,
  parameter int unsigned K        = 8,
  parameter int unsigned MAX_NTOK = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tok_valid_i,
  output logic        tok_ready_o,
  input  logic [7:0]  tok_i,
  input  logic        fire_i,
  input  logic        retire_i,
  input  logic        core_busy_i,
  input  logic        core_done_i,
  input  logic [9:0]  core_pred_i,
  output logic        qse_valid_o,
  output logic [7:0]  q_ent_o,
  output logic [7:0]  q_int_o,
  output logic [7:0]  q_rel_o,
  output logic [7:0]  q_ctx_o,
  output logic        retrieval_done_o,
  output logic [15:0] topk_class_id_o [K],
  output a7ng_pkg::node_id_t topk_id_o [K],
  output logic [15:0] n_host_or_o,
  output logic [6:0]  enc_ntok_o,
  output logic [7:0]  enc_tok_o [0:MAX_NTOK-1],
  output logic [3:0]  enc_n_rec_o,
  output logic [3:0]  enc_n_skip_o,
  output logic        ctx_we_o,
  output logic [6:0]  ctx_idx_o,
  output logic [6:0]  ctx_n_in_o,
  output logic [63:0] ctx_pack_o,
  output logic        start_fwd_o,
  output logic        path_busy_o,
  output logic        path_done_o,
  output logic [9:0]  pred_o,
  output logic [31:0] ctx_we_beats_o,
  output logic [31:0] start_fwd_beats_o,
  output logic [2:0]  dbg_st_o
);
  import a7ng_pkg::*;

  typedef enum logic [2:0] { S_IDLE, S_ARM, S_GO, S_WAIT, S_DONE } st_t;
  st_t st;

  logic        u6_done;
  score_t      top_sc [K];
  logic [15:0] cid_lat [0:K-1];
  logic [15:0] cid_enc [0:K-1];
  integer      ki;
  logic enc_go, enc_busy, enc_done, enc_beat_v, glue_go, glue_busy, glue_done;
  logic [3:0] enc_beat_n;
  logic [63:0] enc_pack;
  logic [15:0] n_emit, n_scored, n_trunc;
  logic ovf;

  assign cid_enc = cid_lat;
  assign retrieval_done_o = u6_done;
  assign path_busy_o = (st != S_IDLE) && (st != S_DONE);
  assign dbg_st_o = st;
  assign pred_o = core_pred_i;

  a7ng_u6_typeclass_retrieval #(.CAND_CAP(CAND_CAP), .K(K)) u_u6 (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_valid_i), .tok_ready_o(tok_ready_o), .tok_i(tok_i),
    .fire_i(fire_i), .retire_i(retire_i),
    .qse_valid_o(qse_valid_o),
    .q_ent_o(q_ent_o), .q_int_o(q_int_o), .q_rel_o(q_rel_o), .q_ctx_o(q_ctx_o),
    .n_host_or_o(n_host_or_o),
    .poke_i(1'b0), .poke_go_i(1'b0),
    .poke_ent_i(8'd0), .poke_int_i(8'd0), .poke_rel_i(8'd0), .poke_ctx_i(8'd0),
    .poke_ev_i(1'b0), .poke_iv_i(1'b0), .poke_rv_i(1'b0), .poke_xv_i(1'b0),
    .stall_scan_i(1'b0), .stall_heap_i(1'b0),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .done_o(u6_done), .retrieval_overflow_o(ovf), .retrieval_trunc_o(n_trunc),
    .n_emit_o(n_emit), .n_scored_o(n_scored),
    .topk_id_o(topk_id_o), .topk_class_id_o(topk_class_id_o), .topk_sc_o(top_sc),
    .dbg_st_o(), .dbg_scan_v_o(), .dbg_scan_id_o(),
    .dbg_mat_v_o(), .dbg_mat_id_o(),
    .dbg_mat_eid_o(), .dbg_mat_iid_o(), .dbg_mat_rid_o(), .dbg_mat_xid_o(),
    .dbg_mat_ptr_o(), .dbg_mat_cnt_o(),
    .dbg_sc_v_o(), .dbg_sc_o(), .dbg_te_o(), .dbg_ti_o(), .dbg_tr_o(), .dbg_tc_o()
  );

  a7ng_lm_ctx_encoder_v1 #(.K(K), .MAX_NTOK(MAX_NTOK)) u_enc (
    .clk(clk), .rst_n(rst_n), .go_i(enc_go),
    .class_id_i(cid_enc),
    .busy_o(enc_busy), .done_o(enc_done),
    .ntok_o(enc_ntok_o), .beat_v_o(enc_beat_v), .beat_n_o(enc_beat_n),
    .beat_pack_o(enc_pack), .tok_o(enc_tok_o),
    .n_rec_o(enc_n_rec_o), .n_skip_o(enc_n_skip_o)
  );

  a7ng_lm_ctx_fwd_v1 u_fwd (
    .clk(clk), .rst_n(rst_n), .go_i(glue_go),
    .enc_go_o(enc_go),
    .enc_busy_i(enc_busy), .enc_done_i(enc_done), .enc_ntok_i(enc_ntok_o),
    .enc_beat_v_i(enc_beat_v), .enc_beat_n_i(enc_beat_n),
    .enc_beat_pack_i(enc_pack),
    .core_busy_i(core_busy_i), .core_done_i(core_done_i), .core_pred_i(core_pred_i),
    .ctx_we_o(ctx_we_o), .ctx_idx_o(ctx_idx_o), .ctx_n_in_o(ctx_n_in_o),
    .ctx_pack_o(ctx_pack_o), .start_fwd_o(start_fwd_o),
    .busy_o(glue_busy), .done_o(glue_done), .pred_o(),
    .ctx_we_beats_o(ctx_we_beats_o), .start_fwd_beats_o(start_fwd_beats_o)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      glue_go <= 1'b0;
      path_done_o <= 1'b0;
      for (ki = 0; ki < K; ki = ki + 1)
        cid_lat[ki] <= 16'd0;
    end else begin
      glue_go <= 1'b0;
      path_done_o <= 1'b0;
      unique case (st)
        S_IDLE: if (u6_done) begin
          for (ki = 0; ki < K; ki = ki + 1)
            cid_lat[ki] <= topk_class_id_o[ki];
          st <= S_ARM;
        end
        S_ARM: st <= S_GO;
        S_GO: if (!enc_busy && !core_busy_i && !glue_busy) begin
          glue_go <= 1'b1;
          st <= S_WAIT;
        end
        S_WAIT: if (glue_done) begin
          path_done_o <= 1'b1;
          st <= S_DONE;
        end
        S_DONE: st <= S_IDLE;
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
