// tb_graph_payload_noreset.sv — GRAPH-PAYLOAD-NORESET-00
// Reset/X/stale regression. PROGRAM=NO. XSim only.
`timescale 1ns / 1ps

module tb_graph_payload_noreset;
  import a7ng_pkg::*;

  localparam int TIMEOUT = 4000;

  logic clk, rst_n;
  integer stale_output_count, tg_stale, hp_stale, ng_stale;
  integer fails, mismatches, cases_pass;
  integer k, t, w, n, waits;
  string tag;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic pulse_rst;
    begin
      rst_n = 1'b0;
      tick;
      tick;
      rst_n = 1'b1;
      tick;
    end
  endtask

  // -------------------- TermGen --------------------
  logic tg_valid_i, tg_ready_o, tg_valid_o, tg_ready_i;
  node_id_t tg_id_i, tg_id_o;
  termgen_cues_t tg_cues_i;
  score_terms_t  tg_terms_o;
  logic tg_armed;

  a7ng_termgen_lane_fold6 u_tg (
    .clk(clk), .rst_n(rst_n),
    .valid_i(tg_valid_i), .ready_o(tg_ready_o),
    .cand_id_i(tg_id_i), .cues_i(tg_cues_i),
    .valid_o(tg_valid_o), .ready_i(tg_ready_i),
    .cand_id_o(tg_id_o), .terms_o(tg_terms_o)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      tg_armed <= 1'b0;
      if (tg_valid_o) tg_stale <= tg_stale + 1;
    end else begin
      if (tg_valid_i && tg_ready_o)
        tg_armed <= 1'b1;
      if (tg_valid_o && tg_ready_i)
        tg_armed <= 1'b0;
      if (tg_valid_o && !tg_armed)
        tg_stale <= tg_stale + 1;
      else if (tg_valid_o && ($isunknown(tg_id_o) || $isunknown(tg_terms_o)))
        tg_stale <= tg_stale + 1;
    end
  end

  task automatic tg_drive_vec(input integer seedv, output score_terms_t gold, output node_id_t exp_id);
    integer s;
    begin
      s = seedv;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_id_i = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.query_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.query_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.node_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.node_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.relation_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.relation_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.intent_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.intent_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.context_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.context_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.path_cue[31:0] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.path_cue[63:32] = s;
      s = s * 32'h19660D + 32'h3C6EF35F; tg_cues_i.learned_prior = term_t'(s[7:0]);
      gold = ng_termgen_compose(tg_cues_i);
      exp_id = tg_id_i;
    end
  endtask

  task automatic tg_run_one(input integer seedv);
    score_terms_t gold;
    node_id_t exp_id;
    begin
      tg_ready_i = 1'b1;
      waits = 0;
      while (!tg_ready_o && waits < 32) begin tick; waits = waits + 1; end
      if (!tg_ready_o) begin
        $display("FAIL %s tg not ready", tag);
        fails = fails + 1;
        return;
      end
      tg_drive_vec(seedv, gold, exp_id);
      tg_valid_i = 1'b1;
      tick;
      tg_valid_i = 1'b0;
      waits = 0;
      while (!tg_valid_o && waits < 16) begin tick; waits = waits + 1; end
      if (!tg_valid_o) begin
        $display("FAIL %s tg timeout", tag);
        fails = fails + 1;
      end else if (tg_id_o !== exp_id) begin
        $display("FAIL %s tg id got=%h exp=%h", tag, tg_id_o, exp_id);
        fails = fails + 1; mismatches = mismatches + 1;
      end else if (tg_terms_o !== gold) begin
        $display("FAIL %s tg terms mismatch", tag);
        fails = fails + 1; mismatches = mismatches + 1;
      end
      tick;
    end
  endtask

  // -------------------- Heap --------------------
  logic hp_clear, hp_in_valid, hp_in_ready, hp_in_v, hp_in_last;
  score_t hp_in_s, hp_out_s;
  node_id_t hp_in_id, hp_out_id;
  logic [3:0] hp_in_lane;
  logic hp_out_valid, hp_out_ready, hp_busy, hp_clr_ign;
  logic [2:0] hp_out_idx;
  logic [31:0] hp_acc, hp_ret, hp_drop;
  logic hp_armed, hp_mon_rst;
  integer hp_hs_in, hp_hs_out;
  score_t hp_got_s [8];
  node_id_t hp_got_id [8];

  a7ng_topk_stream_minheap #(.K(8)) u_hp (
    .clk(clk), .rst_n(rst_n),
    .clear_i(hp_clear),
    .in_valid_i(hp_in_valid), .in_ready_o(hp_in_ready),
    .in_v_i(hp_in_v), .in_s_i(hp_in_s), .in_id_i(hp_in_id), .in_lane_i(hp_in_lane),
    .in_last_i(hp_in_last),
    .out_valid_o(hp_out_valid), .out_ready_i(hp_out_ready),
    .out_s_o(hp_out_s), .out_id_o(hp_out_id), .out_idx_o(hp_out_idx),
    .busy_o(hp_busy), .clear_ignored_o(hp_clr_ign),
    .accepted_count_o(hp_acc), .retired_count_o(hp_ret), .drop_count_o(hp_drop)
  );

  always @(posedge clk) begin
    if (!rst_n || hp_mon_rst) begin
      hp_armed  <= 1'b0;
      hp_hs_in  <= 0;
      hp_hs_out <= 0;
      if (!rst_n && hp_out_valid) hp_stale <= hp_stale + 1;
    end else begin
      if (hp_in_valid && hp_in_ready)
        hp_hs_in <= hp_hs_in + 1;
      if (hp_out_valid && hp_out_ready && (hp_hs_out < 8)) begin
        hp_got_s[hp_hs_out]  <= hp_out_s;
        hp_got_id[hp_hs_out] <= hp_out_id;
        hp_hs_out            <= hp_hs_out + 1;
      end
      if (hp_in_valid && hp_in_ready)
        hp_armed <= 1'b1;
      if (hp_out_valid && hp_out_ready && (hp_out_idx == 3'd7))
        hp_armed <= 1'b0;
      if (hp_out_valid && !hp_armed)
        hp_stale <= hp_stale + 1;
      else if (hp_out_valid && ($isunknown(hp_out_s) || $isunknown(hp_out_id)))
        hp_stale <= hp_stale + 1;
    end
  end

  logic               ref_valid_i, ref_valid_o;
  logic [15:0]        ref_mask;
  score_t             ref_s_i [16], ref_s_o [8];
  node_id_t           ref_id_i [16], ref_id_o [8];
  score_t             vec_s [16];
  node_id_t           vec_id [16];
  logic [15:0]        vec_mask;

  a7ng_topk u_ref (
    .clk(clk), .rst_n(rst_n),
    .valid_i(ref_valid_i), .valid_mask_i(ref_mask),
    .score_i(ref_s_i), .id_i(ref_id_i),
    .valid_o(ref_valid_o), .score_o(ref_s_o), .id_o(ref_id_o)
  );

  task automatic hp_idle_clear;
    begin
      hp_in_valid = 1'b0;
      hp_in_last  = 1'b0;
      hp_out_ready = 1'b1;
      ref_valid_i = 1'b0;
      tick;
      while (hp_busy) tick;
      hp_clear = 1'b1;
      tick;
      hp_clear = 1'b0;
      tick;
    end
  endtask

  task automatic hp_stream16;
    begin
      hp_in_valid  = 1'b0;
      hp_out_ready = 1'b1;
      hp_mon_rst   = 1'b1;
      tick;
      hp_mon_rst   = 1'b0;
      for (w = 0; w < TIMEOUT; w = w + 1) begin
        if ((hp_hs_in < 16)) begin
          hp_in_valid = 1'b1;
          hp_in_v     = vec_mask[hp_hs_in];
          hp_in_s     = vec_s[hp_hs_in];
          hp_in_id    = vec_id[hp_hs_in];
          hp_in_lane  = 4'(hp_hs_in);
          hp_in_last  = (hp_hs_in == 15);
        end else begin
          hp_in_valid = 1'b0;
          hp_in_last  = 1'b0;
        end
        tick;
        if ((hp_hs_in == 16) && (hp_hs_out == 8) && !hp_busy && !hp_out_valid)
          w = TIMEOUT;
      end
      hp_in_valid = 1'b0;
      hp_in_last  = 1'b0;
      if (hp_hs_out != 8) begin
        $display("FAIL %s heap drain hs_out=%0d hs_in=%0d busy=%0d", tag, hp_hs_out, hp_hs_in, hp_busy);
        fails = fails + 1;
      end
      if (hp_acc !== hp_ret) begin
        $display("FAIL %s accepted=%0d retired=%0d", tag, hp_acc, hp_ret);
        fails = fails + 1;
      end
      if (hp_drop !== 32'd0) begin
        $display("FAIL %s drop=%0d", tag, hp_drop);
        fails = fails + 1;
      end
    end
  endtask

  task automatic hp_capture_ref;
    begin
      ref_mask = vec_mask;
      for (k = 0; k < 16; k = k + 1) begin
        ref_s_i[k]  = vec_s[k];
        ref_id_i[k] = vec_id[k];
      end
      tick;
      ref_valid_i = 1'b1;
      tick;
      if (!ref_valid_o) begin
        $display("FAIL %s ref timeout", tag);
        fails = fails + 1;
      end
      ref_valid_i = 1'b0;
    end
  endtask

  task automatic hp_compare_ref;
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if (hp_got_s[k] !== ref_s_o[k] || hp_got_id[k] !== ref_id_o[k]) begin
          $display("MISMATCH %s slot%0d ref s=%0d id=%h dut s=%0d id=%h",
                   tag, k, ref_s_o[k], ref_id_o[k], hp_got_s[k], hp_got_id[k]);
          mismatches = mismatches + 1;
          fails = fails + 1;
        end
      end
    end
  endtask

  task automatic hp_fill_desc(input integer base);
    begin
      vec_mask = 16'hFFFF;
      for (k = 0; k < 16; k = k + 1) begin
        vec_s[k]  = score_t'(16'sd400 - 16'(k) - 16'(base));
        vec_id[k] = node_id_t'(32'hA000 + base*16 + k);
      end
    end
  endtask

  // -------------------- NG02 --------------------
  logic [NG_LANES-1:0] ng_lane_valid;
  node_id_t ng_cand [NG_LANES];
  score_terms_t ng_terms [NG_LANES];
  logic ng_batch_ready, ng_topk_valid, ng_pop;
  score_t ng_topk_s [8];
  node_id_t ng_topk_id [8];
  logic ng_pop_valid, ng_ovf, ng_busy, ng_push_fire, ng_push_stall, ng_beat_v;
  score_t ng_front_s, ng_push_s, ng_beat_s;
  node_id_t ng_front_id, ng_push_id, ng_beat_id;
  logic [7:0] ng_count;
  logic [2:0] ng_push_idx, ng_flow;
  logic ng_armed;
  score_t ng_got_s [8];
  node_id_t ng_got_id [8];
  score_t ng_gold_s [8];
  node_id_t ng_gold_id [8];

  a7ng_ng02_core #(.PHYS(4)) u_ng (
    .clk(clk), .rst_n(rst_n),
    .lane_valid_i(ng_lane_valid),
    .cand_id_i(ng_cand),
    .terms_i(ng_terms),
    .frontier_pop_i(ng_pop),
    .batch_ready_o(ng_batch_ready),
    .topk_valid_o(ng_topk_valid),
    .topk_score_o(ng_topk_s),
    .topk_id_o(ng_topk_id),
    .frontier_pop_valid_o(ng_pop_valid),
    .frontier_score_o(ng_front_s),
    .frontier_id_o(ng_front_id),
    .frontier_overflow_o(ng_ovf),
    .frontier_count_o(ng_count),
    .flow_busy_o(ng_busy),
    .push_idx_o(ng_push_idx),
    .push_fire_o(ng_push_fire),
    .push_stall_o(ng_push_stall),
    .push_beat_valid_o(ng_beat_v),
    .push_beat_score_o(ng_beat_s),
    .push_beat_id_o(ng_beat_id),
    .flow_state_o(ng_flow)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      ng_armed <= 1'b0;
      if (ng_topk_valid) ng_stale <= ng_stale + 1;
      if (ng_beat_v)     ng_stale <= ng_stale + 1;
    end else begin
      if (ng_batch_ready && (&ng_lane_valid))
        ng_armed <= 1'b1;
      if (ng_topk_valid)
        ng_armed <= 1'b0;
      if (ng_topk_valid && !ng_armed)
        ng_stale <= ng_stale + 1;
      else if (ng_topk_valid && ($isunknown(ng_topk_s[0]) || $isunknown(ng_topk_id[0])))
        ng_stale <= ng_stale + 1;
      else if (ng_beat_v && ($isunknown(ng_beat_s) || $isunknown(ng_beat_id)))
        ng_stale <= ng_stale + 1;
    end
  end

  task automatic ng_load_vec(input integer base);
    begin
      for (k = 0; k < NG_LANES; k = k + 1) begin
        ng_cand[k] = node_id_t'(32'h100 + base*16 + k);
        ng_terms[k] = '0;
        ng_terms[k].entity_match  = term_t'(8'd40 - k);
        ng_terms[k].intent_match  = term_t'(8'd3);
        ng_terms[k].relation_match = term_t'(8'd2);
        ng_terms[k].context_match = term_t'(8'd1);
        ng_terms[k].path_confidence = term_t'(8'd4);
        ng_terms[k].learned_prior = term_t'(8'd5);
        ng_terms[k].contradiction_penalty = term_t'(8'd0);
      end
    end
  endtask

  task automatic ng_run_query(input integer base, output score_t os [8], output node_id_t oid [8]);
    begin
      ng_pop = 1'b0;
      ng_lane_valid = '0;
      waits = 0;
      while (!ng_batch_ready && waits < TIMEOUT) begin tick; waits = waits + 1; end
      if (!ng_batch_ready) begin
        $display("FAIL %s ng not ready", tag);
        fails = fails + 1;
        return;
      end
      ng_load_vec(base);
      ng_lane_valid = {NG_LANES{1'b1}};
      tick;
      ng_lane_valid = '0;
      waits = 0;
      while (!ng_topk_valid && waits < TIMEOUT) begin tick; waits = waits + 1; end
      if (!ng_topk_valid) begin
        $display("FAIL %s ng topk timeout state=%0d", tag, ng_flow);
        fails = fails + 1;
        return;
      end
      for (k = 0; k < 8; k = k + 1) begin
        os[k]  = ng_topk_s[k];
        oid[k] = ng_topk_id[k];
      end
      waits = 0;
      while (ng_busy && waits < TIMEOUT) begin tick; waits = waits + 1; end
    end
  endtask

  // -------------------- cases --------------------
  integer st_now;
  score_terms_t tg_gold;
  node_id_t tg_exp;

  initial begin
    stale_output_count = 0;
    tg_stale = 0;
    hp_stale = 0;
    ng_stale = 0;
    hp_mon_rst = 1'b0;
    fails = 0;
    mismatches = 0;
    cases_pass = 0;
    rst_n = 1'b0;
    tg_valid_i = 1'b0;
    tg_ready_i = 1'b1;
    tg_id_i = '0;
    tg_cues_i = '0;
    hp_clear = 1'b0;
    hp_in_valid = 1'b0;
    hp_in_v = 1'b0;
    hp_in_s = '0;
    hp_in_id = '0;
    hp_in_lane = 4'd0;
    hp_in_last = 1'b0;
    hp_out_ready = 1'b1;
    ref_valid_i = 1'b0;
    ref_mask = 16'h0;
    ng_lane_valid = '0;
    ng_pop = 1'b0;
    for (k = 0; k < NG_LANES; k = k + 1) begin
      ng_cand[k] = '0;
      ng_terms[k] = '0;
    end
    for (k = 0; k < 16; k = k + 1) begin
      ref_s_i[k] = '0;
      ref_id_i[k] = '0;
      vec_s[k] = '0;
      vec_id[k] = '0;
    end

    // 1. cold reset idle: no output valid
    tag = "cold_idle";
    repeat (4) tick;
    if (tg_valid_o || hp_out_valid || ng_topk_valid || ng_beat_v) begin
      $display("FAIL %s valid during reset", tag);
      fails = fails + 1;
    end
    rst_n = 1'b1;
    tick; tick;
    if (tg_valid_o || hp_out_valid || ng_topk_valid || ng_beat_v) begin
      $display("FAIL %s valid after cold idle", tag);
      fails = fails + 1;
    end else
      cases_pass = cases_pass + 1;
    $display("CASE1 %s pass_so_far=%0d stale=%0d", tag, cases_pass, stale_output_count);

    // 5 first (and X-init 6): first post-reset query exact while payload may be X
    tag = "first_post_reset_x";
    tg_run_one(32'hC0DEC0DE);
    hp_fill_desc(1);
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();
    ng_run_query(1, ng_gold_s, ng_gold_id);
    cases_pass = cases_pass + 1;
    $display("CASE5/6 %s stale=%0d fails=%0d", tag, stale_output_count, fails);

    // 2. reset during each TermGen microstate
    for (n = 1; n <= 7; n = n + 1) begin
      tag = $sformatf("tg_rst_st%0d", n);
      waits = 0;
      while (!tg_ready_o && waits < 32) begin tick; waits = waits + 1; end
      tg_drive_vec(32'h11110000 + n, tg_gold, tg_exp);
      tg_valid_i = 1'b1;
      tick;
      tg_valid_i = 1'b0;
      waits = 0;
      while ((u_tg.st != n[2:0]) && waits < 16) begin tick; waits = waits + 1; end
      st_now = u_tg.st;
      pulse_rst();
      if (tg_valid_o) begin
        $display("FAIL %s stale valid after rst st_was=%0d", tag, st_now);
        fails = fails + 1;
      end
      if (!tg_ready_o) begin
        $display("FAIL %s not idle after rst", tag);
        fails = fails + 1;
      end
      tick; tick;
      if (tg_valid_o) begin
        $display("FAIL %s valid while idle after rst", tag);
        fails = fails + 1;
      end
      tg_run_one(32'h22220000 + n);
    end
    cases_pass = cases_pass + 1;
    $display("CASE2 tg_microstate_rst stale=%0d fails=%0d", stale_output_count, fails);

    // 3. reset during heap fill / heapify / sort / drain
    tag = "hp_rst_fill";
    hp_idle_clear();
    hp_fill_desc(2);
    hp_hs_in = 0;
    hp_in_valid = 1'b1;
    hp_out_ready = 1'b0;
    for (t = 0; t < 6; t = t + 1) begin
      hp_in_v = 1'b1;
      hp_in_s = vec_s[t];
      hp_in_id = vec_id[t];
      hp_in_lane = 4'(t);
      hp_in_last = 1'b0;
      tick;
    end
    hp_in_valid = 1'b0;
    pulse_rst();
    if (hp_out_valid) begin
      $display("FAIL %s out_valid after fill rst", tag);
      fails = fails + 1;
    end

    tag = "hp_rst_heapify";
    hp_fill_desc(3);
    hp_in_valid = 1'b1;
    hp_out_ready = 1'b0;
    hp_in_v = 1'b1;
    hp_in_s = vec_s[0]; hp_in_id = vec_id[0]; hp_in_lane = 4'd0; hp_in_last = 1'b0;
    tick;
    hp_in_s = vec_s[1]; hp_in_id = vec_id[1]; hp_in_lane = 4'd1; hp_in_last = 1'b0;
    tick;
    waits = 0;
    while ((u_hp.st != 3'd1) && waits < 8) begin tick; waits = waits + 1; end
    hp_in_valid = 1'b0;
    pulse_rst();
    if (hp_out_valid) begin
      $display("FAIL %s out_valid after heapify rst", tag);
      fails = fails + 1;
    end

    tag = "hp_rst_sort";
    hp_fill_desc(4);
    n = 0;
    hp_in_valid = 1'b0;
    hp_out_ready = 1'b0;
    for (w = 0; w < TIMEOUT; w = w + 1) begin
      if ((n < 16) && hp_in_ready) begin
        hp_in_valid = 1'b1;
        hp_in_v = 1'b1;
        hp_in_s = vec_s[n];
        hp_in_id = vec_id[n];
        hp_in_lane = 4'(n);
        hp_in_last = (n == 15);
      end else begin
        hp_in_valid = 1'b0;
        hp_in_last = 1'b0;
      end
      @(posedge clk);
      if (hp_in_valid && hp_in_ready) n = n + 1;
      #1;
      if (u_hp.st == 3'd2) w = TIMEOUT;
    end
    hp_in_valid = 1'b0;
    pulse_rst();
    if (hp_out_valid) begin
      $display("FAIL %s out_valid after sort rst", tag);
      fails = fails + 1;
    end

    tag = "hp_rst_drain";
    hp_fill_desc(5);
    n = 0;
    hp_out_ready = 1'b0;
    for (w = 0; w < TIMEOUT; w = w + 1) begin
      if ((n < 16) && hp_in_ready) begin
        hp_in_valid = 1'b1;
        hp_in_v = 1'b1;
        hp_in_s = vec_s[n];
        hp_in_id = vec_id[n];
        hp_in_lane = 4'(n);
        hp_in_last = (n == 15);
      end else begin
        hp_in_valid = 1'b0;
        hp_in_last = 1'b0;
      end
      @(posedge clk);
      if (hp_in_valid && hp_in_ready) n = n + 1;
      #1;
      if (u_hp.st == 3'd3) w = TIMEOUT;
    end
    hp_in_valid = 1'b0;
    tick;
    pulse_rst();
    if (hp_out_valid) begin
      $display("FAIL %s out_valid after drain rst", tag);
      fails = fails + 1;
    end
    hp_out_ready = 1'b1;
    cases_pass = cases_pass + 1;
    $display("CASE3 heap_phase_rst stale=%0d fails=%0d", stale_output_count, fails);

    // NG02 reset during non-idle
    tag = "ng_rst_busy";
    waits = 0;
    while (!ng_batch_ready && waits < TIMEOUT) begin tick; waits = waits + 1; end
    ng_load_vec(9);
    ng_lane_valid = {NG_LANES{1'b1}};
    tick;
    ng_lane_valid = '0;
    waits = 0;
    while ((ng_flow == 3'd0) && waits < 16) begin tick; waits = waits + 1; end
    pulse_rst();
    if (ng_topk_valid || ng_beat_v) begin
      $display("FAIL %s ng valid after rst", tag);
      fails = fails + 1;
    end
    if (!ng_batch_ready) begin
      $display("FAIL %s ng not idle after rst", tag);
      fails = fails + 1;
    end

    // 4. clear between queries does not reuse stale heap payload
    tag = "clear_no_stale";
    hp_fill_desc(20);
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();
    hp_idle_clear();
    hp_fill_desc(21);
    vec_s[0] = 16'sd1; vec_id[0] = 32'hDEAD0001;
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();
    cases_pass = cases_pass + 1;
    $display("CASE4 clear_no_stale stale=%0d fails=%0d", stale_output_count, fails);

    // 8 smoke: ties / dups / partial mask / backpressure
    tag = "ties";
    vec_mask = 16'hFFFF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k] = 16'sd42;
      vec_id[k] = node_id_t'(32'h1000 + (15 - k));
    end
    hp_idle_clear();
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();

    tag = "dups";
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k] = 16'sd7;
      vec_id[k] = 32'h00C0FFEE;
    end
    hp_idle_clear();
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();

    tag = "partial_mask";
    vec_mask = 16'h00FF;
    for (k = 0; k < 16; k = k + 1) begin
      vec_s[k]  = score_t'(16'sd100 - 16'(k));
      vec_id[k] = node_id_t'(32'hB000 + k);
    end
    hp_idle_clear();
    hp_capture_ref();
    hp_stream16();
    hp_compare_ref();
    cases_pass = cases_pass + 1;
    $display("CASE8 smoke stale=%0d fails=%0d", stale_output_count, fails);

    // post-reset exact again (NG02 vs first gold after busy rst)
    tag = "ng_post_rst_exact";
    ng_run_query(1, ng_got_s, ng_got_id);
    for (k = 0; k < 8; k = k + 1) begin
      if (ng_got_s[k] !== ng_gold_s[k] || ng_got_id[k] !== ng_gold_id[k]) begin
        $display("FAIL %s slot%0d gold s=%0d id=%h got s=%0d id=%h",
                 tag, k, ng_gold_s[k], ng_gold_id[k], ng_got_s[k], ng_got_id[k]);
        fails = fails + 1; mismatches = mismatches + 1;
      end
    end

    stale_output_count = tg_stale + hp_stale + ng_stale;
    $display("MISMATCH_COUNT=%0d", mismatches);
    $display("stale_output_count=%0d tg=%0d hp=%0d ng=%0d", stale_output_count, tg_stale, hp_stale, ng_stale);
    $display("FAILS=%0d", fails);
    $display("CASES_MARKED=%0d", cases_pass);
    if ((fails == 0) && (mismatches == 0) && (stale_output_count == 0))
      $display("GRAPH_PAYLOAD_NORESET_XSIM_PASS");
    else
      $display("GRAPH_PAYLOAD_NORESET_XSIM_FAIL");
    #50 $finish;
  end
endmodule
