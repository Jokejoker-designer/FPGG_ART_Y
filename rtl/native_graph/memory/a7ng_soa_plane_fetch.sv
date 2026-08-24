// a7ng_soa_plane_fetch.sv — thin wrapper over proven a7ng_soa_plane_engine (cue_wavefront clone)
// Gate: ddr_cue_soa_00r_axi_liveness attempt 7.
`timescale 1ns / 1ps

module a7ng_soa_plane_fetch #(
  parameter int unsigned MAX_BEATS  = 52,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [27:0]  base_byte_i,
  input  logic [5:0]   beat_target_i,
  output logic         ar_valid_o,
  input  logic         ar_ready_i,
  output logic [27:0]  ar_addr_o,
  output logic [7:0]   ar_len_o,
  output logic [3:0]   ar_id_o,
  output logic [2:0]   ar_size_o,
  input  logic         r_valid_i,
  output logic         r_ready_o,
  input  logic [127:0] r_data_i,
  input  logic         r_last_i,
  output logic [127:0] beat_data_o [MAX_BEATS],
  output logic         running_o,
  output logic         done_o,
  output logic         done_pulse_o,
  output logic [5:0]   beats_returned_o,
  output logic [5:0]   beats_issued_o,
  output logic         idle_o
);
  a7ng_soa_plane_engine #(
    .MAX_BEATS(MAX_BEATS), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_eng (
    .clk(clk), .rst_n(rst_n),
    .start_i(start_i),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
    .base_byte_i(base_byte_i), .beat_target_i(beat_target_i),
    .ar_valid_o(ar_valid_o), .ar_ready_i(ar_ready_i),
    .ar_addr_o(ar_addr_o), .ar_len_o(ar_len_o),
    .ar_id_o(ar_id_o), .ar_size_o(ar_size_o),
    .r_valid_i(r_valid_i), .r_ready_o(r_ready_o),
    .r_data_i(r_data_i), .r_last_i(r_last_i),
    .beat_data_o(beat_data_o),
    .running_o(running_o), .done_o(done_o),
    .done_pulse_o(done_pulse_o),
    .beats_returned_o(beats_returned_o),
    .beats_issued_o(beats_issued_o),
    .idle_o(idle_o),
    .ar_txns_o()
  );
endmodule
