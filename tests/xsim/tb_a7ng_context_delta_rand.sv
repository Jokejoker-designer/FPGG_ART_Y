// PHASE2-G2-CONTEXT-DELTA-RTL-00 random 100k accepted-txn oracle. PROGRAM=NO.
// Independent signed oracle. Random input gaps and output backpressure.
`timescale 1ns / 1ps

module tb_a7ng_context_delta_rand;
  localparam int unsigned TXN_W     = 16;
  localparam int unsigned N_ACCEPT  = 100000;
  localparam int unsigned MAX_CYC   = 2000000;
  localparam int unsigned QMAX      = 4;

  logic clk, rst_n;
  logic in_valid, in_ready, out_valid, out_ready, sat_flag;
  logic signed [3:0] in_reward, out_reward;
  logic [15:0] in_conf, out_conf, in_qe, in_pe, out_qe, out_pe;
  logic [31:0] in_subj, in_obj, out_subj, out_obj;
  logic [7:0]  in_rel, out_rel;
  logic        in_k, out_k;
  logic [TXN_W-1:0] in_txn, out_txn;
  logic signed [15:0] delta;

  a7ng_context_delta #(.TXN_W(TXN_W)) dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(in_valid), .in_ready(in_ready),
    .in_reward(in_reward), .in_native_conf(in_conf),
    .in_subj(in_subj), .in_rel(in_rel), .in_obj(in_obj),
    .in_q_epoch(in_qe), .in_p_epoch(in_pe),
    .in_contradict(in_k), .in_txn(in_txn),
    .out_valid(out_valid), .out_ready(out_ready),
    .delta_o(delta), .sat_flag_o(sat_flag),
    .out_reward(out_reward), .out_native_conf(out_conf),
    .out_subj(out_subj), .out_rel(out_rel), .out_obj(out_obj),
    .out_q_epoch(out_qe), .out_p_epoch(out_pe),
    .out_contradict(out_k), .out_txn(out_txn)
  );

  initial clk = 1'b0;
  always #40 clk = ~clk;

  integer seed, fails, cyc, n_in, n_out, n_stall, n_gap, qn, qi, qo;
  integer mismatch, extra, loss, reorder, stale, sat_bad;
  logic prev_ov, prev_or;
  logic signed [15:0] prev_d, hold_d;
  logic [31:0] prev_s, prev_o, hold_s, hold_o;
  logic [7:0]  prev_rel, hold_rel;
  logic [15:0] prev_qe, prev_pe, prev_c, hold_qe, hold_pe, hold_c;
  logic        prev_k, hold_k, prev_sat, hold_sat;
  logic [TXN_W-1:0] prev_txn, hold_txn;
  logic signed [3:0] prev_r, hold_r;

  typedef struct packed {
    logic signed [15:0] d;
    logic signed [3:0]  r;
    logic [15:0]        c;
    logic [31:0]        s;
    logic [7:0]         rel;
    logic [31:0]        o;
    logic [15:0]        qe;
    logic [15:0]        pe;
    logic               k;
    logic [TXN_W-1:0]   txn;
    logic               sat;
  } rec_t;

  rec_t q [0:QMAX-1];

  function automatic integer rnd();
    begin
      seed = seed * 32'd1103515245 + 32'd12345;
      rnd  = seed;
    end
  endfunction

  function automatic logic signed [3:0] legal_reward(input integer x);
    integer m;
    begin
      m = x % 7;
      if (m < 0) m = m + 7;
      legal_reward = $signed(m - 3); // {-3..+3}
    end
  endfunction

  function automatic logic signed [15:0] oracle(
      input logic signed [3:0] r,
      input logic [15:0] c
  );
    logic signed [31:0] prod, sh;
    begin
      prod = $signed({{28{r[3]}}, r}) * $signed({16'b0, c});
      sh   = prod >>> 8;
      if (sh > 32'sd32767)       oracle = 16'sd32767;
      else if (sh < -32'sd32768) oracle = -16'sd32768;
      else                       oracle = sh[15:0];
    end
  endfunction

  function automatic logic oracle_sat(input logic signed [3:0] r, input logic [15:0] c);
    logic signed [31:0] prod, sh;
    begin
      prod = $signed({{28{r[3]}}, r}) * $signed({16'b0, c});
      sh   = prod >>> 8;
      oracle_sat = (sh > 32'sd32767) || (sh < -32'sd32768);
    end
  endfunction

  initial begin
    seed = 32'hC0DE_DA7A;
    fails = 0; cyc = 0; n_in = 0; n_out = 0; n_stall = 0; n_gap = 0;
    qn = 0; qi = 0; qo = 0;
    mismatch = 0; extra = 0; loss = 0; reorder = 0; stale = 0; sat_bad = 0;
    rst_n = 1'b0;
    in_valid = 1'b0; out_ready = 1'b0;
    in_reward = 4'sd0; in_conf = 16'd0;
    in_subj = 32'd0; in_rel = 8'd0; in_obj = 32'd0;
    in_qe = 16'd0; in_pe = 16'd0; in_k = 1'b0; in_txn = '0;
    prev_ov = 1'b0; prev_or = 1'b0;
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    while ((n_in < N_ACCEPT) && (cyc < MAX_CYC)) begin
      @(negedge clk);
      if ((rnd() & 32'h3) != 0) begin
        in_valid  = 1'b1;
        in_reward = legal_reward(rnd());
        in_conf   = rnd()[15:0];
        in_subj   = rnd();
        in_rel    = rnd()[7:0];
        in_obj    = rnd();
        in_qe     = rnd()[15:0];
        in_pe     = rnd()[15:0];
        in_k      = rnd()[0];
        in_txn    = rnd()[TXN_W-1:0];
      end else begin
        in_valid = 1'b0;
        n_gap    = n_gap + 1;
      end
      // Multi-cycle backpressure: ~4/11 ready-low windows, not LSB-correlated.
      if ((cyc % 11) < 4)
        out_ready = 1'b0;
      else
        out_ready = (rnd() & 32'h1) != 0;
      @(posedge clk);
      cyc = cyc + 1;

      if (rst_n && prev_ov && !prev_or) begin
        n_stall = n_stall + 1;
        if (delta !== hold_d || out_subj !== hold_s || out_obj !== hold_o ||
            out_rel !== hold_rel || out_qe !== hold_qe || out_pe !== hold_pe ||
            out_conf !== hold_c || out_k !== hold_k || out_txn !== hold_txn ||
            out_reward !== hold_r || sat_flag !== hold_sat || !out_valid) begin
          stale = stale + 1;
          fails = fails + 1;
        end
      end

      if (in_valid && in_ready) begin
        if (qn >= QMAX) begin
          $display("FAIL queue overflow"); fails = fails + 1;
        end else begin
          q[qi].d   = oracle(in_reward, in_conf);
          q[qi].r   = in_reward;
          q[qi].c   = in_conf;
          q[qi].s   = in_subj;
          q[qi].rel = in_rel;
          q[qi].o   = in_obj;
          q[qi].qe  = in_qe;
          q[qi].pe  = in_pe;
          q[qi].k   = in_k;
          q[qi].txn = in_txn;
          q[qi].sat = oracle_sat(in_reward, in_conf);
          qi = (qi + 1) % QMAX;
          qn = qn + 1;
          n_in = n_in + 1;
        end
      end

      if (out_valid && out_ready) begin
        if (qn == 0) begin
          extra = extra + 1;
          fails = fails + 1;
          $display("FAIL output without accepted input cyc=%0d", cyc);
        end else begin
          if (delta !== q[qo].d || out_reward !== q[qo].r || out_conf !== q[qo].c ||
              out_subj !== q[qo].s || out_rel !== q[qo].rel || out_obj !== q[qo].o ||
              out_qe !== q[qo].qe || out_pe !== q[qo].pe || out_k !== q[qo].k ||
              out_txn !== q[qo].txn) begin
            mismatch = mismatch + 1;
            fails = fails + 1;
            if (mismatch < 8)
              $display("FAIL mismatch cyc=%0d got_d=%0d exp_d=%0d txn_got=%h txn_exp=%h",
                       cyc, delta, q[qo].d, out_txn, q[qo].txn);
          end
          if (sat_flag !== q[qo].sat) begin
            sat_bad = sat_bad + 1;
            fails = fails + 1;
          end
          if ((q[qo].r == 4'sd3) && (q[qo].c == 16'd65535) && (delta === 16'sd768)) begin
            $display("FAIL random hit +768"); fails = fails + 1;
          end
          qo = (qo + 1) % QMAX;
          qn = qn - 1;
          n_out = n_out + 1;
        end
      end

      if (out_valid) begin
        hold_d = delta; hold_s = out_subj; hold_o = out_obj; hold_rel = out_rel;
        hold_qe = out_qe; hold_pe = out_pe; hold_c = out_conf; hold_k = out_k;
        hold_txn = out_txn; hold_r = out_reward; hold_sat = sat_flag;
      end
      prev_ov = out_valid;
      prev_or = out_ready;
    end

    // Drop input only on negedge so DUT already sampled the last accept.
    @(negedge clk);
    in_valid = 1'b0;
    out_ready = 1'b0;
    for (cyc = 0; (qn > 0) && (cyc < 128); cyc = cyc + 1) begin
      @(negedge clk);
      out_ready = (cyc > 8);
      @(posedge clk);
      if (rst_n && prev_ov && !prev_or) begin
        if (delta !== hold_d || out_txn !== hold_txn) begin
          stale = stale + 1; fails = fails + 1;
        end
      end
      if (out_valid && out_ready) begin
        if (qn == 0) begin extra = extra + 1; fails = fails + 1; end
        else begin
          if (delta !== q[qo].d || out_txn !== q[qo].txn) begin
            mismatch = mismatch + 1; fails = fails + 1;
          end
          qo = (qo + 1) % QMAX;
          qn = qn - 1;
          n_out = n_out + 1;
        end
      end
      if (out_valid) begin
        hold_d = delta; hold_txn = out_txn;
      end
      prev_ov = out_valid;
      prev_or = out_ready;
    end

    if (qn != 0)
      $display("DRAIN leftover qn=%0d out_valid=%0b delta=%0d txn=%h", qn, out_valid, delta, out_txn);
    if (n_in != n_out) begin
      loss = 1;
      fails = fails + 1;
    end
    if (qn != 0) begin
      loss = 1;
      fails = fails + 1;
    end
    if (n_in < N_ACCEPT) begin
      $display("FAIL accepted short n_in=%0d", n_in);
      fails = fails + 1;
    end

    // Post-reset: no stale from last window
    rst_n = 1'b0;
    in_valid = 1'b0; out_ready = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);
    if (out_valid) begin
      stale = stale + 1; fails = fails + 1;
      $display("FAIL stale after final reset");
    end

    $display("RAND n_in=%0d n_out=%0d n_stall=%0d n_gap=%0d mismatch=%0d extra=%0d loss=%0d stale=%0d sat_bad=%0d seed=%08h",
             n_in, n_out, n_stall, n_gap, mismatch, extra, loss, stale, sat_bad, 32'hC0DEDA7A);
    if (fails == 0)
      $display("CONTEXT_DELTA_RAND_XSIM_PASS MISMATCH_COUNT=0 n_in=%0d n_out=%0d", n_in, n_out);
    else
      $display("CONTEXT_DELTA_RAND_XSIM_FAIL fails=%0d MISMATCH_COUNT=%0d", fails, mismatch);
    $finish;
  end
endmodule
