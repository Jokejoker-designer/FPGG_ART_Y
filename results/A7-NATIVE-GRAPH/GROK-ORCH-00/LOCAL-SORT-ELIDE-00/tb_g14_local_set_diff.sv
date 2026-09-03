// LOCAL-SORT-ELIDE-00: ordered vs unordered drain, SET equality. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_g14_local_set_diff;
  import a7ng_pkg::*;

  logic clk, rst_n, clr;
  logic iv, ir_o, ir_u, last;
  logic ov, ou, v;
  score_t s;
  node_id_t id;
  logic [3:0] lane;
  score_t so, su;
  node_id_t ido, idu;
  logic [2:0] ixo, ixu;

  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b1)) u_ord (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_o), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(ov), .out_ready_i(1'b1), .out_s_o(so), .out_id_o(ido),
    .out_idx_o(ixo), .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );
  a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0)) u_un (
    .clk(clk), .rst_n(rst_n), .clear_i(clr),
    .in_valid_i(iv), .in_ready_o(ir_u), .in_v_i(v), .in_s_i(s), .in_id_i(id),
    .in_lane_i(lane), .in_last_i(last),
    .out_valid_o(ou), .out_ready_i(1'b1), .out_s_o(su), .out_id_o(idu),
    .out_idx_o(ixu), .busy_o(), .clear_ignored_o(),
    .accepted_count_o(), .retired_count_o(), .drop_count_o()
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, n, i, j, t, seed, rr, no, nu, hit;
  score_t os [8], us [8];
  node_id_t oi [8], ui [8];

  task automatic tick; begin @(posedge clk); #1; end endtask
  task automatic lcg(inout integer s, output integer r);
    begin s = s * 32'd1103515245 + 32'd12345; r = s; end
  endtask

  initial begin
    fails = 0; seed = 32'h51DE1E00;
    rst_n = 0; clr = 0; iv = 0; last = 0; v = 1; s = 0; id = 0; lane = 0;
    repeat (4) @(posedge clk); rst_n = 1; tick;

    for (n = 0; n < 64; n = n + 1) begin
      clr = 1; tick; clr = 0; tick;
      for (i = 0; i < 16; i = i + 1) begin
        while (!(ir_o && ir_u)) tick;
        lcg(seed, rr);
        s    = score_t'(rr[15:0]);
        id   = node_id_t'(32'(n * 16 + i + 1));
        lane = 4'(i);
        last = (i == 15);
        iv = 1; tick; iv = 0; last = 0;
      end
      no = 0; nu = 0;
      for (t = 0; t < 80; t = t + 1) begin
        tick;
        if (ov && no < 8) begin os[no] = so; oi[no] = ido; no = no + 1; end
        if (ou && nu < 8) begin us[nu] = su; ui[nu] = idu; nu = nu + 1; end
      end
      if (no != 8 || nu != 8) begin
        $display("SET_FAIL n=%0d counts ord=%0d un=%0d", n, no, nu);
        fails = fails + 1;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          hit = 0;
          for (j = 0; j < 8; j = j + 1)
            if ((os[i] === us[j]) && (oi[i] === ui[j])) hit = 1;
          if (!hit) begin
            $display("SET_FAIL n=%0d missing ord slot%0d s=%0d id=%0d", n, i, os[i], oi[i]);
            fails = fails + 1;
          end
        end
      end
    end

    if (fails == 0) $display("LOCAL_SORT_ELIDE_SET_PASS n=64");
    else $display("LOCAL_SORT_ELIDE_SET_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
