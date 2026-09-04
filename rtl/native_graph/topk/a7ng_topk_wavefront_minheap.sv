// a7ng_topk_wavefront_minheap.sv — research rival to bitonic wavefront global Top-8
// Gate: GLOBAL-TOPK-MINHEAP-00  PROGRAM=NO
// Recurrence: G_0=empty; G_(t+1)=TopK(G_t ∪ TopK(W_t))
// Comparator: exact copy of a7ng_topk beats() (do not edit a7ng_topk.sv)
// Heap root = WORST retained. Ordered-commit: slot0=best .. slot7=eighth-best.
`timescale 1ns / 1ps

module a7ng_topk_wavefront_minheap #(
  parameter int unsigned K = 8,
  parameter int unsigned HEAP_CMP_LANES = 1
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       clear_i,
  input  logic                       wave_valid_i,
  input  logic [4:0]                 wave_scored_i,
  input  a7ng_pkg::score_t           wave_score_i [K],
  input  a7ng_pkg::node_id_t         wave_id_i    [K],
  output logic                       global_valid_o,
  output a7ng_pkg::score_t           global_score_o [K],
  output a7ng_pkg::node_id_t         global_id_o    [K],
  output logic                       busy_o,
  output logic [31:0]                merge_count_o,
  // GLOBAL-MERGE-DONE-SPLIT-00: completion token, independent of ordered
  // Top-8. This gate still pulses it in ST_COMMIT with global_valid_o
  // (cycle-equivalent). Do not assign merge_done_o = global_valid_o.
  output logic                       merge_done_o
);
  import a7ng_pkg::*;

  typedef struct packed {
    logic                  v;
    score_t                s;
    node_id_t              id;
    logic [3:0]            lane;
  } cand_t;

  // Strict "a is better than b" — identical to a7ng_topk.sv
  function automatic logic beats(cand_t a, cand_t b);
    if (a.v != b.v)
      return a.v;
    if (a.v) begin
      if (a.s != b.s)
        return a.s > b.s;
      if (a.id != b.id)
        return a.id < b.id;
      return a.lane < b.lane;
    end else begin
      if (a.id != b.id)
        return a.id < b.id;
      return a.lane < b.lane;
    end
  endfunction

  typedef enum logic [2:0] {
    ST_IDLE    = 3'd0,
    ST_CAND    = 3'd1,
    ST_HEAPIFY = 3'd2,
    ST_NEXT    = 3'd3,
    ST_SORT    = 3'd4,
    ST_COMMIT  = 3'd5
  } st_t;

  typedef enum logic [1:0] { HF_NONE = 2'd0, HF_UP = 2'd1, HF_DOWN = 2'd2 } hf_t;

  st_t st;
  hf_t hf_dir;
  logic [3:0] hf_idx;
  logic [3:0] wave_i;
  logic [4:0] wave_n;
  score_t     w_s [K];
  node_id_t   w_id [K];
  cand_t      h [K];
  logic [2:0] ord [K];
  logic [2:0] sort_pass;
  logic [2:0] sort_j;
  logic [31:0] merges;
  integer gi;

  function automatic logic [3:0] first_empty();
    integer e;
    first_empty = 4'd8;
    for (e = 0; e < K; e = e + 1)
      if (!h[e].v && first_empty == 4'd8)
        first_empty = 4'(e);
  endfunction

  assign busy_o        = (st != ST_IDLE);
  assign merge_count_o = merges;

  integer oi;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st             <= ST_IDLE;
      hf_dir         <= HF_NONE;
      hf_idx         <= 4'd0;
      wave_i         <= 4'd0;
      wave_n         <= 5'd0;
      sort_pass      <= 3'd0;
      sort_j         <= 3'd0;
      merges         <= 32'd0;
      global_valid_o <= 1'b0;
      merge_done_o   <= 1'b0;
      for (gi = 0; gi < K; gi = gi + 1) begin
        h[gi]              <= '0;
        ord[gi]            <= 3'(gi);
        w_s[gi]            <= '0;
        w_id[gi]           <= '0;
        global_score_o[gi] <= '0;
        global_id_o[gi]    <= '0;
      end
    end else begin
      global_valid_o <= 1'b0;
      merge_done_o   <= 1'b0;
      if (clear_i) begin
        st             <= ST_IDLE;
        hf_dir         <= HF_NONE;
        merges         <= 32'd0;
        wave_i         <= 4'd0;
        wave_n         <= 5'd0;
        for (gi = 0; gi < K; gi = gi + 1) begin
          h[gi]              <= '0;
          global_score_o[gi] <= '0;
          global_id_o[gi]    <= '0;
        end
      end else unique case (st)
        ST_IDLE: begin
          if (wave_valid_i) begin
            wave_n <= (wave_scored_i > K) ? 5'(K) : wave_scored_i;
            wave_i <= 4'd0;
            for (gi = 0; gi < K; gi = gi + 1) begin
              w_s[gi]  <= wave_score_i[gi];
              w_id[gi] <= wave_id_i[gi];
            end
            st <= ST_CAND;
          end
        end

        ST_CAND: begin
          if (wave_n == 5'd0) begin
            st <= ST_SORT;
            sort_pass <= 3'd0;
            sort_j    <= 3'd0;
            for (gi = 0; gi < K; gi = gi + 1)
              ord[gi] <= 3'(gi);
          end else begin
            // Incoming wave slot i uses lane=8+i (frozen 16-slot map)
            cand_t c;
            logic [3:0] emp;
            c.v    = 1'b1;
            c.s    = w_s[wave_i];
            c.id   = w_id[wave_i];
            c.lane = 4'(8 + wave_i);
            emp    = first_empty();
            if (emp != 4'd8) begin
              h[emp]  <= c;
              hf_idx  <= emp;
              hf_dir  <= (emp == 4'd0) ? HF_NONE : HF_UP;
              st      <= (emp == 4'd0) ? ST_NEXT : ST_HEAPIFY;
            end else if (beats(c, h[0])) begin
              h[0]   <= c;
              hf_idx <= 4'd0;
              hf_dir <= HF_DOWN;
              st     <= ST_HEAPIFY;
            end else begin
              st <= ST_NEXT;
            end
          end
        end

        ST_HEAPIFY: begin
          if (hf_dir == HF_UP) begin
            if (hf_idx != 4'd0) begin
              logic [3:0] p;
              p = 4'((hf_idx - 4'd1) >> 1);
              if (beats(h[p], h[hf_idx])) begin
                cand_t tmp;
                tmp        = h[p];
                h[p]       <= h[hf_idx];
                h[hf_idx]  <= tmp;
                hf_idx     <= p;
              end else begin
                hf_dir <= HF_NONE;
                st     <= ST_NEXT;
              end
            end else begin
              hf_dir <= HF_NONE;
              st     <= ST_NEXT;
            end
          end else if (hf_dir == HF_DOWN) begin
            logic [4:0] l, r, w;
            l = 5'({hf_idx, 1'b0}) + 5'd1;
            r = l + 5'd1;
            w = {1'b0, hf_idx};
            if (l < K && beats(h[w[3:0]], h[l[3:0]]))
              w = l;
            if (r < K && beats(h[w[3:0]], h[r[3:0]]))
              w = r;
            if (w[3:0] != hf_idx) begin
              cand_t tmp;
              tmp              = h[hf_idx];
              h[hf_idx]        <= h[w[3:0]];
              h[w[3:0]]        <= tmp;
              hf_idx           <= w[3:0];
            end else begin
              hf_dir <= HF_NONE;
              st     <= ST_NEXT;
            end
          end else begin
            st <= ST_NEXT;
          end
        end

        ST_NEXT: begin
          if ({1'b0, wave_i} + 5'd1 >= wave_n) begin
            for (gi = 0; gi < K; gi = gi + 1)
              ord[gi] <= 3'(gi);
            sort_pass <= 3'd0;
            sort_j    <= 3'd0;
            st        <= ST_SORT;
          end else begin
            wave_i <= wave_i + 4'd1;
            st     <= ST_CAND;
          end
        end

        ST_SORT: begin
          // TOPK-SORT-BOUND-00: triangular bubble on ord[] only.
          // beats(right,left) swap ⇒ worse moves right; sorted suffix grows
          // at the right. Pass p compares j=0 .. K-2-p.
          // Heap h[] is not permuted. beats() unchanged.
          if (sort_j <= (3'(K-2) - sort_pass)) begin
            if (beats(h[ord[sort_j+1]], h[ord[sort_j]])) begin
              logic [2:0] tmpi;
              tmpi              = ord[sort_j];
              ord[sort_j]       <= ord[sort_j+1];
              ord[sort_j+1]     <= tmpi;
            end
            if (sort_j == (3'(K-2) - sort_pass)) begin
              if (sort_pass >= 3'(K-2))
                st <= ST_COMMIT;
              else begin
                sort_pass <= sort_pass + 3'd1;
                sort_j    <= 3'd0;
              end
            end else begin
              sort_j <= sort_j + 3'd1;
            end
          end else begin
            st <= ST_COMMIT;
          end
        end

        ST_COMMIT: begin
          for (oi = 0; oi < K; oi = oi + 1) begin
            global_score_o[oi] <= h[ord[oi]].s;
            global_id_o[oi]    <= h[ord[oi]].id;
          end
          global_valid_o <= 1'b1;
          merge_done_o   <= 1'b1;
          merges         <= merges + 32'd1;
          st             <= ST_IDLE;
        end

        default: st <= ST_IDLE;
      endcase
    end
  end

endmodule
