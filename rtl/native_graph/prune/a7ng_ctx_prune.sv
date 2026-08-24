// a7ng_ctx_prune.sv — NG-04 path-local contextual prune + NG-06R-EPOCH stale gate
// Law: a7ng-prune-ctx-v0 + fire_query_epoch DROP_STALE (HS-06/07).
// Bomb clears current path mask only; node stays alive for other queries/paths.
// Stale fire (fire_query_epoch != active) → DROP_STALE; no path/mask mutate; no node ban.
`timescale 1ns / 1ps

module a7ng_ctx_prune (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] query_id_i,
  input  logic [15:0] query_epoch_i,      // stamped into active on new_query
  input  logic [7:0]  path_id_i,
  input  logic [15:0] path_epoch_i,       // carried; active path epoch set on new_query
  input  logic [31:0] node_id_i,
  input  logic [1:0]  outcome_i,          // 00 safe, 01 weak, 10 bomb, 11 reserved
  input  logic        fire_i,
  input  logic [15:0] fire_query_epoch_i, // must match active_query_epoch
  input  logic [15:0] fire_path_epoch_i,  // must match active_path_epoch
  input  logic        clear_path_i,
  input  logic        new_query_i,
  output logic [7:0]  path_mask_o,        // 1 = path still expandable
  output logic        pruned_o,
  output logic        expand_ok_o,
  output logic        node_alive_o,       // always 1 after bomb — no permanent node ban
  output logic [15:0] active_query_epoch_o,
  output logic [15:0] active_path_epoch_o,
  output logic [31:0] drop_stale_o,
  output logic        stale_drop_pulse_o
);
  localparam logic [1:0] OUT_SAFE = 2'b00;
  localparam logic [1:0] OUT_WEAK = 2'b01;
  localparam logic [1:0] OUT_BOMB = 2'b10;

  logic [7:0]  path_mask;
  logic        pruned_q;
  logic [15:0] active_q_epoch;
  logic [15:0] active_p_epoch;
  logic [31:0] drop_stale_cnt;
  logic        stale_pulse;

  assign path_mask_o          = path_mask;
  assign pruned_o             = pruned_q;
  assign node_alive_o         = 1'b1; // HS-06: contextual prune ≠ node blacklist
  assign expand_ok_o          = path_mask[path_id_i[2:0]];
  assign active_query_epoch_o = active_q_epoch;
  assign active_path_epoch_o  = active_p_epoch;
  assign drop_stale_o         = drop_stale_cnt;
  assign stale_drop_pulse_o   = stale_pulse;

  logic [31:0] last_node;
  logic [15:0] active_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_q        <= 16'd0;
      active_q_epoch  <= 16'd1;
      active_p_epoch  <= 16'd1;
      path_mask       <= 8'hFF;
      pruned_q        <= 1'b0;
      last_node       <= 32'd0;
      drop_stale_cnt  <= 32'd0;
      stale_pulse     <= 1'b0;
    end else begin
      pruned_q    <= 1'b0;
      stale_pulse <= 1'b0;

      if (new_query_i) begin
        active_q       <= query_id_i;
        active_q_epoch <= query_epoch_i;
        active_p_epoch <= path_epoch_i;
        path_mask      <= 8'hFF; // fresh query restores paths; nodes stay alive (HS-06/07)
        // intentionally NO wipe of unrelated learned priors / node ban table
      end

      if (clear_path_i) begin
        path_mask[path_id_i[2:0]] <= 1'b1;
      end

      if (fire_i) begin
        // DROP_STALE: mismatch on query or path epoch — ignore fire, no semantic kill
        if ((fire_query_epoch_i != active_q_epoch) ||
            (fire_path_epoch_i  != active_p_epoch)) begin
          drop_stale_cnt <= drop_stale_cnt + 32'd1;
          stale_pulse    <= 1'b1;
        end else begin
          last_node <= node_id_i;
          if (outcome_i == OUT_BOMB) begin
            path_mask[path_id_i[2:0]] <= 1'b0;
            pruned_q <= 1'b1;
            // intentionally NO node ban table write
          end else if (outcome_i == OUT_SAFE || outcome_i == OUT_WEAK) begin
            path_mask[path_id_i[2:0]] <= 1'b1;
          end
        end
      end
    end
  end
endmodule
