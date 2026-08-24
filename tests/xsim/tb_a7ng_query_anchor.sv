// tb_a7ng_query_anchor.sv — NG-07 golden query anchors (blind: no teacher fields)
`timescale 1ns / 1ps

module tb_a7ng_query_anchor;
  logic clk, rst_n, fire, tov, valid;
  logic cue_fpga, cue_cpu, cue_what, cue_how, cue_vs, cue_hw;
  logic [7:0] te, ti, tc, ent, intent, ctx;

  a7ng_query_anchor dut (
    .clk(clk), .rst_n(rst_n), .fire_i(fire),
    .cue_fpga_i(cue_fpga), .cue_cpu_i(cue_cpu),
    .cue_what_i(cue_what), .cue_how_i(cue_how), .cue_vs_i(cue_vs), .cue_hw_i(cue_hw),
    .teacher_override_i(tov), .teacher_entity_i(te), .teacher_intent_i(ti), .teacher_context_i(tc),
    .entity_o(ent), .intent_o(intent), .context_o(ctx), .valid_o(valid)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic ask(
    input logic f, c, w, h, v, hw
  );
    begin
      @(negedge clk);
      cue_fpga=f; cue_cpu=c; cue_what=w; cue_how=h; cue_vs=v; cue_hw=hw;
      tov=0; fire=1;
      @(posedge clk); #1; fire=0;
    end
  endtask

  integer fails;
  initial begin
    fails=0; rst_n=0; fire=0; tov=0;
    cue_fpga=0; cue_cpu=0; cue_what=0; cue_how=0; cue_vs=0; cue_hw=0;
    te=0; ti=0; tc=0;
    repeat (3) @(posedge clk); rst_n=1; @(posedge clk);

    // What is FPGA? → FPGA + DEFINE + HW
    ask(1,0,1,0,0,1);
    if (!valid || ent!==8'd1 || intent!==8'd1 || ctx!==8'd1) begin
      $display("FAIL what-fpga e=%0d i=%0d c=%0d", ent, intent, ctx); fails=fails+1;
    end

    // How does FPGA work? → FPGA + MECHANISM
    ask(1,0,0,1,0,1);
    if (ent!==8'd1 || intent!==8'd2) begin
      $display("FAIL how-fpga e=%0d i=%0d", ent, intent); fails=fails+1;
    end

    // FPGA vs CPU? → BOTH + COMPARE
    ask(1,1,0,0,1,1);
    if (ent!==8'd3 || intent!==8'd3) begin
      $display("FAIL vs e=%0d i=%0d", ent, intent); fails=fails+1;
    end

    // Blind: teacher_override must stay 0 — native still wins when cues present
    // (contract test: override only when TRAIN explicitly sets it)
    @(negedge clk); tov=1; te=8'hFF; ti=8'hFF; tc=8'hFF;
    cue_fpga=1; cue_what=1; cue_hw=1; fire=1;
    @(posedge clk); #1; fire=0; tov=0;
    if (ent!==8'hFF) begin
      $display("FAIL train override not applied"); fails=fails+1;
    end

    if (fails==0) $display("A7NG07_ANCHOR_XSIM_PASS");
    else $display("A7NG07_ANCHOR_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
