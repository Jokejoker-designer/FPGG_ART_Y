// HEAP-TAKE-SIFT-00: sequential HEAPIFY vs SIFT_ON_TAKE SET equality. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_g14_sift_set_diff;
  import a7ng_pkg::*;

  logic clk, rst_n, clr;
  logic iv, ir_seq, ir_cmb, last, v;
  logic ov, oc;
  score_t s, ss, sc;
  node_id_t id, ids, idc;
  logic [3:0] lane;
  logic [2:0] ixs, ixc;

  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0), .SIFT_ON_TAKE(1'b0)) u_seq (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_seq), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(ov), .out_ready_i(1'b1), .out_s_o(ss), .out_id_o(ids),
    .out_idx_o(ixs), .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );
  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0), .SIFT_ON_TAKE(1'b1)) u_cmb (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_cmb), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(oc), .out_ready_i(1'b1), .out_s_o(sc), .out_id_o(idc),
    .out_idx_o(ixc), .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, n, i, j, t, seed, rr, ns, nc, hit;
  score_t os [8], us [8];
  node_id_t oi [8], ui [8];

  task automatic tick; begin @(posedge clk); #1; end endtask
  task automatic lcg(inout integer s0, output integer r);
    begin s0 = s0 * 32'd1103515245 + 32'd12345; r = s0; end
  endtask

  initial begin
    fails = 0; seed = 32'h51F70001;
    rst_n = 0; clr = 0; iv = 0; last = 0; v = 1; s = 0; id = 0; lane = 0;
    repeat (4) @(posedge clk); rst_n = 1; tick;

    for (n = 0; n < 64; n = n + 1) begin
      clr = 1; tick; clr = 0; tick;
      for (i = 0; i < 16; i = i + 1) begin
        while (!(ir_seq && ir_cmb)) tick;
        lcg(seed, rr);
        s    = score_t'(rr[15:0]);
        id   = node_id_t'(32'(n * 16 + i + 1));
        lane = 4'(i);
        last = (i == 15);
        iv = 1; tick; iv = 0; last = 0;
      end
      ns = 0; nc = 0;
      for (t = 0; t < 80; t = t + 1) begin
        tick;
        if (ov && ns < 8) begin os[ns] = ss; oi[ns] = ids; ns = ns + 1; end
        if (oc && nc < 8) begin us[nc] = sc; ui[nc] = idc; nc = nc + 1; end
      end
      if (ns != 8 || nc != 8) begin
        $display("SIFT_SET_FAIL n=%0d counts seq=%0d cmb=%0d", n, ns, nc);
        fails = fails + 1;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          hit = 0;
          for (j = 0; j < 8; j = j + 1)
            if ((os[i] === us[j]) && (oi[i] === ui[j])) hit = 1;
          if (!hit) begin
            $display("SIFT_SET_FAIL n=%0d missing seq slot%0d s=%0d id=%0d", n, i, os[i], oi[i]);
            fails = fails + 1;
          end
        end
      end
    end

    if (fails == 0) $display("HEAP_TAKE_SIFT_SET_PASS n=64");
    else $display("HEAP_TAKE_SIFT_SET_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
