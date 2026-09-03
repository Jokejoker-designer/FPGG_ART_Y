// tb_a7ng_persist_identity_c9.sv — G14-PERSISTENCE-IDENTITY-00
// HOLD_A C9 before FLUSH == after KILL+RELOAD. PROGRAM=NO. Oracle frozen.
`timescale 1ns / 1ps

module tb_a7ng_persist_identity_c9;
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

  integer fails, i, g;
  logic [63:0] c9_pre, c9_kill, c9_post;
  logic [31:0] gen_pre;

  task automatic wait_boot;
    begin
      g = 0;
      while ((!qr || pbusy) && g < 8000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL boot/query_ready"); fails++; end
    end
  endtask

  task automatic pulse_persist(ref logic sig);
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

  task automatic do_exam(input logic [7:0] q);
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL no qr exam %0h", q); fails++; end
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!sv && g < 20000) begin @(posedge clk); g++; end
      if (!sv) begin $display("FAIL no snap exam %0h", q); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic lesson(input logic [7:0] q);
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL no qr lesson %0h", q); fails++; end
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!pending && g < 4000) begin @(posedge clk); g++; end
      if (!pending) begin $display("FAIL no pending q=%0h", q); fails++; end
      @(negedge clk); rew = 4'sd3; rew_v = 1; echo_v = 1; echo = txn;
      @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 q=%0h", q); fails++; end
      @(posedge clk);
    end
  endtask

  initial begin
    #120_000_000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0;
    learn = 1; freeze = 0; sr = 1;
    qv = 0; rew_v = 0; echo_v = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    rst_n = 0;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    wait_boot;
    $display("BOOT GEN=%08h", c8g);
    pulse_persist(trst);
    for (i = 0; i < 20; i++)
      lesson(8'h10 + i[7:0]);
    freeze = 1; learn = 0;
    do_exam(8'd2);
    c9_pre  = c9p;
    gen_pre = c8g;
    $display("PRE_FLUSH HOLD_A C9=%016h GEN=%08h seq=%0d ack=%0d",
             c9_pre, gen_pre, c7seq, c7cnt);
    if (c9_pre != C9_HOLD_A) begin
      $display("FAIL PRE_FLUSH C9 not oracle"); fails++;
    end

    pulse_persist(flush);
    pulse_persist(kill);
    do_exam(8'd2);
    c9_kill = c9p;
    $display("AFTER_KILL HOLD_A C9=%016h (must not keep PRE C9 if vis hidden)", c9_kill);
    if (c9_kill == c9_pre) begin
      $display("FAIL KILL still query-visible C9"); fails++;
    end

    pulse_persist(reload);
    do_exam(8'd2);
    c9_post = c9p;
    $display("AFTER_RELOAD HOLD_A C9=%016h GEN=%08h sdig=%016h", c9_post, c8g, c8d);
    if (c8g !== gen_pre) begin
      $display("FAIL GEN %08h want %08h", c8g, gen_pre); fails++;
    end
    if (c9_post != c9_pre) begin
      $display("FAIL C9 identity pre=%016h post=%016h", c9_pre, c9_post); fails++;
    end

    if (fails == 0)
      $display("PERSIST_IDENTITY_C9_XSIM_PASS fails=0");
    else
      $display("PERSIST_IDENTITY_C9_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
