// tb_u8_r2.sv — U8-R2 structural encoder. No LM forward. No HOLD_A retarget.
`timescale 1ns / 1ps

module tb_u8_r2;
  localparam int K = 8;
  localparam int MAX_NTOK = 64;
  logic clk, rst_n, go, busy, done, beat_v;
  logic [15:0] cid [0:K-1];
  logic [6:0] ntok;
  logic [3:0] beat_n, n_rec, n_skip;
  logic [63:0] beat_pack;
  logic [7:0] tok [0:MAX_NTOK-1];
  integer i, tmo, fails;

  a7ng_lm_ctx_encoder_v1 #(.K(K), .MAX_NTOK(MAX_NTOK)) dut (
    .clk(clk), .rst_n(rst_n), .go_i(go),
    .class_id_i(cid),
    .busy_o(busy), .done_o(done),
    .ntok_o(ntok), .beat_v_o(beat_v), .beat_n_o(beat_n), .beat_pack_o(beat_pack),
    .tok_o(tok), .n_rec_o(n_rec), .n_skip_o(n_skip)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic clr;
    begin
      for (i = 0; i < K; i = i + 1) cid[i] = 16'hFFF0 + 16'(i);
    end
  endtask

  task automatic fire;
    begin
      @(negedge clk); go = 1;
      @(posedge clk); @(negedge clk); go = 0;
      tmo = 0;
      while (!done && tmo < 4000) begin @(posedge clk); tmo++; end
      if (!done) begin $display("FAIL timeout"); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic expect_n(input integer exp_n, input integer exp_rec, input string tag);
    begin
      if (ntok !== exp_n[6:0] || n_rec !== exp_rec[3:0]) begin
        $display("FAIL %s ntok=%0d rec=%0d", tag, ntok, n_rec);
        fails++;
      end else
        $display("OK %s ntok=%0d rec=%0d skip=%0d", tag, ntok, n_rec, n_skip);
    end
  endtask

  task automatic expect_tok(input integer idx, input logic [7:0] e);
    begin
      if (tok[idx] !== e) begin
        $display("FAIL tok[%0d]=%0d exp=%0d", idx, tok[idx], e);
        fails++;
      end
    end
  endtask

  initial begin
    fails = 0; rst_n = 0; go = 0; clr();
    repeat (4) @(posedge clk); rst_n = 1;

    // E1 install chiller 65,66,67
    clr();
    cid[0] = 16'd65; cid[1] = 16'd66; cid[2] = 16'd67;
    fire();
    expect_n(12, 3, "E1_INSTALL");
    expect_tok(0, 8'd1); expect_tok(1, 8'd1); expect_tok(2, 8'd0); expect_tok(3, 8'd0);
    expect_tok(4, 8'd1); expect_tok(5, 8'd1); expect_tok(6, 8'd0); expect_tok(7, 8'd1);
    expect_tok(8, 8'd1); expect_tok(9, 8'd1); expect_tok(10, 8'd1); expect_tok(11, 8'd0);

    // E2 chiller 57-64
    clr();
    cid[0]=16'd57; cid[1]=16'd58; cid[2]=16'd59; cid[3]=16'd60;
    cid[4]=16'd61; cid[5]=16'd62; cid[6]=16'd63; cid[7]=16'd64;
    fire();
    expect_n(32, 8, "E2_CHILLER");
    expect_tok(0, 8'd1); expect_tok(1, 8'd0); expect_tok(2, 8'd0); expect_tok(3, 8'd0);
    expect_tok(4, 8'd1); expect_tok(5, 8'd0); expect_tok(6, 8'd0); expect_tok(7, 8'd1);

    // E3 CLASS 1 vs 257 (no 8-bit alias)
    clr(); cid[0] = 16'd1; fire();
    expect_n(4, 1, "E3_C1");
    expect_tok(0, 8'd0); expect_tok(1, 8'd0); expect_tok(2, 8'd0); expect_tok(3, 8'd0);
    clr(); cid[0] = 16'd257; fire();
    expect_n(4, 1, "E3_C257");
    if (tok[0] === 8'd0 && tok[1] === 8'd0 && tok[2] === 8'd0 && tok[3] === 8'd0) begin
      $display("FAIL E3 alias 1 vs 257"); fails++;
    end else
      $display("OK E3_C257 stream %0d %0d %0d %0d", tok[0], tok[1], tok[2], tok[3]);

    // E4 CLASS_ID >255
    clr(); cid[0] = 16'd256; cid[1] = 16'd427;
    fire();
    expect_n(8, 2, "E4_HI");
    expect_tok(0, 8'd7); expect_tok(1, 8'd0); expect_tok(2, 8'd1); expect_tok(3, 8'd1);
    expect_tok(4, 8'd12); expect_tok(5, 8'd1); expect_tok(6, 8'd3); expect_tok(7, 8'd0);

    // E5 empty / pads only
    clr(); fire();
    expect_n(0, 0, "E5_EMPTY");
    if (n_skip !== 4'd8) begin $display("FAIL E5 skip"); fails++; end

    // E6 CLASS 0 invalid
    clr(); cid[0] = 16'd0; cid[1] = 16'd65;
    fire();
    expect_n(4, 1, "E6_C0");
    expect_tok(0, 8'd1); expect_tok(1, 8'd1); expect_tok(2, 8'd0); expect_tok(3, 8'd0);

    // E7 boundary 443
    clr(); cid[0] = 16'd443;
    fire();
    expect_n(4, 1, "E7_C443");
    expect_tok(0, 8'd12); expect_tok(1, 8'd6); expect_tok(2, 8'd2); expect_tok(3, 8'd0);

    if (fails == 0)
      $display("U8_R2_LM_CONTEXT_ENCODER_V1_PASS semantic=MISMATCH");
    else
      $display("U8_R2_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
