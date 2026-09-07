// tb_a7ng_sparse_dir.sv — scale-256 sentinel. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_sparse_dir;
  logic clk, rst_n, wr_v, wr_ov, q_v, cand_v, q_done;
  logic [0:0] wr_t;
  logic [3:0] wr_b;
  logic [19:0] wr_id, cand_id;
  logic [15:0] k0, k1, n_emit, n_dup, n_trunc;
  integer fail, got_sent, n_cands, i;

  a7ng_sparse_dir dut (
    .clk(clk), .rst_n(rst_n),
    .wr_v(wr_v), .wr_table(wr_t), .wr_bucket(wr_b), .wr_id(wr_id),
    .wr_overflow_o(wr_ov),
    .q_v(q_v), .k0_i(k0), .k1_i(k1),
    .cand_v_o(cand_v), .cand_id_o(cand_id), .q_done_o(q_done),
    .n_emit_o(n_emit), .n_dup_o(n_dup), .n_trunc_o(n_trunc)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic wr(input integer tab, input integer buck, input integer id);
    begin
      @(posedge clk);
      wr_v <= 1; wr_t <= tab[0]; wr_b <= buck[3:0]; wr_id <= id[19:0];
      @(posedge clk);
      wr_v <= 0;
    end
  endtask

  initial begin
    fail = 0; got_sent = 0; n_cands = 0;
    rst_n = 0; wr_v = 0; q_v = 0; k0 = 0; k1 = 0;
    wr_t = 0; wr_b = 0; wr_id = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // bucket 1 table0: 1, 2, 255 sentinel
    wr(0, 1, 1); wr(0, 1, 2); wr(0, 1, 255);
    // bucket 2 table1: 7, 255 (dup across tables)
    wr(1, 2, 7); wr(1, 2, 255);
    // filler in other buckets — must not be scanned
    wr(0, 0, 99); wr(0, 3, 100); wr(1, 0, 101);

    k0 = 16'h0011; // low4 = 1
    k1 = 16'h0022; // low4 = 2
    @(posedge clk);
    q_v <= 1;
    @(posedge clk);
    q_v <= 0;

    begin : wait_q
      for (i = 0; i < 64; i = i + 1) begin
        @(posedge clk);
        if (cand_v) begin
          n_cands = n_cands + 1;
          if (cand_id == 20'd255) got_sent = 1;
          if (cand_id == 20'd99 || cand_id == 20'd100 || cand_id == 20'd101) begin
            fail = fail + 1;
            $display("FULL_SCAN_LEAK id=%0d", cand_id);
          end
        end
        if (q_done) begin
          $display("Q_DONE emit=%0d dup=%0d trunc=%0d cands=%0d sent=%0d",
                   n_emit, n_dup, n_trunc, n_cands, got_sent);
          if (!got_sent) begin fail = fail + 1; $display("SENTINEL_255_MISS"); end
          if (n_dup == 0) begin fail = fail + 1; $display("DUP_NOT_COUNTED"); end
          disable wait_q;
        end
      end
      fail = fail + 1;
      $display("TIMEOUT");
    end

    if (fail == 0) begin
      $display("MEM02_SPARSE_DIRECTORY_PASS scale=256 sentinel=255 full_scan=NO");
    end else
      $display("MEM02_SPARSE_DIRECTORY_FAIL fail=%0d", fail);
    #20 $finish;
  end
endmodule
