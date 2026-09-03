// tb_a7ng_pboot_dirty_ddr.sv — G14-DOWNSTREAM-P0-GEN-BOOT-00
// Prove P_BOOT header accept of dirty DDR vs zero DDR.
// PROGRAM=NO. No COM12. No oracle retarget.
`timescale 1ns / 1ps

module tb_a7ng_pboot_dirty_ddr;
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
  integer seq0, ack0;
  logic   hit0, hit1, hit2, hit3;
  logic signed [7:0] pri0;

  task automatic fill_ddr(input logic [63:0] hdr, input logic [63:0] data, input int unsigned n_zero_tail);
    begin
      for (i = 0; i < 256; i++) ddr_mem[i] = data;
      ddr_mem[0] = hdr;
      if (n_zero_tail > 0) begin
        for (i = 0; i < n_zero_tail; i++)
          ddr_mem[32 - i] = 64'd0;
      end
    end
  endtask

  task automatic wait_boot;
    begin
      g = 0;
      while ((!boot_done || pbusy) && g < 8000) begin @(posedge clk); g++; end
      if (!boot_done) begin $display("FAIL boot_done timeout"); fails++; end
    end
  endtask

  task automatic pulse(ref logic sig);
    begin
      g = 0;
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      while (pbusy && g < 16000) begin @(posedge clk); g++; end
      if (pbusy) begin $display("FAIL persist busy timeout"); fails++; end
      @(posedge clk);
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

  task automatic do_lk(input int unsigned fi, output logic hit, output logic signed [7:0] pri);
    begin
      g = 0;
      while ((pbusy || lk_busy) && g < 8000) begin @(posedge clk); g++; end
      @(negedge clk);
      ls = 32'hA000 + fi; lr = 8'd1; lo = 32'hB000 + fi; lk_go = 1'b1;
      @(posedge clk); @(negedge clk); lk_go = 1'b0;
      g = 0;
      while (!lk_done && g < 8000) begin @(posedge clk); g++; end
      if (!lk_done) begin $display("FAIL no lk_done fi=%0d", fi); fails++; end
      hit = lk_hit; pri = lk_pri;
      @(posedge clk);
    end
  endtask

  task automatic run_case(
      input string tag,
      input logic [63:0] hdr,
      input logic [63:0] data,
      input int unsigned n_zero_tail,
      input bit do_treset
  );
    begin
      $display("CASE %s hdr=%016h data=%016h zero_tail=%0d treset=%0d",
               tag, hdr, data, n_zero_tail, do_treset);
      learn = 1; freeze = 0; flush = 0; reload = 0; kill = 0; trst = 0;
      upd_v = 0; lk_go = 0; rst_n = 0;
      fill_ddr(hdr, data, n_zero_tail);
      repeat (4) @(posedge clk);
      rst_n = 1;
      wait_boot;
      $display("%s S0 GEN=%08h boot=%0d sdig=%0d wrap=%0d",
               tag, live_gen, boot_done, sdig, wrap_im);
      if (do_treset) begin
        pulse(trst);
        $display("%s AFTER_TRESET GEN=%08h sdig=%0d", tag, live_gen, sdig);
      end
      seq0 = c7seq; ack0 = c7cnt;
      for (i = 0; i < 20; i++)
        do_upd(i);
      $display("%s S20 ack=%0d seq=%0d dack=%0d dseq=%0d GEN=%08h sdig=%0d",
               tag, c7cnt, c7seq, c7cnt - ack0, c7seq - seq0, live_gen, sdig);
      do_lk(0, hit0, pri0);
      do_lk(1, hit1, pri0);
      do_lk(2, hit2, pri0);
      do_lk(3, hit3, pri0);
      $display("%s LK A0=%0d A1=%0d A2=%0d A3=%0d", tag, hit0, hit1, hit2, hit3);
    end
  endtask

  initial begin
    #8_000_000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0; c7r = 1;
    // Control: XSim-style empty DDR.
    run_case("ZERO", 64'd0, 64'd0, 0, 1);
    if (live_gen != 32'd2) begin
      $display("FAIL ZERO GEN=%0d want 2 (boot 1 + TRESET)", live_gen); fails++;
    end
    if ((c7seq - seq0) != 16'd20) begin
      $display("FAIL ZERO dseq=%0d want 20", c7seq - seq0); fails++;
    end
    if (!hit0 || !hit1 || !hit2 || !hit3) begin
      $display("FAIL ZERO lookup miss A0-3"); fails++;
    end

    // Silicon-like: all-ones header+payload.
    run_case("ONES", 64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF, 0, 1);
    $display("ONES_CONTRACT gen_ff=%0d dseq=%0d hits=%0d%0d%0d%0d",
             (live_gen == 32'hFFFFFFFF), (c7seq - seq0), hit0, hit1, hit2, hit3);
    if (live_gen == 32'hFFFFFFFF) begin
      $display("FAIL ONES still accepted GEN=FFFFFFFF"); fails++;
    end
    if ((c7seq - seq0) != 16'd20) begin
      $display("FAIL ONES dseq=%0d want 20 after header reject", c7seq - seq0); fails++;
    end
    if (!hit0 || !hit1 || !hit2 || !hit3) begin
      $display("FAIL ONES lookup miss A0-3 after header reject"); fails++;
    end

    // Constructed 30 vis_w + 2 free (stamp 0xFF occupiers).
    run_case("TWO_FREE", 64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF, 2, 1);
    $display("TWO_FREE_CONTRACT gen_ff=%0d dseq=%0d hits=%0d%0d%0d%0d",
             (live_gen == 32'hFFFFFFFF), (c7seq - seq0), hit0, hit1, hit2, hit3);
    if (live_gen == 32'hFFFFFFFF) begin
      $display("FAIL TWO_FREE still accepted GEN=FFFFFFFF"); fails++;
    end
    if ((c7seq - seq0) != 16'd20) begin
      $display("FAIL TWO_FREE dseq=%0d want 20 after header reject", c7seq - seq0); fails++;
    end
    if (!hit0 || !hit1 || !hit2 || !hit3) begin
      $display("FAIL TWO_FREE lookup miss A0-3 after header reject"); fails++;
    end

    // Legal FLUSH header must still restore.
    run_case("LEGAL", {31'd0, 32'd3, 1'b1}, 64'd0, 0, 0);
    if (live_gen != 32'd3) begin
      $display("FAIL LEGAL GEN=%0d want 3", live_gen); fails++;
    end

    if (fails == 0)
      $display("PBOOT_DIRTY_DDR_XSIM_PASS fails=0");
    else
      $display("PBOOT_DIRTY_DDR_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
