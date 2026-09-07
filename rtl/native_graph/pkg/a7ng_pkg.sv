// a7ng_pkg.sv — NG-01 shared types + TermGen HDC helpers
// Scorer law: a7ng-scorer-v0
// TermGen law: a7ng-termgen-v0 (binary HDC/VSA; cue_w=64; DSP=0)
`timescale 1ns / 1ps

package a7ng_pkg;
  localparam int unsigned NG_LANES   = 16;
  localparam int unsigned NG_SCORE_W = 16;
  localparam int unsigned NG_TERM_W  = 8;
  localparam int unsigned NG_ID_W    = 32;
  // U4B: live ID observe width. 799999 = 20'hC34FF. Do not alias to id[7:0].
  localparam int unsigned NG_ID_LIVE_W = 20;
  localparam logic [19:0] NG_ID_SENTINEL_20 = 20'hC34FF;
  localparam int unsigned NG_FEAT_W  = 32;
  localparam int unsigned NG_CUE_W   = 64; // TermGen / 01R-aligned cue width

  // NG-03 DDR map (byte addresses in MIG 28-bit AXI space; FPGA-owned)
  // Region layout archived in results/A7-NATIVE-GRAPH/NG-03/DDR_MAP.md
  localparam logic [27:0] NG_DDR_NODE_BASE   = 28'h0100_0000; // topic/node table (AOS NodeRecordV1)
  localparam logic [27:0] NG_DDR_CUE64_BASE  = 28'h0110_0000; // SOA stage-1 cue64 column (ddr_cue_soa_00)
  localparam logic [27:0] NG_DDR_EDGE_BASE   = 28'h0200_0000; // edge table (reserved)
  localparam logic [27:0] NG_DDR_PRIOR_BASE  = 28'h0300_0000; // NG-05 learned priors (FPGA-owned)
  localparam logic [27:0] NG_DDR_EPISODE_BASE = 28'h0400_0000; // MEM-01 episodes
  localparam logic [27:0] NG_DDR_INDEX_BASE   = 28'h0500_0000; // MEM-02 router index
  // Strides alias mem_schema_v1 (rtl/native_graph/memory/a7ng_mem_schema_v1.sv) — no magic forks
  // Stage-1 SOA column strides (104-bit semantic descriptor — DESCRIPTOR_CONTRACT_FREEZE)
  localparam int unsigned NG_STAGE1_ID_BYTES    = 4;
  localparam int unsigned NG_STAGE1_CUE_BYTES   = 8;
  localparam int unsigned NG_STAGE1_PRIOR_BYTES = 1;
  localparam int unsigned NG_STAGE1_DESC_BITS   = 104;
  localparam int unsigned NG_NODE_REC_BYTES    = 16;          // NodeRecordV1
  localparam int unsigned NG_EDGE_REC_BYTES    = 32;          // EdgeRecordV1
  localparam int unsigned NG_EPISODE_REC_BYTES = 32;          // EpisodeRecordV1
  localparam int unsigned NG_SHARD_FETCH_B     = NG_NODE_REC_BYTES; // one beat / miss (HS-13)
  localparam int unsigned NG_HOTSET_DEPTH    = 256;
  localparam int unsigned NG_PRIOR_DEPTH     = 64;
  localparam int unsigned NG_PRIOR_BYTES     = NG_PRIOR_DEPTH; // 1 byte/prior
  localparam int unsigned NG_PRIOR_BEATS     = (NG_PRIOR_BYTES + 15) / 16; // 4

  // ---- Training-generation EPOCH (RESET-00 law; Gate14 persist cookie) ----
  // One object, two operations:
  //   BUMP     : live_gen++  (logical forget; old 8-bit stamps become !vis_w)
  //   REBIRTH  : live_gen=1, BRAM wiped, DDR header+slots zeroed
  // DDR header word 0 MUST be ng_epoch_pack(gen) or it is garbage, never live_gen.
  // Stamp in the working-set record is live_gen[7:0]; WRAP_LIMIT must be <= 255.
  localparam int unsigned NG_EPOCH_STAMP_W = 8;
  function automatic logic ng_epoch_legal(
      input logic [63:0] d, input logic [31:0] wrap_limit);
    return d[0] && (d[32:1] != 32'd0) && (d[63:33] == 31'd0)
        && (d[32:1] <= wrap_limit);
  endfunction
  function automatic logic [31:0] ng_epoch_gen(input logic [63:0] d);
    return d[32:1];
  endfunction
  function automatic logic [63:0] ng_epoch_pack(input logic [31:0] gen);
    return {31'd0, gen, 1'b1};
  endfunction
  function automatic logic ng_epoch_visible(
      input logic        ws_live,
      input logic [31:0] live_gen,
      input logic        occ,
      input logic [7:0]  stmp);
    return ws_live && (live_gen != 32'd0) && occ && (stmp != 8'd0)
        && (stmp == live_gen[NG_EPOCH_STAMP_W-1:0]);
  endfunction

  typedef logic signed [NG_SCORE_W-1:0] score_t;
  typedef logic signed [NG_TERM_W-1:0]  term_t;
  typedef logic        [NG_ID_W-1:0]    node_id_t;
  typedef logic        [NG_FEAT_W-1:0]  feat_t;
  typedef logic        [NG_CUE_W-1:0]   cue_t;

  typedef struct packed {
    term_t entity_match;
    term_t intent_match;
    term_t relation_match;
    term_t context_match;
    term_t path_confidence;
    term_t learned_prior;
    term_t contradiction_penalty;
  } score_terms_t;

  // Candidate cue bag for TermGen (FPGA-owned features; not host scores)
  typedef struct packed {
    cue_t  query_cue;
    cue_t  node_cue;
    cue_t  relation_cue;
    cue_t  intent_cue;
    cue_t  context_cue;
    cue_t  path_cue;
    term_t learned_prior; // memory prior byte; passthrough (not host-composed)
  } termgen_cues_t;

  // Widen BEFORE add to avoid 16-bit wrap (HS: deterministic integer score)
  function automatic score_t sat_add16(score_t a, score_t b);
    logic signed [NG_SCORE_W:0] aa;
    logic signed [NG_SCORE_W:0] bb;
    logic signed [NG_SCORE_W:0] sum;
    aa  = {a[NG_SCORE_W-1], a};
    bb  = {b[NG_SCORE_W-1], b};
    sum = aa + bb;
    if (sum > 17'sd32767)  return 16'sd32767;
    if (sum < -17'sd32768) return -16'sd32768;
    return score_t'(sum[NG_SCORE_W-1:0]);
  endfunction

  function automatic score_t sext_term(term_t t);
    return {{(NG_SCORE_W-NG_TERM_W){t[NG_TERM_W-1]}}, t};
  endfunction

  function automatic score_t compose_score(score_terms_t t);
    score_t s;
    s = sext_term(t.entity_match);
    s = sat_add16(s, sext_term(t.intent_match));
    s = sat_add16(s, sext_term(t.relation_match));
    s = sat_add16(s, sext_term(t.context_match));
    s = sat_add16(s, sext_term(t.path_confidence));
    s = sat_add16(s, sext_term(t.learned_prior));
    s = sat_add16(s, -sext_term(t.contradiction_penalty));
    return s;
  endfunction

  // ---- TermGen HDC/VSA primitives (a7ng-termgen-v0); LUT/FF only ----
  function automatic cue_t ng_rotl1(cue_t x);
    return {x[NG_CUE_W-2:0], x[NG_CUE_W-1]};
  endfunction

  function automatic cue_t ng_rotl8(cue_t x);
    return {x[NG_CUE_W-9:0], x[NG_CUE_W-1:NG_CUE_W-8]};
  endfunction

  function automatic cue_t ng_rotl16(cue_t x);
    return {x[NG_CUE_W-17:0], x[NG_CUE_W-1:NG_CUE_W-16]};
  endfunction

  function automatic cue_t ng_rotl32(cue_t x);
    return {x[NG_CUE_W-33:0], x[NG_CUE_W-1:NG_CUE_W-32]};
  endfunction

  function automatic logic [3:0] ng_pop8(input logic [7:0] x);
    return {3'b0, x[0]} + {3'b0, x[1]} + {3'b0, x[2]} + {3'b0, x[3]}
         + {3'b0, x[4]} + {3'b0, x[5]} + {3'b0, x[6]} + {3'b0, x[7]};
  endfunction

  function automatic logic [6:0] ng_pop64(input cue_t x);
    logic [3:0] p0, p1, p2, p3, p4, p5, p6, p7;
    logic [5:0] lo, hi;
    p0 = ng_pop8(x[7:0]);
    p1 = ng_pop8(x[15:8]);
    p2 = ng_pop8(x[23:16]);
    p3 = ng_pop8(x[31:24]);
    p4 = ng_pop8(x[39:32]);
    p5 = ng_pop8(x[47:40]);
    p6 = ng_pop8(x[55:48]);
    p7 = ng_pop8(x[63:56]);
    lo = {2'b0, p0} + {2'b0, p1} + {2'b0, p2} + {2'b0, p3};
    hi = {2'b0, p4} + {2'b0, p5} + {2'b0, p6} + {2'b0, p7};
    return {1'b0, lo} + {1'b0, hi};
  endfunction

  // Similarity term: 64 - Hamming distance → [0..64] as signed term_t
  function automatic term_t ng_sim8(cue_t a, cue_t b);
    logic [6:0] d;
    logic [7:0] sim;
    d   = ng_pop64(a ^ b);
    sim = 8'd64 - {1'b0, d};
    return term_t'(sim);
  endfunction

  // Contradiction intensity: popcount((a^b) & mask) >> 1, sat to term
  function automatic term_t ng_contra8(cue_t a, cue_t b, cue_t mask);
    logic [6:0] c;
    c = ng_pop64((a ^ b) & mask);
    return term_t'(c[6:1]); // >> 1, range 0..32
  endfunction

  // Pure combinational TermGen law (bit-exact vs Python/XSim golden)
  // Relation BIND: probe = query XOR ROTL1(relation); sim vs node (relation must not cancel).
  function automatic score_terms_t ng_termgen_compose(termgen_cues_t c);
    score_terms_t t;
    cue_t rel_probe;
    cue_t path_expect;
    rel_probe   = c.query_cue ^ ng_rotl1(c.relation_cue);
    path_expect = ng_rotl8(c.query_cue ^ c.node_cue);
    t.entity_match          = ng_sim8(c.query_cue, c.node_cue);
    t.intent_match          = ng_sim8(c.intent_cue, ng_rotl16(c.node_cue));
    t.relation_match        = ng_sim8(rel_probe, c.node_cue);
    t.context_match         = ng_sim8(c.context_cue, ng_rotl32(c.node_cue));
    t.path_confidence       = ng_sim8(c.path_cue, path_expect);
    t.learned_prior         = c.learned_prior;
    t.contradiction_penalty = ng_contra8(c.query_cue, c.node_cue, c.path_cue);
    return t;
  endfunction
endpackage
