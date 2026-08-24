// a7ng_frontier_systolic_pq.sv — exact sorted shift-register priority queue
// Shootout arm B (frontier_shootout). Law: a7ng-frontier-systolic-v0 (research).
// Order: higher score first; tie → lower node ID. Comparator tree / shift, no pointer heap.
// Overflow: drop push when full (overflow_o). TB issues push XOR pop (no same-cycle).
// Does NOT change global Top-8 law a7ng-topk-global-v1.
`timescale 1ns / 1ps

module a7ng_frontier_systolic_pq #(
  parameter int unsigned DEPTH   = 64,
  parameter int unsigned SCORE_W = 16,
  parameter int unsigned ID_W    = 32
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
  localparam int unsigned PTR_W = $clog2(DEPTH + 1);

  logic signed [SCORE_W-1:0] mem_s  [DEPTH];
  logic [ID_W-1:0]           mem_id [DEPTH];
  logic [PTR_W-1:0]          occ;

  function automatic logic beats(
    input logic signed [SCORE_W-1:0] sa,
    input logic [ID_W-1:0]           ida,
    input logic signed [SCORE_W-1:0] sb,
    input logic [ID_W-1:0]           idb
  );
    if (sa != sb) return sa > sb;
    return ida < idb;
  endfunction

  logic       overflow_r;
  logic [7:0] count_r;

  assign ready_o = (occ < DEPTH);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      occ         <= '0;
      overflow_r  <= 1'b0;
      count_r     <= 8'd0;
      pop_valid_o <= 1'b0;
      score_o     <= '0;
      id_o        <= '0;
      for (int i = 0; i < DEPTH; i++) begin
        mem_s[i]  <= '0;
        mem_id[i] <= '0;
      end
    end else begin
      overflow_r  <= 1'b0;
      pop_valid_o <= 1'b0;

      if (pop_i && (occ != '0)) begin
        score_o     <= mem_s[0];
        id_o        <= mem_id[0];
        pop_valid_o <= 1'b1;
        for (int i = 0; i < DEPTH - 1; i++) begin
          mem_s[i]  <= mem_s[i + 1];
          mem_id[i] <= mem_id[i + 1];
        end
        mem_s[DEPTH - 1]  <= '0;
        mem_id[DEPTH - 1] <= '0;
        occ     <= occ - 1'b1;
        count_r <= 8'(occ - 1'b1);
      end else if (push_i) begin
        if (occ < DEPTH) begin
          // Insert keeping descending score / ascending id order (head = best)
          begin
            automatic int insert_at;
            automatic logic found;
            insert_at = int'(occ);
            found     = 1'b0;
            for (int i = 0; i < DEPTH; i++) begin
              if (!found && i < int'(occ) &&
                  beats(score_i, id_i, mem_s[i], mem_id[i])) begin
                insert_at = i;
                found     = 1'b1;
              end
            end
            for (int j = DEPTH - 1; j > 0; j--) begin
              if (j > insert_at && j <= int'(occ)) begin
                mem_s[j]  <= mem_s[j - 1];
                mem_id[j] <= mem_id[j - 1];
              end
            end
            mem_s[insert_at]  <= score_i;
            mem_id[insert_at] <= id_i;
          end
          occ     <= occ + 1'b1;
          count_r <= 8'(occ + 1'b1);
        end else begin
          overflow_r <= 1'b1;
        end
      end
    end
  end

  assign overflow_o = overflow_r;
  assign count_o    = count_r;
endmodule
