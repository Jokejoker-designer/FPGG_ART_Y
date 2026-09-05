// a7ng_topk_stream_minheap.sv — LOCAL-MINHEAP-STREAM-TOP8-00
// Exact streaming Top-8. Comparator copied from frozen a7ng_topk.sv. Do not edit a7ng_topk.
// Root = worst retained. Ordered drain slot0=best. PROGRAM=NO. LABEL=MINHEAP not SERIAL.
// Occupancy is fill_n, not !v: invalids are real candidates (underfill pad).
// GRAPH-PAYLOAD-NORESET-00: h[].{v,s,id,lane} and out_s/out_id have no reset.
// fill_n gates occupancy; do not zero h[] on reset/clear/drain.
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module a7ng_topk_stream_minheap #(
  parameter int unsigned K = 8,
  // LOCAL-SORT-ELIDE-00: 1 = ST_SORT then ordered drain (C9 default).
  // 0 = drain heap-array order after last TAKE. K-set unchanged.
  // Global re-sorts; order-contract PASS. Do not change beats()/heap.
  parameter bit SORT_BEFORE_DRAIN = 1'b1,
  // HEAP-TAKE-SIFT-00: 1 = full K=8 sift-up/sift-down in the TAKE cycle.
  // 0 = multi-cycle ST_HEAPIFY (C9 default). beats() unchanged.
  parameter bit SIFT_ON_TAKE = 1'b0,
  // LOCAL-TOPK-PARALLEL-COMMIT-00: 1 = one-cycle ordered_* vector, skip ST_DRAIN.
  // 0 = serial out_valid/out_s/out_id (C9 / generic default).
  parameter bit VECTOR_COMMIT = 1'b0
) (
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    clear_i,
  input  logic                    in_valid_i,
  output logic                    in_ready_o,
  input  logic                    in_v_i,
  input  a7ng_pkg::score_t        in_s_i,
  input  a7ng_pkg::node_id_t      in_id_i,
  input  logic [3:0]              in_lane_i,
  input  logic                    in_last_i,
  output logic                    out_valid_o,
  input  logic                    out_ready_i,
  output a7ng_pkg::score_t        out_s_o,
  output a7ng_pkg::node_id_t      out_id_o,
  output logic [2:0]              out_idx_o,
  output logic                    ordered_valid_o,
  input  logic                    ordered_ready_i = 1'b1,
  output a7ng_pkg::score_t        ordered_score_o [K],
  output a7ng_pkg::node_id_t      ordered_id_o    [K],
  output logic                    busy_o,
  output logic                    clear_ignored_o,
  output logic [31:0]             accepted_count_o,
  output logic [31:0]             retired_count_o,
  output logic [31:0]             drop_count_o
);
  import a7ng_pkg::*;

  typedef struct packed {
    logic       v;
    score_t     s;
    node_id_t   id;
    logic [3:0] lane;
  } cand_t;

  // Strict "a is better than b" — identical to frozen a7ng_topk.sv
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
    ST_TAKE    = 3'd0,
    ST_HEAPIFY = 3'd1,
    ST_SORT    = 3'd2,
    ST_DRAIN   = 3'd3,
    ST_VEC     = 3'd4
  } st_t;
  typedef enum logic [1:0] { HF_NONE = 2'd0, HF_UP = 2'd1, HF_DOWN = 2'd2 } hf_t;

  st_t          st;
  hf_t          hf_dir;
  logic [3:0]   hf_idx;
  logic [3:0]   fill_n;
  cand_t        h [K];
  logic [2:0]   ord [K];
  logic [2:0]   sort_pass, sort_j, drain_i;
  logic         last_q;
  integer       gi;

  task automatic enter_emit;
    integer ei;
    begin
      for (ei = 0; ei < K; ei = ei + 1)
        ord[ei] <= 3'(ei);
      drain_i   <= 3'd0;
      sort_pass <= 3'd0;
      sort_j    <= 3'd0;
      if (SORT_BEFORE_DRAIN)
        st <= ST_SORT;
      else if (VECTOR_COMMIT)
        st <= ST_VEC;
      else
        st <= ST_DRAIN;
    end
  endtask

  // Combinational 3-level sift (K=8, depth<=3). Uses pre-NBA h[] / fill_n.
  // do_fill=1: insert at fill_n and sift-up. do_fill=0: replace root and sift-down.
  task automatic write_sifted;
    input cand_t c;
    input logic  do_fill;
    integer      i, step;
    cand_t       nh [K];
    cand_t       tmp;
    logic [3:0]  idx, p;
    logic [4:0]  l, r, w;
    logic        cont;
    begin
      for (i = 0; i < K; i = i + 1)
        nh[i] = h[i];
      if (do_fill) begin
        idx = fill_n;
        nh[idx] = c;
        cont = (idx != 4'd0);
        for (step = 0; step < 3; step = step + 1) begin
          if (cont) begin
            p = 4'((idx - 4'd1) >> 1);
            if (beats(nh[p], nh[idx])) begin
              tmp     = nh[p];
              nh[p]   = nh[idx];
              nh[idx] = tmp;
              idx     = p;
              cont    = (idx != 4'd0);
            end else
              cont = 1'b0;
          end
        end
      end else begin
        nh[0] = c;
        idx   = 4'd0;
        cont  = 1'b1;
        for (step = 0; step < 3; step = step + 1) begin
          if (cont) begin
            l = 5'({idx, 1'b0}) + 5'd1;
            r = l + 5'd1;
            w = {1'b0, idx};
            if (l < K && beats(nh[w[3:0]], nh[l[3:0]]))
              w = l;
            if (r < K && beats(nh[w[3:0]], nh[r[3:0]]))
              w = r;
            if (w[3:0] != idx) begin
              tmp        = nh[idx];
              nh[idx]    = nh[w[3:0]];
              nh[w[3:0]] = tmp;
              idx        = w[3:0];
            end else
              cont = 1'b0;
          end
        end
      end
      for (i = 0; i < K; i = i + 1)
        h[i] <= nh[i];
    end
  endtask

  wire idle_clear_ok = (st == ST_TAKE) && (fill_n == 4'd0) && !out_valid_o && !in_valid_i;

  assign busy_o       = (st != ST_TAKE) || (fill_n != 4'd0) || out_valid_o;
  assign in_ready_o   = (st == ST_TAKE);
  assign drop_count_o = 32'd0;
  assign ordered_valid_o = (st == ST_VEC);

  integer voi;
  always_comb begin
    for (voi = 0; voi < K; voi = voi + 1) begin
      ordered_score_o[voi] = h[ord[voi]].s;
      ordered_id_o[voi]    = h[ord[voi]].id;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st               <= ST_TAKE;
      hf_dir           <= HF_NONE;
      hf_idx           <= 4'd0;
      fill_n           <= 4'd0;
      sort_pass        <= 3'd0;
      sort_j           <= 3'd0;
      drain_i          <= 3'd0;
      last_q           <= 1'b0;
      out_valid_o      <= 1'b0;
      out_idx_o        <= 3'd0;
      clear_ignored_o  <= 1'b0;
      accepted_count_o <= 32'd0;
      retired_count_o  <= 32'd0;
      for (gi = 0; gi < K; gi = gi + 1)
        ord[gi] <= 3'(gi);
    end else begin
      clear_ignored_o <= 1'b0;

      if (clear_i && idle_clear_ok) begin
        st               <= ST_TAKE;
        hf_dir           <= HF_NONE;
        hf_idx           <= 4'd0;
        fill_n           <= 4'd0;
        last_q           <= 1'b0;
        out_valid_o      <= 1'b0;
        accepted_count_o <= 32'd0;
        retired_count_o  <= 32'd0;
        for (gi = 0; gi < K; gi = gi + 1)
          ord[gi] <= 3'(gi);
      end else begin
        if (clear_i)
          clear_ignored_o <= 1'b1;

        case (st)
          ST_TAKE: begin
            if (in_valid_i && in_ready_o) begin
              accepted_count_o <= accepted_count_o + 32'd1;
              last_q           <= in_last_i;
              if (fill_n < 4'(K)) begin
                hf_idx <= fill_n;
                fill_n <= fill_n + 4'd1;
                if ((fill_n == 4'd0) || SIFT_ON_TAKE) begin
                  hf_dir          <= HF_NONE;
                  retired_count_o <= retired_count_o + 32'd1;
                  if (in_last_i) begin
                    enter_emit;
                  end
                end else begin
                  hf_dir <= HF_UP;
                  st     <= ST_HEAPIFY;
                end
              end else if (beats({in_v_i, in_s_i, in_id_i, in_lane_i}, h[0])) begin
                if (SIFT_ON_TAKE) begin
                  hf_dir          <= HF_NONE;
                  retired_count_o <= retired_count_o + 32'd1;
                  if (in_last_i) begin
                    enter_emit;
                  end
                end else begin
                  hf_idx <= 4'd0;
                  hf_dir <= HF_DOWN;
                  st     <= ST_HEAPIFY;
                end
              end else begin
                retired_count_o <= retired_count_o + 32'd1;
                if (in_last_i) begin
                  enter_emit;
                end
              end
            end
          end

          ST_HEAPIFY: begin
            if (hf_dir == HF_UP) begin
              if (hf_idx != 4'd0) begin
                logic [3:0] p;
                p = 4'((hf_idx - 4'd1) >> 1);
                if (beats(h[p], h[hf_idx])) begin
                  hf_idx <= p;
                end else begin
                  hf_dir          <= HF_NONE;
                  retired_count_o <= retired_count_o + 32'd1;
                  if (last_q) begin
                    enter_emit;
                  end else
                    st <= ST_TAKE;
                end
              end else begin
                hf_dir          <= HF_NONE;
                retired_count_o <= retired_count_o + 32'd1;
                if (last_q) begin
                  enter_emit;
                end else
                  st <= ST_TAKE;
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
                hf_idx <= w[3:0];
              end else begin
                hf_dir          <= HF_NONE;
                retired_count_o <= retired_count_o + 32'd1;
                if (last_q) begin
                  enter_emit;
                end else
                  st <= ST_TAKE;
              end
            end else begin
              retired_count_o <= retired_count_o + 32'd1;
              if (last_q) begin
                enter_emit;
              end else
                st <= ST_TAKE;
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
                tmpi          = ord[sort_j];
                ord[sort_j]   <= ord[sort_j+1];
                ord[sort_j+1] <= tmpi;
              end
              if (sort_j == (3'(K-2) - sort_pass)) begin
                if (sort_pass >= 3'(K-2)) begin
                  drain_i <= 3'd0;
                  if (VECTOR_COMMIT)
                    st <= ST_VEC;
                  else
                    st <= ST_DRAIN;
                end else begin
                  sort_pass <= sort_pass + 3'd1;
                  sort_j    <= 3'd0;
                end
              end else begin
                sort_j <= sort_j + 3'd1;
              end
            end else begin
              drain_i <= 3'd0;
              if (VECTOR_COMMIT)
                st <= ST_VEC;
              else
                st <= ST_DRAIN;
            end
          end

          ST_VEC: begin
            if (ordered_ready_i) begin
              fill_n <= 4'd0;
              last_q <= 1'b0;
              for (gi = 0; gi < K; gi = gi + 1)
                ord[gi] <= 3'(gi);
              st <= ST_TAKE;
            end
          end

          ST_DRAIN: begin
            if (!out_valid_o) begin
              out_valid_o <= 1'b1;
              out_idx_o   <= drain_i;
            end else if (out_ready_i) begin
              if (drain_i == 3'(K-1)) begin
                out_valid_o <= 1'b0;
                fill_n      <= 4'd0;
                last_q      <= 1'b0;
                for (gi = 0; gi < K; gi = gi + 1)
                  ord[gi] <= 3'(gi);
                st <= ST_TAKE;
              end else begin
                drain_i   <= drain_i + 3'd1;
                out_idx_o <= drain_i + 3'd1;
              end
            end
          end

          default: st <= ST_TAKE;
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!(clear_i && idle_clear_ok)) begin
      case (st)
        ST_TAKE: begin
          if (in_valid_i && in_ready_o) begin
            cand_t c;
            c.v    = in_v_i;
            c.s    = in_s_i;
            c.id   = in_id_i;
            c.lane = in_lane_i;
            if (fill_n < 4'(K)) begin
              if (SIFT_ON_TAKE)
                write_sifted(c, 1'b1);
              else
                h[fill_n] <= c;
            end else if (beats(c, h[0])) begin
              if (SIFT_ON_TAKE)
                write_sifted(c, 1'b0);
              else
                h[0] <= c;
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
                tmp       = h[p];
                h[p]      <= h[hf_idx];
                h[hf_idx] <= tmp;
              end
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
              tmp       = h[hf_idx];
              h[hf_idx] <= h[w[3:0]];
              h[w[3:0]] <= tmp;
            end
          end
        end

        ST_DRAIN: begin
          if (!out_valid_o) begin
            out_s_o  <= h[ord[drain_i]].s;
            out_id_o <= h[ord[drain_i]].id;
          end else if (out_ready_i) begin
            if (drain_i != 3'(K-1)) begin
              out_s_o  <= h[ord[drain_i + 3'd1]].s;
              out_id_o <= h[ord[drain_i + 3'd1]].id;
            end
          end
        end

        default: ;
      endcase
    end
  end
endmodule
