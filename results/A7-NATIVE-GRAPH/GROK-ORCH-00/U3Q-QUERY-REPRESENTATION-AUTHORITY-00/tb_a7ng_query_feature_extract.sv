// tb_a7ng_query_feature_extract.sv — U3Q. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_query_feature_extract;
  logic clk, rst_n, tok_v, tok_r, fire, busy, valid;
  logic [7:0] tok, ntok, txor, first_t, last_t;
  logic [15:0] tsum, crc, k0, k1, k2, k3;
  integer fail, i;

  a7ng_query_feature_extract dut (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .busy_o(busy), .valid_o(valid),
    .tok_count_o(ntok), .tok_xor_o(txor), .tok_sum_o(tsum), .crc_o(crc),
    .first_tok_o(first_t), .last_tok_o(last_t),
    .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic send_tok(input logic [7:0] b);
    begin
      @(posedge clk);
      tok_v <= 1'b1; tok <= b;
      @(posedge clk);
      if (!tok_r) begin fail = fail + 1; $display("NOT_READY tok=%h", b); end
      tok_v <= 1'b0;
    end
  endtask

  task automatic do_fire;
    begin
      @(posedge clk);
      fire <= 1'b1;
      @(posedge clk);
      fire <= 1'b0;
    end
  endtask

  task automatic expect_keys(
    input logic [15:0] e0, e1, e2, e3,
    input string tag
  );
    begin
      @(posedge clk);
      if (!valid) begin fail = fail + 1; $display("%s NO_VALID", tag); end
      if (k0 !== e0 || k1 !== e1 || k2 !== e2 || k3 !== e3) begin
        fail = fail + 1;
        $display("%s KEY_MISMATCH got %h %h %h %h want %h %h %h %h",
                 tag, k0, k1, k2, k3, e0, e1, e2, e3);
      end else
        $display("%s KEYS k0=%h k1=%h k2=%h k3=%h", tag, k0, k1, k2, k3);
    end
  endtask

  initial begin
    fail = 0;
    rst_n = 0; tok_v = 0; tok = 0; fire = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    send_tok(8'd2); send_tok(8'd3); send_tok(8'd4); do_fire();
    expect_keys(16'hB72B, 16'hB229, 16'h0D07, 16'hB42E, "Q0");

    send_tok(8'd2); send_tok(8'd3); send_tok(8'd5); do_fire();
    expect_keys(16'hA70A, 16'hA308, 16'h0F06, 16'hA40E, "Q1");

    send_tok(8'd2); send_tok(8'd3); send_tok(8'd4); do_fire();
    expect_keys(16'hB72B, 16'hB229, 16'h0D07, 16'hB42E, "Q2_SAME_Q0");

    send_tok(8'd8); send_tok(8'd1); send_tok(8'd9); send_tok(8'd2); do_fire();
    expect_keys(16'hACE9, 16'hAEE1, 16'h160A, 16'hA8EB, "Q3");

    send_tok(8'd8); send_tok(8'd1); send_tok(8'd9); send_tok(8'd3); do_fire();
    expect_keys(16'hBCC8, 16'hBFC0, 16'h160B, 16'hB8CB, "Q4");

    if (k0 == 16'hB72B) begin
      fail = fail + 1;
      $display("Q4_COLLIDED_Q0");
    end

    if (fail == 0) begin
      $display("QUERY_REPRESENTATION_AUTHORITY_PASS law=qfe-v1-crc16-mix-00");
      $display("NO_HOST_HASH_SHARD_BUCKET_WINNER_ADDRESS");
    end else begin
      $display("QUERY_REPRESENTATION_AUTHORITY_FAIL fail=%0d", fail);
    end
    #20 $finish;
  end
endmodule
