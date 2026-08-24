// a7ng_wm_authority.sv — working-memory bank with epoch+generation authority
// Physical payload may linger after QUERY_RESET; authority is stamp match only.
// Law: a7ng-reset-wm-v0. No full-pool wipe (HS-20 / RESET plan §2).
`timescale 1ns / 1ps

module a7ng_wm_authority #(
  parameter int unsigned DEPTH = 32,
  parameter int unsigned DATA_W = 32
) (
  input  logic                 clk,
  input  logic                 rst_n,
  // Active authority (from epoch_mgr)
  input  logic [15:0]          active_query_epoch_i,
  input  logic [31:0]          active_training_generation_i,
  // Write / push into WM
  input  logic                 write_i,
  input  logic [31:0]          node_id_i,
  input  logic [DATA_W-1:0]    payload_i,
  // Logical QUERY/SESSION invalidate: pointer/count reset only (no payload scrub)
  input  logic                 ptr_invalidate_i,
  // Lookup by slot (TB / verify)
  input  logic [$clog2(DEPTH)-1:0] peek_idx_i,
  output logic                 peek_auth_valid_o,
  output logic [31:0]          peek_node_o,
  output logic [DATA_W-1:0]    peek_payload_o,
  // Metrics
  output logic [15:0]          auth_valid_count_o,     // stamp-match authoritative
  output logic [15:0]          physical_valid_count_o, // physical remnant may be >0
  output logic [15:0]          workset_count_o,        // pointer working-set size
  output logic [15:0]          old_generation_visible_count_o
);
  localparam int unsigned IDX_W = $clog2(DEPTH);

  logic              slot_phys_valid [DEPTH];
  logic [15:0]       slot_qepoch     [DEPTH];
  logic [31:0]       slot_tgen       [DEPTH];
  logic [31:0]       slot_node       [DEPTH];
  logic [DATA_W-1:0] slot_payload    [DEPTH];

  logic [IDX_W:0] head;
  logic [IDX_W:0] count;

  logic [15:0] auth_c;
  logic [15:0] phys_c;
  logic [15:0] old_g;

  always_comb begin
    auth_c = 16'd0;
    phys_c = 16'd0;
    old_g  = 16'd0;
    for (int ci = 0; ci < DEPTH; ci++) begin
      if (slot_phys_valid[ci]) begin
        phys_c = phys_c + 16'd1;
        if (slot_tgen[ci] != active_training_generation_i)
          old_g = old_g + 16'd1;
        if ((slot_qepoch[ci] == active_query_epoch_i) &&
            (slot_tgen[ci] == active_training_generation_i))
          auth_c = auth_c + 16'd1;
      end
    end
  end

  assign auth_valid_count_o              = auth_c;
  assign physical_valid_count_o          = phys_c;
  assign workset_count_o                 = { {(16-(IDX_W+1)){1'b0}}, count };
  assign old_generation_visible_count_o  = old_g;

  assign peek_auth_valid_o =
      slot_phys_valid[peek_idx_i] &&
      (slot_qepoch[peek_idx_i] == active_query_epoch_i) &&
      (slot_tgen[peek_idx_i] == active_training_generation_i);
  assign peek_node_o    = slot_node[peek_idx_i];
  assign peek_payload_o = slot_payload[peek_idx_i];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head  <= '0;
      count <= '0;
      for (int ri = 0; ri < DEPTH; ri++) begin
        slot_phys_valid[ri] <= 1'b0;
        slot_qepoch[ri]     <= 16'd0;
        slot_tgen[ri]       <= 32'd0;
        slot_node[ri]       <= 32'd0;
        slot_payload[ri]    <= '0;
      end
    end else begin
      if (ptr_invalidate_i) begin
        // FAST RESET: pointer/count only — payload & phys_valid bits may remain
        head  <= '0;
        count <= '0;
      end
      if (write_i && (count < DEPTH[IDX_W:0])) begin
        slot_phys_valid[head[IDX_W-1:0]] <= 1'b1;
        slot_qepoch[head[IDX_W-1:0]]     <= active_query_epoch_i;
        slot_tgen[head[IDX_W-1:0]]       <= active_training_generation_i;
        slot_node[head[IDX_W-1:0]]       <= node_id_i;
        slot_payload[head[IDX_W-1:0]]    <= payload_i;
        head  <= head + 1'b1;
        count <= count + 1'b1;
      end
    end
  end
endmodule
