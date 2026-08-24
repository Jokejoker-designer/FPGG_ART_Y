// a7ng_wm00_evidence.sv — A7-BRAM-WM-00 exact Top-8 evidence (global, ordered)
// Law: a7ng-bram-wm00-v0. Tie: higher score, then lower node_id.
// Timing (wm00_timing): ONE unknown = systolic pipeline insert (1 dedupe + K shift
// stages). Same exact Top-8 semantics as prior single-cycle selection-sort;
// ready_o low while busy. Synth-safe fixed loops / one compare per cycle.
`timescale 1ns / 1ps

module a7ng_wm00_evidence #(
  parameter int unsigned K = 8
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] active_query_epoch_i,
  input  logic        insert_i,
  input  logic [31:0] node_id_i,
  input  logic [31:0] subject_i,
  input  logic [15:0] relation_i,
  input  logic [31:0] object_i,
  input  logic [31:0] episode_i,
  input  logic signed [15:0] score_i,
  input  logic [15:0] conf_i,
  input  logic [7:0]  path_depth_i,
  output logic        ready_o,
  output logic [K-1:0] valid_mask_o,
  output logic [31:0]  node_o [K],
  output logic signed [15:0] score_o [K],
  output logic [15:0]  count_o,
  input  logic         clear_i
);
  typedef struct packed {
    logic               v;
    logic [15:0]        qepoch;
    logic [31:0]        node;
    logic [31:0]        subject;
    logic [15:0]        rel;
    logic [31:0]        object;
    logic [31:0]        episode;
    logic signed [15:0] score;
    logic [15:0]        conf;
    logic [7:0]         depth;
  } ev_t;

  typedef enum logic [1:0] {
    ST_IDLE   = 2'd0,
    ST_DEDUPE = 2'd1,
    ST_SHIFT  = 2'd2
  } st_t;

  ev_t slot [K];
  st_t st;
  ev_t bubble;
  logic [$clog2(K+1)-1:0] sh_idx;

  function automatic logic beats(ev_t a, ev_t b);
    if (a.v != b.v) return a.v;
    if (!a.v) return 1'b0;
    if (a.score != b.score) return a.score > b.score;
    return a.node < b.node;
  endfunction

  assign ready_o = (st == ST_IDLE);

  logic [15:0] cnt;
  always_comb begin
    cnt = 16'd0;
    for (int i = 0; i < K; i++)
      if (slot[i].v && (slot[i].qepoch == active_query_epoch_i))
        cnt = cnt + 16'd1;
  end
  assign count_o = cnt;

  always_comb begin
    for (int i = 0; i < K; i++) begin
      valid_mask_o[i] = slot[i].v && (slot[i].qepoch == active_query_epoch_i);
      node_o[i]  = slot[i].node;
      score_o[i] = slot[i].score;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE;
      bubble <= '0;
      sh_idx <= '0;
      for (int i = 0; i < K; i++) slot[i] <= '0;
    end else if (clear_i) begin
      st <= ST_IDLE;
      bubble <= '0;
      sh_idx <= '0;
      for (int i = 0; i < K; i++) slot[i] <= '0;
    end else begin
      unique case (st)
        ST_IDLE: begin
          if (insert_i) begin
            bubble.v       <= 1'b1;
            bubble.qepoch  <= active_query_epoch_i;
            bubble.node    <= node_id_i;
            bubble.subject <= subject_i;
            bubble.rel     <= relation_i;
            bubble.object  <= object_i;
            bubble.episode <= episode_i;
            bubble.score   <= score_i;
            bubble.conf    <= conf_i;
            bubble.depth   <= path_depth_i;
            st             <= ST_DEDUPE;
            sh_idx         <= '0;
          end
        end
        ST_DEDUPE: begin
          // Invalidate any existing entry with the same node_id (exact prior law).
          for (int i = 0; i < K; i++) begin
            if (slot[i].v && (slot[i].node == bubble.node))
              slot[i].v <= 1'b0;
          end
          sh_idx <= '0;
          st     <= ST_SHIFT;
        end
        ST_SHIFT: begin
          // One compare/swap per cycle: maintain descending rank order.
          if (beats(bubble, slot[sh_idx])) begin
            slot[sh_idx] <= bubble;
            bubble       <= slot[sh_idx];
          end
          if (sh_idx >= $clog2(K+1)'(K - 1)) begin
            st     <= ST_IDLE;
            sh_idx <= '0;
            bubble <= '0;
          end else begin
            sh_idx <= sh_idx + 1'b1;
          end
        end
        default: st <= ST_IDLE;
      endcase
    end
  end
endmodule
