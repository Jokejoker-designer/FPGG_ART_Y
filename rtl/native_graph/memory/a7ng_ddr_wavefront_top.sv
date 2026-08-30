// a7ng_ddr_wavefront_top.sv — DDR → burst compact cue fetch → ping A/B → 16-candidate wave
//                              → EXISTING 16-lane TermGen+scorer → EXISTING true Top-8
// Gate: ddr_wavefront_00. Memory DELIVERY only. Law: a7ng-cue-wave-v0 (delivery), everything
// downstream is instantiated UNCHANGED as a black box:
//   a7ng_ddr_feed_pp            (a7ng-ddr-feed-wm01-v0)
//   a7ng_ddr_feed_axi_bridge    (a7ng-mig-rival-v0 + mig_metric_00 per-run deltas)
//   a7ng_termgen_array          (a7ng-termgen-v0)
//   a7ng_scorer_array           (a7ng-scorer-v0)
//   a7ng_topk                   (a7ng-topk-global-v1) — per-wave 16→8, law frozen
//   a7ng_topk_wavefront_minheap — serial/min-heap cross-wave Top-8 (not bitonic)
// Evidence class: MIG_XSIM only. Never claim BOARD_PASS or silicon bandwidth from this.
`timescale 1ns / 1ps

module a7ng_ddr_wavefront_top #(
  parameter int unsigned BANK_DEPTH       = 32,
  parameter int unsigned N_LANES          = 16,
  parameter int unsigned ENTRIES_PER_BANK = 16,
  parameter int unsigned MAX_OUT          = 8,
  parameter int unsigned MAX_BURST        = 16
) (
  input  logic         clk,      // MIG ui_clk
  input  logic         rst_n,    // ~ui_clk_sync_rst && calib
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  input  logic         sink_ready_i,  // downstream consumer ready (throttle pattern)
  input  logic         flush_i,       // allow tail partial wave
  // read-only query context, broadcast to all 16 lanes (SPEC §11 replication)
  input  a7ng_pkg::cue_t  query_cue_i,
  input  a7ng_pkg::cue_t  relation_cue_i,
  input  a7ng_pkg::cue_t  intent_cue_i,
  input  a7ng_pkg::cue_t  context_cue_i,
  input  a7ng_pkg::cue_t  path_cue_i,
  input  a7ng_pkg::term_t learned_prior_i,
  // ---- status ----
  output logic         feed_done_o,
  output logic         wave_done_o,
  output logic         running_o,
  // ---- ping/pong telemetry (SPEC §10) ----
  output logic [31:0]  buffer_empty_stall_o,
  output logic [31:0]  buffer_full_stall_o,
  output logic [31:0]  swap_count_o,
  output logic [31:0]  pp_cycles_o,
  output logic [31:0]  pp_consumed_o,
  output logic [15:0]  occ_active_o,
  output logic [15:0]  occ_fill_o,
  output logic [31:0]  pp_resident_o,
  // ---- AXI per-run deltas (MIG-METRIC-00 semantics) ----
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  expected_records_o,
  output logic [31:0]  received_records_o,
  output logic [31:0]  beat_mismatch_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o,
  // ---- wavefront telemetry ----
  output logic [31:0]  wave_accepted_o,
  output logic [31:0]  wave_dispatched_o,
  output logic [31:0]  wave_resident_o,
  output logic [31:0]  wave_max_resident_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  partial_waves_o,
  output logic [31:0]  emit_cycles_o,
  output logic [31:0]  fill_cycles_o,
  output logic [31:0]  mem_wait_cycles_o,
  output logic [31:0]  sink_wait_cycles_o,
  output logic [31:0]  active_cycles_o,
  output logic [31:0]  bank_full_stall_o,
  output logic [31:0]  wave_struct_mismatch_o,
  output logic [31:0]  wave_bank_map_err_o,
  // ---- wave observation (TB scoreboard) ----
  output logic         wave_fire_o,
  output logic [N_LANES-1:0] wave_mask_o,
  output logic [31:0]  wave_id_o  [N_LANES],
  output logic [31:0]  wave_cue_o [N_LANES],
  output logic [31:0]  wave_index_o,
  // ---- lane / Top-K diagnostics (non-gate) ----
  output logic [31:0]  lane_scored_o,
  output logic [31:0]  lane_busy_cycles_o,
  output logic [31:0]  topk_batches_o,
  output logic [31:0]  global_merge_count_o,
  output logic         global_topk_valid_o,
  output logic [31:0]  global_topk_id_o   [MAX_OUT],
  output logic signed [15:0] global_topk_score_o [MAX_OUT],
  output logic [31:0]  top1_id_o,
  output logic signed [15:0] top1_score_o,
  // ---- Digilent AXI MIG read master ----
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
  output logic         m_axi_rready
);
  import a7ng_pkg::*;

  // ---------------- ping/pong feeder (unchanged law) ----------------
  logic         ar_valid, ar_ready;
  logic [31:0]  ar_addr;
  logic [7:0]   ar_len;
  logic [3:0]   ar_id;
  logic         r_valid, r_ready, r_last;
  logic [127:0] r_data;
  logic [3:0]   r_id;

  logic         pp_pop, pp_valid;
  logic [127:0] pp_data;
  logic [31:0]  pp_empty_st, pp_full_st, pp_pe_st, pp_pe_bs, pp_cyc, pp_cons, pp_drop;
  logic [15:0]  occ_a, occ_f;
  logic         active_bank, pp_running, pp_done;

  a7ng_ddr_feed_pp #(
    .BANK_DEPTH(BANK_DEPTH), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_pp (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_i),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_node_i(base_node_i), .total_recs_i(total_recs_i),
    .ar_valid_o(ar_valid), .ar_ready_i(ar_ready),
    .ar_addr_o(ar_addr), .ar_len_o(ar_len), .ar_id_o(ar_id),
    .r_valid_i(r_valid), .r_ready_o(r_ready),
    .r_data_i(r_data), .r_last_i(r_last),
    .pe_pop_i(pp_pop), .pe_valid_o(pp_valid), .pe_data_o(pp_data),
    .done_o(pp_done), .running_o(pp_running),
    .empty_stall_o(pp_empty_st), .full_stall_o(pp_full_st),
    .pe_stall_o(pp_pe_st), .pe_busy_o(pp_pe_bs),
    .cycles_o(pp_cyc), .recs_consumed_o(pp_cons),
    .drop_o(pp_drop),
    .occ_active_o(occ_a), .occ_fill_o(occ_f),
    .active_bank_o(active_bank)
  );

  // ---------------- AXI bridge (unchanged; per-run metric_clear) ----------------
  logic [31:0] br_bytes, br_bursts, br_beats, br_exp, br_rcv, br_mm;
  logic [31:0] br_dummy_rd_b, br_dummy_rd_c, br_dummy_br_c;
  logic [3:0]  br_rid_obs;

  a7ng_ddr_feed_axi_bridge u_br (
    .clk(clk), .rst_n(rst_n),
    .metric_clear_i(start_i),
    .ar_valid_i(ar_valid), .ar_ready_o(ar_ready),
    .ar_addr_i(ar_addr), .ar_len_i(ar_len), .ar_id_i(ar_id),
    .r_valid_o(r_valid), .r_ready_i(r_ready),
    .r_data_o(r_data), .r_last_o(r_last), .r_id_o(r_id),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .ddr_rd_bytes_o(br_dummy_rd_b),
    .ddr_rd_count_o(br_dummy_rd_c),
    .ddr_burst_count_o(br_dummy_br_c),
    .axi_read_bytes_o(br_bytes),
    .axi_read_bursts_o(br_bursts),
    .axi_read_beats_o(br_beats),
    .data_mismatch_count_o(br_mm),
    .rresp_error_count_o(rresp_error_count_o),
    .rlast_error_count_o(rlast_error_count_o),
    .expected_records_o(br_exp),
    .received_records_o(br_rcv),
    .rid_observed_o(br_rid_obs),
    .rid_order_error_o(rid_order_error_o),
    .r_backpressure_cycles_o(r_backpressure_cycles_o)
  );

  // ---------------- bounded compact-cue working set → 16-wide wave ----------------
  logic wave_valid, wave_in_ready, wave_active, wave_done;
  logic [N_LANES-1:0] w_mask;
  logic [31:0] w_id  [N_LANES];
  logic [31:0] w_cue [N_LANES];
  logic gl_busy;
  logic gl_pipe_inflight;
  wire  wave_cons_ready;

  // pp_pop is a REQUEST: asserting it while pp is empty is what makes
  // buffer_empty_stall meaningful (SPEC §10). pp only pops when pe_valid_o is high.
  assign pp_pop = wave_in_ready;

  a7ng_cue_wave_stage #(
    .N_LANES(N_LANES), .ENTRIES_PER_BANK(ENTRIES_PER_BANK)
  ) u_wave (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_i),
    .total_i(total_recs_i),
    .flush_i(flush_i),
    .in_valid_i(pp_valid), .in_ready_o(wave_in_ready), .in_rec_i(pp_data),
    .wave_ready_i(wave_cons_ready),
    .wave_valid_o(wave_valid),
    .wave_mask_o(w_mask), .wave_id_o(w_id), .wave_cue_o(w_cue),
    .wave_index_o(wave_index_o),
    .accepted_o(wave_accepted_o),
    .dispatched_o(wave_dispatched_o),
    .resident_o(wave_resident_o),
    .max_resident_o(wave_max_resident_o),
    .waves_o(waves_o),
    .partial_waves_o(partial_waves_o),
    .emit_cycles_o(emit_cycles_o),
    .fill_cycles_o(fill_cycles_o),
    .mem_wait_cycles_o(mem_wait_cycles_o),
    .sink_wait_cycles_o(sink_wait_cycles_o),
    .active_cycles_o(active_cycles_o),
    .bank_full_stall_o(bank_full_stall_o),
    .struct_mismatch_o(wave_struct_mismatch_o),
    .bank_map_err_o(wave_bank_map_err_o),
    .active_o(wave_active),
    .done_o(wave_done)
  );

  wire wave_fire = wave_valid && wave_cons_ready;

  assign wave_fire_o = wave_fire;
  assign wave_mask_o = w_mask;
  always_comb begin
    for (int b = 0; b < N_LANES; b++) begin
      wave_id_o[b]  = w_id[b];
      wave_cue_o[b] = w_cue[b];
    end
  end

  // ---------------- EXISTING 16 lanes: TermGen → scorer → true Top-8 ----------------
  logic [N_LANES-1:0] tg_valid_i;
  node_id_t           tg_id_i   [N_LANES];
  termgen_cues_t      tg_cues_i [N_LANES];
  logic [N_LANES-1:0] tg_valid_o;
  node_id_t           tg_id_o   [N_LANES];
  score_terms_t       tg_terms_o[N_LANES];

  logic [N_LANES-1:0] sc_valid_o;
  node_id_t           sc_id_o   [N_LANES];
  score_t             sc_score_o[N_LANES];

  always_comb begin
    for (int b = 0; b < N_LANES; b++) begin
      tg_valid_i[b] = wave_fire && w_mask[b];
      tg_id_i[b]    = w_id[b];
      // 32-bit NodeRecordV1 cue widened to the 64-bit cue bus by replication
      // (wiring choice of this gate; TermGen law itself untouched)
      tg_cues_i[b].query_cue     = query_cue_i;
      tg_cues_i[b].node_cue      = {w_cue[b], w_cue[b]};
      tg_cues_i[b].relation_cue  = relation_cue_i;
      tg_cues_i[b].intent_cue    = intent_cue_i;
      tg_cues_i[b].context_cue   = context_cue_i;
      tg_cues_i[b].path_cue      = path_cue_i;
      tg_cues_i[b].learned_prior = learned_prior_i;
    end
  end

  a7ng_termgen_array u_tg (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tg_valid_i), .cand_id_i(tg_id_i), .cues_i(tg_cues_i),
    .valid_o(tg_valid_o), .cand_id_o(tg_id_o), .terms_o(tg_terms_o)
  );

  a7ng_scorer_array u_sc (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tg_valid_o), .cand_id_i(tg_id_o), .terms_i(tg_terms_o),
    .valid_o(sc_valid_o), .cand_id_o(sc_id_o), .score_o(sc_score_o)
  );

  logic       tk_valid_o;
  score_t     tk_score_o [8];
  node_id_t   tk_id_o    [8];

  a7ng_topk #(.N(N_LANES), .K(8)) u_tk (
    .clk(clk), .rst_n(rst_n),
    .valid_i(|sc_valid_o), .valid_mask_i(sc_valid_o),
    .score_i(sc_score_o), .id_i(sc_id_o),
    .valid_o(tk_valid_o), .score_o(tk_score_o), .id_o(tk_id_o)
  );

  logic [4:0] wave_scored_q;
  logic       gl_valid_o;
  score_t     gl_score_o [8];
  node_id_t   gl_id_o    [8];
  logic [31:0] gl_merges;
  logic [31:0] lane_pop;

  always_comb begin
    lane_pop = 32'd0;
    for (int b = 0; b < N_LANES; b++)
      if (sc_valid_o[b]) lane_pop = lane_pop + 32'd1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      wave_scored_q <= 5'd0;
    else if (start_i)
      wave_scored_q <= 5'd0;
    else if (|sc_valid_o)
      wave_scored_q <= 5'(lane_pop);
  end

  // Serial/min-heap: one wave in TG→SC→local Top-8→merge at a time.
  // Frozen bitonic a7ng_topk_wavefront_global is 1–2 cycle; do not reuse that handshake.
  assign wave_cons_ready = sink_ready_i && !gl_busy && !gl_pipe_inflight && !tk_valid_o;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      gl_pipe_inflight <= 1'b0;
    else if (start_i)
      gl_pipe_inflight <= 1'b0;
    else if (wave_fire)
      gl_pipe_inflight <= 1'b1;
    else if (tk_valid_o)
      gl_pipe_inflight <= 1'b0;
  end

  a7ng_topk_wavefront_minheap #(.K(8), .HEAP_CMP_LANES(1)) u_global (
    .clk(clk), .rst_n(rst_n),
    .clear_i(start_i),
    .wave_valid_i(tk_valid_o),
    .wave_scored_i(wave_scored_q),
    .wave_score_i(tk_score_o),
    .wave_id_i(tk_id_o),
    .global_valid_o(gl_valid_o),
    .global_score_o(gl_score_o),
    .global_id_o(gl_id_o),
    .busy_o(gl_busy),
    .merge_count_o(gl_merges)
  );

  // ---------------- derived telemetry ----------------
  logic [31:0] scored, lane_busy, tk_batches, swaps;
  logic        act_bank_q;

  assign lane_scored_o      = scored;
  assign lane_busy_cycles_o = lane_busy;
  assign topk_batches_o     = tk_batches;
  assign global_merge_count_o = gl_merges;
  assign swap_count_o       = swaps;
  assign top1_id_o          = gl_valid_o ? gl_id_o[0] : tk_id_o[0];
  assign top1_score_o       = gl_valid_o ? gl_score_o[0] : tk_score_o[0];
  assign global_topk_valid_o = gl_valid_o;
  always_comb begin
    for (int gi = 0; gi < MAX_OUT; gi++) begin
      global_topk_id_o[gi]    = gl_id_o[gi];
      global_topk_score_o[gi] = gl_score_o[gi];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      scored     <= 32'd0;
      lane_busy  <= 32'd0;
      tk_batches <= 32'd0;
      swaps      <= 32'd0;
      act_bank_q <= 1'b0;
    end else if (start_i) begin
      scored     <= 32'd0;
      lane_busy  <= 32'd0;
      tk_batches <= 32'd0;
      swaps      <= 32'd0;
      act_bank_q <= active_bank;
    end else begin
      scored <= scored + lane_pop;
      if (|sc_valid_o)
        lane_busy <= lane_busy + 32'd1;
      if (tk_valid_o)
        tk_batches <= tk_batches + 32'd1;
      if (active_bank != act_bank_q)
        swaps <= swaps + 32'd1;
      act_bank_q <= active_bank;
    end
  end

  assign feed_done_o          = pp_done;
  assign wave_done_o          = wave_done;
  assign running_o            = pp_running || wave_active || gl_busy || gl_pipe_inflight;
  assign buffer_empty_stall_o = pp_empty_st;
  assign buffer_full_stall_o  = pp_full_st;
  assign pp_cycles_o          = pp_cyc;
  assign pp_consumed_o        = pp_cons;
  assign occ_active_o         = occ_a;
  assign occ_fill_o           = occ_f;
  assign pp_resident_o        = 32'(occ_a) + 32'(occ_f);
  assign axi_read_bytes_o     = br_bytes;
  assign axi_read_bursts_o    = br_bursts;
  assign axi_read_beats_o     = br_beats;
  assign expected_records_o   = br_exp;
  assign received_records_o   = br_rcv;
  assign beat_mismatch_o      = br_mm;
endmodule
