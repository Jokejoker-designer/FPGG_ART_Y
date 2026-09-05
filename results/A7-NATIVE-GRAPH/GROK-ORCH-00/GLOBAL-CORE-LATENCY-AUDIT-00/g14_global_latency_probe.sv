// Bind-only global minheap occupancy. NO production RTL. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_global_latency_probe (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        sched_idle,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic [1:0]  hf_dir,
  input logic [3:0]  wave_i,
  input logic [4:0]  wave_n,
  input logic [4:0]  wave_scored_i,
  input logic        wave_valid_i,
  input logic        global_valid_o,
  input logic        busy_o,
  input logic        global_topk_busy,
  input logic [2:0]  soa_st,
  input logic [31:0] merge_count_o,
  input a7ng_pkg::score_t   wave_score_i [8],
  input a7ng_pkg::node_id_t wave_id_i    [8],
  input a7ng_pkg::score_t   global_score_o [8],
  input a7ng_pkg::node_id_t global_id_o    [8],
  input logic [7:0]         h_valid,
  input a7ng_pkg::score_t   h0_s,
  input a7ng_pkg::node_id_t h0_id,
  input logic [3:0]         h0_lane,
  input a7ng_pkg::score_t   w_s [8],
  input a7ng_pkg::node_id_t w_id [8]
);
  import a7ng_pkg::*;

  localparam logic [2:0] ST_IDLE    = 3'd0;
  localparam logic [2:0] ST_CAND    = 3'd1;
  localparam logic [2:0] ST_HEAPIFY = 3'd2;
  localparam logic [2:0] ST_NEXT    = 3'd3;
  localparam logic [2:0] ST_SORT    = 3'd4;
  localparam logic [2:0] ST_COMMIT  = 3'd5;
  localparam logic [1:0] HF_UP      = 2'd1;
  localparam logic [1:0] HF_DOWN    = 2'd2;

  function automatic logic beats_sc(score_t sa, node_id_t ida, logic [3:0] la,
                                    score_t sb, node_id_t idb, logic [3:0] lb);
    if (sa != sb) return sa > sb;
    if (ida != idb) return ida < idb;
    return la < lb;
  endfunction

  function automatic logic [3:0] first_empty();
    integer e;
    first_empty = 4'd8;
    for (e = 0; e < 8; e = e + 1)
      if (!h_valid[e] && first_empty == 4'd8)
        first_empty = 4'(e);
  endfunction

  logic running_d, g_valid_d, drain, printed, ging;
  logic [2:0] g_st_d;
  integer nw, drop, dup, deadlock, inflight;
  integer busy_cyc, blk_up;
  integer occ_cand, occ_hf, occ_next, occ_sort, occ_commit;
  integer t_cand, t_hf, t_next, t_sort, t_commit;
  integer t_empty, t_repl, t_rej, t_acc, t_up, t_dn;
  integer c_cand [0:7], c_hf [0:7], c_next [0:7], c_sort [0:7], c_commit [0:7];
  integer c_total [0:7], c_gcand [0:7], c_gsort [0:7], c_gcommit [0:7];
  integer c_empty [0:7], c_repl [0:7], c_rej [0:7], c_accepted [0:7];
  integer c_up [0:7], c_dn [0:7], c_wn [0:7];
  integer ri, k;
  score_t   in_s [0:7][0:7];
  node_id_t in_id [0:7][0:7];
  score_t   out_s [0:7][0:7];
  node_id_t out_id [0:7][0:7];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; g_valid_d <= 0; drain <= 0; g_st_d <= 3'd0; ging <= 0;
      nw <= 0; drop <= 0; dup <= 0; deadlock <= 0; inflight <= 0;
      busy_cyc <= 0; blk_up <= 0;
      occ_cand <= 0; occ_hf <= 0; occ_next <= 0; occ_sort <= 0; occ_commit <= 0;
      t_cand <= 0; t_hf <= 0; t_next <= 0; t_sort <= 0; t_commit <= 0;
      t_empty <= 0; t_repl <= 0; t_rej <= 0; t_acc <= 0; t_up <= 0; t_dn <= 0;
      for (ri = 0; ri < 8; ri = ri + 1) begin
        c_cand[ri] <= 0; c_hf[ri] <= 0; c_next[ri] <= 0; c_sort[ri] <= 0;
        c_commit[ri] <= 0; c_total[ri] <= 0; c_gcand[ri] <= 0; c_gsort[ri] <= 0;
        c_gcommit[ri] <= 0; c_empty[ri] <= 0; c_repl[ri] <= 0; c_rej[ri] <= 0;
        c_accepted[ri] <= 0; c_up[ri] <= 0; c_dn[ri] <= 0; c_wn[ri] <= 0;
      end
    end else begin
      running_d <= running;
      g_valid_d <= global_valid_o;
      g_st_d <= g_st;

      if (running && !running_d) begin
        drain <= 1; ging <= 0;
        nw <= 0; drop <= 0; dup <= 0; deadlock <= 0; inflight <= 0;
        busy_cyc <= 0; blk_up <= 0;
        occ_cand <= 0; occ_hf <= 0; occ_next <= 0; occ_sort <= 0; occ_commit <= 0;
        t_cand <= 0; t_hf <= 0; t_next <= 0; t_sort <= 0; t_commit <= 0;
        t_empty <= 0; t_repl <= 0; t_rej <= 0; t_acc <= 0; t_up <= 0; t_dn <= 0;
        for (ri = 0; ri < 8; ri = ri + 1) begin
          c_cand[ri] <= 0; c_hf[ri] <= 0; c_next[ri] <= 0; c_sort[ri] <= 0;
          c_commit[ri] <= 0; c_total[ri] <= 0; c_gcand[ri] <= 0; c_gsort[ri] <= 0;
          c_gcommit[ri] <= 0; c_empty[ri] <= 0; c_repl[ri] <= 0; c_rej[ri] <= 0;
          c_accepted[ri] <= 0; c_up[ri] <= 0; c_dn[ri] <= 0; c_wn[ri] <= 0;
        end
      end else if (running || drain) begin
        if (!running && drain && sched_idle && (ng_st == 3'd0) && (g_st == ST_IDLE))
          drain <= 0;

        if (busy_o) busy_cyc <= busy_cyc + 1;
        if ((soa_st == 3'd3) && global_topk_busy) blk_up <= blk_up + 1;

        if (wave_valid_i && (g_st != ST_IDLE))
          drop <= drop + 1;
        if (wave_valid_i && ging)
          dup <= dup + 1;

        if ((g_st != ST_IDLE) && (g_st_d == ST_IDLE)) begin
          ging <= 1;
          inflight <= inflight + 1;
          t_cand <= (g_st == ST_CAND) ? 1 : 0;
          t_hf <= 0; t_next <= 0; t_sort <= 0; t_commit <= 0;
          if (g_st == ST_CAND) occ_cand <= occ_cand + 1;
          t_empty <= 0; t_repl <= 0; t_rej <= 0; t_acc <= 0; t_up <= 0; t_dn <= 0;
          if (nw < 8) begin
            for (k = 0; k < 8; k = k + 1) begin
              in_s[nw][k]  <= w_s[k];
              in_id[nw][k] <= w_id[k];
            end
          end
          if (g_st == ST_CAND && wave_n != 5'd0) begin
            if (first_empty() != 4'd8) begin
              t_empty <= 1; t_acc <= 1;
            end else if (beats_sc(w_s[wave_i], w_id[wave_i], 4'(8 + wave_i),
                                  h0_s, h0_id, h0_lane)) begin
              t_repl <= 1; t_acc <= 1;
            end else
              t_rej <= 1;
          end
        end else begin
          if (g_st == ST_CAND) begin
            occ_cand <= occ_cand + 1;
            t_cand <= t_cand + 1;
            if (wave_n != 5'd0) begin
              if (first_empty() != 4'd8) begin
                t_empty <= t_empty + 1;
                t_acc <= t_acc + 1;
              end else if (beats_sc(w_s[wave_i], w_id[wave_i], 4'(8 + wave_i),
                                    h0_s, h0_id, h0_lane)) begin
                t_repl <= t_repl + 1;
                t_acc <= t_acc + 1;
              end else
                t_rej <= t_rej + 1;
            end
          end
          if (g_st == ST_HEAPIFY) begin
            occ_hf <= occ_hf + 1;
            t_hf <= t_hf + 1;
            if (hf_dir == HF_UP) t_up <= t_up + 1;
            if (hf_dir == HF_DOWN) t_dn <= t_dn + 1;
          end
          if (g_st == ST_NEXT) begin
            occ_next <= occ_next + 1;
            t_next <= t_next + 1;
          end
          if (g_st == ST_SORT) begin
            occ_sort <= occ_sort + 1;
            t_sort <= t_sort + 1;
          end
          if (g_st == ST_COMMIT) begin
            occ_commit <= occ_commit + 1;
            t_commit <= t_commit + 1;
          end
        end

        if (global_valid_o && !g_valid_d && (nw < 8)) begin
          for (k = 0; k < 8; k = k + 1) begin
            out_s[nw][k]  <= global_score_o[k];
            out_id[nw][k] <= global_id_o[k];
          end
          c_cand[nw]     <= t_cand;
          c_hf[nw]       <= t_hf;
          c_next[nw]     <= t_next;
          c_sort[nw]     <= t_sort;
          c_commit[nw]   <= t_commit + 1;
          c_gcand[nw]    <= t_cand + t_hf + t_next;
          c_gsort[nw]    <= t_sort;
          c_gcommit[nw]  <= t_commit + 1;
          c_total[nw]    <= t_cand + t_hf + t_next + t_sort + t_commit + 1;
          c_empty[nw]    <= t_empty;
          c_repl[nw]     <= t_repl;
          c_rej[nw]      <= t_rej;
          c_accepted[nw] <= t_acc;
          c_up[nw]       <= t_up;
          c_dn[nw]       <= t_dn;
          c_wn[nw]       <= integer'(wave_n);
          nw <= nw + 1;
          ging <= 0;
          inflight <= (inflight > 0) ? (inflight - 1) : 0;
        end
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      printed = 1'b0;
    else if (running && !running_d)
      printed = 1'b0;
    else if (!printed && !running && sched_idle && (ng_st == 3'd0) &&
             (g_st == ST_IDLE) && (nw == 4) && (merge_count_o == 32'd4) &&
             (inflight == 0)) begin
      printed = 1'b1;
      begin : gprint
      integer rj, pk, pj, phit, pdead, sort_ok, merge_ok, cand8_ok, w0_set_ok, order_ok, cg_max, cg_sum;
      pdead = inflight;
      sort_ok = 1; merge_ok = (integer'(merge_count_o) == nw); cand8_ok = 1;
      w0_set_ok = 1; order_ok = 1; cg_max = 0; cg_sum = 0;
      for (rj = 0; rj < nw && rj < 8; rj = rj + 1) begin
        if (c_total[rj] > cg_max) cg_max = c_total[rj];
        cg_sum = cg_sum + c_total[rj];
        if (c_sort[rj] != 28) sort_ok = 0;
        if ((c_accepted[rj] + c_rej[rj]) != 8) cand8_ok = 0;
        if (c_wn[rj] != 8) cand8_ok = 0;
        for (pk = 0; pk < 7; pk = pk + 1)
          if (!beats_sc(out_s[rj][pk], out_id[rj][pk], 4'd0,
                        out_s[rj][pk+1], out_id[rj][pk+1], 4'd1))
            order_ok = 0;
      end
      if (nw > 0) begin
        for (pk = 0; pk < 8; pk = pk + 1) begin
          phit = 0;
          for (pj = 0; pj < 8; pj = pj + 1)
            if ((in_id[0][pk] === out_id[0][pj]) && (in_s[0][pk] === out_s[0][pj]))
              phit = 1;
          if (!phit) w0_set_ok = 0;
        end
      end

      $display("GLOBAL_CORE_AUDIT_DONE waves=%0d merges=%0d C_G_MAX=%0d C_G_AVG=%0d ST_SORT_OK=%0d",
               nw, merge_count_o, cg_max, (nw>0)?(cg_sum/nw):0, sort_ok);
      $display("GLOBAL_CORE_OCC CAND=%0d HEAPIFY=%0d NEXT=%0d SORT=%0d COMMIT=%0d BUSY=%0d BLK_UP=%0d",
               occ_cand, occ_hf, occ_next, occ_sort, occ_commit, busy_cyc, blk_up);
      $display("GLOBAL_CORE_SEM drop=%0d dup=%0d deadlock=%0d inflight=%0d wave_scored_pin=%0d",
               drop, dup, pdead, inflight, wave_scored_i);
      $display("GLOBAL_CORE_CHECKS sort28=%0d cand8=%0d merge_eq_waves=%0d w0_set=%0d out_order=%0d",
               sort_ok, cand8_ok, merge_ok, w0_set_ok, order_ok);

      for (rj = 0; rj < nw && rj < 8; rj = rj + 1) begin
        $display("GLOBAL_CORE_WAVE%0d C_G_TOTAL=%0d C_G_CAND=%0d C_G_SORT=%0d C_G_COMMIT=%0d",
                 rj, c_total[rj], c_gcand[rj], c_gsort[rj], c_gcommit[rj]);
        $display("GLOBAL_CORE_WAVE%0d ST_CAND=%0d ST_HEAPIFY=%0d ST_NEXT=%0d ST_SORT=%0d ST_COMMIT=%0d",
                 rj, c_cand[rj], c_hf[rj], c_next[rj], c_sort[rj], c_commit[rj]);
        $display("GLOBAL_CORE_WAVE%0d CAND_ACCEPTED=%0d FIRST_EMPTY=%0d ROOT_REPL=%0d REJECTED=%0d wave_n=%0d",
                 rj, c_accepted[rj], c_empty[rj], c_repl[rj], c_rej[rj], c_wn[rj]);
        $display("GLOBAL_CORE_WAVE%0d HF_UP=%0d HF_DOWN=%0d",
                 rj, c_up[rj], c_dn[rj]);
        $write("GLOBAL_CORE_WAVE%0d INPUT_TOP8_SET", rj);
        for (pk = 0; pk < 8; pk = pk + 1)
          $write(" id=%0d,s=%0d", in_id[rj][pk], in_s[rj][pk]);
        $write("\n");
        $write("GLOBAL_CORE_WAVE%0d OUTPUT_TOP8_ORDER", rj);
        for (pk = 0; pk < 8; pk = pk + 1)
          $write(" id=%0d,s=%0d", out_id[rj][pk], out_s[rj][pk]);
        $write("\n");
        $write("GLOBAL_CORE_WAVE%0d OUTPUT_TOP8_SET", rj);
        for (pk = 0; pk < 8; pk = pk + 1)
          $write(" id=%0d,s=%0d", out_id[rj][pk], out_s[rj][pk]);
        $write("\n");
      end

      if ((nw == 4) && (merge_count_o == 32'd4) && (drop == 0) && (dup == 0) &&
          (pdead == 0) && sort_ok && cand8_ok && order_ok)
        $display("GLOBAL_CORE_AUDIT_PASS");
      else
        $display("GLOBAL_CORE_AUDIT_FAIL waves=%0d merges=%0d drop=%0d dup=%0d deadlock=%0d sort28=%0d cand8=%0d",
                 nw, merge_count_o, drop, dup, pdead, sort_ok, cand8_ok);
      end
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_global_latency_probe u_g14_glat (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .sched_idle(sched_idle),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .hf_dir(u_global.hf_dir),
  .wave_i(u_global.wave_i),
  .wave_n(u_global.wave_n),
  .wave_scored_i(u_global.wave_scored_i),
  .wave_valid_i(core_topk_valid),
  .global_valid_o(global_topk_valid),
  .busy_o(global_topk_busy),
  .global_topk_busy(global_topk_busy),
  .soa_st(u_soa.st),
  .merge_count_o(global_merge_count),
  .wave_score_i(core_topk_score),
  .wave_id_i(core_topk_id),
  .global_score_o(global_topk_score),
  .global_id_o(global_topk_id),
  .h_valid({u_global.h[7].v, u_global.h[6].v, u_global.h[5].v, u_global.h[4].v,
            u_global.h[3].v, u_global.h[2].v, u_global.h[1].v, u_global.h[0].v}),
  .h0_s(u_global.h[0].s),
  .h0_id(u_global.h[0].id),
  .h0_lane(u_global.h[0].lane),
  .w_s(u_global.w_s),
  .w_id(u_global.w_id)
);
