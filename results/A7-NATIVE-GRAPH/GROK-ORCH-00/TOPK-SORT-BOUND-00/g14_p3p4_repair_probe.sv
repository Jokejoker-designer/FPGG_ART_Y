// Bind probe: stage service times on a7ng_cue_soa_mig_top. NO RTL EDIT.
`timescale 1ps / 100fs

module g14_p3p4_repair_probe #(parameter int PHYS = 4, parameter int NWMAX = 8) (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        done,
  input logic        wave_valid,
  input logic        wf_cons_ready,
  input logic        sched_idle,
  input logic        tg_ready,
  input logic        core_batch_ready,
  input logic        global_topk_busy,
  input logic        core_fire,
  input logic        core_topk_valid,
  input logic        global_topk_valid,
  input logic        ar_fire,
  input logic [1:0]  sch,
  input logic [2:0]  soa_st,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic [31:0] empty_st,
  input logic [31:0] axi_bytes,
  input logic [31:0] delivered,
  input logic [31:0] waves,
  input logic [31:0] cycles
);
  // soa: IDLE=0 ARM=1 FETCH=2 HOLD=3 DONE=4
  // sch: IDLE=0 FIRE=1 WAIT=2 ISSUE=3
  // ng:  IDLE=0 FIRE=1 WAIT=2 STREAM=3 COLLECT=4 COMMIT=5 PUSH=6
  // g:   IDLE=0 CAND=1 HEAPIFY=2 NEXT=3 SORT=4 COMMIT=5

  logic running_d, wave_d, core_fire_d, core_topk_d, g_valid_d;
  logic drain, drain_d;
  logic [1:0] sch_d;
  logic [2:0] soa_st_d, ng_st_d, g_st_d;

  integer elig, run_cyc;
  integer ddr_occ, tg_occ, ng_occ, ng_push, g_occ, g_sort;
  integer c_d_exp, blk_g, blk_core, blk_sched, blk_tg, blk_hold;
  integer overlap2, overlap3, ar_cnt;
  integer fetch_w, acc_w, tg_w, l_w, g_w;
  integer t_d, t_t, t_l, t_g, fetching, tging, ling, ging;
  integer c_d [0:NWMAX-1];
  integer c_t [0:NWMAX-1];
  integer c_l [0:NWMAX-1];
  integer c_g [0:NWMAX-1];
  integer t_acc [0:NWMAX-1];
  integer ri;
  integer pi;
  integer nbusy;

  function automatic integer imax4(input integer a, input integer b,
                                   input integer c, input integer d);
    integer m;
    m = a;
    if (b > m) m = b;
    if (c > m) m = c;
    if (d > m) m = d;
    imax4 = m;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 1'b0; wave_d <= 1'b0; core_fire_d <= 1'b0;
      core_topk_d <= 1'b0; g_valid_d <= 1'b0;
      drain <= 1'b0; drain_d <= 1'b0;
      sch_d <= 2'd0; soa_st_d <= 3'd0; ng_st_d <= 3'd0; g_st_d <= 3'd0;
      elig <= 0; run_cyc <= 0; ddr_occ <= 0; tg_occ <= 0; ng_occ <= 0; ng_push <= 0;
      g_occ <= 0; g_sort <= 0; c_d_exp <= 0;
      blk_g <= 0; blk_core <= 0; blk_sched <= 0; blk_tg <= 0; blk_hold <= 0;
      overlap2 <= 0; overlap3 <= 0; ar_cnt <= 0;
      fetch_w <= 0; acc_w <= 0; tg_w <= 0; l_w <= 0; g_w <= 0;
      t_d <= 0; t_t <= 0; t_l <= 0; t_g <= 0;
      fetching <= 0; tging <= 0; ling <= 0; ging <= 0;
      for (ri = 0; ri < NWMAX; ri = ri + 1) begin
        c_d[ri] <= 0; c_t[ri] <= 0; c_l[ri] <= 0; c_g[ri] <= 0; t_acc[ri] <= 0;
      end
    end else begin
      running_d <= running;
      wave_d <= wave_valid;
      core_fire_d <= core_fire;
      core_topk_d <= core_topk_valid;
      g_valid_d <= global_topk_valid;
      drain_d <= drain;
      sch_d <= sch; soa_st_d <= soa_st; ng_st_d <= ng_st; g_st_d <= g_st;

      if (running && !running_d) begin
        drain <= 1'b0;
        elig <= 0; run_cyc <= 0; ddr_occ <= 0; tg_occ <= 0; ng_occ <= 0; ng_push <= 0;
        g_occ <= 0; g_sort <= 0; c_d_exp <= 0;
        blk_g <= 0; blk_core <= 0; blk_sched <= 0; blk_tg <= 0; blk_hold <= 0;
        overlap2 <= 0; overlap3 <= 0; ar_cnt <= 0;
        fetch_w <= 0; acc_w <= 0; tg_w <= 0; l_w <= 0; g_w <= 0;
        t_d <= 0; t_t <= 0; t_l <= 0; t_g <= 0;
        fetching <= 0; tging <= 0; ling <= 0; ging <= 0;
        for (ri = 0; ri < NWMAX; ri = ri + 1) begin
          c_d[ri] <= 0; c_t[ri] <= 0; c_l[ri] <= 0; c_g[ri] <= 0; t_acc[ri] <= 0;
        end
      end else if (running || drain) begin
        if (!running && drain) begin
          if (sched_idle && (ng_st == 3'd0) && (g_st == 3'd0) && (soa_st != 3'd1) && (soa_st != 3'd2))
            drain <= 1'b0;
        end else if (running && (!sched_idle || (ng_st != 3'd0) || (g_st != 3'd0))) begin
          drain <= 1'b1;
        end
        elig <= elig + 1;
        if (running) run_cyc <= run_cyc + 1;
        if (soa_st == 3'd2) ddr_occ <= ddr_occ + 1;
        if ((sch == 2'd1) || (sch == 2'd2)) tg_occ <= tg_occ + 1;
        if (ng_st != 3'd0) ng_occ <= ng_occ + 1;
        if (ng_st == 3'd6) ng_push <= ng_push + 1;
        if (g_st != 3'd0) g_occ <= g_occ + 1;
        if (g_st == 3'd4) g_sort <= g_sort + 1;
        if (wf_cons_ready && !wave_valid) c_d_exp <= c_d_exp + 1;
        if (ar_fire) ar_cnt <= ar_cnt + 1;

        if ((soa_st == 3'd3) && !wf_cons_ready) begin
          blk_hold <= blk_hold + 1;
          if (global_topk_busy) blk_g <= blk_g + 1;
          if (!core_batch_ready) blk_core <= blk_core + 1;
          if (!sched_idle) blk_sched <= blk_sched + 1;
          if (!tg_ready) blk_tg <= blk_tg + 1;
        end

        nbusy = ((soa_st == 3'd2) ? 1 : 0)
              + (((sch == 2'd1) || (sch == 2'd2)) ? 1 : 0)
              + ((ng_st != 3'd0) ? 1 : 0)
              + ((g_st != 3'd0) ? 1 : 0);
        if (nbusy >= 2) overlap2 <= overlap2 + 1;
        if (nbusy >= 3) overlap3 <= overlap3 + 1;

        // C_D service: ST_FETCH residency per wave
        if ((soa_st == 3'd2) && (soa_st_d != 3'd2)) begin
          t_d <= 1;
          fetching <= 1;
        end else if (fetching) begin
          if ((soa_st == 3'd3) && (soa_st_d == 3'd2)) begin
            if (fetch_w < NWMAX) c_d[fetch_w] <= t_d + 1;
            fetch_w <= fetch_w + 1;
            fetching <= 0;
            t_d <= 0;
          end else begin
            t_d <= t_d + 1;
          end
        end

        // C_T: SCH_FIRE/WAIT after wave accept
        if (wave_valid && !wave_d) begin
          if (acc_w < NWMAX) t_acc[acc_w] <= elig + 1;
          acc_w <= acc_w + 1;
          t_t <= 0;
          tging <= 1;
        end else if (tging) begin
          if ((sch == 2'd1) || (sch == 2'd2))
            t_t <= t_t + 1;
          if ((sch == 2'd3) && (sch_d != 2'd3)) begin
            if (tg_w < NWMAX) c_t[tg_w] <= t_t + (((sch_d == 2'd1) || (sch_d == 2'd2)) ? 1 : 0);
            tg_w <= tg_w + 1;
            tging <= 0;
          end
        end

        // C_L: NG02 scorer+local heap, snapshot at core_topk_valid (ST_COMMIT).
        // ST_PUSH is counted in NG_PUSH / ng_occ only (frontier deadpath).
        if (core_fire && !core_fire_d) begin
          t_l <= 1;
          ling <= 1;
        end else if (ling) begin
          t_l <= t_l + 1;
          if (core_topk_valid && !core_topk_d) begin
            if (l_w < NWMAX) c_l[l_w] <= t_l + 1;
            l_w <= l_w + 1;
            ling <= 0;
          end
        end

        // C_G: global busy pulse
        if ((g_st != 3'd0) && (g_st_d == 3'd0)) begin
          t_g <= 1;
          ging <= 1;
        end else if (ging) begin
          if ((g_st == 3'd0) && (g_st_d != 3'd0)) begin
            if (g_w < NWMAX) c_g[g_w] <= t_g;
            g_w <= g_w + 1;
            ging <= 0;
            t_g <= 0;
          end else begin
            t_g <= t_g + 1;
          end
        end
      end
    end
  end

  integer nw, ii_obs, ii_pred, fill, t_ideal, s_tax;
  integer cd_max, ct_max, cl_max, cg_max, ii_gap;
  real cand_cyc, eta_tg, s_pct;
  logic printed;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      printed = 1'b0;
    else if (running && !running_d)
      printed = 1'b0;
    else if (!printed &&
        sched_idle && (ng_st == 3'd0) && (g_st == 3'd0) &&
        (acc_w > 0) && (!running || done)) begin
      printed = 1'b1;
      nw = (acc_w > 0) ? acc_w : (waves > 0 ? waves : 0);
      cd_max = 0; ct_max = 0; cl_max = 0; cg_max = 0; ii_obs = 0;
      for (pi = 0; pi < nw; pi = pi + 1) begin
        if (c_d[pi] > cd_max) cd_max = c_d[pi];
        if (c_t[pi] > ct_max) ct_max = c_t[pi];
        if (c_l[pi] > cl_max) cl_max = c_l[pi];
        if (c_g[pi] > cg_max) cg_max = c_g[pi];
        if (pi > 0) begin
          ii_gap = t_acc[pi] - t_acc[pi-1];
          if (ii_gap > ii_obs) ii_obs = ii_gap;
        end
      end
      ii_pred = imax4(cd_max, ct_max, cl_max, cg_max);
      fill = (nw > 0) ? (c_d[0] + c_t[0] + c_l[0] + c_g[0]) : 0;
      t_ideal = (nw > 0) ? (fill + ((nw - 1) * ii_pred)) : 0;
      s_tax = elig - t_ideal;
      cand_cyc = (elig > 0) ? (real'(delivered) / real'(elig)) : 0.0;
      eta_tg = (tg_occ > 0) ? (real'(6 * delivered) / (real'(PHYS) * real'(tg_occ))) : 0.0;
      s_pct = (elig > 0) ? (real'(s_tax) / real'(elig)) : 0.0;

      $display("P3P4_REPAIR_DONE PHYS=%0d N=%0d WAVES=%0d T_QUERY=%0d T_RUN=%0d cycles_o=%0d ACC_W=%0d TG_W=%0d L_W=%0d G_W=%0d",
               PHYS, delivered, waves, elig, run_cyc, cycles, acc_w, tg_w, l_w, g_w);
      $display("P3P4_CAND_PER_CYCLE=%0.6f", cand_cyc);
      $display("P3P4_C_D_EXPOSED=%0d C_D_SERVICE_OCC=%0d C_D_MAX=%0d AR_FIRE=%0d empty_stall=%0d",
               c_d_exp, ddr_occ, cd_max, ar_cnt, empty_st);
      $display("P3P4_C_T_OCC=%0d C_T_MAX=%0d ETA_TG=%0.6f", tg_occ, ct_max, eta_tg);
      $display("P3P4_C_L_OCC=%0d C_L_MAX=%0d NG_PUSH=%0d", ng_occ, cl_max, ng_push);
      $display("P3P4_C_G_OCC=%0d C_G_MAX=%0d G_SORT=%0d", g_occ, cg_max, g_sort);
      $display("P3P4_II_WAVE_OBS=%0d II_PRED_MAX_Ci=%0d FILL0=%0d T_IDEAL_PIPE=%0d",
               ii_obs, ii_pred, fill, t_ideal);
      $display("P3P4_S_TAX=%0d S_PCT=%0.6f", s_tax, s_pct);
      $display("P3P4_OVERLAP2=%0d OVERLAP3=%0d", overlap2, overlap3);
      $display("P3P4_BLK_HOLD=%0d BLK_GLOBAL=%0d BLK_CORE=%0d BLK_SCHED=%0d BLK_TG=%0d",
               blk_hold, blk_g, blk_core, blk_sched, blk_tg);
      $display("P3P4_AXI_BYTES=%0d", axi_bytes);
      $display("P3P4_DDR_PREFETCH_INDICATED=%s", (c_d_exp > 0) ? "YES" : "NO");
      for (pi = 0; pi < nw && pi < NWMAX; pi = pi + 1)
        $display("P3P4_WAVE%0d C_D=%0d C_T=%0d C_L=%0d C_G=%0d t_accept=%0d SUM=%0d",
                 pi, c_d[pi], c_t[pi], c_l[pi], c_g[pi], t_acc[pi],
                 c_d[pi] + c_t[pi] + c_l[pi] + c_g[pi]);
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_p3p4_repair_probe #(.PHYS(4)) u_g14_p3p4 (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .done(done_o),
  .wave_valid(wave_valid),
  .wf_cons_ready(wf_cons_ready),
  .sched_idle(sched_idle),
  .tg_ready(tg_ready),
  .core_batch_ready(core_batch_ready),
  .global_topk_busy(global_topk_busy),
  .core_fire(|core_valid),
  .core_topk_valid(core_topk_valid),
  .global_topk_valid(global_topk_valid),
  .ar_fire(ar_valid && ar_ready),
  .sch(sch),
  .soa_st(u_soa.st),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .empty_st(buffer_empty_stall_o),
  .axi_bytes(axi_read_bytes_o),
  .delivered(cand_delivered_o),
  .waves(waves_o),
  .cycles(cycles_o)
);
