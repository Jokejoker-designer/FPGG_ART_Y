// a7ng_wm00_frontier.sv — A7-BRAM-WM-00 64-entry frontier (OPEN/HOLD/EXPANDED/PRUNED/STALE)
// Law: a7ng-bram-wm00-v0. PRUNE ≠ delete knowledge (HS-06). LUTRAM.
`timescale 1ns / 1ps

module a7ng_wm00_frontier #(
  parameter int unsigned DEPTH = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] active_query_epoch_i,
  input  logic        push_i,
  input  logic [31:0] node_id_i,
  input  logic [31:0] parent_id_i,
  input  logic [7:0]  depth_i,
  input  logic signed [15:0] score_i,
  input  logic [15:0] conf_i,
  input  logic [2:0]  status_i,       // 0=OPEN 1=HOLD 2=EXPANDED 3=PRUNED 4=STALE
  input  logic [15:0] path_epoch_i,
  input  logic [7:0]  logical_agent_i,
  output logic        ready_o,
  input  logic        pop_i,
  output logic        pop_valid_o,
  output logic [31:0] pop_node_o,
  output logic signed [15:0] pop_score_o,
  output logic [2:0]  pop_status_o,
  output logic [15:0] count_o,
  output logic [31:0] drop_count_o,
  input  logic        ptr_invalidate_i
);
  localparam int unsigned IDX_W = $clog2(DEPTH);
  localparam logic [2:0] ST_OPEN = 3'd0;

  typedef struct packed {
    logic               phys_v;
    logic [15:0]        qepoch;
    logic [15:0]        pepoch;
    logic [7:0]         agent;
    logic [31:0]        node;
    logic [31:0]        parent;
    logic [7:0]         depth;
    logic signed [15:0] score;
    logic [15:0]        conf;
    logic [2:0]         status;
  } fr_t;

  (* ram_style = "distributed" *) fr_t mem [DEPTH];

  logic [IDX_W:0] wr_ptr, rd_ptr, count;
  logic [31:0] drops;

  wire full  = (count == DEPTH[IDX_W:0]);
  wire empty = (count == '0);
  wire do_push = push_i && !full;
  wire do_pop  = pop_i && !empty;
  wire do_drop = push_i && full;

  assign ready_o = !full;
  assign count_o = {{(16-(IDX_W+1)){1'b0}}, count};
  assign drop_count_o = drops;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0; rd_ptr <= '0; count <= '0; drops <= 32'd0;
      pop_valid_o <= 1'b0; pop_node_o <= '0; pop_score_o <= '0; pop_status_o <= ST_OPEN;
      for (int r = 0; r < DEPTH; r++) mem[r] <= '0;
    end else begin
      pop_valid_o <= 1'b0;
      if (ptr_invalidate_i) begin
        wr_ptr <= '0; rd_ptr <= '0; count <= '0;
      end else begin
        if (do_drop) drops <= drops + 32'd1;
        if (do_push) begin
          mem[wr_ptr[IDX_W-1:0]].phys_v <= 1'b1;
          mem[wr_ptr[IDX_W-1:0]].qepoch <= active_query_epoch_i;
          mem[wr_ptr[IDX_W-1:0]].pepoch <= path_epoch_i;
          mem[wr_ptr[IDX_W-1:0]].agent  <= logical_agent_i;
          mem[wr_ptr[IDX_W-1:0]].node   <= node_id_i;
          mem[wr_ptr[IDX_W-1:0]].parent <= parent_id_i;
          mem[wr_ptr[IDX_W-1:0]].depth  <= depth_i;
          mem[wr_ptr[IDX_W-1:0]].score  <= score_i;
          mem[wr_ptr[IDX_W-1:0]].conf   <= conf_i;
          mem[wr_ptr[IDX_W-1:0]].status <= status_i;
          wr_ptr <= wr_ptr + 1'b1;
        end
        if (do_pop) begin
          pop_valid_o <= 1'b1;
          pop_node_o  <= mem[rd_ptr[IDX_W-1:0]].node;
          pop_score_o <= mem[rd_ptr[IDX_W-1:0]].score;
          pop_status_o<= mem[rd_ptr[IDX_W-1:0]].status;
          rd_ptr <= rd_ptr + 1'b1;
        end
        unique case ({do_push, do_pop})
          2'b10: count <= count + 1'b1;
          2'b01: count <= count - 1'b1;
          default: count <= count;
        endcase
      end
    end
  end
endmodule
