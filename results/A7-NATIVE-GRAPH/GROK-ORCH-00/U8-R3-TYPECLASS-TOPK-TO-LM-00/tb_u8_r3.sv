// tb_u8_r3.sv — U8-R3-TYPECLASS-TOPK-TO-LM-00
// Ranking CLASS_ID heap → encoder V1 → ctx_we eirx beats → one start_fwd
// → LM-06 SIM_FULL → one done. Host tok/w/win/addr = 0.
// Semantic LM claim = MISMATCH. No CLASS_ID-as-token. No bind low8.
// PROGRAM=NO. QHEAD=NO. BIT=NO. HOLD_A not retargeted.
`timescale 1ns / 1ps

module tb_u8_r3;
  import a7ng_pkg::*;
  localparam int K = 8;
  localparam int MAX_NTOK = 64;
  localparam int NPARAM = 802816;
  localparam int TO = 400000000;

  logic clk, rst_n;
  logic learn, freeze, train_after;
  logic poke, poke_go, pev, piv, prv, pxv;
  logic [7:0] pe, pi, pr, px;
  logic flush, reload, kill, trst;
  logic rank_done, train_done;
  logic [15:0] n_emit, n_scored, n_learned, n_host;
  logic [15:0] top_cid [K];
  node_id_t    top_id  [K];
  score_t      top_sc  [K];
  logic cand_v, cand_hit;
  logic [15:0] cand_cid;
  score_t cand_sc;
  logic signed [7:0] cand_pri;
  logic rew_v, echo_v, rew_rdy, pending, ack_v;
  logic signed [3:0] rew;
  logic [15:0] txn, echo;
  logic [2:0] ack;
  logic [15:0] learn_cid;
  logic [31:0] learn_subj, learn_obj;
  logic [7:0]  learn_rel;
  logic pbusy, pdone, pnak, boot_done, c7v;
  logic [31:0] c7a;
  logic [15:0] c7seq, c7cnt;
  logic [4:0] st;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata, ddr_mem [0:255];

  logic [15:0] cid [0:K-1];
  logic enc_go, enc_busy, enc_done, enc_beat_v;
  logic [6:0] enc_ntok;
  logic [3:0] enc_beat_n, n_rec, n_skip;
  logic [63:0] enc_pack;
  logic [7:0] enc_tok [0:MAX_NTOK-1];

  logic glue_go, glue_busy, glue_done;
  logic ctx_we, start_fwd, core_busy, core_done;
  logic [6:0] ctx_idx, ctx_n;
  logic [63:0] ctx_pack;
  logic [9:0] core_pred, glue_pred;
  logic [31:0] ctx_beats, st_beats;

  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic signed [7:0] wmem [0:NPARAM-1];

  integer n_ctx_we, n_sfwd, n_busy_rise, n_done, n_mem_exam;
  logic ctx_d, sf_d, busy_d, done_d, exam;
  logic [7:0] ctx_tok [0:MAX_NTOK-1];
  integer i, ki, g, wd, tmo, fails, n_host_tok, n_host_w, n_host_win, n_host_addr;

  a7ng_u7_contextual_rank #(.CAND_CAP(64), .K(K)) u_rank (
    .clk(clk), .rst_n(rst_n),
    .learn_i(learn), .freeze_i(freeze), .train_after_i(train_after),
    .poke_i(poke), .poke_go_i(poke_go),
    .poke_ent_i(pe), .poke_int_i(pi), .poke_rel_i(pr), .poke_ctx_i(px),
    .poke_ev_i(pev), .poke_iv_i(piv), .poke_rv_i(prv), .poke_xv_i(pxv),
    .flush_i(flush), .reload_i(reload), .bram_kill_i(kill), .train_reset_i(trst),
    .rank_done_o(rank_done), .train_done_o(train_done),
    .n_emit_o(n_emit), .n_scored_o(n_scored), .n_learned_o(n_learned),
    .n_host_or_o(n_host),
    .topk_id_o(top_id), .topk_class_id_o(top_cid), .topk_sc_o(top_sc),
    .cand_rep_v_o(cand_v), .cand_rep_cid_o(cand_cid), .cand_rep_sc_o(cand_sc),
    .cand_rep_pri_o(cand_pri), .cand_rep_hit_o(cand_hit),
    .reward_valid_i(rew_v), .reward_i(rew),
    .txn_echo_valid_i(echo_v), .txn_echo_i(echo),
    .reward_ready_o(rew_rdy), .pending_o(pending), .txn_o(txn),
    .ack_valid_o(ack_v), .ack_o(ack),
    .learn_cid_o(learn_cid), .learn_subj_o(learn_subj),
    .learn_rel_o(learn_rel), .learn_obj_o(learn_obj),
    .persist_busy_o(pbusy), .persist_done_o(pdone), .persist_nak_o(pnak),
    .boot_done_o(boot_done),
    .c7_ack_valid_o(c7v), .c7_addr_o(c7a),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .dbg_st_o(st),
    .ddr_req_o(ddr_req), .ddr_we_o(ddr_we), .ddr_addr_o(ddr_addr),
    .ddr_wdata_o(ddr_wdata), .ddr_rdata_i(ddr_rdata), .ddr_ack_i(ddr_ack)
  );

  a7ng_lm_ctx_encoder_v1 #(.K(K), .MAX_NTOK(MAX_NTOK)) u_enc (
    .clk(clk), .rst_n(rst_n), .go_i(enc_go),
    .class_id_i(cid),
    .busy_o(enc_busy), .done_o(enc_done),
    .ntok_o(enc_ntok), .beat_v_o(enc_beat_v), .beat_n_o(enc_beat_n),
    .beat_pack_o(enc_pack), .tok_o(enc_tok),
    .n_rec_o(n_rec), .n_skip_o(n_skip)
  );

  a7ng_lm_ctx_fwd_v1 u_fwd (
    .clk(clk), .rst_n(rst_n), .go_i(glue_go),
    .enc_go_o(enc_go),
    .enc_busy_i(enc_busy), .enc_done_i(enc_done), .enc_ntok_i(enc_ntok),
    .enc_beat_v_i(enc_beat_v), .enc_beat_n_i(enc_beat_n),
    .enc_beat_pack_i(enc_pack),
    .core_busy_i(core_busy), .core_done_i(core_done), .core_pred_i(core_pred),
    .ctx_we_o(ctx_we), .ctx_idx_o(ctx_idx), .ctx_n_in_o(ctx_n),
    .ctx_pack_o(ctx_pack), .start_fwd_o(start_fwd),
    .busy_o(glue_busy), .done_o(glue_done), .pred_o(glue_pred),
    .ctx_we_beats_o(ctx_beats), .start_fwd_beats_o(st_beats)
  );

  tiny_gpt803k_core #(.SIM_FULL(1'b1)) u_lm06 (
    .clk(clk), .rst_n(rst_n),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n), .ctx_pack(ctx_pack),
    .start_fwd(start_fwd),
    .start_train(1'b0), .start_ce(1'b0), .start_corpus(1'b0),
    .after_mode(1'b0), .do_snap(1'b0), .do_restore(1'b0), .do_fold(1'b0),
    .tgt_in(10'd0), .lr_in(4'd0), .corpus_n(8'd0), .corpus_ep(8'd0),
    .busy(core_busy), .done(core_done), .pred(core_pred),
    .last_loss(), .ce0(), .ce1(), .wr_n(), .xor32(), .add32(),
    .phase(), .w_stall(),
    .clk_dma(1'b0), .rst_dma_n(1'b1),
    .wdma_owner(), .wdma_go(), .wdma_wr(), .wdma_addr(), .wdma_bytes(),
    .wdma_busy(1'b0), .wdma_done(1'b0),
    .wdma_w_valid(), .wdma_w_ready(1'b0), .wdma_w_data(),
    .wdma_r_valid(1'b0), .wdma_r_ready(), .wdma_r_data(128'd0),
    .dbg_tile_bst(), .dbg_tile_dst(), .dbg_tile_rg(),
    .dbg_tile_miss(), .dbg_tile_dirty(), .dbg_tile_req(), .dbg_tile_req_s1()
  );

  initial clk = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk) if (ddr_req && ddr_we) ddr_mem[ddr_addr] <= ddr_wdata;
  assign ddr_ack   = ddr_req;
  assign ddr_rdata = ddr_mem[ddr_addr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      n_ctx_we <= 0; n_sfwd <= 0; n_busy_rise <= 0; n_done <= 0; n_mem_exam <= 0;
      ctx_d <= 0; sf_d <= 0; busy_d <= 0; done_d <= 0;
      for (ki = 0; ki < MAX_NTOK; ki = ki + 1) ctx_tok[ki] <= 8'd0;
      for (ki = 0; ki < K; ki = ki + 1) cid[ki] <= 16'd0;
    end else begin
      ctx_d <= ctx_we;
      sf_d  <= start_fwd;
      busy_d <= core_busy;
      done_d <= core_done;
      if (ctx_we) n_ctx_we <= n_ctx_we + 1;
      if (start_fwd && !sf_d) n_sfwd <= n_sfwd + 1;
      if (core_busy && !busy_d) n_busy_rise <= n_busy_rise + 1;
      if (core_done && !done_d) n_done <= n_done + 1;
      if (exam && mem_we) n_mem_exam <= n_mem_exam + 1;
      if (ctx_we) begin
        for (ki = 0; ki < 8; ki = ki + 1)
          if (({9'd0, ctx_idx} + ki) < MAX_NTOK)
            ctx_tok[ctx_idx + ki[6:0]] <= ctx_pack[8*ki +: 8];
      end
      if (rank_done) begin
        for (ki = 0; ki < K; ki = ki + 1)
          cid[ki] <= top_cid[ki];
      end
    end
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
      fails = fails + 1;
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

  task automatic wait_idle;
    begin
      tmo = 0;
      while ((st != 5'd1 || pbusy) && tmo < 200000) begin @(posedge clk); tmo++; end
      if (st != 5'd1 || pbusy) diverge("EARLY_DONE", "idle");
    end
  endtask

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;
  initial begin
    wd = 0;
    wait (wd > TO);
    $display("FAIL TB watchdog cyc=%0d", wd);
    $finish;
  end

  initial begin
    fails = 0; rst_n = 0; exam = 0;
    learn = 1; freeze = 1; train_after = 0;
    poke = 0; poke_go = 0; pe = 0; pi = 0; pr = 0; px = 0;
    pev = 0; piv = 0; prv = 0; pxv = 0;
    flush = 0; reload = 0; kill = 0; trst = 0;
    rew_v = 0; echo_v = 0; rew = 0; echo = 0;
    glue_go = 0; mem_we = 0; mem_addr = 0; mem_wdata = 0;
    n_host_tok = 0; n_host_w = 0; n_host_win = 0; n_host_addr = 0;
    for (i = 0; i < 256; i = i + 1) ddr_mem[i] = 64'd0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk); rst_n = 1;
    wait_boot();
    wait_idle();

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    $display("WMEM_INIT n=%0d", NPARAM);
    exam = 1;

    wait_idle();
    @(negedge clk);
    poke = 1; pe = 8'd1; pi = 8'd1; pr = 8'd0; px = 8'd0;
    pev = 1; piv = 1; prv = 0; pxv = 0;
    poke_go = 1;
    @(posedge clk); @(negedge clk); poke_go = 0;

    tmo = 0;
    while (!rank_done && tmo < 400000) begin
      @(posedge clk);
      if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "n_host rank");
      tmo++;
    end
    if (!rank_done) diverge("EARLY_DONE", "rank timeout");
    @(posedge clk); @(posedge clk);
    poke = 0;
    $display("HEAP cid=%0d %0d %0d %0d %0d %0d %0d %0d",
      cid[0], cid[1], cid[2], cid[3], cid[4], cid[5], cid[6], cid[7]);
    if (cid[0] !== 16'd65 || cid[1] !== 16'd66 || cid[2] !== 16'd67)
      diverge("RANK_HEAP", "not 65,66,67");
    for (i = 3; i < K; i = i + 1)
      if (cid[i] >= 16'd1 && cid[i] <= 16'd443)
        diverge("RANK_HEAP", "unexpected valid pad");

    @(negedge clk); glue_go = 1;
    @(posedge clk); @(negedge clk); glue_go = 0;

    g = 0;
    while (!glue_done && !core_done && g < TO) begin @(posedge clk); g++; end
    if (!core_done && !glue_done) diverge("LM_DONE", "timeout");
    g = 0;
    while (!glue_done && g < 64) begin @(posedge clk); g++; end
    repeat (4) @(posedge clk);

    $display("ENC ntok=%0d rec=%0d skip=%0d", enc_ntok, n_rec, n_skip);
    $display("ENC stream %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
      enc_tok[0], enc_tok[1], enc_tok[2], enc_tok[3],
      enc_tok[4], enc_tok[5], enc_tok[6], enc_tok[7],
      enc_tok[8], enc_tok[9], enc_tok[10], enc_tok[11]);
    $display("CTX stream %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
      ctx_tok[0], ctx_tok[1], ctx_tok[2], ctx_tok[3],
      ctx_tok[4], ctx_tok[5], ctx_tok[6], ctx_tok[7],
      ctx_tok[8], ctx_tok[9], ctx_tok[10], ctx_tok[11]);
    $display("CHAIN ctx_we=%0d sfwd_pulses=%0d busy_rise=%0d core_done=%0d",
      n_ctx_we, n_sfwd, n_busy_rise, n_done);
    $display("CHAIN ctx_beats=%0d sfwd_beats=%0d glue_pred=%0d core_pred=%0d",
      ctx_beats, st_beats, glue_pred, core_pred);
    $display("HOST tok=%0d w=%0d win=%0d addr=%0d rank_or=%0d mem_exam=%0d",
      n_host_tok, n_host_w, n_host_win, n_host_addr, n_host, n_mem_exam);

    if (enc_ntok !== 7'd12 || n_rec !== 4'd3) diverge("ENC_NTOK", "not 12/3");
    if (enc_tok[0] !== 8'd1 || enc_tok[1] !== 8'd1 || enc_tok[2] !== 8'd0 || enc_tok[3] !== 8'd0)
      diverge("ENC_STREAM", "class65");
    if (enc_tok[4] !== 8'd1 || enc_tok[5] !== 8'd1 || enc_tok[6] !== 8'd0 || enc_tok[7] !== 8'd1)
      diverge("ENC_STREAM", "class66");
    if (enc_tok[8] !== 8'd1 || enc_tok[9] !== 8'd1 || enc_tok[10] !== 8'd1 || enc_tok[11] !== 8'd0)
      diverge("ENC_STREAM", "class67");
    for (i = 0; i < 12; i = i + 1) begin
      if (enc_tok[i] === 8'd65 || enc_tok[i] === 8'd66 || enc_tok[i] === 8'd67)
        diverge("CLASS_ID_AS_TOKEN", "stream");
      if (ctx_tok[i] !== enc_tok[i])
        diverge("CTX_PACK", $sformatf("i=%0d ctx=%0d enc=%0d", i, ctx_tok[i], enc_tok[i]));
    end
    if (n_ctx_we !== 2) diverge("CTX_WE", "not two eirx beats");
    if (ctx_beats !== 32'd2) diverge("CTX_WE", "beats");
    if (n_busy_rise !== 1) diverge("LM_BUSY", "not one forward");
    if (n_done !== 1) diverge("LM_DONE", "not exactly once");
    if (n_sfwd !== 1) diverge("START_FWD", "not exactly one pulse");
    if (glue_pred !== core_pred) diverge("PRED_OWNER", "glue!=core");
    if (n_host !== 0 || n_host_tok !== 0 || n_host_w !== 0 ||
        n_host_win !== 0 || n_host_addr !== 0)
      diverge("HOST_SEMANTIC_LEAK", "counters");
    if (n_mem_exam !== 0) diverge("HOST_SEMANTIC_LEAK", "mem_we exam");

    $display("PRED_OBS core=%0d (not HOLD_A oracle; not OUT=653 claim)", core_pred);
    $display("SEMANTIC_LM_CLAIM=NO CLASS=LM_CHECKPOINT_CONTEXT_MISMATCH");
    $display("BIT=NO PROGRAM=NO QHEAD=NO HOLD_A_ORACLE_RETARGET=NO");
    $display("CLAIM_NOT_SEMANTIC_LM");
    $display("U8_R3_TYPECLASS_TOPK_TO_LM_PASS");
    $finish;
  end
endmodule
