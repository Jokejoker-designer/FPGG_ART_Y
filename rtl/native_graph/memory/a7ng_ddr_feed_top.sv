// a7ng_ddr_feed_top.sv — A7-BRAM-WM-01 / ddr_feed glue: ping-pong + lat DDR + PE pull
// Builds on WM-00; no LM-06; no PE count increase. Law: a7ng-ddr-feed-wm01-v0.
`timescale 1ns / 1ps

module a7ng_ddr_feed_top #(
  parameter int unsigned N_NODES    = 1024,
  parameter int unsigned BANK_DEPTH = 32,
  parameter int unsigned N_PE       = 16,
  parameter int unsigned LATENCY    = 24,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [4:0]  burst_i,
  input  logic [3:0]  outstanding_i,
  input  logic [31:0] base_node_i,
  input  logic [31:0] total_recs_i,
  input  logic [N_PE-1:0] pe_req_i,
  output logic        done_o,
  output logic        running_o,
  output logic [31:0] empty_stall_o,
  output logic [31:0] full_stall_o,
  output logic [31:0] pe_stall_o,
  output logic [31:0] pe_busy_o,
  output logic [31:0] cycles_o,
  output logic [31:0] recs_consumed_o,
  output logic [31:0] drop_o,
  output logic [15:0] occ_active_o,
  output logic [15:0] occ_fill_o,
  output logic        active_bank_o,
  output logic [31:0] ddr_rd_bytes_o,
  output logic [31:0] ddr_rd_count_o,
  output logic [31:0] ddr_burst_count_o,
  output logic [7:0]  ddr_outstanding_o,
  output logic [N_PE-1:0] pe_grant_o,
  output logic [31:0] pe_grant_count_o
);
  logic        ar_valid, ar_ready;
  logic [31:0] ar_addr;
  logic [7:0]  ar_len;
  logic [3:0]  ar_id;
  logic        r_valid, r_ready, r_last;
  logic [127:0] r_data;
  logic [3:0]  r_id;
  logic        pe_pop, pe_valid;
  logic [127:0] pe_data;

  a7ng_ddr_feed_lat_ddr #(
    .N_NODES(N_NODES), .LATENCY(LATENCY), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_ddr (
    .clk(clk), .rst_n(rst_n),
    .ar_valid_i(ar_valid), .ar_ready_o(ar_ready),
    .ar_addr_i(ar_addr), .ar_len_i(ar_len), .ar_id_i(ar_id),
    .r_valid_o(r_valid), .r_ready_i(r_ready),
    .r_data_o(r_data), .r_last_o(r_last), .r_id_o(r_id),
    .ddr_rd_bytes_o(ddr_rd_bytes_o),
    .ddr_rd_count_o(ddr_rd_count_o),
    .ddr_burst_count_o(ddr_burst_count_o),
    .outstanding_o(ddr_outstanding_o)
  );

  a7ng_ddr_feed_pp #(
    .BANK_DEPTH(BANK_DEPTH), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_pp (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_i),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_node_i(base_node_i), .total_recs_i(total_recs_i),
    .ar_valid_o(ar_valid), .ar_ready_i(ar_ready),
    .ar_addr_o(ar_addr), .ar_len_o(ar_len), .ar_id_o(ar_id),
    .r_valid_i(r_valid), .r_ready_o(r_ready),
    .r_data_i(r_data), .r_last_i(r_last),
    .pe_pop_i(pe_pop), .pe_valid_o(pe_valid), .pe_data_o(pe_data),
    .done_o(done_o), .running_o(running_o),
    .empty_stall_o(empty_stall_o), .full_stall_o(full_stall_o),
    .pe_stall_o(pe_stall_o), .pe_busy_o(pe_busy_o),
    .cycles_o(cycles_o), .recs_consumed_o(recs_consumed_o),
    .drop_o(drop_o),
    .occ_active_o(occ_active_o), .occ_fill_o(occ_fill_o),
    .active_bank_o(active_bank_o)
  );

  // PE pull: any requesting lane may take one record/cycle when buffer valid.
  // N_PE stays 16 (no PE increase this gate). Round-robin grant for telemetry.
  logic [3:0]  rr;
  logic [31:0] grants;
  logic [N_PE-1:0] grant;

  assign pe_grant_o       = grant;
  assign pe_grant_count_o = grants;

  logic [3:0] pick;
  logic       found;
  always_comb begin
    found = 1'b0;
    pick  = rr;
    for (int k = 0; k < N_PE; k++) begin
      logic [3:0] idx;
      idx = rr + 4'(k);
      if (!found && pe_req_i[idx]) begin
        found = 1'b1;
        pick  = idx;
      end
    end
  end

  // pe_pop = PE wants a record (stall counted in pp when !pe_valid)
  assign pe_pop = found;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr <= 4'd0;
      grants <= 32'd0;
      grant <= '0;
    end else begin
      grant <= '0;
      if (found && pe_valid) begin
        grant[pick] <= 1'b1;
        grants <= grants + 32'd1;
        rr <= pick + 4'd1;
      end
    end
  end

  wire _unused = |pe_data | (|r_id);
endmodule
