// a7ng_wm00_owner.sv — single BRAM bank owner (GRAPH | LM | RESET). Dual-write → FAIL.
// WM-00: LM phase never granted (no LM-06). Law: a7ng-bram-wm00-v0.
`timescale 1ns / 1ps

module a7ng_wm00_owner (
  input  logic       clk,
  input  logic       rst_n,
  // request ports (exactly one granted writer)
  input  logic       graph_wr_req_i,
  input  logic       lm_wr_req_i,     // must stay 0 in WM-00 bags
  input  logic       reset_wr_req_i,
  output logic [1:0] owner_o,         // 0=GRAPH 1=LM 2=RESET 3=NONE
  output logic       dual_owner_err_o,
  output logic [31:0] dual_owner_count_o,
  output logic       lm_grant_o       // always 0 this gate
);
  localparam logic [1:0] OWN_GRAPH = 2'd0;
  localparam logic [1:0] OWN_LM    = 2'd1;
  localparam logic [1:0] OWN_RESET = 2'd2;
  localparam logic [1:0] OWN_NONE  = 2'd3;

  logic [1:0] owner;
  logic       dual_err;
  logic [31:0] dual_cnt;

  assign owner_o = owner;
  assign dual_owner_err_o = dual_err;
  assign dual_owner_count_o = dual_cnt;
  assign lm_grant_o = 1'b0; // WM-00 hard: never grant LM

  wire [2:0] reqs = {reset_wr_req_i, lm_wr_req_i, graph_wr_req_i};
  wire multi = (reqs[0] + reqs[1] + reqs[2]) > 2'd1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      owner    <= OWN_NONE;
      dual_err <= 1'b0;
      dual_cnt <= 32'd0;
    end else begin
      if (multi) begin
        dual_err <= 1'b1;
        dual_cnt <= dual_cnt + 32'd1;
        owner    <= OWN_NONE; // no grant on conflict
      end else if (reset_wr_req_i) begin
        owner <= OWN_RESET;
      end else if (lm_wr_req_i) begin
        // refused — sticky dual/illegal for WM-00 (LM not in experiment)
        dual_err <= 1'b1;
        dual_cnt <= dual_cnt + 32'd1;
        owner    <= OWN_NONE;
      end else if (graph_wr_req_i) begin
        owner <= OWN_GRAPH;
      end else begin
        owner <= OWN_NONE;
      end
    end
  end
endmodule
