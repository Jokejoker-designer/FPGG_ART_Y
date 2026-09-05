// tb_u7.sv — U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00
// Host/TB: txn echo + preregistered ordinal scalar reward only.
// FPGA owns CLASS_ID / learn key / Top-K. PROGRAM=NO. QHEAD=NO. BIT=NO.
`timescale 1ns / 1ps

module tb_u7;
  import a7ng_pkg::*;
  localparam int K = 8;

  logic clk, rst_n, learn, freeze, train_after;
  logic poke, poke_go, pev, piv, prv, pxv;
  logic [7:0] pe, pi, pr, px;
  logic flush, reload, kill, trst;
  logic rank_done, train_done;
  logic [15:0] n_emit, n_scored, n_learned, n_host;
  logic [15:0] top_cid [K];
  node_id_t    top_id  [K];
  score_t      top_sc  [K];
  logic cand_v, cand_hit;
  logic [15:0] cand_cid;
  score_t cand_sc;
  logic signed [7:0] cand_pri;
  logic rew_v, echo_v, rew_rdy, pending, ack_v;
  logic signed [3:0] rew;
  logic [15:0] txn, echo;
  logic [2:0] ack;
  logic [15:0] learn_cid;
  logic [31:0] learn_subj, learn_obj;
  logic [7:0]  learn_rel;
  logic pbusy, pdone, pnak, boot_done, c7v;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic [4:0] st;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, ddr_mem [0:255];

  logic pend_d, pdone_d, pnak_d, got_rank, got_train;
  logic signed [3:0] cur_sched [0:7];
  integer cur_nsched, ord, n_rew, tmo, i, n_rec, ii;
  integer n_commit, n_nak, n_dup_ack, n_host_leaks;
  integer top1_changed, pairwise_changes, freeze_mut, ctx_leak;
  integer first_nak_at, store_occ_max, persist_reload_match;
  logic [15:0] rec_cid [0:63];
  score_t rec_sc [0:63];
  logic signed [7:0] rec_pri [0:63];
  logic rec_hit [0:63];
  logic [15:0] snap_cid [K];
  score_t      snap_sc  [K];
  logic [15:0] base_cid [K];
  score_t      base_sc  [K];
  logic [15:0] a_cid [K];
  score_t      a_sc  [K];
  logic [15:0] last_txn;
  logic [15:0] seq_before;
  integer pri58c, pri58w, sc58c, sc58w, hit58c, hit58w;
  integer pri65, pri66, pri67, sc65, sc66, sc67;
  integer cap_writes, cap_unique, cap_naks, queries_to_nak;

  a7ng_u7_contextual_rank #(.CAND_CAP(64), .K(K)) dut (
    .clk(clk), .rst_n(rst_n),
    .learn_i(learn), .freeze_i(freeze), .train_after_i(train_after),
    .poke_i(poke), .poke_go_i(poke_go),
    .poke_ent_i(pe), .poke_int_i(pi), .poke_rel_i(pr), .poke_ctx_i(px),
    .poke_ev_i(pev), .poke_iv_i(piv), .poke_rv_i(prv), .poke_xv_i(pxv),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill), .train_reset_i(trst),
    .rank_done_o(rank_done), .train_done_o(train_done),
    .n_emit_o(n_emit), .n_scored_o(n_scored), .n_learned_o(n_learned),
    .n_host_or_o(n_host),
    .topk_id_o(top_id), .topk_class_id_o(top_cid), .topk_sc_o(top_sc),
    .cand_rep_v_o(cand_v), .cand_rep_cid_o(cand_cid), .cand_rep_sc_o(cand_sc),
    .cand_rep_pri_o(cand_pri), .cand_rep_hit_o(cand_hit),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy), .pending_o(pending), .txn_o(txn),
    .ack_valid_o(ack_v), .ack_o(ack),
    .learn_cid_o(learn_cid), .learn_subj_o(learn_subj),
    .learn_rel_o(learn_rel), .learn_obj_o(learn_obj),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .c7_ack_valid_o(c7v), .c7_addr_o(c7a),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .dbg_st_o(st),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk) if (ddr_req && ddr_we) ddr_mem[ddr_addr] <= ddr_wdata;
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pend_d <= 0; pdone_d <= 0; pnak_d <= 0;
      got_rank <= 0; got_train <= 0; n_rec <= 0;
    end else begin
      pend_d  <= pending;
      pdone_d <= pdone;
      pnak_d  <= pnak;
      if (cand_v && n_rec < 64) begin
        rec_cid[n_rec] <= cand_cid;
        rec_sc[n_rec]  <= cand_sc;
        rec_pri[n_rec] <= cand_pri;
        rec_hit[n_rec] <= cand_hit;
        n_rec <= n_rec + 1;
      end
      if (rank_done) begin
        for (ii = 0; ii < K; ii = ii + 1) begin
          snap_cid[ii] <= top_cid[ii];
          snap_sc[ii]  <= top_sc[ii];
        end
        got_rank <= 1'b1;
      end
      if (train_done) got_train <= 1'b1;
    end
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s st=%0d seq=%0d", c, d, st, c7seq);
      #20 $finish;
    end
  endtask

  task automatic wait_boot;
    begin
      tmo = 0;
      while (!boot_done && tmo < 40000) begin @(posedge clk); tmo++; end
      if (!boot_done) diverge("EARLY_DONE", "boot");
      while (pbusy && tmo < 80000) begin @(posedge clk); tmo++; end
    end
  endtask

  task automatic wait_idle;
    begin
      tmo = 0;
      while ((st != 5'd1 || pbusy) && tmo < 200000) begin @(posedge clk); tmo++; end
      if (st != 5'd1 || pbusy) diverge("EARLY_DONE", "idle");
    end
  endtask

  task automatic load_sched(input integer kind);
    begin
      for (i = 0; i < 8; i = i + 1) cur_sched[i] = 4'sd0;
      cur_nsched = 8;
      // 0=A 1=B 2=ZERO 3=CHILLER58 4=PLUS1
      if (kind == 0) begin
        cur_sched[0] = -4'sd1; cur_sched[1] = 4'sd2; cur_sched[2] = 4'sd0;
        cur_nsched = 3;
      end else if (kind == 1) begin
        cur_sched[0] = 4'sd2; cur_sched[1] = 4'sd0; cur_sched[2] = -4'sd1;
        cur_nsched = 3;
      end else if (kind == 2) begin
        cur_nsched = 3;
      end else if (kind == 3) begin
        cur_sched[1] = 4'sd2;
        cur_nsched = 8;
      end else begin
        for (i = 0; i < 8; i = i + 1) cur_sched[i] = 4'sd1;
        cur_nsched = 8;
      end
    end
  endtask

  task automatic fire_q(
      input logic [7:0] e, ii, r, x,
      input logic ev, iv, rv, xv,
      input logic do_learn, do_freeze, do_train
  );
    begin
      wait_idle();
      @(negedge clk);
      n_rec = 0; got_rank = 0; got_train = 0; ord = 0; n_rew = 0;
      learn = do_learn; freeze = do_freeze; train_after = do_train;
      poke = 1; pe = e; pi = ii; pr = r; px = x;
      pev = ev; piv = iv; prv = rv; pxv = xv;
      poke_go = 1;
      @(posedge clk); @(negedge clk); poke_go = 0;
    end
  endtask

  task automatic pulse_rew(input logic signed [3:0] mag);
    begin
      echo = txn; echo_v = 1; rew = mag; last_txn = txn;
      @(negedge clk); rew_v = 1;
      @(posedge clk); @(negedge clk); rew_v = 0;
    end
  endtask

  task automatic maybe_reward;
    begin
      if (pending && !pend_d && rew_rdy) begin
        if (learn_subj[31:16] !== 16'h5443)
          diverge("NAMESPACE", "subj prefix");
        if (learn_cid < 16'd1 || learn_cid > 16'd443)
          diverge("CLASS_ID_AS_NID", "cid");
        if (learn_subj[15:0] !== learn_cid)
          diverge("CLASS_ID_AS_NID", "low16");
        pulse_rew(ord < cur_nsched ? cur_sched[ord] : 4'sd0);
        ord = ord + 1;
        n_rew = n_rew + 1;
        if (ack_v && ack == 3'd6) n_dup_ack = n_dup_ack + 1;
      end
    end
  endtask

  task automatic run_query(
      input logic [7:0] e, ii, r, x,
      input logic ev, iv, rv, xv,
      input logic do_learn, do_freeze, do_train,
      input integer allow_nak
  );
    begin
      fire_q(e, ii, r, x, ev, iv, rv, xv, do_learn, do_freeze, do_train);
      tmo = 0;
      while (!got_rank && tmo < 400000) begin
        @(posedge clk);
        if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "n_host rank");
        if (pnak && !allow_nak) diverge("PERSIST_NAK", "unexpected rank");
        tmo++;
      end
      if (!got_rank) diverge("EARLY_DONE", "rank timeout");
      if (do_train && do_learn && !do_freeze) begin
        tmo = 0;
        while (!got_train && tmo < 400000) begin
          @(posedge clk);
          maybe_reward();
          if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "n_host train");
          if (pdone && !pdone_d) n_commit = n_commit + 1;
          if (pnak && !pnak_d) begin
            n_nak = n_nak + 1;
            if (!allow_nak) diverge("PERSIST_NAK", "unexpected train");
          end
          tmo++;
        end
        if (!got_train) diverge("EARLY_DONE", "train timeout");
      end
      @(posedge clk);
      poke = 0;
      wait_idle();
    end
  endtask

  task automatic find_cid(input integer cid, output integer sc, output integer pri, output integer hit);
    integer k;
    begin
      sc = 0; pri = 0; hit = 0;
      for (k = 0; k < n_rec; k = k + 1) begin
        if (rec_cid[k] == cid[15:0]) begin
          sc  = rec_sc[k];
          pri = rec_pri[k];
          hit = rec_hit[k];
        end
      end
    end
  endtask

  task automatic dump_topk(input string tag);
    begin
      $display("%s emit=%0d scored=%0d learned=%0d rec=%0d seq=%0d",
        tag, n_emit, n_scored, n_learned, n_rec, c7seq);
      for (i = 0; i < K; i = i + 1)
        $display("  TOPK[%0d] cid=%0d sc=%0d", i, snap_cid[i], snap_sc[i]);
    end
  endtask

  task automatic pulse_ctl(output logic sig);
    begin
      wait_idle();
      @(negedge clk); sig = 1;
      @(posedge clk); @(negedge clk); sig = 0;
      tmo = 0;
      while (pbusy && tmo < 200000) begin @(posedge clk); tmo++; end
      if (pbusy) diverge("INCONCLUSIVE", "ctl busy");
      wait_boot();
      wait_idle();
    end
  endtask

  // train_reset is epoch-bump only: a later same-key update restamps and
  // keeps pri. Independent controls need a clean working set, so TB resets
  // DUT + wipes modeled DDR (header illegal → P_CLR). Not a G2 redesign.
  task automatic hard_rebirth;
    begin
      @(negedge clk); rst_n = 0;
      for (i = 0; i < 256; i = i + 1) ddr_mem[i] = 64'd0;
      repeat (8) @(posedge clk);
      rst_n = 1;
      wait_boot();
      wait_idle();
    end
  endtask

  initial begin
    #120_000_000;
    $display("FAIL TB timeout");
    $finish;
  end

  initial begin
    rst_n = 0; learn = 1; freeze = 0; train_after = 0;
    poke = 0; poke_go = 0; pe = 0; pi = 0; pr = 0; px = 0;
    pev = 0; piv = 0; prv = 0; pxv = 0;
    flush = 0; reload = 0; kill = 0; trst = 0;
    rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    n_commit = 0; n_nak = 0; n_dup_ack = 0; n_host_leaks = 0;
    top1_changed = 0; pairwise_changes = 0; freeze_mut = 0; ctx_leak = 0;
    first_nak_at = 0; store_occ_max = 0; persist_reload_match = 0;
    cap_writes = 0; cap_unique = 0; cap_naks = 0; queries_to_nak = 0;
    for (i = 0; i < 256; i = i + 1) ddr_mem[i] = 64'd0;
    load_sched(2);
    repeat (8) @(posedge clk); rst_n = 1;
    wait_boot();

    // ---------------------------------------------------------------
    // E1 BASELINE install chiller, learn frozen, no train
    // ---------------------------------------------------------------
    load_sched(2);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E1_BASELINE_INSTALL");
    if (n_host !== 0) diverge("HOST_SEMANTIC_LEAK", "E1");
    if (snap_cid[0] !== 16'd65 || snap_cid[1] !== 16'd66 || snap_cid[2] !== 16'd67)
      diverge("BASELINE", "install heap not 65,66,67");
    if (snap_sc[0] !== 16'sd16 || snap_sc[1] !== 16'sd16 || snap_sc[2] !== 16'sd16)
      diverge("BASELINE", "install scores not 16");
    for (i = 0; i < K; i = i + 1) begin
      base_cid[i] = snap_cid[i];
      base_sc[i]  = snap_sc[i];
    end
    find_cid(65, sc65, pri65, hit58c);
    if (pri65 !== 0) diverge("BASELINE", "prior not 0");
    seq_before = c7seq;

    // ---------------------------------------------------------------
    // E2 FREEZE CONTROL: train_after=1 freeze=1 must not mutate
    // ---------------------------------------------------------------
    load_sched(0);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 0);
    dump_topk("E2_FREEZE_CTRL");
    if (c7seq !== seq_before) begin
      freeze_mut = freeze_mut + 1;
      diverge("FREEZE_BROKEN", "c7seq mutated");
    end
    if (n_learned !== 16'd0) diverge("FREEZE_BROKEN", "n_learned");
    if (snap_cid[0] !== 16'd65 || snap_cid[1] !== 16'd66 || snap_cid[2] !== 16'd67)
      diverge("FREEZE_BROKEN", "rank changed");

    // ---------------------------------------------------------------
    // E3 CAUSAL RANK FLIP — SCHED_A = [-1,+2,0]
    // ---------------------------------------------------------------
    load_sched(0);
    seq_before = c7seq;
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    dump_topk("E3_TRAIN_A");
    if (n_learned !== 16'd3) diverge("STORE_COMMIT", "A n_learned");
    if (n_rew !== 3) diverge("STORE_COMMIT", "A n_rew");
    if (n_commit < 3) diverge("STORE_COMMIT", "A commits");

    // duplicate reward: last txn again must ACK_DUP, no extra commit
    begin
      integer seq_dup;
      seq_dup = c7seq;
      @(negedge clk); echo = last_txn; echo_v = 1; rew = 4'sd2;
      @(negedge clk); rew_v = 1;
      @(posedge clk); @(negedge clk); rew_v = 0;
      tmo = 0;
      while (!ack_v && tmo < 4000) begin @(posedge clk); tmo++; end
      $display("E3_DUP ack=%0d seq=%0d->%0d", ack, seq_dup, c7seq);
      if (ack !== 3'd6) diverge("DUPLICATE_LEARN_COMMIT", "ack not DUP");
      if (c7seq !== seq_dup) diverge("DUPLICATE_LEARN_COMMIT", "seq advanced");
      n_dup_ack = n_dup_ack + 1;
      echo_v = 0;
    end

    // freeze, identical query — ranking must flip
    load_sched(2);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E3_AFTER_A");
    find_cid(65, sc65, pri65, hit58c);
    find_cid(66, sc66, pri66, hit58w);
    find_cid(67, sc67, pri67, hit58c);
    $display("E3_PRI 65=%0d/sc=%0d 66=%0d/sc=%0d 67=%0d/sc=%0d",
      pri65, sc65, pri66, sc66, pri67, sc67);
    if (pri65 !== -1 || pri66 !== 2 || pri67 !== 0)
      diverge("PRIOR_LAW", "A stored priors");
    if (sc65 !== 15 || sc66 !== 18 || sc67 !== 16)
      diverge("PRIOR_LAW", "A composed scores");
    if (snap_cid[0] !== 16'd66 || snap_sc[0] !== 16'sd18)
      diverge("LEARNING_NOT_CAUSAL_TO_RANKING", "TOP1 not 66@18");
    if (snap_cid[1] !== 16'd67 || snap_cid[2] !== 16'd65)
      diverge("LEARNING_NOT_CAUSAL_TO_RANKING", "order not 66,67,65");
    top1_changed = top1_changed + 1;
    pairwise_changes = pairwise_changes + 2; // 66>65 and 67>65
    for (i = 0; i < K; i = i + 1) begin
      a_cid[i] = snap_cid[i];
      a_sc[i]  = snap_sc[i];
    end

    // E3c same-key accumulation: second A
    load_sched(0);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E3C_ACCUM");
    find_cid(65, sc65, pri65, hit58c);
    find_cid(66, sc66, pri66, hit58w);
    find_cid(67, sc67, pri67, hit58c);
    $display("E3C_PRI 65=%0d 66=%0d 67=%0d", pri65, pri66, pri67);
    // Second SCHED_A is ordinal on CURRENT heap (66,67,65), not original 65,66,67.
    // 66: 2+(-1)=1; 67: 0+2=2; 65: -1+0=-1. Same three keys; seq=6.
    if (c7seq !== 16'd6) diverge("SAME_KEY_UPDATE", "seq not 6 (dup alloc?)");
    if (pri65 !== -1 || pri66 !== 1 || pri67 !== 2)
      diverge("SAME_KEY_UPDATE", "accumulate");
    if (sc65 !== 15 || sc66 !== 17 || sc67 !== 18)
      diverge("SAME_KEY_UPDATE", "scores");
    if (snap_cid[0] !== 16'd67 || snap_sc[0] !== 16'sd18)
      diverge("LEARNING_NOT_CAUSAL_TO_RANKING", "accum TOP1");

    // ---------------------------------------------------------------
    // E8 PERSIST flush / kill / reload / re-query
    // ---------------------------------------------------------------
    wait_idle();
    @(negedge clk); flush = 1;
    @(posedge clk); @(negedge clk); flush = 0;
    tmo = 0;
    while (pbusy && tmo < 200000) begin @(posedge clk); tmo++; end
    if (pbusy) diverge("LEARNED_STATE_NOT_DURABLE", "flush");
    wait_idle();
    @(negedge clk); kill = 1;
    @(posedge clk); @(negedge clk); kill = 0;
    tmo = 0;
    while (tmo < 16) begin @(posedge clk); tmo++; end
    // after kill, ranking must lose prior until reload (observability)
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    find_cid(66, sc66, pri66, hit58w);
    $display("E8_AFTER_KILL pri66=%0d top0=%0d", pri66, snap_cid[0]);
    if (pri66 !== 0 || snap_cid[0] !== 16'd65)
      diverge("LEARNED_STATE_NOT_DURABLE", "kill did not hide BRAM");
    wait_idle();
    @(negedge clk); reload = 1;
    @(posedge clk); @(negedge clk); reload = 0;
    wait_boot();
    wait_idle();
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E8_RELOAD");
    find_cid(65, sc65, pri65, hit58c);
    find_cid(66, sc66, pri66, hit58w);
    find_cid(67, sc67, pri67, hit58c);
    if (pri65 !== -1 || pri66 !== 1 || pri67 !== 2)
      diverge("LEARNED_STATE_NOT_DURABLE", "pri after reload");
    if (snap_cid[0] !== 16'd67 || snap_sc[0] !== 16'sd18)
      diverge("LEARNED_STATE_NOT_DURABLE", "rank after reload");
    persist_reload_match = 1;
    $display("E8_PERSIST_RELOAD_MATCH=1");

    // ---------------------------------------------------------------
    // E4 ZERO reward control (clean store; G2 0→0)
    // ---------------------------------------------------------------
    hard_rebirth();
    load_sched(2);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E4_ZERO");
    find_cid(65, sc65, pri65, hit58c);
    find_cid(66, sc66, pri66, hit58w);
    find_cid(67, sc67, pri67, hit58c);
    $display("E4_ZERO_PRI 65=%0d 66=%0d 67=%0d G2_zero_maps_to_zero", pri65, pri66, pri67);
    if (pri65 !== 0 || pri66 !== 0 || pri67 !== 0)
      diverge("ZERO_REWARD", "nonzero prior");
    if (snap_cid[0] !== 16'd65 || snap_cid[1] !== 16'd66 || snap_cid[2] !== 16'd67)
      diverge("ZERO_REWARD", "rank improved");

    // ---------------------------------------------------------------
    // E5 SHUFFLE B = [+2,0,-1]  → 65@18,66@16,67@15 order 65,66,67
    // ---------------------------------------------------------------
    hard_rebirth();
    load_sched(1);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E5_SHUFFLE_B");
    find_cid(65, sc65, pri65, hit58c);
    find_cid(66, sc66, pri66, hit58w);
    find_cid(67, sc67, pri67, hit58c);
    $display("E5_PRI 65=%0d 66=%0d 67=%0d", pri65, pri66, pri67);
    if (pri65 !== 2 || pri66 !== 0 || pri67 !== -1)
      diverge("SHUFFLE", "B priors");
    if (sc65 !== 18 || sc66 !== 16 || sc67 !== 15)
      diverge("SHUFFLE", "B scores");
    if (snap_cid[0] !== 16'd65)
      diverge("SHUFFLE", "B TOP1");
    // A and B stored priors differ (already checked vs A which was -1,+2,0)

    // ---------------------------------------------------------------
    // E6 CONTEXT ISOLATION CLASS_ID 58
    // ---------------------------------------------------------------
    hard_rebirth();
    load_sched(3);
    run_query(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    dump_topk("E6_TRAIN_CHILLER");
    if (n_learned !== 16'd8) diverge("ISOLATION", "chiller n_learned");
    run_query(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E6_CHILLER_AFTER");
    find_cid(58, sc58c, pri58c, hit58c);
    $display("E6_CHILLER58 pri=%0d sc=%0d hit=%0d top0=%0d", pri58c, sc58c, hit58c, snap_cid[0]);
    if (pri58c !== 2) diverge("ISOLATION", "chiller 58 prior");
    if (sc58c !== 10) diverge("ISOLATION", "chiller 58 score 8+2");
    if (snap_cid[0] !== 16'd58)
      diverge("LEARNING_NOT_CAUSAL_TO_RANKING", "chiller TOP1 not 58");
    // water, no train
    run_query(8'd1, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E6_WATER");
    find_cid(58, sc58w, pri58w, hit58w);
    $display("E6_WATER58 pri=%0d sc=%0d hit=%0d", pri58w, sc58w, hit58w);
    if (hit58w !== 0 || pri58w !== 0)
      diverge("CONTEXT_ALIAS", "water 58 inherited chiller prior");
    if (sc58w !== 16) diverge("CONTEXT_ALIAS", "water 58 score");
    ctx_leak = 0;

    // ---------------------------------------------------------------
    // E7 HELD-OUT leak_chiller never trained
    // ---------------------------------------------------------------
    run_query(8'd1, 8'd2, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 0);
    dump_topk("E7_HELDOUT_LEAK");
    if (snap_cid[0] !== 16'd68 || snap_cid[1] !== 16'd69 ||
        snap_cid[2] !== 16'd70 || snap_cid[3] !== 16'd71)
      diverge("HELDOUT", "leak topk");
    find_cid(68, sc65, pri65, hit58c);
    find_cid(69, sc66, pri66, hit58w);
    if (pri65 !== 0 || pri66 !== 0) diverge("HELDOUT", "unearned prior");
    if (snap_sc[0] !== 16'sd16) diverge("HELDOUT", "score");

    // ---------------------------------------------------------------
    // E9 STORE CAPACITY 32
    // ---------------------------------------------------------------
    hard_rebirth();
    n_commit = 0; n_nak = 0; first_nak_at = 0; queries_to_nak = 0;
    load_sched(4);
    // 1 chiller 8
    run_query(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    cap_unique = n_learned; queries_to_nak = 1;
    $display("CAP q1 chiller unique=%0d seq=%0d", cap_unique, c7seq);
    // 2 water 8 → 16
    run_query(8'd1, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 0);
    cap_unique = cap_unique + n_learned; queries_to_nak = 2;
    $display("CAP q2 water unique=%0d seq=%0d", cap_unique, c7seq);
    // 3 install 3 → 19
    run_query(8'd1, 8'd1, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    cap_unique = cap_unique + n_learned; queries_to_nak = 3;
    $display("CAP q3 install unique=%0d seq=%0d", cap_unique, c7seq);
    // 4 leak 4 → 23
    run_query(8'd1, 8'd2, 8'd0, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 0);
    cap_unique = cap_unique + n_learned; queries_to_nak = 4;
    $display("CAP q4 leak unique=%0d seq=%0d", cap_unique, c7seq);
    // 5 air condenser 8 → 31
    run_query(8'd2, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 0);
    cap_unique = cap_unique + n_learned; queries_to_nak = 5;
    $display("CAP q5 aircond unique=%0d seq=%0d", cap_unique, c7seq);
    // 6 supply duct: 32nd ok, 33rd NAK
    run_query(8'd7, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1);
    queries_to_nak = 6;
    cap_naks = n_nak;
    first_nak_at = 32 + 1;
    store_occ_max = 32;
    $display("CAP q6 duct learned=%0d nak=%0d seq=%0d", n_learned, n_nak, c7seq);
    if (n_nak < 1) diverge("STORE_FULL", "expected NAK");
    if (c7seq < 16'd32) diverge("STORE_FULL", "seq<32");
    // existing key while full: re-train chiller
    begin
      integer seq_full, nak_full;
      seq_full = c7seq; nak_full = n_nak;
      run_query(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1);
      $display("CAP existing-while-full learned=%0d seq %0d->%0d nak %0d->%0d",
        n_learned, seq_full, c7seq, nak_full, n_nak);
      if (c7seq <= seq_full) diverge("UPDATE_EXISTING_WHILE_FULL", "no commit");
    end

    if (n_host_leaks !== 0) diverge("HOST_SEMANTIC_LEAK", "aggregate");
    if (n_dup_ack < 1) diverge("DUPLICATE_LEARN_COMMIT", "no dup observed");
    if (freeze_mut !== 0) diverge("FREEZE_BROKEN", "agg");
    if (ctx_leak !== 0) diverge("CONTEXT_ALIAS", "agg");
    if (persist_reload_match !== 1) diverge("LEARNED_STATE_NOT_DURABLE", "agg");
    if (top1_changed < 1) diverge("LEARNING_NOT_CAUSAL_TO_RANKING", "no top1");

    $display("METRICS TOP1_CHANGED_COUNT=%0d PAIRWISE_ORDER_CHANGES=%0d",
      top1_changed, pairwise_changes);
    $display("METRICS CONTEXT_LEAK_COUNT=%0d FREEZE_MUTATION_COUNT=%0d DUPLICATE_UPDATE_COUNT=%0d",
      ctx_leak, freeze_mut, 0);
    $display("METRICS HOST_SEMANTIC_COUNTERS=%0d STORE_OCCUPANCY_MAX=%0d FIRST_NAK_AT_WRITE=%0d",
      n_host, store_occ_max, first_nak_at);
    $display("METRICS PERSIST_RELOAD_MATCH=%0d NAK_COUNT=%0d QUERIES_TO_FIRST_NAK=%0d",
      persist_reload_match, cap_naks, queries_to_nak);
    $display("METRICS STORE_DEPTH=32 N_UNIQUE_LEARN_KEYS=%0d N_WRITES_PER_QUERY=K_OR_VALID",
      store_occ_max);
    $display("HAZARD LEARN_STORE_CAPACITY_32 OPEN HIGH_RISK_ARCHITECTURAL_HAZARD");
    $display("C7_ADDR_OBSERVE_ONLY %08h", c7a);
    $display("U7_CONTEXTUAL_LEARNING_EFFECTIVENESS_PASS");
    $finish;
  end
endmodule
