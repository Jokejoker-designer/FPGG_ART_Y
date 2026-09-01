// a7ng_native_ctx_bind.sv
// HS22-LM06-NATIVE-CTX-FWD-00 R1: latch encoded Top-8 at accepted start_i.
// ctx_pack_o is the captured register, not the live global_id bus.
// Encoding (PREREGISTER): ctx_idx=0, ctx_n_in=8,
//   pack[8*i +: 8] = global_id_i[i][7:0]
`timescale 1ns / 1ps

module a7ng_native_ctx_bind (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         grant_lm_i,
  input  logic         start_i,
  input  logic         do_start_i,
  input  logic [31:0]  global_id_i [0:7],
  input  logic         core_busy_i,
  input  logic         core_done_i,
  input  logic [9:0]   core_pred_i,
  output logic         busy_o,
  output logic         done_o,
  output logic         ctx_we_o,
  output logic [6:0]   ctx_idx_o,
  output logic [6:0]   ctx_n_in_o,
  output logic [63:0]  ctx_pack_o,
  output logic         start_fwd_o,
  output logic [9:0]   pred_o,
  output logic [31:0]  ctx_we_beats_o,
  output logic [31:0]  start_fwd_beats_o,
  output logic         capture_valid_o
);
  typedef enum logic [2:0] {
    S_IDLE, S_CTX, S_GAP, S_START, S_WAIT, S_DONE
  } st_t;
  st_t st;

  logic [63:0] captured_pack;
  logic        do_start_r;
  logic        capture_valid;
  logic [9:0]  pred_r;
  logic [31:0] ctx_beats, st_beats;
  logic [63:0] pack_comb;

  integer i;
  always_comb begin
    pack_comb = 64'd0;
    for (i = 0; i < 8; i = i + 1)
      pack_comb[8*i +: 8] = global_id_i[i][7:0];
  end

  assign ctx_idx_o         = 7'd0;
  assign ctx_n_in_o        = 7'd8;
  assign ctx_pack_o        = captured_pack;
  assign pred_o            = pred_r;
  assign ctx_we_beats_o    = ctx_beats;
  assign start_fwd_beats_o = st_beats;
  assign capture_valid_o   = capture_valid;
  assign busy_o            = (st != S_IDLE) && (st != S_DONE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st             <= S_IDLE;
      ctx_we_o       <= 1'b0;
      start_fwd_o    <= 1'b0;
      done_o         <= 1'b0;
      do_start_r     <= 1'b0;
      pred_r         <= 10'd0;
      ctx_beats      <= 32'd0;
      st_beats       <= 32'd0;
      captured_pack  <= 64'd0;
      capture_valid  <= 1'b0;
    end else begin
      ctx_we_o    <= 1'b0;
      start_fwd_o <= 1'b0;
      done_o      <= 1'b0;
      unique case (st)
        S_IDLE: begin
          capture_valid <= 1'b0;
          if (start_i && grant_lm_i && !core_busy_i) begin
            captured_pack <= pack_comb;
            capture_valid <= 1'b1;
            do_start_r    <= do_start_i;
            st            <= S_CTX;
          end
        end
        S_CTX: begin
          if (grant_lm_i) begin
            ctx_we_o  <= 1'b1;
            ctx_beats <= ctx_beats + 32'd1;
            st        <= S_GAP;
          end else
            st <= S_IDLE;
        end
        S_GAP: begin
          if (do_start_r)
            st <= S_START;
          else begin
            done_o <= 1'b1;
            st     <= S_DONE;
          end
        end
        S_START: begin
          // Do not drop to IDLE if grant_lm is 0 for a cycle: pending already
          // cleared, TinyGPT never sees start_fwd (H4 SIM_FULL=0: busy=0 forever).
          if (grant_lm_i) begin
            start_fwd_o <= 1'b1;
            st_beats    <= st_beats + 32'd1;
            st          <= S_WAIT;
          end
        end
        S_WAIT: begin
          // Re-issue start_fwd until TinyGPT leaves IDLE. One-cycle pulse
          // is missed if ntok/ctx NBA or stall-on-idle (H4: st_beats=1, busy=0).
          if (!core_busy_i && !core_done_i && grant_lm_i)
            start_fwd_o <= 1'b1;
          if (core_done_i) begin
            pred_r <= core_pred_i;
            done_o <= 1'b1;
            st     <= S_DONE;
          end
        end
        S_DONE: st <= S_IDLE;
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
