// Isolated ST_SORT occupancy = 28. PROGRAM=NO. Bag TB only.
`timescale 1ns / 1ps

module tb_g14_sort_bound_count;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t   wave_score_i [8];
  node_id_t wave_id_i    [8];
  logic hv, hb;
  score_t hs [8];
  node_id_t hi [8];
  logic [31:0] hmc;

  a7ng_topk_wavefront_minheap #(.K(8)) u_g (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(hv), .global_score_o(hs), .global_id_o(hi),
    .busy_o(hb), .merge_count_o(hmc)
  );

  logic in_valid, in_ready, in_v, in_last, out_valid, out_ready, busy;
  score_t in_s, out_s;
  node_id_t in_id, out_id;
  logic [3:0] in_lane;
  logic [2:0] out_idx;

  a7ng_topk_stream_minheap #(.K(8)) u_l (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .in_v_i(in_v), .in_s_i(in_s), .in_id_i(in_id), .in_lane_i(in_lane),
    .in_last_i(in_last),
    .out_valid_o(out_valid), .out_ready_i(out_ready),
    .out_s_o(out_s), .out_id_o(out_id), .out_idx_o(out_idx),
    .busy_o(busy), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer k, t, fails, nout;

  initial begin
    fails = 0;
    rst_n = 0; clear_i = 0; wave_valid_i = 0; wave_scored_i = 0;
    in_valid = 0; in_v = 1; in_s = 0; in_id = 0; in_lane = 0; in_last = 0;
    out_ready = 1;
    for (k = 0; k < 8; k = k + 1) begin
      wave_score_i[k] = 0; wave_id_i[k] = 0;
    end
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    for (k = 0; k < 8; k = k + 1) begin
      wave_score_i[k] = score_t'(200 - 10*k);
      wave_id_i[k]    = node_id_t'(32'hA000 + k);
    end
    wave_scored_i = 5'd8;
    @(posedge clk);
    wave_valid_i = 1;
    @(posedge clk);
    wave_valid_i = 0;
    for (t = 0; t < 400; t = t + 1) begin
      @(posedge clk);
      if (hv) t = 400;
    end
    if (hmc !== 32'd1) begin
      $display("FAIL global merge_count=%0d", hmc);
      fails = fails + 1;
    end

    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    nout = 0;
    for (k = 0; k < 16; k = k + 1) begin
      while (!in_ready) @(posedge clk);
      in_valid = 1;
      in_v = 1;
      in_s = score_t'(16'sd300 - 16'(k));
      in_id = node_id_t'(32'hB000 + k);
      in_lane = 4'(k);
      in_last = (k == 15);
      @(posedge clk);
      in_valid = 0; in_last = 0;
    end
    out_ready = 1;
    for (t = 0; t < 400; t = t + 1) begin
      @(posedge clk);
      if (out_valid) nout = nout + 1;
      if ((nout >= 8) && !busy) t = 400;
    end
    if (nout != 8) begin
      $display("FAIL local drain nout=%0d", nout);
      fails = fails + 1;
    end

    #20;
    if (fails == 0)
      $display("SORT_BOUND_COUNT_XSIM_PASS");
    else
      $display("SORT_BOUND_COUNT_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
