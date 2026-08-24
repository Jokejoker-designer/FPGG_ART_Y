// tb_a7ng_scorer.sv — NG-01 XSim golden (law a7ng-scorer-v0)
`timescale 1ns / 1ps

module tb_a7ng_scorer;
  import a7ng_pkg::*;

  logic clk;
  logic rst_n;
  logic [NG_LANES-1:0] valid_i;
  node_id_t     cand_id_i [NG_LANES];
  score_terms_t terms_i   [NG_LANES];
  logic [NG_LANES-1:0] valid_o;
  node_id_t     cand_id_o [NG_LANES];
  score_t       score_o   [NG_LANES];

  localparam int GOLD_SCORE [0:15] = '{
    37, 38, 39, 40, 41, 42, 43, 44,
    45, 46, 47, 48, 49, 50, 51, 52
  };
  localparam int GOLD_SAT_POS = 720;
  localparam int GOLD_PENALTY = -127;
  localparam int GOLD_NEG_MIX = -95;

  a7ng_scorer_array dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .cand_id_i(cand_id_i),
    .terms_i(terms_i),
    .valid_o(valid_o),
    .cand_id_o(cand_id_o),
    .score_o(score_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic drive_lane(
      input int unsigned lane,
      input int unsigned id_u,
      input int entity_v,
      input int intent_v,
      input int relation_v,
      input int context_v,
      input int path_v,
      input int prior_v,
      input int penalty_v
  );
    cand_id_i[lane] = node_id_t'(id_u);
    terms_i[lane].entity_match          = term_t'(entity_v);
    terms_i[lane].intent_match          = term_t'(intent_v);
    terms_i[lane].relation_match        = term_t'(relation_v);
    terms_i[lane].context_match         = term_t'(context_v);
    terms_i[lane].path_confidence       = term_t'(path_v);
    terms_i[lane].learned_prior         = term_t'(prior_v);
    terms_i[lane].contradiction_penalty = term_t'(penalty_v);
  endtask

  integer fails;
  integer li;
  integer got;

  initial begin
    fails = 0;
    rst_n = 1'b0;
    valid_i = {NG_LANES{1'b0}};
    for (li = 0; li < NG_LANES; li = li + 1) begin
      cand_id_i[li] = {NG_ID_W{1'b0}};
      terms_i[li] = '0;
    end
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    for (li = 0; li < NG_LANES; li = li + 1) begin
      drive_lane(li, 32'h1000 + li, 10 + li, 20, 5, 3, 2, 1, 4);
    end
    // Latency = 2 cycles: hold valid for 2 clocks, sample after
    @(negedge clk);
    valid_i = {NG_LANES{1'b1}};
    repeat (2) @(posedge clk);
    valid_i = {NG_LANES{1'b0}};
    #1;
    if (valid_o !== {NG_LANES{1'b1}}) begin
      $display("FAIL valid_o=%b", valid_o);
      fails = fails + 1;
    end
    for (li = 0; li < NG_LANES; li = li + 1) begin
      if (cand_id_o[li] !== node_id_t'(32'h1000 + li)) begin
        $display("FAIL lane %0d id got %0h", li, cand_id_o[li]);
        fails = fails + 1;
      end
      got = integer'(score_o[li]);
      if (got !== GOLD_SCORE[li]) begin
        $display("FAIL lane %0d score got %0d exp %0d", li, got, GOLD_SCORE[li]);
        fails = fails + 1;
      end
    end
    @(posedge clk);

    drive_lane(0, 32'hAAAA, 120, 120, 120, 120, 120, 120, 0);
    @(negedge clk);
    valid_i = 16'h0001;
    repeat (2) @(posedge clk);
    valid_i = {NG_LANES{1'b0}};
    #1;
    got = integer'(score_o[0]);
    if (got !== GOLD_SAT_POS) begin
      $display("FAIL sat_pos got %0d exp %0d", got, GOLD_SAT_POS);
      fails = fails + 1;
    end
    @(posedge clk);

    drive_lane(1, 32'hBBBB, 0, 0, 0, 0, 0, 0, 127);
    @(negedge clk);
    valid_i = 16'h0002;
    repeat (2) @(posedge clk);
    valid_i = {NG_LANES{1'b0}};
    #1;
    got = integer'(score_o[1]);
    if (got !== GOLD_PENALTY) begin
      $display("FAIL penalty got %0d exp %0d", got, GOLD_PENALTY);
      fails = fails + 1;
    end
    @(posedge clk);

    drive_lane(2, 32'hCCCC, -50, -40, 10, 5, 0, 0, 20);
    @(negedge clk);
    valid_i = 16'h0004;
    repeat (2) @(posedge clk);
    valid_i = {NG_LANES{1'b0}};
    #1;
    got = integer'(score_o[2]);
    if (got !== GOLD_NEG_MIX) begin
      $display("FAIL neg_mix got %0d exp %0d", got, GOLD_NEG_MIX);
      fails = fails + 1;
    end

    if (fails == 0) begin
      $display("A7NG01_XSIM_PASS");
      $display("lanes=%0d law=a7ng-scorer-v0", NG_LANES);
    end else begin
      $display("A7NG01_XSIM_FAIL fails=%0d", fails);
    end
    $finish;
  end
endmodule
