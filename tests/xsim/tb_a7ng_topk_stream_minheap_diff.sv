// tb_a7ng_topk_stream_minheap_diff.sv — LOCAL-MINHEAP-STREAM-TOP8-00
// Differential vs frozen a7ng_topk. Exact ordered Top-8. PROGRAM=NO. XSim only.
`timescale 1ns / 1ps

module tb_a7ng_topk_stream_minheap_diff;
  import a7ng_pkg::*;

  localparam int NVEC_RAND = 100000;
  localparam int TIMEOUT   = 4000;

  logic clk, rst_n;

  logic               ref_valid_i, ref_valid_o;
  logic [15:0]        ref_mask;
  score_t             ref_s_i [16], ref_s_o [8];
  node_id_t           ref_id_i [16], ref_id_o [8];

  logic               clear_i, in_valid, in_ready, in_v, in_last;
  score_t             in_s;
  node_id_t           in_id;
  logic [3:0]         in_lane;
  logic               out_valid, out_ready;
  score_t             out_s;
  node_id_t           out_id;
  logic [2:0]         out_idx;
  logic               busy, clear_ignored;
  logic [31:0]        accepted, retired, drops;

  a7ng_topk u_ref (
    .clk(clk), .rst_n(rst_n),
    .valid_i(ref_valid_i), .valid_mask_i(ref_mask),
    .score_i(ref_s_i), .id_i(ref_id_i),
    .valid_o(ref_valid_o), .score_o(ref_s_o), .id_o(ref_id_o)
  );

  a7ng_topk_stream_minheap #(.K(8)) u_dut (
    .clk(clk), .rst_n(rst_n),
    .clear_i(clear_i),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .in_v_i(in_v), .in_s_i(in_s), .in_id_i(in_id), .in_lane_i(in_lane),
    .in_last_i(in_last),
    .out_valid_o(out_valid), .out_ready_i(out_ready),
    .out_s_o(out_s), .out_id_o(out_id), .out_idx_o(out_idx),
    .busy_o(busy), .clear_ignored_o(clear_ignored),
    .accepted_count_o(accepted), .retired_count_o(retired), .drop_count_o(drops)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer mismatches, fails, seed, bp_seed;
  integer vec_i, k, t, got, ignored_seen, r, stall_pat, drain_pat;
  integer beats, drain_n, w, in_stall, out_stall, done, hs_in, hs_out;
  score_t   exp_s [8], got_s [8];
  node_id_t exp_id [8], got_id [8];
  logic [2:0] got_idx [8];
  score_t   vec_s [16];
  node_id_t vec_id [16];
  logic [15:0] vec_mask;
  logic mon_rst;
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

  task automatic lcg(inout integer s, output integer rr);
    begin
      s  = s * 32'd1103515245 + 32'd12345;
      rr = s;
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

  task automatic stream_dut(input integer sp, input integer dp);
    begin
      in_valid  = 1'b0;
      out_ready = 1'b0;
      done      = 0;
      for (w = 0; w < TIMEOUT; w = w + 1) begin
        in_stall  = (sp == 0) ? 0 : ((sp == 1) ? (w[0] == 1'b1) : ((w % sp) == 0));
        out_stall = (dp == 0) ? 0 : ((dp == 1) ? (w[0] == 1'b0) : ((w % dp) == 0));

        if ((hs_in < 16) && !in_stall) begin
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
        out_ready = ((hs_out < 8) && !out_stall);

        tick;

        if ((hs_in == 16) && (hs_out == 8) && !busy && !out_valid) begin
          done = 1;
          w = TIMEOUT;
        end
      end
      if (!done) begin
        $display("FAIL dut timeout %s hs_in=%0d hs_out=%0d busy=%0d", tag, hs_in, hs_out, busy);
        fails = fails + 1;
      end
      in_valid  = 1'b0;
      in_last   = 1'b0;
      out_ready = 1'b1;
    end
  endtask

  task automatic compare_ordered;
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if (got_idx[k] !== 3'(k)) begin
          $display("MISMATCH %s idx slot%0d got_idx=%0d", tag, k, got_idx[k]);
          mismatches = mismatches + 1;
          fails = fails + 1;
        end
        if (got_s[k] !== exp_s[k] || got_id[k] !== exp_id[k]) begin
          $display("MISMATCH %s slot%0d ref s=%0d id=%h dut s=%0d id=%h",
                   tag, k, exp_s[k], exp_id[k], got_s[k], got_id[k]);
          mismatches = mismatches + 1;
          fails = fails + 1;
          if (mismatches >= 8) begin
            $display("ABORT after 8 mismatches");
            $display("MISMATCH_COUNT=%0d", mismatches);
            $finish;
          end
        end
      end
      if (accepted !== retired) begin
        $display("FAIL %s accepted=%0d retired=%0d", tag, accepted, retired);
        fails = fails + 1;
      end
      if (drops !== 32'd0) begin
        $display("FAIL %s drop_count=%0d", tag, drops);
        fails = fails + 1;
      end
      if (accepted !== 32'd16) begin
        $display("FAIL %s accepted=%0d want 16", tag, accepted);
        fails = fails + 1;
      end
    end
  endtask

  task automatic run_vec(input integer sp, input integer dp);
    begin
      idle_clear();
      capture_ref();
      stream_dut(sp, dp);
      compare_ordered();
    end
  endtask

  initial begin
    mismatches = 0;
    fails = 0;
    seed = 32'hC0DEC0DE;
    bp_seed = 32'hA5A55A5A;
    rst_n = 1'b0;
    mon_rst = 1'b0;
    clear_i = 1'b0;
    in_valid = 1'b0;
    in_v = 1'b0;
    in_s = '0;
    in_id = '0;
    in_lane = 4'd0;
    in_last = 1'b0;
    out_ready = 1'b1;
    ref_valid_i = 1'b0;
    ref_mask = 16'h0;
    for (k = 0; k < 16; k = k + 1) begin
      ref_s_i[k]  = '0;
      ref_id_i[k] = '0;
      vec_s[k]    = '0;
      vec_id[k]   = '0;
    end
    repeat (4) tick;
    rst_n = 1'b1;
    tick;

    tag = "desc_all";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd300 - 16'(k));
      vec_id[k] = node_id_t'(32'hA000 + k);
    end
    run_vec(0, 0);

    tag = "eqscore_id";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd42;
      vec_id[k] = node_id_t'(32'h1000 + (15 - k));
    end
    run_vec(1, 1);

    tag = "dup_score_id";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = 16'sd7;
      vec_id[k] = 32'h00C0FFEE;
    end
    run_vec(2, 2);

    tag = "two_dups";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd50 - 16'(k));
      vec_id[k] = node_id_t'(32'hB000 + k);
    end
    vec_s[3]  = vec_s[9];
    vec_id[3] = vec_id[9];
    run_vec(0, 1);

    tag = "signed_ext";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = (k[0]) ? -16'sd32768 : 16'sd32767;
      vec_id[k] = node_id_t'(k);
    end
    run_vec(3, 0);

    for (vec_i = 0; vec_i <= 16; vec_i = vec_i + 1) begin
      tag = $sformatf("mask_n%0d", vec_i);
      vec_mask = (vec_i == 16) ? 16'hFFFF : 16'((1 << vec_i) - 1);
      for (k = 0; k < 16; k = k + 1) begin
        vec_s[k]  = score_t'(16'sd1000 - 16'(3*k) - 16'(vec_i));
        vec_id[k] = node_id_t'(32'hC000 + vec_i*16 + k);
      end
      run_vec(vec_i[0], vec_i % 3);
    end

    tag = "bp_every";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd80 - 16'(k*5));
      vec_id[k] = node_id_t'(32'hD000 + k);
    end
    run_vec(1, 1);

    tag = "clear_idle";
    idle_clear();
    if (busy || accepted !== 32'd0 || retired !== 32'd0) begin
      $display("FAIL clear_idle leftover busy=%0d acc=%0d ret=%0d", busy, accepted, retired);
      fails = fails + 1;
    end

    tag = "clear_busy";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd200 - 16'(k));
      vec_id[k] = node_id_t'(32'hE000 + k);
    end
    idle_clear();
    capture_ref();
    ignored_seen = 0;
    in_valid  = 1'b0;
    out_ready = 1'b1;
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
      tick;
      if (hs_in == 16)
        w = TIMEOUT;
    end
    in_valid = 1'b0;
    in_last  = 1'b0;
    clear_i  = 1'b1;
    tick;
    if (clear_ignored)
      ignored_seen = 1;
    clear_i = 1'b0;
    for (t = 0; t < TIMEOUT; t = t + 1) begin
      out_ready = 1'b1;
      tick;
      if (clear_ignored)
        ignored_seen = 1;
      if ((hs_out == 8) && !busy)
        t = TIMEOUT;
    end
    if (!ignored_seen) begin
      $display("FAIL clear_busy did not raise clear_ignored_o");
      fails = fails + 1;
    end
    compare_ordered();

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
      lcg(bp_seed, r);
      stall_pat = r[2:0];
      lcg(bp_seed, r);
      drain_pat = r[2:0];
      run_vec(stall_pat, drain_pat);
      if ((vec_i % 10000) == 0)
        $display("PROGRESS rnd=%0d mismatches=%0d fails=%0d", vec_i, mismatches, fails);
      if (fails != 0) begin
        $display("ABORT at rnd=%0d", vec_i);
        $display("MISMATCH_COUNT=%0d", mismatches);
        $display("LOCAL_MINHEAP_STREAM_TOP8_XSIM_FAIL");
        $finish;
      end
    end

    $display("MISMATCH_COUNT=%0d", mismatches);
    $display("accepted_candidates=retired_candidates");
    $display("drop_count=0");
    $display("FAILS=%0d", fails);
    if ((fails == 0) && (mismatches == 0))
      $display("LOCAL_MINHEAP_STREAM_TOP8_XSIM_PASS");
    else
      $display("LOCAL_MINHEAP_STREAM_TOP8_XSIM_FAIL");
    #50 $finish;
  end
endmodule
