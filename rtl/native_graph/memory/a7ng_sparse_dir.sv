// a7ng_sparse_dir.sv — U4-MEM02-SPARSE-DIRECTORY-00 scale-256
// 2 tables, bounded heads, explicit overflow/dedup. No full scan.
// PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_sparse_dir #(
  parameter int unsigned N_TABLES = 2,
  parameter int unsigned N_BUCKETS = 16,
  parameter int unsigned HEAD_CAP = 8,
  parameter int unsigned CAND_CAP = 32,
  parameter int unsigned ID_W = 20
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 wr_v,
  input  logic [0:0]           wr_table,
  input  logic [3:0]           wr_bucket,
  input  logic [ID_W-1:0]      wr_id,
  output logic                 wr_overflow_o,
  input  logic                 q_v,
  input  logic [15:0]          k0_i,
  input  logic [15:0]          k1_i,
  output logic                 cand_v_o,
  output logic [ID_W-1:0]      cand_id_o,
  output logic                 q_done_o,
  output logic [15:0]          n_emit_o,
  output logic [15:0]          n_dup_o,
  output logic [15:0]          n_trunc_o
);
  logic [ID_W-1:0] head [0:1][0:15][0:7];
  logic [3:0]      hlen [0:1][0:15];
  logic [ID_W-1:0] seen [0:31];
  logic [5:0]      nseen;
  logic [1:0]      t;
  logic [3:0]      hi;
  logic            busy;
  logic [15:0]     nemit, ndup, ntrunc;
  logic [3:0]      bsel;
  logic [ID_W-1:0] rid;
  integer ti, bi, si;
  logic            is_dup;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_overflow_o <= 1'b0;
      cand_v_o <= 1'b0;
      cand_id_o <= '0;
      q_done_o <= 1'b0;
      n_emit_o <= 16'd0;
      n_dup_o <= 16'd0;
      n_trunc_o <= 16'd0;
      busy <= 1'b0;
      t <= 2'd0;
      hi <= 4'd0;
      nseen <= 6'd0;
      nemit <= 16'd0;
      ndup <= 16'd0;
      ntrunc <= 16'd0;
      for (ti = 0; ti < 2; ti = ti + 1)
        for (bi = 0; bi < 16; bi = bi + 1)
          hlen[ti][bi] <= 4'd0;
    end else begin
      wr_overflow_o <= 1'b0;
      cand_v_o <= 1'b0;
      q_done_o <= 1'b0;
      if (wr_v && !busy) begin
        if (hlen[wr_table][wr_bucket] >= HEAD_CAP[3:0])
          wr_overflow_o <= 1'b1;
        else begin
          head[wr_table][wr_bucket][hlen[wr_table][wr_bucket][2:0]] <= wr_id;
          hlen[wr_table][wr_bucket] <= hlen[wr_table][wr_bucket] + 4'd1;
        end
      end else if (q_v && !busy) begin
        busy <= 1'b1;
        t <= 2'd0;
        hi <= 4'd0;
        nseen <= 6'd0;
        nemit <= 16'd0;
        ndup <= 16'd0;
        ntrunc <= 16'd0;
      end else if (busy) begin
        bsel = (t == 2'd0) ? k0_i[3:0] : k1_i[3:0];
        if (t >= 2'd2) begin
          busy <= 1'b0;
          q_done_o <= 1'b1;
          n_emit_o <= nemit;
          n_dup_o <= ndup;
          n_trunc_o <= ntrunc;
        end else if (hi >= hlen[t[0]][bsel]) begin
          t <= t + 2'd1;
          hi <= 4'd0;
        end else begin
          rid = head[t[0]][bsel][hi[2:0]];
          is_dup = 1'b0;
          for (si = 0; si < 32; si = si + 1)
            if ((si < nseen) && (seen[si] == rid))
              is_dup = 1'b1;
          if (is_dup)
            ndup <= ndup + 16'd1;
          else if (nemit >= CAND_CAP[15:0])
            ntrunc <= ntrunc + 16'd1;
          else begin
            cand_v_o <= 1'b1;
            cand_id_o <= rid;
            seen[nseen] <= rid;
            nseen <= nseen + 6'd1;
            nemit <= nemit + 16'd1;
          end
          hi <= hi + 4'd1;
        end
      end
    end
  end
endmodule
