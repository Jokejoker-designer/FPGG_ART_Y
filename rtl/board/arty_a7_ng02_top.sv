// arty_a7_ng02_top.sv — NG-02 timing shell: scorer + topk + frontier
`timescale 1ns / 1ps

module arty_a7_ng02_top (
  input  logic       CLK100MHZ,
  input  logic [3:0] sw,
  input  logic [3:0] btn,
  output logic [3:0] led
);
  import a7ng_pkg::*;

  logic rst_n;
  assign rst_n = ~btn[0];

  logic [15:0] lfsr;
  logic [7:0]  tick;
  logic [NG_LANES-1:0] lane_valid;
  node_id_t     cand_id [NG_LANES];
  score_terms_t terms   [NG_LANES];

  logic topk_valid;
  score_t   topk_s [8];
  node_id_t topk_id [8];
  logic pop_v, ovf;
  score_t f_s;
  node_id_t f_id;
  logic [7:0] fcnt;
  logic pop_req;

  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) begin
      lfsr <= 16'hBEEF;
      tick <= 8'd0;
      lane_valid <= '0;
      pop_req <= 1'b0;
    end else begin
      lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
      tick <= tick + 8'd1;
      lane_valid <= (tick[4:0] == 5'd0) ? {NG_LANES{1'b1}} : '0;
      pop_req <= sw[0] & (tick[2:0] == 3'd1);
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < NG_LANES; gi++) begin : g_stim
      always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
          cand_id[gi] <= '0;
          terms[gi]   <= '0;
        end else begin
          cand_id[gi] <= node_id_t'({16'h2000, lfsr} + gi);
          terms[gi].entity_match          <= term_t'(lfsr[7:0] + gi[7:0]);
          terms[gi].intent_match          <= term_t'(8'd20);
          terms[gi].relation_match        <= term_t'(8'd5);
          terms[gi].context_match         <= term_t'(8'd3);
          terms[gi].path_confidence       <= term_t'(8'd2);
          terms[gi].learned_prior         <= term_t'(8'd1);
          terms[gi].contradiction_penalty <= term_t'(sw[3:1]);
        end
      end
    end
  endgenerate

  logic batch_ready_unused;
  logic flow_busy_unused, push_fire_unused, push_stall_unused, beat_v_unused;
  logic [2:0] push_idx_unused;
  logic [1:0] flow_state_unused;
  score_t beat_s_unused;
  node_id_t beat_id_unused;

  a7ng_ng02_core u_core (
    .clk(CLK100MHZ),
    .rst_n(rst_n),
    .lane_valid_i(lane_valid),
    .cand_id_i(cand_id),
    .terms_i(terms),
    .frontier_pop_i(pop_req),
    .batch_ready_o(batch_ready_unused),
    .topk_valid_o(topk_valid),
    .topk_score_o(topk_s),
    .topk_id_o(topk_id),
    .frontier_pop_valid_o(pop_v),
    .frontier_score_o(f_s),
    .frontier_id_o(f_id),
    .frontier_overflow_o(ovf),
    .frontier_count_o(fcnt),
    .flow_busy_o(flow_busy_unused),
    .push_idx_o(push_idx_unused),
    .push_fire_o(push_fire_unused),
    .push_stall_o(push_stall_unused),
    .push_beat_valid_o(beat_v_unused),
    .push_beat_score_o(beat_s_unused),
    .push_beat_id_o(beat_id_unused),
    .flow_state_o(flow_state_unused)
  );

  logic [15:0] fold;
  always_ff @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n) begin
      fold <= 16'h0;
      led  <= 4'h0;
    end else begin
      fold <= topk_s[0] ^ topk_s[1] ^ f_s ^ {8'h0, fcnt};
      led  <= {ovf, pop_v, topk_valid, fold[0]};
    end
  end
endmodule
