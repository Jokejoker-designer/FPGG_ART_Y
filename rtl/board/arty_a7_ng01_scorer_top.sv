// arty_a7_ng01_scorer_top.sv — NG-01 timing shell (16 physical lanes)
// Law: a7ng-scorer-v0. Does NOT overwrite frozen encoder/LM bits.
`timescale 1ns / 1ps

module arty_a7_ng01_scorer_top (
  input  logic       CLK100MHZ,
  input  logic [3:0] sw,
  input  logic [3:0] btn,
  output logic [3:0] led
);
  import a7ng_pkg::*;

  logic rst_n;
  logic [NG_LANES-1:0] valid_i;
  node_id_t     cand_id_i [NG_LANES];
  score_terms_t terms_i   [NG_LANES];
  logic [NG_LANES-1:0] valid_o;
  node_id_t     cand_id_o [NG_LANES];
  score_t       score_o   [NG_LANES];

  logic [15:0] lfsr;
  logic [7:0]  tick;

  assign rst_n = ~btn[0];

  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) begin
      lfsr <= 16'hACE1;
      tick <= 8'd0;
      valid_i <= '0;
    end else begin
      lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
      tick <= tick + 8'd1;
      // fire all lanes every 16 cycles after fill
      valid_i <= (tick[3:0] == 4'd0) ? {NG_LANES{1'b1}} : '0;
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_stim
      always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
          cand_id_i[gi] <= '0;
          terms_i[gi]   <= '0;
        end else begin
          cand_id_i[gi] <= node_id_t'({16'h1000, lfsr} + gi);
          terms_i[gi].entity_match          <= term_t'(lfsr[7:0] + gi[7:0]);
          terms_i[gi].intent_match          <= term_t'(sw[1:0] + 8'd20);
          terms_i[gi].relation_match        <= term_t'(8'd5);
          terms_i[gi].context_match         <= term_t'(8'd3);
          terms_i[gi].path_confidence       <= term_t'(8'd2);
          terms_i[gi].learned_prior         <= term_t'(8'd1);
          terms_i[gi].contradiction_penalty <= term_t'(sw[3:2]);
        end
      end
    end
  endgenerate

  a7ng_scorer_array u_scorer (
    .clk(CLK100MHZ),
    .rst_n(rst_n),
    .valid_i(valid_i),
    .cand_id_i(cand_id_i),
    .terms_i(terms_i),
    .valid_o(valid_o),
    .cand_id_o(cand_id_o),
    .score_o(score_o)
  );

  // Keep all lane scores in the timing cone without a wide combo OR tree
  logic [15:0] score_fold;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) score_fold <= 16'h0;
    else begin
      score_fold <= score_o[0] ^ score_o[1] ^ score_o[2] ^ score_o[3]
                  ^ score_o[4] ^ score_o[5] ^ score_o[6] ^ score_o[7]
                  ^ score_o[8] ^ score_o[9] ^ score_o[10] ^ score_o[11]
                  ^ score_o[12] ^ score_o[13] ^ score_o[14] ^ score_o[15];
    end
  end

  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) led <= 4'h0;
    else led <= {valid_o[0], score_fold[2:0]};
  end
endmodule
