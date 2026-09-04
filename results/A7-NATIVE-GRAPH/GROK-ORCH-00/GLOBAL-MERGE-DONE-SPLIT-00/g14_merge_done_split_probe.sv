// Bind-only merge_done vs ordered-valid coincidence. PROGRAM=NO.
`timescale 1ps / 100fs

module g14_merge_done_split_probe (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        sched_idle,
  input logic [2:0]  ng_st,
  input logic [2:0]  g_st,
  input logic        merge_done,
  input logic        global_valid,
  input logic        wave_valid_i,
  input logic        busy_o,
  input logic [31:0] merge_count_o
);
  localparam logic [2:0] ST_IDLE = 3'd0;
  localparam logic [2:0] ST_SORT = 3'd4;

  logic running_d, drain, idle_now, idle_d;
  integer md_n, gv_n, xor_n, sort_n, drop_n, dup_n;
  logic ging, printed;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_d <= 0; drain <= 0; idle_d <= 0;
      md_n <= 0; gv_n <= 0; xor_n <= 0; sort_n <= 0;
      drop_n <= 0; dup_n <= 0; ging <= 0;
    end else begin
      running_d <= running;
      idle_now = (!running && drain && sched_idle &&
                  (ng_st == ST_IDLE) && (g_st == ST_IDLE));
      idle_d <= idle_now;
      if (running && !running_d) begin
        drain <= 1;
        idle_d <= 0;
        md_n <= 0; gv_n <= 0; xor_n <= 0; sort_n <= 0;
        drop_n <= 0; dup_n <= 0; ging <= 0;
      end else if (running || drain) begin
        if (idle_now)
          drain <= 0;
        if (merge_done) md_n <= md_n + 1;
        if (global_valid) gv_n <= gv_n + 1;
        if (merge_done !== global_valid) xor_n <= xor_n + 1;
        if (g_st == ST_SORT) sort_n <= sort_n + 1;
        if (wave_valid_i && (g_st != ST_IDLE)) drop_n <= drop_n + 1;
        if (wave_valid_i && ging) dup_n <= dup_n + 1;
        if (g_st != ST_IDLE) ging <= 1'b1;
        if (merge_done) ging <= 1'b0;
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
      $display("MERGE_DONE_SPLIT_DONE md=%0d ordered_valid=%0d xor=%0d sort=%0d merges=%0d drop=%0d dup=%0d",
               md_n, gv_n, xor_n, sort_n, merge_count_o, drop_n, dup_n);
      if ((md_n == 4) && (gv_n == 4) && (xor_n == 0) && (sort_n == 112) &&
          (drop_n == 0) && (dup_n == 0))
        $display("MERGE_DONE_SPLIT_PASS");
      else
        $display("MERGE_DONE_SPLIT_FAIL md=%0d gv=%0d xor=%0d sort=%0d drop=%0d dup=%0d",
                 md_n, gv_n, xor_n, sort_n, drop_n, dup_n);
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_merge_done_split_probe u_g14_mds (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .sched_idle(sched_idle),
  .ng_st(u_core.state),
  .g_st(u_global.st),
  .merge_done(merge_done_o),
  .global_valid(global_topk_valid),
  .wave_valid_i(core_topk_valid),
  .busy_o(global_topk_busy),
  .merge_count_o(global_merge_count)
);
