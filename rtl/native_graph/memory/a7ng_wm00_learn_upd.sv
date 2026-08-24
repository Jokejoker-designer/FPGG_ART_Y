// a7ng_wm00_learn_upd.sv — A7-BRAM-WM-00 32-entry learning update coalesce buffer
// Law: a7ng-bram-wm00-v0. Coalesce before DDR writeback. LUTRAM. No silent overwrite.
`timescale 1ns / 1ps

module a7ng_wm00_learn_upd #(
  parameter int unsigned DEPTH = 32
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] active_query_epoch_i,
  input  logic        push_i,
  input  logic [31:0] subject_i,
  input  logic [15:0] relation_i,
  input  logic [31:0] object_i,
  input  logic signed [15:0] delta_i,
  input  logic [15:0] evidence_count_i,
  input  logic signed [7:0] teacher_reward_i,
  input  logic [15:0] native_conf_i,
  output logic        ready_o,
  // drain one dirty entry for DDR writeback
  input  logic        drain_i,
  output logic        drain_valid_o,
  output logic [31:0] drain_subject_o,
  output logic [15:0] drain_relation_o,
  output logic [31:0] drain_object_o,
  output logic signed [15:0] drain_delta_o,
  output logic [15:0] count_o,
  output logic [15:0] dirty_count_o,
  output logic [31:0] drop_count_o,
  output logic [31:0] coalesce_hits_o,
  input  logic        ptr_invalidate_i
);
  localparam int unsigned IDX_W = $clog2(DEPTH);

  typedef struct packed {
    logic               phys_v;
    logic               dirty;
    logic [15:0]        qepoch;
    logic [31:0]        subject;
    logic [15:0]        rel;
    logic [31:0]        object;
    logic signed [15:0] delta;
    logic [15:0]        evid;
    logic signed [7:0]  reward;
    logic [15:0]        conf;
  } upd_t;

  (* ram_style = "distributed" *) upd_t mem [DEPTH];

  logic [IDX_W:0] count;
  logic [31:0] drops, coal;
  logic [IDX_W:0] free_idx;
  logic found_coal;
  logic [IDX_W-1:0] coal_idx;
  logic found_free;

  always_comb begin
    found_coal = 1'b0;
    coal_idx   = '0;
    found_free = 1'b0;
    free_idx   = '0;
    for (int i = 0; i < DEPTH; i++) begin
      if (mem[i].phys_v &&
          mem[i].subject == subject_i &&
          mem[i].rel == relation_i &&
          mem[i].object == object_i &&
          mem[i].qepoch == active_query_epoch_i) begin
        found_coal = 1'b1;
        coal_idx   = IDX_W'(i);
      end
      if (!mem[i].phys_v && !found_free) begin
        found_free = 1'b1;
        free_idx   = IDX_W'(i);
      end
    end
  end

  wire can_push = found_coal || found_free;
  assign ready_o = can_push || !push_i; // combinatorial hint; actual DROP on push&&!can

  logic [15:0] dirty_c;
  always_comb begin
    dirty_c = 16'd0;
    for (int i = 0; i < DEPTH; i++)
      if (mem[i].phys_v && mem[i].dirty) dirty_c = dirty_c + 16'd1;
  end
  assign count_o        = {{(16-(IDX_W+1)){1'b0}}, count};
  assign dirty_count_o  = dirty_c;
  assign drop_count_o   = drops;
  assign coalesce_hits_o= coal;

  // drain scan
  logic        d_found;
  logic [IDX_W-1:0] d_idx;
  always_comb begin
    d_found = 1'b0;
    d_idx   = '0;
    for (int i = 0; i < DEPTH; i++) begin
      if (!d_found && mem[i].phys_v && mem[i].dirty) begin
        d_found = 1'b1;
        d_idx   = IDX_W'(i);
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= '0; drops <= 32'd0; coal <= 32'd0;
      drain_valid_o <= 1'b0;
      drain_subject_o <= '0; drain_relation_o <= '0;
      drain_object_o <= '0; drain_delta_o <= '0;
      for (int r = 0; r < DEPTH; r++) mem[r] <= '0;
    end else begin
      drain_valid_o <= 1'b0;
      if (ptr_invalidate_i) begin
        count <= '0;
        for (int r = 0; r < DEPTH; r++) mem[r].dirty <= 1'b0; // invalidate authority; phys may linger
        // clear phys for clean WM-00 bags
        for (int r = 0; r < DEPTH; r++) mem[r] <= '0;
      end else begin
        if (push_i) begin
          if (found_coal) begin
            mem[coal_idx].delta  <= mem[coal_idx].delta + delta_i;
            mem[coal_idx].evid   <= mem[coal_idx].evid + evidence_count_i;
            mem[coal_idx].reward <= teacher_reward_i;
            mem[coal_idx].conf   <= native_conf_i;
            mem[coal_idx].dirty  <= 1'b1;
            coal <= coal + 32'd1;
          end else if (found_free) begin
            mem[free_idx].phys_v  <= 1'b1;
            mem[free_idx].dirty   <= 1'b1;
            mem[free_idx].qepoch  <= active_query_epoch_i;
            mem[free_idx].subject <= subject_i;
            mem[free_idx].rel     <= relation_i;
            mem[free_idx].object  <= object_i;
            mem[free_idx].delta   <= delta_i;
            mem[free_idx].evid    <= evidence_count_i;
            mem[free_idx].reward  <= teacher_reward_i;
            mem[free_idx].conf    <= native_conf_i;
            count <= count + 1'b1;
          end else begin
            drops <= drops + 32'd1;
          end
        end
        if (drain_i && d_found) begin
          drain_valid_o    <= 1'b1;
          drain_subject_o  <= mem[d_idx].subject;
          drain_relation_o <= mem[d_idx].rel;
          drain_object_o   <= mem[d_idx].object;
          drain_delta_o    <= mem[d_idx].delta;
          mem[d_idx].dirty <= 1'b0;
        end
      end
    end
  end
endmodule
