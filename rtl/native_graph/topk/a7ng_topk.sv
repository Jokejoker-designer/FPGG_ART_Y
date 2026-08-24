// a7ng_topk.sv — NG-02R global Top-8 over 16 candidates (bitonic 16→8)
// Law: a7ng-topk-global-v1
// Contract:
//   - Exact Top-K (K=8): the 8 globally best candidates, not pair-winners
//   - Tie: lower node_id wins; if still tied, lower lane index wins
//   - valid_mask_i=0 → candidate loses to any valid; never preferred under fill
//   - Underfill (<8 valid): pad with invalids ranked by (id asc, lane asc)
//   - Architecture: full bitonic sorting network (FANNS-aligned K-select),
//     take ranked[15:8] reversed → Top-8. Chosen over systolic PQ (multi-cycle)
//     and over thin partial nets (harder ordered Top-8 proof at N=16).
`timescale 1ns / 1ps

module a7ng_topk #(
  parameter int unsigned N = 16,
  parameter int unsigned K = 8
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       valid_i,
  input  logic [N-1:0]               valid_mask_i,
  input  a7ng_pkg::score_t           score_i [N],
  input  a7ng_pkg::node_id_t         id_i    [N],
  output logic                       valid_o,
  output a7ng_pkg::score_t           score_o [K],
  output a7ng_pkg::node_id_t         id_o    [K]
);
  import a7ng_pkg::*;

  typedef struct packed {
    logic                  v;
    score_t                s;
    node_id_t              id;
    logic [3:0]            lane;
  } cand_t;

  // Strict "a is better than b" (total order).
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

  typedef struct packed {
    cand_t lo;
    cand_t hi;
  } cas_pair_t;

  // Bitonic CAS: dir_asc=1 → worse at lo, better at hi (ascending key).
  function automatic cas_pair_t cas2(input logic dir_asc, input cand_t a, input cand_t b);
    cas_pair_t r;
    logic a_better;
    a_better = beats(a, b);
    if (dir_asc) begin
      if (a_better) begin r.lo = b; r.hi = a; end
      else          begin r.lo = a; r.hi = b; end
    end else begin
      if (a_better) begin r.lo = a; r.hi = b; end
      else          begin r.lo = b; r.hi = a; end
    end
    return r;
  endfunction

  cand_t stage0 [N];
  integer li;
  always_comb begin
    for (li = 0; li < N; li = li + 1) begin
      stage0[li].v    = valid_mask_i[li];
      stage0[li].s    = score_i[li];
      stage0[li].id   = id_i[li];
      stage0[li].lane = 4'(li);
    end
  end

  // ---- Bitonic sorting network n=16 (10 stages) → ascending (worst..best) ----
  cand_t s1 [N], s2 [N], s3 [N], s4 [N], s5 [N];
  cand_t s6 [N], s7 [N], s8 [N], s9 [N], s10 [N];

  // stage 0
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, stage0[0],  stage0[1]);  s1[0]  = p.lo; s1[1]  = p.hi;
    p = cas2(1'b0, stage0[2],  stage0[3]);  s1[2]  = p.lo; s1[3]  = p.hi;
    p = cas2(1'b1, stage0[4],  stage0[5]);  s1[4]  = p.lo; s1[5]  = p.hi;
    p = cas2(1'b0, stage0[6],  stage0[7]);  s1[6]  = p.lo; s1[7]  = p.hi;
    p = cas2(1'b1, stage0[8],  stage0[9]);  s1[8]  = p.lo; s1[9]  = p.hi;
    p = cas2(1'b0, stage0[10], stage0[11]); s1[10] = p.lo; s1[11] = p.hi;
    p = cas2(1'b1, stage0[12], stage0[13]); s1[12] = p.lo; s1[13] = p.hi;
    p = cas2(1'b0, stage0[14], stage0[15]); s1[14] = p.lo; s1[15] = p.hi;
  end
  // stage 1
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s1[0],  s1[2]);  s2[0]  = p.lo; s2[2]  = p.hi;
    p = cas2(1'b1, s1[1],  s1[3]);  s2[1]  = p.lo; s2[3]  = p.hi;
    p = cas2(1'b0, s1[4],  s1[6]);  s2[4]  = p.lo; s2[6]  = p.hi;
    p = cas2(1'b0, s1[5],  s1[7]);  s2[5]  = p.lo; s2[7]  = p.hi;
    p = cas2(1'b1, s1[8],  s1[10]); s2[8]  = p.lo; s2[10] = p.hi;
    p = cas2(1'b1, s1[9],  s1[11]); s2[9]  = p.lo; s2[11] = p.hi;
    p = cas2(1'b0, s1[12], s1[14]); s2[12] = p.lo; s2[14] = p.hi;
    p = cas2(1'b0, s1[13], s1[15]); s2[13] = p.lo; s2[15] = p.hi;
  end
  // stage 2
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s2[0],  s2[1]);  s3[0]  = p.lo; s3[1]  = p.hi;
    p = cas2(1'b1, s2[2],  s2[3]);  s3[2]  = p.lo; s3[3]  = p.hi;
    p = cas2(1'b0, s2[4],  s2[5]);  s3[4]  = p.lo; s3[5]  = p.hi;
    p = cas2(1'b0, s2[6],  s2[7]);  s3[6]  = p.lo; s3[7]  = p.hi;
    p = cas2(1'b1, s2[8],  s2[9]);  s3[8]  = p.lo; s3[9]  = p.hi;
    p = cas2(1'b1, s2[10], s2[11]); s3[10] = p.lo; s3[11] = p.hi;
    p = cas2(1'b0, s2[12], s2[13]); s3[12] = p.lo; s3[13] = p.hi;
    p = cas2(1'b0, s2[14], s2[15]); s3[14] = p.lo; s3[15] = p.hi;
  end
  // stage 3
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s3[0],  s3[4]);  s4[0]  = p.lo; s4[4]  = p.hi;
    p = cas2(1'b1, s3[1],  s3[5]);  s4[1]  = p.lo; s4[5]  = p.hi;
    p = cas2(1'b1, s3[2],  s3[6]);  s4[2]  = p.lo; s4[6]  = p.hi;
    p = cas2(1'b1, s3[3],  s3[7]);  s4[3]  = p.lo; s4[7]  = p.hi;
    p = cas2(1'b0, s3[8],  s3[12]); s4[8]  = p.lo; s4[12] = p.hi;
    p = cas2(1'b0, s3[9],  s3[13]); s4[9]  = p.lo; s4[13] = p.hi;
    p = cas2(1'b0, s3[10], s3[14]); s4[10] = p.lo; s4[14] = p.hi;
    p = cas2(1'b0, s3[11], s3[15]); s4[11] = p.lo; s4[15] = p.hi;
  end
  // stage 4
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s4[0],  s4[2]);  s5[0]  = p.lo; s5[2]  = p.hi;
    p = cas2(1'b1, s4[1],  s4[3]);  s5[1]  = p.lo; s5[3]  = p.hi;
    p = cas2(1'b1, s4[4],  s4[6]);  s5[4]  = p.lo; s5[6]  = p.hi;
    p = cas2(1'b1, s4[5],  s4[7]);  s5[5]  = p.lo; s5[7]  = p.hi;
    p = cas2(1'b0, s4[8],  s4[10]); s5[8]  = p.lo; s5[10] = p.hi;
    p = cas2(1'b0, s4[9],  s4[11]); s5[9]  = p.lo; s5[11] = p.hi;
    p = cas2(1'b0, s4[12], s4[14]); s5[12] = p.lo; s5[14] = p.hi;
    p = cas2(1'b0, s4[13], s4[15]); s5[13] = p.lo; s5[15] = p.hi;
  end
  // stage 5
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s5[0],  s5[1]);  s6[0]  = p.lo; s6[1]  = p.hi;
    p = cas2(1'b1, s5[2],  s5[3]);  s6[2]  = p.lo; s6[3]  = p.hi;
    p = cas2(1'b1, s5[4],  s5[5]);  s6[4]  = p.lo; s6[5]  = p.hi;
    p = cas2(1'b1, s5[6],  s5[7]);  s6[6]  = p.lo; s6[7]  = p.hi;
    p = cas2(1'b0, s5[8],  s5[9]);  s6[8]  = p.lo; s6[9]  = p.hi;
    p = cas2(1'b0, s5[10], s5[11]); s6[10] = p.lo; s6[11] = p.hi;
    p = cas2(1'b0, s5[12], s5[13]); s6[12] = p.lo; s6[13] = p.hi;
    p = cas2(1'b0, s5[14], s5[15]); s6[14] = p.lo; s6[15] = p.hi;
  end
  // stage 6
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s6[0],  s6[8]);  s7[0]  = p.lo; s7[8]  = p.hi;
    p = cas2(1'b1, s6[1],  s6[9]);  s7[1]  = p.lo; s7[9]  = p.hi;
    p = cas2(1'b1, s6[2],  s6[10]); s7[2]  = p.lo; s7[10] = p.hi;
    p = cas2(1'b1, s6[3],  s6[11]); s7[3]  = p.lo; s7[11] = p.hi;
    p = cas2(1'b1, s6[4],  s6[12]); s7[4]  = p.lo; s7[12] = p.hi;
    p = cas2(1'b1, s6[5],  s6[13]); s7[5]  = p.lo; s7[13] = p.hi;
    p = cas2(1'b1, s6[6],  s6[14]); s7[6]  = p.lo; s7[14] = p.hi;
    p = cas2(1'b1, s6[7],  s6[15]); s7[7]  = p.lo; s7[15] = p.hi;
  end
  // stage 7
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s7[0],  s7[4]);  s8[0]  = p.lo; s8[4]  = p.hi;
    p = cas2(1'b1, s7[1],  s7[5]);  s8[1]  = p.lo; s8[5]  = p.hi;
    p = cas2(1'b1, s7[2],  s7[6]);  s8[2]  = p.lo; s8[6]  = p.hi;
    p = cas2(1'b1, s7[3],  s7[7]);  s8[3]  = p.lo; s8[7]  = p.hi;
    p = cas2(1'b1, s7[8],  s7[12]); s8[8]  = p.lo; s8[12] = p.hi;
    p = cas2(1'b1, s7[9],  s7[13]); s8[9]  = p.lo; s8[13] = p.hi;
    p = cas2(1'b1, s7[10], s7[14]); s8[10] = p.lo; s8[14] = p.hi;
    p = cas2(1'b1, s7[11], s7[15]); s8[11] = p.lo; s8[15] = p.hi;
  end
  // stage 8
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s8[0],  s8[2]);  s9[0]  = p.lo; s9[2]  = p.hi;
    p = cas2(1'b1, s8[1],  s8[3]);  s9[1]  = p.lo; s9[3]  = p.hi;
    p = cas2(1'b1, s8[4],  s8[6]);  s9[4]  = p.lo; s9[6]  = p.hi;
    p = cas2(1'b1, s8[5],  s8[7]);  s9[5]  = p.lo; s9[7]  = p.hi;
    p = cas2(1'b1, s8[8],  s8[10]); s9[8]  = p.lo; s9[10] = p.hi;
    p = cas2(1'b1, s8[9],  s8[11]); s9[9]  = p.lo; s9[11] = p.hi;
    p = cas2(1'b1, s8[12], s8[14]); s9[12] = p.lo; s9[14] = p.hi;
    p = cas2(1'b1, s8[13], s8[15]); s9[13] = p.lo; s9[15] = p.hi;
  end
  // stage 9 — fully ascending: s10[0]=worst … s10[15]=best
  always_comb begin
    cas_pair_t p;
    p = cas2(1'b1, s9[0],  s9[1]);  s10[0]  = p.lo; s10[1]  = p.hi;
    p = cas2(1'b1, s9[2],  s9[3]);  s10[2]  = p.lo; s10[3]  = p.hi;
    p = cas2(1'b1, s9[4],  s9[5]);  s10[4]  = p.lo; s10[5]  = p.hi;
    p = cas2(1'b1, s9[6],  s9[7]);  s10[6]  = p.lo; s10[7]  = p.hi;
    p = cas2(1'b1, s9[8],  s9[9]);  s10[8]  = p.lo; s10[9]  = p.hi;
    p = cas2(1'b1, s9[10], s9[11]); s10[10] = p.lo; s10[11] = p.hi;
    p = cas2(1'b1, s9[12], s9[13]); s10[12] = p.lo; s10[13] = p.hi;
    p = cas2(1'b1, s9[14], s9[15]); s10[14] = p.lo; s10[15] = p.hi;
  end

  // Top-8 = best … 8th-best  = s10[15] .. s10[8]
  cand_t top8 [K];
  always_comb begin
    top8[0] = s10[15];
    top8[1] = s10[14];
    top8[2] = s10[13];
    top8[3] = s10[12];
    top8[4] = s10[11];
    top8[5] = s10[10];
    top8[6] = s10[9];
    top8[7] = s10[8];
  end

  integer bi;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_o <= 1'b0;
      for (bi = 0; bi < K; bi = bi + 1) begin
        score_o[bi] <= '0;
        id_o[bi]    <= '0;
      end
    end else begin
      valid_o <= valid_i;
      if (valid_i) begin
        for (bi = 0; bi < K; bi = bi + 1) begin
          score_o[bi] <= top8[bi].s;
          id_o[bi]    <= top8[bi].id;
        end
      end
    end
  end
endmodule
