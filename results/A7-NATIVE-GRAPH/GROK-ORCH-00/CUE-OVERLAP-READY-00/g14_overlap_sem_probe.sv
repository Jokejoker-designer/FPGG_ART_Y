// Bind-only ownership probe. NO production RTL edit. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_overlap_sem_probe (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        done,
  input logic        wave_valid,
  input logic        sched_idle,
  input logic        core_fire,
  input logic        core_topk_valid,
  input logic [1:0]  sch,
  input logic [31:0] delivered,
  input logic [31:0] waves,
  input logic [31:0] merge_count
);
  integer wave_accept, tg_complete, core_issue;
  integer overwrite, dup, inflight, deadlock;
  integer drop_n;
  logic [1:0] sch_d;
  logic running_d, started, drain;

  // done_o is wavefront FETCH complete, not query complete.
  // Overlap lets TermGen/NG02/Global of the last wave run after done.
  // Count from running-rise through pipeline drain.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wave_accept <= 0; tg_complete <= 0; core_issue <= 0;
      overwrite <= 0; dup <= 0; inflight <= 0; deadlock <= 0;
      sch_d <= 2'd0; running_d <= 1'b0; started <= 1'b0; drain <= 1'b0;
    end else begin
      sch_d <= sch;
      running_d <= running;
      if (running && !running_d) begin
        started <= 1'b1;
        drain <= 1'b1;
        wave_accept <= 0; tg_complete <= 0; core_issue <= 0;
        overwrite <= 0; dup <= 0; inflight <= 0; deadlock <= 0;
      end else if (started && (running || drain)) begin
        if (!running && sched_idle && (inflight == 0) && (sch == 2'd0))
          drain <= 1'b0;
        if (wave_valid) begin
          wave_accept <= wave_accept + 1;
          if (!sched_idle)
            overwrite <= overwrite + 1;
          if (inflight)
            dup <= dup + 1;
          inflight <= 1;
        end
        if ((sch == 2'd3) && (sch_d != 2'd3))
          tg_complete <= tg_complete + 1;
        if (core_fire) begin
          core_issue <= core_issue + 1;
          inflight <= 0;
        end
      end
    end
  end

  final begin
    drop_n = 0;
    if (wave_accept != 4) drop_n = drop_n + 1;
    if (tg_complete != 4) drop_n = drop_n + 1;
    if (core_issue != 4) drop_n = drop_n + 1;
    if (merge_count != 32'd4) drop_n = drop_n + 1;
    if (delivered != 32'd64) drop_n = drop_n + 1;
    if (waves != 32'd4) drop_n = drop_n + 1;
    $display("CUE_OVERLAP_SEM wave_accept=%0d tg_complete=%0d core_issue=%0d global_merge=%0d",
             wave_accept, tg_complete, core_issue, merge_count);
    $display("CUE_OVERLAP_SEM delivered=%0d waves=%0d drop=%0d dup=%0d overwrite=%0d deadlock=%0d inflight=%0d",
             delivered, waves, drop_n, dup, overwrite, deadlock, inflight);
    if ((wave_accept == 4) && (tg_complete == 4) && (core_issue == 4) &&
        (merge_count == 32'd4) && (delivered == 32'd64) && (waves == 32'd4) &&
        (dup == 0) && (overwrite == 0) && (deadlock == 0) && (inflight == 0))
      $display("CUE_OVERLAP_SEM_PASS");
    else
      $display("CUE_OVERLAP_SEM_FAIL");
  end
endmodule

bind a7ng_cue_soa_mig_top g14_overlap_sem_probe u_g14_overlap_sem (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .done(done_o),
  .wave_valid(wave_valid),
  .sched_idle(sched_idle),
  .core_fire(|core_valid),
  .core_topk_valid(core_topk_valid),
  .sch(sch),
  .delivered(cand_delivered_o),
  .waves(waves_o),
  .merge_count(global_merge_count)
);
