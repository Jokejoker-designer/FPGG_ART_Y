// tb_persist_identity_width.sv — PERSIST-IDENTITY-WIDTH-00
// Measure whether 32-bit subj/obj survive flush→DDR→kill→reload.
// RTL_EDIT=NO. PROGRAM=NO. No COM12. No C9 oracle retarget.
`timescale 1ns / 1ps

module tb_persist_identity_width;
  import a7ng_pkg::*;

  localparam logic [31:0] S1 = 32'h0001_1234;
  localparam logic [31:0] S2 = 32'h0002_1234;
  localparam logic [31:0] O1 = 32'h0003_5678;
  localparam logic [31:0] O2 = 32'h0004_5678;
  localparam logic [31:0] S3 = 32'h000C_34FF;
  localparam logic [31:0] O3 = 32'h000B_EEFF;
  localparam logic [31:0] S_LO = 32'h0000_0011;
  localparam logic [31:0] O_LO = 32'h0000_0022;
  localparam logic [31:0] S1A = 32'h0000_1234; // 16-bit alias of S1/S2
  localparam logic [31:0] O1A = 32'h0000_5678;
  localparam logic [31:0] S3A = 32'h0000_34FF;
  localparam logic [31:0] O3A = 32'h0000_EEFF;
  localparam logic [7:0]  REL = 8'h01;

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

  integer fd, fails, g, i;
  integer n_div;
  logic hit;
  logic signed [7:0] pri, pen;
  logic [15:0] seq_before, ack_before;
  logic [63:0] pay1, pay2, pay3, paylo;

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

  task automatic wait_idle;
    begin
      g = 0;
      while ((pbusy || lk_busy || !boot_done) && g < 32000) begin
        @(posedge clk); g++;
      end
      if (pbusy || !boot_done) begin
        $display("FAIL idle/boot timeout boot=%0d busy=%0d", boot_done, pbusy);
        fails++;
      end
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
      g = 0;
      while (!boot_done && g < 16000) begin @(posedge clk); g++; end
      @(posedge clk);
    end
  endtask

  task automatic do_upd(input logic [31:0] s, input logic [31:0] o,
                        input logic signed [3:0] rew);
    begin
      g = 0;
      while (!upd_r && g < 8000) begin @(posedge clk); g++; end
      if (!upd_r) begin $display("FAIL no upd_ready s=%h", s); fails++; end
      @(negedge clk);
      us = s; ur = REL; uo = o; urew = rew; uk = 1'b0; upd_v = 1'b1;
      @(posedge clk); @(negedge clk); upd_v = 1'b0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 ack s=%h", s); fails++; end
      $display("C7_ACK seq=%0d cnt=%0d addr=%08h subj=%08h", c7seq, c7cnt, c7a, s);
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input logic [31:0] s, input logic [31:0] o,
                       output logic hit_o, output logic signed [7:0] pri_o,
                       output logic signed [7:0] pen_o);
    begin
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk);
      ls = s; lr = REL; lo = o; lk_go = 1'b1;
      @(posedge clk); @(negedge clk); lk_go = 1'b0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      if (!lk_done) begin $display("FAIL no lk_done s=%h", s); fails++; end
      hit_o = lk_hit; pri_o = lk_pri; pen_o = lk_pen;
      @(posedge clk);
    end
  endtask

  task automatic dump_ddr(input string tag);
    begin
      $display("DDR_DUMP %s hdr=%016h", tag, ddr_mem[0]);
      for (i = 1; i <= 4; i++)
        $display("DDR_SLOT %s i=%0d w=%016h subj16=%04h obj16=%04h rel=%02h pri=%02h pen=%02h stp=%02h",
          tag, i, ddr_mem[i],
          ddr_mem[i][63:48], ddr_mem[i][47:32],
          ddr_mem[i][31:24], ddr_mem[i][23:16],
          ddr_mem[i][15:8], ddr_mem[i][7:0]);
    end
  endtask

  task automatic rec_div(input string tag, input string why);
    begin
      n_div++;
      $display("FIRST_DIVERGENCE tag=%s %s", tag, why);
      $fdisplay(fd, "DIVERGENCE,%s,%s", tag, why);
    end
  endtask

  initial begin
    #20_000_000;
    $display("FAIL TB timeout");
    $finish;
  end

  initial begin
    fails = 0; n_div = 0; c7r = 1;
    learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; lk_go = 0; rst_n = 0;
    fd = $fopen("persist_identity.csv", "w");
    $fdisplay(fd, "case,phase,subj,obj,hit,pri,pen,note");

    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    wait_idle;
    $display("BOOT gen=%0d boot=%0d", live_gen, boot_done);

    // ---- CASE LO: identity < 0xFFFF must survive ----
    seq_before = c7seq; ack_before = c7cnt;
    do_upd(S_LO, O_LO, 4'sd3);
    if (c7seq !== (seq_before + 16'd1)) rec_div("LO", "commit_seq did not increment");
    if (c7cnt !== (ack_before + 16'd1)) rec_div("LO", "ack_count did not increment");
    do_lk(S_LO, O_LO, hit, pri, pen);
    $display("LO BEFORE hit=%0d pri=%0d pen=%0d", hit, pri, pen);
    $fdisplay(fd, "LO,before,%08h,%08h,%0d,%0d,%0d,learn", S_LO, O_LO, hit, pri, pen);
    if (!hit) rec_div("LO", "false miss before flush");
    pulse_busy(flush);
    dump_ddr("LO");
    paylo = ddr_mem[1];
    $display("LO DDR_PAYLOAD=%016h", paylo);
    if (paylo[63:48] !== S_LO[15:0] || paylo[47:32] !== O_LO[15:0])
      rec_div("LO", "low-id DDR slice mismatch");
    pulse_busy(kill);
    do_lk(S_LO, O_LO, hit, pri, pen);
    $display("LO AFTER_KILL hit=%0d (expect 0, ws_live=0)", hit);
    if (hit) rec_div("LO", "hit after kill; BRAM still visible");
    pulse_busy(reload);
    wait_idle;
    do_lk(S_LO, O_LO, hit, pri, pen);
    $display("LO AFTER_RELOAD orig hit=%0d pri=%0d pen=%0d", hit, pri, pen);
    $fdisplay(fd, "LO,after,%08h,%08h,%0d,%0d,%0d,reload", S_LO, O_LO, hit, pri, pen);
    if (!hit) rec_div("LO", "low-id false miss after reload");
    if (pri !== 8'sd3) rec_div("LO", "low-id pri not preserved");

    // ---- CASE S1: high identity, alias in low 16 ----
    do_upd(S1, O1, 4'sd4);
    do_lk(S1, O1, hit, pri, pen);
    $display("S1 BEFORE hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S1,before,%08h,%08h,%0d,%0d,%0d,learn", S1, O1, hit, pri, pen);
    if (!hit) rec_div("S1", "false miss before flush");
    pulse_busy(flush);
    dump_ddr("S1");
    pay1 = ddr_mem[2];
    // After LO occupies slot0→DDR[1], S1 is likely DDR[2]
    // Scan occupied data slots for 16-bit slice of S1.
    pay1 = 64'd0;
    for (i = 1; i <= 32; i++) begin
      if (ddr_mem[i][63:48] === S1[15:0] && ddr_mem[i][47:32] === O1[15:0])
        pay1 = ddr_mem[i];
    end
    $display("S1 DDR_PAYLOAD=%016h packed_subj16=%04h packed_obj16=%04h",
      pay1, pay1[63:48], pay1[47:32]);
    $fdisplay(fd, "S1,ddr,0,%016h,0,0,0,payload", pay1);
    if (pay1[63:48] !== S1[15:0]) rec_div("S1", "DDR did not even keep low 16 of subj");
    if (pay1[63:48] === S1[15:0] && pay1[63:32] !== S1)
      $display("S1_OBSERVED DDR stores only subj[15:0] (lost %04h)", S1[31:16]);
    pulse_busy(kill);
    pulse_busy(reload);
    wait_idle;
    do_lk(S1, O1, hit, pri, pen);
    $display("S1 AFTER orig hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S1,after_orig,%08h,%08h,%0d,%0d,%0d,reload", S1, O1, hit, pri, pen);
    if (!hit) rec_div("S1", "false miss of canonical S1/O1 after reload");
    do_lk(S1A, O1A, hit, pri, pen);
    $display("S1 AFTER alias(0x1234/0x5678) hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S1,after_alias,%08h,%08h,%0d,%0d,%0d,reload", S1A, O1A, hit, pri, pen);
    if (hit) rec_div("S1", "false hit on 16-bit alias after reload");

    // ---- CASE PAIR: S1/O1 already present; add S2/O2 ----
    do_upd(S2, O2, 4'sd5);
    do_lk(S1, O1, hit, pri, pen);
    $display("PAIR BEFORE S1 hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "PAIR,before_s1,%08h,%08h,%0d,%0d,%0d,learn", S1, O1, hit, pri, pen);
    do_lk(S2, O2, hit, pri, pen);
    $display("PAIR BEFORE S2 hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "PAIR,before_s2,%08h,%08h,%0d,%0d,%0d,learn", S2, O2, hit, pri, pen);
    if (!hit) rec_div("PAIR", "S2 miss before flush");
    pulse_busy(flush);
    dump_ddr("PAIR");
    pay1 = 64'd0; pay2 = 64'd0;
    for (i = 1; i <= 32; i++) begin
      if (ddr_mem[i][63:48] === 16'h1234 && ddr_mem[i][47:32] === 16'h5678) begin
        if (pay1 == 64'd0) pay1 = ddr_mem[i];
        else pay2 = ddr_mem[i];
      end
    end
    $display("PAIR DDR_S1_SLICE=%016h DDR_S2_SLICE=%016h same16=%0d",
      pay1, pay2, (pay1[63:32] === pay2[63:32]));
    if (pay1 != 64'd0 && pay2 != 64'd0 && (pay1[63:32] === pay2[63:32]))
      rec_div("PAIR", "S1 and S2 serialize to identical 16-bit subj/obj");
    pulse_busy(kill);
    pulse_busy(reload);
    wait_idle;
    do_lk(S1, O1, hit, pri, pen);
    $display("PAIR AFTER S1 hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "PAIR,after_s1,%08h,%08h,%0d,%0d,%0d,reload", S1, O1, hit, pri, pen);
    if (!hit) rec_div("PAIR", "S1 false miss after reload");
    do_lk(S2, O2, hit, pri, pen);
    $display("PAIR AFTER S2 hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "PAIR,after_s2,%08h,%08h,%0d,%0d,%0d,reload", S2, O2, hit, pri, pen);
    if (!hit) rec_div("PAIR", "S2 false miss after reload");
    do_lk(S1A, O1A, hit, pri, pen);
    $display("PAIR AFTER alias hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "PAIR,after_alias,%08h,%08h,%0d,%0d,%0d,reload", S1A, O1A, hit, pri, pen);
    if (hit) rec_div("PAIR", "alias false hit after reload");

    // ---- CASE S3 sentinel-high ----
    do_upd(S3, O3, 4'sd2);
    do_lk(S3, O3, hit, pri, pen);
    $display("S3 BEFORE hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S3,before,%08h,%08h,%0d,%0d,%0d,learn", S3, O3, hit, pri, pen);
    pulse_busy(flush);
    dump_ddr("S3");
    pulse_busy(kill);
    pulse_busy(reload);
    wait_idle;
    do_lk(S3, O3, hit, pri, pen);
    $display("S3 AFTER orig hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S3,after_orig,%08h,%08h,%0d,%0d,%0d,reload", S3, O3, hit, pri, pen);
    if (!hit) rec_div("S3", "canonical S3/O3 false miss after reload");
    do_lk(S3A, O3A, hit, pri, pen);
    $display("S3 AFTER alias hit=%0d pri=%0d", hit, pri);
    $fdisplay(fd, "S3,after_alias,%08h,%08h,%0d,%0d,%0d,reload", S3A, O3A, hit, pri, pen);
    if (hit) rec_div("S3", "S3 16-bit alias false hit");

    $display("N_DIVERGENCE=%0d FAILS=%0d", n_div, fails);
    if (n_div == 0 && fails == 0) begin
      $display("PERSIST_IDENTITY_WIDTH_PASS");
    end else begin
      $display("PERSIST_IDENTITY_WIDTH_FAIL n_div=%0d", n_div);
    end
    $fclose(fd);
    #20 $finish;
  end
endmodule
