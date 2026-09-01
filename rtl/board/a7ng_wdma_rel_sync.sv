// a7ng_wdma_rel_sync.sv — P2-WDMA-RELEASE-CDC-AUDIT-03
// UI cmd_empty / dma IDLE / AR-outstanding==0 used as a coherent AND to
// drop wdma_owner_grant on core. Independent 2-FF of the 3-bit vector is
// UNSAFE: CDC-10 combo-before-sync + dest-AND of skewed bits can release
// the mux while AR is still outstanding.
//
// Fix: register combo sources on ui_clk; AND in UI; dest 3-flop ASYNC_REG
// of the AND (level, so grant cannot miss the owner-drop window);
// request/ack toggle + ASYNC_REG 3-flop for exactly-once idle-window pulse.
// Dest does not sample the 3-bit payload bus. No false-path. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_wdma_rel_sync (
  input  logic       ui_clk,
  input  logic       ui_rst_n,
  input  logic       core_clk,
  input  logic       core_rst_n,
  input  logic       cmd_empty_i,
  input  logic [2:0] dma_st_i,
  input  logic [3:0] arr_outst_i,
  output logic       rel_ok_o,
  output logic       rel_pulse_o,
  output logic       req_tog_o,
  output logic       ack_tog_o,
  output logic       and_q_o,
  output logic [2:0] payload_hold_o
);
  // ---- UI: register combo, then AND, then handshake ----
  logic quiet_q, idle_q, empty_q, and_q;
  logic req_tog, pend, sent;
  (* ASYNC_REG = "TRUE" *) logic ack_s0, ack_s1, ack_s2;
  logic [2:0] payload_hold;

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      quiet_q <= 1'b0;
      idle_q <= 1'b0;
      empty_q <= 1'b0;
      and_q <= 1'b0;
      req_tog <= 1'b0;
      pend <= 1'b0;
      sent <= 1'b0;
      ack_s0 <= 1'b0;
      ack_s1 <= 1'b0;
      ack_s2 <= 1'b0;
      payload_hold <= 3'b000;
    end else begin
      ack_s0 <= ack_tog_o;
      ack_s1 <= ack_s0;
      ack_s2 <= ack_s1;
      quiet_q <= (arr_outst_i == 4'd0);
      idle_q  <= (dma_st_i == 3'd0);
      empty_q <= cmd_empty_i;
      and_q   <= quiet_q & idle_q & empty_q;

      if (!pend) begin
        if (and_q && !sent) begin
          req_tog <= ~req_tog;
          pend <= 1'b1;
          sent <= 1'b1;
          payload_hold <= {empty_q, idle_q, quiet_q};
        end
      end else if (ack_s2 == req_tog) begin
        pend <= 1'b0;
      end
      if (!and_q)
        sent <= 1'b0;
    end
  end

  assign req_tog_o = req_tog;
  assign and_q_o = and_q;
  assign payload_hold_o = payload_hold;

  // ---- core: 3-flop level of AND + req edge pulse/ack ----
  (* ASYNC_REG = "TRUE" *) logic and_s0, and_s1, and_s2;
  (* ASYNC_REG = "TRUE" *) logic req_s0, req_s1, req_s2;
  logic req_seen, ack_tog;

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      and_s0 <= 1'b0;
      and_s1 <= 1'b0;
      and_s2 <= 1'b0;
      req_s0 <= 1'b0;
      req_s1 <= 1'b0;
      req_s2 <= 1'b0;
      req_seen <= 1'b0;
      ack_tog <= 1'b0;
      rel_pulse_o <= 1'b0;
    end else begin
      and_s0 <= and_q;
      and_s1 <= and_s0;
      and_s2 <= and_s1;
      req_s0 <= req_tog;
      req_s1 <= req_s0;
      req_s2 <= req_s1;
      rel_pulse_o <= 1'b0;
      if (req_s2 != req_seen) begin
        req_seen <= req_s2;
        ack_tog <= ~ack_tog;
        rel_pulse_o <= 1'b1;
      end
    end
  end

  assign rel_ok_o = and_s2;
  assign ack_tog_o = ack_tog;
endmodule
