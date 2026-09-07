// a7ng_lm_ctx_fwd_v1.sv
// U8-R3 glue: encoder beat_pack → LM ctx_we beats → one start_fwd.
// Does not pack CLASS_ID / CLASS_ID[7:0] / member NID.
// Not a7ng_native_ctx_bind (NID-era global_id low8). PROGRAM=NO. QHEAD=NO.
`timescale 1ns / 1ps

module a7ng_lm_ctx_fwd_v1 (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        go_i,
  output logic        enc_go_o,
  input  logic        enc_busy_i,
  input  logic        enc_done_i,
  input  logic [6:0]  enc_ntok_i,
  input  logic        enc_beat_v_i,
  input  logic [3:0]  enc_beat_n_i,
  input  logic [63:0] enc_beat_pack_i,
  input  logic        core_busy_i,
  input  logic        core_done_i,
  input  logic [9:0]  core_pred_i,
  output logic        ctx_we_o,
  output logic [6:0]  ctx_idx_o,
  output logic [6:0]  ctx_n_in_o,
  output logic [63:0] ctx_pack_o,
  output logic        start_fwd_o,
  output logic        busy_o,
  output logic        done_o,
  output logic [9:0]  pred_o,
  output logic [31:0] ctx_we_beats_o,
  output logic [31:0] start_fwd_beats_o
);
  typedef enum logic [2:0] {
    S_IDLE, S_GO, S_BEATS, S_FLUSH, S_GAP, S_START, S_WAIT, S_DONE
  } st_t;
  st_t st;

  logic [6:0]  wr_idx;
  logic [31:0] ctx_beats, st_beats;
  logic [9:0]  pred_r;
  logic [63:0] pack_d;

  assign busy_o            = (st != S_IDLE) && (st != S_DONE);
  assign pred_o            = pred_r;
  assign ctx_we_beats_o    = ctx_beats;
  assign start_fwd_beats_o = st_beats;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st          <= S_IDLE;
      enc_go_o    <= 1'b0;
      ctx_we_o    <= 1'b0;
      start_fwd_o <= 1'b0;
      done_o      <= 1'b0;
      wr_idx      <= 7'd0;
      ctx_idx_o   <= 7'd0;
      ctx_n_in_o  <= 7'd0;
      ctx_pack_o  <= 64'd0;
      ctx_beats   <= 32'd0;
      st_beats    <= 32'd0;
      pred_r      <= 10'd0;
      pack_d      <= 64'd0;
    end else begin
      enc_go_o    <= 1'b0;
      ctx_we_o    <= 1'b0;
      start_fwd_o <= 1'b0;
      done_o      <= 1'b0;
      pack_d      <= enc_beat_pack_i;
      unique case (st)
        S_IDLE: begin
          if (go_i && !enc_busy_i && !core_busy_i) begin
            wr_idx    <= 7'd0;
            ctx_beats <= 32'd0;
            enc_go_o  <= 1'b1;
            st        <= S_GO;
          end
        end
        S_GO: st <= S_BEATS;
        S_BEATS: begin
          if (enc_beat_v_i) begin
            ctx_we_o   <= 1'b1;
            ctx_pack_o <= pack_d;
            ctx_idx_o  <= wr_idx;
            if (wr_idx == 7'd0)
              ctx_n_in_o <= enc_ntok_i;
            wr_idx    <= wr_idx + 7'd8;
            ctx_beats <= ctx_beats + 32'd1;
          end
          if (enc_done_i)
            st <= S_FLUSH;
        end
        S_FLUSH: st <= S_GAP;
        S_GAP:   st <= S_START;
        S_START: begin
          if (ctx_beats != 32'd0) begin
            start_fwd_o <= 1'b1;
            st_beats    <= st_beats + 32'd1;
            st          <= S_WAIT;
          end else begin
            done_o <= 1'b1;
            st     <= S_DONE;
          end
        end
        S_WAIT: begin
          if (!core_busy_i && !core_done_i) begin
            start_fwd_o <= 1'b1;
            st_beats    <= st_beats + 32'd1;
          end
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
