// a7ng_ddr_store.sv — MEM-01/02 FPGA-owned episode+index address map (law: a7ng-memddr-v0)
// Does not overwrite frozen 01R/02M bits. Host never supplies winning address.
`timescale 1ns / 1ps

module a7ng_ddr_store (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        sel_episode_i, // 1=episode region, 0=index region
  input  logic [15:0] rec_id_i,
  input  logic        req_i,
  output logic        req_valid_o,
  output logic [27:0] ddr_addr_o,
  output logic [31:0] bytes_o
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_valid_o <= 1'b0;
      ddr_addr_o  <= 28'd0;
      bytes_o     <= 32'd0;
    end else begin
      req_valid_o <= 1'b0;
      if (req_i) begin
        req_valid_o <= 1'b1;
        if (sel_episode_i) begin
          ddr_addr_o <= a7ng_episode_byte_addr(NG_DDR_EPISODE_BASE, {16'd0, rec_id_i});
          bytes_o    <= NG_EPISODE_REC_BYTES[31:0];
        end else begin
          // Index companion rows (16 B) — not Node/Edge/EpisodeRecordV1; see MEM_SCHEMA_V1.md
          ddr_addr_o <= NG_DDR_INDEX_BASE + {12'd0, rec_id_i, 4'b0000};
          bytes_o    <= 32'd16;
        end
      end
    end
  end
endmodule
