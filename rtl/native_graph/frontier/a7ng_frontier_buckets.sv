// a7ng_frontier_buckets.sv — NG-02 16-bin score-bucket frontier (no pointer heap)
// Law: a7ng-frontier-v0.
// Overflow: drop push when selected bin is full (intentional prune, flagged).
// NG-02R-FLOW: ready_o for push stall; same-cycle pop+push allowed (no silent drop).
`timescale 1ns / 1ps

module a7ng_frontier_buckets #(
  parameter int unsigned NBINS   = 16,
  parameter int unsigned DEPTH   = 8,
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
  localparam int unsigned PTR_W = $clog2(DEPTH);

  logic [15:0] score_u;
  logic [3:0]  bin_sel;
  assign score_u = score_i + 16'sd32768;
  assign bin_sel = score_u[15:12];

  logic signed [SCORE_W-1:0] mem_s  [NBINS][DEPTH];
  logic [ID_W-1:0]           mem_id [NBINS][DEPTH];
  logic [PTR_W:0]            wr_ptr [NBINS];
  logic [PTR_W:0]            rd_ptr [NBINS];
  logic [PTR_W:0]            occ    [NBINS];

  logic [3:0] hi_bin;
  logic       found;

  always_comb begin
    found  = 1'b0;
    hi_bin = 4'd0;
    for (int b = NBINS - 1; b >= 0; b--) begin
      if (!found && (occ[b] != 0)) begin
        found  = 1'b1;
        hi_bin = 4'(b);
      end
    end
  end

  logic               pop_fire;
  logic               same_bin_pop;
  logic [PTR_W:0]     occ_push_view;
  logic               push_ok;

  assign pop_fire      = pop_i && found;
  assign same_bin_pop  = pop_fire && (hi_bin == bin_sel);
  assign occ_push_view = same_bin_pop ? (occ[bin_sel] - 1'b1) : occ[bin_sel];
  assign push_ok       = push_i && (occ_push_view < DEPTH);
  assign ready_o       = (occ_push_view < DEPTH);

  logic       overflow_r;
  logic [7:0] count_r;
  logic signed [8:0] count_delta;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      overflow_r  <= 1'b0;
      count_r     <= 8'd0;
      pop_valid_o <= 1'b0;
      score_o     <= '0;
      id_o        <= '0;
      for (int b = 0; b < NBINS; b++) begin
        wr_ptr[b] <= '0;
        rd_ptr[b] <= '0;
        occ[b]    <= '0;
        for (int d = 0; d < DEPTH; d++) begin
          mem_s[b][d]  <= '0;
          mem_id[b][d] <= '0;
        end
      end
    end else begin
      count_delta = 9'sd0;
      overflow_r  <= 1'b0;
      pop_valid_o <= 1'b0;

      if (pop_fire) begin
        score_o        <= mem_s[hi_bin][rd_ptr[hi_bin][PTR_W-1:0]];
        id_o           <= mem_id[hi_bin][rd_ptr[hi_bin][PTR_W-1:0]];
        pop_valid_o    <= 1'b1;
        rd_ptr[hi_bin] <= rd_ptr[hi_bin] + 1'b1;
        occ[hi_bin]    <= occ[hi_bin] - 1'b1;
        count_delta    = count_delta - 9'sd1;
      end

      if (push_i) begin
        if (push_ok) begin
          mem_s[bin_sel][wr_ptr[bin_sel][PTR_W-1:0]]  <= score_i;
          mem_id[bin_sel][wr_ptr[bin_sel][PTR_W-1:0]] <= id_i;
          wr_ptr[bin_sel] <= wr_ptr[bin_sel] + 1'b1;
          if (same_bin_pop) begin
            occ[bin_sel] <= occ_push_view + 1'b1;
          end else begin
            occ[bin_sel] <= occ[bin_sel] + 1'b1;
          end
          count_delta = count_delta + 9'sd1;
        end else begin
          overflow_r <= 1'b1;
        end
      end

      count_r <= 8'(count_r + count_delta);
    end
  end

  assign overflow_o = overflow_r;
  assign count_o    = count_r;
endmodule
