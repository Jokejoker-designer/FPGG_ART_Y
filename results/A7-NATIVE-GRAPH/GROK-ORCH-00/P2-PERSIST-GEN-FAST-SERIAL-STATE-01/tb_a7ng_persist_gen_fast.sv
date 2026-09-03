// P2-PERSIST-GEN-FAST-SERIAL-STATE-01. PROGRAM=NO. UNIT=mapping.
// Same 7-cell oracle as FAST-00 (bit-exact ranks/scores/GEN/SDIG). Extra cycles OK.
`timescale 1ns / 1ps

module tb_a7ng_persist_gen_fast;
  import a7ng_pkg::*;
  localparam node_id_t KA = 32'h1000;
  localparam node_id_t KB = 32'h1008;

  logic clk, rst_n, learn, freeze;
  logic qv, qr, sv, sr;
  logic [7:0] qid, dig_cyc;
  node_id_t top_id [8];
  score_t   top_s  [8];
  logic [31:0] evs, evo, c7a, c8g;
  logic [7:0] evr;
  logic pending;
  logic [15:0] txn, echo;
  logic rew_v, echo_v, rew_rdy, ack_v, c5, c7v;
  logic signed [3:0] rew;
  logic [2:0] ack;
  logic [63:0] c8d;
  logic flush, reload, kill, trst, wimm, pbusy, pdone;
  logic ddr_req, ddr_we, ddr_ack;
  logic [4:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:31];

  a7ng_persist_gen_fast #(.WRAP_LIMIT(32'd6)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .query_valid_i(qv), .query_ready_o(qr), .query_id_i(qid),
    .snap_valid_o(sv), .snap_ready_i(sr),
    .topk_id_o(top_id), .topk_score_o(top_s),
    .ev_subj_o(evs), .ev_rel_o(evr), .ev_obj_o(evo),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_o(ack),
    .c5_consume_o(c5),
    .c7_ack_valid_o(c7v), .c7_ack_ready_i(1'b1), .c7_addr_o(c7a),
    .c8_gen_o(c8g), .c8_sdig_o(c8d), .dig_cyc_o(dig_cyc),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill),
    .train_reset_i(trst), .wrap_imminent_o(wimm),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  initial clk = 0;
  always #40 clk = ~clk;

  integer fails, i, rA, rB;
  logic signed [15:0] sA, sB;
  logic [63:0] adig, bdig, sdig0;
  logic [31:0] gen0;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we)
      ddr_mem[ddr_addr] <= ddr_wdata;
  end
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  function automatic int rank_of(input node_id_t id);
    rank_of = 0;
    for (int k = 0; k < 8; k++)
      if (top_id[k] == id) rank_of = k + 1;
  endfunction
  function automatic logic signed [15:0] score_of(input node_id_t id);
    score_of = 0;
    for (int k = 0; k < 8; k++)
      if (top_id[k] == id) score_of = top_s[k];
  endfunction

  task automatic wait_boot;
    integer g;
    begin
      g = 0;
      while ((!qr || pbusy) && g < 800) begin @(posedge clk); g++; end
      if (!qr) begin $display("FAIL boot/query_ready"); fails++; end
    end
  endtask

  task automatic pulse_persist(ref logic sig);
    integer g;
    begin
      g = 0;
      @(negedge clk); sig = 1'b1;
      @(posedge clk);
      @(negedge clk); sig = 1'b0;
      while (pbusy && g < 800) begin @(posedge clk); g = g + 1; end
      if (pbusy) begin $display("FAIL persist busy timeout"); fails = fails + 1; end
      @(posedge clk);
    end
  endtask

  task automatic do_query(input logic [7:0] q);
    integer g;
    begin
      g = 0;
      while (!qr && g < 800) begin @(posedge clk); g++; end
      @(negedge clk); qid = q; qv = 1;
      @(posedge clk); @(negedge clk); qv = 0;
      g = 0;
      while (!sv && g < 1200) begin @(posedge clk); g++; end
      if (!sv) begin $display("FAIL no snap q=%0d", q); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic send_rew(input logic signed [3:0] r);
    integer g;
    begin
      g = 0;
      while (!pending && g < 200) begin @(posedge clk); g++; end
      if (!pending) begin $display("FAIL no pending"); fails++; end
      @(negedge clk); rew = r; rew_v = 1; echo_v = 1; echo = txn;
      @(posedge clk); @(negedge clk); rew_v = 0; echo_v = 0;
      g = 0;
      while (!c7v && g < 400) begin @(posedge clk); g++; end
      if (!c7v) begin $display("FAIL no C7 ACK after reward"); fails++; end
    end
  endtask

  task automatic learn_map_a;
    begin
      do_query(8'd1);
      send_rew(4'sd3);
      @(posedge clk);
      do_query(8'd2);
    end
  endtask
  task automatic learn_map_b;
    begin
      do_query(8'd5);
      send_rew(4'sd3);
      @(posedge clk);
      do_query(8'd6);
    end
  endtask

  task automatic cell_rst;
    integer k;
    begin
      rst_n = 0; qv = 0; rew_v = 0; echo_v = 0; freeze = 0;
      flush = 0; reload = 0; kill = 0; trst = 0;
      for (k = 0; k < 32; k++) ddr_mem[k] = 64'd0;
      repeat (4) @(posedge clk);
      rst_n = 1;
      wait_boot;
    end
  endtask

  initial begin
    #20000000; $display("FAIL TB timeout"); $finish;
  end

  initial begin
    fails = 0; learn = 1; freeze = 0; sr = 1;
    qv = 0; rew_v = 0; echo_v = 0; flush = 0; reload = 0; kill = 0; trst = 0;
    rst_n = 0;
    for (i = 0; i < 32; i++) ddr_mem[i] = 0;
    repeat (3) @(posedge clk);

    cell_rst;
    learn_map_a;
    rA = rank_of(KA); sA = score_of(KA); gen0 = c8g; sdig0 = c8d;
    $display("FR A vis rank=%0d score=%0d GEN=%0d SDIG=%h", rA, sA, c8g, c8d);
    $display("DIG_CYC learn=%0d", dig_cyc);
    if (rA == 0 || sA <= 39 || c8g == 0 || $isunknown(c8d) || $isunknown(c8g))
      begin $display("FAIL FR A not visible"); fails++; end
    pulse_persist(flush);
    pulse_persist(kill);
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin
      $display("FAIL FR A still in BRAM after kill"); fails++;
    end
    pulse_persist(reload);
    wait_boot;
    do_query(8'd2);
    rB = rank_of(KA); sB = score_of(KA);
    $display("FR reload vis rank=%0d score=%0d GEN=%0d SDIG=%h", rB, sB, c8g, c8d);
    $display("DIG_CYC reload=%0d", dig_cyc);
    if (c8g != gen0 || c8g == 0 || $isunknown(c8g)) begin $display("FAIL FR GEN"); fails++; end
    if (c8d !== sdig0 || $isunknown(c8d)) begin $display("FAIL FR SDIG"); fails++; end
    if (rB == 0 || sB <= 39) begin $display("FAIL FR A lost"); fails++; end
    if (fails == 0) $display("CELL_FLUSH_RELOAD PASS");
    else $display("CELL_FLUSH_RELOAD FAIL");

    cell_rst;
    learn_map_a;
    gen0 = c8g; sdig0 = c8d; rA = rank_of(KA); sA = score_of(KA);
    do_query(8'd1);
    @(negedge clk);
    freeze = 1;
    rew = 4'sd2; rew_v = 1; echo_v = 1; echo = txn;
    @(posedge clk);
    @(negedge clk); rew_v = 0; echo_v = 0;
    begin : fz_ack
      integer ga;
      ga = 0;
      while (!ack_v && ga < 20) begin @(posedge clk); ga = ga + 1; end
      if (ack != 3'd5)
        begin $display("FAIL FZ ack=%0d want DROP=5", ack); fails++; end
    end
    begin : fz_c7
      integer gc7;
      for (gc7 = 0; gc7 < 8; gc7 = gc7 + 1) begin
        @(posedge clk);
        if (c7v) begin $display("FAIL FZ C7 write ACK under freeze"); fails++; end
      end
    end
    do_query(8'd2);
    if (c8g != gen0 || c8d !== sdig0) begin $display("FAIL FZ C8 moved"); fails++; end
    if (rank_of(KA) != rA || score_of(KA) != sA) begin $display("FAIL FZ C9 moved"); fails++; end
    freeze = 0;
    $display("CELL_FREEZE_BLOCKS_WRITE done ack=%0d", ack);

    cell_rst;
    learn_map_a;
    adig = c8d; gen0 = c8g;
    pulse_persist(trst);
    if (c8g != gen0 + 1 || c8g == 0) begin $display("FAIL TR GEN"); fails++; end
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin $display("FAIL TR A still visible"); fails++; end
    $display("TR GEN %0d->%0d Ascore=%0d", gen0, c8g, score_of(KA));
    $display("CELL_TRAIN_RESET_FORGETS_A done");

    cell_rst;
    learn_map_a; adig = c8d;
    pulse_persist(trst);
    learn_map_b; bdig = c8d;
    do_query(8'd6);
    rB = rank_of(KB); sB = score_of(KB);
    if (rB == 0 || sB <= 39) begin $display("FAIL B not visible rank=%0d score=%0d", rB, sB); fails++; end
    do_query(8'd2);
    if (rank_of(KA) != 0 && score_of(KA) > 39) begin $display("FAIL B retains A"); fails++; end
    if (adig === bdig || $isunknown(adig) || $isunknown(bdig)) begin $display("FAIL ADIG/BDIG"); fails++; end
    $display("ADIG=%h BDIG=%h Bscore=%0d Ascore_after=%0d", adig, bdig, sB, score_of(KA));
    $display("CELL_RUN_B_NE_A done");

    rst_n = 0; qv = 0;
    for (i = 0; i < 32; i++) ddr_mem[i] = 0;
    ddr_mem[1] = {KA, 8'sd99, 8'sd0, 8'd0, 8'd0};
    ddr_mem[0] = 64'd0;
    repeat (4) @(posedge clk); rst_n = 1; wait_boot;
    if (c8g == 0) begin $display("FAIL GEN0 live GEN=0"); fails++; end
    do_query(8'd2);
    if (score_of(KA) > 39) begin $display("FAIL GEN0 visible score=%0d", score_of(KA)); fails++; end
    $display("GEN0 GEN=%0d KAscore=%0d", c8g, score_of(KA));
    $display("CELL_GEN0_NEVER_VISIBLE done");

    cell_rst;
    learn_map_a;
    i = 0;
    while (!wimm && i < 12) begin
      pulse_persist(trst); i++;
    end
    if (!wimm) begin $display("FAIL wrap not imminent after bumps"); fails++; end
    pulse_persist(trst);
    if (c8g == 0) begin $display("FAIL wrap to GEN=0"); fails++; end
    do_query(8'd2);
    if (score_of(KA) > 39) begin $display("FAIL wrap resurrect A"); fails++; end
    $display("WRAP GEN=%0d wimm=%0b Ascore=%0d", c8g, wimm, score_of(KA));
    $display("CELL_ROOT_INVALIDATE_BEFORE_WRAP done");

    cell_rst;
    learn_map_a;
    gen0 = c8g; sdig0 = c8d; rA = rank_of(KA); sA = score_of(KA);
    pulse_persist(flush);
    rst_n = 0;
    repeat (4) @(posedge clk);
    rst_n = 1; wait_boot;
    if (c8g == 0) begin $display("FAIL PWR GEN=0"); fails++; end
    do_query(8'd2);
    $display("PWR GEN=%0d (pre %0d) rank=%0d score=%0d", c8g, gen0, rank_of(KA), score_of(KA));
    if (c8g != gen0) begin $display("FAIL PWR GEN restore"); fails++; end
    if (rank_of(KA) == 0 || score_of(KA) <= 39) begin $display("FAIL PWR A invisible"); fails++; end
    $display("CELL_POWER_REPROGRAM_AUTHORITY done");

    if (fails == 0)
      $display("PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7");
    else
      $display("PERSIST_GEN_FAST_SERIAL_STATE_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
