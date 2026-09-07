// tb_u7a_r3b.sv — TYPE_CLASS → LEARN_KEY_CLASS_CONTEXT_V1 reachability.
// PROGRAM=NO. U7 CLOSED. Host does not construct learn target.
`timescale 1ns / 1ps

module tb_u7a_r3b;
  import a7ng_pkg::*;
  localparam int K = 8;

  logic clk, rst_n, learn, freeze;
  logic poke, poke_go, pev, piv, prv, pxv;
  logic [7:0] pe, pi, pr, px;
  logic retr_done, batch_done;
  logic [15:0] n_emit, n_learned, n_host;
  logic [15:0] top_cid [K];
  node_id_t top_id [K];
  score_t top_sc [K];
  logic rew_v, echo_v, rew_rdy, pending, ack_v;
  logic signed [3:0] rew;
  logic [15:0] txn, echo;
  logic [2:0] ack;
  logic [15:0] learn_cid;
  logic [31:0] learn_subj, learn_obj, k58c_s, k58c_o, k58w_s, k58w_o, high_subj;
  logic [7:0]  learn_rel, k58c_r, k58w_r;
  logic saw58c, saw58w;
  logic signed [7:0] pri58c, pri58w, lk_pri, lk_pen;
  logic [15:0] high_cid;
  logic lk_snap_go, lk_busy, lk_done, lk_hit;
  logic [1:0] lk_snap_sel;
  logic probe_v;
  score_t probe_sc;
  logic [15:0] probe_cid;
  logic pbusy, pdone, pnak, boot_done, c7v;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic [4:0] st;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, ddr_mem [0:255];
  integer tmo, i, n_rew, score58_chiller, score58_water;
  logic pend_d, rew_armed;

  a7ng_u7a_r3b_typeclass_to_learn #(.CAND_CAP(64), .K(K)) dut (
    .clk(clk), .rst_n(rst_n), .learn_i(learn), .freeze_i(freeze),
    .poke_i(poke), .poke_go_i(poke_go),
    .poke_ent_i(pe), .poke_int_i(pi), .poke_rel_i(pr), .poke_ctx_i(px),
    .poke_ev_i(pev), .poke_iv_i(piv), .poke_rv_i(prv), .poke_xv_i(pxv),
    .retr_done_o(retr_done), .batch_done_o(batch_done),
    .n_emit_o(n_emit), .n_learned_o(n_learned),
    .topk_class_id_o(top_cid), .topk_id_o(top_id), .topk_sc_o(top_sc),
    .n_host_or_o(n_host),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy), .pending_o(pending), .txn_o(txn),
    .ack_valid_o(ack_v), .ack_o(ack),
    .learn_cid_o(learn_cid), .learn_subj_o(learn_subj),
    .learn_rel_o(learn_rel), .learn_obj_o(learn_obj),
    .saw58_chiller_o(saw58c), .saw58_water_o(saw58w),
    .k58c_subj_o(k58c_s), .k58c_rel_o(k58c_r), .k58c_obj_o(k58c_o),
    .pri58_chiller_o(pri58c),
    .k58w_subj_o(k58w_s), .k58w_rel_o(k58w_r), .k58w_obj_o(k58w_o),
    .pri58_water_o(pri58w),
    .high_cid_o(high_cid), .high_subj_o(high_subj),
    .lk_snap_go_i(lk_snap_go), .lk_snap_sel_i(lk_snap_sel),
    .lk_busy_o(lk_busy), .lk_done_o(lk_done), .lk_hit_o(lk_hit),
    .lk_pri_o(lk_pri), .lk_pen_o(lk_pen),
    .probe_valid_o(probe_v), .probe_score_o(probe_sc), .probe_cid_o(probe_cid),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .c7_ack_valid_o(c7v), .c7_addr_o(c7a),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .dbg_st_o(st),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk) if (ddr_req && ddr_we) ddr_mem[ddr_addr] <= ddr_wdata;
  assign ddr_ack = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) pend_d <= 1'b0;
    else pend_d <= pending;
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s st=%0d", c, d, st);
      #20 $finish;
    end
  endtask

  task automatic wait_boot;
    begin
      tmo = 0;
      while (!boot_done && tmo < 40000) begin @(posedge clk); tmo++; end
      if (!boot_done) diverge("EARLY_DONE", "boot");
      while (pbusy && tmo < 80000) begin @(posedge clk); tmo++; end
    end
  endtask

  task automatic fire_q(
      input logic [7:0] e, i, r, x,
      input logic ev, iv, rv, xv
  );
    begin
      @(negedge clk);
      poke = 1; pe = e; pi = i; pr = r; px = x;
      pev = ev; piv = iv; prv = rv; pxv = xv;
      poke_go = 1;
      @(posedge clk); @(negedge clk); poke_go = 0;
    end
  endtask

  task automatic service_batch;
    begin
      n_rew = 0;
      tmo = 0;
      while (!batch_done && tmo < 400000) begin
        @(posedge clk);
        if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "n_host");
        if (pnak) diverge("PERSIST_NAK", "unexpected");
        if (probe_v && probe_cid == 16'd58) begin
          if (pev && pxv)
            score58_water = probe_sc;
          else
            score58_chiller = probe_sc;
        end
        if (pending && !pend_d && rew_rdy) begin
          echo = txn; echo_v = 1; rew = 4'sd2;
          @(negedge clk); rew_v = 1;
          @(posedge clk); @(negedge clk); rew_v = 0;
          n_rew = n_rew + 1;
          if (learn_subj[31:16] !== 16'h5443)
            diverge("NAMESPACE", "subj prefix");
          if (learn_cid < 16'd1 || learn_cid > 16'd443)
            diverge("CLASS_ID_AS_NID", "cid out of catalog");
          if (learn_subj[15:0] !== learn_cid)
            diverge("CLASS_ID_AS_NID", "subj low16 != CLASS_ID");
        end
        tmo++;
      end
      if (!batch_done) diverge("EARLY_DONE", "batch timeout");
      @(posedge clk);
      poke = 0;
    end
  endtask

  task automatic snap_lk(input logic [1:0] sel);
    begin
      tmo = 0;
      while ((pbusy || lk_busy || pending) && tmo < 8000) begin @(posedge clk); tmo++; end
      @(negedge clk); lk_snap_sel = sel; lk_snap_go = 1;
      @(posedge clk); @(negedge clk); lk_snap_go = 0;
      tmo = 0;
      while (!lk_done && tmo < 8000) begin @(posedge clk); tmo++; end
      if (!lk_done) diverge("INCONCLUSIVE", "snap lk");
      @(posedge clk);
    end
  endtask

  initial begin
    #80_000_000;
    $display("FAIL TB timeout");
    $finish;
  end

  initial begin
    rst_n = 0; learn = 1; freeze = 0;
    poke = 0; poke_go = 0; pe = 0; pi = 0; pr = 0; px = 0;
    pev = 0; piv = 0; prv = 0; pxv = 0;
    rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    lk_snap_go = 0; lk_snap_sel = 0;
    score58_chiller = 0; score58_water = 0;
    for (i = 0; i < 256; i++) ddr_mem[i] = 64'd0;
    repeat (8) @(posedge clk); rst_n = 1;
    wait_boot();

    // 1) chiller — CLASS_ID 58 in Top-K, learn all K
    fire_q(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0);
    service_batch();
    $display("CHILLER emit=%0d learned=%0d saw58=%0d key=%h/%h/%h pri=%0d score=%0d",
      n_emit, n_learned, saw58c, k58c_s, k58c_r, k58c_o, pri58c, score58_chiller);
    if (n_host !== 0) diverge("HOST_SEMANTIC_LEAK", "after chiller");
    if (n_learned !== 16'd8) diverge("TOPK_LEARN", "chiller n_learned");
    if (!saw58c) diverge("CLASS_ID_58", "not in chiller Top-K learn");
    if (k58c_s !== 32'h5443003A) diverge("V1_KEY", "chiller 58 subj");
    if (k58c_r !== 8'h1) diverge("V1_KEY", "chiller 58 rel");
    if (k58c_o !== 32'h01000000) diverge("V1_KEY", "chiller 58 obj");
    if (pri58c !== 8'sd2) diverge("PRIOR", "chiller 58 pri!=2");
    if (score58_chiller !== 10) diverge("SCORER_PRIOR", "8+2");

    // 2) same query again — same key, pri accumulates
    fire_q(8'd1, 8'd0, 8'd0, 8'd0, 1'b1, 1'b0, 1'b0, 1'b0);
    service_batch();
    $display("CHILLER2 pri=%0d score=%0d seq=%0d", pri58c, score58_chiller, c7seq);
    if (pri58c !== 8'sd4) diverge("SAME_KEY_UPDATE", "pri not 4");
    if (score58_chiller !== 12) diverge("SCORER_PRIOR", "8+4");

    // 3) water chiller — same CLASS_ID 58, different context
    fire_q(8'd1, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1);
    service_batch();
    $display("WATER emit=%0d learned=%0d saw58=%0d key=%h/%h/%h pri=%0d score=%0d",
      n_emit, n_learned, saw58w, k58w_s, k58w_r, k58w_o, pri58w, score58_water);
    if (!saw58w) diverge("CLASS_ID_58", "not in water Top-K learn");
    if (k58w_s !== 32'h5443003A) diverge("V1_KEY", "water 58 subj");
    if (k58w_r !== 8'h9) diverge("V1_KEY", "water 58 rel");
    if (k58w_o !== 32'h01000001) diverge("V1_KEY", "water 58 obj");
    if (k58c_s === k58w_s && k58c_r === k58w_r && k58c_o === k58w_o)
      diverge("ALIAS_58", "CLASS_ONLY alias");
    if (pri58w !== 8'sd2) diverge("PRIOR", "water 58 pri!=2");
    if (score58_water !== 18) diverge("SCORER_PRIOR", "16+2");

    // 4) FPGA snap lookup: both HIT, unbound-mask MISS, chiller pri still 4
    snap_lk(2'd0);
    $display("LK chiller58 hit=%0d pri=%0d", lk_hit, lk_pri);
    if (!lk_hit) diverge("LOOKUP", "chiller 58 miss");
    if (lk_pri !== 8'sd4) diverge("LOOKUP", "chiller pri stomped");
    snap_lk(2'd1);
    $display("LK water58 hit=%0d pri=%0d", lk_hit, lk_pri);
    if (!lk_hit) diverge("LOOKUP", "water 58 miss");
    if (lk_pri !== 8'sd2) diverge("LOOKUP", "water pri");
    snap_lk(2'd2);
    $display("LK unbound-mask hit=%0d", lk_hit);
    if (lk_hit) diverge("BIND_MASK_ALIAS", "rel=0 must miss");

    // 5) high CLASS_ID query (supply duct)
    fire_q(8'd7, 8'd0, 8'd0, 8'd1, 1'b1, 1'b0, 1'b0, 1'b1);
    service_batch();
    $display("DUCT high_cid=%0d high_subj=%h learned=%0d", high_cid, high_subj, n_learned);
    if (high_cid <= 16'd255) diverge("HIGH_CLASS_ID", "no cid>255 learned");
    if (high_subj[31:16] !== 16'h5443) diverge("HIGH_CLASS_ID", "prefix");
    if (high_subj[15:0] !== high_cid) diverge("HIGH_CLASS_ID", "low16");

    // 6) zero/unbound (piano) — no valid CLASS_ID, nothing latched
    fire_q(8'd0, 8'd0, 8'd0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0);
    service_batch();
    $display("PIANO emit=%0d learned=%0d", n_emit, n_learned);
    if (n_learned !== 16'd0) diverge("UNBOUND", "piano must not learn");

    // C7 observe-only: recorded, not graded as identity
    $display("C7_OBS addr=%h seq=%0d ack=%0d", c7a, c7seq, c7cnt);

    $display("U7A_R3B_TYPECLASS_TO_LEARN_REACHABILITY_PASS");
    $finish;
  end
endmodule
