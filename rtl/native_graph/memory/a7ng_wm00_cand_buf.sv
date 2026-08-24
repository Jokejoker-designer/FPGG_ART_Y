// a7ng_wm00_cand_buf.sv — A7-BRAM-WM-00 256-entry candidate working-memory
// Law: a7ng-bram-wm00-v0. LUTRAM preferred. No silent overwrite (DROP counted).
`timescale 1ns / 1ps

module a7ng_wm00_cand_buf #(
  parameter int unsigned DEPTH = 256
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] active_query_epoch_i,
  input  logic        push_i,
  input  logic [31:0] node_id_i,
  input  logic [31:0] parent_id_i,
  input  logic [15:0] relation_i,
  input  logic [31:0] cue_i,
  input  logic signed [15:0] base_score_i,
  input  logic [15:0] path_epoch_i,
  input  logic [7:0]  logical_agent_i,
  output logic        ready_o,
  input  logic        pop_i,
  output logic        pop_valid_o,
  output logic [31:0] pop_node_o,
  output logic [31:0] pop_parent_o,
  output logic [15:0] pop_relation_o,
  output logic [31:0] pop_cue_o,
  output logic signed [15:0] pop_score_o,
  output logic [15:0] pop_path_epoch_o,
  output logic [7:0]  pop_logical_agent_o,
  input  logic [$clog2(DEPTH)-1:0] peek_idx_i,
  output logic        peek_auth_o,
  output logic [31:0] peek_node_o,
  output logic signed [15:0] peek_score_o,
  output logic [15:0] count_o,
  output logic [15:0] auth_count_o,
  output logic [31:0] drop_count_o,
  input  logic        ptr_invalidate_i
);
  localparam int unsigned IDX_W = $clog2(DEPTH);

  typedef struct packed {
    logic               phys_v;
    logic [15:0]        qepoch;
    logic [15:0]        pepoch;
    logic [7:0]         agent;
    logic [31:0]        node;
    logic [31:0]        parent;
    logic [15:0]        rel;
    logic [31:0]        cue;
    logic signed [15:0] score;
  } cand_t;

  (* ram_style = "distributed" *) cand_t mem [DEPTH];

  logic [IDX_W:0] wr_ptr;
  logic [IDX_W:0] rd_ptr;
  logic [IDX_W:0] count;
  logic [31:0]    drops;
  logic [15:0]    auth_reg;

  wire full  = (count == DEPTH[IDX_W:0]);
  wire empty = (count == '0);
  wire do_push = push_i && !full;
  wire do_pop  = pop_i && !empty;
  wire do_drop = push_i && full;

  assign ready_o      = !full;
  assign count_o      = {{(16-(IDX_W+1)){1'b0}}, count};
  assign drop_count_o = drops;
  // Incremental auth (avoid 256-wide comb scan — OOC timing)
  assign auth_count_o = auth_reg;

  cand_t peek_e;
  assign peek_e       = mem[peek_idx_i];
  assign peek_auth_o  = peek_e.phys_v && (peek_e.qepoch == active_query_epoch_i);
  assign peek_node_o  = peek_e.node;
  assign peek_score_o = peek_e.score;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr      <= '0;
      rd_ptr      <= '0;
      count       <= '0;
      drops       <= 32'd0;
      auth_reg    <= 16'd0;
      pop_valid_o <= 1'b0;
      pop_node_o  <= '0;
      pop_parent_o<= '0;
      pop_relation_o <= '0;
      pop_cue_o   <= '0;
      pop_score_o <= '0;
      pop_path_epoch_o <= '0;
      pop_logical_agent_o <= '0;
      for (int r = 0; r < DEPTH; r++)
        mem[r] <= '0;
    end else begin
      pop_valid_o <= 1'b0;

      if (ptr_invalidate_i) begin
        wr_ptr   <= '0;
        rd_ptr   <= '0;
        count    <= '0;
        auth_reg <= 16'd0;
      end else begin
        if (do_drop)
          drops <= drops + 32'd1;

        if (do_push) begin
          mem[wr_ptr[IDX_W-1:0]].phys_v <= 1'b1;
          mem[wr_ptr[IDX_W-1:0]].qepoch <= active_query_epoch_i;
          mem[wr_ptr[IDX_W-1:0]].pepoch <= path_epoch_i;
          mem[wr_ptr[IDX_W-1:0]].agent  <= logical_agent_i;
          mem[wr_ptr[IDX_W-1:0]].node   <= node_id_i;
          mem[wr_ptr[IDX_W-1:0]].parent <= parent_id_i;
          mem[wr_ptr[IDX_W-1:0]].rel    <= relation_i;
          mem[wr_ptr[IDX_W-1:0]].cue    <= cue_i;
          mem[wr_ptr[IDX_W-1:0]].score  <= base_score_i;
          wr_ptr   <= wr_ptr + 1'b1;
          auth_reg <= auth_reg + 16'd1;
        end

        if (do_pop) begin
          pop_valid_o <= 1'b1;
          pop_node_o  <= mem[rd_ptr[IDX_W-1:0]].node;
          pop_parent_o<= mem[rd_ptr[IDX_W-1:0]].parent;
          pop_relation_o <= mem[rd_ptr[IDX_W-1:0]].rel;
          pop_cue_o   <= mem[rd_ptr[IDX_W-1:0]].cue;
          pop_score_o <= mem[rd_ptr[IDX_W-1:0]].score;
          pop_path_epoch_o <= mem[rd_ptr[IDX_W-1:0]].pepoch;
          pop_logical_agent_o <= mem[rd_ptr[IDX_W-1:0]].agent;
          rd_ptr <= rd_ptr + 1'b1;
          if (mem[rd_ptr[IDX_W-1:0]].phys_v &&
              (mem[rd_ptr[IDX_W-1:0]].qepoch == active_query_epoch_i) &&
              (auth_reg != 16'd0))
            auth_reg <= auth_reg - 16'd1;
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
