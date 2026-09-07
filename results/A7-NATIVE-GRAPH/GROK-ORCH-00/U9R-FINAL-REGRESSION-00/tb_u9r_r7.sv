// tb_u9r_r7.sv — U9R R7 TYPE_CLASS encoder stream (no LM, no QHEAD, no retarget).
// Structural: class 65/66/67 → {eid,iid,rid,xid} beats. CLASS_ID not a token.
// Semantic HOLD_A 653 is not this path. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_u9r_r7;
  localparam int K = 8;
  localparam int MAX_NTOK = 64;
  localparam int WATCH_CYC = 400000;

  logic clk, rst_n, go, busy, done, beat_v;
  logic [15:0] cid [0:K-1];
  logic [6:0] ntok;
  logic [3:0] beat_n, n_rec, n_skip;
  logic [63:0] pack;
  logic [7:0] tok [0:MAX_NTOK-1];
  integer cyc, tmo, i, fails;

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cyc <= 0;
    else cyc <= cyc + 1;
  end

  a7ng_lm_ctx_encoder_v1 #(.K(K), .MAX_NTOK(MAX_NTOK)) u_enc (
    .clk(clk), .rst_n(rst_n),
    .go_i(go),
    .class_id_i(cid),
    .busy_o(busy), .done_o(done),
    .ntok_o(ntok), .beat_v_o(beat_v), .beat_n_o(beat_n), .beat_pack_o(pack),
    .tok_o(tok), .n_rec_o(n_rec), .n_skip_o(n_skip)
  );

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s cyc=%0d", c, d, cyc);
      fails = fails + 1;
      #20 $finish;
    end
  endtask

  initial begin
    fails = 0; rst_n = 0; go = 0;
    cid[0] = 16'd65; cid[1] = 16'd66; cid[2] = 16'd67;
    for (i = 3; i < K; i = i + 1) cid[i] = 16'd0;
    repeat (8) @(posedge clk); rst_n = 1;
    @(posedge clk); go = 1; @(posedge clk); go = 0;
    tmo = 0;
    while (!done && tmo < 4096) begin @(posedge clk); tmo++; end
    if (!done) diverge("ENC_TIMEOUT", "encoder");
    $display("R7_ENC ntok=%0d rec=%0d skip=%0d", ntok, n_rec, n_skip);
    $display("R7_STREAM %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
             tok[0], tok[1], tok[2], tok[3], tok[4], tok[5], tok[6], tok[7],
             tok[8], tok[9], tok[10], tok[11]);
    if (ntok !== 7'd12 || n_rec !== 4'd3) diverge("ENC_NTOK", "not 12/3");
    if (tok[0] !== 8'd1 || tok[1] !== 8'd1 || tok[2] !== 8'd0 || tok[3] !== 8'd0)
      diverge("ENC_STREAM", "class65");
    if (tok[4] !== 8'd1 || tok[5] !== 8'd1 || tok[6] !== 8'd0 || tok[7] !== 8'd1)
      diverge("ENC_STREAM", "class66");
    if (tok[8] !== 8'd1 || tok[9] !== 8'd1 || tok[10] !== 8'd1 || tok[11] !== 8'd0)
      diverge("ENC_STREAM", "class67");
    for (i = 0; i < 12; i = i + 1) begin
      if (tok[i] === 8'd65 || tok[i] === 8'd66 || tok[i] === 8'd67)
        diverge("CLASS_ID_AS_TOKEN", "stream");
    end
    $display("R7_STRUCTURAL PASS TYPE_CLASS 12-token stream; CLASS_ID not serialized");
    $display("R7_ARCHIVED_LM pred_obs=861 from U8-UNIFIED-SOC xsim.log (source hash MATCH; full-forward not re-run)");
    $display("LM_ORACLE_COMPATIBILITY ORACLE_COMPATIBILITY_GAP 861!=HOLD_A_653");
    $display("SEMANTIC_LM LM_CHECKPOINT_CONTEXT_MISMATCH");
    $display("HOLD_A_ORACLE_RETARGET=NO QHEAD=NO");
    $display("U9R_R7_STRUCTURAL_PASS_ORACLE_GAP");
    $finish;
  end

  always @(posedge clk) begin
    if (rst_n && cyc > WATCH_CYC) begin
      $display("FAIL TB cycle watchdog cyc=%0d", cyc);
      $finish;
    end
  end
endmodule
