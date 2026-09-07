// tb_u7a_rootb.sv — U7A Root-B reachability reaudit. PROGRAM=NO.
// Does NOT wire TYPE_CLASS into G1/store (NOT_REACHABLE — do not fake).
`timescale 1ns / 1ps

module tb_u7a_rootb;
  import a7ng_pkg::*;

  logic clk, rst_n, learn, freeze, flush, reload, kill, trst;
  logic pbusy, pdone, boot_done;
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

  integer tmo, i, n_pdone, n_upd, n_ack_c7;
  logic [15:0] seq32, ack32;
  logic hit33;
  logic signed [7:0] pri33, pen33;
  integer first_div;
  string first_tag, first_why;

  // G1
  logic g1_learn, g1_freeze, latch_v, latch_rdy, pending;
  logic [15:0] txn;
  logic rew_v, rew_rdy, echo_v;
  logic signed [3:0] rew;
  logic [15:0] echo;
  logic ack_v, ack_rdy;
  logic [2:0] ack;
  logic cons_v, cons_rdy;
  logic signed [3:0] cons_rew;
  logic [31:0] cons_s, cons_o;
  logic [7:0] cons_rel, cons_c;
  logic [15:0] cons_qe, cons_pe, n_cons, n_orph, n_range, n_late, n_drop, n_dup, n_mode;
  logic cons_k;
  logic [15:0] cons_txn;

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) u_st (
    .clk(clk), .rst_n(rst_n),
    .learn_i(learn), .freeze_i(freeze),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .boot_done_o(boot_done),
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
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_ready_i(ack_rdy), .ack_o(ack),
    .consume_valid_o(cons_v), .consume_ready_i(cons_rdy),
    .consume_reward_o(cons_rew),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(cons_qe), .consume_p_epoch_o(cons_pe),
    .consume_conf_o(cons_c), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
    .n_consume_o(n_cons), .n_orphan_o(n_orph), .n_range_o(n_range),
    .n_late_o(n_late), .n_drop_o(n_drop), .n_dup_o(n_dup), .n_mode_o(n_mode)
  );

  // Disconnected TYPE_CLASS CLASS_ID — never drives store/G1.
  logic [15:0] decoy_class_id;
  assign decoy_class_id = 16'd57;

  initial clk = 0;
  always #5 clk = ~clk;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      n_pdone <= 0; n_ack_c7 <= 0;
    end else begin
      if (pdone) n_pdone <= n_pdone + 1;
      if (c7v) n_ack_c7 <= n_ack_c7 + 1;
    end
  end

  task automatic diverge(input string tag, input string why);
    begin
      if (first_div == 0) begin
        first_div = 1;
        first_tag = tag;
        first_why = why;
        $display("FIRST_DIVERGENCE %s %s", tag, why);
      end else
        $display("ALSO %s %s", tag, why);
    end
  endtask

  task automatic wait_boot;
    begin
      tmo = 0;
      while (!boot_done && tmo < 40000) begin @(posedge clk); tmo++; end
      if (!boot_done) diverge("EARLY_DONE", "boot timeout");
      while (pbusy && tmo < 80000) begin @(posedge clk); tmo++; end
    end
  endtask

  task automatic do_upd(input logic [31:0] s, input logic [31:0] o,
                        input logic signed [3:0] rew);
    begin
      tmo = 0;
      while (!upd_r && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!upd_r) diverge("INCONCLUSIVE", "no upd_ready");
      @(negedge clk);
      us = s; ur = 8'd1; uo = o; urew = rew; uk = 1'b0; upd_v = 1'b1;
      @(posedge clk); @(negedge clk); upd_v = 1'b0;
      tmo = 0;
      while (!pdone && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!pdone) diverge("INCONCLUSIVE", "no persist_done after upd");
      n_upd++;
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input logic [31:0] s, input logic [31:0] o);
    begin
      tmo = 0;
      while ((pbusy || lk_busy) && tmo < 8000) begin @(posedge clk); tmo++; end
      @(negedge clk);
      ls = s; lr = 8'd1; lo = o; lk_go = 1'b1;
      @(posedge clk); @(negedge clk); lk_go = 1'b0;
      tmo = 0;
      while (!lk_done && tmo < 8000) begin @(posedge clk); tmo++; end
      @(posedge clk);
    end
  endtask

  initial begin
    #20_000_000;
    $display("FAIL TB timeout");
    $finish;
  end

  initial begin
    first_div = 0; n_upd = 0;
    rst_n = 0; learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; uk = 0; urew = 0; us = 0; uo = 0; ur = 1; lk_go = 0; c7r = 1;
    g1_learn = 1; g1_freeze = 0; latch_v = 0; rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    ack_rdy = 1; cons_rdy = 1;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    wait_boot();
    $display("BOOT pdone_n=%0d boot=%0d", n_pdone, boot_done);

    // Reachability: decoy CLASS_ID never equals store key unless we program it.
    if (decoy_class_id == 16'd57)
      $display("REACHABILITY NOT_REACHABLE decoy_CLASS_ID=%0d not wired to upd_subj", decoy_class_id);

    // C7_ADDR observe-only: PRIOR_BASE + {subj[15:0],4'h0}. Not commit proof.
    do_upd(32'h0001_1234, 32'h0003_5678, 4'sd1);
    $display("C7_OBSERVE addr=%08h seq=%0d cnt=%0d (NOT commit proof; low16 shifted)", c7a, c7seq, c7cnt);
    if (c7a === 32'd0)
      diverge("EVIDENCE_GAP", "c7_addr zero");
    do_lk(32'h0001_1234, 32'h0003_5678);
    if (!lk_hit) diverge("CONFIRMED_DEFECT", "first update not visible");

    // Duplicate G1 reward
    tmo = 0;
    while (!latch_rdy && tmo < 4000) begin @(posedge clk); tmo++; end
    @(negedge clk); latch_v = 1; @(posedge clk); @(negedge clk); latch_v = 0;
    tmo = 0;
    while (!pending && tmo < 4000) begin @(posedge clk); tmo++; end
    echo = txn; echo_v = 1; rew = 4'sd2;
    @(negedge clk); rew_v = 1; @(posedge clk); @(negedge clk); rew_v = 0;
    tmo = 0;
    while (!ack_v && tmo < 4000) begin @(posedge clk); tmo++; end
    $display("G1_ACK1 code=%0d n_cons=%0d n_dup=%0d pending=%0d", ack, n_cons, n_dup, pending);
    if (ack !== 3'd1) diverge("CONFIRMED_DEFECT", "first reward not ACK_CONSUME");
    @(posedge clk);
    // second identical reward
    @(negedge clk); rew_v = 1; @(posedge clk); @(negedge clk); rew_v = 0;
    tmo = 0;
    while (!ack_v && tmo < 4000) begin @(posedge clk); tmo++; end
    $display("G1_ACK2 code=%0d n_cons=%0d n_dup=%0d", ack, n_cons, n_dup);
    if (n_cons !== 16'd1)
      diverge("CONFIRMED_DEFECT", "duplicate reward consumed twice");
    if (ack !== 3'd6 && n_dup == 0)
      diverge("CONFIRMED_DEFECT", "second reward not marked dup/orphan");
    rew_v = 0; echo_v = 0;

    // CLASS_ID vs subj namespace: CLASS_ID 57 as 32-bit subj is not retrieval id
    do_upd(32'd57, 32'd99, 4'sd1);
    do_lk(32'd57, 32'd99);
    $display("ALIAS_NS subj=57 (not CLASS_ID) hit=%0d pri=%0d", lk_hit, lk_pri);
    if (!lk_hit) diverge("INCONCLUSIVE", "numeric 57 subj not stored");

    // Store-full: 32 distinct vis rows then 33rd
    // slot 0 already has 0x00011234; fill remaining 31 + extras from 0
    // Use 32 keys 0xA000+i / 0xB000+i. First update already occupied one slot
    // with 0x00011234. Need 31 more then check occupancy, then 32 of A000.
    // Simpler: reset store and fill 32 of A000 then 33rd.
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    wait_boot();
    n_upd = 0;
    for (i = 0; i < 32; i++)
      do_upd(32'hA000 + i, 32'hB000 + i, 4'sd1);
    seq32 = c7seq;
    ack32 = c7cnt;
    $display("FULL32 seq=%0d ack=%0d n_upd=%0d", seq32, ack32, n_upd);
    do_lk(32'hA000 + 0, 32'hB000 + 0);
    if (!lk_hit) diverge("CONFIRMED_DEFECT", "slot0 missing after fill");
    do_upd(32'hA000 + 32, 32'hB000 + 32, 4'sd1);
    $display("UPD33 persist_done seen seq=%0d ack=%0d", c7seq, c7cnt);
    do_lk(32'hA000 + 32, 32'hB000 + 32);
    hit33 = lk_hit; pri33 = lk_pri; pen33 = lk_pen;
    $display("LK33 hit=%0d pri=%0d seq=%0d ack=%0d", hit33, pri33, c7seq, c7cnt);
    if (c7cnt !== (ack32 + 16'd1))
      diverge("EVIDENCE_GAP", "ack_count did not advance on 33rd");
    if (hit33)
      diverge("INCONCLUSIVE", "33rd unexpectedly allocated");
    if (!hit33 && (c7seq === seq32) && (c7cnt === (ack32 + 16'd1)))
      diverge("CONFIRMED_DEFECT",
        "persist_done/ack_count without BRAM commit (store full, wrote=0)");

    // Reset between SchemaV2 beats: 1 record, flush, cut after identity beat
    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    wait_boot();
    do_upd(32'h000C_34FF, 32'h000B_EEFF, 4'sd2);
    @(negedge clk); flush = 1; @(posedge clk); @(negedge clk); flush = 0;
    tmo = 0;
    while (!(ddr_req && ddr_we && ddr_addr == 8'd1) && tmo < 20000) begin
      @(posedge clk); tmo++;
    end
    if (tmo >= 20000) diverge("INCONCLUSIVE", "no identity beat");
    else begin
      $display("FLUSH identity beat addr=%0d data=%016h", ddr_addr, ddr_wdata);
      @(posedge clk);
      rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
      wait_boot();
      do_lk(32'h000C_34FF, 32'h000B_EEFF);
      $display("RESET_BEAT2 lk_hit=%0d (expect 0 if incomplete flush not committed)", lk_hit);
      if (lk_hit)
        diverge("CONFIRMED_DEFECT", "reset between SchemaV2 beats left committed record");
    end

    $display("U7A_COUNTERS n_upd=%0d n_pdone=%0d n_c7ack=%0d n_cons=%0d n_dup=%0d",
      n_upd, n_pdone, n_ack_c7, n_cons, n_dup);
    $display("C7_ADDR_NOT_PROOF observe_only");
    $display("HOST_SEMANTIC=0");
    $display("QHEAD=NO BIT=NO PROGRAM=NO");
    $display("U6_TYPECLASS_MINHEAP_TIMING residual OPEN WNS=-4.103ns");
    if (first_div)
      $display("U7A_ROOTB_FAIL tag=%s %s", first_tag, first_why);
    else
      $display("U7A_ROOTB_PASS");
    #20 $finish;
  end
endmodule
