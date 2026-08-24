// a7ng_frontier_twolevel.sv — local sorted PQs + global best-of-heads merge
// Shootout arm C (frontier_shootout). Law: a7ng-frontier-twolevel-v0 (research).
// Push routes by id[1:0] into one of N_LOCAL lanes; pop takes max among heads.
// Tie: higher score, then lower ID. Overflow drop when selected local full.
// TB issues push XOR pop. Does NOT change a7ng-topk-global-v1.
`timescale 1ns / 1ps

module a7ng_frontier_twolevel #(
  parameter int unsigned N_LOCAL     = 4,
  parameter int unsigned LOCAL_DEPTH = 16,
  parameter int unsigned SCORE_W     = 16,
  parameter int unsigned ID_W        = 32
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       push_i,
  input  logic signed [SCORE_W-1:0]  score_i,
  input  logic [ID_W-1:0]            id_i,
  input  logic                       pop_i,
  output logic                       pop_valid_o,
  output logic signed [SCORE_W-1:0]  score_o,
  output logic [ID_W-1:0]            id_o,
  output logic                       overflow_o,
  output logic                       ready_o,
  output logic [7:0]                 count_o
);
  localparam int unsigned PTR_W  = $clog2(LOCAL_DEPTH + 1);
  localparam int unsigned LANE_W = (N_LOCAL <= 1) ? 1 : $clog2(N_LOCAL);

  logic signed [SCORE_W-1:0] mem_s  [N_LOCAL][LOCAL_DEPTH];
  logic [ID_W-1:0]           mem_id [N_LOCAL][LOCAL_DEPTH];
  logic [PTR_W-1:0]          occ    [N_LOCAL];

  function automatic logic beats(
    input logic signed [SCORE_W-1:0] sa,
    input logic [ID_W-1:0]           ida,
    input logic signed [SCORE_W-1:0] sb,
    input logic [ID_W-1:0]           idb
  );
    if (sa != sb) return sa > sb;
    return ida < idb;
  endfunction

  logic [LANE_W-1:0] push_lane;
  assign push_lane = LANE_W'(id_i[LANE_W-1:0]);

  logic                      found_head;
  logic [LANE_W-1:0]         hi_lane;
  logic signed [SCORE_W-1:0] hi_s;
  logic [ID_W-1:0]           hi_id;

  always_comb begin
    found_head = 1'b0;
    hi_lane    = '0;
    hi_s       = '0;
    hi_id      = '0;
    for (int l = 0; l < N_LOCAL; l++) begin
      if (occ[l] != '0) begin
        if (!found_head ||
            beats(mem_s[l][0], mem_id[l][0], hi_s, hi_id)) begin
          found_head = 1'b1;
          hi_lane    = LANE_W'(l);
          hi_s       = mem_s[l][0];
          hi_id      = mem_id[l][0];
        end
      end
    end
  end

  logic       overflow_r;
  logic [7:0] count_r;

  assign ready_o = (occ[push_lane] < LOCAL_DEPTH);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      overflow_r  <= 1'b0;
      count_r     <= 8'd0;
      pop_valid_o <= 1'b0;
      score_o     <= '0;
      id_o        <= '0;
      for (int l = 0; l < N_LOCAL; l++) begin
        occ[l] <= '0;
        for (int d = 0; d < LOCAL_DEPTH; d++) begin
          mem_s[l][d]  <= '0;
          mem_id[l][d] <= '0;
        end
      end
    end else begin
      overflow_r  <= 1'b0;
      pop_valid_o <= 1'b0;

      if (pop_i && found_head) begin
        score_o     <= mem_s[hi_lane][0];
        id_o        <= mem_id[hi_lane][0];
        pop_valid_o <= 1'b1;
        for (int d = 0; d < LOCAL_DEPTH - 1; d++) begin
          mem_s[hi_lane][d]  <= mem_s[hi_lane][d + 1];
          mem_id[hi_lane][d] <= mem_id[hi_lane][d + 1];
        end
        mem_s[hi_lane][LOCAL_DEPTH - 1]  <= '0;
        mem_id[hi_lane][LOCAL_DEPTH - 1] <= '0;
        occ[hi_lane] <= occ[hi_lane] - 1'b1;
        count_r      <= count_r - 8'd1;
      end else if (push_i) begin
        if (occ[push_lane] < LOCAL_DEPTH) begin
          begin
            automatic int insert_at;
            automatic int base_occ;
            automatic logic found;
            base_occ  = int'(occ[push_lane]);
            insert_at = base_occ;
            found     = 1'b0;
            for (int i = 0; i < LOCAL_DEPTH; i++) begin
              if (!found && i < base_occ &&
                  beats(score_i, id_i, mem_s[push_lane][i], mem_id[push_lane][i])) begin
                insert_at = i;
                found     = 1'b1;
              end
            end
            for (int j = LOCAL_DEPTH - 1; j > 0; j--) begin
              if (j > insert_at && j <= base_occ) begin
                mem_s[push_lane][j]  <= mem_s[push_lane][j - 1];
                mem_id[push_lane][j] <= mem_id[push_lane][j - 1];
              end
            end
            mem_s[push_lane][insert_at]  <= score_i;
            mem_id[push_lane][insert_at] <= id_i;
          end
          occ[push_lane] <= occ[push_lane] + 1'b1;
          count_r        <= count_r + 8'd1;
        end else begin
          overflow_r <= 1'b1;
        end
      end
    end
  end

  assign overflow_o = overflow_r;
  assign count_o    = count_r;
endmodule
