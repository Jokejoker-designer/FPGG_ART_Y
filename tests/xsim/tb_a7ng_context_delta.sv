// PHASE2-G2-CONTEXT-DELTA-RTL-00 directed table. PROGRAM=NO. Not on SoC.
// TB models FPGA G1 consume output. No host delta/index/address authority.
`timescale 1ns / 1ps

module tb_a7ng_context_delta;
  localparam int unsigned TXN_W = 16;

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

  // 12.5 MHz core-clock contract: period 80 ns
  initial clk = 1'b0;
  always #40 clk = ~clk;

  integer fails, n_in, n_out, i, stall;
  logic signed [15:0] hold_d;
  logic [31:0] hold_s, hold_o;
  logic [7:0]  hold_rel;
  logic [15:0] hold_qe, hold_pe, hold_c;
  logic        hold_k, hold_sat;
  logic [TXN_W-1:0] hold_txn;
  logic signed [3:0] hold_r;

  function automatic logic signed [15:0] oracle(
      input logic signed [3:0] r,
      input logic [15:0] c
  );
    logic signed [31:0] prod, sh;
    begin
      prod = $signed({{28{r[3]}}, r}) * $signed({16'b0, c});
      sh   = prod >>> 8;
      if (sh > 32'sd32767)      oracle = 16'sd32767;
      else if (sh < -32'sd32768) oracle = -16'sd32768;
      else                       oracle = sh[15:0];
    end
  endfunction

  task automatic apply_reset;
    begin
      rst_n = 1'b0;
      in_valid = 1'b0;
      out_ready = 1'b0;
      in_reward = 4'sd0;
      in_conf = 16'd0;
      in_subj = 32'd0; in_rel = 8'd0; in_obj = 32'd0;
      in_qe = 16'd0; in_pe = 16'd0; in_k = 1'b0; in_txn = '0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
      if (out_valid) begin
        $display("FAIL stale out_valid after reset");
        fails = fails + 1;
      end
    end
  endtask

  task automatic idle_n(input integer n);
    integer k;
    begin
      in_valid = 1'b0;
      out_ready = 1'b0;
      for (k = 0; k < n; k = k + 1) begin
        @(posedge clk);
        if (out_valid) begin
          $display("FAIL unexpected out_valid during idle");
          fails = fails + 1;
        end
      end
    end
  endtask

  task automatic stim_row(
      input logic signed [3:0] r,
      input logic [15:0] c,
      input logic signed [15:0] exp_d,
      input logic [31:0] s,
      input logic [7:0] rel,
      input logic [31:0] o,
      input logic [15:0] qe,
      input logic [15:0] pe,
      input logic k,
      input logic [TXN_W-1:0] txn
  );
    logic signed [15:0] exp_or;
    begin
      exp_or = oracle(r, c);
      if (exp_or !== exp_d) begin
        $display("FAIL oracle vs table r=%0d c=%0d oracle=%0d table=%0d", r, c, exp_or, exp_d);
        fails = fails + 1;
      end
      @(negedge clk);
      in_valid = 1'b1;
      in_reward = r;
      in_conf = c;
      in_subj = s; in_rel = rel; in_obj = o;
      in_qe = qe; in_pe = pe; in_k = k; in_txn = txn;
      out_ready = 1'b0;
      @(posedge clk);
      while (!(in_valid && in_ready)) @(posedge clk);
      n_in = n_in + 1;
      @(negedge clk);
      in_valid = 1'b0;
      @(posedge clk);
      if (!out_valid) begin
        $display("FAIL no out_valid after accept r=%0d c=%0d", r, c);
        fails = fails + 1;
      end
      if (delta !== exp_d) begin
        $display("FAIL delta r=%0d c=%0d got=%0d exp=%0d", r, c, delta, exp_d);
        fails = fails + 1;
      end
      if ((r == 4'sd3) && (c == 16'd65535) && (delta === 16'sd768)) begin
        $display("FAIL +3 x 65535 produced +768");
        fails = fails + 1;
      end
      if (out_subj !== s || out_rel !== rel || out_obj !== o ||
          out_qe !== qe || out_pe !== pe || out_k !== k || out_txn !== txn ||
          out_reward !== r || out_conf !== c) begin
        $display("FAIL identity r=%0d c=%0d", r, c);
        fails = fails + 1;
      end
      hold_d = delta; hold_s = out_subj; hold_o = out_obj; hold_rel = out_rel;
      hold_qe = out_qe; hold_pe = out_pe; hold_c = out_conf; hold_k = out_k;
      hold_txn = out_txn; hold_r = out_reward; hold_sat = sat_flag;
      for (stall = 0; stall < 5; stall = stall + 1) begin
        @(posedge clk);
        if (!out_valid || delta !== hold_d || out_subj !== hold_s ||
            out_obj !== hold_o || out_rel !== hold_rel || out_qe !== hold_qe ||
            out_pe !== hold_pe || out_conf !== hold_c || out_k !== hold_k ||
            out_txn !== hold_txn || out_reward !== hold_r || sat_flag !== hold_sat) begin
          $display("FAIL stall mutate r=%0d c=%0d", r, c);
          fails = fails + 1;
        end
      end
      @(negedge clk);
      out_ready = 1'b1;
      @(posedge clk);
      if (!(out_valid && out_ready)) begin
        $display("FAIL retire handshake r=%0d c=%0d", r, c);
        fails = fails + 1;
      end
      n_out = n_out + 1;
      @(negedge clk);
      out_ready = 1'b0;
      @(posedge clk);
      if (out_valid) begin
        $display("FAIL extra out_valid after retire r=%0d c=%0d", r, c);
        fails = fails + 1;
      end
    end
  endtask

  initial begin
    fails = 0;
    n_in = 0;
    n_out = 0;

    // Row 1: +3, 256 -> +3  (own reset/idle)
    apply_reset; idle_n(3);
    stim_row(4'sd3, 16'd256, 16'sd3, 32'hA1, 8'h11, 32'hB1, 16'h01, 16'h11, 1'b0, 16'h1001);
    $display("ROW1 +3*256 -> %0d", 16'sd3);

    // Row 2: -3, 256 -> -3
    apply_reset; idle_n(3);
    stim_row(-4'sd3, 16'd256, -16'sd3, 32'hA2, 8'h12, 32'hB2, 16'h02, 16'h12, 1'b1, 16'h1002);
    $display("ROW2 -3*256 -> %0d", -16'sd3);

    // Row 3: +1, 0 -> 0
    apply_reset; idle_n(2);
    stim_row(4'sd1, 16'd0, 16'sd0, 32'hA3, 8'h13, 32'hB3, 16'h03, 16'h13, 1'b0, 16'h1003);
    $display("ROW3 +1*0 -> 0");

    // Row 4: +1, 255 -> 0
    apply_reset; idle_n(2);
    stim_row(4'sd1, 16'd255, 16'sd0, 32'hA4, 8'h14, 32'hB4, 16'h04, 16'h14, 1'b0, 16'h1004);
    $display("ROW4 +1*255 -> 0");

    // Row 5: +3, 65535 -> +767 (never +768)
    apply_reset; idle_n(4);
    stim_row(4'sd3, 16'd65535, 16'sd767, 32'hA5, 8'h15, 32'hB5, 16'h05, 16'h15, 1'b1, 16'h1005);
    $display("ROW5 +3*65535 -> +767");

    // Row 6: -3, 65535 -> -768
    apply_reset; idle_n(4);
    stim_row(-4'sd3, 16'd65535, -16'sd768, 32'hA6, 8'h16, 32'hB6, 16'h06, 16'h16, 1'b0, 16'h1006);
    $display("ROW6 -3*65535 -> -768");

    // Row 7: 0, 256 -> 0
    apply_reset; idle_n(3);
    stim_row(4'sd0, 16'd256, 16'sd0, 32'hA7, 8'h17, 32'hB7, 16'h07, 16'h17, 1'b0, 16'h1007);
    $display("ROW7 0*256 -> 0");

    // Back-to-back without reset: two legal consumes, 1-deep hold
    apply_reset; idle_n(1);
    out_ready = 1'b1;
    @(negedge clk);
    in_valid = 1'b1; in_reward = 4'sd2; in_conf = 16'd512;
    in_subj = 32'd9; in_rel = 8'd3; in_obj = 32'd8;
    in_qe = 16'd9; in_pe = 16'd8; in_k = 1'b0; in_txn = 16'h2001;
    @(posedge clk);
    if (!(in_valid && in_ready)) begin
      $display("FAIL b2b first accept"); fails = fails + 1;
    end
    n_in = n_in + 1;
    @(negedge clk);
    in_reward = -4'sd2; in_conf = 16'd512;
    in_subj = 32'd19; in_rel = 8'd4; in_obj = 32'd18;
    in_qe = 16'd19; in_pe = 16'd18; in_k = 1'b1; in_txn = 16'h2002;
    @(posedge clk);
    // previous must retire same cycle new may accept (1-deep skid)
    if (out_valid) begin
      if (delta !== 16'sd4 || out_txn !== 16'h2001) begin
        $display("FAIL b2b first delta got=%0d txn=%h", delta, out_txn);
        fails = fails + 1;
      end
      n_out = n_out + 1;
    end
    if (in_valid && in_ready) n_in = n_in + 1;
    @(negedge clk); in_valid = 1'b0;
    @(posedge clk);
    if (!out_valid || delta !== -16'sd4 || out_txn !== 16'h2002) begin
      $display("FAIL b2b second delta got=%0d txn=%h", delta, out_txn);
      fails = fails + 1;
    end
    n_out = n_out + 1;
    @(negedge clk); out_ready = 1'b0;
    @(posedge clk);

    // Reset while valid held: must drop, no stale
    apply_reset;
    @(negedge clk);
    in_valid = 1'b1; in_reward = 4'sd3; in_conf = 16'd256;
    in_subj = 32'hDEAD; in_rel = 8'hAA; in_obj = 32'hBEEF;
    in_qe = 16'h1111; in_pe = 16'h2222; in_k = 1'b1; in_txn = 16'hFEED;
    out_ready = 1'b0;
    @(posedge clk);
    n_in = n_in + 1;
    @(negedge clk); in_valid = 1'b0;
    @(posedge clk);
    if (!out_valid || delta !== 16'sd3) begin
      $display("FAIL pre-reset hold"); fails = fails + 1;
    end
    rst_n = 1'b0;
    @(posedge clk);
    @(posedge clk);
    if (out_valid || delta !== 16'sd0 || out_txn !== '0) begin
      $display("FAIL stale after mid-stream reset valid=%0b d=%0d txn=%h", out_valid, delta, out_txn);
      fails = fails + 1;
    end
    rst_n = 1'b1;
    idle_n(3);

    if (n_in < n_out) begin
      $display("FAIL more outputs than inputs n_in=%0d n_out=%0d", n_in, n_out);
      fails = fails + 1;
    end

    if (fails == 0)
      $display("CONTEXT_DELTA_UNIT_XSIM_PASS fails=0 n_in=%0d n_out=%0d", n_in, n_out);
    else
      $display("CONTEXT_DELTA_UNIT_XSIM_FAIL fails=%0d n_in=%0d n_out=%0d", fails, n_in, n_out);
    $finish;
  end
endmodule
