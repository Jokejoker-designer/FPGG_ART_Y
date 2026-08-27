// a7ng_late_materialize.sv — Phase C graph_late_materialize_00
// Law: a7ng-late-mat-v0
// ONE UNKNOWN: expensive NodeRecordV1 fetch only after global Top-K commit.
// SCORE CHEAP EARLY — FETCH EXPENSIVE LATE.
// HS-01/14: FPGA owns AR address (mem_schema_v1 stride). Host never supplies it.
// Does not retune TermGen / scorer / Top-K. Does not fetch invalid (loser) slots.
`timescale 1ns / 1ps

module a7ng_late_materialize #(
  parameter int unsigned K = 8
) (
  input  logic                       clk,
  input  logic                       rst_n,
  // Top-K commit (pulse). Must precede any AR.
  input  logic                       commit_i,
  input  logic [K-1:0]               valid_mask_i,
  input  a7ng_pkg::node_id_t         id_i [K],
  output logic                       busy_o,
  output logic                       done_o,
  output logic                       beat_valid_o,
  output logic                       beat_last_o,
  output logic [2:0]                 beat_idx_o,
  output a7ng_pkg::node_id_t         beat_id_o,
  output logic [127:0]               beat_data_o,
  output logic [15:0]                n_fetch_o,
  output logic [15:0]                n_skip_o,
  output logic [31:0]                payload_bytes_o,
  output logic [31:0]                ar_beats_o,
  output logic                       early_ar_fault_o,
  // AXI4 read master (128-bit, 16 B / beat — NodeRecordV1)
  output logic [3:0]                 m_axi_arid,
  output logic [27:0]                m_axi_araddr,
  output logic [7:0]                 m_axi_arlen,
  output logic [2:0]                 m_axi_arsize,
  output logic [1:0]                 m_axi_arburst,
  output logic                       m_axi_arvalid,
  input  logic                       m_axi_arready,
  input  logic [3:0]                 m_axi_rid,
  input  logic [127:0]               m_axi_rdata,
  input  logic [1:0]                 m_axi_rresp,
  input  logic                       m_axi_rlast,
  input  logic                       m_axi_rvalid,
  output logic                       m_axi_rready
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  typedef enum logic [2:0] {ST_IDLE, ST_PICK, ST_AR, ST_R, ST_DONE} st_t;
  st_t st;

  logic [K-1:0] mask_q;
  node_id_t     id_q [K];
  logic [3:0]   idx;
  logic         committed;

  assign m_axi_arid    = 4'd0;
  assign m_axi_arlen   = 8'd0;
  assign m_axi_arsize  = 3'd4;
  assign m_axi_arburst = 2'b01;
  assign busy_o        = (st != ST_IDLE) && (st != ST_DONE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE;
      mask_q <= '0;
      idx <= '0;
      committed <= 1'b0;
      done_o <= 1'b0;
      beat_valid_o <= 1'b0;
      beat_last_o <= 1'b0;
      beat_idx_o <= '0;
      beat_id_o <= '0;
      beat_data_o <= '0;
      n_fetch_o <= '0;
      n_skip_o <= '0;
      payload_bytes_o <= '0;
      ar_beats_o <= '0;
      early_ar_fault_o <= 1'b0;
      m_axi_araddr <= '0;
      m_axi_arvalid <= 1'b0;
      m_axi_rready <= 1'b0;
    end else begin
      done_o <= 1'b0;
      beat_valid_o <= 1'b0;
      beat_last_o <= 1'b0;

      if (m_axi_arvalid && !committed)
        early_ar_fault_o <= 1'b1;

      unique case (st)
        ST_IDLE: begin
          m_axi_arvalid <= 1'b0;
          m_axi_rready  <= 1'b0;
          if (commit_i) begin
            integer k;
            mask_q <= valid_mask_i;
            for (k = 0; k < K; k = k + 1)
              id_q[k] <= id_i[k];
            idx <= 4'd0;
            n_fetch_o <= '0;
            n_skip_o <= '0;
            payload_bytes_o <= '0;
            ar_beats_o <= '0;
            committed <= 1'b1;
            st <= ST_PICK;
          end
        end

        ST_PICK: begin
          if (idx >= 4'(K)) begin
            st <= ST_DONE;
          end else if (!mask_q[idx[2:0]]) begin
            n_skip_o <= n_skip_o + 16'd1;
            idx <= idx + 4'd1;
          end else begin
            m_axi_araddr  <= a7ng_node_byte_addr(NG_DDR_NODE_BASE, id_q[idx[2:0]]);
            m_axi_arvalid <= 1'b1;
            st <= ST_AR;
          end
        end

        ST_AR: begin
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b1;
            ar_beats_o    <= ar_beats_o + 32'd1;
            st <= ST_R;
          end
        end

        ST_R: begin
          if (m_axi_rvalid && m_axi_rready) begin
            beat_valid_o    <= 1'b1;
            beat_idx_o      <= idx[2:0];
            beat_id_o       <= id_q[idx[2:0]];
            beat_data_o     <= m_axi_rdata;
            n_fetch_o       <= n_fetch_o + 16'd1;
            payload_bytes_o <= payload_bytes_o + 32'(A7NG_NODE_REC_BYTES);
            m_axi_rready    <= 1'b0;
            if (idx == 4'(K - 1))
              beat_last_o <= 1'b1;
            idx <= idx + 4'd1;
            st <= ST_PICK;
          end
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
