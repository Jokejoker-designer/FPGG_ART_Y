// tb_u3qr3_rtl_golden.sv — every frozen PREREG vector vs golden. STOP on first mismatch.
// Law qse-v1-lexicon-hdc-00 unchanged. PROGRAM=NO.
`timescale 1ns / 1ps

module tb_u3qr3_rtl_golden;
  import a7ng_pkg::*;
  `include "frozen_vectors.svh"

  logic clk, rst_n, tok_v, tok_r, fire, retire, busy, acc, valid;
  logic [7:0] tok, eid, iid, rid, xid;
  logic [63:0] ec, ic, rc, xc;
  logic [15:0] crc, k0, k1, k2, k3;
  logic [15:0] h_ent, h_int, h_hash, h_sh, h_bkt, h_cand, h_win, h_addr, h_rel, h_nxt, h_ans;
  integer vi, bi, n_match, n_run;
  integer fd;

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

  task automatic pulse_retire;
    begin
      @(posedge clk); retire <= 1'b1;
      @(posedge clk); retire <= 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    n_match = 0; n_run = 0;
    rst_n = 0; tok_v = 0; tok = 0; fire = 0; retire = 0;
    fd = $fopen("golden_compare.csv", "w");
    $fdisplay(fd, "id,sec,result,eid,iid,rid,xid,k0,k1,k2,k3,crc,host");
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    for (vi = 0; vi < NVEC; vi = vi + 1) begin
      n_run = n_run + 1;
      for (bi = 0; bi < VEC_LEN[vi]; bi = bi + 1) begin
        @(posedge clk);
        tok_v <= 1'b1;
        tok   <= VEC_BYTES[vi][8*bi +: 8];
        @(posedge clk);
        if (!tok_r) begin
          $display("FIRST_DIVERGENCE vec=%0d NOT_READY byte=%0d", vi, bi);
          $fdisplay(fd, "%0d,%0d,NOT_READY,%0d,%0d,%0d,%0d,%h,%h,%h,%h,%h,%0d",
            vi, VEC_SEC[vi], eid, iid, rid, xid, k0, k1, k2, k3, crc,
            h_ent|h_hash|h_cand|h_win|h_addr|h_ans);
          $fclose(fd);
          $finish;
        end
        tok_v <= 1'b0;
      end
      @(posedge clk); fire <= 1'b1;
      @(posedge clk); fire <= 1'b0;
      @(posedge clk);
      if (!valid) begin
        $display("FIRST_DIVERGENCE vec=%0d NO_VALID", vi);
        $fdisplay(fd, "%0d,%0d,NO_VALID,0,0,0,0,0,0,0,0,0,0", vi, VEC_SEC[vi]);
        $fclose(fd);
        $finish;
      end
      if ((eid !== G_EID[vi]) || (iid !== G_IID[vi]) || (rid !== G_RID[vi]) || (xid !== G_XID[vi]) ||
          (ec !== G_ECUE[vi]) || (ic !== G_ICUE[vi]) || (rc !== G_RCUE[vi]) || (xc !== G_XCUE[vi]) ||
          (crc !== G_CRC[vi]) || (k0 !== G_K0[vi]) || (k1 !== G_K1[vi]) || (k2 !== G_K2[vi]) || (k3 !== G_K3[vi]) ||
          (h_ent|h_int|h_hash|h_sh|h_bkt|h_cand|h_win|h_addr|h_rel|h_nxt|h_ans)) begin
        $display("FIRST_DIVERGENCE vec=%0d sec=%0d", vi, VEC_SEC[vi]);
        $display("RTL eid=%0d iid=%0d rid=%0d xid=%0d k0=%h k1=%h k2=%h k3=%h crc=%h ec=%h ic=%h rc=%h xc=%h host=%0d",
          eid, iid, rid, xid, k0, k1, k2, k3, crc, ec, ic, rc, xc,
          h_ent|h_hash|h_cand|h_win|h_addr|h_ans);
        $display("GOLD eid=%0d iid=%0d rid=%0d xid=%0d k0=%h k1=%h k2=%h k3=%h crc=%h ec=%h ic=%h rc=%h xc=%h",
          G_EID[vi], G_IID[vi], G_RID[vi], G_XID[vi], G_K0[vi], G_K1[vi], G_K2[vi], G_K3[vi],
          G_CRC[vi], G_ECUE[vi], G_ICUE[vi], G_RCUE[vi], G_XCUE[vi]);
        $fdisplay(fd, "%0d,%0d,MISMATCH,%0d,%0d,%0d,%0d,%h,%h,%h,%h,%h,%0d",
          vi, VEC_SEC[vi], eid, iid, rid, xid, k0, k1, k2, k3, crc,
          h_ent|h_hash|h_cand|h_win|h_addr|h_ans);
        $fclose(fd);
        $finish;
      end
      $display("VEC %0d sec=%0d MATCH eid=%0d iid=%0d k0=%h crc=%h", vi, VEC_SEC[vi], eid, iid, k0, crc);
      $fdisplay(fd, "%0d,%0d,MATCH,%0d,%0d,%0d,%0d,%h,%h,%h,%h,%h,0",
        vi, VEC_SEC[vi], eid, iid, rid, xid, k0, k1, k2, k3, crc);
      n_match = n_match + 1;
      pulse_retire();
    end
    $display("U3Q_R3_RTL_GOLDEN_PASS n=%0d match=%0d", n_run, n_match);
    $fclose(fd);
    #20 $finish;
  end
endmodule
