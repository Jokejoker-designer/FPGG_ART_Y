// a7ng_topk_wavefront_global.sv — cross-wave global Top-8 accumulator for ddr_wavefront
// Law: a7ng-topk-wavefront-global-v1
// Recurrence: G_0 = empty; G_(t+1) = TopK( G_t ∪ TopK(W_t) )
// Merge uses UNCHANGED a7ng_topk 16→8 (a7ng-topk-global-v1 comparator law).
// Lane map: slots 0..7 = G_t (valid_mask from g_valid); slots 8..15 = W_t wave top-8.
`timescale 1ns / 1ps

module a7ng_topk_wavefront_global #(
  parameter int unsigned K = 8
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
  output logic [31:0]                merge_count_o
);
  import a7ng_pkg::*;

  localparam int unsigned N_MERGE = 16;

  score_t   g_score [K];
  node_id_t g_id    [K];
  logic     g_valid [K];

  logic       m_valid_i;
  logic [N_MERGE-1:0] m_mask_i;
  score_t     m_score [N_MERGE];
  node_id_t   m_id    [N_MERGE];

  logic       m_valid_o;
  score_t     m_score_o [K];
  node_id_t   m_id_o    [K];

  a7ng_topk #(.N(N_MERGE), .K(K)) u_merge (
    .clk(clk), .rst_n(rst_n),
    .valid_i(m_valid_i), .valid_mask_i(m_mask_i),
    .score_i(m_score), .id_i(m_id),
    .valid_o(m_valid_o), .score_o(m_score_o), .id_o(m_id_o)
  );

  logic [4:0] wave_n_lat;
  score_t     wave_s_lat [K];
  node_id_t   wave_i_lat [K];
  logic       merge_armed;
  logic       merge_fire;
  logic       m_valid_q;
  logic [31:0] merges;

  function automatic logic [N_MERGE-1:0] wave_slot_mask(input logic [4:0] n);
    logic [N_MERGE-1:0] m;
    int i;
    begin
      m = '0;
      if (n == 0)
        wave_slot_mask = '0;
      else if (n <= K) begin
        for (i = 0; i < K; i = i + 1)
          m[8 + i] = (i < n);
        wave_slot_mask = m;
      end else
        wave_slot_mask = 16'hFF00;
    end
  endfunction

  function automatic logic [4:0] count_valid_slots(input logic valid_arr [K]);
    int j;
    count_valid_slots = 5'd0;
    for (j = 0; j < K; j = j + 1)
      if (valid_arr[j]) count_valid_slots = count_valid_slots + 5'd1;
  endfunction

  integer mi;
  always_comb begin
    for (mi = 0; mi < K; mi = mi + 1) begin
      m_score[mi]     = g_score[mi];
      m_id[mi]        = g_id[mi];
      m_score[8 + mi] = wave_s_lat[mi];
      m_id[8 + mi]    = wave_i_lat[mi];
    end
    m_mask_i = '0;
    for (mi = 0; mi < K; mi = mi + 1)
      if (g_valid[mi])
        m_mask_i[mi] = 1'b1;
    m_mask_i |= wave_slot_mask(wave_n_lat);
    m_valid_i = merge_fire;
  end

  assign busy_o = merge_armed;

  integer gi;
  logic [4:0] g_valid_count;
  logic [4:0] out_valid_count;
  logic [4:0] wave_eff;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      merge_armed      <= 1'b0;
      merge_fire       <= 1'b0;
      wave_n_lat       <= '0;
      global_valid_o   <= 1'b0;
      merges           <= 32'd0;
      for (gi = 0; gi < K; gi = gi + 1) begin
        g_score[gi] <= '0;
        g_id[gi]    <= '0;
        g_valid[gi] <= 1'b0;
        global_score_o[gi] <= '0;
        global_id_o[gi]    <= '0;
        wave_s_lat[gi]     <= '0;
        wave_i_lat[gi]     <= '0;
      end
    end else begin
      global_valid_o <= 1'b0;
      merge_fire     <= 1'b0;
      m_valid_q      <= m_valid_o;
      if (clear_i) begin
        merge_armed <= 1'b0;
        merges      <= 32'd0;
        for (gi = 0; gi < K; gi = gi + 1) begin
          g_score[gi] <= '0;
          g_id[gi]    <= '0;
          g_valid[gi] <= 1'b0;
          global_score_o[gi] <= '0;
          global_id_o[gi]    <= '0;
        end
      end else begin
        if (wave_valid_i && !merge_armed) begin
          wave_n_lat <= wave_scored_i;
          for (gi = 0; gi < K; gi = gi + 1) begin
            wave_s_lat[gi] <= wave_score_i[gi];
            wave_i_lat[gi] <= wave_id_i[gi];
          end
          merge_armed <= 1'b1;
          merge_fire  <= 1'b1;
        end else if (merge_armed && m_valid_q) begin
          g_valid_count = count_valid_slots(g_valid);
          wave_eff = (wave_n_lat > K) ? 5'd8 : wave_n_lat;
          out_valid_count = g_valid_count + wave_eff;
          if (out_valid_count > 5'd8)
            out_valid_count = 5'd8;
          for (gi = 0; gi < K; gi = gi + 1) begin
            g_score[gi]        <= m_score_o[gi];
            g_id[gi]           <= m_id_o[gi];
            g_valid[gi]        <= (gi < out_valid_count);
            global_score_o[gi] <= m_score_o[gi];
            global_id_o[gi]    <= m_id_o[gi];
          end
          global_valid_o <= 1'b1;
          merges         <= merges + 32'd1;
          merge_armed    <= 1'b0;
        end
      end
    end
  end

  assign merge_count_o = merges;

endmodule
