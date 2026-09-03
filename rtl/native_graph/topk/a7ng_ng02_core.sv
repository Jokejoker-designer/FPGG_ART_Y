// a7ng_ng02_core.sv — PHYS physical scorer lanes; 16 scores in NBATCH batches
// LOCAL-MINHEAP-STREAM-TOP8-00: stream each batch into exact min-heap Top-8.
// GRAPH-PAYLOAD-NORESET-00: hold_id16/terms16, sc_hold_s/id, hold_s/id, beat_s/id
// have no reset. Authority (state,bidx,sidx,push_idx,beat_v) keeps async reset.
// Do not store all 16 scores and fire combinational a7ng_topk.
`timescale 1ns / 1ps

module a7ng_ng02_core #(
  parameter int unsigned PHYS = 4
) (
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
  output logic                       flow_busy_o,
  output logic [2:0]                 push_idx_o,
  output logic                       push_fire_o,
  output logic                       push_stall_o,
  output logic                       push_beat_valid_o,
  output a7ng_pkg::score_t           push_beat_score_o,
  output a7ng_pkg::node_id_t         push_beat_id_o,
  output logic [2:0]                 flow_state_o
);
  import a7ng_pkg::*;
  localparam int unsigned NBATCH = NG_LANES / PHYS;

  typedef enum logic [2:0] {
    ST_IDLE    = 3'd0,
    ST_FIRE    = 3'd1,
    ST_WAIT    = 3'd2,
    ST_STREAM  = 3'd3,
    ST_COLLECT = 3'd4,
    ST_COMMIT  = 3'd5,
    ST_PUSH    = 3'd6
  } flow_state_e;

  flow_state_e state, state_n;
  logic [2:0]  bidx;
  logic [2:0]  sidx;

  node_id_t      hold_id16    [NG_LANES];
  score_terms_t  hold_terms16 [NG_LANES];

  logic [PHYS-1:0] sc_valid_p;
  node_id_t        sc_id_p    [PHYS];
  score_t          sc_score_p [PHYS];
  logic [PHYS-1:0] sc_fire;
  node_id_t        sc_id_in   [PHYS];
  score_terms_t    sc_terms_in[PHYS];
  score_t          sc_hold_s  [PHYS];
  node_id_t        sc_hold_id [PHYS];

  logic input_hs;
  assign batch_ready_o = (state == ST_IDLE);
  assign input_hs      = batch_ready_o && (&lane_valid_i);

  integer ki;
  always_comb begin
    for (ki = 0; ki < int'(PHYS); ki++) begin
      sc_fire[ki]     = (state == ST_FIRE);
      sc_id_in[ki]    = hold_id16[int'(bidx) * int'(PHYS) + ki];
      sc_terms_in[ki] = hold_terms16[int'(bidx) * int'(PHYS) + ki];
    end
  end

  a7ng_scorer_array #(.PHYS(PHYS)) u_scorer (
    .clk(clk), .rst_n(rst_n),
    .valid_i(sc_fire),
    .cand_id_i(sc_id_in),
    .terms_i(sc_terms_in),
    .valid_o(sc_valid_p),
    .cand_id_o(sc_id_p),
    .score_o(sc_score_p)
  );

  logic                 heap_in_ready;
  logic                 heap_out_valid;
  logic                 heap_busy;
  logic                 heap_clr_ign;
  score_t               heap_out_s;
  node_id_t             heap_out_id;
  logic [2:0]           heap_out_idx;
  logic [31:0]          heap_acc, heap_ret, heap_drop;
  logic                 heap_in_valid;
  logic                 heap_in_last;
  logic [3:0]           heap_in_lane;

  assign heap_in_valid = (state == ST_STREAM);
  assign heap_in_last  = (bidx == 3'(NBATCH - 1)) && (sidx == 3'(PHYS - 1));
  assign heap_in_lane  = 4'(int'(bidx) * int'(PHYS) + int'(sidx));

  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0)) u_topk (
    .clk(clk), .rst_n(rst_n),
    .clear_i(input_hs),
    .in_valid_i(heap_in_valid),
    .in_ready_o(heap_in_ready),
    .in_v_i(1'b1),
    .in_s_i(sc_hold_s[sidx]),
    .in_id_i(sc_hold_id[sidx]),
    .in_lane_i(heap_in_lane),
    .in_last_i(heap_in_last),
    .out_valid_o(heap_out_valid),
    .out_ready_i(state == ST_COLLECT),
    .out_s_o(heap_out_s),
    .out_id_o(heap_out_id),
    .out_idx_o(heap_out_idx),
    .busy_o(heap_busy),
    .clear_ignored_o(heap_clr_ign),
    .accepted_count_o(heap_acc),
    .retired_count_o(heap_ret),
    .drop_count_o(heap_drop)
  );

  score_t   hold_s [8];
  node_id_t hold_id [8];
  logic [2:0] push_idx;
  logic       push_fire;
  logic       push_stall;
  logic       frontier_ready;
  integer     hi_c, hi_f;

  assign topk_valid_o = (state == ST_COMMIT);
  always_comb begin
    for (hi_c = 0; hi_c < 8; hi_c = hi_c + 1) begin
      topk_score_o[hi_c] = hold_s[hi_c];
      topk_id_o[hi_c]    = hold_id[hi_c];
    end
  end

  wire stream_hs  = (state == ST_STREAM) && heap_in_valid && heap_in_ready;
  wire collect_hs = (state == ST_COLLECT) && heap_out_valid;

  always_comb begin
    state_n = state;
    unique case (state)
      ST_IDLE:    if (input_hs) state_n = ST_FIRE;
      ST_FIRE:    state_n = ST_WAIT;
      ST_WAIT:    if (&sc_valid_p) state_n = ST_STREAM;
      ST_STREAM:  if (stream_hs && (sidx == 3'(PHYS - 1)))
                    state_n = (bidx == 3'(NBATCH - 1)) ? ST_COLLECT : ST_FIRE;
      ST_COLLECT: if (collect_hs && (heap_out_idx == 3'd7)) state_n = ST_COMMIT;
      ST_COMMIT:  state_n = ST_PUSH;
      ST_PUSH:    if (push_fire && (push_idx == 3'd7)) state_n = ST_IDLE;
      default:    state_n = ST_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= ST_IDLE;
      bidx     <= 3'd0;
      sidx     <= 3'd0;
      push_idx <= 3'd0;
    end else begin
      state <= state_n;

      if (input_hs) begin
        bidx <= 3'd0;
        sidx <= 3'd0;
      end

      if ((state == ST_WAIT) && (&sc_valid_p))
        sidx <= 3'd0;

      if (stream_hs) begin
        if (sidx != 3'(PHYS - 1))
          sidx <= sidx + 3'd1;
        else if (bidx != 3'(NBATCH - 1))
          bidx <= bidx + 3'd1;
      end

      if (collect_hs) begin
        if (heap_out_idx == 3'd7)
          push_idx <= 3'd0;
      end else if ((state == ST_PUSH) && push_fire) begin
        if (push_idx != 3'd7)
          push_idx <= push_idx + 3'd1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (input_hs) begin
      for (hi_f = 0; hi_f < int'(NG_LANES); hi_f = hi_f + 1) begin
        hold_id16[hi_f]    <= cand_id_i[hi_f];
        hold_terms16[hi_f] <= terms_i[hi_f];
      end
    end

    if ((state == ST_WAIT) && (&sc_valid_p)) begin
      for (hi_f = 0; hi_f < int'(PHYS); hi_f = hi_f + 1) begin
        sc_hold_s[hi_f]  <= sc_score_p[hi_f];
        sc_hold_id[hi_f] <= sc_id_p[hi_f];
      end
    end

    if (collect_hs) begin
      hold_s[heap_out_idx]  <= heap_out_s;
      hold_id[heap_out_idx] <= heap_out_id;
    end
  end

  logic push_req;
  assign push_req   = (state == ST_PUSH);
  assign push_stall = push_req && !frontier_ready;
  assign push_fire  = push_req && frontier_ready;

  logic [7:0] count_w;
  a7ng_frontier_buckets #(
    .NBINS(16), .DEPTH(8), .SCORE_W(16), .ID_W(32)
  ) u_frontier (
    .clk(clk), .rst_n(rst_n),
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

  logic       beat_v;
  score_t     beat_s;
  node_id_t   beat_id;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      beat_v <= 1'b0;
    else
      beat_v <= push_fire;
  end
  always_ff @(posedge clk) begin
    if (push_fire) begin
      beat_s  <= hold_s[push_idx];
      beat_id <= hold_id[push_idx];
    end
  end
  assign push_beat_valid_o = beat_v;
  assign push_beat_score_o = beat_s;
  assign push_beat_id_o    = beat_id;
  assign flow_state_o      = state;
endmodule
