// a7ng_ddr_feed_axi_bridge.sv — node-id AR → Digilent AXI4 128b (HS-14 FPGA addresses)
// Law: a7ng-mig-rival-v0 (+ mig_metric_00 measurement ports). Official Digilent AXI MIG only.
// Converts ddr_feed_pp node indices to NG_DDR_NODE_BASE byte addresses.
// Per-run deltas: metric_clear_i (not only rst_n). RVALID&&!RREADY → r_backpressure_cycles (not DROP).
`timescale 1ns / 1ps

module a7ng_ddr_feed_axi_bridge (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         metric_clear_i,  // pulse: zero per-run telemetry (idle between cells)
  // from a7ng_ddr_feed_pp (node-id AR / beat R)
  input  logic         ar_valid_i,
  output logic         ar_ready_o,
  input  logic [31:0]  ar_addr_i,   // node id (not byte)
  input  logic [7:0]   ar_len_i,
  input  logic [3:0]   ar_id_i,
  output logic         r_valid_o,
  input  logic         r_ready_i,
  output logic [127:0] r_data_o,
  output logic         r_last_o,
  output logic [3:0]   r_id_o,
  // Digilent AXI MIG read master (28-bit byte addr, 128-bit data)
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
  output logic         m_axi_rready,
  // per-run telemetry (cleared by metric_clear_i or rst_n)
  output logic [31:0]  ddr_rd_bytes_o,       // axi_read_bytes
  output logic [31:0]  ddr_rd_count_o,       // axi_read_beats
  output logic [31:0]  ddr_burst_count_o,    // axi_read_bursts
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  data_mismatch_count_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  expected_records_o,   // beats issued via AR
  output logic [31:0]  received_records_o,   // beats accepted on R
  output logic [3:0]   rid_observed_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  localparam int unsigned TRACK_DEPTH = 16;
  localparam int unsigned TRACK_W     = $clog2(TRACK_DEPTH);

  logic [31:0] rd_b, rd_c, br_c;
  logic [31:0] mm_c, rr_c, rl_c, exp_c, rcv_c, rid_err, bp_c;
  logic [3:0]  rid_obs;
  logic [3:0]  expect_rid;

  // In-flight AR track: start node_id + remaining beats (for RLAST + data check)
  logic [31:0] tr_nid  [TRACK_DEPTH];
  logic [8:0]  tr_left [TRACK_DEPTH];
  logic [3:0]  tr_rid  [TRACK_DEPTH];
  logic [TRACK_W:0] tr_wr, tr_rd, tr_cnt;

  assign ddr_rd_bytes_o    = rd_b;
  assign ddr_rd_count_o    = rd_c;
  assign ddr_burst_count_o = br_c;
  assign axi_read_bytes_o  = rd_b;
  assign axi_read_bursts_o = br_c;
  assign axi_read_beats_o  = rd_c;
  assign data_mismatch_count_o  = mm_c;
  assign rresp_error_count_o    = rr_c;
  assign rlast_error_count_o    = rl_c;
  assign expected_records_o     = exp_c;
  assign received_records_o     = rcv_c;
  assign rid_observed_o         = rid_obs;
  assign rid_order_error_o      = rid_err;
  assign r_backpressure_cycles_o = bp_c;

  assign m_axi_arid    = ar_id_i;
  assign m_axi_araddr  = a7ng_node_byte_addr(NG_DDR_NODE_BASE, ar_addr_i);
  assign m_axi_arlen   = ar_len_i;
  assign m_axi_arsize  = 3'd4;   // 16 B
  assign m_axi_arburst = 2'b01;  // INCR
  assign m_axi_arvalid = ar_valid_i;
  assign ar_ready_o    = m_axi_arready;

  assign r_valid_o     = m_axi_rvalid;
  assign r_data_o      = m_axi_rdata;
  assign r_last_o      = m_axi_rlast;
  assign r_id_o        = m_axi_rid;
  assign m_axi_rready  = r_ready_i;

  wire do_ar = ar_valid_i && ar_ready_o;
  wire do_r  = r_valid_o && r_ready_i;
  wire bp_r  = m_axi_rvalid && !m_axi_rready;

  wire [8:0] ar_beats = 9'(ar_len_i) + 9'd1;

  // Expected NodeRecordV1 beat matching TB preload (deterministic node_id packing)
  function automatic logic [127:0] expected_node_beat(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[47:32]   = 16'd1;
    b[63:48]   = 16'(nid[7:0]);
    b[95:64]   = 32'hDDFE_0000 + nid;
    b[111:96]  = 16'h0100;
    b[119:112] = 8'(nid[7:0]);
    b[127:120] = A7NG_MEM_SCHEMA_VERSION[7:0];
    return b;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_b <= 32'd0;
      rd_c <= 32'd0;
      br_c <= 32'd0;
      mm_c <= 32'd0;
      rr_c <= 32'd0;
      rl_c <= 32'd0;
      exp_c <= 32'd0;
      rcv_c <= 32'd0;
      rid_err <= 32'd0;
      bp_c <= 32'd0;
      rid_obs <= 4'd0;
      expect_rid <= 4'd0;
      tr_wr <= '0;
      tr_rd <= '0;
      tr_cnt <= '0;
    end else if (metric_clear_i) begin
      rd_b <= 32'd0;
      rd_c <= 32'd0;
      br_c <= 32'd0;
      mm_c <= 32'd0;
      rr_c <= 32'd0;
      rl_c <= 32'd0;
      exp_c <= 32'd0;
      rcv_c <= 32'd0;
      rid_err <= 32'd0;
      bp_c <= 32'd0;
      rid_obs <= 4'd0;
      expect_rid <= 4'd0;
      tr_wr <= '0;
      tr_rd <= '0;
      tr_cnt <= '0;
    end else begin
      automatic logic [TRACK_W:0] tw, trd, tc;
      automatic logic [31:0] head_nid;
      automatic logic [8:0]  head_left;
      automatic logic [3:0]  head_rid;
      tw  = tr_wr;
      trd = tr_rd;
      tc  = tr_cnt;

      if (bp_r)
        bp_c <= bp_c + 32'd1;

      if (do_ar) begin
        br_c  <= br_c + 32'd1;
        exp_c <= exp_c + 32'(ar_beats);
        if (tc < TRACK_DEPTH[TRACK_W:0]) begin
          tr_nid[tw[TRACK_W-1:0]]  <= ar_addr_i;
          tr_left[tw[TRACK_W-1:0]] <= ar_beats;
          tr_rid[tw[TRACK_W-1:0]]  <= ar_id_i;
          tw  = tw + 1'b1;
          tc  = tc + 1'b1;
        end
      end

      if (do_r) begin
        rd_c  <= rd_c + 32'd1;
        rd_b  <= rd_b + 32'd16;
        rcv_c <= rcv_c + 32'd1;
        rid_obs <= m_axi_rid;

        if (m_axi_rresp != 2'b00)
          rr_c <= rr_c + 32'd1;

        if (tc != '0) begin
          head_nid  = tr_nid[trd[TRACK_W-1:0]];
          head_left = tr_left[trd[TRACK_W-1:0]];
          head_rid  = tr_rid[trd[TRACK_W-1:0]];

          // Conservation: NodeRecordV1.node_id (+ full beat vs deterministic pack)
          if (m_axi_rdata[31:0] != head_nid)
            mm_c <= mm_c + 32'd1;
          else if (m_axi_rdata != expected_node_beat(head_nid))
            mm_c <= mm_c + 32'd1;

          // RID must match the AR that owns this beat (not global in-order expect)
          if (m_axi_rid != head_rid)
            rid_err <= rid_err + 32'd1;

          if (m_axi_rlast) begin
            if (head_left != 9'd1)
              rl_c <= rl_c + 32'd1;
            trd = trd + 1'b1;
            tc  = tc - 1'b1;
            expect_rid <= expect_rid + 4'd1;
          end else begin
            if (head_left <= 9'd1)
              rl_c <= rl_c + 32'd1;
            tr_nid[trd[TRACK_W-1:0]]  <= head_nid + 32'd1;
            tr_left[trd[TRACK_W-1:0]] <= head_left - 9'd1;
          end
        end else begin
          // Beat with empty track — count as integrity fault
          mm_c <= mm_c + 32'd1;
          if (m_axi_rlast)
            rl_c <= rl_c + 32'd1;
        end
      end

      tr_wr  <= tw;
      tr_rd  <= trd;
      tr_cnt <= tc;
    end
  end
endmodule
