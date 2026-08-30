// Differential: frozen bitonic wavefront vs min-heap. PROGRAM=NO. XSim only.
`timescale 1ns / 1ps

module tb_a7ng_topk_minheap_diff;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t   wave_score_i [8];
  node_id_t wave_id_i    [8];

  logic       bv, hv, bb, hb;
  score_t     bs [8], hs [8];
  node_id_t   bi [8], hi [8];
  logic [31:0] bmc, hmc;

  a7ng_topk_wavefront_global #(.K(8)) u_bitonic (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(bv), .global_score_o(bs), .global_id_o(bi),
    .busy_o(bb), .merge_count_o(bmc)
  );

  a7ng_topk_wavefront_minheap #(.K(8), .HEAP_CMP_LANES(1)) u_heap (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(hv), .global_score_o(hs), .global_id_o(hi),
    .busy_o(hb), .merge_count_o(hmc)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, mismatches, i, c, seed, q, w;

  task automatic wait_pair(output logic ok);
    integer t;
    logic got_b, got_h;
    begin
      ok = 1'b0; got_b = 1'b0; got_h = 1'b0;
      for (t = 0; t < 400; t = t + 1) begin
        @(posedge clk);
        if (bv) got_b = 1'b1;
        if (hv) got_h = 1'b1;
        if (got_b && got_h) begin
          ok = 1'b1;
          return;
        end
      end
    end
  endtask

  task automatic drive_and_cmp(input logic [4:0] n, input string tag);
    logic ok;
    integer k;
    begin
      while (bb || hb) @(posedge clk);
      wave_scored_i = n;
      @(posedge clk);
      wave_valid_i = 1'b1;
      @(posedge clk);
      wave_valid_i = 1'b0;
      wait_pair(ok);
      if (!ok) begin
        $display("FAIL timeout %s", tag);
        fails = fails + 1;
      end else begin
        for (k = 0; k < 8; k = k + 1) begin
          if (bs[k] !== hs[k] || bi[k] !== hi[k]) begin
            $display("MISMATCH %s slot%0d bitonic s=%0d id=%0h heap s=%0d id=%0h",
                     tag, k, bs[k], bi[k], hs[k], hi[k]);
            mismatches = mismatches + 1;
            fails = fails + 1;
          end
        end
        if (bmc !== hmc) begin
          $display("FAIL merge_count %s bitonic=%0d heap=%0d", tag, bmc, hmc);
          fails = fails + 1;
        end
      end
    end
  endtask

  initial begin
    fails = 0; mismatches = 0;
    rst_n = 0; clear_i = 0; wave_valid_i = 0; wave_scored_i = 0;
    for (i = 0; i < 8; i = i + 1) begin
      wave_score_i[i] = 0; wave_id_i[i] = 0;
    end
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // F1 counterexample (same as tb_a7ng_wf_global_topk)
    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    for (i = 0; i < 8; i = i + 1) begin
      wave_score_i[i] = score_t'(200 - 10*i);
      wave_id_i[i]    = node_id_t'(32'hA000 + i);
    end
    drive_and_cmp(5'd8, "W1");
    wave_score_i[0] = 135; wave_id_i[0] = 32'hDEAD_BEEF;
    for (i = 1; i < 8; i = i + 1) begin
      wave_score_i[i] = score_t'(50 - i);
      wave_id_i[i]    = node_id_t'(32'hB000 + i);
    end
    drive_and_cmp(5'd8, "W2_DEADBEEF");
    if (hi[7] !== 32'hDEAD_BEEF) begin
      $display("FAIL F1 heap missing DEADBEEF in slot7 id=%0h", hi[7]);
      fails = fails + 1;
    end

    // Equal-score, lower id wins
    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    for (i = 0; i < 8; i = i + 1) begin
      wave_score_i[i] = 10; wave_id_i[i] = node_id_t'(32'h1000 + (7-i));
    end
    drive_and_cmp(5'd8, "eqscore_w1");
    for (i = 0; i < 8; i = i + 1) begin
      wave_score_i[i] = 10; wave_id_i[i] = node_id_t'(32'h0F00 + i);
    end
    drive_and_cmp(5'd8, "eqscore_w2");

    // Underfill
    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    wave_score_i[0] = 99; wave_id_i[0] = 32'h11;
    wave_score_i[1] = 88; wave_id_i[1] = 32'h22;
    for (i = 2; i < 8; i = i + 1) begin
      wave_score_i[i] = 0; wave_id_i[i] = 0;
    end
    drive_and_cmp(5'd2, "underfill");

    // Four waves
    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    for (w = 0; w < 4; w = w + 1) begin
      for (i = 0; i < 8; i = i + 1) begin
        wave_score_i[i] = score_t'(1000 - 20*w - i);
        wave_id_i[i]    = node_id_t'(32'h8000 + 16*w + i);
      end
      drive_and_cmp(5'd8, $sformatf("four_w%0d", w));
    end

    // Deterministic random
    seed = 32'hA5A5_5A5A;
    clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
    for (q = 0; q < 32; q = q + 1) begin
      if (q[2:0] == 0) begin
        clear_i = 1; @(posedge clk); clear_i = 0; @(posedge clk);
      end
      for (i = 0; i < 8; i = i + 1) begin
        seed = seed * 32'd1103515245 + 32'd12345;
        wave_score_i[i] = score_t'(seed[15:0]);
        seed = seed * 32'd1103515245 + 32'd12345;
        wave_id_i[i]    = seed;
      end
      drive_and_cmp(5'd8, $sformatf("rnd%0d", q));
    end

    $display("MINHEAP_DIFF mismatches=%0d fails=%0d", mismatches, fails);
    if (fails == 0)
      $display("GLOBAL_TOPK_MINHEAP_XSIM_PASS");
    else
      $display("GLOBAL_TOPK_MINHEAP_XSIM_FAIL");
    #50 $finish;
  end
endmodule
