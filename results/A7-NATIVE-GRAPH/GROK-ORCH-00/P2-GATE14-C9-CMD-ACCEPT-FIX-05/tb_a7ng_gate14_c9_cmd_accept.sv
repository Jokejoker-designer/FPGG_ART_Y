// tb_a7ng_gate14_c9_cmd_accept.sv — P2-GATE14-C9-CMD-ACCEPT-FIX-05
// Stimulus samples cmd_valid&&cmd_ready locally. Monitor counters = evidence only.
// TRESET/KILL complete on persist_done/GEN, not persist_busy.
// PROGRAM=NO. Graph-only. Stop at first divergence.
`timescale 1ns / 1ps

module tb_a7ng_gate14_c9_cmd_accept;
  import a7ng_pkg::*;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  localparam logic [7:0] T_HOLD_A=8'hA2, T_UNREL=8'hA3, T_CONTRA=8'hA4, T_HOLD_B=8'hB2;
  localparam logic [63:0] PACK_A = 64'h8382238122802120;
  localparam logic [63:0] PACK_U = 64'h8786858483828180;
  localparam logic [63:0] PACK_C = 64'h2322832182208180;
  localparam logic [63:0] PACK_B = 64'h8382438142804140;
  localparam logic [63:0] PACK_FORGET = 64'h2322832182208180;
  localparam int TO = 200000;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd, mode;
  logic [7:0] tok, qid, r1r;
  logic signed [3:0] rew;
  logic [63:0] anch, topk, c9g, c8d, adig, bdig;
  logic [127:0] scpack;
  logic lmst, lmdn, lmused, qv, qr, sv, pend, pbusy, pdone, c5, c7v, afor, bvis;
  logic [9:0] lmout;
  logic [15:0] ncue, nwin, naddr, ntok, nw, nmode, txn, c7seq, c7cnt;
  logic [2:0] ack;
  node_id_t tid [8];
  score_t tsc [8];
  logic [31:0] c8g, c7a, r1s, r1o;

  a7ng_gate14_c9_graph_only_xsim dut (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(cv), .cmd_ready_o(cr), .cmd_i(cmd), .tok_i(tok), .reward_i(rew),
    .c1_mode_o(mode), .c2_anch_o(anch),
    .c9_topk_o(topk), .c9_pack_graph_o(c9g), .c9_score_o(scpack),
    .c9_r1s_o(r1s), .c9_r1r_o(r1r), .c9_r1o_o(r1o),
    .c10_lmst_o(lmst), .c10_lmdn_o(lmdn), .c10_out_o(lmout),
    .n_host_cue_o(ncue), .n_host_win_o(nwin), .n_host_addr_o(naddr),
    .n_host_tok_o(ntok), .n_host_w_o(nw), .n_host_mode_o(nmode),
    .last_ack_o(ack), .exam_lm_used_o(lmused),
    .topk_id_o(tid), .topk_sc_o(tsc),
    .p_txn_o(txn), .c5_cons_o(c5), .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .c7_addr_o(c7a), .c7_v_o(c7v),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
    .query_valid_o(qv), .query_ready_o(qr), .query_id_o(qid),
    .snap_valid_o(sv), .pending_o(pend),
    .c11_adig_o(adig), .c11_bdig_o(bdig), .c11_a_for_o(afor), .c11_b_vis_o(bvis)
  );

  initial clk = 0;
  always #40 clk = ~clk;

  integer fails, i, g, k, wd;
  integer cmd_accept_n, graph_accept_n, reward_commit_n, snap_n, cmd_dup_n;
  integer a_graph_n, b_graph_n, a_rew_n, b_rew_n;
  integer a_cmd_fire_n, b_cmd_fire_n, gen_before, gen_after;
  logic [19:0] a_tok_mask, b_tok_mask;
  integer phase;
  integer broken_hs;
  string first_div;
  logic [7:0] last_graph_qid, expected_qid;
  logic [15:0] txn_at_query;
  logic cv_d, cr_d, qv_d, qr_d, sv_d, c7v_d, pdone_d;

  function automatic logic [7:0] map_qid(input logic [7:0] t);
    if (t == T_HOLD_A) return 8'h02;
    if (t == T_UNREL)  return 8'h03;
    if (t == T_CONTRA) return 8'h04;
    if (t == T_HOLD_B) return 8'h06;
    return t;
  endfunction

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;

  // Evidence-only. NBA so stimulus does not race on these counters.
  always @(posedge clk) begin
    cv_d <= cv; cr_d <= cr; qv_d <= qv; qr_d <= qr;
    sv_d <= sv; c7v_d <= c7v; pdone_d <= pdone;
    if (rst_n && cv && !cr)
      $display("CMD_STALL cyc=%0d cmd=%0d tok=%h ready=0", wd, cmd, tok);
    if (rst_n && cv && cr) begin
      cmd_accept_n <= cmd_accept_n + 1;
      $display("CMD_ACCEPT seq=%0d cmd=%0d tok=%h reward=%0d",
               cmd_accept_n + 1, cmd, tok, rew);
      if (cv_d && cr_d) begin
        cmd_dup_n <= cmd_dup_n + 1;
        $display("CMD_DUPLICATE cyc=%0d cmd=%0d tok=%h", wd, cmd, tok);
      end
      if (cmd == C_FIRE && phase == 1) a_cmd_fire_n <= a_cmd_fire_n + 1;
      if (cmd == C_FIRE && phase == 3) b_cmd_fire_n <= b_cmd_fire_n + 1;
    end
    if (rst_n && qv && qr) begin
      graph_accept_n <= graph_accept_n + 1;
      last_graph_qid <= qid;
      $display("GRAPH_ACCEPT seq=%0d qid=%h", graph_accept_n + 1, qid);
      if (qid >= 8'h10 && qid <= 8'h23 && !a_tok_mask[qid - 8'h10]) begin
        a_tok_mask[qid - 8'h10] <= 1'b1;
        a_graph_n <= a_graph_n + 1;
      end
      if (qid >= 8'h30 && qid <= 8'h43 && !b_tok_mask[qid - 8'h30]) begin
        b_tok_mask[qid - 8'h30] <= 1'b1;
        b_graph_n <= b_graph_n + 1;
      end
    end
    if (rst_n && sv && !sv_d) begin
      snap_n <= snap_n + 1;
      $display("SNAP_RISE n=%0d qid=%h", snap_n + 1, last_graph_qid);
    end
    if (rst_n && c7v && !c7v_d) begin
      reward_commit_n <= reward_commit_n + 1;
      $display("REWARD_COMMIT ack_count=%0d commit_seq=%0d txn=%0d qid=%h",
               c7cnt, c7seq, txn, last_graph_qid);
      if (phase == 1) a_rew_n <= a_rew_n + 1;
      if (phase == 3) b_rew_n <= b_rew_n + 1;
    end
  end

  task automatic dump_counts;
    begin
      $display("CMD_DUPLICATE_COUNT=%0d", cmd_dup_n);
      $display("A_CMD_FIRE_ACCEPT=%0d A_GRAPH_ACCEPT_COUNT=%0d A_REWARD_COMMIT_COUNT=%0d A_ACK_COUNT=%0d A_COMMIT_SEQ=%0d",
               a_cmd_fire_n, a_graph_n, a_rew_n, c7cnt, c7seq);
      $display("B_CMD_FIRE_ACCEPT=%0d B_GRAPH_ACCEPT_COUNT=%0d B_REWARD_COMMIT_COUNT=%0d B_ACK_COUNT=%0d B_COMMIT_SEQ=%0d",
               b_cmd_fire_n, b_graph_n, b_rew_n, c7cnt, c7seq);
      $display("GEN_BEFORE_RESET=%0d GEN_AFTER_RESET=%0d", gen_before, gen_after);
      $display("C9_PACK_GLUE=%h C9_PACK_GRAPH=%h", topk, c9g);
    end
  endtask

  task automatic stop_div(input string tag);
    begin
      first_div = tag;
      fails = fails + 1;
      $display("FIRST_DIVERGENCE=%s", tag);
      dump_counts();
      $display("GATE14_C9_CMD_ACCEPT_GRAPH_FAIL fails=%0d", fails);
      $finish;
    end
  endtask

  task automatic print_missing(input string tag, input logic [19:0] mask, input logic [7:0] base);
    begin
      for (i = 0; i < 20; i = i + 1)
        if (!mask[i])
          $display("MISSING_%s qid=%h", tag, base + i[7:0]);
    end
  endtask

  task automatic do_cmd_broken(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    begin
      g = 0;
      while (!cr && g < TO) begin @(posedge clk); g++; end
      if (!cr) stop_div("CMD_READY_TIMEOUT");
      @(negedge clk); cmd = c; tok = t; rew = r; cv = 1'b1;
      @(posedge clk); @(negedge clk); cv = 1'b0;
      g = 0;
      while (!cr && g < TO) begin @(posedge clk); g++; end
    end
  endtask

  // Local handshake. Do not wait on cmd_accept_n to drop valid.
  task automatic do_cmd_fix(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    integer cmd0, graph0, rew0, snap0, ack0, seq0, gen0, accepted, saw_done, saw_busy, dcmd, dgraph, dsnap, drew;
    begin
      cmd0 = cmd_accept_n; graph0 = graph_accept_n; rew0 = reward_commit_n;
      snap0 = snap_n; ack0 = c7cnt; seq0 = c7seq; gen0 = c8g;

      g = 0;
      while (!(cr && !cv) && g < TO) begin @(posedge clk); g++; end
      if (!(cr && !cv)) stop_div("CMD_READY_BEFORE_SEND");

      @(negedge clk);
      cmd = c; tok = t; rew = r; cv = 1'b1;
      accepted = 0; g = 0;
      while (!accepted && g < TO) begin
        @(posedge clk); g++;
        if (cv && cr) accepted = 1;
      end
      if (!accepted)
        stop_div($sformatf("CMD_ACCEPT_MISS cmd=%0d tok=%h", c, t));
      @(negedge clk); cv = 1'b0;
      @(posedge clk);
      dcmd = cmd_accept_n - cmd0;
      if (dcmd != 1)
        stop_div($sformatf("CMD_ACCEPT_DELTA=%0d cmd=%0d (want 1)", dcmd, c));

      case (c)
        C_FIRE: begin
          g = 0;
          while (!(qv && qr) && g < TO) begin @(posedge clk); g++; end
          if (!(qv && qr)) stop_div("GRAPH_ACCEPT_MISS");
          if (qid !== expected_qid)
            stop_div($sformatf("QID_MISMATCH got=%h want=%h", qid, expected_qid));
          txn_at_query = txn;
          g = 0;
          while (!sv && g < TO) begin @(posedge clk); g++; end
          if (!sv) stop_div("SNAP_MISS");
          g = 0;
          while (!cr && g < TO) begin @(posedge clk); g++; end
          if (!cr) stop_div("C_FIRE not idle after snap");
          @(posedge clk);
          dgraph = graph_accept_n - graph0;
          dsnap  = snap_n - snap0;
          if (dgraph != 1) stop_div($sformatf("GRAPH_ACCEPT_DELTA=%0d", dgraph));
          if (dsnap != 1)  stop_div($sformatf("SNAP_DELTA=%0d", dsnap));
        end
        C_REW: begin
          g = 0;
          while (!c7v && g < TO) begin @(posedge clk); g++; end
          if (!c7v) stop_div("REWARD_COMMIT_MISS");
          @(posedge clk);
          drew = reward_commit_n - rew0;
          if (drew != 1) stop_div($sformatf("REWARD_COMMIT_DELTA=%0d", drew));
          if (c7cnt != ack0 + 16'd1)
            stop_div($sformatf("ACK_COUNT got=%0d want=%0d", c7cnt, ack0 + 1));
          if (c7seq != seq0 + 16'd1)
            stop_div($sformatf("COMMIT_SEQ got=%0d want=%0d", c7seq, seq0 + 1));
          g = 0;
          while (pbusy && g < TO) begin @(posedge clk); g++; end
        end
        C_FLUSH, C_RELOAD: begin
          saw_done = 0; saw_busy = 0; g = 0;
          while (g < TO) begin
            @(posedge clk); g++;
            if (pbusy) saw_busy = 1;
            if (pdone) saw_done = 1;
            if (saw_done && !pbusy) break;
          end
          if (!saw_done) stop_div($sformatf("PERSIST_DONE_MISS cmd=%0d", c));
          if (pbusy) stop_div($sformatf("PERSIST_BUSY_STUCK cmd=%0d", c));
        end
        C_TRESET: begin
          saw_done = 0; g = 0;
          while (g < TO) begin
            @(posedge clk); g++;
            if (pdone) saw_done = 1;
            if (c8g != gen0) break;
          end
          if (c8g != gen0 + 32'd1)
            stop_div($sformatf("TRESET_GEN got=%0d want=%0d", c8g, gen0 + 1));
          if (!saw_done)
            $display("WARN TRESET GEN ok without persist_done pulse");
        end
        C_KILL: begin
          saw_done = 0; g = 0;
          while (!pdone && g < TO) begin @(posedge clk); g++; end
          if (!pdone) stop_div("KILL_DONE_MISS");
        end
        default: ;
      endcase
    end
  endtask

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    begin
      if (broken_hs) do_cmd_broken(c, t, r);
      else           do_cmd_fix(c, t, r);
    end
  endtask

  task automatic fire_tok(input logic [7:0] t);
    begin
      expected_qid = map_qid(t);
      do_cmd(C_TOK, t, 0);
      do_cmd(C_FIRE, 0, 0);
    end
  endtask

  task automatic exam_pack(input string tag, input logic [7:0] t, input logic [63:0] exp_pack);
    begin
      fire_tok(t);
      $display("EXAM %s MODE=%h C9_GLUE=%h C9_GRAPH=%h r1=%h", tag, mode, topk, c9g, c9g[7:0]);
      if (mode != 4'h8) stop_div({tag, "_MODE"});
      if (c9g !== exp_pack) begin
        $display("FAIL %s C9 graph pack %h want %h", tag, c9g, exp_pack);
        stop_div({tag, "_C9"});
      end
      if (topk !== exp_pack) begin
        $display("FAIL %s C9 glue pack %h want %h", tag, topk, exp_pack);
        stop_div({tag, "_C9_GLUE"});
      end
      $display("PACK_OK %s %h", tag, c9g);
    end
  endtask

  initial begin
    wait (wd > 400000000);
    stop_div("WATCHDOG");
  end

  initial begin
    fails = 0; cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    cmd_accept_n = 0; graph_accept_n = 0; reward_commit_n = 0; snap_n = 0; cmd_dup_n = 0;
    a_graph_n = 0; b_graph_n = 0; a_rew_n = 0; b_rew_n = 0;
    a_cmd_fire_n = 0; b_cmd_fire_n = 0; gen_before = 0; gen_after = 0;
    a_tok_mask = 20'd0; b_tok_mask = 20'd0;
    phase = 0; first_div = "NONE"; last_graph_qid = 8'd0; expected_qid = 8'd0;
    txn_at_query = 16'd0; wd = 0;
    broken_hs = $test$plusargs("BROKEN_HS");
    $display("HS_MODE broken=%0d", broken_hs);

    repeat (8) @(posedge clk);
    rst_n = 1;
    i = 0;
    while (!cr && i < 8000) begin @(posedge clk); i++; end
    if (!cr) stop_div("BOOT_CMD_READY");
    if (mode != 4'h5) stop_div("BOOT_MODE");
    do_cmd(C_TRAIN, 0, 0);

    phase = 1;
    for (k = 0; k < 20; k = k + 1) begin
      $display("LESSON_A k=%0d tok=%h (intent only)", k, 8'h10 + k[7:0]);
      fire_tok(8'h10 + k[7:0]);
      do_cmd(C_REW, 0, 4'sd3);
    end
    @(posedge clk);
    $display("CURRICULUM_A_TOTAL CMD_FIRE_ACCEPT=%0d GRAPH_ACCEPT_DISTINCT=%0d REWARD_COMMIT=%0d ack=%0d seq=%0d",
             a_cmd_fire_n, a_graph_n, a_rew_n, c7cnt, c7seq);
    print_missing("A", a_tok_mask, 8'h10);
    if (cmd_dup_n != 0) stop_div("CMD_DUPLICATE");
    if (a_cmd_fire_n != 20) stop_div("A_CMD_FIRE_ACCEPT");
    if (a_graph_n != 20) stop_div("A_GRAPH_ACCEPT_COUNT");
    if (a_rew_n != 20)   stop_div("A_REWARD_COMMIT_COUNT");
    if (c7cnt != 16'd20) stop_div("A_ACK_COUNT");
    if (c7seq != 16'd20) stop_div("A_COMMIT_SEQ");

    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    if (mode != 4'h8) stop_div("FREEZE_MODE");

    phase = 2;
    exam_pack("HOLD_A", T_HOLD_A, PACK_A);
    exam_pack("UNREL",  T_UNREL,  PACK_U);
    exam_pack("CONTRA", T_CONTRA, PACK_C);

    gen_before = c8g;
    do_cmd(C_TRESET, 0, 0);
    gen_after = c8g;
    $display("GEN_BEFORE_RESET=%0d GEN_AFTER_RESET=%0d", gen_before, gen_after);
    if (gen_after != gen_before + 1) stop_div("TRESET_GEN_STEP");
    exam_pack("FORGET_HOLD_A", T_HOLD_A, PACK_FORGET);
    if (c9g === PACK_A) stop_div("FORGET_STILL_HOLD_A");
    if (c9g[7:0] !== 8'h80) stop_div("FORGET_R1");

    do_cmd(C_TRAIN, 0, 0);
    phase = 3;
    for (k = 0; k < 20; k = k + 1) begin
      $display("LESSON_B k=%0d tok=%h (intent only)", k, 8'h30 + k[7:0]);
      fire_tok(8'h30 + k[7:0]);
      do_cmd(C_REW, 0, 4'sd3);
    end
    @(posedge clk);
    $display("CURRICULUM_B_TOTAL CMD_FIRE_ACCEPT=%0d GRAPH_ACCEPT_DISTINCT=%0d REWARD_COMMIT=%0d ack=%0d seq=%0d",
             b_cmd_fire_n, b_graph_n, b_rew_n, c7cnt, c7seq);
    print_missing("B", b_tok_mask, 8'h30);
    if (cmd_dup_n != 0) stop_div("CMD_DUPLICATE");
    if (b_cmd_fire_n != 20) stop_div("B_CMD_FIRE_ACCEPT");
    if (b_graph_n != 20) stop_div("B_GRAPH_ACCEPT_COUNT");
    if (b_rew_n != 20)   stop_div("B_REWARD_COMMIT_COUNT");
    if (c7cnt != 16'd40) stop_div("B_ACK_COUNT");
    if (c7seq != 16'd40) stop_div("B_COMMIT_SEQ");

    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    phase = 4;
    exam_pack("HOLD_B", T_HOLD_B, PACK_B);

    if (ncue != 0 || nwin != 0 || naddr != 0 || ntok != 0 || nw != 0 || nmode != 0)
      stop_div("HOST_INGRESS");

    dump_counts();
    $display("C9_PACK_A=%h C9_PACK_UNREL=%h C9_PACK_CONTRA=%h C9_PACK_B=%h",
             PACK_A, PACK_U, PACK_C, PACK_B);
    $display("FIRST_DIVERGENCE=NONE");
    $display("GATE14_C9_CMD_ACCEPT_GRAPH_PASS fails=0 A=20 B=20 dup=0");
    $finish;
  end
endmodule
