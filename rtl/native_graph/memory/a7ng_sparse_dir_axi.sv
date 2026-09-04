// a7ng_sparse_dir_axi.sv — U4-R2-DDR-SPARSE-DIRECTORY-00
// AXI DDR directory + posting walker. No on-chip [T][B][H][C] geometry.
// PROGRAM=NO. SoC integration = NO.
`timescale 1ns / 1ps

module a7ng_sparse_dir_axi #(
  parameter int unsigned N_TABLES   = 2,
  parameter int unsigned N_BUCKETS  = 16,
  parameter int unsigned CAND_CAP   = 32,
  parameter int unsigned ID_W       = 20,
  parameter logic [27:0] INDEX_BASE = 28'h0500_0000
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic [15:0]          live_epoch_i,
  input  logic                 q_v,
  output logic                 q_ready,
  input  logic [15:0]          k0_i,
  input  logic [15:0]          k1_i,
  output logic                 cand_v,
  input  logic                 cand_ready,
  output logic [ID_W-1:0]      cand_id,
  output logic                 q_done,
  output logic                 q_overflow_o,
  output logic [15:0]          n_emit_o,
  output logic [15:0]          n_dup_o,
  output logic [15:0]          n_trunc_o,
  output logic [3:0]           m_axi_arid,
  output logic [27:0]          m_axi_araddr,
  output logic [7:0]           m_axi_arlen,
  output logic [2:0]           m_axi_arsize,
  output logic [1:0]           m_axi_arburst,
  output logic                 m_axi_arvalid,
  input  logic                 m_axi_arready,
  input  logic [3:0]           m_axi_rid,
  input  logic [127:0]         m_axi_rdata,
  input  logic [1:0]           m_axi_rresp,
  input  logic                 m_axi_rlast,
  input  logic                 m_axi_rvalid,
  output logic                 m_axi_rready
);
  localparam int unsigned B_W = (N_BUCKETS <= 1) ? 1 : $clog2(N_BUCKETS);
  localparam int unsigned T_W = (N_TABLES  <= 1) ? 1 : $clog2(N_TABLES);
  localparam int unsigned C_W = (CAND_CAP  <= 1) ? 1 : $clog2(CAND_CAP);

  typedef enum logic [2:0] {
    S_IDLE, S_ARDIR, S_RDIR, S_ARPOST, S_RPOST, S_DRAIN, S_NEXT, S_DONE
  } st_t;
  st_t st;

  logic [T_W-1:0]  t;
  logic [27:0]     dir_addr, post_base;
  logic [15:0]     post_count, epoch, left;
  logic            ovf_ent, ovf_q, last_r, have_beat;
  logic [1:0]      lane;
  logic [127:0]    beat;
  logic [ID_W-1:0] seen [0:CAND_CAP-1];
  logic [C_W:0]    nseen;
  logic [15:0]     nemit, ndup, ntrunc;
  logic [7:0]      arlen_post;
  logic            stall, step, is_dup;
  logic [ID_W-1:0] rid;
  logic [15:0]     k_use;
  integer          si;

  function automatic logic [15:0] key_of(input logic [T_W-1:0] tt);
    if (tt == '0) return k0_i;
    if ((N_TABLES > 1) && (tt == T_W'(1))) return k1_i;
    return (k0_i ^ k1_i) ^ {8'd0, 8'(tt)};
  endfunction

  assign q_ready       = (st == S_IDLE);
  assign m_axi_arid    = 4'd1;
  assign m_axi_arsize  = 3'd4;
  assign m_axi_arburst = 2'b01;
  assign stall         = cand_v && !cand_ready;

  always_comb begin
    k_use    = key_of(t);
    dir_addr = INDEX_BASE + {{(28-4-B_W-T_W){1'b0}}, t, k_use[B_W-1:0], 4'b0000};
    if (post_count == 16'd0)
      arlen_post = 8'd0;
    else
      arlen_post = 8'(((post_count + 16'd3) >> 2) - 16'd1);
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      t <= '0;
      m_axi_arvalid <= 1'b0;
      m_axi_araddr  <= '0;
      m_axi_arlen   <= 8'd0;
      m_axi_rready  <= 1'b0;
      cand_v <= 1'b0;
      cand_id <= '0;
      q_done <= 1'b0;
      q_overflow_o <= 1'b0;
      n_emit_o <= '0; n_dup_o <= '0; n_trunc_o <= '0;
      post_base <= '0; post_count <= '0; epoch <= '0;
      ovf_ent <= 1'b0; ovf_q <= 1'b0; last_r <= 1'b0;
      left <= '0; lane <= 2'd0; beat <= '0; have_beat <= 1'b0;
      nseen <= '0; nemit <= '0; ndup <= '0; ntrunc <= '0;
    end else begin
      q_done <= 1'b0;
      if (cand_v && cand_ready)
        cand_v <= 1'b0;

      unique case (st)
        S_IDLE: begin
          m_axi_arvalid <= 1'b0;
          m_axi_rready  <= 1'b0;
          cand_v <= 1'b0;
          if (q_v) begin
            t <= '0;
            nseen <= '0; nemit <= '0; ndup <= '0; ntrunc <= '0;
            ovf_q <= 1'b0;
            st <= S_ARDIR;
          end
        end

        S_ARDIR: begin
          m_axi_araddr  <= dir_addr;
          m_axi_arlen   <= 8'd0;
          m_axi_arvalid <= 1'b1;
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b1;
            st <= S_RDIR;
          end
        end

        S_RDIR: begin
          m_axi_rready <= 1'b1;
          if (m_axi_rvalid && m_axi_rready) begin
            m_axi_rready <= 1'b0;
            post_base  <= m_axi_rdata[27:0];
            post_count <= m_axi_rdata[47:32];
            ovf_ent    <= m_axi_rdata[48];
            epoch      <= m_axi_rdata[79:64];
            if (m_axi_rdata[48])
              ovf_q <= 1'b1;
            if ((m_axi_rdata[47:32] == 16'd0) ||
                (m_axi_rdata[79:64] != live_epoch_i))
              st <= S_NEXT;
            else begin
              left <= m_axi_rdata[47:32];
              lane <= 2'd0;
              have_beat <= 1'b0;
              last_r <= 1'b0;
              st <= S_ARPOST;
            end
          end
        end

        S_ARPOST: begin
          m_axi_araddr  <= post_base;
          m_axi_arlen   <= arlen_post;
          m_axi_arvalid <= 1'b1;
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            st <= S_RPOST;
          end
        end

        S_RPOST: begin
          m_axi_rready <= (!have_beat) && !stall;
          if (m_axi_rvalid && m_axi_rready) begin
            beat      <= m_axi_rdata;
            last_r    <= m_axi_rlast;
            have_beat <= 1'b1;
            lane      <= 2'd0;
            m_axi_rready <= 1'b0;
          end

          step = have_beat && !stall && (left != 16'd0);
          if (step) begin
            rid = beat[32*lane +: ID_W];
            is_dup = 1'b0;
            for (si = 0; si < CAND_CAP; si = si + 1)
              if ((si < 32'(nseen)) && (seen[si] == rid))
                is_dup = 1'b1;
            if (is_dup)
              ndup <= ndup + 16'd1;
            else if (nemit >= CAND_CAP[15:0])
              ntrunc <= ntrunc + 16'd1;
            else begin
              cand_v <= 1'b1;
              cand_id <= rid;
              seen[nseen[C_W-1:0]] <= rid;
              nseen <= nseen + 1'b1;
              nemit <= nemit + 16'd1;
            end
            left <= left - 16'd1;
            if (lane == 2'd3)
              have_beat <= 1'b0;
            else
              lane <= lane + 2'd1;
          end

          // Burst leftover after IDs exhausted or cap hit: drain R.
          if (!stall && (left == 16'd0) && !cand_v) begin
            if (have_beat)
              have_beat <= 1'b0;
            if (last_r || (!have_beat && !m_axi_rvalid && !m_axi_arvalid))
              st <= S_NEXT;
            else if (have_beat && last_r)
              st <= S_NEXT;
            else if (!have_beat)
              st <= S_DRAIN;
          end
        end

        S_DRAIN: begin
          m_axi_rready <= 1'b1;
          if (m_axi_rvalid && m_axi_rready && m_axi_rlast) begin
            m_axi_rready <= 1'b0;
            last_r <= 1'b1;
            st <= S_NEXT;
          end
        end

        S_NEXT: begin
          m_axi_rready <= 1'b0;
          have_beat <= 1'b0;
          if (stall) begin
            // wait last cand handshake
          end else if (t == T_W'(N_TABLES-1))
            st <= S_DONE;
          else begin
            t <= t + T_W'(1);
            st <= S_ARDIR;
          end
        end

        S_DONE: begin
          cand_v <= 1'b0;
          q_done <= 1'b1;
          q_overflow_o <= ovf_q;
          n_emit_o <= nemit;
          n_dup_o <= ndup;
          n_trunc_o <= ntrunc;
          st <= S_IDLE;
        end

        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
