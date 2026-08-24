// a7ng_ng02_core.sv — 16-lane scorer → Top-K → bucket frontier (NG-02R-FLOW)
// Law: a7ng-topk-global-v1 intact; flow law: one in-flight Top-8→frontier push.
// Backpressure: batch_ready_o low from input accept until all 8 winners pushed
// (or intentionally overflow-pruned). New batch cannot overwrite hold.
`timescale 1ns / 1ps

module a7ng_ng02_core (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic [a7ng_pkg::NG_LANES-1:0] lane_valid_i,
  input  a7ng_pkg::node_id_t         cand_id_i [a7ng_pkg::NG_LANES],
  input  a7ng_pkg::score_terms_t     terms_i   [a7ng_pkg::NG_LANES],
  input  logic                       frontier_pop_i,
  output logic                       batch_ready_o,
  output logic                       topk_valid_o,
  output a7ng_pkg::score_t           topk_score_o [8],
  output a7ng_pkg::node_id_t         topk_id_o    [8],
  output logic                       frontier_pop_valid_o,
  output a7ng_pkg::score_t           frontier_score_o,
  output a7ng_pkg::node_id_t         frontier_id_o,
  output logic                       frontier_overflow_o,
  output logic [7:0]                 frontier_count_o,
  // NG-02R-FLOW telemetry (conservation / stall)
  output logic                       flow_busy_o,
  output logic [2:0]                 push_idx_o,
  output logic                       push_fire_o,
  output logic                       push_stall_o,
  output logic                       push_beat_valid_o,
  output a7ng_pkg::score_t           push_beat_score_o,
  output a7ng_pkg::node_id_t         push_beat_id_o,
  output logic [1:0]                 flow_state_o
);
  import a7ng_pkg::*;

  // ---- FSM: IDLE → WAIT_SCORE → WAIT_TOPK → PUSH ----
  typedef enum logic [1:0] {
    ST_IDLE       = 2'd0,
    ST_WAIT_SCORE = 2'd1,
    ST_WAIT_TOPK  = 2'd2,
    ST_PUSH       = 2'd3
  } flow_state_e;

  flow_state_e state, state_n;

  logic [NG_LANES-1:0] sc_valid;
  node_id_t sc_id   [NG_LANES];
  score_t   sc_score[NG_LANES];

  // Input handshake: all 16 lanes valid while ready (IDLE)
  logic input_hs;
  assign batch_ready_o = (state == ST_IDLE);
  assign input_hs      = batch_ready_o && (&lane_valid_i);

  // Gate scorer inputs so a non-ready concurrent batch cannot enter the pipe
  logic [NG_LANES-1:0] lane_valid_gated;
  assign lane_valid_gated = input_hs ? lane_valid_i : '0;

  a7ng_scorer_array u_scorer (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(lane_valid_gated),
    .cand_id_i(cand_id_i),
    .terms_i(terms_i),
    .valid_o(sc_valid),
    .cand_id_o(sc_id),
    .score_o(sc_score)
  );

  // Single Top-K fire per accepted batch (no &sc_valid spam)
  logic topk_fire;
  assign topk_fire = (state == ST_WAIT_SCORE) && (&sc_valid);

  a7ng_topk u_topk (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(topk_fire),
    .valid_mask_i({NG_LANES{1'b1}}),
    .score_i(sc_score),
    .id_i(sc_id),
    .valid_o(topk_valid_o),
    .score_o(topk_score_o),
    .id_o(topk_id_o)
  );

  score_t   hold_s [8];
  node_id_t hold_id [8];
  logic [2:0] push_idx;
  logic       push_fire;
  logic       push_stall;
  logic       frontier_ready;
  integer     hi;

  always_comb begin
    state_n = state;
    unique case (state)
      ST_IDLE: begin
        if (input_hs)
          state_n = ST_WAIT_SCORE;
      end
      ST_WAIT_SCORE: begin
        if (topk_fire)
          state_n = ST_WAIT_TOPK;
      end
      ST_WAIT_TOPK: begin
        if (topk_valid_o)
          state_n = ST_PUSH;
      end
      ST_PUSH: begin
        // Leave after last winner accepted or intentionally overflow-pruned
        if (push_fire && (push_idx == 3'd7))
          state_n = ST_IDLE;
      end
      default: state_n = ST_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= ST_IDLE;
      push_idx <= 3'd0;
      for (hi = 0; hi < 8; hi = hi + 1) begin
        hold_s[hi]  <= '0;
        hold_id[hi] <= '0;
      end
    end else begin
      state <= state_n;

      // Capture Top-8 once; never reload while PUSH (no overwrite)
      if ((state == ST_WAIT_TOPK) && topk_valid_o) begin
        push_idx <= 3'd0;
        for (hi = 0; hi < 8; hi = hi + 1) begin
          hold_s[hi]  <= topk_score_o[hi];
          hold_id[hi] <= topk_id_o[hi];
        end
      end else if ((state == ST_PUSH) && push_fire) begin
        if (push_idx != 3'd7)
          push_idx <= push_idx + 3'd1;
      end
    end
  end

  // Push request while in ST_PUSH; stall when selected bin cannot accept
  logic push_req;
  assign push_req   = (state == ST_PUSH);
  assign push_stall = push_req && !frontier_ready;
  // Attempt push every PUSH cycle; frontier ready stalls acceptance.
  // If ready=0 we do not advance idx. Overflow path: force push when
  // ready=0 would deadlock without pop — TB pops; production may later
  // intentional-overflow. Here: only fire when ready (lossless stall).
  assign push_fire  = push_req && frontier_ready;

  logic [7:0] count_w;
  a7ng_frontier_buckets #(
    .NBINS(16),
    .DEPTH(8),
    .SCORE_W(16),
    .ID_W(32)
  ) u_frontier (
    .clk(clk),
    .rst_n(rst_n),
    .push_i(push_fire),
    .score_i(hold_s[push_idx]),
    .id_i(hold_id[push_idx]),
    .pop_i(frontier_pop_i),
    .pop_valid_o(frontier_pop_valid_o),
    .score_o(frontier_score_o),
    .id_o(frontier_id_o),
    .overflow_o(frontier_overflow_o),
    .ready_o(frontier_ready),
    .count_o(count_w)
  );
  assign frontier_count_o = count_w;

  assign flow_busy_o  = (state != ST_IDLE);
  assign push_idx_o   = push_idx;
  assign push_fire_o  = push_fire;
  assign push_stall_o = push_stall;

  // Registered beat for TB (avoids push_idx NBA race)
  logic       beat_v;
  score_t     beat_s;
  node_id_t   beat_id;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      beat_v  <= 1'b0;
      beat_s  <= '0;
      beat_id <= '0;
    end else begin
      beat_v <= push_fire;
      if (push_fire) begin
        beat_s  <= hold_s[push_idx];
        beat_id <= hold_id[push_idx];
      end
    end
  end
  assign push_beat_valid_o = beat_v;
  assign push_beat_score_o = beat_s;
  assign push_beat_id_o    = beat_id;
  assign flow_state_o      = state;
endmodule
