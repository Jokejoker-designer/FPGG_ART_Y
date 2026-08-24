// tb_a7ng_termgen.sv — TermGen XSim golden (law a7ng-termgen-v0)
// Unit = candidate vector / query bag (TG_N), not cycles-as-queries.
`timescale 1ns / 1ps

module tb_a7ng_termgen;
  import a7ng_pkg::*;

  logic clk;
  logic rst_n;
  logic [NG_LANES-1:0] valid_i;
  node_id_t      cand_id_i [NG_LANES];
  termgen_cues_t cues_i    [NG_LANES];
  logic [NG_LANES-1:0] valid_o;
  node_id_t      cand_id_o [NG_LANES];
  score_terms_t  terms_o   [NG_LANES];

`include "tb_a7ng_termgen_golden.svh"

  a7ng_termgen_array dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .cand_id_i(cand_id_i),
    .cues_i(cues_i),
    .valid_o(valid_o),
    .cand_id_o(cand_id_o),
    .terms_o(terms_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer fails;
  integer vi;
  integer lane;
  integer base;
  integer idx;

  task automatic load_vec(input int unsigned lane_i, input int unsigned vec_i);
    cand_id_i[lane_i]              = node_id_t'(32'h2000 + vec_i);
    cues_i[lane_i].query_cue       = TG_Q[vec_i];
    cues_i[lane_i].node_cue        = TG_NODE[vec_i];
    cues_i[lane_i].relation_cue    = TG_REL[vec_i];
    cues_i[lane_i].intent_cue      = TG_INT[vec_i];
    cues_i[lane_i].context_cue     = TG_CTX[vec_i];
    cues_i[lane_i].path_cue        = TG_PATH[vec_i];
    cues_i[lane_i].learned_prior   = TG_PRIOR[vec_i];
  endtask

  task automatic check_lane(input int unsigned lane_i, input int unsigned vec_i);
    if (cand_id_o[lane_i] !== node_id_t'(32'h2000 + vec_i)) begin
      $display("FAIL id lane=%0d vec=%0d got=%0h", lane_i, vec_i, cand_id_o[lane_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].entity_match !== TG_GOLD_ENTITY_MATCH[vec_i]) begin
      $display("FAIL entity lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].entity_match, TG_GOLD_ENTITY_MATCH[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].intent_match !== TG_GOLD_INTENT_MATCH[vec_i]) begin
      $display("FAIL intent lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].intent_match, TG_GOLD_INTENT_MATCH[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].relation_match !== TG_GOLD_RELATION_MATCH[vec_i]) begin
      $display("FAIL relation lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].relation_match, TG_GOLD_RELATION_MATCH[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].context_match !== TG_GOLD_CONTEXT_MATCH[vec_i]) begin
      $display("FAIL context lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].context_match, TG_GOLD_CONTEXT_MATCH[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].path_confidence !== TG_GOLD_PATH_CONFIDENCE[vec_i]) begin
      $display("FAIL path lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].path_confidence, TG_GOLD_PATH_CONFIDENCE[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].learned_prior !== TG_GOLD_LEARNED_PRIOR[vec_i]) begin
      $display("FAIL prior lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].learned_prior, TG_GOLD_LEARNED_PRIOR[vec_i]);
      fails = fails + 1;
    end
    if (terms_o[lane_i].contradiction_penalty !== TG_GOLD_CONTRADICTION_PENALTY[vec_i]) begin
      $display("FAIL contra lane=%0d vec=%0d got=%0d exp=%0d",
               lane_i, vec_i, terms_o[lane_i].contradiction_penalty,
               TG_GOLD_CONTRADICTION_PENALTY[vec_i]);
      fails = fails + 1;
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 1'b0;
    valid_i = {NG_LANES{1'b0}};
    for (lane = 0; lane < NG_LANES; lane = lane + 1) begin
      cand_id_i[lane] = '0;
      cues_i[lane] = '0;
    end
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // Drive TG_N vectors across 16 lanes in waves (II=1 after fill; latency=2)
    for (base = 0; base < TG_N; base = base + NG_LANES) begin
      for (lane = 0; lane < NG_LANES; lane = lane + 1) begin
        idx = base + lane;
        if (idx < TG_N) load_vec(lane, idx);
        else begin
          cand_id_i[lane] = '0;
          cues_i[lane] = '0;
        end
      end
      @(negedge clk);
      for (lane = 0; lane < NG_LANES; lane = lane + 1)
        valid_i[lane] = ((base + lane) < TG_N) ? 1'b1 : 1'b0;
      repeat (2) @(posedge clk);
      valid_i = {NG_LANES{1'b0}};
      #1;
      for (lane = 0; lane < NG_LANES; lane = lane + 1) begin
        idx = base + lane;
        if (idx < TG_N) begin
          if (valid_o[lane] !== 1'b1) begin
            $display("FAIL valid lane=%0d vec=%0d", lane, idx);
            fails = fails + 1;
          end
          check_lane(lane, idx);
        end
      end
      @(posedge clk);
    end

    // Package-function cross-check (combinational law == pipelined)
    begin
      termgen_cues_t c0;
      score_terms_t  tfn;
      c0.query_cue     = TG_Q[0];
      c0.node_cue      = TG_NODE[0];
      c0.relation_cue  = TG_REL[0];
      c0.intent_cue    = TG_INT[0];
      c0.context_cue   = TG_CTX[0];
      c0.path_cue      = TG_PATH[0];
      c0.learned_prior = TG_PRIOR[0];
      tfn = ng_termgen_compose(c0);
      if (tfn.entity_match !== TG_GOLD_ENTITY_MATCH[0] ||
          tfn.relation_match !== TG_GOLD_RELATION_MATCH[0] ||
          tfn.path_confidence !== TG_GOLD_PATH_CONFIDENCE[0]) begin
        $display("FAIL pkg_compose mismatch");
        fails = fails + 1;
      end
    end

    if (fails == 0) begin
      $display("A7NG_TERMGEN_XSIM_PASS");
      $display("law=%s lanes=%0d vectors=%0d families=hamming,bind,intent_context,path",
               "a7ng-termgen-v0", NG_LANES, TG_N);
    end else begin
      $display("A7NG_TERMGEN_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
