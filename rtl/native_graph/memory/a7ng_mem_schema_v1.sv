// a7ng_mem_schema_v1.sv — package body for mem_schema_v1 (include twin: .svh/.h)
`timescale 1ns / 1ps

package a7ng_mem_schema_v1_pkg;
  localparam int unsigned A7NG_MEM_SCHEMA_VERSION = 1;

  localparam int unsigned A7NG_NODE_REC_BYTES    = 16;
  localparam int unsigned A7NG_EDGE_REC_BYTES    = 32;
  localparam int unsigned A7NG_EPISODE_REC_BYTES = 32;

  localparam int unsigned A7NG_NODE_OFF_NODE_ID     = 0;
  localparam int unsigned A7NG_NODE_OFF_NODE_TYPE   = 4;
  localparam int unsigned A7NG_NODE_OFF_TOPIC_ID    = 6;
  localparam int unsigned A7NG_NODE_OFF_CUE         = 8;
  localparam int unsigned A7NG_NODE_OFF_CONFIDENCE  = 12;
  localparam int unsigned A7NG_NODE_OFF_DEGREE_SAT  = 14;
  localparam int unsigned A7NG_NODE_OFF_VERSION     = 15;

  localparam int unsigned A7NG_EDGE_OFF_SRC           = 0;
  localparam int unsigned A7NG_EDGE_OFF_DST           = 4;
  localparam int unsigned A7NG_EDGE_OFF_RELATION      = 8;
  localparam int unsigned A7NG_EDGE_OFF_PAD0          = 10;
  localparam int unsigned A7NG_EDGE_OFF_LEARNED_W     = 12;
  localparam int unsigned A7NG_EDGE_OFF_TEACHER_PRIOR = 14;
  localparam int unsigned A7NG_EDGE_OFF_POS_COUNT     = 16;
  localparam int unsigned A7NG_EDGE_OFF_NEG_COUNT     = 18;
  localparam int unsigned A7NG_EDGE_OFF_LAST_EPOCH    = 20;
  localparam int unsigned A7NG_EDGE_OFF_VERSION       = 24;
  localparam int unsigned A7NG_EDGE_OFF_FLAGS         = 26;
  localparam int unsigned A7NG_EDGE_OFF_CHECKSUM      = 28;

  localparam int unsigned A7NG_EP_OFF_EPISODE_ID   = 0;
  localparam int unsigned A7NG_EP_OFF_SUBJECT      = 4;
  localparam int unsigned A7NG_EP_OFF_RELATION     = 8;
  localparam int unsigned A7NG_EP_OFF_OBJECT       = 12;
  localparam int unsigned A7NG_EP_OFF_CONTEXT      = 16;
  localparam int unsigned A7NG_EP_OFF_SOURCE_REF   = 20;
  localparam int unsigned A7NG_EP_OFF_ANSWER_REF   = 24;
  localparam int unsigned A7NG_EP_OFF_CONFIDENCE   = 28;
  localparam int unsigned A7NG_EP_OFF_VERSION      = 30;
  localparam int unsigned A7NG_EP_OFF_FLAGS        = 31;

  // Power-of-two strides: node<<4, edge/episode<<5
  function automatic logic [27:0] a7ng_node_byte_addr(
      input logic [27:0] base,
      input logic [31:0] node_id
  );
    return base + {node_id[23:0], 4'b0000};
  endfunction

  function automatic logic [27:0] a7ng_edge_byte_addr(
      input logic [27:0] base,
      input logic [31:0] edge_id
  );
    return base + {edge_id[22:0], 5'b00000};
  endfunction

  function automatic logic [27:0] a7ng_episode_byte_addr(
      input logic [27:0] base,
      input logic [31:0] episode_id
  );
    return base + {episode_id[22:0], 5'b00000};
  endfunction
endpackage
