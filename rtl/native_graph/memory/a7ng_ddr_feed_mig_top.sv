// a7ng_ddr_feed_mig_top.sv — ddr_feed ping-pong + PE pull on Digilent AXI MIG ui_clk
// Law: a7ng-mig-rival-v0 (+ mig_metric_00 integrity at PE consume). No LM-06. N_PE=16 frozen.
// Evidence class: MIG_XSIM or BOARD only — never claim BOARD_PASS from synthetic CONTROL.
`timescale 1ns / 1ps

module a7ng_ddr_feed_mig_top #(
  parameter int unsigned BANK_DEPTH = 32,
  parameter int unsigned N_PE       = 16,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic         clk,      // MIG ui_clk
  input  logic         rst_n,    // ~ui_clk_sync_rst && calib
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  input  logic [N_PE-1:0] pe_req_i,
  output logic         done_o,
  output logic         running_o,
  output logic [31:0]  empty_stall_o,
  output logic [31:0]  full_stall_o,
  output logic [31:0]  pe_stall_o,
  output logic [31:0]  pe_busy_o,
  output logic [31:0]  cycles_o,
  output logic [31:0]  recs_consumed_o,
  output logic [31:0]  drop_o,   // legacy pp backpressure tick — NOT lost-data DROP
  output logic [15:0]  occ_active_o,
  output logic [15:0]  occ_fill_o,
  output logic         active_bank_o,
  output logic [31:0]  ddr_rd_bytes_o,
  output logic [31:0]  ddr_rd_count_o,
  output logic [31:0]  ddr_burst_count_o,
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  data_mismatch_count_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  expected_records_o,
  output logic [31:0]  received_records_o,
  output logic [31:0]  consumed_records_o,
  output logic [3:0]   rid_observed_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o,
  output logic [31:0]  pe_data_mismatch_count_o,
  output logic [127:0] pe_data_o,
  output logic [31:0]  expect_nid_o,
  output logic [N_PE-1:0] pe_grant_o,
  output logic [31:0]  pe_grant_count_o,
  // Digilent AXI MIG read master
  output logic [3:0]   m_axi_arid,
  output logic [27:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [3:0]   m_axi_rid,
  input  logic [127:0] m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready
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
  logic [31:0] br_mm;
  logic [31:0] pe_mm;
  logic [31:0] expect_nid;
  logic [31:0] axi_bytes, axi_bursts, axi_beats;

  // Clear bridge per-run counters on cell start (feed law unchanged)
  wire metric_clear = start_i;

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

  a7ng_ddr_feed_axi_bridge u_br (
    .clk(clk), .rst_n(rst_n),
    .metric_clear_i(metric_clear),
    .ar_valid_i(ar_valid), .ar_ready_o(ar_ready),
    .ar_addr_i(ar_addr), .ar_len_i(ar_len), .ar_id_i(ar_id),
    .r_valid_o(r_valid), .r_ready_i(r_ready),
    .r_data_o(r_data), .r_last_o(r_last), .r_id_o(r_id),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .ddr_rd_bytes_o(ddr_rd_bytes_o),
    .ddr_rd_count_o(ddr_rd_count_o),
    .ddr_burst_count_o(ddr_burst_count_o),
    .axi_read_bytes_o(axi_bytes),
    .axi_read_bursts_o(axi_bursts),
    .axi_read_beats_o(axi_beats),
    .data_mismatch_count_o(br_mm),
    .rresp_error_count_o(rresp_error_count_o),
    .rlast_error_count_o(rlast_error_count_o),
    .expected_records_o(expected_records_o),
    .received_records_o(received_records_o),
    .rid_observed_o(rid_observed_o),
    .rid_order_error_o(rid_order_error_o),
    .r_backpressure_cycles_o(r_backpressure_cycles_o)
  );

  assign axi_read_bytes_o  = axi_bytes;
  assign axi_read_bursts_o = axi_bursts;
  assign axi_read_beats_o  = axi_beats;
  assign consumed_records_o = recs_consumed_o;
  assign pe_data_mismatch_count_o = pe_mm;
  assign pe_data_o         = pe_data;
  assign expect_nid_o      = expect_nid;
  // Conservation = AXI beat + PE consume mismatches (sum; both should be 0)
  assign data_mismatch_count_o = br_mm + pe_mm;

  logic [3:0]  rr;
  logic [31:0] grants;
  logic [N_PE-1:0] grant;
  logic [3:0] pick;
  logic       found;

  assign pe_grant_o       = grant;
  assign pe_grant_count_o = grants;

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

  assign pe_pop = found;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr <= 4'd0;
      grants <= 32'd0;
      grant <= '0;
      pe_mm <= 32'd0;
      expect_nid <= 32'd0;
    end else if (start_i) begin
      rr <= 4'd0;
      grants <= 32'd0;
      grant <= '0;
      pe_mm <= 32'd0;
      expect_nid <= base_node_i;
    end else begin
      grant <= '0;
      if (found && pe_valid) begin
        grant[pick] <= 1'b1;
        grants <= grants + 32'd1;
        rr <= pick + 4'd1;
        // Verify NodeRecordV1.node_id at service consumption
        if (pe_data[31:0] != expect_nid)
          pe_mm <= pe_mm + 32'd1;
        expect_nid <= expect_nid + 32'd1;
      end
    end
  end
endmodule
