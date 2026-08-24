// a7ng_wm00_synth_ddr.sv — synthetic DDR graph using mem_schema_v1 Node/Edge records
// FPGA generates addresses (HS-14). Not MIG silicon — WM-00 behavioral store.
`timescale 1ns / 1ps

module a7ng_wm00_synth_ddr #(
  parameter int unsigned N_NODES = 256,
  parameter int unsigned N_EDGES = 256
) (
  input  logic        clk,
  input  logic        rst_n,
  // FPGA-owned node fetch
  input  logic        node_req_i,
  input  logic [31:0] node_id_i,
  output logic        node_valid_o,
  output logic [127:0] node_beat_o,   // NodeRecordV1 = 16 B = one 128b beat
  // FPGA-owned edge fetch
  input  logic        edge_req_i,
  input  logic [31:0] edge_id_i,
  output logic        edge_valid_o,
  output logic [255:0] edge_beat_o,  // EdgeRecordV1 = 32 B
  // learning writeback (EdgeRecordV1 partial)
  input  logic        edge_wr_i,
  input  logic [31:0] edge_wr_id_i,
  input  logic [255:0] edge_wr_beat_i,
  // telemetry
  output logic [31:0] ddr_rd_bytes_o,
  output logic [31:0] ddr_wr_bytes_o,
  output logic [31:0] ddr_rd_count_o,
  output logic [31:0] ddr_wr_count_o
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  // Packed LE NodeRecordV1 / EdgeRecordV1 arrays (LUTRAM/regs — synthetic)
  (* ram_style = "distributed" *) logic [127:0] node_mem [N_NODES];
  (* ram_style = "distributed" *) logic [255:0] edge_mem [N_EDGES];

  function automatic logic [127:0] pack_node(
      input logic [31:0] nid,
      input logic [15:0] ntype,
      input logic [15:0] topic,
      input logic [31:0] cue,
      input logic [15:0] conf,
      input logic [7:0]  deg
  );
    logic [127:0] b;
    b = '0;
    b[31:0]   = nid;
    b[47:32]  = ntype;
    b[63:48]  = topic;
    b[95:64]  = cue;
    b[111:96] = conf;
    b[119:112]= deg;
    b[127:120]= A7NG_MEM_SCHEMA_VERSION[7:0];
    return b;
  endfunction

  function automatic logic [255:0] pack_edge(
      input logic [31:0] src,
      input logic [31:0] dst,
      input logic [15:0] rel,
      input logic signed [15:0] lw,
      input logic signed [15:0] tp
  );
    logic [255:0] b;
    b = '0;
    b[31:0]    = src;
    b[63:32]   = dst;
    b[79:64]   = rel;
    b[95:80]   = 16'd0; // pad0
    b[111:96]  = lw;
    b[127:112] = tp;
    b[143:128] = 16'd0; // pos
    b[159:144] = 16'd0; // neg
    b[191:160] = 32'd0; // last_epoch
    b[207:192] = 16'(A7NG_MEM_SCHEMA_VERSION);
    b[223:208] = 16'd0; // flags
    b[255:224] = 32'd0; // checksum unused
    return b;
  endfunction

  integer i;
  initial begin
    for (i = 0; i < N_NODES; i = i + 1)
      node_mem[i] = pack_node(32'(i), 16'd1, 16'(i[7:0]), 32'hC0E0_0000 + 32'(i), 16'h0100, 8'(i[7:0]));
    for (i = 0; i < N_EDGES; i = i + 1)
      edge_mem[i] = pack_edge(32'(i), 32'((i + 1) % N_NODES), 16'd1, 16'sd10, 16'sd0);
  end

  logic [31:0] rd_b, wr_b, rd_c, wr_c;
  assign ddr_rd_bytes_o = rd_b;
  assign ddr_wr_bytes_o = wr_b;
  assign ddr_rd_count_o = rd_c;
  assign ddr_wr_count_o = wr_c;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      node_valid_o <= 1'b0;
      edge_valid_o <= 1'b0;
      node_beat_o  <= '0;
      edge_beat_o  <= '0;
      rd_b <= 32'd0; wr_b <= 32'd0; rd_c <= 32'd0; wr_c <= 32'd0;
    end else begin
      node_valid_o <= 1'b0;
      edge_valid_o <= 1'b0;
      if (node_req_i) begin
        // HS-14: address from FPGA node_id * 16 via schema helper (byte offset tracked in telemetry)
        node_beat_o  <= node_mem[node_id_i[$clog2(N_NODES)-1:0]];
        node_valid_o <= 1'b1;
        rd_b <= rd_b + A7NG_NODE_REC_BYTES;
        rd_c <= rd_c + 32'd1;
      end
      if (edge_req_i) begin
        edge_beat_o  <= edge_mem[edge_id_i[$clog2(N_EDGES)-1:0]];
        edge_valid_o <= 1'b1;
        rd_b <= rd_b + A7NG_EDGE_REC_BYTES;
        rd_c <= rd_c + 32'd1;
      end
      if (edge_wr_i) begin
        edge_mem[edge_wr_id_i[$clog2(N_EDGES)-1:0]] <= edge_wr_beat_i;
        wr_b <= wr_b + A7NG_EDGE_REC_BYTES;
        wr_c <= wr_c + 32'd1;
      end
    end
  end
endmodule
