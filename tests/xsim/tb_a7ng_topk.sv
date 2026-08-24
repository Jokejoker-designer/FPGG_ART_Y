// tb_a7ng_topk.sv — NG-02R global Top-8 vs Python-oracle vectors
// Retires pair-winner assertions. Counterexample {100,99}/{10,9} must PASS global Top-8.
`timescale 1ns / 1ps

module tb_a7ng_topk;
  import a7ng_pkg::*;

  logic clk, rst_n, valid_i, valid_o;
  logic [15:0] valid_mask_i;
  score_t   score_i [16];
  node_id_t id_i    [16];
  score_t   score_o [8];
  node_id_t id_o    [8];

  a7ng_topk dut (
    .clk(clk), .rst_n(rst_n), .valid_i(valid_i),
    .valid_mask_i(valid_mask_i),
    .score_i(score_i), .id_i(id_i),
    .valid_o(valid_o), .score_o(score_o), .id_o(id_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, i, nvec, vi, k;
  integer fd;
  integer exp_s, got_s;
  integer unsigned exp_id, got_id;
  integer unsigned mask_u;
  string vecpath;
  integer dummy;

  task automatic drive_and_check(
    input logic [15:0] mask,
    input score_t scores [16],
    input node_id_t ids [16],
    input score_t exp_scores [8],
    input node_id_t exp_ids [8],
    input string tag
  );
    begin
      @(negedge clk);
      valid_mask_i = mask;
      for (i = 0; i < 16; i = i + 1) begin
        score_i[i] = scores[i];
        id_i[i]    = ids[i];
      end
      valid_i = 1'b1;
      @(posedge clk);
      #1;
      valid_i = 1'b0;
      if (!valid_o) begin
        $display("FAIL %s valid_o=0", tag);
        fails = fails + 1;
      end else begin
        for (k = 0; k < 8; k = k + 1) begin
          if (score_o[k] !== exp_scores[k] || id_o[k] !== exp_ids[k]) begin
            $display("FAIL %s slot%0d got s=%0d id=%0h exp s=%0d id=%0h",
                     tag, k, score_o[k], id_o[k], exp_scores[k], exp_ids[k]);
            fails = fails + 1;
          end
        end
      end
    end
  endtask

  score_t   ts [16];
  node_id_t ti [16];
  score_t   es [8];
  node_id_t ei [8];

  initial begin
    fails = 0;
    rst_n = 0;
    valid_i = 0;
    valid_mask_i = 16'hFFFF;
    for (i = 0; i < 16; i = i + 1) begin
      score_i[i] = '0;
      id_i[i] = '0;
    end
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // ------------------------------------------------------------------
    // Counterexample: pair-winner would keep 100,10,... and DROP 99.
    // Global Top-8 must keep 100 AND 99 (and 90,89,...).
    // ------------------------------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
      ts[2*i]     = score_t'(100 - 10*i);
      ti[2*i]     = node_id_t'(2*i);
      ts[2*i + 1] = score_t'(99  - 10*i);
      ti[2*i + 1] = node_id_t'(2*i + 1);
    end
    es[0] = 100; ei[0] = 0;
    es[1] = 99;  ei[1] = 1;
    es[2] = 90;  ei[2] = 2;
    es[3] = 89;  ei[3] = 3;
    es[4] = 80;  ei[4] = 4;
    es[5] = 79;  ei[5] = 5;
    es[6] = 70;  ei[6] = 6;
    es[7] = 69;  ei[7] = 7;
    drive_and_check(16'hFFFF, ts, ti, es, ei, "counterexample_100_99");

    // ------------------------------------------------------------------
    // Directed: ties + signed + partial valid mask
    // ------------------------------------------------------------------
    for (i = 0; i < 16; i = i + 1) begin
      ti[i] = node_id_t'(100 + i);
      ts[i] = score_t'(-1000);
    end
    // 5 valids: scores 5,5,3,-2,-9 with ids forcing tie order
    valid_mask_i = 16'b0000_0000_0001_1111;
    ts[0] = 5;  ti[0] = 50;
    ts[1] = 5;  ti[1] = 40; // lower id wins tie → rank0
    ts[2] = 3;  ti[2] = 60;
    ts[3] = -2; ti[3] = 70;
    ts[4] = -9; ti[4] = 80;
    // invalids should pad by id asc: ids 105..115 for lanes 5..15
    for (i = 5; i < 16; i = i + 1) begin
      ti[i] = node_id_t'(105 + (i - 5));
      ts[i] = score_t'(9999); // score ignored when invalid
    end
    es[0] = 5;  ei[0] = 40;
    es[1] = 5;  ei[1] = 50;
    es[2] = 3;  ei[2] = 60;
    es[3] = -2; ei[3] = 70;
    es[4] = -9; ei[4] = 80;
    es[5] = 9999; ei[5] = 105; // pad invalids by id
    es[6] = 9999; ei[6] = 106;
    es[7] = 9999; ei[7] = 107;
    drive_and_check(16'b0000_0000_0001_1111, ts, ti, es, ei, "ties_signed_mask");

    // ------------------------------------------------------------------
    // 100_000 random vectors from Python oracle file
    // ------------------------------------------------------------------
    if (!$value$plusargs("VEC=%s", vecpath)) begin
      vecpath = "../../results/A7-NATIVE-GRAPH/NG-02R-TOPK/vectors/topk_100k.txt";
    end
    fd = $fopen(vecpath, "r");
    if (fd == 0) begin
      $display("FAIL cannot open VEC %s", vecpath);
      fails = fails + 1;
      $display("A7NG02R_TOPK_XSIM_FAIL fails=%0d", fails);
      $finish;
    end
    dummy = $fscanf(fd, "%d\n", nvec);
    $display("NG02R reading %0d oracle vectors from %s", nvec, vecpath);
    for (vi = 0; vi < nvec; vi = vi + 1) begin
      dummy = $fscanf(fd, "%h", mask_u);
      valid_mask_i = mask_u[15:0];
      for (i = 0; i < 16; i = i + 1) begin
        dummy = $fscanf(fd, "%d %h", exp_s, exp_id);
        ts[i] = score_t'(exp_s);
        ti[i] = node_id_t'(exp_id);
      end
      for (k = 0; k < 8; k = k + 1) begin
        dummy = $fscanf(fd, "%d %h", exp_s, exp_id);
        es[k] = score_t'(exp_s);
        ei[k] = node_id_t'(exp_id);
      end
      drive_and_check(valid_mask_i, ts, ti, es, ei, $sformatf("rnd%0d", vi));
      if (fails != 0) begin
        $display("A7NG02R_TOPK_XSIM_FAIL fails=%0d at vec=%0d", fails, vi);
        $fclose(fd);
        $finish;
      end
      if ((vi % 10000) == 0)
        $display("NG02R progress vec=%0d", vi);
    end
    $fclose(fd);

    if (fails == 0) $display("A7NG02R_TOPK_XSIM_PASS nvec=%0d", nvec);
    else $display("A7NG02R_TOPK_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
