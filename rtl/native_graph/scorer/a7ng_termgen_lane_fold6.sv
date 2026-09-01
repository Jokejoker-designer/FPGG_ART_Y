// a7ng_termgen_lane_fold6.sv — R1: one XOR/popcount64 per physical lane, 6 microsteps
// Law: a7ng-termgen-v0 bit-exact vs ng_termgen_compose. II=6. PROGRAM=NO.
// GRAPH-PAYLOAD-NORESET-00: payload (cues_q,id_q,terms_q,cand_id_o,terms_o) has no reset.
// Authority (st, valid_o) keeps async reset. Do not convert async→sync.
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module a7ng_termgen_lane_fold6 (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     valid_i,
  output logic                     ready_o,
  input  a7ng_pkg::node_id_t       cand_id_i,
  input  a7ng_pkg::termgen_cues_t  cues_i,
  output logic                     valid_o,
  input  logic                     ready_i,
  output a7ng_pkg::node_id_t       cand_id_o,
  output a7ng_pkg::score_terms_t   terms_o
);
  import a7ng_pkg::*;

  typedef enum logic [2:0] {
    ST_IDLE = 3'd0,
    ST_ENT  = 3'd1,
    ST_INT  = 3'd2,
    ST_REL  = 3'd3,
    ST_CTX  = 3'd4,
    ST_PTH  = 3'd5,
    ST_CTR  = 3'd6,
    ST_HOLD = 3'd7
  } st_e;

  st_e st;
  termgen_cues_t cues_q;
  node_id_t      id_q;
  score_terms_t  terms_q;

  assign ready_o = (st == ST_IDLE);

  cue_t xor_now;
  always_comb begin
    unique case (st)
      ST_ENT: xor_now = cues_q.query_cue ^ cues_q.node_cue;
      ST_INT: xor_now = cues_q.intent_cue ^ ng_rotl16(cues_q.node_cue);
      ST_REL: xor_now = (cues_q.query_cue ^ ng_rotl1(cues_q.relation_cue)) ^ cues_q.node_cue;
      ST_CTX: xor_now = cues_q.context_cue ^ ng_rotl32(cues_q.node_cue);
      ST_PTH: xor_now = cues_q.path_cue ^ ng_rotl8(cues_q.query_cue ^ cues_q.node_cue);
      ST_CTR: xor_now = (cues_q.query_cue ^ cues_q.node_cue) & cues_q.path_cue;
      default: xor_now = '0;
    endcase
  end

  logic [6:0] pop_now;
  always_comb pop_now = ng_pop64(xor_now);

  term_t sim_now;
  always_comb sim_now = term_t'(8'd64 - {1'b0, pop_now});

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st      <= ST_IDLE;
      valid_o <= 1'b0;
    end else begin
      if (valid_o && ready_i)
        valid_o <= 1'b0;

      unique case (st)
        ST_IDLE: begin
          if (valid_i)
            st <= ST_ENT;
        end
        ST_ENT: st <= ST_INT;
        ST_INT: st <= ST_REL;
        ST_REL: st <= ST_CTX;
        ST_CTX: st <= ST_PTH;
        ST_PTH: st <= ST_CTR;
        ST_CTR: begin
          valid_o <= 1'b1;
          st      <= ST_HOLD;
        end
        ST_HOLD: begin
          if (valid_o && ready_i)
            st <= ST_IDLE;
          else if (!valid_o)
            st <= ST_IDLE;
        end
        default: st <= ST_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    unique case (st)
      ST_IDLE: begin
        if (valid_i) begin
          cues_q <= cues_i;
          id_q   <= cand_id_i;
          terms_q.learned_prior <= cues_i.learned_prior;
        end
      end
      ST_ENT: terms_q.entity_match  <= sim_now;
      ST_INT: terms_q.intent_match  <= sim_now;
      ST_REL: terms_q.relation_match <= sim_now;
      ST_CTX: terms_q.context_match <= sim_now;
      ST_PTH: terms_q.path_confidence <= sim_now;
      ST_CTR: begin
        terms_q.contradiction_penalty <= term_t'({1'b0, pop_now[6:1]});
        cand_id_o <= id_q;
        terms_o   <= terms_q;
        terms_o.contradiction_penalty <= term_t'({1'b0, pop_now[6:1]});
      end
      default: ;
    endcase
  end
endmodule
