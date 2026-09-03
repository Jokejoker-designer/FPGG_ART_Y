// Bind-only NG02 occupancy. NO production RTL. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_ng02_latency_probe (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        core_fire,
  input logic        core_topk_valid,
  input logic [2:0]  ng_st,
  input logic        sched_idle,
  input logic [2:0]  g_st
);
  // ng: IDLE=0 FIRE=1 WAIT=2 STREAM=3 COLLECT=4 COMMIT=5 PUSH=6
  logic running_d, fire_d, topk_d, drain;
  integer occ_fire, occ_wait, occ_stream, occ_collect, occ_commit, occ_push;
  integer c_l, ling, cl_max, push_after, pat, issue_to_idle, iti, iti_max;
  integer nw;
  integer cl_w [0:7];
  integer fi_w [0:7];
  integer wa_w [0:7];
  integer st_w [0:7];
  integer co_w [0:7];
  integer cm_w [0:7];
  integer pu_w [0:7];
  integer t_fi, t_wa, t_st, t_co, t_cm, t_pu;
  integer ri, rj;
  logic printed;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; fire_d <= 0; topk_d <= 0; drain <= 0;
      occ_fire <= 0; occ_wait <= 0; occ_stream <= 0; occ_collect <= 0;
      occ_commit <= 0; occ_push <= 0;
      c_l <= 0; ling <= 0; cl_max <= 0; push_after <= 0; pat <= 0;
      issue_to_idle <= 0; iti <= 0; iti_max <= 0; nw <= 0;
      t_fi <= 0; t_wa <= 0; t_st <= 0; t_co <= 0; t_cm <= 0; t_pu <= 0;
      for (ri = 0; ri < 8; ri = ri + 1) begin
        cl_w[ri] <= 0; fi_w[ri] <= 0; wa_w[ri] <= 0; st_w[ri] <= 0;
        co_w[ri] <= 0; cm_w[ri] <= 0; pu_w[ri] <= 0;
      end
    end else begin
      running_d <= running;
      fire_d <= core_fire;
      topk_d <= core_topk_valid;
      if (running && !running_d) begin
        drain <= 1;
        occ_fire <= 0; occ_wait <= 0; occ_stream <= 0; occ_collect <= 0;
        occ_commit <= 0; occ_push <= 0;
        c_l <= 0; ling <= 0; cl_max <= 0; push_after <= 0; pat <= 0;
        issue_to_idle <= 0; iti <= 0; iti_max <= 0; nw <= 0;
        t_fi <= 0; t_wa <= 0; t_st <= 0; t_co <= 0; t_cm <= 0; t_pu <= 0;
        for (ri = 0; ri < 8; ri = ri + 1) begin
          cl_w[ri] <= 0; fi_w[ri] <= 0; wa_w[ri] <= 0; st_w[ri] <= 0;
          co_w[ri] <= 0; cm_w[ri] <= 0; pu_w[ri] <= 0;
        end
      end else if (running || drain) begin
        if (!running && drain && sched_idle && (ng_st == 3'd0) && (g_st == 3'd0))
          drain <= 0;
        if (ng_st == 3'd1) occ_fire <= occ_fire + 1;
        if (ng_st == 3'd2) occ_wait <= occ_wait + 1;
        if (ng_st == 3'd3) occ_stream <= occ_stream + 1;
        if (ng_st == 3'd4) occ_collect <= occ_collect + 1;
        if (ng_st == 3'd5) occ_commit <= occ_commit + 1;
        if (ng_st == 3'd6) occ_push <= occ_push + 1;

        if (core_fire && !fire_d) begin
          c_l <= 1; ling <= 1; iti <= 1; issue_to_idle <= 1;
          t_fi <= 0; t_wa <= 0; t_st <= 0; t_co <= 0; t_cm <= 0; t_pu <= 0;
        end else if (ling) begin
          c_l <= c_l + 1;
          if (ng_st == 3'd1) t_fi <= t_fi + 1;
          if (ng_st == 3'd2) t_wa <= t_wa + 1;
          if (ng_st == 3'd3) t_st <= t_st + 1;
          if (ng_st == 3'd4) t_co <= t_co + 1;
          if (ng_st == 3'd5) t_cm <= t_cm + 1;
          if (core_topk_valid && !topk_d) begin
            if (c_l + 1 > cl_max) cl_max <= c_l + 1;
            if (nw < 8) begin
              cl_w[nw] <= c_l + 1;
              fi_w[nw] <= t_fi;
              wa_w[nw] <= t_wa;
              st_w[nw] <= t_st;
              co_w[nw] <= t_co;
              cm_w[nw] <= t_cm + 1;
            end
            ling <= 0;
            pat <= 1;
          end
        end
        if (pat && (ng_st == 3'd6)) begin
          t_pu <= t_pu + 1;
          push_after <= push_after + 1;
        end
        if (issue_to_idle) begin
          iti <= iti + 1;
          if (ng_st == 3'd0) begin
            if (iti > iti_max) iti_max <= iti;
            if (nw < 8) pu_w[nw] <= t_pu;
            nw <= nw + 1;
            issue_to_idle <= 0;
            pat <= 0;
          end
        end
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      printed = 1'b0;
    else if (running && !running_d)
      printed = 1'b0;
    else if (!printed && !running && sched_idle && (ng_st == 3'd0) && (g_st == 3'd0) && (nw > 0)) begin
      printed = 1'b1;
      $display("LOCAL_CORE_AUDIT_DONE waves=%0d C_L_MAX=%0d ISSUE_TO_IDLE_MAX=%0d",
               nw, cl_max, iti_max);
      $display("LOCAL_CORE_OCC FIRE=%0d WAIT=%0d STREAM=%0d COLLECT=%0d COMMIT=%0d PUSH=%0d",
               occ_fire, occ_wait, occ_stream, occ_collect, occ_commit, occ_push);
      $display("LOCAL_CORE_PUSH_AFTER_TOPK=%0d", push_after);
      for (rj = 0; rj < nw && rj < 8; rj = rj + 1)
        $display("LOCAL_CORE_WAVE%0d C_L=%0d FIRE=%0d WAIT=%0d STREAM=%0d COLLECT=%0d COMMIT=%0d PUSH=%0d",
                 rj, cl_w[rj], fi_w[rj], wa_w[rj], st_w[rj], co_w[rj], cm_w[rj], pu_w[rj]);
      if (occ_wait >= occ_stream && occ_wait >= occ_collect && occ_wait >= occ_push)
        $display("LOCAL_CORE_DOMINANT=SCORER_WAIT");
      else if (occ_stream >= occ_collect && occ_stream >= occ_push)
        $display("LOCAL_CORE_DOMINANT=HEAP_STREAM");
      else if (occ_collect >= occ_push)
        $display("LOCAL_CORE_DOMINANT=HEAP_COLLECT");
      else
        $display("LOCAL_CORE_DOMINANT=FRONTIER_PUSH");
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_ng02_latency_probe u_g14_ng02_lat (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .core_fire(|core_valid),
  .core_topk_valid(core_topk_valid),
  .ng_st(u_core.state),
  .sched_idle(sched_idle),
  .g_st(u_global.st)
);
