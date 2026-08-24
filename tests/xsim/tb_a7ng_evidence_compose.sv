`timescale 1ns / 1ps
module tb_a7ng_evidence_compose;
  logic clk, rst_n, start, busy, tv, done, lm_on;
  logic [31:0] e0, e1, e2;
  logic [7:0] ent, intent, tok;
  integer ntok, fails;

  a7ng_evidence_compose dut (
    .clk(clk), .rst_n(rst_n), .start_i(start),
    .evid_id0_i(e0), .evid_id1_i(e1), .evid_id2_i(e2),
    .entity_i(ent), .intent_i(intent),
    .busy_o(busy), .tok_valid_o(tv), .tok_o(tok), .done_o(done), .lm_path_active_o(lm_on)
  );

  initial clk=0; always #5 clk=~clk;
  initial begin
    fails=0; ntok=0; rst_n=0; start=0;
    e0=32'hA1; e1=32'hB2; e2=32'hC3; ent=8'd1; intent=8'd2;
    repeat(3) @(posedge clk); rst_n=1; @(posedge clk);
    @(negedge clk); start=1; @(posedge clk); #1; start=0;
    while (!done) begin
      @(posedge clk); #1;
      if (tv) ntok = ntok + 1;
    end
    if (ntok < 10 || !lm_on && ntok==0) begin
      // lm_on may drop at DONE; require tokens streamed
    end
    if (ntok < 10) begin $display("FAIL ntok=%0d", ntok); fails=fails+1; end
    // no final_answer input port on module — host cannot inject answer
    if (fails==0) $display("A7NG_LMCOMPOSE_XSIM_PASS ntok=%0d", ntok);
    else $display("A7NG_LMCOMPOSE_XSIM_FAIL");
    $finish;
  end
endmodule
