// a7ng_bram_hotset.sv — NG-03 BRAM-resident hotset cache (DDR cold path stubbed)
// Law: a7ng-hotset-v0. Records candidate feature lines; miss pulses ddr_req.
`timescale 1ns / 1ps

module a7ng_bram_hotset #(
  parameter int unsigned DEPTH   = 256,
  parameter int unsigned DATA_W  = 64,
  parameter int unsigned ADDR_W  = 8
) (
  input  logic                 clk,
  input  logic                 rst_n,
  // lookup
  input  logic                 lookup_i,
  input  logic [31:0]          node_id_i,
  output logic                 hit_o,
  output logic                 miss_o,
  output logic [DATA_W-1:0]    data_o,
  // fill from DDR (host/MIG later supplies)
  input  logic                 fill_i,
  input  logic [31:0]          fill_id_i,
  input  logic [DATA_W-1:0]    fill_data_i,
  // telemetry
  output logic [31:0]          hits_o,
  output logic [31:0]          misses_o,
  output logic                 ddr_req_o,
  output logic [31:0]          ddr_addr_o
);
  // Simple direct-mapped: index = node_id[ADDR_W-1:0]
  logic [31:0]       tag   [DEPTH];
  logic [DATA_W-1:0] data  [DEPTH];
  logic              valid [DEPTH];

  logic [ADDR_W-1:0] idx;
  assign idx = node_id_i[ADDR_W-1:0];

  logic [ADDR_W-1:0] fill_idx;
  assign fill_idx = fill_id_i[ADDR_W-1:0];

  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hit_o     <= 1'b0;
      miss_o    <= 1'b0;
      data_o    <= '0;
      hits_o    <= 32'd0;
      misses_o  <= 32'd0;
      ddr_req_o <= 1'b0;
      ddr_addr_o<= 32'd0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        tag[i]   <= 32'd0;
        data[i]  <= '0;
        valid[i] <= 1'b0;
      end
    end else begin
      hit_o     <= 1'b0;
      miss_o    <= 1'b0;
      ddr_req_o <= 1'b0;

      if (fill_i) begin
        tag[fill_idx]   <= fill_id_i;
        data[fill_idx]  <= fill_data_i;
        valid[fill_idx] <= 1'b1;
      end

      if (lookup_i) begin
        if (valid[idx] && tag[idx] == node_id_i) begin
          hit_o  <= 1'b1;
          data_o <= data[idx];
          hits_o <= hits_o + 32'd1;
        end else begin
          miss_o     <= 1'b1;
          misses_o   <= misses_o + 32'd1;
          ddr_req_o  <= 1'b1;
          // FPGA-owned address: NodeRecordV1 stride (16 B) — mem_schema_v1; not host-chosen
          // Relative offset only; shard_fetch adds NG_DDR_NODE_BASE via a7ng_node_byte_addr.
          ddr_addr_o <= {5'b0, node_id_i[22:0], 4'b0000};
        end
      end
    end
  end
endmodule
