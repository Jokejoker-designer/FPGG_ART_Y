// tb_a7ng_ctx_prune.sv — NG-04 path-local bomb + NG-06R-EPOCH DROP_STALE
`timescale 1ns / 1ps

module tb_a7ng_ctx_prune;
  logic clk, rst_n, fire, clear_path, new_query, pruned, expand_ok, node_alive;
  logic [15:0] qid, qep, pep, fire_qep, fire_pep, act_qep, act_pep;
  logic [7:0]  pid, mask;
  logic [31:0] nid, drop_stale;
  logic [1:0]  outcome;
  logic        stale_pulse;

  a7ng_ctx_prune dut (
    .clk(clk), .rst_n(rst_n),
    .query_id_i(qid), .query_epoch_i(qep), .path_id_i(pid), .path_epoch_i(pep),
    .node_id_i(nid), .outcome_i(outcome), .fire_i(fire),
    .fire_query_epoch_i(fire_qep), .fire_path_epoch_i(fire_pep),
    .clear_path_i(clear_path), .new_query_i(new_query),
    .path_mask_o(mask), .pruned_o(pruned),
    .expand_ok_o(expand_ok), .node_alive_o(node_alive),
    .active_query_epoch_o(act_qep), .active_path_epoch_o(act_pep),
    .drop_stale_o(drop_stale), .stale_drop_pulse_o(stale_pulse)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails;
  initial begin
    fails = 0;
    rst_n = 0; fire = 0; clear_path = 0; new_query = 0;
    qid = 0; qep = 16'd1; pep = 16'd1; pid = 0; nid = 32'h55; outcome = 2'b00;
    fire_qep = 16'd1; fire_pep = 16'd1;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // start Q0 epoch=10 path_epoch=3
    @(negedge clk); qid = 16'hA0; qep = 16'd10; pep = 16'd3; new_query = 1;
    @(posedge clk); #1; new_query = 0;
    if (act_qep !== 16'd10 || act_pep !== 16'd3) begin
      $display("FAIL active epoch q=%0d p=%0d", act_qep, act_pep);
      fails = fails + 1;
    end

    // T1: bomb on path 0 (matched epoch)
    @(negedge clk); pid = 8'd0; nid = 32'h55; outcome = 2'b10;
    fire_qep = 16'd10; fire_pep = 16'd3; fire = 1;
    @(posedge clk); #1; fire = 0;
    if (!pruned || mask[0] !== 1'b0 || !node_alive || drop_stale != 0) begin
      $display("FAIL T1 prune mask=%b alive=%0d drop=%0d", mask, node_alive, drop_stale);
      fails = fails + 1;
    end

    // T1b: stale fire must DROP_STALE and not restore bombed path
    @(negedge clk); outcome = 2'b00; // would restore if accepted
    fire_qep = 16'd9; fire_pep = 16'd3; fire = 1;
    @(posedge clk); #1; fire = 0;
    if (!stale_pulse || drop_stale < 1 || mask[0] !== 1'b0) begin
      $display("FAIL T1b stale drop pulse=%0d drop=%0d mask=%b", stale_pulse, drop_stale, mask);
      fails = fails + 1;
    end

    // T2: new query Q1 — same node safe → expand ok, path restored
    @(negedge clk); qid = 16'hA1; qep = 16'd11; pep = 16'd4; new_query = 1;
    @(posedge clk); #1; new_query = 0;
    if (mask !== 8'hFF) begin
      $display("FAIL T2 mask not restored %b", mask);
      fails = fails + 1;
    end
    @(negedge clk); pid = 8'd0; nid = 32'h55; outcome = 2'b00;
    fire_qep = 16'd11; fire_pep = 16'd4; fire = 1;
    @(posedge clk); #1; fire = 0;
    if (!node_alive || mask[0] !== 1'b1) begin
      $display("FAIL T2 revive");
      fails = fails + 1;
    end

    // T3: no sticky node ban — after bomb again, node_alive still 1
    @(negedge clk); outcome = 2'b10; fire_qep = 16'd11; fire_pep = 16'd4; fire = 1;
    @(posedge clk); #1; fire = 0;
    if (!node_alive) begin
      $display("FAIL T3 node blacklisted");
      fails = fails + 1;
    end

    if (fails == 0) $display("A7NG04_PRUNE_PASS");
    else $display("A7NG04_PRUNE_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
