// a7ng_typeclass_scan.sv — U5Q-T2 sequential TYPE_CLASS catalog scan.
// Masked conjunctive match. CLASS_ID 16-bit, not from NID. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_typeclass_scan #(
  parameter int unsigned CAND_CAP = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        q_go_i,
  output logic        q_ready_o,
  input  logic [7:0]  q_eid_i,
  input  logic [7:0]  q_iid_i,
  input  logic [7:0]  q_rid_i,
  input  logic [7:0]  q_xid_i,
  input  logic        q_ev_i,
  input  logic        q_iv_i,
  input  logic        q_rv_i,
  input  logic        q_xv_i,
  output logic        cand_v_o,
  input  logic        cand_ready_i,
  output logic [15:0] cand_id_o,
  output logic        q_done_o,
  output logic        q_overflow_o,
  output logic [15:0] n_emit_o,
  output logic [15:0] n_trunc_o
);
  `include "typeclass_table.svh"

  typedef enum logic [1:0] {S_IDLE, S_SCAN, S_DONE} st_t;
  st_t st;

  logic [7:0]  qe, qi, qr, qx;
  logic        ev, iv, rv, xv;
  logic [15:0] idx, n_emit, n_trunc;
  logic        ovf;
  logic        match, bound_empty, illegal, stall;
  logic [15:0] row_id, row_mcnt;
  logic [7:0]  row_e, row_i, row_r, row_x;

  assign q_ready_o    = (st == S_IDLE);
  assign q_overflow_o = ovf;
  assign n_emit_o     = n_emit;
  assign n_trunc_o    = n_trunc;
  assign stall        = cand_v_o && !cand_ready_i;

  always_comb begin
    row_id   = (idx < 16'(TC_N)) ? TC_ID[idx] : 16'd0;
    row_e    = (idx < 16'(TC_N)) ? TC_EID[idx] : 8'd0;
    row_i    = (idx < 16'(TC_N)) ? TC_IID[idx] : 8'd0;
    row_r    = (idx < 16'(TC_N)) ? TC_RID[idx] : 8'd0;
    row_x    = (idx < 16'(TC_N)) ? TC_XID[idx] : 8'd0;
    row_mcnt = (idx < 16'(TC_N)) ? TC_MCNT[idx] : 16'd0;
    illegal  = (row_mcnt == 16'd0);
    bound_empty = !(ev | iv | rv | xv);
    match = (st == S_SCAN) && (idx < 16'(TC_N)) && !bound_empty && !illegal
          && (!ev || (row_e == qe))
          && (!iv || (row_i == qi))
          && (!rv || (row_r == qr))
          && (!xv || (row_x == qx));
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      idx <= '0; n_emit <= '0; n_trunc <= '0; ovf <= 1'b0;
      qe <= '0; qi <= '0; qr <= '0; qx <= '0;
      ev <= 1'b0; iv <= 1'b0; rv <= 1'b0; xv <= 1'b0;
      cand_v_o <= 1'b0; cand_id_o <= '0; q_done_o <= 1'b0;
    end else begin
      q_done_o <= 1'b0;
      unique case (st)
        S_IDLE: begin
          cand_v_o <= 1'b0;
          if (q_go_i) begin
            qe <= q_eid_i; qi <= q_iid_i; qr <= q_rid_i; qx <= q_xid_i;
            ev <= q_ev_i; iv <= q_iv_i; rv <= q_rv_i; xv <= q_xv_i;
            idx <= '0; n_emit <= '0; n_trunc <= '0; ovf <= 1'b0;
            st <= S_SCAN;
          end
        end
        S_SCAN: begin
          if (stall) begin
            cand_v_o <= 1'b1;
          end else begin
            if (cand_v_o && cand_ready_i)
              cand_v_o <= 1'b0;
            if (idx >= 16'(TC_N)) begin
              if (!(cand_v_o && !cand_ready_i)) begin
                q_done_o <= 1'b1;
                cand_v_o <= 1'b0;
                st <= S_DONE;
              end
            end else if (match && (n_emit < CAND_CAP[15:0])) begin
              cand_v_o <= 1'b1;
              cand_id_o <= row_id;
              n_emit <= n_emit + 16'd1;
              idx <= idx + 16'd1;
            end else if (match) begin
              ovf <= 1'b1;
              n_trunc <= n_trunc + 16'd1;
              cand_v_o <= 1'b0;
              idx <= idx + 16'd1;
            end else begin
              cand_v_o <= 1'b0;
              idx <= idx + 16'd1;
            end
          end
        end
        S_DONE: begin
          cand_v_o <= 1'b0;
          st <= S_IDLE;
        end
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
