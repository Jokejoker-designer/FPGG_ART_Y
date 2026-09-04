// tb_a7ng_query_struct_extract.sv — U3Q-R3 raw token → packet. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_a7ng_query_struct_extract;
  import a7ng_pkg::*;
  logic clk, rst_n, tok_v, tok_r, fire, retire, busy, acc, valid;
  logic [7:0] tok, eid, iid, rid, xid;
  logic [63:0] ec, ic, rc, xc;
  logic [15:0] crc, k0, k1, k2, k3;
  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;
  integer fail, i;
  logic [15:0] hold_k0;

  a7ng_query_struct_extract dut (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .busy_o(busy), .accepted_o(acc), .valid_o(valid),
    .entity_id_o(eid), .intent_id_o(iid), .relation_id_o(rid), .context_id_o(xid),
    .entity_cue_o(ec), .intent_cue_o(ic), .relation_cue_o(rc), .context_cue_o(xc),
    .crc16_dbg_o(crc), .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3),
    .n_host_entity_o(h_ent), .n_host_intent_o(h_int), .n_host_hash_o(h_hash),
    .n_host_shard_o(h_sh), .n_host_bucket_o(h_bkt), .n_host_cand_o(h_cand),
    .n_host_winner_o(h_win), .n_host_addr_o(h_addr), .n_host_relpath_o(h_rel),
    .n_host_next_o(h_nxt), .n_host_answer_o(h_ans)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic send_str(input string s);
    integer k;
    begin
      for (k = 0; k < s.len(); k = k + 1) begin
        @(posedge clk);
        tok_v <= 1'b1;
        tok   <= s[k];
        @(posedge clk);
        if (!tok_r) fail = fail + 1;
        tok_v <= 1'b0;
      end
    end
  endtask

  task automatic do_fire;
    begin
      @(posedge clk);
      fire <= 1'b1;
      @(posedge clk);
      fire <= 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic do_retire;
    begin
      @(posedge clk);
      retire <= 1'b1;
      @(posedge clk);
      retire <= 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    fail = 0;
    rst_n = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    if (h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans) begin
      fail = fail + 1; $display("QUERY_REPRESENTATION_LEAK");
    end

    send_str("chiller");
    do_fire();
    if (!valid) begin fail = fail + 1; $display("NO_VALID"); end
    if (eid !== 8'd1) begin fail = fail + 1; $display("CHILLER_EID %0d", eid); end
    if (k0 !== {8'd1, 8'd0}) begin fail = fail + 1; $display("K0 %h", k0); end
    if (k0 === crc) begin fail = fail + 1; $display("CRC_AS_ROUTE"); end
    hold_k0 = k0;
    @(posedge clk);
    tok_v <= 1'b1; tok <= 8'h7A;
    @(posedge clk);
    if (tok_r) begin fail = fail + 1; $display("TOK_ACCEPTED_WHILE_HELD"); end
    tok_v <= 1'b0;
    if (k0 !== hold_k0 || !valid) begin fail = fail + 1; $display("PACKET_UNSTABLE"); end
    do_retire();
    if (valid) begin fail = fail + 1; $display("NO_RETIRE"); end

    send_str("water chiller");
    do_fire();
    if (eid !== 8'd1) begin fail = fail + 1; $display("WATER_CHILLER %0d", eid); end
    do_retire();

    send_str("install chiller");
    do_fire();
    if (eid !== 8'd1 || iid !== 8'd1) begin fail = fail + 1; $display("INSTALL %0d %0d", eid, iid); end
    if (k0 !== 16'h0101) begin fail = fail + 1; $display("INSTALL_K0 %h", k0); end
    do_retire();

    send_str("leak chiller");
    do_fire();
    if (eid !== 8'd1 || iid !== 8'd2) begin fail = fail + 1; $display("LEAK %0d %0d", eid, iid); end
    do_retire();

    tok_v = 1; tok = 8'hC3; @(posedge clk); tok = 8'h4F; @(posedge clk); tok = 8'hFF; @(posedge clk); tok_v = 0;
    do_fire();
    if (eid !== 8'd0) begin fail = fail + 1; $display("SENTINEL_EID %0d", eid); end
    do_retire();

    if (h_ent|h_hash|h_cand|h_win|h_addr|h_ans) begin
      fail = fail + 1; $display("QUERY_REPRESENTATION_LEAK_LATE");
    end

    if (fail == 0) $display("U3Q_R3_XSIM_PASS");
    else $display("U3Q_R3_XSIM_FAIL fail=%0d", fail);
    #20 $finish;
  end
endmodule
