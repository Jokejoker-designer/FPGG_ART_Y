// tb_a7ng_ng02_flow.sv — NG-02R-FLOW backpressure / conservation
// Hard stop: ≥100_000 cycles random ready/valid
//   DROP = 0, DUPLICATE = 0, UNEXPLAINED_REORDER = 0
// Invariant each sample (after posedge NBA):
//   accepted = queued + popped + intentionally_pruned + still_in_pipeline
`timescale 1ns / 1ps

module tb_a7ng_ng02_flow;
  import a7ng_pkg::*;

  localparam int unsigned CYCLES = 100_000;

  logic clk, rst_n;
  logic [NG_LANES-1:0] lane_valid;
  node_id_t     cand_id [NG_LANES];
  score_terms_t terms   [NG_LANES];
  logic         frontier_pop;

  logic         batch_ready;
  logic         topk_valid;
  score_t       topk_s [8];
  node_id_t     topk_id [8];
  logic         pop_v, ovf;
  score_t       f_s;
  node_id_t     f_id;
  logic [7:0]   fcnt;
  logic         flow_busy;
  logic [2:0]   push_idx;
  logic         push_fire;
  logic         push_stall;
  logic         beat_v;
  score_t       beat_s;
  node_id_t     beat_id;
  logic [1:0]   flow_state;

  a7ng_ng02_core dut (
    .clk(clk),
    .rst_n(rst_n),
    .lane_valid_i(lane_valid),
    .cand_id_i(cand_id),
    .terms_i(terms),
    .frontier_pop_i(frontier_pop),
    .batch_ready_o(batch_ready),
    .topk_valid_o(topk_valid),
    .topk_score_o(topk_s),
    .topk_id_o(topk_id),
    .frontier_pop_valid_o(pop_v),
    .frontier_score_o(f_s),
    .frontier_id_o(f_id),
    .frontier_overflow_o(ovf),
    .frontier_count_o(fcnt),
    .flow_busy_o(flow_busy),
    .push_idx_o(push_idx),
    .push_fire_o(push_fire),
    .push_stall_o(push_stall),
    .push_beat_valid_o(beat_v),
    .push_beat_score_o(beat_s),
    .push_beat_id_o(beat_id),
    .flow_state_o(flow_state)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  logic [31:0] rnd;
  function automatic logic [31:0] next_rnd(input logic [31:0] x);
    return {x[30:0], x[31] ^ x[21] ^ x[1] ^ x[0]};
  endfunction

  localparam int unsigned QMAX = 8192;
  node_id_t    exp_id [QMAX];
  score_t      exp_s  [QMAX];
  int unsigned q_hd, q_tl;

  int unsigned accepted_winners;
  int unsigned popped_n;
  int unsigned overflow_n;
  int unsigned drop_n;
  int unsigned dup_n;
  int unsigned reorder_n;
  int unsigned cons_fail_n;
  int unsigned ready_busy_fail_n;
  int unsigned batches_accepted;
  int unsigned cycle_i;
  int unsigned batch_tag;

  localparam int unsigned SEEN_N = 1024;
  node_id_t seen_id [SEEN_N];
  bit       seen_v  [SEEN_N];
  int unsigned seen_wr;

  int unsigned still_pipe;
  int unsigned queued;
  int unsigned intentionally_pruned;
  int unsigned cons_rhs;
  int li, k;
  bit do_batch;
  bit do_pop;
  bit present;
  bit saw_topk;

  task automatic enqueue_expected;
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if ((q_tl - q_hd) >= QMAX) begin
          $display("FAIL expected queue overflow");
          drop_n = drop_n + 1;
        end else begin
          exp_id[q_tl % QMAX] = topk_id[k];
          exp_s[q_tl % QMAX]  = topk_s[k];
          q_tl = q_tl + 1;
          accepted_winners = accepted_winners + 1;
        end
      end
      batches_accepted = batches_accepted + 1;
      batch_tag = batch_tag + 1;
    end
  endtask

  task automatic on_push_beat;
    begin
      if (q_hd == q_tl) begin
        $display("FAIL cycle %0d unexpected push id=%0h (empty expected)", cycle_i, beat_id);
        drop_n = drop_n + 1;
      end else if (exp_id[q_hd % QMAX] !== beat_id || exp_s[q_hd % QMAX] !== beat_s) begin
        $display("FAIL cycle %0d UNEXPLAINED_REORDER got id=%0h s=%0d exp id=%0h s=%0d",
                 cycle_i, beat_id, beat_s, exp_id[q_hd % QMAX], exp_s[q_hd % QMAX]);
        reorder_n = reorder_n + 1;
        q_hd = q_hd + 1;
      end else begin
        q_hd = q_hd + 1;
      end
    end
  endtask

  task automatic on_pop;
    int unsigned si;
    begin
      popped_n = popped_n + 1;
      for (si = 0; si < SEEN_N; si = si + 1) begin
        if (seen_v[si] && seen_id[si] === f_id) begin
          $display("FAIL cycle %0d DUPLICATE pop id=%0h", cycle_i, f_id);
          dup_n = dup_n + 1;
        end
      end
      seen_id[seen_wr % SEEN_N] = f_id;
      seen_v[seen_wr % SEEN_N]  = 1'b1;
      seen_wr = seen_wr + 1;
    end
  endtask

  task automatic check_conservation;
    begin
      queued = fcnt;
      intentionally_pruned = overflow_n;
      // still_in_pipeline = winners in hold not yet frontier-accepted
      if (flow_state == 2'd3)
        still_pipe = 8 - push_idx;
      else
        still_pipe = 0;
      cons_rhs = queued + popped_n + intentionally_pruned + still_pipe;
      if (cons_rhs !== accepted_winners) begin
        if (cons_fail_n < 12) begin
          $display("FAIL CONS cycle %0d accepted=%0d rhs=%0d (q=%0d pop=%0d ovf=%0d pipe=%0d st=%0d idx=%0d)",
                   cycle_i, accepted_winners, cons_rhs, queued, popped_n,
                   intentionally_pruned, still_pipe, flow_state, push_idx);
        end
        cons_fail_n = cons_fail_n + 1;
      end
    end
  endtask

  initial begin
    rst_n = 0;
    lane_valid = '0;
    frontier_pop = 0;
    rnd = 32'hA5A5_C3C3;
    q_hd = 0;
    q_tl = 0;
    accepted_winners = 0;
    popped_n = 0;
    overflow_n = 0;
    drop_n = 0;
    dup_n = 0;
    reorder_n = 0;
    cons_fail_n = 0;
    ready_busy_fail_n = 0;
    batches_accepted = 0;
    batch_tag = 1;
    seen_wr = 0;
    for (k = 0; k < SEEN_N; k = k + 1)
      seen_v[k] = 0;
    for (li = 0; li < NG_LANES; li = li + 1) begin
      cand_id[li] = '0;
      terms[li] = '0;
    end

    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    for (cycle_i = 0; cycle_i < CYCLES; cycle_i = cycle_i + 1) begin
      @(negedge clk);
      rnd = next_rnd(rnd);

      do_batch = rnd[0];
      present  = batch_ready && do_batch;
      if (present) begin
        lane_valid = {NG_LANES{1'b1}};
        for (li = 0; li < NG_LANES; li = li + 1) begin
          cand_id[li] = node_id_t'((batch_tag << 8) + li + 32'h1000_0000);
          terms[li].entity_match          = term_t'(rnd[7:0] ^ li[7:0]);
          terms[li].intent_match          = term_t'(rnd[15:8]);
          terms[li].relation_match        = term_t'(8'(li));
          terms[li].context_match         = term_t'(rnd[19:16]);
          terms[li].path_confidence       = term_t'(rnd[23:20]);
          terms[li].learned_prior         = term_t'(rnd[27:24]);
          terms[li].contradiction_penalty = term_t'(rnd[31:28]);
          rnd = next_rnd(rnd);
        end
      end else if (!batch_ready && rnd[1]) begin
        // Overwrite-attack while busy — poison IDs must never be pushed
        lane_valid = {NG_LANES{1'b1}};
        for (li = 0; li < NG_LANES; li = li + 1) begin
          cand_id[li] = node_id_t'(32'hDEAD_0000 + li);
          terms[li]   = '0;
          terms[li].entity_match = term_t'(8'h7F);
        end
      end else begin
        lane_valid = '0;
      end

      rnd = next_rnd(rnd);
      do_pop = rnd[2] || push_stall || (fcnt > 8'd48);
      frontier_pop = do_pop;

      // Registered topk_valid is stable across the cycle; sample before consuming edge
      saw_topk = topk_valid;

      @(posedge clk);
      #1;

      if (saw_topk)
        enqueue_expected();

      if (beat_v) begin
        if ((beat_id & 32'hFFFF_0000) === 32'hDEAD_0000) begin
          $display("FAIL cycle %0d poison id pushed id=%0h", cycle_i, beat_id);
          drop_n = drop_n + 1;
        end
        on_push_beat();
      end

      if (ovf)
        overflow_n = overflow_n + 1;

      if (pop_v)
        on_pop();

      if (batch_ready != (!flow_busy)) begin
        if (ready_busy_fail_n < 8)
          $display("FAIL cycle %0d ready/busy mismatch ready=%0b busy=%0b",
                   cycle_i, batch_ready, flow_busy);
        ready_busy_fail_n = ready_busy_fail_n + 1;
      end

      check_conservation();
    end

    begin : drain
      int unsigned d;
      for (d = 0; d < 30000; d = d + 1) begin
        @(negedge clk);
        lane_valid = '0;
        frontier_pop = flow_busy || (fcnt != 0) || (q_tl != q_hd);
        saw_topk = topk_valid;
        @(posedge clk);
        #1;
        if (saw_topk) enqueue_expected();
        if (beat_v) on_push_beat();
        if (ovf) overflow_n = overflow_n + 1;
        if (pop_v) on_pop();
        check_conservation();
        if (!flow_busy && (fcnt == 0) && (q_tl == q_hd))
          disable drain;
      end
    end

    $display("NG02R_FLOW cycles=%0d batches=%0d accepted=%0d popped=%0d ovf=%0d",
             CYCLES, batches_accepted, accepted_winners, popped_n, overflow_n);
    $display("DROP=%0d DUPLICATE=%0d UNEXPLAINED_REORDER=%0d CONS_FAIL=%0d READY_BUSY_FAIL=%0d",
             drop_n, dup_n, reorder_n, cons_fail_n, ready_busy_fail_n);

    if (drop_n == 0 && dup_n == 0 && reorder_n == 0 && cons_fail_n == 0 &&
        ready_busy_fail_n == 0 && batches_accepted > 0 && accepted_winners > 0 &&
        accepted_winners == popped_n && overflow_n == 0) begin
      $display("A7NG02R_FLOW_XSIM_PASS");
    end else begin
      $display("A7NG02R_FLOW_XSIM_FAIL");
    end
    $finish;
  end
endmodule
