// GLOBAL-MERGE-DONE-SPLIT-00 unit: merge_done coincident with ordered valid.
// ST_SORT still 28/wave. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_g14_merge_done_split;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i, gv, md, busy;
  logic [4:0] wave_scored_i;
  score_t wave_score_i [8];
  node_id_t wave_id_i [8];
  score_t gs [8];
  node_id_t gi [8];
  logic [31:0] merges;

  a7ng_topk_wavefront_minheap #(.K(8)) dut (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(gv), .global_score_o(gs), .global_id_o(gi),
    .busy_o(busy), .merge_count_o(merges), .merge_done_o(md)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer md_n, gv_n, xor_n, sort_n, drop_n, fails, w, i, t;
  integer sort_w [0:3];
  score_t cap_s [0:3][0:7];
  node_id_t cap_id [0:3][0:7];

  always @(posedge clk) begin
    if (!rst_n || clear_i) begin
      md_n <= 0; gv_n <= 0; xor_n <= 0; sort_n <= 0; drop_n <= 0;
    end else begin
      if (md) md_n <= md_n + 1;
      if (gv) gv_n <= gv_n + 1;
      if (md !== gv) xor_n <= xor_n + 1;
      if (dut.st == 3'd4) sort_n <= sort_n + 1;
      if (wave_valid_i && busy) drop_n <= drop_n + 1;
    end
  end

  task automatic tick; begin @(posedge clk); #1; end endtask

  task automatic drive_wave(input integer wv);
    begin
      while (busy) tick;
      for (i = 0; i < 8; i = i + 1) begin
        wave_score_i[i] = score_t'(16'sd240 - 16'(8 * wv) - 16'(i));
        wave_id_i[i]    = node_id_t'(32'(32 + 8 * wv + i));
      end
      wave_scored_i = 5'd8;
      tick;
      wave_valid_i = 1; tick; wave_valid_i = 0;
      for (t = 0; t < 400; t = t + 1) begin
        tick;
        if (gv && md) begin
          for (i = 0; i < 8; i = i + 1) begin
            cap_s[wv][i]  = gs[i];
            cap_id[wv][i] = gi[i];
          end
          t = 400;
        end
      end
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 0; clear_i = 0; wave_valid_i = 0; wave_scored_i = 0;
    for (i = 0; i < 8; i = i + 1) begin wave_score_i[i] = 0; wave_id_i[i] = 0; end
    repeat (4) @(posedge clk); rst_n = 1; tick;
    clear_i = 1; tick; clear_i = 0; tick;
    for (w = 0; w < 4; w = w + 1)
      drive_wave(w);
    while (busy) tick;
    tick; tick;

    $display("MERGE_DONE_SPLIT_UNIT md=%0d gv=%0d xor=%0d sort=%0d merges=%0d drop=%0d",
             md_n, gv_n, xor_n, sort_n, merges, drop_n);
    if (md_n !== 4 || gv_n !== 4 || xor_n !== 0 || merges !== 32'd4 || drop_n !== 0)
      fails = fails + 1;
    if (sort_n !== 112) begin
      $display("MERGE_DONE_SPLIT_SORT_FAIL got=%0d want=112", sort_n);
      fails = fails + 1;
    end
    for (w = 0; w < 4; w = w + 1) begin
      for (i = 0; i < 7; i = i + 1) begin
        if (cap_s[w][i] < cap_s[w][i+1]) begin
          $display("ORDER_FAIL w=%0d slot%0d s=%0d < next %0d",
                   w, i, cap_s[w][i], cap_s[w][i+1]);
          fails = fails + 1;
        end
      end
      $write("WAVE%0d_OUT", w);
      for (i = 0; i < 8; i = i + 1)
        $write(" id=%0d,s=%0d", cap_id[w][i], cap_s[w][i]);
      $write("\n");
    end
    if (fails == 0)
      $display("MERGE_DONE_SPLIT_UNIT_PASS");
    else
      $display("MERGE_DONE_SPLIT_UNIT_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
