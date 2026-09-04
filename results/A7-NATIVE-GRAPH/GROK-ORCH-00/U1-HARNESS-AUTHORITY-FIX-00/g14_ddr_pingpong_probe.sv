// Bind-only DDR-WAVE-PINGPONG-00. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_ddr_pingpong_probe #(parameter int NWMAX = 8) (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        sched_idle,
  input logic [2:0]  soa_st,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic        wave_valid,
  input logic        ar_fire,
  input logic        r_fire,
  input logic        r_last,
  input logic [3:0]  ar_id,
  input logic [3:0]  in_flight,
  input logic [31:0] ar_overlap_n,
  input logic [31:0] out_hw,
  input logic [31:0] drop_q,
  input logic [31:0] dup_q,
  input logic [31:0] overwrite_q,
  input logic [31:0] ooo_q,
  input logic [31:0] axi_bytes,
  input logic [31:0] axi_beats,
  input logic [31:0] axi_bursts,
  input logic [31:0] rresp_err,
  input logic [31:0] rlast_err,
  input logic [31:0] rid_err,
  input logic        merge_done,
  input logic [31:0] merge_count
);
  localparam logic [2:0] ST_IDLE = 3'd0;

  logic running_d, drain, idle_d, printed;
  logic wave_d;

  integer cyc, acc_i, ar_i, lr_i;
  integer t_last_g, t_query;
  integer t_ar [0:7], t_lr [0:7], t_acc [0:7];
  integer rid_nz, inf_hw;
  integer g_w, t_g, ging;
  logic [2:0] g_st_d;
  integer ri;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; drain <= 0; idle_d <= 0; wave_d <= 0;
      cyc <= 0; acc_i <= 0; ar_i <= 0; lr_i <= 0;
      t_last_g <= 0; t_query <= 0;
      rid_nz <= 0; inf_hw <= 0;
      g_w <= 0; t_g <= 0; ging <= 0; g_st_d <= 0;
      for (ri = 0; ri < 8; ri = ri + 1) begin
        t_ar[ri] <= 0; t_lr[ri] <= 0; t_acc[ri] <= 0;
      end
    end else begin
      running_d <= running;
      wave_d <= wave_valid;
      g_st_d <= g_st;
      if (running && !running_d) begin
        drain <= 1; idle_d <= 0;
        cyc <= 0; acc_i <= 0; ar_i <= 0; lr_i <= 0;
        t_last_g <= 0; t_query <= 0;
        rid_nz <= 0; inf_hw <= 0;
        g_w <= 0; t_g <= 0; ging <= 0;
        for (ri = 0; ri < 8; ri = ri + 1) begin
          t_ar[ri] <= 0; t_lr[ri] <= 0; t_acc[ri] <= 0;
        end
      end else if (running || drain) begin
        cyc <= cyc + 1;
        idle_d <= (!running && drain && sched_idle && (ng_st == ST_IDLE) &&
                   (g_st == ST_IDLE) && (acc_i == 4) && (g_w == 4));
        if (!running && idle_d)
          drain <= 0;
        else if (running)
          t_query <= cyc + 1;

        if (integer'(in_flight) > inf_hw)
          inf_hw <= integer'(in_flight);
        if (ar_fire && (ar_id != 4'd0))
          rid_nz <= rid_nz + 1;

        if (ar_fire && (ar_i < NWMAX)) begin
          t_ar[ar_i] <= cyc + 1;
          ar_i <= ar_i + 1;
        end
        if (r_fire && r_last && (lr_i < NWMAX)) begin
          t_lr[lr_i] <= cyc + 1;
          lr_i <= lr_i + 1;
        end
        if (wave_valid && !wave_d && (acc_i < NWMAX)) begin
          t_acc[acc_i] <= cyc + 1;
          acc_i <= acc_i + 1;
        end

        if ((g_st != ST_IDLE) && (g_st_d == ST_IDLE)) begin
          t_g <= 1; ging <= 1;
        end else if (ging) begin
          if ((g_st == ST_IDLE) && (g_st_d != ST_IDLE)) begin
            g_w <= g_w + 1;
            ging <= 0;
            t_last_g <= cyc + 1;
            t_g <= 0;
          end else
            t_g <= t_g + 1;
        end
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
        integer w, ii_st, ar_before, tq;
        integer ok;
        ii_st = 0; ar_before = 1;
        $display("DDR_PP_DONE waves=%0d ar=%0d lr=%0d overlap=%0d out_hw=%0d inf_hw=%0d",
                 acc_i, ar_i, lr_i, ar_overlap_n, out_hw, inf_hw);
        $display("DDR_PP_AXI bytes=%0d beats=%0d bursts=%0d",
                 axi_bytes, axi_beats, axi_bursts);
        $display("DDR_PP_ERR rresp=%0d rlast=%0d rid=%0d rid_nz=%0d drop=%0d dup=%0d ovw=%0d ooo=%0d",
                 rresp_err, rlast_err, rid_err, rid_nz, drop_q, dup_q, overwrite_q, ooo_q);
        for (w = 0; w < acc_i && w < 8; w = w + 1) begin
          $display("DDR_PP_WAVE%0d AR_FIRE=%0d LAST_R=%0d WAVE_ACCEPT=%0d",
                   w, t_ar[w], t_lr[w], t_acc[w]);
          if (w + 1 < acc_i) begin
            if (!((t_ar[w+1] != 0) && (t_lr[w] != 0) && (t_ar[w+1] < t_lr[w])))
              ar_before = 0;
          end
          if (w >= 1 && w <= 2) begin
            if ((t_acc[w] > t_acc[w-1]) && ((t_acc[w] - t_acc[w-1]) > ii_st))
              ii_st = t_acc[w] - t_acc[w-1];
          end
        end
        tq = (t_last_g != 0) ? t_last_g : t_query;
        $display("DDR_PP_CLASS II_STEADY=%0d T_QUERY=%0d AR_BEFORE_LASTR=%0d SAME_RID=%0d",
                 ii_st, tq, ar_before, (rid_nz == 0));
        ok = (acc_i == 4) && (ar_i == 4) && (lr_i == 4) &&
             (axi_bytes == 32'd1024) && (axi_beats == 32'd64) && (axi_bursts == 32'd4) &&
             (out_hw >= 32'd2) && (ar_overlap_n > 32'd0) &&
             (drop_q == 0) && (dup_q == 0) && (overwrite_q == 0) && (ooo_q == 0) &&
             (rresp_err == 0) && (rlast_err == 0) && (rid_err == 0) && (rid_nz == 0) &&
             (ar_before == 1) && (ii_st > 0) && (ii_st < 46) && (tq < 310);
        if (ok)
          $display("DDR_WAVE_PINGPONG_PASS");
        else
          $display("DDR_WAVE_PINGPONG_FAIL ii=%0d tq=%0d ov=%0d hw=%0d before=%0d",
                   ii_st, tq, ar_overlap_n, out_hw, ar_before);
      end
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_ddr_pingpong_probe u_g14_pp (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .sched_idle(sched_idle),
  .soa_st(u_soa.st),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .wave_valid(wave_valid),
  .ar_fire(ar_valid && ar_ready),
  .r_fire(r_valid && r_ready),
  .r_last(r_last),
  .ar_id(ar_id),
  .in_flight(u_soa.in_flight),
  .ar_overlap_n(u_soa.ar_overlap_n),
  .out_hw(u_soa.out_hw),
  .drop_q(u_soa.drop_q),
  .dup_q(u_soa.dup_q),
  .overwrite_q(u_soa.overwrite_q),
  .ooo_q(u_soa.ooo_q),
  .axi_bytes(axi_read_bytes_o),
  .axi_beats(axi_read_beats_o),
  .axi_bursts(axi_read_bursts_o),
  .rresp_err(rresp_error_count_o),
  .rlast_err(rlast_error_count_o),
  .rid_err(rid_order_error_o),
  .merge_done(merge_done_o),
  .merge_count(global_merge_count)
);
