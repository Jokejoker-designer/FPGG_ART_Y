// a7ng_gate14_c9_glue.sv — P2-GATE14-C9-SOA-LM-BIT-04
// Distinct 20-fact qids 0x10..0x23 / 0x30..0x43. CONTRA=qid 4 (typed R).
// C9 from learned graph TopK, not persist FAST IDs. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_gate14_c9_glue (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         cmd_valid_i,
  output logic         cmd_ready_o,
  input  logic [3:0]   cmd_i,
  input  logic [7:0]   tok_i,
  input  logic signed [3:0] reward_i,
  // forbidden ingress (live decoder; TB must keep 0)
  input  logic [63:0]  host_cue_i,
  input  logic [31:0]  host_winner_i,
  input  logic [31:0]  host_addr_i,
  input  logic [9:0]   host_next_i,
  input  logic         host_wren_i,
  input  logic [3:0]   host_mode_i,
  // persist
  output logic         p_learn_o,
  output logic         p_freeze_o,
  output logic         p_qvalid_o,
  input  logic         p_qready_i,
  output logic [7:0]   p_qid_o,
  input  logic         p_snap_v_i,
  output logic         p_snap_r_o,
  input  a7ng_pkg::node_id_t p_topk_id_i [8],
  input  a7ng_pkg::score_t   p_topk_sc_i [8],
  input  logic [31:0]  p_evs_i,
  input  logic [7:0]   p_evr_i,
  input  logic [31:0]  p_evo_i,
  input  logic         p_pending_i,
  input  logic [15:0]  p_txn_i,
  output logic         p_rew_v_o,
  output logic signed [3:0] p_rew_o,
  output logic         p_echo_v_o,
  output logic [15:0]  p_echo_o,
  input  logic         p_ack_v_i,
  input  logic [2:0]   p_ack_i,
  input  logic         p_c7_i,
  output logic         p_flush_o,
  output logic         p_reload_o,
  output logic         p_kill_o,
  output logic         p_trst_o,
  input  logic         p_busy_i,
  // LM bind
  output logic         lm_start_o,
  input  logic         lm_busy_i,
  input  logic         lm_done_i,
  input  logic [9:0]   lm_pred_i,
  // CFRAME observe (FPGA-owned)
  output logic [3:0]   c1_mode_o,
  output logic [63:0]  c2_anch_o,
  output logic [63:0]  c9_topk_o,
  output logic [127:0] c9_score_o,
  output logic [31:0]  c9_r1s_o,
  output logic [7:0]   c9_r1r_o,
  output logic [31:0]  c9_r1o_o,
  output logic         c10_lmst_o,
  output logic         c10_lmdn_o,
  output logic [9:0]   c10_out_o,
  output logic [15:0]  n_host_cue_o,
  output logic [15:0]  n_host_win_o,
  output logic [15:0]  n_host_addr_o,
  output logic [15:0]  n_host_tok_o,
  output logic [15:0]  n_host_w_o,
  output logic [15:0]  n_host_mode_o,
  output logic         teacher_active_o,
  output logic         ext_llm_active_o,
  output logic [2:0]   last_ack_o,
  output logic         exam_lm_used_o
);
  import a7ng_pkg::*;

  // Live (not UART-hardcoded). Same wires that increment n_host_*.
  assign teacher_active_o =
      (host_cue_i != 64'd0) | (host_winner_i != 32'd0) |
      (host_addr_i != 32'd0) | (host_mode_i != 4'd0);
  assign ext_llm_active_o = (host_next_i != 10'd0) | host_wren_i;

  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  localparam logic [7:0] T_PRE_A=8'hA1, T_HOLD_A=8'hA2, T_UNREL=8'hA3,
                         T_CONTRA=8'hA4, T_PRE_B=8'hB1, T_HOLD_B=8'hB2;
  localparam logic [2:0] S_IDLE=0, S_QISS=1, S_QWAIT=2, S_LMW=3, S_PBUSY=4, S_REW=5;

  logic [2:0] st;
  logic [3:0] mode;
  logic [63:0] anch;
  logic [7:0]  tok0;
  logic        tok_any, want_lm;
  logic [7:0]  mapped_q;
  logic [9:0]  wait_n;
  integer ki;

  function automatic logic [7:0] map_q(input logic [7:0] t);
    if ((t >= 8'h10) && (t <= 8'h23)) return t;
    if ((t >= 8'h30) && (t <= 8'h43)) return t;
    case (t)
      T_HOLD_A: map_q = 8'd2;
      T_UNREL:  map_q = 8'd3;
      T_CONTRA: map_q = 8'd4;
      T_HOLD_B: map_q = 8'd6;
      default:  map_q = 8'd3;
    endcase
  endfunction
  function automatic logic need_lm(input logic [7:0] t);
    return (t == T_HOLD_A) || (t == T_UNREL) || (t == T_CONTRA) || (t == T_HOLD_B);
  endfunction
  function automatic logic [63:0] mix64(input logic [63:0] a, input logic [7:0] t);
    mix64 = {a[62:0], a[63]} ^ {56'd0, t} ^ {t, a[63:8]};
  endfunction

  assign cmd_ready_o = (st == S_IDLE) && !p_busy_i;
  assign p_learn_o   = mode[2];
  assign p_freeze_o  = mode[3];
  assign p_snap_r_o  = 1'b1;
  assign c1_mode_o   = mode;
  assign c2_anch_o   = anch;
  assign p_qid_o     = mapped_q;

  always_comb begin
    c9_topk_o  = 64'd0;
    c9_score_o = 128'd0;
    for (ki = 0; ki < 8; ki = ki + 1) begin
      c9_topk_o[8*ki +: 8] = p_topk_id_i[ki][7:0];
      c9_score_o[16*ki +: 16] = p_topk_sc_i[ki];
    end
  end
  assign c9_r1s_o = p_evs_i;
  assign c9_r1r_o = p_evr_i;
  assign c9_r1o_o = p_evo_i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; mode <= 4'h5;
      anch <= 64'd0; tok0 <= 8'd0; tok_any <= 1'b0; want_lm <= 1'b0;
      mapped_q <= 8'd2; wait_n <= 10'd0;
      p_qvalid_o <= 0; p_rew_v_o <= 0; p_echo_v_o <= 0;
      p_rew_o <= 0; p_echo_o <= 0;
      p_flush_o <= 0; p_reload_o <= 0; p_kill_o <= 0; p_trst_o <= 0;
      lm_start_o <= 0; c10_lmst_o <= 0; c10_lmdn_o <= 0; c10_out_o <= 0;
      n_host_cue_o <= 0; n_host_win_o <= 0; n_host_addr_o <= 0;
      n_host_tok_o <= 0; n_host_w_o <= 0; n_host_mode_o <= 0;
      last_ack_o <= 0; exam_lm_used_o <= 0;
    end else begin
      p_qvalid_o <= 1'b0;
      p_rew_v_o  <= 1'b0;
      p_echo_v_o <= 1'b0;
      p_flush_o  <= 1'b0;
      p_reload_o <= 1'b0;
      p_kill_o   <= 1'b0;
      p_trst_o   <= 1'b0;
      lm_start_o <= 1'b0;

      if (host_cue_i != 64'd0) n_host_cue_o <= n_host_cue_o + 16'd1;
      if (host_winner_i != 32'd0) n_host_win_o <= n_host_win_o + 16'd1;
      if (host_addr_i != 32'd0) n_host_addr_o <= n_host_addr_o + 16'd1;
      if (host_next_i != 10'd0) n_host_tok_o <= n_host_tok_o + 16'd1;
      if (host_wren_i) n_host_w_o <= n_host_w_o + 16'd1;
      if (host_mode_i != 4'd0) n_host_mode_o <= n_host_mode_o + 16'd1;
      if (p_ack_v_i) last_ack_o <= p_ack_i;

      case (st)
        S_IDLE: if (cmd_valid_i && !p_busy_i) begin
          unique case (cmd_i)
            C_TOK: begin
              tok0 <= tok_i;
              if (!tok_any) begin
                anch <= {56'd0, tok_i}; tok_any <= 1'b1;
              end else
                anch <= mix64(anch, tok_i);
            end
            C_FIRE: begin
              mapped_q <= map_q(tok0);
              want_lm  <= (mode == 4'h8) && need_lm(tok0);
              c10_lmst_o <= 1'b0;
              c10_lmdn_o <= 1'b0;
              c10_out_o  <= 10'd0;
              tok_any  <= 1'b0;
              st <= S_QISS;
              $display("GLUE_FIRE tok0=%h map=%h mode=%h want_lm=%0d",
                       tok0, map_q(tok0), mode, (mode == 4'h8) && need_lm(tok0));
            end
            C_REW: begin
              p_rew_o <= reward_i; wait_n <= 10'd0;
              st <= S_REW;
            end
            C_FLUSH: begin p_flush_o <= 1'b1; st <= S_PBUSY; end
            C_KILL:  begin p_kill_o  <= 1'b1; st <= S_PBUSY; end
            C_RELOAD:begin p_reload_o<= 1'b1; st <= S_PBUSY; end
            C_FREEZE: begin mode <= 4'h8; tok_any <= 1'b0; end
            C_TRESET: begin p_trst_o <= 1'b1; st <= S_PBUSY; end
            C_TRAIN:  mode <= 4'h5;
            default: ;
          endcase
        end
        S_QISS: if (p_qready_i) begin
          p_qvalid_o <= 1'b1; st <= S_QWAIT;
          $display("GLUE_QISS qid=%h qr=%0d", mapped_q, p_qready_i);
        end
        S_QWAIT: if (p_snap_v_i) begin
          $display("GLUE_SNAP want_lm=%0d", want_lm);
          if (want_lm) begin
            c10_lmst_o <= 1'b1; c10_lmdn_o <= 1'b0;
            lm_start_o <= 1'b1; exam_lm_used_o <= 1'b1;
            st <= S_LMW;
          end else
            st <= S_IDLE;
        end
        S_LMW: begin
          if (lm_done_i) begin
            c10_lmdn_o <= 1'b1;
            c10_out_o  <= lm_pred_i;
            st <= S_IDLE;
          end else if (!lm_busy_i)
            // Arb grant is registered (1-cycle). Re-pulse until bind accepts.
            lm_start_o <= 1'b1;
        end
        S_REW: begin
          if (p_pending_i) begin
            p_rew_v_o <= 1'b1; p_echo_v_o <= 1'b1; p_echo_o <= p_txn_i;
            st <= S_IDLE;
          end else if (wait_n == 10'd511)
            st <= S_IDLE;
          else
            wait_n <= wait_n + 10'd1;
        end
        S_PBUSY: if (!p_busy_i) st <= S_IDLE;
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
