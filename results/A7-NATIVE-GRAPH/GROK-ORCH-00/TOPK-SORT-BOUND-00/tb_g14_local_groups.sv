// Directed groups vs frozen a7ng_topk. Clocked capture (NBA). PROGRAM=NO. Bag TB only.
`timescale 1ns / 1ps

module tb_g14_local_groups;
  import a7ng_pkg::*;

  localparam int TIMEOUT = 4000;
  localparam int NVEC_RAND = 256;

  logic clk, rst_n;
  logic ref_valid_i, ref_valid_o;
  logic [15:0] ref_mask;
  score_t ref_s_i [16], ref_s_o [8];
  node_id_t ref_id_i [16], ref_id_o [8];

  logic clear_i, in_valid, in_ready, in_v, in_last;
  score_t in_s, out_s;
  node_id_t in_id, out_id;
  logic [3:0] in_lane;
  logic out_valid, out_ready, busy, mon_rst;
  logic [2:0] out_idx;
  logic [31:0] accepted, retired, drops;

  a7ng_topk u_ref (
    .clk(clk), .rst_n(rst_n),
    .valid_i(ref_valid_i), .valid_mask_i(ref_mask),
    .score_i(ref_s_i), .id_i(ref_id_i),
    .valid_o(ref_valid_o), .score_o(ref_s_o), .id_o(ref_id_o)
  );
  a7ng_topk_stream_minheap #(.K(8)) u_dut (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .in_v_i(in_v), .in_s_i(in_s), .in_id_i(in_id), .in_lane_i(in_lane),
    .in_last_i(in_last),
    .out_valid_o(out_valid), .out_ready_i(out_ready),
    .out_s_o(out_s), .out_id_o(out_id), .out_idx_o(out_idx),
    .busy_o(busy), .clear_ignored_o(),
    .accepted_count_o(accepted), .retired_count_o(retired), .drop_count_o(drops)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  score_t vec_s [16], exp_s [8], got_s [8];
  node_id_t vec_id [16], exp_id [8], got_id [8];
  logic [2:0] got_idx [8];
  logic [15:0] vec_mask;
  integer k, w, hs_in, hs_out, fails, mismatches, seed, r, vec_i, done;
  string tag;

  always @(posedge clk) begin
    if (!rst_n || mon_rst) begin
      hs_in  <= 0;
      hs_out <= 0;
    end else begin
      if (in_valid && in_ready)
        hs_in <= hs_in + 1;
      if (out_valid && out_ready && (hs_out < 8)) begin
        got_s[hs_out]   <= out_s;
        got_id[hs_out]  <= out_id;
        got_idx[hs_out] <= out_idx;
        hs_out          <= hs_out + 1;
      end
    end
  end

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic idle_clear;
    begin
      in_valid    = 1'b0;
      in_last     = 1'b0;
      out_ready   = 1'b1;
      ref_valid_i = 1'b0;
      tick;
      while (busy) tick;
      clear_i = 1'b1;
      mon_rst = 1'b1;
      tick;
      clear_i = 1'b0;
      mon_rst = 1'b0;
      tick;
    end
  endtask

  task automatic capture_ref;
    begin
      ref_mask = vec_mask;
      for (k = 0; k < 16; k = k + 1) begin
        ref_s_i[k]  = vec_s[k];
        ref_id_i[k] = vec_id[k];
      end
      tick;
      ref_valid_i = 1'b1;
      tick;
      if (ref_valid_o) begin
        for (k = 0; k < 8; k = k + 1) begin
          exp_s[k]  = ref_s_o[k];
          exp_id[k] = ref_id_o[k];
        end
        ref_valid_i = 1'b0;
        return;
      end
      ref_valid_i = 1'b0;
      $display("FAIL ref timeout %s", tag);
      fails = fails + 1;
    end
  endtask

  task automatic stream_dut;
    begin
      in_valid  = 1'b0;
      out_ready = 1'b1;
      done      = 0;
      for (w = 0; w < TIMEOUT; w = w + 1) begin
        if (hs_in < 16) begin
          in_valid = 1'b1;
          in_v     = vec_mask[hs_in];
          in_s     = vec_s[hs_in];
          in_id    = vec_id[hs_in];
          in_lane  = 4'(hs_in);
          in_last  = (hs_in == 15);
        end else begin
          in_valid = 1'b0;
          in_last  = 1'b0;
        end
        out_ready = 1'b1;
        tick;
        if ((hs_in == 16) && (hs_out == 8) && !busy && !out_valid) begin
          done = 1;
          w = TIMEOUT;
        end
      end
      if (!done) begin
        $display("FAIL dut timeout %s hs_in=%0d hs_out=%0d busy=%0d",
                 tag, hs_in, hs_out, busy);
        fails = fails + 1;
      end
      in_valid = 1'b0;
      in_last  = 1'b0;
      out_ready = 1'b1;
    end
  endtask

  task automatic compare_ordered;
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if (got_idx[k] !== 3'(k)) begin
          $display("MISMATCH %s idx slot%0d got=%0d", tag, k, got_idx[k]);
          mismatches = mismatches + 1;
          fails = fails + 1;
        end
        if ((got_s[k] !== exp_s[k]) || (got_id[k] !== exp_id[k])) begin
          $display("MISMATCH %s slot%0d ref s=%0d id=%h dut s=%0d id=%h",
                   tag, k, exp_s[k], exp_id[k], got_s[k], got_id[k]);
          mismatches = mismatches + 1;
          fails = fails + 1;
        end
      end
    end
  endtask

  task automatic run_one;
    begin
      idle_clear();
      capture_ref();
      stream_dut();
      compare_ordered();
    end
  endtask

  task automatic lcg(inout integer s, output integer rr);
    begin
      s  = s * 32'd1103515245 + 32'd12345;
      rr = s;
    end
  endtask

  initial begin
    fails = 0; mismatches = 0; rst_n = 0; ref_valid_i = 0; clear_i = 0;
    in_valid = 0; in_v = 1; in_s = 0; in_id = 0; in_lane = 0; in_last = 0;
    out_ready = 1; mon_rst = 0; seed = 32'hC0DEC0DE;
    repeat (4) @(posedge clk); rst_n = 1; tick;

    tag = "reverse_ordered";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd10 + 16'(k));
      vec_id[k] = node_id_t'(32'h10 + k);
    end
    run_one();

    tag = "ordered_input";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd100 - 16'(k));
      vec_id[k] = node_id_t'(32'h40 + k);
    end
    run_one();

    tag = "all_equal_scores";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd42;
      vec_id[k] = node_id_t'(32'h1000 + (15 - k));
    end
    run_one();

    tag = "duplicate_ids";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd7;
      vec_id[k] = 32'h00C0FFEE;
    end
    run_one();

    tag = "score_ties_id_asc";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd5;
      vec_id[k] = node_id_t'(32'hF000 - k);
    end
    run_one();

    tag = "id_ties_lane_asc";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd11;
      vec_id[k] = 32'h00AABBCC;
    end
    run_one();

    tag = "lane_ties_same_score_id";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd9;
      vec_id[k] = 32'h00AABBCC;
    end
    run_one();

    tag = "all_negative";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(-16'sd1 - 16'(k));
      vec_id[k] = node_id_t'(32'h20 + k);
    end
    run_one();

    tag = "int16_extrema";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = (k[0]) ? -16'sd32768 : 16'sd32767;
      vec_id[k] = node_id_t'(k);
    end
    run_one();

    tag = "underfill";
    vec_mask = 16'h000F;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd200 - 16'(k));
      vec_id[k] = node_id_t'(32'h50 + k);
    end
    run_one();

    tag = "invalid_entries";
    vec_mask = 16'hA5A5;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd80 - 16'(3 * k));
      vec_id[k] = node_id_t'(32'h60 + k);
    end
    run_one();

    tag = "worst_case_replacements";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd1000 + 16'(k));
      vec_id[k] = node_id_t'(32'h30 + k);
    end
    run_one();

    for (vec_i = 0; vec_i < NVEC_RAND; vec_i = vec_i + 1) begin
      tag = $sformatf("rnd%0d", vec_i);
      lcg(seed, r);
      vec_mask = r[15:0];
      for (k = 0; k < 16; k = k + 1) begin
        lcg(seed, r);
        vec_s[k] = score_t'(r[15:0]);
        lcg(seed, r);
        vec_id[k] = node_id_t'(r);
      end
      run_one();
      if (fails != 0) begin
        $display("ABORT at %s", tag);
        $display("LOCAL_GROUPS_XSIM_FAIL DIFF_COUNT=%0d", mismatches);
        $finish;
      end
    end

    $display("LOCAL_GROUPS mismatches=%0d fails=%0d", mismatches, fails);
    if ((fails == 0) && (mismatches == 0))
      $display("LOCAL_GROUPS_XSIM_PASS DIFF_COUNT=0");
    else
      $display("LOCAL_GROUPS_XSIM_FAIL DIFF_COUNT=%0d", mismatches);
    $finish;
  end
endmodule
