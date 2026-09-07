// Bind-only: merge_done=4, ordered_valid=1, ST_SORT=28. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_sort_final_only_probe (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        sched_idle,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic        merge_done,
  input logic        global_valid,
  input logic        wave_valid_i,
  input logic [31:0] merge_count_o
);
  localparam logic [2:0] ST_IDLE = 3'd0;
  localparam logic [2:0] ST_SORT = 3'd4;

  logic running_d, drain, idle_now, idle_d, printed;
  integer md_n, gv_n, sort_n, drop_n, mid_gv;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; drain <= 0; idle_d <= 0;
      md_n <= 0; gv_n <= 0; sort_n <= 0; drop_n <= 0; mid_gv <= 0;
    end else begin
      running_d <= running;
      idle_now = (!running && drain && sched_idle &&
                  (ng_st == ST_IDLE) && (g_st == ST_IDLE));
      idle_d <= idle_now;
      if (running && !running_d) begin
        drain <= 1; idle_d <= 0;
        md_n <= 0; gv_n <= 0; sort_n <= 0; drop_n <= 0; mid_gv <= 0;
      end else if (running || drain) begin
        if (idle_now) drain <= 0;
        if (merge_done) md_n <= md_n + 1;
        if (global_valid) gv_n <= gv_n + 1;
        if (global_valid && (md_n < 3)) mid_gv <= mid_gv + 1;
        if (g_st == ST_SORT) sort_n <= sort_n + 1;
        if (wave_valid_i && (g_st != ST_IDLE)) drop_n <= drop_n + 1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      printed = 1'b0;
    else if (running && !running_d)
      printed = 1'b0;
    else if (!printed && idle_d && (!running) && sched_idle &&
             (ng_st == ST_IDLE) && (g_st == ST_IDLE) &&
             (merge_count_o == 32'd4)) begin
      printed = 1'b1;
      $display("SORT_FINAL_ONLY_DONE md=%0d ordered_valid=%0d sort=%0d merges=%0d mid_gv=%0d drop=%0d",
               md_n, gv_n, sort_n, merge_count_o, mid_gv, drop_n);
      if ((md_n == 4) && (gv_n == 1) && (sort_n == 28) && (mid_gv == 0) && (drop_n == 0))
        $display("SORT_FINAL_ONLY_PASS");
      else
        $display("SORT_FINAL_ONLY_FAIL md=%0d gv=%0d sort=%0d mid_gv=%0d drop=%0d",
                 md_n, gv_n, sort_n, mid_gv, drop_n);
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_sort_final_only_probe u_g14_sfo (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .sched_idle(sched_idle),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .merge_done(merge_done_o),
  .global_valid(global_topk_valid),
  .wave_valid_i(core_topk_valid),
  .merge_count_o(global_merge_count)
);
