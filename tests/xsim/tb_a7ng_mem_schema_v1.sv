// tb_a7ng_mem_schema_v1.sv — golden address/size check (UNIT=record id, not cycles)
`timescale 1ns / 1ps

module tb_a7ng_mem_schema_v1;
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  integer fails;
  logic [27:0] a;

  initial begin
    fails = 0;
    if (A7NG_MEM_SCHEMA_VERSION !== 1) fails = fails + 1;
    if (A7NG_NODE_REC_BYTES !== 16) fails = fails + 1;
    if (A7NG_EDGE_REC_BYTES !== 32) fails = fails + 1;
    if (A7NG_EPISODE_REC_BYTES !== 32) fails = fails + 1;
    if (NG_NODE_REC_BYTES !== A7NG_NODE_REC_BYTES) fails = fails + 1;
    if (NG_EDGE_REC_BYTES !== A7NG_EDGE_REC_BYTES) fails = fails + 1;
    if (NG_EPISODE_REC_BYTES !== A7NG_EPISODE_REC_BYTES) fails = fails + 1;

    a = a7ng_node_byte_addr(NG_DDR_NODE_BASE, 32'd7);
    if (a !== (NG_DDR_NODE_BASE + {24'd7, 4'b0000})) begin
      $display("FAIL node addr %h", a); fails = fails + 1;
    end
    a = a7ng_edge_byte_addr(NG_DDR_EDGE_BASE, 32'd7);
    if (a !== (NG_DDR_EDGE_BASE + {23'd7, 5'b00000})) begin
      $display("FAIL edge addr %h", a); fails = fails + 1;
    end
    a = a7ng_episode_byte_addr(NG_DDR_EPISODE_BASE, 32'd7);
    if (a !== (NG_DDR_EPISODE_BASE + {23'd7, 5'b00000})) begin
      $display("FAIL episode addr %h", a); fails = fails + 1;
    end

    if (fails == 0) $display("A7NG_MEM_SCHEMA_V1_SV_GOLDEN_PASS");
    else $display("A7NG_MEM_SCHEMA_V1_SV_GOLDEN_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
