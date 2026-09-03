// Bind-only occupancy probe. NO production RTL edit.
`timescale 1ns / 1ps

module g14_sort_occ_probe #(
  parameter int ST_SORT_CODE = 4,
  parameter int EXPECT = 28
) (
  input logic       clk,
  input logic       rst_n,
  input logic [2:0] st
);
  integer run_cyc, n_run, sum_cyc, min_cyc, max_cyc, bad;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      run_cyc <= 0; n_run <= 0; sum_cyc <= 0; min_cyc <= 0; max_cyc <= 0; bad <= 0;
    end else if (st == 3'(ST_SORT_CODE)) begin
      run_cyc <= run_cyc + 1;
    end else if (run_cyc > 0) begin
      n_run   <= n_run + 1;
      sum_cyc <= sum_cyc + run_cyc;
      if ((min_cyc == 0) || (run_cyc < min_cyc)) min_cyc <= run_cyc;
      if (run_cyc > max_cyc) max_cyc <= run_cyc;
      if (run_cyc != EXPECT) bad <= bad + 1;
      $display("SORT_RUN code=%0d cycles=%0d expect=%0d %s",
               ST_SORT_CODE, run_cyc, EXPECT, (run_cyc == EXPECT) ? "OK" : "FAIL");
      run_cyc <= 0;
    end
  end

  final begin
    $display("SORT_OCC_SUM code=%0d n_run=%0d sum=%0d min=%0d max=%0d bad=%0d",
             ST_SORT_CODE, n_run, sum_cyc, min_cyc, max_cyc, bad);
  end
endmodule

bind a7ng_topk_wavefront_minheap g14_sort_occ_probe #(.ST_SORT_CODE(4), .EXPECT(28)) u_g14_gsort (
  .clk(clk), .rst_n(rst_n), .st(st)
);

bind a7ng_topk_stream_minheap g14_sort_occ_probe #(.ST_SORT_CODE(2), .EXPECT(28)) u_g14_lsort (
  .clk(clk), .rst_n(rst_n), .st(st)
);
