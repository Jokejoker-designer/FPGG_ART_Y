// tb_a7ng_local_learn.sv — NG-05 learn / freeze / forget
`timescale 1ns / 1ps

module tb_a7ng_local_learn;
  logic clk, rst_n, learn_en, freeze, forget, upd, rd, updated;
  logic [5:0] idx, rd_idx;
  logic signed [3:0] reward;
  logic signed [7:0] prior;
  logic [15:0] ucnt;

  a7ng_local_learn dut (
    .clk(clk), .rst_n(rst_n),
    .learn_en_i(learn_en), .freeze_i(freeze), .forget_i(forget),
    .upd_i(upd), .idx_i(idx), .reward_i(reward),
    .rd_i(rd), .rd_idx_i(rd_idx),
    .prior_o(prior), .updated_o(updated), .update_count_o(ucnt)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic poke_upd(input [5:0] i, input signed [3:0] r);
    begin
      @(negedge clk); idx = i; reward = r; upd = 1;
      @(posedge clk); #1; upd = 0;
    end
  endtask

  task automatic poke_rd(input [5:0] i);
    begin
      @(negedge clk); rd_idx = i; rd = 1;
      @(posedge clk); #1; rd = 0;
    end
  endtask

  integer fails;
  initial begin
    fails = 0;
    rst_n = 0; learn_en = 1; freeze = 0; forget = 0;
    upd = 0; rd = 0; idx = 0; rd_idx = 0; reward = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // T1: learn +3 twice → prior = 6
    poke_upd(6'd3, 4'sd3);
    poke_upd(6'd3, 4'sd3);
    poke_rd(6'd3);
    if (prior !== 8'sd6 || ucnt !== 16'd2) begin
      $display("FAIL T1 prior=%0d ucnt=%0d", prior, ucnt);
      fails = fails + 1;
    end

    // T2: freeze blocks update
    @(negedge clk); freeze = 1;
    poke_upd(6'd3, 4'sd3);
    poke_rd(6'd3);
    if (prior !== 8'sd6 || ucnt !== 16'd2) begin
      $display("FAIL T2 freeze leak prior=%0d", prior);
      fails = fails + 1;
    end

    // T3: forget clears
    @(negedge clk); freeze = 0; forget = 1;
    @(posedge clk); #1; forget = 0;
    poke_rd(6'd3);
    if (prior !== 8'sd0 || ucnt !== 16'd0) begin
      $display("FAIL T3 forget prior=%0d ucnt=%0d", prior, ucnt);
      fails = fails + 1;
    end

    // T4: learn_en=0 (teacher-off) blocks
    @(negedge clk); learn_en = 0;
    poke_upd(6'd3, 4'sd3);
    poke_rd(6'd3);
    if (prior !== 8'sd0) begin
      $display("FAIL T4 learn_en gate");
      fails = fails + 1;
    end

    // T5: retrain different mapping
    @(negedge clk); learn_en = 1;
    poke_upd(6'd3, -4'sd3);
    poke_rd(6'd3);
    if (prior !== -8'sd3) begin
      $display("FAIL T5 retrain prior=%0d", prior);
      fails = fails + 1;
    end

    if (fails == 0) $display("A7NG05_LEARN_XSIM_PASS");
    else $display("A7NG05_LEARN_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
