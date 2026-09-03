// LOCAL-TOPK-PARALLEL-COMMIT-00: serial drain SET vs VECTOR_COMMIT. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_g14_vec_set_diff;
  import a7ng_pkg::*;

  logic clk, rst_n, clr;
  logic iv, ir_s, ir_v, last, v;
  logic ov, ovec;
  score_t s, ss;
  node_id_t id, ids;
  logic [3:0] lane;
  logic [2:0] ixs;
  score_t vec_s [8];
  node_id_t vec_id [8];

  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0), .SIFT_ON_TAKE(1'b1), .VECTOR_COMMIT(1'b0)) u_ser (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_s), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(ov), .out_ready_i(1'b1), .out_s_o(ss), .out_id_o(ids),
    .out_idx_o(ixs), .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );
  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0), .SIFT_ON_TAKE(1'b1), .VECTOR_COMMIT(1'b1)) u_vec (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_v), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(), .out_ready_i(1'b0), .out_s_o(), .out_id_o(),
    .out_idx_o(),
    .ordered_valid_o(ovec), .ordered_ready_i(1'b1),
    .ordered_score_o(vec_s), .ordered_id_o(vec_id),
    .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, n, i, j, t, seed, rr, ns, nv, hit;
  score_t os [8], us [8];
  node_id_t oi [8], ui [8];

  task automatic tick; begin @(posedge clk); #1; end endtask
  task automatic lcg(inout integer s0, output integer r);
    begin s0 = s0 * 32'd1103515245 + 32'd12345; r = s0; end
  endtask

  initial begin
    fails = 0; seed = 32'h51FEC001;
    rst_n = 0; clr = 0; iv = 0; last = 0; v = 1; s = 0; id = 0; lane = 0;
    repeat (4) @(posedge clk); rst_n = 1; tick;

    for (n = 0; n < 64; n = n + 1) begin
      clr = 1; tick; clr = 0; tick;
      for (i = 0; i < 16; i = i + 1) begin
        while (!(ir_s && ir_v)) tick;
        lcg(seed, rr);
        s    = score_t'(rr[15:0]);
        id   = node_id_t'(32'(n * 16 + i + 1));
        lane = 4'(i);
        last = (i == 15);
        iv = 1; tick; iv = 0; last = 0;
      end
      ns = 0; nv = 0;
      for (t = 0; t < 80; t = t + 1) begin
        @(posedge clk);
        if (ovec && nv == 0) begin
          for (j = 0; j < 8; j = j + 1) begin
            us[j] = vec_s[j];
            ui[j] = vec_id[j];
          end
          nv = 8;
        end
        #1;
        if (ov && ns < 8) begin os[ns] = ss; oi[ns] = ids; ns = ns + 1; end
      end
      if (ns != 8 || nv != 8) begin
        $display("VEC_SET_FAIL n=%0d counts ser=%0d vec=%0d", n, ns, nv);
        fails = fails + 1;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          hit = 0;
          for (j = 0; j < 8; j = j + 1)
            if ((os[i] === us[j]) && (oi[i] === ui[j])) hit = 1;
          if (!hit) begin
            $display("VEC_SET_FAIL n=%0d missing ser slot%0d s=%0d id=%0d", n, i, os[i], oi[i]);
            fails = fails + 1;
          end
        end
      end
    end

    if (fails == 0) $display("LOCAL_TOPK_PARALLEL_COMMIT_SET_PASS n=64");
    else $display("LOCAL_TOPK_PARALLEL_COMMIT_SET_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
