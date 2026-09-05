// Bind-only DDR exposure vs service. NO production RTL. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_ddr_exposed_probe #(parameter int NWMAX = 8) (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        sched_idle,
  input logic [2:0]  soa_st,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic        wave_valid,
  input logic        wf_cons_ready,
  input logic        ar_fire,
  input logic        r_fire,
  input logic        r_last,
  input logic        m_ar_fire,
  input logic        m_r_fire,
  input logic        m_r_last,
  input logic [2:0]  fifo_level,
  input logic [31:0] outstanding,
  input logic [3:0]  pf_inflight,
  input logic [31:0] axi_bytes,
  input logic [31:0] axi_beats,
  input logic [31:0] axi_bursts,
  input logic [31:0] r_bp,
  input logic [31:0] rresp_err,
  input logic [31:0] rlast_err,
  input logic [31:0] rid_err,
  input logic        merge_done,
  input logic [31:0] merge_count
);
  localparam logic [2:0] ST_IDLE  = 3'd0;
  localparam logic [2:0] ST_ARM   = 3'd1;
  localparam logic [2:0] ST_FETCH = 3'd2;
  localparam logic [2:0] ST_HOLD  = 3'd3;

  logic running_d, drain, idle_d, printed;
  logic [2:0] soa_st_d, g_st_d;
  logic wave_d, ar_seen, r_seen;

  integer cyc, fetch_i, acc_i;
  integer ar_n, r_n, mar_n, mr_n;
  integer fifo_hw, out_hw, inf_hw, exp_tot, hold_wait_tot;
  integer t_last_g, t_last_md, t_query;

  integer t_ar [0:7], t_fr [0:7], t_lr [0:7], t_fd [0:7];
  integer t_avail [0:7], t_acc [0:7];
  integer n_ar_w [0:7], n_r_w [0:7];
  integer exp_w [0:7], hold_w [0:7];
  integer c_g [0:7];
  integer t_g, ging, g_w;
  integer ri;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; drain <= 0; idle_d <= 0;
      soa_st_d <= 0; g_st_d <= 0; wave_d <= 0;
      ar_seen <= 0; r_seen <= 0;
      cyc <= 0; fetch_i <= 0; acc_i <= 0;
      ar_n <= 0; r_n <= 0; mar_n <= 0; mr_n <= 0;
      fifo_hw <= 0; out_hw <= 0; inf_hw <= 0;
      exp_tot <= 0; hold_wait_tot <= 0;
      t_last_g <= 0; t_last_md <= 0; t_query <= 0;
      t_g <= 0; ging <= 0; g_w <= 0;
      for (ri = 0; ri < 8; ri = ri + 1) begin
        t_ar[ri] <= 0; t_fr[ri] <= 0; t_lr[ri] <= 0; t_fd[ri] <= 0;
        t_avail[ri] <= 0; t_acc[ri] <= 0;
        n_ar_w[ri] <= 0; n_r_w[ri] <= 0;
        exp_w[ri] <= 0; hold_w[ri] <= 0; c_g[ri] <= 0;
      end
    end else begin
      running_d <= running;
      soa_st_d <= soa_st;
      g_st_d <= g_st;
      wave_d <= wave_valid;

      if (running && !running_d) begin
        drain <= 1; idle_d <= 0;
        ar_seen <= 0; r_seen <= 0;
        cyc <= 0; fetch_i <= 0; acc_i <= 0;
        ar_n <= 0; r_n <= 0; mar_n <= 0; mr_n <= 0;
        fifo_hw <= 0; out_hw <= 0; inf_hw <= 0;
        exp_tot <= 0; hold_wait_tot <= 0;
        t_last_g <= 0; t_last_md <= 0; t_query <= 0;
        t_g <= 0; ging <= 0; g_w <= 0;
        for (ri = 0; ri < 8; ri = ri + 1) begin
          t_ar[ri] <= 0; t_fr[ri] <= 0; t_lr[ri] <= 0; t_fd[ri] <= 0;
          t_avail[ri] <= 0; t_acc[ri] <= 0;
          n_ar_w[ri] <= 0; n_r_w[ri] <= 0;
          exp_w[ri] <= 0; hold_w[ri] <= 0; c_g[ri] <= 0;
        end
      end else if (running || drain) begin
        cyc <= cyc + 1;
        idle_d <= (!running && drain && sched_idle && (ng_st == ST_IDLE) &&
                   (g_st == ST_IDLE) && (soa_st != ST_ARM) && (soa_st != ST_FETCH) &&
                   (acc_i == 4) && (g_w == 4));
        if (!running && idle_d)
          drain <= 0;
        else if (running)
          t_query <= cyc + 1;

        if (ar_fire) ar_n <= ar_n + 1;
        if (r_fire) r_n <= r_n + 1;
        if (m_ar_fire) mar_n <= mar_n + 1;
        if (m_r_fire) mr_n <= mr_n + 1;
        if (integer'(fifo_level) > fifo_hw) fifo_hw <= integer'(fifo_level);
        if (integer'(outstanding) > out_hw) out_hw <= integer'(outstanding);
        if (integer'(pf_inflight) > inf_hw) inf_hw <= integer'(pf_inflight);
        if (wf_cons_ready && !wave_valid) exp_tot <= exp_tot + 1;
        if ((soa_st == ST_HOLD) && wf_cons_ready && !wave_valid)
          hold_wait_tot <= hold_wait_tot + 1;

        if (fetch_i < NWMAX) begin
          if (wf_cons_ready && !wave_valid &&
              ((soa_st == ST_ARM) || (soa_st == ST_FETCH)))
            exp_w[fetch_i] <= exp_w[fetch_i] + 1;
          if ((soa_st == ST_HOLD) && wf_cons_ready && !wave_valid)
            hold_w[fetch_i] <= hold_w[fetch_i] + 1;
        end

        if (ar_fire && (fetch_i < NWMAX)) begin
          n_ar_w[fetch_i] <= n_ar_w[fetch_i] + 1;
          if (!ar_seen) begin
            t_ar[fetch_i] <= cyc + 1;
            ar_seen <= 1;
            r_seen <= 0;
          end
        end
        if (r_fire && (fetch_i < NWMAX)) begin
          n_r_w[fetch_i] <= n_r_w[fetch_i] + 1;
          t_lr[fetch_i] <= cyc + 1;
          if (!r_seen) begin
            t_fr[fetch_i] <= cyc + 1;
            r_seen <= 1;
          end
        end
        if ((soa_st == ST_HOLD) && (soa_st_d == ST_FETCH) && (fetch_i < NWMAX)) begin
          t_fd[fetch_i] <= cyc + 1;
          t_avail[fetch_i] <= cyc + 1;
          ar_seen <= 0;
        end
        if (wave_valid && !wave_d && (acc_i < NWMAX)) begin
          t_acc[acc_i] <= cyc + 1;
          acc_i <= acc_i + 1;
          fetch_i <= fetch_i + 1;
        end

        if ((g_st != ST_IDLE) && (g_st_d == ST_IDLE)) begin
          t_g <= 1; ging <= 1;
        end else if (ging) begin
          if ((g_st == ST_IDLE) && (g_st_d != ST_IDLE)) begin
            if (g_w < NWMAX) c_g[g_w] <= t_g;
            g_w <= g_w + 1;
            ging <= 0;
            t_last_g <= cyc + 1;
            t_g <= 0;
          end else
            t_g <= t_g + 1;
        end
        if (merge_done)
          t_last_md <= cyc + 1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      printed = 1'b0;
    else if (running && !running_d)
      printed = 1'b0;
    else if (!printed && idle_d && (!running) && (acc_i == 4) &&
             (merge_count == 32'd4)) begin
      printed = 1'b1;
      begin : dprint
        integer w, gap, ii_st, cd_svc_max, cd_exp_w0, cd_exp_rest, g_tail;
        integer ar2r, rdr, fsvc, expw, nxt;
        ii_st = 0; cd_svc_max = 0; cd_exp_w0 = 0; cd_exp_rest = 0;
        $display("DDR_EXPOSED_DONE waves=%0d fetch=%0d acc=%0d ar=%0d r=%0d mar=%0d mr=%0d",
                 acc_i, fetch_i, acc_i, ar_n, r_n, mar_n, mr_n);
        $display("DDR_AXI bytes=%0d beats=%0d bursts=%0d bp=%0d fifo_hw=%0d out_hw=%0d inf_hw=%0d",
                 axi_bytes, axi_beats, axi_bursts, r_bp, fifo_hw, out_hw, inf_hw);
        $display("DDR_ERR rresp=%0d rlast=%0d rid=%0d", rresp_err, rlast_err, rid_err);
        $display("DDR_OCC C_D_EXPOSED_TOT=%0d HOLD_WAIT_TOT=%0d T_QUERY=%0d last_g=%0d last_md=%0d",
                 exp_tot, hold_wait_tot, t_query, t_last_g, t_last_md);
        for (w = 0; w < acc_i && w < 8; w = w + 1) begin
          ar2r = (t_fr[w] > t_ar[w]) ? (t_fr[w] - t_ar[w]) : 0;
          rdr  = (t_lr[w] >= t_fr[w] && t_fr[w] != 0) ? (t_lr[w] - t_fr[w] + 1) : 0;
          fsvc = (t_fd[w] > t_ar[w]) ? (t_fd[w] - t_ar[w] + 1) : 0;
          expw = (t_acc[w] > t_avail[w]) ? (t_acc[w] - t_avail[w]) : 0;
          nxt  = (w + 1 < acc_i) ? t_ar[w+1] : 0;
          gap  = (w + 1 < acc_i && t_ar[w+1] > t_ar[w]) ? (t_ar[w+1] - t_ar[w]) : 0;
          if (fsvc > cd_svc_max) cd_svc_max = fsvc;
          if (w == 0) cd_exp_w0 = exp_w[w];
          else cd_exp_rest = cd_exp_rest + exp_w[w];
          if (w >= 1 && w <= 2) begin
            if ((t_acc[w] > t_acc[w-1]) && ((t_acc[w] - t_acc[w-1]) > ii_st))
              ii_st = t_acc[w] - t_acc[w-1];
          end
          $display("DDR_WAVE%0d AR_FIRE=%0d FIRST_R=%0d LAST_R=%0d FETCH_DONE=%0d WAVE_AVAILABLE=%0d WAVE_ACCEPT=%0d NEXT_AR=%0d",
                   w, t_ar[w], t_fr[w], t_lr[w], t_fd[w], t_avail[w], t_acc[w], nxt);
          $display("DDR_WAVE%0d AR_TO_FIRST_R=%0d R_DRAIN=%0d FETCH_SERVICE=%0d INTERWAVE_AR_GAP=%0d EXPOSED_HOLD=%0d EXPOSED_FETCH=%0d n_ar=%0d n_r=%0d C_G=%0d",
                   w, ar2r, rdr, fsvc, gap, expw, exp_w[w], n_ar_w[w], n_r_w[w], c_g[w]);
        end
        if (acc_i >= 4 && t_acc[3] != 0 && t_last_g > t_acc[3])
          g_tail = t_last_g - t_acc[3];
        else
          g_tail = 0;
        $display("DDR_CLASS C_D_SERVICE_MAX=%0d C_D_EXPOSED_W0=%0d C_D_EXPOSED_W1_3=%0d II_STEADY=%0d FINAL_G_TAIL=%0d",
                 cd_svc_max, cd_exp_w0, cd_exp_rest, ii_st, g_tail);
        if ((acc_i == 4) && (ar_n > 0) && (rresp_err == 0) && (rlast_err == 0) &&
            (rid_err == 0) && (t_ar[0] != 0) && (t_ar[3] != 0) && (t_acc[3] != 0))
          $display("DDR_EXPOSED_REMEASURE_PASS");
        else
          $display("DDR_EXPOSED_REMEASURE_FAIL acc=%0d ar=%0d", acc_i, ar_n);
      end
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_ddr_exposed_probe u_g14_ddr (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .sched_idle(sched_idle),
  .soa_st(u_soa.st),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .wave_valid(wave_valid),
  .wf_cons_ready(wf_cons_ready),
  .ar_fire(ar_valid && ar_ready),
  .r_fire(r_valid && r_ready),
  .r_last(r_last),
  .m_ar_fire(m_axi_arvalid && m_axi_arready),
  .m_r_fire(m_axi_rvalid && m_axi_rready),
  .m_r_last(m_axi_rlast),
  .fifo_level(r_fifo_level),
  .outstanding(br_outstanding),
  .pf_inflight(u_soa.u_pf.in_flight),
  .axi_bytes(axi_read_bytes_o),
  .axi_beats(axi_read_beats_o),
  .axi_bursts(axi_read_bursts_o),
  .r_bp(r_backpressure_cycles_o),
  .rresp_err(rresp_error_count_o),
  .rlast_err(rlast_error_count_o),
  .rid_err(rid_order_error_o),
  .merge_done(merge_done_o),
  .merge_count(global_merge_count)
);
