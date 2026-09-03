// a7ng_cue_soa_mig_top.sv — ddr_cue_soa_00 DUT: SOA stage-1 fetch + unchanged scorer path
`timescale 1ns / 1ps

module a7ng_cue_soa_mig_top #(
  parameter int unsigned WAVE      = 16,
  parameter int unsigned MAX_CANDS = 64,
  parameter int unsigned MAX_OUT   = 8,
  parameter int unsigned MAX_BURST = 16,
  parameter int unsigned PHYS      = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  input  logic         cons_ready_i,
  input  logic [63:0]  q_query_cue_i,
  input  logic [63:0]  q_intent_cue_i,
  input  logic [63:0]  q_relation_cue_i,
  input  logic [63:0]  q_context_cue_i,
  input  logic [63:0]  q_path_cue_i,
  output logic         done_o,
  output logic         running_o,
  output logic [31:0]  cycles_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  cand_delivered_o,
  output logic [31:0]  data_mismatch_o,
  output logic [31:0]  swap_count_o,
  output logic [31:0]  buffer_empty_stall_o,
  output logic [31:0]  buffer_full_stall_o,
  output logic [31:0]  soa_id_beats_o,
  output logic [31:0]  soa_cue_beats_o,
  output logic [31:0]  soa_prior_beats_o,
  output logic [31:0]  bytes_id_o,
  output logic [31:0]  bytes_cue_o,
  output logic [31:0]  bytes_prior_o,
  output logic [31:0]  bytes_total_o,
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  expected_records_o,
  output logic [31:0]  received_records_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o,
  output logic [31:0]  topk_batches_o,
  output logic         topk_valid_o,
  output a7ng_pkg::score_t   topk_score_o [8],
  output a7ng_pkg::node_id_t topk_id_o    [8],
  output logic [3:0]   m_axi_arid,
  output logic [27:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [3:0]   m_axi_rid,
  input  logic [127:0] m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready,
  output logic         owner_ready_o,
  output logic         r_path_idle_o,
  output logic         global_topk_busy_o
);
  import a7ng_pkg::*;

  typedef enum logic [1:0] {
    OWN_IDLE,
    OWN_WAIT_DRAIN,
    OWN_CLEAR,
    OWN_WAIT_RELEASE
  } owner_e;

  logic         ar_valid, ar_ready, r_valid, r_ready, r_last;
  logic [27:0]  ar_addr;
  logic [7:0]   ar_len;
  logic [3:0]   ar_id;
  logic [2:0]   ar_size;
  logic [127:0] r_data;

  logic         core_batch_ready;
  logic         global_topk_busy;
  logic         wf_cons_ready;
  logic         sched_idle;
  logic         start_d;
  wire          start_pulse = start_i & ~start_d;

  logic         r_path_idle;
  logic         r_fifo_empty;
  logic [2:0]   r_fifo_level;
  logic [31:0]  br_outstanding;
  logic         plane_fetch_idle;
  logic         metric_clear;
  logic         wf_start;
  owner_e       owner_st;

  wire owner_ready = r_path_idle && r_fifo_empty && plane_fetch_idle &&
                     (br_outstanding == 32'd0) && !m_axi_rvalid;

  assign owner_ready_o = owner_ready;
  assign r_path_idle_o = r_path_idle;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      start_d <= 1'b0;
    else
      start_d <= start_i;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      owner_st <= OWN_IDLE;
      metric_clear <= 1'b0;
      wf_start <= 1'b0;
    end else begin
      metric_clear <= 1'b0;
      wf_start <= 1'b0;
      case (owner_st)
        OWN_IDLE: begin
          if (start_pulse) begin
            if (owner_ready)
              owner_st <= OWN_CLEAR;
            else
              owner_st <= OWN_WAIT_DRAIN;
          end
        end
        OWN_WAIT_DRAIN: begin
          if (owner_ready)
            owner_st <= OWN_CLEAR;
        end
        OWN_CLEAR: begin
          metric_clear <= 1'b1;
          owner_st <= OWN_WAIT_RELEASE;
        end
        OWN_WAIT_RELEASE: begin
          if (r_path_idle) begin
            wf_start <= 1'b1;
            owner_st <= OWN_IDLE;
          end
        end
        default: owner_st <= OWN_IDLE;
      endcase
    end
  end

  logic tg_ready;
  assign wf_cons_ready = cons_ready_i && core_batch_ready &&
                         sched_idle && tg_ready && !global_topk_busy;

  logic         wave_valid;
  logic [127:0] wave_rec [WAVE];
  logic [31:0]  wave_base_id;

  a7ng_cue_soa_wavefront #(
    .WAVE(WAVE), .MAX_CANDS(MAX_CANDS), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_soa (
    .clk(clk), .rst_n(rst_n),
    .start_i(wf_start),
    .bridge_idle_i(r_path_idle),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_node_i(base_node_i), .total_recs_i(total_recs_i),
    .ar_valid_o(ar_valid), .ar_ready_i(ar_ready),
    .ar_addr_o(ar_addr), .ar_len_o(ar_len), .ar_id_o(ar_id), .ar_size_o(ar_size),
    .r_valid_i(r_valid), .r_ready_o(r_ready),
    .r_data_i(r_data), .r_last_i(r_last),
    .cons_ready_i(wf_cons_ready),
    .wave_valid_o(wave_valid), .wave_rec_o(wave_rec), .wave_base_id_o(wave_base_id),
    .running_o(running_o), .done_o(done_o),
    .cycles_o(cycles_o), .waves_o(waves_o),
    .cand_delivered_o(cand_delivered_o),
    .data_mismatch_o(data_mismatch_o), .swap_count_o(swap_count_o),
    .buffer_empty_stall_o(buffer_empty_stall_o), .buffer_full_stall_o(buffer_full_stall_o),
    .soa_id_beats_o(soa_id_beats_o), .soa_cue_beats_o(soa_cue_beats_o),
    .soa_prior_beats_o(soa_prior_beats_o),
    .bytes_id_o(bytes_id_o), .bytes_cue_o(bytes_cue_o),
    .bytes_prior_o(bytes_prior_o), .bytes_total_o(bytes_total_o),
    .plane_fetch_idle_o(plane_fetch_idle),
    .cand_accepted_o(), .cand_queued_o(), .cand_inflight_o(), .cand_pruned_o(),
    .conserve_err_o(), .cons_ready_cycles_o(), .fill_cycles_o(), .fill_episodes_o(),
    .occ_fill_o(), .occ_drain_o(),
    .accepted_txns_o(), .accepted_beat_credit_o(), .returned_beats_o(),
    .returned_transactions_o(), .outstanding_txns_o(), .unpack_beats_o()
  );

  a7ng_ddr_soa_axi_bridge u_br (
    .clk(clk), .rst_n(rst_n),
    .metric_clear_i(metric_clear),
    .r_path_idle_o(r_path_idle),
    .r_fifo_empty_o(r_fifo_empty),
    .r_fifo_level_o(r_fifo_level),
    .outstanding_beats_o(br_outstanding),
    .ar_valid_i(ar_valid), .ar_ready_o(ar_ready),
    .ar_addr_i(ar_addr), .ar_len_i(ar_len), .ar_id_i(ar_id), .ar_size_i(ar_size),
    .r_valid_o(r_valid), .r_ready_i(r_ready),
    .r_data_o(r_data), .r_last_o(r_last), .r_id_o(),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .axi_read_bytes_o(axi_read_bytes_o),
    .axi_read_bursts_o(axi_read_bursts_o),
    .axi_read_beats_o(axi_read_beats_o),
    .rresp_error_count_o(rresp_error_count_o),
    .rlast_error_count_o(rlast_error_count_o),
    .expected_records_o(expected_records_o),
    .received_records_o(received_records_o),
    .rid_order_error_o(rid_order_error_o),
    .r_backpressure_cycles_o(r_backpressure_cycles_o)
  );

  localparam int unsigned NBATCH = WAVE / PHYS;

  typedef enum logic [1:0] {
    SCH_IDLE  = 2'd0,
    SCH_FIRE  = 2'd1,
    SCH_WAIT  = 2'd2,
    SCH_ISSUE = 2'd3
  } sch_e;

  sch_e sch;
  logic [2:0]   bidx;
  logic         issued;
  logic [127:0] rec_hold [WAVE];
  node_id_t     tg_id_hold [NG_LANES];
  score_terms_t tg_terms_hold [NG_LANES];
  logic [NG_LANES-1:0] core_valid;

  node_id_t      tg_id_in   [PHYS];
  termgen_cues_t tg_cues_in [PHYS];
  logic [PHYS-1:0] tg_valid_in;
  logic [PHYS-1:0] tg_valid_out;
  node_id_t        tg_id_out [PHYS];
  score_terms_t    tg_terms  [PHYS];

  assign sched_idle = (sch == SCH_IDLE);

  integer tk_c0, tk_c1, tk_f;
  always_comb begin
    for (tk_c0 = 0; tk_c0 < int'(PHYS); tk_c0++) begin
      tg_valid_in[tk_c0]              = (sch == SCH_FIRE);
      tg_id_in[tk_c0]                 = rec_hold[int'(bidx) * int'(PHYS) + tk_c0][31:0];
      tg_cues_in[tk_c0].query_cue     = q_query_cue_i;
      tg_cues_in[tk_c0].node_cue      = rec_hold[int'(bidx) * int'(PHYS) + tk_c0][95:32];
      tg_cues_in[tk_c0].relation_cue  = q_relation_cue_i;
      tg_cues_in[tk_c0].intent_cue    = q_intent_cue_i;
      tg_cues_in[tk_c0].context_cue   = q_context_cue_i;
      tg_cues_in[tk_c0].path_cue      = q_path_cue_i;
      tg_cues_in[tk_c0].learned_prior =
          term_t'(rec_hold[int'(bidx) * int'(PHYS) + tk_c0][103:96]);
    end
  end

  a7ng_termgen_array_fold6 #(.PHYS(PHYS)) u_tg (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tg_valid_in), .ready_o(tg_ready),
    .cand_id_i(tg_id_in), .cues_i(tg_cues_in),
    .valid_o(tg_valid_out), .ready_i(1'b1),
    .cand_id_o(tg_id_out), .terms_o(tg_terms)
  );

  node_id_t     tg_id_out16 [NG_LANES];
  score_terms_t tg_terms16  [NG_LANES];
  always_comb begin
    for (tk_c1 = 0; tk_c1 < int'(NG_LANES); tk_c1++) begin
      tg_id_out16[tk_c1] = tg_id_hold[tk_c1];
      tg_terms16[tk_c1]  = tg_terms_hold[tk_c1];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sch <= SCH_IDLE;
      bidx <= 3'd0;
      issued <= 1'b0;
      core_valid <= '0;
      for (tk_f = 0; tk_f < int'(WAVE); tk_f++)
        rec_hold[tk_f] <= '0;
      for (tk_f = 0; tk_f < int'(NG_LANES); tk_f++) begin
        tg_id_hold[tk_f]    <= '0;
        tg_terms_hold[tk_f] <= '0;
      end
    end else begin
      core_valid <= '0;
      unique case (sch)
        SCH_IDLE: begin
          if (wave_valid) begin
            for (tk_f = 0; tk_f < int'(WAVE); tk_f++)
              rec_hold[tk_f] <= wave_rec[tk_f];
            bidx <= 3'd0;
            sch <= SCH_FIRE;
          end
        end
        SCH_FIRE: begin
          if (tg_ready)
            sch <= SCH_WAIT;
        end
        SCH_WAIT: begin
          if (&tg_valid_out) begin
            for (tk_f = 0; tk_f < int'(PHYS); tk_f++) begin
              tg_id_hold[int'(bidx) * int'(PHYS) + tk_f]    <= tg_id_out[tk_f];
              tg_terms_hold[int'(bidx) * int'(PHYS) + tk_f] <= tg_terms[tk_f];
            end
            if (bidx == 3'(NBATCH - 1))
              sch <= SCH_ISSUE;
            else begin
              bidx <= bidx + 3'd1;
              sch <= SCH_FIRE;
            end
          end
        end
        SCH_ISSUE: begin
          if (!issued && core_batch_ready && !global_topk_busy) begin
            core_valid <= {NG_LANES{1'b1}};
            issued <= 1'b1;
          end else if (issued && !core_batch_ready) begin
            issued <= 1'b0;
            sch <= SCH_IDLE;
          end
        end
        default: sch <= SCH_IDLE;
      endcase
    end
  end

  logic core_topk_valid;
  score_t   core_topk_score [8];
  node_id_t core_topk_id    [8];
  logic global_topk_valid;
  score_t   global_topk_score [8];
  node_id_t global_topk_id    [8];
  logic [31:0] global_merge_count;
  logic [31:0] topk_batch_cnt;

  a7ng_ng02_core #(.PHYS(PHYS)) u_core (
    .clk(clk), .rst_n(rst_n),
    .lane_valid_i(core_valid),
    .cand_id_i(tg_id_out16),
    .terms_i(tg_terms16),
    .frontier_pop_i(1'b1),
    .batch_ready_o(core_batch_ready),
    .topk_valid_o(core_topk_valid),
    .topk_score_o(core_topk_score),
    .topk_id_o(core_topk_id),
    .frontier_pop_valid_o(), .frontier_score_o(), .frontier_id_o(),
    .frontier_overflow_o(), .frontier_count_o(),
    .flow_busy_o(), .push_idx_o(), .push_fire_o(), .push_stall_o(),
    .push_beat_valid_o(), .push_beat_score_o(), .push_beat_id_o(), .flow_state_o()
  );

  // Grok independent product copy: min-heap Global Top-8 (bitonic file frozen).
  // Local NG02 still computes an exact Top-8 per 16-candidate wave.
  a7ng_topk_wavefront_minheap #(.K(8), .HEAP_CMP_LANES(1)) u_global (
    .clk(clk), .rst_n(rst_n),
    .clear_i(wf_start),
    .wave_valid_i(core_topk_valid),
    .wave_scored_i(5'd16),
    .wave_score_i(core_topk_score),
    .wave_id_i(core_topk_id),
    .global_valid_o(global_topk_valid),
    .global_score_o(global_topk_score),
    .global_id_o(global_topk_id),
    .busy_o(global_topk_busy),
    .merge_count_o(global_merge_count)
  );

  assign topk_valid_o = global_topk_valid;
  assign global_topk_busy_o = global_topk_busy;
  always_comb begin
    for (int k = 0; k < 8; k++) begin
      topk_score_o[k] = global_topk_score[k];
      topk_id_o[k]    = global_topk_id[k];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      topk_batch_cnt <= '0;
    else if (wf_start)
      topk_batch_cnt <= '0;
    else if (wave_valid && core_batch_ready)
      topk_batch_cnt <= topk_batch_cnt + 32'd1;
  end
  assign topk_batches_o = topk_batch_cnt;

endmodule
