// a7ng_shard_fetch.sv — NG-03 miss → FPGA-owned AXI read → BRAM hotset fill
// Law: a7ng-hotset-v0. HS-13/14: no full-graph scan; host never picks address.
`timescale 1ns / 1ps

module a7ng_shard_fetch (
  input  logic         clk,
  input  logic         rst_n,
  // query
  input  logic         query_i,
  input  logic [31:0]  node_id_i,
  output logic         busy_o,
  output logic         done_o,
  output logic         hit_o,
  output logic [63:0]  data_o,
  // telemetry (cumulative)
  output logic [31:0]  hits_o,
  output logic [31:0]  misses_o,
  output logic [31:0]  candidates_o,
  output logic [31:0]  ddr_read_bytes_o,
  output logic [31:0]  ddr_bursts_o,
  // AXI4 read master (128-bit, matches Digilent MIG)
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
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  logic hs_lookup, hs_fill, hs_hit, hs_miss, hs_ddr_req;
  logic [31:0] hs_nid, hs_fill_id, hs_hits, hs_misses, hs_ddr_addr;
  logic [63:0] hs_data, hs_fill_data;

  a7ng_bram_hotset #(
    .DEPTH(NG_HOTSET_DEPTH),
    .DATA_W(64),
    .ADDR_W(8)
  ) u_hot (
    .clk(clk), .rst_n(rst_n),
    .lookup_i(hs_lookup), .node_id_i(hs_nid),
    .hit_o(hs_hit), .miss_o(hs_miss), .data_o(hs_data),
    .fill_i(hs_fill), .fill_id_i(hs_fill_id), .fill_data_i(hs_fill_data),
    .hits_o(hs_hits), .misses_o(hs_misses),
    .ddr_req_o(hs_ddr_req), .ddr_addr_o(hs_ddr_addr)
  );

  typedef enum logic [2:0] {ST_IDLE, ST_LOOKUP, ST_CHECK, ST_AR, ST_R, ST_FILL, ST_DONE} st_t;
  st_t st;
  logic [31:0] pending_id;
  logic [127:0] beat_q;

  assign m_axi_arid    = 4'd0;
  assign m_axi_arlen   = 8'd0;   // single 16B beat — bounded, not full scan
  assign m_axi_arsize  = 3'd4;   // 16 bytes
  assign m_axi_arburst = 2'b01;  // INCR
  assign busy_o = (st != ST_IDLE) && (st != ST_DONE);

  // FPGA address: region base + node_id * NodeRecordV1 (mem_schema_v1; ignores host)
  function automatic logic [27:0] node_axi_addr(input logic [31:0] nid);
    return a7ng_node_byte_addr(NG_DDR_NODE_BASE, nid);
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE;
      hs_lookup <= 1'b0;
      hs_fill   <= 1'b0;
      hs_nid    <= '0;
      hs_fill_id <= '0;
      hs_fill_data <= '0;
      pending_id <= '0;
      beat_q <= '0;
      done_o <= 1'b0;
      hit_o  <= 1'b0;
      data_o <= '0;
      hits_o <= '0;
      misses_o <= '0;
      candidates_o <= '0;
      ddr_read_bytes_o <= '0;
      ddr_bursts_o <= '0;
      m_axi_araddr <= '0;
      m_axi_arvalid <= 1'b0;
      m_axi_rready <= 1'b0;
    end else begin
      hs_lookup <= 1'b0;
      hs_fill   <= 1'b0;
      done_o    <= 1'b0;

      unique case (st)
        ST_IDLE: if (query_i) begin
          pending_id   <= node_id_i;
          candidates_o <= candidates_o + 32'd1;
          hs_nid       <= node_id_i;
          hs_lookup    <= 1'b1;
          st           <= ST_LOOKUP;
        end

        // wait one cycle for hotset registered hit/miss
        ST_LOOKUP: st <= ST_CHECK;

        ST_CHECK: begin
          hits_o   <= hs_hits;
          misses_o <= hs_misses;
          if (hs_hit) begin
            hit_o  <= 1'b1;
            data_o <= hs_data;
            st     <= ST_DONE;
          end else begin
            hit_o         <= 1'b0;
            m_axi_araddr  <= node_axi_addr(pending_id);
            m_axi_arvalid <= 1'b1;
            st            <= ST_AR;
          end
        end

        ST_AR: begin
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b1;
            ddr_bursts_o  <= ddr_bursts_o + 32'd1;
            st <= ST_R;
          end
        end

        ST_R: begin
          if (m_axi_rvalid && m_axi_rready) begin
            beat_q <= (m_axi_rresp == 2'b00) ? m_axi_rdata : 128'd0;
            ddr_read_bytes_o <= ddr_read_bytes_o + NG_SHARD_FETCH_B[31:0];
            m_axi_rready <= 1'b0;
            st <= ST_FILL;
          end
        end

        ST_FILL: begin
          hs_fill      <= 1'b1;
          hs_fill_id   <= pending_id;
          hs_fill_data <= beat_q[63:0];
          data_o       <= beat_q[63:0];
          st           <= ST_DONE;
        end

        ST_DONE: begin
          done_o <= 1'b1;
          st <= ST_IDLE;
        end

        default: st <= ST_IDLE;
      endcase
    end
  end
endmodule
