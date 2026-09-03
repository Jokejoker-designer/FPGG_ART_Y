// PHASE2-G1-RESOLVER-V2-00 randomized scoreboard. PROGRAM=NO. TXN_W=4 wrap surrogate.
`timescale 1ns / 1ps

module tb_a7ng_feedback_resolver_v2_rand;
  localparam int unsigned TXN_W  = 4;
  localparam int unsigned CYCLES = 100000;

  logic clk, rst_n, learn, freeze;
  logic latch_v, latch_rdy, pending;
  logic [31:0] subj, obj;
  logic [7:0] rel, conf;
  logic [15:0] qe, pe;
  logic [TXN_W-1:0] txn, echo;
  logic contra;
  logic rew_v, echo_v, rew_rdy, ack_v, ack_rdy, cons_v, cons_rdy;
  logic signed [3:0] rew, cons_r;
  logic [2:0] ack;
  logic [31:0] cons_s, cons_o;
  logic [7:0] cons_rel, cons_c;
  logic [15:0] cons_qe, cons_pe;
  logic cons_k;
  logic [TXN_W-1:0] cons_txn;
  logic [15:0] n_c, n_or, n_rg, n_lt, n_dr, n_dp, n_md;

  a7ng_feedback_resolver #(.TXN_W(TXN_W)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .latch_valid_i(latch_v), .latch_ready_o(latch_rdy),
    .subj_i(subj), .rel_i(rel), .obj_i(obj),
    .q_epoch_i(qe), .p_epoch_i(pe), .conf_i(conf), .contradict_i(contra),
    .pending_o(pending), .txn_o(txn),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy),
    .ack_valid_o(ack_v), .ack_ready_i(ack_rdy), .ack_o(ack),
    .consume_valid_o(cons_v), .consume_ready_i(cons_rdy),
    .consume_reward_o(cons_r),
    .consume_subj_o(cons_s), .consume_rel_o(cons_rel), .consume_obj_o(cons_o),
    .consume_q_epoch_o(cons_qe), .consume_p_epoch_o(cons_pe),
    .consume_conf_o(cons_c), .consume_contradict_o(cons_k), .consume_txn_o(cons_txn),
    .n_consume_o(n_c), .n_orphan_o(n_or), .n_range_o(n_rg),
    .n_late_o(n_lt), .n_drop_o(n_dr), .n_dup_o(n_dp), .n_mode_o(n_md)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer fails, cyc, seed, rr;
  integer n_hs, n_issue, wrap_seen;
  integer tb_c, tb_or, tb_rg, tb_lt, tb_dr, tb_dp, tb_md;
  integer have_ev, last_v_sb;
  integer ev_subj, ev_obj, ev_rel, ev_conf, ev_qe, ev_pe, ev_k;
  logic [TXN_W-1:0] ev_txn, last_txn_sb;
  logic signed [3:0] acc_rew;
  logic prev_cons;
  logic [31:0] hold_s, hold_o;
  logic [7:0] hold_rel, hold_c;
  logic [15:0] hold_qe, hold_pe;
  logic hold_k;
  logic [TXN_W-1:0] hold_txn;
  logic signed [3:0] hold_r;
  logic [TXN_W-1:0] txn_prev;
  logic ack_busy, cons_busy;

  function automatic integer rnd();
    begin
      seed = seed * 32'd1103515245 + 32'd12345;
      return seed;
    end
  endfunction

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      have_ev   <= 0;
      last_v_sb <= 0;
      prev_cons <= 0;
      tb_c <= 0; tb_or <= 0; tb_rg <= 0; tb_lt <= 0; tb_dr <= 0; tb_dp <= 0; tb_md <= 0;
    end else begin
      ack_busy  = ack_v && !ack_rdy;
      cons_busy = cons_v && !cons_rdy;

      if (cons_v && prev_cons && !cons_rdy) begin
        if (cons_s !== hold_s || cons_o !== hold_o || cons_rel !== hold_rel ||
            cons_c !== hold_c || cons_qe !== hold_qe || cons_pe !== hold_pe ||
            cons_k !== hold_k || cons_txn !== hold_txn || cons_r !== hold_r)
          fails <= fails + 1;
      end
      if (cons_v && !prev_cons) begin
        hold_s <= cons_s; hold_o <= cons_o; hold_rel <= cons_rel;
        hold_c <= cons_c; hold_qe <= cons_qe; hold_pe <= cons_pe;
        hold_k <= cons_k; hold_txn <= cons_txn; hold_r <= cons_r;
        if (!have_ev) fails <= fails + 1;
        if (cons_s !== ev_subj[31:0] || cons_o !== ev_obj[31:0] ||
            cons_rel !== ev_rel[7:0] || cons_c !== ev_conf[7:0] ||
            cons_qe !== ev_qe[15:0] || cons_pe !== ev_pe[15:0] ||
            cons_k !== ev_k[0] || cons_txn !== ev_txn || cons_r !== acc_rew)
          fails <= fails + 1;
      end
      if (cons_v && cons_rdy) begin
        n_hs        <= n_hs + 1;
        last_v_sb   <= 1;
        last_txn_sb <= cons_txn;
        have_ev     <= 0;
      end

      if (latch_v && latch_rdy) begin
        have_ev <= 1;
        ev_subj <= subj; ev_obj <= obj; ev_rel <= rel; ev_conf <= conf;
        ev_qe <= qe; ev_pe <= pe; ev_k <= contra;
        ev_txn <= {dut.gen, dut.seq};
      end

      if (rew_v && !ack_busy && !cons_busy) begin
        if (!((rew >= -4'sd3) && (rew <= 4'sd3)))
          tb_rg <= (tb_rg == 65535) ? tb_rg : tb_rg + 1;
        else if (cons_v)
          tb_dp <= (tb_dp == 65535) ? tb_dp : tb_dp + 1;
        else if (!pending) begin
          if (last_v_sb && echo_v && (echo == last_txn_sb))
            tb_dp <= (tb_dp == 65535) ? tb_dp : tb_dp + 1;
          else
            tb_or <= (tb_or == 65535) ? tb_or : tb_or + 1;
        end else if (!echo_v || (echo != txn))
          tb_lt <= (tb_lt == 65535) ? tb_lt : tb_lt + 1;
        else if (freeze)
          tb_dr <= (tb_dr == 65535) ? tb_dr : tb_dr + 1;
        else if (!learn)
          tb_md <= (tb_md == 65535) ? tb_md : tb_md + 1;
        else begin
          tb_c    <= (tb_c == 65535) ? tb_c : tb_c + 1;
          acc_rew <= rew;
          n_issue <= n_issue + 1;
          if (cons_rdy) begin
            last_v_sb   <= 1;
            last_txn_sb <= txn;
          end
        end
      end else if (freeze && pending && !cons_v && !ack_busy) begin
        tb_dr   <= (tb_dr == 65535) ? tb_dr : tb_dr + 1;
        have_ev <= 0;
      end

      prev_cons <= cons_v;
    end
  end

  initial begin
    fails = 0; seed = 32'hC0DEC0DE; cyc = 0;
    n_hs = 0; n_issue = 0; wrap_seen = 0;
    rst_n = 0; learn = 1; freeze = 0;
    latch_v = 0; rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    subj = 0; rel = 0; obj = 0; qe = 0; pe = 0; conf = 0; contra = 0;
    ack_rdy = 1; cons_rdy = 1;
    repeat (3) tick;
    rst_n = 1;
    tick;

    learn = 0;
    latch_v = 1; subj = 32'd1; rel = 8'd2; obj = 32'd3;
    tick; latch_v = 0;
    if (pending || latch_rdy) begin $display("FAIL learn0 latch"); fails = fails + 1; end

    learn = 1; freeze = 0; cons_rdy = 1; ack_rdy = 1;
    tick;
    latch_v = 1; subj = 32'd41; rel = 8'd2; obj = 32'd57;
    qe = 16'd7; pe = 16'd9; conf = 8'd200; contra = 1;
    tick; latch_v = 0; tick;
    rew_v = 1; rew = 4'sd2; echo_v = 0;
    tick; rew_v = 0;
    if (cons_v) begin $display("FAIL missing echo consumed"); fails = fails + 1; end

    rew_v = 1; rew = 4'sd7; echo_v = 1; echo = txn;
    tick; rew_v = 0; echo_v = 0;
    if (cons_v) begin $display("FAIL range consumed"); fails = fails + 1; end

    rew_v = 1; rew = 4'sd1; echo_v = 1; echo = ~txn;
    tick; rew_v = 0; echo_v = 0;
    ack_rdy = 1; tick;

    cons_rdy = 0; ack_rdy = 0;
    rew_v = 1; rew = 4'sd3; echo_v = 1; echo = txn;
    tick; rew_v = 0; echo_v = 0;
    if (!cons_v) begin $display("FAIL consume not issued"); fails = fails + 1; end
    tick; tick;
    if (!cons_v || cons_s != 32'd41 || cons_r != 4'sd3 || cons_k != 1'b1 ||
        cons_qe != 16'd7 || cons_pe != 16'd9) begin
      $display("FAIL hold fields s=%0d r=%0d k=%0d", cons_s, cons_r, cons_k);
      fails = fails + 1;
    end
    ack_rdy = 1; tick;
    cons_rdy = 1; tick; tick;

    latch_v = 1; subj = 32'd8; obj = 32'd9; contra = 0;
    tick; latch_v = 0; tick;
    learn = 0;
    rew_v = 1; rew = 4'sd1; echo_v = 1; echo = txn;
    tick; rew_v = 0; echo_v = 0; learn = 1;
    if (cons_v) begin $display("FAIL mode consumed"); fails = fails + 1; end
    freeze = 1; tick; freeze = 0;
    if (pending || cons_v) begin $display("FAIL freeze leftover"); fails = fails + 1; end

    learn = 1; freeze = 0; cons_rdy = 1; ack_rdy = 1;
    txn_prev = txn;
    begin : wrap_loop
      integer i;
      for (i = 0; i < 24; i = i + 1) begin
        if (!latch_rdy) tick;
        latch_v = 1; subj = 32'd100 + i; obj = 32'd200 + i; rel = 8'(i);
        conf = 8'd10; contra = 1'b0; qe = 16'(i); pe = 16'(i+1);
        tick; latch_v = 0;
        if (!pending) tick;
        rew_v = 1; rew = 4'sd1; echo_v = 1; echo = txn;
        tick; rew_v = 0; echo_v = 0;
        if (pending) tick;
        if (txn[3:2] != txn_prev[3:2]) wrap_seen = 1;
        txn_prev = txn;
      end
    end
    $display("DIRECTED_DONE fails=%0d wrap_seen=%0d", fails, wrap_seen);

    for (cyc = 0; cyc < CYCLES; cyc = cyc + 1) begin
      rr = rnd();
      if (rr[11:0] == 12'd0) begin
        rst_n = 0; latch_v = 0; rew_v = 0; echo_v = 0;
        tick; rst_n = 1;
      end
      rr = rnd();
      learn    = (rr[2:0] != 3'd0);
      freeze   = (rr[5:3] == 3'b111);
      cons_rdy = rr[6];
      ack_rdy  = rr[7];
      rr = rnd();
      if (latch_rdy && rr[0]) begin
        latch_v = 1;
        subj = rnd(); obj = rnd(); rel = rnd()[7:0]; conf = rnd()[7:0];
        qe = rnd()[15:0]; pe = rnd()[15:0]; contra = rnd()[0];
      end else
        latch_v = 0;
      rr = rnd();
      if (rr[1:0] != 2'b00) begin
        rew_v = 1;
        if (rr[3:2] == 2'b11) rew = $signed(rnd()[3:0]);
        else rew = $signed({1'b0, rnd()[1:0]}) - 4'sd1;
        echo_v = (rr[5:4] != 2'b00);
        case (rr[7:6])
          2'd0: echo = txn;
          2'd1: echo = last_txn_sb;
          2'd2: echo = ~txn;
          default: echo = txn;
        endcase
      end else begin
        rew_v = 0;
        echo_v = 0;
      end
      tick;
      if (fails != 0 && cyc[11:0] == 0) begin
        $display("ABORT cyc=%0d fails=%0d", cyc, fails);
        cyc = CYCLES;
      end
    end

    cons_rdy = 1; ack_rdy = 1; latch_v = 0; rew_v = 0; freeze = 0; learn = 1;
    repeat (32) tick;

    if (n_c !== tb_c[15:0]) begin $display("FAIL n_consume dut=%0d tb=%0d", n_c, tb_c); fails = fails + 1; end
    if (n_or !== tb_or[15:0]) begin $display("FAIL n_orphan dut=%0d tb=%0d", n_or, tb_or); fails = fails + 1; end
    if (n_rg !== tb_rg[15:0]) begin $display("FAIL n_range dut=%0d tb=%0d", n_rg, tb_rg); fails = fails + 1; end
    if (n_lt !== tb_lt[15:0]) begin $display("FAIL n_late dut=%0d tb=%0d", n_lt, tb_lt); fails = fails + 1; end
    if (n_dr !== tb_dr[15:0]) begin $display("FAIL n_drop dut=%0d tb=%0d", n_dr, tb_dr); fails = fails + 1; end
    if (n_dp !== tb_dp[15:0]) begin $display("FAIL n_dup dut=%0d tb=%0d", n_dp, tb_dp); fails = fails + 1; end
    if (n_md !== tb_md[15:0]) begin $display("FAIL n_mode dut=%0d tb=%0d", n_md, tb_md); fails = fails + 1; end
    if (n_hs > n_issue) begin $display("FAIL hs %0d > issue %0d", n_hs, n_issue); fails = fails + 1; end

    $display("SCOREBOARD issue=%0d hs=%0d n_c=%0d n_or=%0d n_rg=%0d n_lt=%0d n_dr=%0d n_dp=%0d n_md=%0d",
             n_issue, n_hs, n_c, n_or, n_rg, n_lt, n_dr, n_dp, n_md);
    $display("MISMATCH_COUNT=%0d", fails);
    if (fails == 0)
      $display("RESOLVER_V2_RAND_XSIM_PASS cycles=%0d wrap_seen=%0d", CYCLES, wrap_seen);
    else
      $display("RESOLVER_V2_RAND_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
