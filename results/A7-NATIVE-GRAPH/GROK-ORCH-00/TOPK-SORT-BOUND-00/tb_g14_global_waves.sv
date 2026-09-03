// Global recurrence 1..4 waves vs frozen bitonic. Ordered + merge_count == n_waves.
`timescale 1ns / 1ps

module tb_g14_global_waves;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t wave_score_i [8];
  node_id_t wave_id_i [8];
  logic bv, hv, bb, hb;
  score_t bs [8], hs [8];
  node_id_t bi [8], hi [8];
  logic [31:0] bmc, hmc;

  a7ng_topk_wavefront_global #(.K(8)) u_b (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(bv), .global_score_o(bs), .global_id_o(bi),
    .busy_o(bb), .merge_count_o(bmc)
  );
  a7ng_topk_wavefront_minheap #(.K(8)) u_h (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(hv), .global_score_o(hs), .global_id_o(hi),
    .busy_o(hb), .merge_count_o(hmc)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, mismatches, nw, w, i, t, seed, rr;
  logic got_b, got_h;
  score_t cap_bs [8], cap_hs [8];
  node_id_t cap_bi [8], cap_hi [8];

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic one_wave(input integer wv, input integer base);
    begin
      while (bb || hb) tick;
      for (i = 0; i < 8; i = i + 1) begin
        wave_score_i[i] = score_t'(16'sd800 - 16'(20 * wv) - 16'(i) - 16'(base));
        wave_id_i[i]    = node_id_t'(32'h1000 * (wv + 1) + i);
      end
      wave_scored_i = 5'd8;
      tick;
      wave_valid_i = 1; tick; wave_valid_i = 0;
      got_b = 0; got_h = 0;
      for (t = 0; t < 400; t = t + 1) begin
        tick;
        if (bv) begin
          got_b = 1;
          for (i = 0; i < 8; i = i + 1) begin
            cap_bs[i] = bs[i]; cap_bi[i] = bi[i];
          end
        end
        if (hv) begin
          got_h = 1;
          for (i = 0; i < 8; i = i + 1) begin
            cap_hs[i] = hs[i]; cap_hi[i] = hi[i];
          end
        end
        if (got_b && got_h) t = 400;
      end
      if (!(got_b && got_h)) begin
        $display("FAIL timeout waves=%0d w=%0d", nw, wv);
        fails = fails + 1;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          if ((cap_bs[i] !== cap_hs[i]) || (cap_bi[i] !== cap_hi[i])) begin
            $display("MISMATCH n=%0d w=%0d slot%0d b s=%0d id=%h h s=%0d id=%h",
                     nw, wv, i, cap_bs[i], cap_bi[i], cap_hs[i], cap_hi[i]);
            mismatches = mismatches + 1; fails = fails + 1;
          end
        end
        if (bmc !== 32'(wv + 1) || hmc !== 32'(wv + 1)) begin
          $display("FAIL merge_count n=%0d w=%0d bmc=%0d hmc=%0d want=%0d",
                   nw, wv, bmc, hmc, wv + 1);
          fails = fails + 1;
        end
      end
    end
  endtask

  task automatic lcg(inout integer s, output integer rr);
    begin
      s  = s * 32'd1103515245 + 32'd12345;
      rr = s;
    end
  endtask

  initial begin
    fails = 0; mismatches = 0; seed = 32'hA5A55A5A;
    rst_n = 0; clear_i = 0; wave_valid_i = 0; wave_scored_i = 0;
    for (i = 0; i < 8; i = i + 1) begin wave_score_i[i] = 0; wave_id_i[i] = 0; end
    repeat (4) @(posedge clk); rst_n = 1; tick;
    for (nw = 1; nw <= 4; nw = nw + 1) begin
      clear_i = 1; tick; clear_i = 0; tick;
      for (w = 0; w < nw; w = w + 1)
        one_wave(w, nw);
      $display("WAVES_%0d merge_b=%0d merge_h=%0d mismatches_so_far=%0d",
               nw, bmc, hmc, mismatches);
    end

    // Random 4-wave recurrence, ordered after each wave.
    clear_i = 1; tick; clear_i = 0; tick;
    nw = 4;
    for (w = 0; w < 4; w = w + 1) begin
      while (bb || hb) tick;
      for (i = 0; i < 8; i = i + 1) begin
        lcg(seed, rr);
        wave_score_i[i] = score_t'(rr[15:0]);
        lcg(seed, rr);
        wave_id_i[i] = node_id_t'(rr);
      end
      wave_scored_i = 5'd8;
      tick;
      wave_valid_i = 1; tick; wave_valid_i = 0;
      got_b = 0; got_h = 0;
      for (t = 0; t < 400; t = t + 1) begin
        tick;
        if (bv) begin
          got_b = 1;
          for (i = 0; i < 8; i = i + 1) begin
            cap_bs[i] = bs[i]; cap_bi[i] = bi[i];
          end
        end
        if (hv) begin
          got_h = 1;
          for (i = 0; i < 8; i = i + 1) begin
            cap_hs[i] = hs[i]; cap_hi[i] = hi[i];
          end
        end
        if (got_b && got_h) t = 400;
      end
      if (!(got_b && got_h)) begin
        $display("FAIL timeout rnd w=%0d", w);
        fails = fails + 1;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          if ((cap_bs[i] !== cap_hs[i]) || (cap_bi[i] !== cap_hi[i])) begin
            $display("MISMATCH rnd w=%0d slot%0d", w, i);
            mismatches = mismatches + 1; fails = fails + 1;
          end
        end
        if (bmc !== 32'(w + 1) || hmc !== 32'(w + 1)) begin
          $display("FAIL rnd merge_count w=%0d bmc=%0d hmc=%0d", w, bmc, hmc);
          fails = fails + 1;
        end
      end
    end
    $display("RND4 merge_b=%0d merge_h=%0d", bmc, hmc);

    $display("GLOBAL_WAVES mismatches=%0d fails=%0d", mismatches, fails);
    if ((fails == 0) && (mismatches == 0))
      $display("GLOBAL_WAVES_XSIM_PASS DIFF_COUNT=0");
    else
      $display("GLOBAL_WAVES_XSIM_FAIL DIFF_COUNT=%0d", mismatches);
    $finish;
  end
endmodule
