// tb_u7a_r1.sv — store-full persist_done law. PROGRAM=NO. U7 CLOSED.
`timescale 1ns / 1ps

module tb_u7a_r1;
  import a7ng_pkg::*;

  logic clk, rst_n, learn, freeze, flush, reload, kill, trst;
  logic pbusy, pdone, pnak, boot_done;
  logic [31:0] live_gen;
  logic [63:0] sdig;
  logic wrap_im;
  logic upd_v, upd_r;
  logic [31:0] us, uo;
  logic [7:0]  ur;
  logic signed [3:0] urew;
  logic uk;
  logic lk_go, lk_busy, lk_done, lk_hit;
  logic [31:0] ls, lo;
  logic [7:0]  lr;
  logic signed [7:0] lk_pri, lk_pen;
  logic c7v, c7r;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:255];
  integer tmo, i, n_done, n_nak;
  logic saw_done, saw_nak;
  logic signed [7:0] pri_snap [0:31];
  logic hit_snap [0:31];

  // G1 duplicate-reward (TRANSACTION_CONSUMED, not store commit)
  logic g1_learn, g1_freeze, latch_v, latch_rdy, pending;
  logic [15:0] txn;
  logic rew_v, echo_v, ack_v, ack_rdy, cons_v, cons_rdy;
  logic signed [3:0] rew, cons_rew;
  logic [15:0] echo, cons_qe, cons_pe, n_cons, n_orph, n_range, n_late, n_drop, n_dup, n_mode, cons_txn;
  logic [2:0] ack;
  logic [31:0] cons_s, cons_o;
  logic [7:0] cons_rel, cons_c;
  logic cons_k;

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(clk), .rst_n(rst_n),
    .learn_i(learn), .freeze_i(freeze),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .live_gen_o(live_gen), .sdig_o(sdig), .wrap_imminent_o(wrap_im),
    .upd_valid_i(upd_v), .upd_ready_o(upd_r),
    .upd_subj_i(us), .upd_rel_i(ur), .upd_obj_i(uo),
    .upd_rew_i(urew), .upd_contra_i(uk),
    .lk_go_i(lk_go), .lk_subj_i(ls), .lk_rel_i(lr), .lk_obj_i(lo),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(c7r),
    .c7_addr_o(c7a), .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_feedback_resolver #(.TXN_W(16)) u_g1 (
    .clk(clk), .rst_n(rst_n), .learn_i(g1_learn), .freeze_i(g1_freeze),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(32'h0001_1234), .rel_i(8'd1), .obj_i(32'h0003_5678),
    .q_epoch_i(16'd1), .p_epoch_i(16'd1), .conf_i(8'd1), .contradict_i(1'b0),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(),
    .ack_valid_o(ack_v), .ack_ready_i(ack_rdy), .ack_o(ack),
    .consume_valid_o(cons_v), .consume_ready_i(cons_rdy),
    .consume_reward_o(cons_rew),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(cons_qe), .consume_p_epoch_o(cons_pe),
    .consume_conf_o(cons_c), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
    .n_consume_o(n_cons), .n_orphan_o(n_orph), .n_range_o(n_range),
    .n_late_o(n_late), .n_drop_o(n_drop), .n_dup_o(n_dup), .n_mode_o(n_mode)
  );

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk) if (ddr_req && ddr_we) ddr_mem[ddr_addr] <= ddr_wdata;
  assign ddr_ack = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
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

  task automatic issue_upd(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while (!upd_r && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!upd_r) diverge("INCONCLUSIVE", "no upd_ready");
      @(negedge clk);
      us = s; ur = 8'd1; uo = o; urew = 4'sd1; uk = 0; upd_v = 1;
      @(posedge clk); @(negedge clk); upd_v = 0;
      saw_done = 0; saw_nak = 0;
      tmo = 0;
      while (!saw_done && !saw_nak && tmo < 8000) begin
        @(posedge clk);
        if (pdone) saw_done = 1;
        if (pnak) saw_nak = 1;
        tmo++;
      end
      if (!saw_done && !saw_nak) diverge("INCONCLUSIVE", "no done/nak");
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while ((pbusy || lk_busy) && tmo < 8000) begin @(posedge clk); tmo++; end
      @(negedge clk); ls = s; lr = 8'd1; lo = o; lk_go = 1;
      @(posedge clk); @(negedge clk); lk_go = 0;
      tmo = 0;
      while (!lk_done && tmo < 8000) begin @(posedge clk); tmo++; end
      @(posedge clk);
    end
  endtask

  initial begin
    #20_000_000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    rst_n = 0; learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; uk = 0; urew = 0; us = 0; uo = 0; ur = 1; lk_go = 0; c7r = 1;
    g1_learn = 1; g1_freeze = 0; latch_v = 0; rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    ack_rdy = 1; cons_rdy = 1;
    n_done = 0; n_nak = 0;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (8) @(posedge clk); rst_n = 1;
    wait_boot();

    // G1 dup reward (not store commit)
    tmo = 0;
    while (!latch_rdy && tmo < 4000) begin @(posedge clk); tmo++; end
    @(negedge clk); latch_v = 1; @(posedge clk); @(negedge clk); latch_v = 0;
    tmo = 0;
    while (!pending && tmo < 4000) begin @(posedge clk); tmo++; end
    echo = txn; echo_v = 1; rew = 4'sd2;
    @(negedge clk); rew_v = 1; @(posedge clk); @(negedge clk); rew_v = 0;
    tmo = 0;
    while (!ack_v && tmo < 4000) begin @(posedge clk); tmo++; end
    if (ack !== 3'd1) diverge("DUPLICATE_COMMIT", "first not ACK_CONSUME");
    @(posedge clk);
    @(negedge clk); rew_v = 1; @(posedge clk); @(negedge clk); rew_v = 0;
    tmo = 0;
    while (!ack_v && tmo < 4000) begin @(posedge clk); tmo++; end
    $display("G1_DUP n_cons=%0d n_dup=%0d ack2=%0d", n_cons, n_dup, ack);
    if (n_cons !== 16'd1) diverge("DUPLICATE_COMMIT", "n_consume!=1");
    rew_v = 0; echo_v = 0;

    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    wait_boot();
    for (i = 0; i < 32; i++) begin
      issue_upd(32'hA000 + i, 32'hB000 + i);
      if (!saw_done) diverge("EXISTING_KEY_UPDATE_REGRESSION", "fill must commit");
      if (saw_nak) diverge("EXISTING_KEY_UPDATE_REGRESSION", "fill nak");
      n_done++;
    end
    $display("FULL32 seq=%0d ack=%0d", c7seq, c7cnt);
    if (c7seq !== 16'd32 || c7cnt !== 16'd32)
      diverge("ACK_COUNT_WITHOUT_COMMIT", "fill seq/ack != 32");
    for (i = 0; i < 32; i++) begin
      do_lk(32'hA000 + i, 32'hB000 + i);
      if (!lk_hit) diverge("STORE_FULL_CORRUPTION", "fill miss");
      pri_snap[i] = lk_pri;
      hit_snap[i] = lk_hit;
    end

    issue_upd(32'hA000 + 32, 32'hB000 + 32);
    $display("UPD33 done=%0d nak=%0d seq=%0d ack=%0d", saw_done, saw_nak, c7seq, c7cnt);
    if (saw_done)
      diverge("PERSIST_DONE_WITHOUT_COMMIT", "store-full must not persist_done");
    if (!saw_nak)
      diverge("INTERFACE_EVIDENCE_GAP", "store-full must persist_nak (fail completion)");
    if (c7seq !== 16'd32 || c7cnt !== 16'd32)
      diverge("COMMIT_SEQ_WITHOUT_WRITE", "store-full must not bump seq/ack");
    n_nak++;
    do_lk(32'hA000 + 32, 32'hB000 + 32);
    if (lk_hit) diverge("FALSE_COMMIT_SIGNAL", "33rd must miss");
    for (i = 0; i < 32; i++) begin
      do_lk(32'hA000 + i, 32'hB000 + i);
      if (!lk_hit || lk_pri !== pri_snap[i])
        diverge("STORE_FULL_CORRUPTION", "32-set not bit-exact after reject");
    end

    // existing key while full: in-place write, not allocation failure
    issue_upd(32'hA000 + 0, 32'hB000 + 0);
    $display("UPD_EXIST done=%0d nak=%0d seq=%0d ack=%0d", saw_done, saw_nak, c7seq, c7cnt);
    if (!saw_done || saw_nak)
      diverge("EXISTING_KEY_UPDATE_REGRESSION", "in-place while full must commit");
    if (c7seq !== 16'd33 || c7cnt !== 16'd33)
      diverge("EXISTING_KEY_UPDATE_REGRESSION", "in-place seq/ack");
    n_done++;
    do_lk(32'hA000 + 0, 32'hB000 + 0);
    if (!lk_hit || lk_pri !== (pri_snap[0] + 8'sd1))
      diverge("EXISTING_KEY_UPDATE_REGRESSION", "in-place pri");
    do_lk(32'hA000 + 1, 32'hB000 + 1);
    if (!lk_hit || lk_pri !== pri_snap[1])
      diverge("STORE_FULL_CORRUPTION", "neighbor corrupted");

    // SchemaV2 high identity vs low16 alias
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    wait_boot();
    issue_upd(32'h000C_34FF, 32'h000B_EEFF);
    if (!saw_done) diverge("PERSIST_IDENTITY_REGRESSION", "high-id write");
    do_lk(32'h000C_34FF, 32'h000B_EEFF);
    if (!lk_hit) diverge("PERSIST_IDENTITY_REGRESSION", "high-id miss");
    do_lk(32'h0000_34FF, 32'h0000_EEFF);
    if (lk_hit) diverge("PERSIST_IDENTITY_REGRESSION", "low16 alias hit");
    $display("C7_OBSERVE addr=%08h (NOT commit proof)", c7a);

    // reset between SchemaV2 beats
    @(negedge clk); flush = 1; @(posedge clk); @(negedge clk); flush = 0;
    tmo = 0;
    while (!(ddr_req && ddr_we && ddr_addr == 8'd1) && tmo < 20000) begin
      @(posedge clk); tmo++;
    end
    if (tmo >= 20000) diverge("INCONCLUSIVE", "no identity beat");
    @(posedge clk);
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    wait_boot();
    do_lk(32'h000C_34FF, 32'h000B_EEFF);
    $display("RESET_BEAT2 lk_hit=%0d", lk_hit);
    if (lk_hit)
      diverge("SCHEMAV2_ATOMICITY_REGRESSION", "false committed after mid-flush reset");

    $display("U7A_R1_STORE_FULL_COMMIT_LAW_PASS n_done=%0d n_nak=%0d n_cons=%0d",
      n_done, n_nak, n_cons);
    $display("U7A_FAIL_IMMUTABLE TYPECLASS_TO_LEARN=NOT_REACHABLE BIT=NO PROGRAM=NO");
    $display("U6_TYPECLASS_MINHEAP_TIMING OPEN");
    #20 $finish;
  end
endmodule
