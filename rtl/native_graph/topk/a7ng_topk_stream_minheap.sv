// a7ng_topk_stream_minheap.sv — LOCAL-MINHEAP-STREAM-TOP8-00
// Exact streaming Top-8. Comparator copied from frozen a7ng_topk.sv. Do not edit a7ng_topk.
// Root = worst retained. Ordered drain slot0=best. PROGRAM=NO. LABEL=MINHEAP not SERIAL.
// Occupancy is fill_n, not !v: invalids are real candidates (underfill pad).
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module a7ng_topk_stream_minheap #(
  parameter int unsigned K = 8
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
    ST_DRAIN   = 3'd3
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

  wire idle_clear_ok = (st == ST_TAKE) && (fill_n == 4'd0) && !out_valid_o && !in_valid_i;

  assign busy_o       = (st != ST_TAKE) || (fill_n != 4'd0) || out_valid_o;
  assign in_ready_o   = (st == ST_TAKE);
  assign drop_count_o = 32'd0;

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
      out_s_o          <= '0;
      out_id_o         <= '0;
      out_idx_o        <= 3'd0;
      clear_ignored_o  <= 1'b0;
      accepted_count_o <= 32'd0;
      retired_count_o  <= 32'd0;
      for (gi = 0; gi < K; gi = gi + 1) begin
        h[gi]   <= '0;
        ord[gi] <= 3'(gi);
      end
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
        for (gi = 0; gi < K; gi = gi + 1) begin
          h[gi]   <= '0;
          ord[gi] <= 3'(gi);
        end
      end else begin
        if (clear_i)
          clear_ignored_o <= 1'b1;

        case (st)
          ST_TAKE: begin
            if (in_valid_i && in_ready_o) begin
              cand_t c;
              accepted_count_o <= accepted_count_o + 32'd1;
              last_q           <= in_last_i;
              c.v              = in_v_i;
              c.s              = in_s_i;
              c.id             = in_id_i;
              c.lane           = in_lane_i;
              if (fill_n < 4'(K)) begin
                h[fill_n] <= c;
                hf_idx    <= fill_n;
                fill_n    <= fill_n + 4'd1;
                if (fill_n == 4'd0) begin
                  hf_dir          <= HF_NONE;
                  retired_count_o <= retired_count_o + 32'd1;
                  if (in_last_i) begin
                    sort_pass <= 3'd0;
                    sort_j    <= 3'd0;
                    for (gi = 0; gi < K; gi = gi + 1)
                      ord[gi] <= 3'(gi);
                    st <= ST_SORT;
                  end
                end else begin
                  hf_dir <= HF_UP;
                  st     <= ST_HEAPIFY;
                end
              end else if (beats(c, h[0])) begin
                h[0]   <= c;
                hf_idx <= 4'd0;
                hf_dir <= HF_DOWN;
                st     <= ST_HEAPIFY;
              end else begin
                retired_count_o <= retired_count_o + 32'd1;
                if (in_last_i) begin
                  sort_pass <= 3'd0;
                  sort_j    <= 3'd0;
                  for (gi = 0; gi < K; gi = gi + 1)
                    ord[gi] <= 3'(gi);
                  st <= ST_SORT;
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
                  cand_t tmp;
                  tmp       = h[p];
                  h[p]      <= h[hf_idx];
                  h[hf_idx] <= tmp;
                  hf_idx    <= p;
                end else begin
                  hf_dir          <= HF_NONE;
                  retired_count_o <= retired_count_o + 32'd1;
                  if (last_q) begin
                    sort_pass <= 3'd0;
                    sort_j    <= 3'd0;
                    for (gi = 0; gi < K; gi = gi + 1)
                      ord[gi] <= 3'(gi);
                    st <= ST_SORT;
                  end else
                    st <= ST_TAKE;
                end
              end else begin
                hf_dir          <= HF_NONE;
                retired_count_o <= retired_count_o + 32'd1;
                if (last_q) begin
                  sort_pass <= 3'd0;
                  sort_j    <= 3'd0;
                  for (gi = 0; gi < K; gi = gi + 1)
                    ord[gi] <= 3'(gi);
                  st <= ST_SORT;
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
                cand_t tmp;
                tmp       = h[hf_idx];
                h[hf_idx] <= h[w[3:0]];
                h[w[3:0]] <= tmp;
                hf_idx    <= w[3:0];
              end else begin
                hf_dir          <= HF_NONE;
                retired_count_o <= retired_count_o + 32'd1;
                if (last_q) begin
                  sort_pass <= 3'd0;
                  sort_j    <= 3'd0;
                  for (gi = 0; gi < K; gi = gi + 1)
                    ord[gi] <= 3'(gi);
                  st <= ST_SORT;
                end else
                  st <= ST_TAKE;
              end
            end else begin
              retired_count_o <= retired_count_o + 32'd1;
              if (last_q) begin
                sort_pass <= 3'd0;
                sort_j    <= 3'd0;
                for (gi = 0; gi < K; gi = gi + 1)
                  ord[gi] <= 3'(gi);
                st <= ST_SORT;
              end else
                st <= ST_TAKE;
            end
          end

          ST_SORT: begin
            // Permute ord[] only. Heap h[] stays a min-heap. Best bubbles to ord[0].
            if (sort_j < 3'(K-1)) begin
              if (beats(h[ord[sort_j+1]], h[ord[sort_j]])) begin
                logic [2:0] tmpi;
                tmpi          = ord[sort_j];
                ord[sort_j]   <= ord[sort_j+1];
                ord[sort_j+1] <= tmpi;
              end
              sort_j <= sort_j + 3'd1;
            end else if (sort_pass < 3'(K-1)) begin
              sort_pass <= sort_pass + 3'd1;
              sort_j    <= 3'd0;
            end else begin
              drain_i <= 3'd0;
              st      <= ST_DRAIN;
            end
          end

          ST_DRAIN: begin
            if (!out_valid_o) begin
              out_valid_o <= 1'b1;
              out_s_o     <= h[ord[drain_i]].s;
              out_id_o    <= h[ord[drain_i]].id;
              out_idx_o   <= drain_i;
            end else if (out_ready_i) begin
              if (drain_i == 3'(K-1)) begin
                out_valid_o <= 1'b0;
                fill_n      <= 4'd0;
                last_q      <= 1'b0;
                for (gi = 0; gi < K; gi = gi + 1) begin
                  h[gi]   <= '0;
                  ord[gi] <= 3'(gi);
                end
                st <= ST_TAKE;
              end else begin
                drain_i   <= drain_i + 3'd1;
                out_s_o   <= h[ord[drain_i + 3'd1]].s;
                out_id_o  <= h[ord[drain_i + 3'd1]].id;
                out_idx_o <= drain_i + 3'd1;
              end
            end
          end

          default: st <= ST_TAKE;
        endcase
      end
    end
  end
endmodule
