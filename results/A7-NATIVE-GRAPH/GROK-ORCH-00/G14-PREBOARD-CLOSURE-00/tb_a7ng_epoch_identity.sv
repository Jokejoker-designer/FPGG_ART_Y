// tb_a7ng_epoch_identity.sv — G14-PREBOARD-CLOSURE-00
// Epoch object: cookie matrix, BUMP forget, WRAP REBIRTH.
// PROGRAM=NO. No COM12. No oracle retarget.
`timescale 1ns / 1ps

module tb_a7ng_epoch_identity;
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

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) dut (
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

  initial clk = 0;
  always #5 clk = ~clk;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  integer fails, i, g;
  logic hit;
  logic signed [7:0] pri;

  task automatic fill_all(input logic [63:0] v);
    begin
      for (i = 0; i < 256; i++) ddr_mem[i] = v;
    end
  endtask

  task automatic wait_boot;
    begin
      g = 0;
      while ((!boot_done || pbusy) && g < 16000) begin @(posedge clk); g++; end
      if (!boot_done) begin $display("FAIL boot_done timeout"); fails++; end
    end
  endtask

  task automatic pulse_busy(ref logic sig);
    begin
      g = 0;
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      while (pbusy && g < 32000) begin @(posedge clk); g++; end
      if (pbusy) begin $display("FAIL persist busy timeout"); fails++; end
      // REBIRTH drops boot_done during P_CLR; wait it back.
      g = 0;
      while (!boot_done && g < 8000) begin @(posedge clk); g++; end
      if (!boot_done) begin $display("FAIL boot_done after pulse"); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic cold_boot(input logic [63:0] hdr);
    begin
      learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
      upd_v = 0; lk_go = 0; rst_n = 0;
      ddr_mem[0] = hdr;
      repeat (4) @(posedge clk);
      rst_n = 1;
      wait_boot;
    end
  endtask

  task automatic do_upd(input int unsigned fi);
    begin
      g = 0;
      while (!upd_r && g < 8000) begin @(posedge clk); g++; end
      if (!upd_r) begin $display("FAIL no upd_ready fi=%0d", fi); fails++; end
      @(negedge clk);
      us = 32'hA000 + fi; ur = 8'd1; uo = 32'hB000 + fi;
      urew = 4'sd3; uk = 1'b0; upd_v = 1'b1;
      @(posedge clk); @(negedge clk); upd_v = 1'b0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 fi=%0d", fi); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input int unsigned fi, output logic hit_o);
    begin
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk);
      ls = 32'hA000 + fi; lr = 8'd1; lo = 32'hB000 + fi; lk_go = 1'b1;
      @(posedge clk); @(negedge clk); lk_go = 1'b0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      if (!lk_done) begin $display("FAIL no lk_done fi=%0d", fi); fails++; end
      hit_o = lk_hit;
      @(posedge clk);
    end
  endtask

  task automatic expect_gen(input string tag, input logic [31:0] want);
    begin
      $display("%s GEN=%08h want=%08h boot=%0d wrap=%0d",
               tag, live_gen, want, boot_done, wrap_im);
      if (live_gen !== want) begin
        $display("FAIL %s GEN=%08h want=%08h", tag, live_gen, want);
        fails++;
      end
    end
  endtask

  initial begin
    #20_000_000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0; c7r = 1; learn = 1; freeze = 0;
    flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; lk_go = 0; rst_n = 0;

    // ---- I6 cookie matrix: illegal → REBIRTH gen=1; legal → restore ----
    fill_all(64'd0);
    cold_boot(64'd0);
    expect_gen("ZERO", 32'd1);

    fill_all(64'hFFFFFFFFFFFFFFFF);
    cold_boot(64'hFFFFFFFFFFFFFFFF);
    expect_gen("ONES", 32'd1);

    fill_all(64'd0);
    cold_boot(ng_epoch_pack(32'd1));
    expect_gen("VALID_GEN_1", 32'd1);

    fill_all(64'd0);
    cold_boot(ng_epoch_pack(32'd2));
    expect_gen("VALID_GEN_2", 32'd2);

    fill_all(64'd0);
    cold_boot(ng_epoch_pack(32'd6));
    expect_gen("VALID_GEN_6", 32'd6);

    fill_all(64'd0);
    cold_boot(ng_epoch_pack(32'd7));
    expect_gen("GEN_7_WRAP", 32'd1);

    fill_all(64'd0);
    cold_boot({31'd0, 32'd0, 1'b1});
    expect_gen("GEN_0", 32'd1);

    fill_all(64'd0);
    cold_boot({31'd0, 32'd1, 1'b0});
    expect_gen("VALID_BIT0_0", 32'd1);

    fill_all(64'd0);
    cold_boot({30'd0, 1'b1, 32'd1, 1'b1});
    expect_gen("RESERVED_NZ", 32'd1);

    // ---- I5 BUMP: fact A vis_w, TRESET, A forgotten, B allocatable ----
    fill_all(64'd0);
    cold_boot(64'd0);
    expect_gen("BUMP_BOOT", 32'd1);
    do_upd(0);
    do_lk(0, hit);
    if (!hit) begin $display("FAIL BUMP A0 miss before TRESET"); fails++; end
    pulse_busy(trst);
    expect_gen("BUMP_AFTER", 32'd2);
    do_lk(0, hit);
    if (hit) begin $display("FAIL BUMP A0 still vis_w after TRESET"); fails++; end
    do_upd(1);
    do_lk(1, hit);
    if (!hit) begin $display("FAIL BUMP B1 miss after TRESET"); fails++; end

    // ---- I9 REBIRTH at wrap: 5 bumps to gen=6, 6th TRESET wipes ----
    fill_all(64'd0);
    cold_boot(64'd0);
    do_upd(0);
    do_lk(0, hit);
    if (!hit) begin $display("FAIL WRAP A0 miss before bumps"); fails++; end
    // gen 1 → 2,3,4,5,6
    for (i = 0; i < 5; i++)
      pulse_busy(trst);
    expect_gen("WRAP_AT_LIMIT", 32'd6);
    if (!wrap_im) begin $display("FAIL wrap_imminent not set at gen=6"); fails++; end
    do_lk(0, hit);
    if (hit) begin $display("FAIL A0 vis_w at gen=6 (stamp still 1)"); fails++; end
    // Need a vis_w row at gen=6 so rebirth has something to destroy.
    do_upd(2);
    do_lk(2, hit);
    if (!hit) begin $display("FAIL C2 miss at gen=6"); fails++; end
    pulse_busy(trst);
    expect_gen("REBIRTH", 32'd1);
    if (wrap_im) begin $display("FAIL wrap_imminent still set after rebirth"); fails++; end
    do_lk(2, hit);
    if (hit) begin $display("FAIL REBIRTH left C2 vis_w (P_INVAL was DDR-only)"); fails++; end
    do_lk(0, hit);
    if (hit) begin $display("FAIL REBIRTH left A0 vis_w"); fails++; end
    // DDR cookie must not be a legal epoch after rebirth (zeros).
    if (ng_epoch_legal(ddr_mem[0], 32'd6)) begin
      $display("FAIL REBIRTH DDR[0] still legal cookie %016h", ddr_mem[0]);
      fails++;
    end
    // New epoch can learn again.
    do_upd(3);
    do_lk(3, hit);
    if (!hit) begin $display("FAIL post-rebirth D3 miss"); fails++; end
    expect_gen("POST_REBIRTH_LEARN", 32'd1);

    if (fails == 0)
      $display("EPOCH_IDENTITY_XSIM_PASS fails=0");
    else
      $display("EPOCH_IDENTITY_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
