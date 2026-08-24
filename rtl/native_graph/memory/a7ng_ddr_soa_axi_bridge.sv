// a7ng_ddr_soa_axi_bridge.sv — byte-addressed AXI read bridge for SOA stage-1 planes
// Gate: ddr_cue_soa_00r_axi_liveness. AR passthrough + 4-entry R skid FIFO (feed-bridge law).
`timescale 1ns / 1ps

module a7ng_ddr_soa_axi_bridge (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         metric_clear_i,
  output logic         r_path_idle_o,
  output logic         r_fifo_empty_o,
  output logic [2:0]   r_fifo_level_o,
  output logic [31:0]  outstanding_beats_o,
  input  logic         ar_valid_i,
  output logic         ar_ready_o,
  input  logic [27:0]  ar_addr_i,
  input  logic [7:0]   ar_len_i,
  input  logic [3:0]   ar_id_i,
  input  logic [2:0]   ar_size_i,
  output logic         r_valid_o,
  input  logic         r_ready_i,
  output logic [127:0] r_data_o,
  output logic         r_last_o,
  output logic [3:0]   r_id_o,
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
  output logic [31:0]  axi_read_bytes_o,
  output logic [31:0]  axi_read_bursts_o,
  output logic [31:0]  axi_read_beats_o,
  output logic [31:0]  rresp_error_count_o,
  output logic [31:0]  rlast_error_count_o,
  output logic [31:0]  expected_records_o,
  output logic [31:0]  received_records_o,
  output logic [31:0]  rid_order_error_o,
  output logic [31:0]  r_backpressure_cycles_o
);
  localparam int unsigned TRACK_DEPTH = 16;
  localparam int unsigned TRACK_W     = $clog2(TRACK_DEPTH);
  localparam int unsigned R_FIFO_DEPTH = 4;
  localparam int unsigned R_FIFO_W     = $clog2(R_FIFO_DEPTH);

  logic [127:0] fifo_data [R_FIFO_DEPTH];
  logic         fifo_last [R_FIFO_DEPTH];
  logic [3:0]   fifo_rid  [R_FIFO_DEPTH];
  logic [1:0]   fifo_rresp[R_FIFO_DEPTH];
  logic [R_FIFO_W:0] fifo_wr, fifo_rd, fifo_cnt;
  logic              r_drain_hold;

  logic [31:0] rd_b, rd_c, br_c;
  logic [31:0] rr_c, rl_c, exp_c, rcv_c, rid_err, bp_c;
  logic [3:0]  expect_rid;
  logic [31:0] tr_addr [TRACK_DEPTH];
  logic [8:0]  tr_left [TRACK_DEPTH];
  logic [3:0]  tr_rid  [TRACK_DEPTH];
  logic [2:0]  tr_size [TRACK_DEPTH];
  logic [TRACK_W:0] tr_wr, tr_rd, tr_cnt;

  assign axi_read_bytes_o  = rd_b;
  assign axi_read_bursts_o = br_c;
  assign axi_read_beats_o  = rd_c;
  assign rresp_error_count_o    = rr_c;
  assign rlast_error_count_o    = rl_c;
  assign expected_records_o     = exp_c;
  assign received_records_o     = rcv_c;
  assign rid_order_error_o      = rid_err;
  assign r_backpressure_cycles_o = bp_c;
  assign r_fifo_level_o         = fifo_cnt[2:0];
  assign r_fifo_empty_o         = (fifo_cnt == '0);
  assign outstanding_beats_o    = {23'd0, tr_cnt};

  assign r_path_idle_o         = !r_drain_hold && (fifo_cnt == '0) && !m_axi_rvalid &&
                                 (tr_cnt == '0);

  assign m_axi_arid    = ar_id_i;
  assign m_axi_araddr  = ar_addr_i;
  assign m_axi_arlen   = ar_len_i;
  assign m_axi_arsize  = ar_size_i;
  assign m_axi_arburst = 2'b01;
  assign m_axi_arvalid = ar_valid_i;
  assign ar_ready_o    = m_axi_arready && !r_drain_hold;

  assign m_axi_rready  = (fifo_cnt < R_FIFO_DEPTH[0+:R_FIFO_W+1]) || r_drain_hold;
  assign r_valid_o     = (fifo_cnt != '0) && !r_drain_hold;
  assign r_data_o      = fifo_data[fifo_rd[R_FIFO_W-1:0]];
  assign r_last_o      = fifo_last[fifo_rd[R_FIFO_W-1:0]];
  assign r_id_o        = fifo_rid[fifo_rd[R_FIFO_W-1:0]];

  wire push_r = m_axi_rvalid && m_axi_rready;
  wire pop_c  = r_valid_o && r_ready_i;
  wire pop_d  = r_drain_hold && (fifo_cnt != '0);
  wire pop_r  = pop_c || pop_d;
  wire do_ar  = ar_valid_i && ar_ready_o;
  wire do_r   = pop_r;
  wire bp_r   = m_axi_rvalid && !m_axi_rready;
  wire [1:0] pop_rresp = fifo_rresp[fifo_rd[R_FIFO_W-1:0]];

  wire [8:0] ar_beats = 9'(ar_len_i) + 9'd1;

  function automatic int unsigned beat_bytes(input logic [2:0] sz);
    case (sz)
      3'd4: return 16;
      3'd3: return 8;
      3'd2: return 4;
      3'd1: return 2;
      default: return 1;
    endcase
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_wr <= '0;
      fifo_rd <= '0;
      fifo_cnt <= '0;
      r_drain_hold <= 1'b0;
      rd_b <= 32'd0;
      rd_c <= 32'd0;
      br_c <= 32'd0;
      rr_c <= 32'd0;
      rl_c <= 32'd0;
      exp_c <= 32'd0;
      rcv_c <= 32'd0;
      rid_err <= 32'd0;
      bp_c <= 32'd0;
      expect_rid <= 4'd0;
      tr_wr <= '0;
      tr_rd <= '0;
      tr_cnt <= '0;
    end else if (metric_clear_i) begin
      fifo_wr <= '0;
      fifo_rd <= '0;
      fifo_cnt <= '0;
      r_drain_hold <= 1'b1;
      rd_b <= 32'd0;
      rd_c <= 32'd0;
      br_c <= 32'd0;
      rr_c <= 32'd0;
      rl_c <= 32'd0;
      exp_c <= 32'd0;
      rcv_c <= 32'd0;
      rid_err <= 32'd0;
      bp_c <= 32'd0;
      expect_rid <= 4'd0;
      tr_wr <= '0;
      tr_rd <= '0;
      tr_cnt <= '0;
    end else begin
      automatic logic [R_FIFO_W:0] fw, fr, fc;
      automatic logic [TRACK_W:0] tw, trd, tc;
      automatic logic [27:0] head_addr;
      automatic logic [8:0]  head_left;
      automatic logic [3:0]  head_rid;
      automatic logic [2:0]  head_size;
      automatic int unsigned bbytes;
      fw  = fifo_wr;
      fr  = fifo_rd;
      fc  = fifo_cnt;
      tw  = tr_wr;
      trd = tr_rd;
      tc  = tr_cnt;

      if (r_drain_hold && !m_axi_rvalid && (fifo_cnt == '0) && (tr_cnt == '0))
        r_drain_hold <= 1'b0;

      if (push_r && pop_r) begin
        fifo_data[fw[R_FIFO_W-1:0]] <= m_axi_rdata;
        fifo_last[fw[R_FIFO_W-1:0]] <= m_axi_rlast;
        fifo_rid[fw[R_FIFO_W-1:0]]  <= m_axi_rid;
        fifo_rresp[fw[R_FIFO_W-1:0]] <= m_axi_rresp;
        fw = fw + 1'b1;
        fr = fr + 1'b1;
      end else if (push_r) begin
        fifo_data[fw[R_FIFO_W-1:0]] <= m_axi_rdata;
        fifo_last[fw[R_FIFO_W-1:0]] <= m_axi_rlast;
        fifo_rid[fw[R_FIFO_W-1:0]]  <= m_axi_rid;
        fifo_rresp[fw[R_FIFO_W-1:0]] <= m_axi_rresp;
        fw = fw + 1'b1;
        fc = fc + 1'b1;
      end else if (pop_r) begin
        fr = fr + 1'b1;
        fc = fc - 1'b1;
      end
      fifo_wr  <= fw;
      fifo_rd  <= fr;
      fifo_cnt <= fc;

      if (bp_r)
        bp_c <= bp_c + 32'd1;

      if (do_ar) begin
        br_c  <= br_c + 32'd1;
        exp_c <= exp_c + 32'(ar_beats);
        if (tc < TRACK_DEPTH[TRACK_W:0]) begin
          tr_addr[tw[TRACK_W-1:0]] <= ar_addr_i;
          tr_left[tw[TRACK_W-1:0]] <= ar_beats;
          tr_rid[tw[TRACK_W-1:0]]  <= ar_id_i;
          tr_size[tw[TRACK_W-1:0]] <= ar_size_i;
          tw  = tw + 1'b1;
          tc  = tc + 1'b1;
        end
      end

      if (do_r) begin
        rd_c  <= rd_c + 32'd1;
        if (tc != '0) begin
          rcv_c <= rcv_c + 32'd1;
          head_addr = tr_addr[trd[TRACK_W-1:0]];
          head_left = tr_left[trd[TRACK_W-1:0]];
          head_rid  = tr_rid[trd[TRACK_W-1:0]];
          head_size = tr_size[trd[TRACK_W-1:0]];
          bbytes    = beat_bytes(head_size);
          rd_b <= rd_b + 32'(bbytes);

          if (pop_rresp != 2'b00)
            rr_c <= rr_c + 32'd1;
          if (r_id_o != head_rid)
            rid_err <= rid_err + 32'd1;

          if (r_last_o) begin
            if (head_left != 9'd1)
              rl_c <= rl_c + 32'd1;
            trd = trd + 1'b1;
            tc  = tc - 1'b1;
            expect_rid <= expect_rid + 4'd1;
          end else begin
            if (head_left <= 9'd1)
              rl_c <= rl_c + 32'd1;
            tr_addr[trd[TRACK_W-1:0]] <= head_addr + 28'(bbytes);
            tr_left[trd[TRACK_W-1:0]] <= head_left - 9'd1;
          end
        end
      end

      tr_wr  <= tw;
      tr_rd  <= trd;
      tr_cnt <= tc;
    end
  end
endmodule
