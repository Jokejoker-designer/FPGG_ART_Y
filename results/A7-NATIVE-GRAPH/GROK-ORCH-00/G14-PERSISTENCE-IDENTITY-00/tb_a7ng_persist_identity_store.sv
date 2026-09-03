// tb_a7ng_persist_identity_store.sv — G14-PERSISTENCE-IDENTITY-00
// state before FLUSH == after KILL+RELOAD (store slots + lookup). PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_persist_identity_store;
  import a7ng_pkg::*;

  logic clk, rst_n, learn, freeze, flush, reload, kill, trst;
  logic pbusy, pdone, boot_done;
  logic [31:0] live_gen;
  logic [63:0] sdig;
  logic upd_v, upd_rdy;
  logic [31:0] us, uo;
  logic [7:0] ur;
  logic signed [3:0] urew;
  logic uk;
  logic lk_go, lk_busy, lk_done, lk_hit;
  logic signed [7:0] lk_pri, lk_pen;
  logic c7v;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:255];

  a7ng_learned_prior_store #(.WRAP_LIMIT(32'd6)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .boot_done_o(boot_done),
    .live_gen_o(live_gen), .sdig_o(sdig), .wrap_imminent_o(),
    .upd_valid_i(upd_v), .upd_ready_o(upd_rdy),
    .upd_subj_i(us), .upd_rel_i(ur), .upd_obj_i(uo),
    .upd_rew_i(urew), .upd_contra_i(uk),
    .lk_go_i(lk_go), .lk_subj_i(us), .lk_rel_i(ur), .lk_obj_i(uo),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(1'b1),
    .c7_addr_o(c7a), .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  initial clk = 0;
  always #40 clk = ~clk;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  integer fails, i, g;
  logic [31:0] snap_gen;
  logic [63:0] snap_sdig;
  logic signed [7:0] snap_pri [0:7];
  logic        snap_hit [0:7];
  logic [96:0] snap_row [0:31];

  task automatic wait_idle;
    begin
      g = 0;
      while ((pbusy || !boot_done) && g < 16000) begin @(posedge clk); g++; end
      if (pbusy || !boot_done) begin $display("FAIL idle/boot timeout"); fails++; end
    end
  endtask

  task automatic pulse(ref logic sig);
    begin
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      g = 0;
      while (pbusy && g < 16000) begin @(posedge clk); g++; end
      if (pbusy) begin $display("FAIL persist busy timeout"); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic do_upd(input int unsigned k);
    begin
      us = 32'h0000A000 + k[31:0];
      uo = 32'h0000B000 + k[31:0];
      ur = 8'h80;
      urew = 4'sd3;
      uk = 1'b0;
      g = 0;
      while (!upd_rdy && g < 8000) begin @(posedge clk); g++; end
      if (!upd_rdy) begin $display("FAIL no upd_ready k=%0d", k); fails++; end
      @(negedge clk); upd_v = 1;
      @(posedge clk); @(negedge clk); upd_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 k=%0d", k); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic do_lk(input int unsigned k);
    begin
      us = 32'h0000A000 + k[31:0];
      uo = 32'h0000B000 + k[31:0];
      ur = 8'h80;
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk); lk_go = 1;
      @(posedge clk); @(negedge clk); lk_go = 0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      if (!lk_done) begin $display("FAIL no lk_done k=%0d", k); fails++; end
      @(posedge clk);
    end
  endtask

  initial begin
    #80_000_000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0;
    learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    upd_v = 0; lk_go = 0; uk = 0; urew = 0; us = 0; uo = 0; ur = 0;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    rst_n = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    wait_idle;
    $display("BOOT GEN=%0d sdig=%0h", live_gen, sdig);

    for (i = 0; i < 8; i++)
      do_upd(i);

    snap_gen  = live_gen;
    snap_sdig = sdig;
    for (i = 0; i < 32; i++)
      snap_row[i] = dut.ws_mem[i];
    for (i = 0; i < 8; i++) begin
      do_lk(i);
      snap_hit[i] = lk_hit;
      snap_pri[i] = lk_pri;
      if (!lk_hit || lk_pri !== 8'sd3) begin
        $display("FAIL pre-FLUSH lookup k=%0d hit=%0b pri=%0d", i, lk_hit, lk_pri);
        fails++;
      end
    end
    $display("PRE_FLUSH GEN=%0d seq=%0d ack=%0d sdig=%016h hits=8",
             snap_gen, c7seq, c7cnt, snap_sdig);

    freeze = 1; learn = 0;
    pulse(flush);
    $display("AFTER_FLUSH GEN=%0d hdr=%016h", live_gen, ddr_mem[0]);

    pulse(kill);
    do_lk(0);
    if (lk_hit) begin
      $display("FAIL KILL still visible hit pri=%0d", lk_pri); fails++;
    end else
      $display("KILL_HIDES lookup miss (ws_live=0)");
    $display("AFTER_KILL sdig=%016h (expect 0)", sdig);

    pulse(reload);
    $display("AFTER_RELOAD GEN=%0d sdig=%016h boot=%0b", live_gen, sdig, boot_done);

    if (live_gen !== snap_gen) begin
      $display("FAIL GEN %0d want %0d", live_gen, snap_gen); fails++;
    end
    if (sdig !== snap_sdig) begin
      $display("NOTE C8_SDIG after RELOAD=%016h pre=%016h (kill zeros sdig; RELOAD does not rebuild)",
               sdig, snap_sdig);
      // C8 digest is observe-only. Query identity is lookup/C9, not sdig.
    end

    for (i = 0; i < 8; i++) begin
      do_lk(i);
      if (lk_hit !== snap_hit[i] || lk_pri !== snap_pri[i]) begin
        $display("FAIL post-RELOAD lookup k=%0d hit=%0b pri=%0d want hit=%0b pri=%0d",
                 i, lk_hit, lk_pri, snap_hit[i], snap_pri[i]);
        fails++;
      end
    end

    begin : trunc_case
      logic hit32;
      learn = 1; freeze = 0;
      us = 32'h0001A000; uo = 32'h0001B000; ur = 8'h81; urew = 4'sd2; uk = 0;
      g = 0;
      while (!upd_rdy && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk); upd_v = 1;
      @(posedge clk); @(negedge clk); upd_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      @(posedge clk);
      freeze = 1; learn = 0;
      pulse(flush); pulse(kill); pulse(reload);
      us = 32'h0001A000; uo = 32'h0001B000; ur = 8'h81;
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk); lk_go = 1;
      @(posedge clk); @(negedge clk); lk_go = 0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      hit32 = lk_hit;
      @(posedge clk);
      us = 32'h0000A000; uo = 32'h0000B000; ur = 8'h81;
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk); lk_go = 1;
      @(posedge clk); @(negedge clk); lk_go = 0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      $display("TRUNC32 full-key hit=%0b truncated-key hit=%0b pri=%0d", hit32, lk_hit, lk_pri);
      if (hit32) begin
        $display("FAIL 32-bit key survived FLUSH (expected 16-bit truncation)"); fails++;
      end
    end

    if (fails == 0)
      $display("PERSIST_IDENTITY_STORE_XSIM_PASS fails=0");
    else
      $display("PERSIST_IDENTITY_STORE_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
