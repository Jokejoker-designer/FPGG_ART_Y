// tb_a7ng_teacher_off_soc.sv — G14-TEACHER-OFF-NATIVE-CAUSALITY-00
// Gate T: host-off → native retrieval → HOLD_A C9. OUT observed, not scored.
`timescale 1ns / 1ps

module tb_a7ng_teacher_off_soc;
  import a7ng_pkg::*;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  localparam logic [7:0] T_HOLD_A=8'hA2, T_UNREL=8'hA3, T_CONTRA=8'hA4, T_HOLD_B=8'hB2;
  localparam logic [63:0] PACK_A = 64'h8382238122802120;
  localparam logic [63:0] PACK_U = 64'h8786858483828180;
  localparam logic [63:0] PACK_C = 64'h2322832182208180;
  localparam logic [63:0] PACK_B = 64'h8382438142804140;
  localparam logic [9:0]  OUT_A = 10'd653, OUT_U = 10'd689, OUT_C = 10'd237, OUT_B = 10'd60;
  localparam int NPARAM = 802816;
  localparam int TO = 40000000;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd, mode;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic [63:0] anch, topk;
  logic lmst, lmdn;
  logic [9:0] lmout;
  logic [15:0] ncue, nwin, naddr, ntok, nw, nmode;
  logic [2:0] ack;
  logic lmused;
  node_id_t tid [8];
  score_t tsc [8];
  logic [15:0] txn, c7seq, c7cnt;
  logic c5, pbusy, pdone, c7v, afor, bvis, qv, qr, sv;
  logic [31:0] c8g, c7a, r1s, r1o;
  logic [63:0] c8d, adig, bdig, ctx_pack;
  logic [7:0] r1r, qid;
  logic [127:0] scpack;
  logic ctx_we;
  logic [6:0] ctx_idx, ctx_n;

  a7ng_gate14_c9_soc_cofit_xsim dut (
    .clk(clk), .rst_n(rst_n),
    .cmd_valid_i(cv), .cmd_ready_o(cr), .cmd_i(cmd), .tok_i(tok), .reward_i(rew),
    .mem_we_i(mem_we), .mem_addr_i(mem_addr), .mem_wdata_i(mem_wdata),
    .mem_rdata_o(mem_rdata),
    .c1_mode_o(mode), .c2_anch_o(anch),
    .c9_topk_o(topk), .c9_score_o(scpack),
    .c9_r1s_o(r1s), .c9_r1r_o(r1r), .c9_r1o_o(r1o),
    .c10_lmst_o(lmst), .c10_lmdn_o(lmdn), .c10_out_o(lmout),
    .n_host_cue_o(ncue), .n_host_win_o(nwin), .n_host_addr_o(naddr),
    .n_host_tok_o(ntok), .n_host_w_o(nw), .n_host_mode_o(nmode),
    .last_ack_o(ack), .exam_lm_used_o(lmused),
    .topk_id_o(tid), .topk_sc_o(tsc),
    .p_txn_o(txn), .c5_cons_o(c5), .c8_gen_o(c8g), .c8_sdig_o(c8d),
    .c7_addr_o(c7a), .c7_v_o(c7v),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
    .query_valid_o(qv), .query_ready_o(qr), .query_id_o(qid),
    .snap_valid_o(sv),
    .ctx_we_obs_o(ctx_we), .ctx_idx_obs_o(ctx_idx),
    .ctx_n_obs_o(ctx_n), .ctx_pack_obs_o(ctx_pack),
    .c11_adig_o(adig), .c11_bdig_o(bdig), .c11_a_for_o(afor), .c11_b_vis_o(bvis)
  );

  initial clk = 0;
  always #40 clk = ~clk;

  integer fails, i, g, k, wd;
  integer cmd_accept_n, graph_accept_n, reward_commit_n, snap_n, cmd_dup_n;
  integer a_graph_n, b_graph_n, a_rew_n, b_rew_n;
  integer a_cmd_fire_n, b_cmd_fire_n, gen_before, gen_after;
  integer lmst_rise, last_lmst_cyc, phase, ctx_we_n, start_fwd_n;
  logic [19:0] a_tok_mask, b_tok_mask;
  logic signed [7:0] wmem [0:NPARAM-1];
  logic lmst_d, cv_d, cr_d, qv_d, qr_d, sv_d, c7v_d;
  logic [7:0] last_graph_qid, expected_qid;
  string first_div;
  localparam logic [63:0] PACK_FORGET = 64'h2322832182208180;
  logic [9:0] out_a, out_u, out_c, out_b;
  logic [63:0] pack_a, pack_u, pack_c, pack_b;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;
  always @(posedge clk) begin
    lmst_d <= lmst;
    if (rst_n && lmst && !lmst_d) begin
      lmst_rise = lmst_rise + 1;
      last_lmst_cyc = wd;
      $display("LMST_RISE n=%0d cyc=%0d", lmst_rise, wd);
    end
  end

  function automatic logic [7:0] map_qid(input logic [7:0] t);
    if (t == T_HOLD_A) return 8'h02;
    if (t == T_UNREL)  return 8'h03;
    if (t == T_CONTRA) return 8'h04;
    if (t == T_HOLD_B) return 8'h06;
    return t;
  endfunction

  always @(posedge clk) begin
    cv_d <= cv; cr_d <= cr; qv_d <= qv; qr_d <= qr;
    sv_d <= sv; c7v_d <= c7v;
    if (rst_n && cv && !cr)
      $display("CMD_STALL cyc=%0d cmd=%0d tok=%h ready=0", wd, cmd, tok);
    if (rst_n && cv && cr) begin
      cmd_accept_n <= cmd_accept_n + 1;
      $display("CMD_ACCEPT seq=%0d cmd=%0d tok=%h reward=%0d",
               cmd_accept_n + 1, cmd, tok, rew);
      if (cv_d && cr_d) begin
        cmd_dup_n <= cmd_dup_n + 1;
        $display("CMD_DUPLICATE cyc=%0d cmd=%0d tok=%h", wd, cmd, tok);
      end
      if (cmd == C_FIRE && phase == 1) a_cmd_fire_n <= a_cmd_fire_n + 1;
      if (cmd == C_FIRE && phase == 3) b_cmd_fire_n <= b_cmd_fire_n + 1;
    end
    if (rst_n && ctx_we) begin
      ctx_we_n <= ctx_we_n + 1;
      $display("CTX_BEAT idx=%0d n=%0d pack=%h c9=%h beats=%0d",
               ctx_idx, ctx_n, ctx_pack, topk, ctx_we_n + 1);
    end
    if (rst_n && qv && qr) begin
      graph_accept_n <= graph_accept_n + 1;
      last_graph_qid <= qid;
      $display("GRAPH_ACCEPT seq=%0d qid=%h", graph_accept_n + 1, qid);
      if (qid >= 8'h10 && qid <= 8'h23 && !a_tok_mask[qid - 8'h10]) begin
        a_tok_mask[qid - 8'h10] <= 1'b1;
        a_graph_n <= a_graph_n + 1;
      end
      if (qid >= 8'h30 && qid <= 8'h43 && !b_tok_mask[qid - 8'h30]) begin
        b_tok_mask[qid - 8'h30] <= 1'b1;
        b_graph_n <= b_graph_n + 1;
      end
    end
    if (rst_n && sv && !sv_d) begin
      snap_n <= snap_n + 1;
      $display("SNAP_RISE n=%0d qid=%h", snap_n + 1, last_graph_qid);
    end
    if (rst_n && c7v && !c7v_d) begin
      reward_commit_n <= reward_commit_n + 1;
      $display("REWARD_COMMIT ack_count=%0d commit_seq=%0d txn=%0d qid=%h",
               c7cnt, c7seq, txn, last_graph_qid);
      if (phase == 1) a_rew_n <= a_rew_n + 1;
      if (phase == 3) b_rew_n <= b_rew_n + 1;
    end
  end

  task automatic stop_div(input string tag);
    begin
      first_div = tag;
      fails = fails + 1;
      $display("FIRST_DIVERGENCE=%s", tag);
      $display("A_GRAPH_ACCEPT_COUNT=%0d A_REWARD_COMMIT_COUNT=%0d", a_graph_n, a_rew_n);
      $display("B_GRAPH_ACCEPT_COUNT=%0d B_REWARD_COMMIT_COUNT=%0d", b_graph_n, b_rew_n);
      $display("C9_PACK_A/U/C/B=%h/%h/%h/%h", pack_a, pack_u, pack_c, pack_b);
      $display("LM_OUT_A/U/C/B=%0d/%0d/%0d/%0d", out_a, out_u, out_c, out_b);
      $display("GATE14_C9_SOC_COFIT_XSIM_FAIL fails=%0d", fails);
      $finish;
    end
  endtask

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    integer cmd0, graph0, rew0, snap0, ack0, seq0, gen0, accepted, saw_done, dcmd, dgraph, dsnap, drew;
    begin
      cmd0 = cmd_accept_n; graph0 = graph_accept_n; rew0 = reward_commit_n;
      snap0 = snap_n; ack0 = c7cnt; seq0 = c7seq; gen0 = c8g;
      g = 0;
      while (!(cr && !cv) && g < TO) begin @(posedge clk); g++; end
      if (!(cr && !cv)) stop_div("CMD_READY_BEFORE_SEND");
      @(negedge clk); cmd = c; tok = t; rew = r; cv = 1'b1;
      accepted = 0; g = 0;
      while (!accepted && g < TO) begin
        @(posedge clk); g++;
        if (cv && cr) accepted = 1;
      end
      if (!accepted) stop_div("CMD_ACCEPT_MISS");
      @(negedge clk); cv = 1'b0;
      @(posedge clk);
      dcmd = cmd_accept_n - cmd0;
      if (dcmd != 1) stop_div($sformatf("CMD_ACCEPT_DELTA=%0d cmd=%0d", dcmd, c));
      case (c)
        C_FIRE: begin
          g = 0;
          while (!(qv && qr) && g < TO) begin @(posedge clk); g++; end
          if (!(qv && qr)) stop_div("GRAPH_ACCEPT_MISS");
          if (qid !== expected_qid)
            stop_div($sformatf("QID_MISMATCH got=%h want=%h", qid, expected_qid));
          g = 0;
          while (!sv && g < TO) begin @(posedge clk); g++; end
          if (!sv) stop_div("SNAP_MISS");
          g = 0;
          while (!cr && g < TO) begin @(posedge clk); g++; end
          if (!cr) stop_div("C_FIRE not idle");
          @(posedge clk);
          dgraph = graph_accept_n - graph0;
          dsnap  = snap_n - snap0;
          if (dgraph != 1) stop_div($sformatf("GRAPH_ACCEPT_DELTA=%0d", dgraph));
          if (dsnap != 1)  stop_div($sformatf("SNAP_DELTA=%0d", dsnap));
        end
        C_REW: begin
          g = 0;
          while (!c7v && g < TO) begin @(posedge clk); g++; end
          if (!c7v) stop_div("REWARD_COMMIT_MISS");
          @(posedge clk);
          drew = reward_commit_n - rew0;
          if (drew != 1) stop_div($sformatf("REWARD_COMMIT_DELTA=%0d", drew));
          if (c7cnt != ack0 + 16'd1) stop_div("ACK_COUNT");
          if (c7seq != seq0 + 16'd1) stop_div("COMMIT_SEQ");
          g = 0;
          while (pbusy && g < TO) begin @(posedge clk); g++; end
        end
        C_FLUSH, C_RELOAD: begin
          saw_done = 0; g = 0;
          while (g < TO) begin
            @(posedge clk); g++;
            if (pdone) saw_done = 1;
            if (saw_done && !pbusy) break;
          end
          if (!saw_done) stop_div("PERSIST_DONE_MISS");
          if (pbusy) stop_div("PERSIST_BUSY_STUCK");
        end
        C_TRESET: begin
          g = 0;
          while (c8g == gen0 && g < TO) begin @(posedge clk); g++; end
          if (c8g != gen0 + 32'd1) stop_div("TRESET_GEN_MISS");
        end
        C_KILL: begin
          g = 0;
          while (!pdone && g < TO) begin @(posedge clk); g++; end
          if (!pdone) stop_div("KILL_DONE_MISS");
        end
        default: ;
      endcase
    end
  endtask

  task automatic fire_tok(input logic [7:0] t);
    begin
      expected_qid = map_qid(t);
      do_cmd(C_TOK, t, 0);
      do_cmd(C_FIRE, 0, 0);
    end
  endtask

  task automatic exam_query(input string tag, input logic [7:0] t,
                            input logic [9:0] exp_out, input logic [63:0] exp_pack);
    integer rise0;
    begin
      rise0 = lmst_rise;
      fire_tok(t);
      $display("EXAM %s MODE=%h C9=%h OUT=%0d LMST=%0d LMDN=%0d",
               tag, mode, topk, lmout, lmst, lmdn);
      if (mode != 4'h8) stop_div({tag, "_MODE"});
      if (topk !== exp_pack) begin
        $display("FAIL %s C9 pack %h want %h — not running LM compare", tag, topk, exp_pack);
        stop_div({tag, "_C9"});
      end
      $display("OUT_OBSERVED %s OUT=%0d oracle=%0d (Gate T does not score OUT)",
               tag, lmout, exp_out);
    end
  endtask

  initial begin
    wait (wd > 400000000);
    $display("FAIL TB watchdog");
    stop_div("WATCHDOG");
  end

  initial begin
    fails = 0; cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    mem_we = 0; lmst_rise = 0; last_lmst_cyc = -1;
    cmd_accept_n = 0; graph_accept_n = 0; reward_commit_n = 0; snap_n = 0; cmd_dup_n = 0;
    a_graph_n = 0; b_graph_n = 0; a_rew_n = 0; b_rew_n = 0;
    a_cmd_fire_n = 0; b_cmd_fire_n = 0; gen_before = 0; gen_after = 0;
    ctx_we_n = 0; start_fwd_n = 0; expected_qid = 8'd0;
    a_tok_mask = 20'd0; b_tok_mask = 20'd0; phase = 0;
    first_div = "NONE"; last_graph_qid = 8'd0;
    out_a = 0; out_u = 0; out_c = 0; out_b = 0;
    pack_a = 0; pack_u = 0; pack_c = 0; pack_b = 0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk);
    rst_n = 1;
    i = 0;
    while (!cr && i < 8000) begin @(posedge clk); i++; end
    if (!cr) stop_div("BOOT_CMD_READY");

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    $display("WMEM_INIT n=%0d", NPARAM);

    if (mode != 4'h5) stop_div("BOOT_MODE");
    do_cmd(C_TRAIN, 0, 0);

    phase = 1;
    for (k = 0; k < 20; k = k + 1) begin
      $display("LESSON_A k=%0d tok=%h (intent only)", k, 8'h10 + k[7:0]);
      fire_tok(8'h10 + k[7:0]);
      do_cmd(C_REW, 0, 4'sd3);
    end
    $display("CURRICULUM_A_TOTAL GRAPH_ACCEPT_DISTINCT=%0d REWARD_COMMIT=%0d ack=%0d seq=%0d",
             a_graph_n, a_rew_n, c7cnt, c7seq);
    if (a_graph_n != 20) stop_div("A_GRAPH_ACCEPT_COUNT");
    if (a_rew_n != 20)   stop_div("A_REWARD_COMMIT_COUNT");
    if (c7cnt != 16'd20) stop_div("A_ACK_COUNT");
    if (c7seq != 16'd20) stop_div("A_COMMIT_SEQ");

    do_cmd(C_FLUSH, 0, 0);
    do_cmd(C_KILL, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    if (mode != 4'h8) stop_div("FREEZE_MODE");
    fire_tok(T_HOLD_A);
    $display("AFTER_KILL HOLD_A C9=%h r1=%h", topk, topk[7:0]);
    if (topk[7:0] !== 8'h80) stop_div("KILL_HIDE");
    $display("PERSIST_KILL_OK");

    do_cmd(C_RELOAD, 0, 0);
    do_cmd(C_FREEZE, 0, 0);
    phase = 2;
    $display("GATE_T_PRE_EXAM mode=%h learn=%0d freeze=%0d n_host cue/win/addr/tok/w/mode=%0d/%0d/%0d/%0d/%0d/%0d",
             mode, dut.u_cofit.p_learn, dut.u_cofit.p_freeze,
             ncue, nwin, naddr, ntok, nw, nmode);
    if (mode != 4'h8) stop_div("MODE_NOT_FREEZE");
    if (dut.u_cofit.p_learn !== 1'b0) stop_div("LEARN_NOT_0");
    if (dut.u_cofit.p_freeze !== 1'b1) stop_div("FREEZE_NOT_1");
    exam_query("HOLD_A", T_HOLD_A, OUT_A, PACK_A);
    pack_a = topk; out_a = lmout;
    $display("GATE_T HOLD_A C9=%h OUT_OBSERVED=%0d learn=%0d freeze=%0d",
             pack_a, out_a, dut.u_cofit.p_learn, dut.u_cofit.p_freeze);
    if (pack_a !== PACK_A) stop_div("C9_TEACHER_OFF");
    if (dut.u_cofit.p_learn !== 1'b0) stop_div("LEARN_NOT_0_AFTER");
    if (dut.u_cofit.p_freeze !== 1'b1) stop_div("FREEZE_NOT_1_AFTER");
    if (ncue != 0 || nwin != 0 || naddr != 0 || ntok != 0 || nw != 0 || nmode != 0)
      stop_div("HOST_INGRESS");
    $display("HOST_WIRES_ZERO cue/win/addr/next/wren/mode counters all 0");
    $display("FIRST_DIVERGENCE=NONE");
    $display("TEACHER_OFF_SOC_XSIM_PASS fails=0 C9A=%h OUT_OBSERVED=%0d", pack_a, out_a);
    $finish;
  end
endmodule
