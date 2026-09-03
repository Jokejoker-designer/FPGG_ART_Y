// tb_a7ng_learned_prior_graph.sv — P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03
// 20 distinct facts. PROGRAM=NO. No COM12. Host reward + txn echo only.
`timescale 1ns / 1ps

module tb_a7ng_learned_prior_graph;
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
  logic [63:0] ddr_mem [0:127];

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
  logic [15:0] cnt0;
  logic [63:0] hold_a_c3, hold_a_c9, unrel_c3, unrel_c9, contra_c9, hold_b_c9;
  logic [7:0] r1;

  task automatic wait_boot;
    begin
      g = 0;
      while ((!qr || pbusy) && g < 4000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL boot/query_ready"); fails++; end
    end
  endtask

  task automatic pulse_persist(ref logic sig);
    begin
      g = 0;
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      while (pbusy && g < 8000) begin @(posedge clk); g++; end
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

  task automatic lesson(input logic [7:0] q, input int unsigned want_cnt);
    begin
      g = 0;
      while (!qr && g < 8000) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL no qr lesson %0h", q); fails++; end
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!pending && g < 2000) begin @(posedge clk); g++; end
      if (!pending) begin $display("FAIL no pending q=%0h", q); fails++; end
      @(negedge clk); rew = 4'sd3; rew_v = 1; echo_v = 1; echo = txn;
      @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
      g = 0;
      while (!c7v && g < 8000) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 q=%0h txn=%0h", q, txn); fails++; end
      if (c7cnt != want_cnt[15:0]) begin
        $display("FAIL C7 ack_count=%0d want=%0d q=%0h", c7cnt, want_cnt, q);
        fails++;
      end
      if (c7seq == 16'd0) begin $display("FAIL commit_seq=0 q=%0h", q); fails++; end
      if (c7a == 32'd0) begin $display("FAIL C7 addr=0 q=%0h", q); fails++; end
      @(posedge clk);
    end
  endtask

  initial begin
    #40000000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0; learn = 1; freeze = 0; sr = 1;
    qv = 0; rew_v = 0; echo_v = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    rst_n = 0;
    for (i = 0; i < 128; i++) ddr_mem[i] = 64'd0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    wait_boot;

    cnt0 = c7cnt;
    for (i = 0; i < 20; i++)
      lesson(8'h10 + i[7:0], cnt0 + i + 1);
    if (c7cnt != 16'd20) begin $display("FAIL A ack_count=%0d", c7cnt); fails++; end
    $display("A_TRAIN_OK ack=%0d seq=%0d GEN=%0d", c7cnt, c7seq, c8g);

    pulse_persist(flush);
    pulse_persist(kill);
    do_exam(8'd2);
    $display("AFTER_KILL HOLD_A C9=%016h r1=%0h (expect unrel 80 if kill hides)", c9p, c9p[7:0]);
    pulse_persist(reload);
    wait_boot;

    freeze = 1; learn = 0;
    do_exam(8'd2);
    hold_a_c3 = c3p; hold_a_c9 = c9p;
    r1 = c9p[7:0];
    $display("HOLD_A C3=%016h C9=%016h r1=%0h GEN=%0d", c3p, c9p, r1, c8g);
    if (c3p[7:0] != 8'h80) begin $display("FAIL C3 r1=%0h want 80", c3p[7:0]); fails++; end
    if (r1 != 8'h20) begin $display("FAIL C9 r1=%0h want 20 (A0)", r1); fails++; end
    if (c9p == c3p) begin $display("FAIL C9==C3 no movement"); fails++; end

    do_exam(8'd3);
    unrel_c3 = c3p; unrel_c9 = c9p;
    $display("UNREL C3=%016h C9=%016h", c3p, c9p);
    if (unrel_c9 != unrel_c3) begin $display("FAIL UNREL C9 moved"); fails++; end
    if (unrel_c9[7:0] < 8'h80) begin $display("FAIL UNREL r1 not U"); fails++; end

    do_exam(8'd4);
    contra_c9 = c9p;
    $display("CONTRA C9=%016h r1=%0h", c9p, c9p[7:0]);
    if (c9p[7:0] == hold_a_c9[7:0]) begin $display("FAIL typed R CONTRA==HOLD_A"); fails++; end
    if (c9p[7:0] != 8'h80) begin $display("FAIL CONTRA r1=%0h want 80", c9p[7:0]); fails++; end

    freeze = 0; learn = 1;
    pulse_persist(trst);
    if (c8g == 32'd0) begin $display("FAIL GEN=0 after TRESET"); fails++; end
    $display("TRESET GEN=%0d", c8g);
    freeze = 1; learn = 0;
    do_exam(8'd2);
    $display("FORGET HOLD_A C9=%016h r1=%0h", c9p, c9p[7:0]);
    if (c9p[7:0] != 8'h80) begin $display("FAIL A not forgotten r1=%0h", c9p[7:0]); fails++; end

    freeze = 0; learn = 1;
    cnt0 = c7cnt;
    for (i = 0; i < 20; i++)
      lesson(8'h30 + i[7:0], cnt0 + i + 1);
    if (c7cnt != 16'd40) begin $display("FAIL B ack_count=%0d", c7cnt); fails++; end
    pulse_persist(flush);
    freeze = 1; learn = 0;
    do_exam(8'd6);
    hold_b_c9 = c9p;
    $display("HOLD_B C9=%016h r1=%0h", c9p, c9p[7:0]);
    if (c9p[7:0] != 8'h40) begin $display("FAIL HOLD_B r1=%0h want 40", c9p[7:0]); fails++; end
    if (hold_b_c9 == hold_a_c9) begin $display("FAIL B pack == A pack"); fails++; end

    $display("C9PACK HOLD_A %016h", hold_a_c9);
    $display("C9PACK UNREL %016h", unrel_c9);
    $display("C9PACK CONTRA %016h", contra_c9);
    $display("C9PACK HOLD_B %016h", hold_b_c9);

    if (fails == 0)
      $display("C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0 facts=20");
    else
      $display("C9_LEARNED_PRIOR_GRAPH_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
