// a7ng_wm00_pe_iface.sv — 16 physical PE read ports over candidate WM (HS-09 honesty)
// Law: a7ng-bram-wm00-v0. Pull: req → pop → load on valid. Measures lane util.
`timescale 1ns / 1ps

module a7ng_wm00_pe_iface #(
  parameter int unsigned N_PE = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        cand_valid_i,
  input  logic [31:0] cand_node_i,
  input  logic signed [15:0] cand_score_i,
  input  logic [31:0] cand_cue_i,
  output logic        cand_pop_o,
  input  logic [N_PE-1:0] pe_req_i,
  output logic [N_PE-1:0] pe_grant_o,
  output logic [31:0]     pe_node_o  [N_PE],
  output logic signed [15:0] pe_score_o [N_PE],
  output logic [31:0]     pe_cue_o   [N_PE],
  output logic [N_PE-1:0] pe_valid_o,
  output logic [31:0] lane_busy_acc_o [N_PE],
  output logic [31:0] grant_count_o,
  output logic [31:0] cycles_o,
  output logic [15:0] active_lanes_o
);
  logic [3:0] rr;
  logic [31:0] busy_acc [N_PE];
  logic [31:0] grants, cycles;
  logic [N_PE-1:0] grant;
  logic [N_PE-1:0] slot_v;
  logic [31:0] slot_node [N_PE];
  logic signed [15:0] slot_score [N_PE];
  logic [31:0] slot_cue [N_PE];
  logic        pending;
  logic [3:0]  pending_pe;

  assign pe_grant_o = grant;
  assign pe_valid_o = slot_v;
  assign grant_count_o = grants;
  assign cycles_o = cycles;

  integer li;
  always_comb begin
    for (li = 0; li < N_PE; li++) begin
      pe_node_o[li]  = slot_node[li];
      pe_score_o[li] = slot_score[li];
      pe_cue_o[li]   = slot_cue[li];
      lane_busy_acc_o[li] = busy_acc[li];
    end
  end

  logic [15:0] act;
  always_comb begin
    act = 16'd0;
    for (int aj = 0; aj < N_PE; aj++)
      if (slot_v[aj]) act = act + 16'd1;
  end
  assign active_lanes_o = act;

  // Choose next PE that requests and has empty slot
  logic [3:0] pick;
  logic       found;
  always_comb begin
    found = 1'b0;
    pick  = rr;
    for (int k = 0; k < N_PE; k++) begin
      logic [3:0] idx;
      idx = rr + 4'(k);
      if (!found && pe_req_i[idx] && !slot_v[idx]) begin
        found = 1'b1;
        pick  = idx;
      end
    end
  end

  assign cand_pop_o = found && !pending;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr <= 4'd0;
      grants <= 32'd0;
      cycles <= 32'd0;
      slot_v <= '0;
      grant <= '0;
      pending <= 1'b0;
      pending_pe <= 4'd0;
      for (int i = 0; i < N_PE; i++) begin
        busy_acc[i] <= 32'd0;
        slot_node[i] <= '0;
        slot_score[i] <= '0;
        slot_cue[i] <= '0;
      end
    end else begin
      cycles <= cycles + 32'd1;
      grant  <= '0;
      for (int i = 0; i < N_PE; i++)
        if (slot_v[i] || pe_req_i[i])
          busy_acc[i] <= busy_acc[i] + 32'd1;

      if (cand_pop_o) begin
        pending    <= 1'b1;
        pending_pe <= pick;
      end

      if (pending && cand_valid_i) begin
        slot_v[pending_pe]     <= 1'b1;
        slot_node[pending_pe]  <= cand_node_i;
        slot_score[pending_pe] <= cand_score_i;
        slot_cue[pending_pe]   <= cand_cue_i;
        grant[pending_pe]      <= 1'b1;
        grants <= grants + 32'd1;
        rr <= pending_pe + 4'd1;
        pending <= 1'b0;
      end

      for (int i = 0; i < N_PE; i++) begin
        if (slot_v[i] && !pe_req_i[i])
          slot_v[i] <= 1'b0;
      end
    end
  end
endmodule
