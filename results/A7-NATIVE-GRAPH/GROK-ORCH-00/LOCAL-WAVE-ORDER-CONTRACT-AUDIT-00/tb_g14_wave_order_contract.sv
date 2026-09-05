// LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00. NO RTL EDIT. PROGRAM=NO.
// Same SET, three presentations (id, reverse, shuffle) into global minheap.
`timescale 1ns / 1ps

module tb_g14_wave_order_contract;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t   wave_score_i [8];
  node_id_t wave_id_i    [8];
  logic gv, busy;
  score_t   gs [8];
  node_id_t gi [8];
  logic [31:0] merges;

  a7ng_topk_wavefront_minheap #(.K(8)) u_g (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(gv), .global_score_o(gs), .global_id_o(gi),
    .busy_o(busy), .merge_count_o(merges)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, k, t, w, p, a, b, tmp, seed, rr;
  score_t   src_s [0:3][0:7];
  node_id_t src_id [0:3][0:7];
  score_t   gold_s [8], cap_s [8];
  node_id_t gold_id [8], cap_id [8];
  integer perm [8];
  logic got;

  task automatic tick; begin @(posedge clk); #1; end endtask

  task automatic lcg(inout integer s, output integer r);
    begin s = s * 32'd1103515245 + 32'd12345; r = s; end
  endtask

  task automatic capture_one(output logic ok);
    begin
      got = 0;
      for (t = 0; t < 400; t = t + 1) begin
        tick;
        if (gv) begin
          got = 1;
          for (k = 0; k < 8; k = k + 1) begin
            cap_s[k]  = gs[k];
            cap_id[k] = gi[k];
          end
        end
        if (got && !busy) t = 400;
      end
      ok = got;
    end
  endtask

  task automatic drive_wave(input integer wv, input integer mode);
    begin
      while (busy) tick;
      for (k = 0; k < 8; k = k + 1) perm[k] = k;
      if (mode == 1) begin
        for (k = 0; k < 8; k = k + 1) perm[k] = 7 - k;
      end else if (mode == 2) begin
        for (k = 7; k > 0; k = k - 1) begin
          lcg(seed, rr);
          a = k;
          b = (rr < 0 ? -rr : rr) % (k + 1);
          tmp = perm[a]; perm[a] = perm[b]; perm[b] = tmp;
        end
      end
      for (k = 0; k < 8; k = k + 1) begin
        wave_score_i[k] = src_s[wv][perm[k]];
        wave_id_i[k]    = src_id[wv][perm[k]];
      end
      wave_scored_i = 5'd8;
      tick;
      wave_valid_i = 1; tick; wave_valid_i = 0;
    end
  endtask

  task automatic cmp_gold(input string tag);
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if ((cap_s[k] !== gold_s[k]) || (cap_id[k] !== gold_id[k])) begin
          $display("ORDER_CONTRACT_FAIL %s slot%0d gold s=%0d id=%0d got s=%0d id=%0d",
                   tag, k, gold_s[k], gold_id[k], cap_s[k], cap_id[k]);
          fails = fails + 1;
        end
      end
    end
  endtask

  integer ok_i;
  logic ok;

  initial begin
    fails = 0; seed = 32'hC0FFEE01;
    rst_n = 0; clear_i = 0; wave_valid_i = 0; wave_scored_i = 0;
    for (k = 0; k < 8; k = k + 1) begin wave_score_i[k] = 0; wave_id_i[k] = 0; end
    for (w = 0; w < 4; w = w + 1)
      for (k = 0; k < 8; k = k + 1) begin
        src_s[w][k]  = score_t'(16'sd900 - 16'(30 * w) - 16'(3 * k) - 16'(w));
        src_id[w][k] = node_id_t'(32'h1000 * (w + 1) + k);
      end
    repeat (4) @(posedge clk); rst_n = 1; tick;

    // --- 1-wave SET: identity gold, reverse + 16 shuffles must match ---
    clear_i = 1; tick; clear_i = 0; tick;
    drive_wave(0, 0);
    capture_one(ok);
    if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout gold1"); fails = fails + 1; end
    for (k = 0; k < 8; k = k + 1) begin gold_s[k] = cap_s[k]; gold_id[k] = cap_id[k]; end
    $display("ORDER_CONTRACT_GOLD1 s0=%0d id0=%0d", gold_s[0], gold_id[0]);

    clear_i = 1; tick; clear_i = 0; tick;
    drive_wave(0, 1);
    capture_one(ok);
    if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout rev1"); fails = fails + 1; end
    else cmp_gold("rev1");

    for (p = 0; p < 16; p = p + 1) begin
      clear_i = 1; tick; clear_i = 0; tick;
      drive_wave(0, 2);
      capture_one(ok);
      if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout shuf1 p=%0d", p); fails = fails + 1; end
      else cmp_gold("shuf1");
    end

    // --- 4-wave recurrence: identity gold vs reverse-each and shuffle-each ---
    clear_i = 1; tick; clear_i = 0; tick;
    for (w = 0; w < 4; w = w + 1) begin
      drive_wave(w, 0);
      capture_one(ok);
      if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout gold4 w=%0d", w); fails = fails + 1; end
    end
    for (k = 0; k < 8; k = k + 1) begin gold_s[k] = cap_s[k]; gold_id[k] = cap_id[k]; end
    $display("ORDER_CONTRACT_GOLD4 s0=%0d id0=%0d merges=%0d", gold_s[0], gold_id[0], merges);

    clear_i = 1; tick; clear_i = 0; tick;
    for (w = 0; w < 4; w = w + 1) begin
      drive_wave(w, 1);
      capture_one(ok);
      if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout rev4 w=%0d", w); fails = fails + 1; end
    end
    cmp_gold("rev4");

    clear_i = 1; tick; clear_i = 0; tick;
    for (w = 0; w < 4; w = w + 1) begin
      drive_wave(w, 2);
      capture_one(ok);
      if (!ok) begin $display("ORDER_CONTRACT_FAIL timeout shuf4 w=%0d", w); fails = fails + 1; end
    end
    cmp_gold("shuf4");

    // Equal-score unique-id: reverse must still match (id tiebreak, not lane)
    for (k = 0; k < 8; k = k + 1) begin
      src_s[0][k]  = 16'sd100;
      src_id[0][k] = node_id_t'(32'(k + 1));
    end
    clear_i = 1; tick; clear_i = 0; tick;
    drive_wave(0, 0);
    capture_one(ok);
    if (!ok) fails = fails + 1;
    for (k = 0; k < 8; k = k + 1) begin gold_s[k] = cap_s[k]; gold_id[k] = cap_id[k]; end
    clear_i = 1; tick; clear_i = 0; tick;
    drive_wave(0, 1);
    capture_one(ok);
    if (!ok) fails = fails + 1;
    else cmp_gold("eqscore_rev");

    if (fails == 0) $display("LOCAL_WAVE_ORDER_CONTRACT_PASS");
    else $display("LOCAL_WAVE_ORDER_CONTRACT_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
