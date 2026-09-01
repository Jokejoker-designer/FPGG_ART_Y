// a7ng_feedback_resolver.sv — a7ng-feedback-v2 (UNIT/OOC only; SoC instantiate ABSENT)
// Host: reward ∈ {-3..+3} and FPGA txn echo. No idx/delta/winner/address/answer.
// FPGA latches evidence, mints {gen,seq} txn, holds consume under backpressure.
`timescale 1ns / 1ps

module a7ng_feedback_resolver #(
  parameter int unsigned TXN_W = 16,
  parameter int unsigned CNT_W = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         learn_i,
  input  logic         freeze_i,
  input  logic         latch_valid_i,
  output logic         latch_ready_o,
  input  logic [31:0]  subj_i,
  input  logic [7:0]   rel_i,
  input  logic [31:0]  obj_i,
  input  logic [15:0]  q_epoch_i,
  input  logic [15:0]  p_epoch_i,
  input  logic [7:0]   conf_i,
  input  logic         contradict_i,
  output logic         pending_o,
  output logic [TXN_W-1:0] txn_o,
  input  logic         reward_valid_i,
  input  logic signed [3:0] reward_i,
  input  logic         txn_echo_valid_i,
  input  logic [TXN_W-1:0] txn_echo_i,
  output logic         reward_ready_o,
  output logic         ack_valid_o,
  input  logic         ack_ready_i,
  output logic [2:0]   ack_o,
  output logic         consume_valid_o,
  input  logic         consume_ready_i,
  output logic signed [3:0] consume_reward_o,
  output logic [31:0]  consume_subj_o,
  output logic [7:0]   consume_rel_o,
  output logic [31:0]  consume_obj_o,
  output logic [15:0]  consume_q_epoch_o,
  output logic [15:0]  consume_p_epoch_o,
  output logic [7:0]   consume_conf_o,
  output logic         consume_contradict_o,
  output logic [TXN_W-1:0] consume_txn_o,
  output logic [CNT_W-1:0] n_consume_o,
  output logic [CNT_W-1:0] n_orphan_o,
  output logic [CNT_W-1:0] n_range_o,
  output logic [CNT_W-1:0] n_late_o,
  output logic [CNT_W-1:0] n_drop_o,
  output logic [CNT_W-1:0] n_dup_o,
  output logic [CNT_W-1:0] n_mode_o
);
  localparam int unsigned SEQ_W = (TXN_W / 2 == 0) ? 1 : TXN_W / 2;
  localparam int unsigned GEN_W = TXN_W - SEQ_W;
  localparam logic [2:0] ACK_CONSUME = 3'd1;
  localparam logic [2:0] ACK_ORPHAN  = 3'd2;
  localparam logic [2:0] ACK_RANGE   = 3'd3;
  localparam logic [2:0] ACK_LATE    = 3'd4;
  localparam logic [2:0] ACK_DROP    = 3'd5;
  localparam logic [2:0] ACK_DUP     = 3'd6;
  localparam logic [2:0] ACK_MODE    = 3'd7;

  logic pending;
  logic [TXN_W-1:0] txn;
  logic [GEN_W-1:0] gen;
  logic [SEQ_W-1:0] seq;
  logic [31:0] subj_q, obj_q;
  logic [7:0]  rel_q, conf_q;
  logic [15:0] qe_q, pe_q;
  logic        contra_q;
  logic        last_v;
  logic [TXN_W-1:0] last_txn;

  wire ack_busy  = ack_valid_o && !ack_ready_i;
  wire cons_busy = consume_valid_o && !consume_ready_i;
  wire cons_fire = consume_valid_o && consume_ready_i;
  wire ack_fire  = ack_valid_o && ack_ready_i;

  assign pending_o      = pending;
  assign txn_o          = txn;
  assign latch_ready_o  = learn_i && !freeze_i && !pending && !consume_valid_o && !ack_busy;
  assign reward_ready_o = !ack_busy && !cons_busy;

  function automatic logic reward_in_range(input logic signed [3:0] r);
    return (r >= -4'sd3) && (r <= 4'sd3);
  endfunction

  function automatic logic [CNT_W-1:0] sat_inc(input logic [CNT_W-1:0] n);
    return (n == {CNT_W{1'b1}}) ? n : (n + {{(CNT_W-1){1'b0}}, 1'b1});
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending <= 1'b0;
      txn <= '0;
      gen <= '0;
      seq <= SEQ_W'(1);
      subj_q <= '0; rel_q <= '0; obj_q <= '0;
      qe_q <= '0; pe_q <= '0; conf_q <= '0; contra_q <= 1'b0;
      last_v <= 1'b0;
      last_txn <= '0;
      ack_valid_o <= 1'b0; ack_o <= 3'd0;
      consume_valid_o <= 1'b0;
      consume_reward_o <= '0;
      consume_subj_o <= '0; consume_rel_o <= '0; consume_obj_o <= '0;
      consume_q_epoch_o <= '0; consume_p_epoch_o <= '0;
      consume_conf_o <= '0; consume_contradict_o <= 1'b0;
      consume_txn_o <= '0;
      n_consume_o <= '0; n_orphan_o <= '0; n_range_o <= '0;
      n_late_o <= '0; n_drop_o <= '0; n_dup_o <= '0; n_mode_o <= '0;
    end else begin
      if (ack_fire)
        ack_valid_o <= 1'b0;

      if (cons_fire) begin
        consume_valid_o <= 1'b0;
        pending         <= 1'b0;
        last_v          <= 1'b1;
        last_txn        <= consume_txn_o;
      end

      if (freeze_i && pending && !consume_valid_o) begin
        pending <= 1'b0;
        if (!ack_busy) begin
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_DROP;
          n_drop_o    <= sat_inc(n_drop_o);
        end
      end else if (reward_valid_i && !ack_busy && !cons_busy) begin
        if (!reward_in_range(reward_i)) begin
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_RANGE;
          n_range_o   <= sat_inc(n_range_o);
        end else if (consume_valid_o) begin
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_DUP;
          n_dup_o     <= sat_inc(n_dup_o);
        end else if (!pending) begin
          if (last_v && txn_echo_valid_i && (txn_echo_i == last_txn)) begin
            ack_valid_o <= 1'b1;
            ack_o       <= ACK_DUP;
            n_dup_o     <= sat_inc(n_dup_o);
          end else begin
            ack_valid_o <= 1'b1;
            ack_o       <= ACK_ORPHAN;
            n_orphan_o  <= sat_inc(n_orphan_o);
          end
        end else if (!txn_echo_valid_i || (txn_echo_i != txn)) begin
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_LATE;
          n_late_o    <= sat_inc(n_late_o);
        end else if (freeze_i) begin
          pending     <= 1'b0;
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_DROP;
          n_drop_o    <= sat_inc(n_drop_o);
        end else if (!learn_i) begin
          ack_valid_o <= 1'b1;
          ack_o       <= ACK_MODE;
          n_mode_o    <= sat_inc(n_mode_o);
        end else begin
          consume_valid_o      <= 1'b1;
          consume_reward_o     <= reward_i;
          consume_subj_o       <= subj_q;
          consume_rel_o        <= rel_q;
          consume_obj_o        <= obj_q;
          consume_q_epoch_o    <= qe_q;
          consume_p_epoch_o    <= pe_q;
          consume_conf_o       <= conf_q;
          consume_contradict_o <= contra_q;
          consume_txn_o        <= txn;
          n_consume_o          <= sat_inc(n_consume_o);
          ack_valid_o          <= 1'b1;
          ack_o                <= ACK_CONSUME;
          if (consume_ready_i) begin
            pending  <= 1'b0;
            last_v   <= 1'b1;
            last_txn <= txn;
          end
        end
      end else if (latch_valid_i && latch_ready_o) begin
        pending  <= 1'b1;
        txn      <= {gen, seq};
        subj_q   <= subj_i;
        rel_q    <= rel_i;
        obj_q    <= obj_i;
        qe_q     <= q_epoch_i;
        pe_q     <= p_epoch_i;
        conf_q   <= conf_i;
        contra_q <= contradict_i;
        if (seq == {SEQ_W{1'b1}}) begin
          seq <= SEQ_W'(1);
          if (gen == {GEN_W{1'b1}}) begin
            gen    <= '0;
            last_v <= 1'b0;
          end else
            gen <= gen + 1'b1;
        end else
          seq <= seq + 1'b1;
      end
    end
  end
endmodule
