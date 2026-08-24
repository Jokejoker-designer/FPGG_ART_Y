// tb_a7ng_frontier.sv — NG-02 bucket frontier XSim
`timescale 1ns / 1ps

module tb_a7ng_frontier;
  logic clk, rst_n, push_i, pop_i, pop_valid, overflow;
  logic signed [15:0] score_i, score_o;
  logic [31:0] id_i, id_o;
  logic [7:0] count;

  logic ready;
  a7ng_frontier_buckets dut (
    .clk(clk), .rst_n(rst_n),
    .push_i(push_i), .score_i(score_i), .id_i(id_i),
    .pop_i(pop_i), .pop_valid_o(pop_valid), .score_o(score_o), .id_o(id_o),
    .overflow_o(overflow), .ready_o(ready), .count_o(count)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails;

  task automatic do_push(input int s, input int id);
    begin
      @(negedge clk);
      score_i = s[15:0];
      id_i = id;
      push_i = 1;
      pop_i = 0;
      @(posedge clk);
      #1;
      push_i = 0;
    end
  endtask

  task automatic do_pop;
    begin
      @(negedge clk);
      pop_i = 1;
      push_i = 0;
      @(posedge clk);
      #1;
      pop_i = 0;
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 0; push_i = 0; pop_i = 0; score_i = 0; id_i = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Low score then high score — pop must return high first
    do_push(100, 1);
    do_push(20000, 2);
    do_push(50, 3);

    if (count !== 8'd3) begin $display("FAIL count=%0d", count); fails = fails + 1; end

    do_pop();
    if (!pop_valid || score_o !== 16'sd20000 || id_o !== 32'd2) begin
      $display("FAIL pop1 s=%0d id=%0d v=%0b", score_o, id_o, pop_valid);
      fails = fails + 1;
    end
    do_pop();
    if (!pop_valid || score_o !== 16'sd100 || id_o !== 32'd1) begin
      $display("FAIL pop2 s=%0d id=%0d", score_o, id_o);
      fails = fails + 1;
    end
    do_pop();
    if (!pop_valid || score_o !== 16'sd50 || id_o !== 32'd3) begin
      $display("FAIL pop3 s=%0d id=%0d", score_o, id_o);
      fails = fails + 1;
    end

    // Overflow: fill one bin (DEPTH=8) with same band scores
    begin : ov
      integer k;
      for (k = 0; k < 8; k = k + 1) do_push(30000, 100 + k);
      do_push(30000, 999); // 9th in same high bin → overflow
      if (!overflow) begin $display("FAIL expected overflow"); fails = fails + 1; end
    end

    if (fails == 0) $display("A7NG02_FRONTIER_XSIM_PASS");
    else $display("A7NG02_FRONTIER_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
