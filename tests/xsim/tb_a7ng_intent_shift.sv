`timescale 1ns / 1ps
module tb_a7ng_intent_shift;
  logic clk, rst_n, fire, valid;
  logic [7:0] ent, intent, tag;
  logic signed [15:0] prior;

  a7ng_intent_shift dut (
    .clk(clk), .rst_n(rst_n), .fire_i(fire),
    .entity_i(ent), .intent_i(intent), .cand_tag_i(tag),
    .prior_o(prior), .valid_o(valid)
  );

  initial clk=0; always #5 clk=~clk;

  task automatic poke(input [7:0] e, i, t);
    begin
      @(negedge clk); ent=e; intent=i; tag=t; fire=1;
      @(posedge clk); #1; fire=0;
    end
  endtask

  integer fails;
  initial begin
    fails=0; rst_n=0; fire=0; ent=0; intent=0; tag=0;
    repeat(3) @(posedge clk); rst_n=1; @(posedge clk);

    // Same entity FPGA: DEFINE vs MECHANISM shifts ranking
    poke(8'd1, 8'd1, 8'd1); // DEF match
    if (prior !== 16'sd100) begin $display("FAIL def match %0d", prior); fails=fails+1; end
    poke(8'd1, 8'd2, 8'd1); // MECH query, DEF cand → demote
    if (prior !== -16'sd20) begin $display("FAIL mech demote %0d", prior); fails=fails+1; end
    poke(8'd1, 8'd2, 8'd2); // MECH match
    if (prior !== 16'sd100) begin $display("FAIL mech match %0d", prior); fails=fails+1; end
    poke(8'd1, 8'd3, 8'd3); // COMPARE
    if (prior !== 16'sd100) begin $display("FAIL cmp %0d", prior); fails=fails+1; end
    poke(8'd1, 8'd4, 8'd4); // CAUSE
    if (prior !== 16'sd100) begin $display("FAIL cause %0d", prior); fails=fails+1; end
    poke(8'd1, 8'd5, 8'd5); // PART_OF
    if (prior !== 16'sd100) begin $display("FAIL part %0d", prior); fails=fails+1; end

    if (fails==0) $display("A7NG09_INTENT_XSIM_PASS");
    else $display("A7NG09_INTENT_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
