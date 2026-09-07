// a7ng_lm_ctx_encoder_v1.sv
// U8-R2: FPGA-owned TYPE_CLASS descriptor → 8-bit token stream.
// Record = {eid,iid,rid,xid}. CLASS_ID not serialized (no low8).
// Semantic LM compatibility: MISMATCH. PROGRAM=NO. QHEAD=NO.
`timescale 1ns / 1ps

module a7ng_lm_ctx_encoder_v1 #(
  parameter int K = 8,
  parameter int MAX_NTOK = 64
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        go_i,
  input  logic [15:0] class_id_i [0:K-1],
  output logic        busy_o,
  output logic        done_o,
  output logic [6:0]  ntok_o,
  output logic        beat_v_o,
  output logic [3:0]  beat_n_o,
  output logic [63:0] beat_pack_o,
  output logic [7:0]  tok_o [0:MAX_NTOK-1],
  output logic [3:0]  n_rec_o,
  output logic [3:0]  n_skip_o
);
  typedef enum logic [2:0] {
    S_IDLE, S_SCAN, S_MAT, S_TAKE, S_BEAT, S_DONE
  } st_t;
  st_t st;

  logic [3:0] k, rec, skp;
  logic [6:0] ntok, rd;
  logic [7:0] tok [0:MAX_NTOK-1];
  integer ti, bi;

  logic        mat_go, mat_hit;
  logic [15:0] mat_cid, want;
  logic [7:0]  mat_e, mat_i, mat_r, mat_x;
  logic [15:0] mat_ptr, mat_cnt;
  logic        cid_ok;
  logic [6:0]  remain;

  assign cid_ok = (want >= 16'd1) && (want <= 16'd443);
  assign busy_o = (st != S_IDLE) && (st != S_DONE);
  assign want   = class_id_i[k];
  assign mat_go = (st == S_SCAN) && cid_ok;
  assign remain = (ntok > rd) ? (ntok - rd) : 7'd0;

  a7ng_typeclass_materialize u_mat (
    .clk(clk), .rst_n(rst_n),
    .go_i(mat_go), .class_id_i(want),
    .poison_en_i(1'b0), .poison_class_id_i(16'd0), .poison_eid_i(8'd0),
    .hit_o(mat_hit), .class_id_o(mat_cid),
    .eid_o(mat_e), .iid_o(mat_i), .rid_o(mat_r), .xid_o(mat_x),
    .member_ptr_o(mat_ptr), .member_count_o(mat_cnt)
  );

  always_comb begin
    beat_pack_o = 64'd0;
    for (bi = 0; bi < 8; bi = bi + 1)
      if ((rd + 7'(bi)) < ntok)
        beat_pack_o[8*bi +: 8] = tok[rd + 7'(bi)];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; k <= 4'd0; rec <= 4'd0; skp <= 4'd0;
      ntok <= 7'd0; rd <= 7'd0;
      done_o <= 1'b0; beat_v_o <= 1'b0; beat_n_o <= 4'd0;
      ntok_o <= 7'd0; n_rec_o <= 4'd0; n_skip_o <= 4'd0;
      for (ti = 0; ti < MAX_NTOK; ti = ti + 1) begin
        tok[ti] <= 8'd0;
        tok_o[ti] <= 8'd0;
      end
    end else begin
      done_o <= 1'b0;
      beat_v_o <= 1'b0;
      unique case (st)
        S_IDLE: begin
          if (go_i) begin
            k <= 4'd0; rec <= 4'd0; skp <= 4'd0; ntok <= 7'd0; rd <= 7'd0;
            for (ti = 0; ti < MAX_NTOK; ti = ti + 1) tok[ti] <= 8'd0;
            st <= S_SCAN;
          end
        end
        S_SCAN: begin
          if (k >= 4'(K))
            st <= S_BEAT;
          else if (cid_ok)
            st <= S_MAT;
          else begin
            skp <= skp + 4'd1;
            k <= k + 4'd1;
          end
        end
        S_MAT: st <= S_TAKE;
        S_TAKE: begin
          if (mat_hit && (ntok <= 7'(MAX_NTOK-4))) begin
            tok[ntok + 7'd0] <= mat_e;
            tok[ntok + 7'd1] <= mat_i;
            tok[ntok + 7'd2] <= mat_r;
            tok[ntok + 7'd3] <= mat_x;
            ntok <= ntok + 7'd4;
            rec <= rec + 4'd1;
          end else
            skp <= skp + 4'd1;
          k <= k + 4'd1;
          st <= S_SCAN;
        end
        S_BEAT: begin
          ntok_o <= ntok;
          n_rec_o <= rec;
          n_skip_o <= skp;
          for (ti = 0; ti < MAX_NTOK; ti = ti + 1) tok_o[ti] <= tok[ti];
          if (ntok == 7'd0) begin
            done_o <= 1'b1;
            st <= S_DONE;
          end else begin
            beat_v_o <= 1'b1;
            beat_n_o <= (remain >= 7'd8) ? 4'd8 : remain[3:0];
            if ((rd + 7'd8) >= ntok) begin
              done_o <= 1'b1;
              st <= S_DONE;
            end else
              rd <= rd + 7'd8;
          end
        end
        S_DONE: st <= S_IDLE;
        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
