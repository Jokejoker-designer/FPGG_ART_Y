// tb_a7ng_reset_retrain_c9.sv — G14-RESET-RETRAIN-00
// Semantic A → RESET → B → A not resurrected. C9 + slot vis. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_reset_retrain_c9;
  import a7ng_pkg::*;

  logic clk, rst_n, learn, freeze;
  logic qv, qr, sv, sr;
  logic [7:0] qid;
  node_id_t top_id [8];
  score_t   top_s  [8];
  logic [63:0] c3p, c9p;
  logic pending;
  logic [15:0] txn, echo, c7seq, c7cnt;
  logic rew_v, echo_v, rew_rdy, ack_v, c5, c7v;
  logic signed [3:0] rew;
  logic [2:0] ack;
  logic [31:0] c7a, c8g;
  logic [63:0] c8d;
  logic flush, reload, kill, trst, pbusy, pdone;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:255];

  localparam logic [63:0] C9_HOLD_A = 64'h8382238122802120;
  localparam logic [63:0] C9_HOLD_B = 64'h8382438142804140;
  localparam logic [63:0] C9_FORGET = 64'h2322832182208180;

  a7ng_learned_prior_graph #(.WRAP_LIMIT(32'd6)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .query_valid_i(qv), .query_ready_o(qr), .query_id_i(qid),
    .snap_valid_o(sv), .snap_ready_i(sr),
    .topk_id_o(top_id), .topk_score_o(top_s),
    .c3_pack_o(c3p), .c9_pack_o(c9p),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_o(ack),
    .c5_consume_o(c5),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(1'b1),
    .c7_addr_o(c7a), .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
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

  integer fails, i, g, n_occ, n_vis, n_stale;
  string first_div;
  logic [31:0] gen_base, gen_a, gen_rst, gen_b;
  logic [15:0] seq_a, seq_rst, seq_b;
  logic [63:0] c9_base, c9_a, c9_rst, c9_b, c9_a2;
  logic [96:0] row;
  logic occ;
  logic [7:0] stmp, rel, pri, pen;
  logic [31:0] subj, obj;

  task automatic stop_div(input string tag);
    begin
      first_div = tag;
      fails++;
      $display("FIRST_DIVERGENCE=%s", tag);
      $display("RESET_RETRAIN_C9_XSIM_FAIL fails=%0d", fails);
      $finish;
    end
  endtask

  task automatic wait_boot;
    begin
      g = 0;
      while ((!qr || pbusy) && g < 8000) begin @(posedge clk); g++; end
      if (!qr) stop_div("BOOT");
    end
  endtask

  task automatic pulse_persist(ref logic sig);
    begin
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      g = 0;
      while (pbusy && g < 16000) begin @(posedge clk); g++; end
      if (pbusy) stop_div("PERSIST_BUSY");
      @(posedge clk);
    end
  endtask

  task automatic do_exam(input logic [7:0] q);
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      if (!qr) stop_div("NO_QR");
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!sv && g < 20000) begin @(posedge clk); g++; end
      if (!sv) stop_div("NO_SNAP");
      @(posedge clk);
    end
  endtask

  task automatic lesson(input logic [7:0] q);
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      if (!qr) stop_div("NO_QR_LESSON");
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!pending && g < 4000) begin @(posedge clk); g++; end
      if (!pending) stop_div("NO_PENDING");
      @(negedge clk); rew = 4'sd3; rew_v = 1; echo_v = 1; echo = txn;
      @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) stop_div("NO_C7");
      @(posedge clk);
    end
  endtask

  task automatic dump_slots(input string tag);
    begin
      n_occ = 0; n_vis = 0; n_stale = 0;
      for (i = 0; i < 32; i++) begin
        row  = dut.u_st.ws_mem[i];
        occ  = row[96];
        stmp = row[95:88];
        pen  = row[87:80];
        pri  = row[79:72];
        rel  = row[71:64];
        obj  = row[63:32];
        subj = row[31:0];
        if (occ) n_occ++;
        if (occ && (stmp == c8g[7:0]) && (stmp != 8'd0) && (c8g != 32'd0)) begin
          n_vis++;
          $display("VIS %s sl=%0d s=%h r=%h o=%h pri=%0d pen=%0d stmp=%h GEN=%0d",
                   tag, i, subj, rel, obj, $signed(pri), $signed(pen), stmp, c8g);
        end else if (occ && (stmp != c8g[7:0])) begin
          n_stale++;
        end
      end
      $display("SLOTS %s GEN=%0d seq=%0d ack=%0d n_occ=%0d n_vis=%0d n_stale=%0d C9=%016h",
               tag, c8g, c7seq, c7cnt, n_occ, n_vis, n_stale, c9p);
    end
  endtask

  initial begin
    #120_000_000; stop_div("WATCHDOG");
  end

  initial begin
    fails = 0; first_div = "NONE";
    learn = 1; freeze = 0; sr = 1;
    qv = 0; rew_v = 0; echo_v = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    rst_n = 0;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    wait_boot;
    pulse_persist(trst);
    gen_base = c8g;
    freeze = 1; learn = 0;
    do_exam(8'd2);
    c9_base = c9p;
    dump_slots("BASELINE");
    $display("PHASE BASELINE GEN=%0d C9=%016h", gen_base, c9_base);
    if (c9_base == C9_HOLD_A) stop_div("BASELINE_A_ALREADY_VISIBLE");

    freeze = 0; learn = 1;
    for (i = 0; i < 20; i++)
      lesson(8'h10 + i[7:0]);
    freeze = 1; learn = 0;
    do_exam(8'd2);
    c9_a  = c9p;
    gen_a = c8g;
    seq_a = c7seq;
    dump_slots("A_VISIBLE");
    $display("PHASE A_VISIBLE GEN=%0d seq=%0d C9=%016h", gen_a, seq_a, c9_a);
    if (c9_a != C9_HOLD_A) stop_div("A_NOT_VISIBLE_AFTER_TRAIN");
    if (seq_a != 16'd20) stop_div("A_COMMIT_SEQ");
    if (n_vis != 20) stop_div("A_VIS_COUNT");

    pulse_persist(trst);
    gen_rst = c8g;
    seq_rst = c7seq;
    do_exam(8'd2);
    c9_rst = c9p;
    dump_slots("A_NOT_VISIBLE");
    $display("PHASE RESET GEN %0d→%0d C9=%016h", gen_a, gen_rst, c9_rst);
    if (gen_rst != gen_a + 32'd1) stop_div("TRESET_GEN_STEP");
    if (c9_rst == C9_HOLD_A) stop_div("A_STILL_VISIBLE_AFTER_RESET");
    if (n_vis != 0) stop_div("STALE_EPOCH_A_STILL_VIS");

    freeze = 0; learn = 1;
    for (i = 0; i < 20; i++)
      lesson(8'h30 + i[7:0]);
    freeze = 1; learn = 0;
    do_exam(8'd6);
    c9_b  = c9p;
    gen_b = c8g;
    seq_b = c7seq;
    dump_slots("B_VISIBLE");
    $display("PHASE B_VISIBLE GEN=%0d seq=%0d C9=%016h", gen_b, seq_b, c9_b);
    if (c9_b != C9_HOLD_B) stop_div("B_NOT_VISIBLE");
    if (seq_b != 16'd40) stop_div("B_COMMIT_SEQ");
    if (n_vis != 20) stop_div("B_VIS_COUNT");
    if (gen_b != gen_rst) stop_div("B_GEN_DRIFT");

    do_exam(8'd2);
    c9_a2 = c9p;
    dump_slots("A_NOT_RESURRECTED");
    $display("PHASE A_NOT_RESURRECTED HOLD_A C9=%016h", c9_a2);
    if (c9_a2 == C9_HOLD_A) stop_div("A_RESURRECTED");

    $display("FIRST_DIVERGENCE=NONE");
    $display("RESET_RETRAIN_C9_XSIM_PASS fails=0");
    $finish;
  end
endmodule
