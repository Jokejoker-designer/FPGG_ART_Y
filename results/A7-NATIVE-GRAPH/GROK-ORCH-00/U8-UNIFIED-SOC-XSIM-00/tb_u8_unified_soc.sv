// tb_u8_unified_soc.sv — U8-UNIFIED-SOC-XSIM-00
// Raw query bytes only. No poke of eid/iid/rid/xid. No native_ctx_bind.
// DUT = a7ng_typeclass_soc_chain. Stop at first divergence.
// SEMANTIC_LM=MISMATCH. BIT=NO PROGRAM=NO QHEAD=NO.
`timescale 1ns / 1ps

module tb_u8_unified_soc;
  import a7ng_pkg::*;
  localparam int K = 8;
  localparam int MAX_NTOK = 64;
  localparam int NPARAM = 802816;
  localparam int TO = 400000000;
  localparam int QLEN = 15;
  localparam logic [7:0] QBYTES [0:QLEN-1] = '{
    8'h69, 8'h6e, 8'h73, 8'h74, 8'h61, 8'h6c, 8'h6c, 8'h20,
    8'h63, 8'h68, 8'h69, 8'h6c, 8'h6c, 8'h65, 8'h72
  };

  logic clk, rst_n, tok_v, tok_r, fire, retire, qse_v;
  logic [7:0] tok, qe, qi, qr, qx;
  logic retr_done, chain_busy, chain_done;
  logic [15:0] top_cid [K];
  node_id_t    top_id  [K];
  logic [15:0] n_host;
  logic [6:0]  enc_ntok;
  logic [7:0]  enc_tok [0:MAX_NTOK-1];
  logic [3:0]  n_rec, n_skip;
  logic ctx_we, start_fwd, core_busy, core_done;
  logic [6:0] ctx_idx, ctx_n;
  logic [63:0] ctx_pack;
  logic [9:0] pred;
  logic [31:0] ctx_beats, st_beats;
  logic [2:0]  cst;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic signed [7:0] wmem [0:NPARAM-1];

  integer n_ctx_we, n_sfwd, n_busy_rise, n_done, n_mem_exam;
  logic ctx_d, sf_d, busy_d, done_d, exam;
  logic [7:0] ctx_tok [0:MAX_NTOK-1];
  integer i, ki, g, wd, tmo, fails, bi;

  a7ng_typeclass_soc_chain #(.CAND_CAP(64), .K(K), .MAX_NTOK(MAX_NTOK), .SIM_FULL(1'b1)) dut (
    .clk(clk), .rst_n(rst_n),
    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),
    .fire_i(fire), .retire_i(retire),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .qse_valid_o(qse_v), .q_ent_o(qe), .q_int_o(qi), .q_rel_o(qr), .q_ctx_o(qx),
    .retrieval_done_o(retr_done), .topk_class_id_o(top_cid), .topk_id_o(top_id),
    .n_host_or_o(n_host),
    .enc_ntok_o(enc_ntok), .enc_tok_o(enc_tok), .enc_n_rec_o(n_rec), .enc_n_skip_o(n_skip),
    .ctx_we_o(ctx_we), .ctx_idx_o(ctx_idx), .ctx_n_in_o(ctx_n), .ctx_pack_o(ctx_pack),
    .start_fwd_o(start_fwd), .core_busy_o(core_busy), .core_done_o(core_done),
    .pred_o(pred), .chain_busy_o(chain_busy), .chain_done_o(chain_done),
    .ctx_we_beats_o(ctx_beats), .start_fwd_beats_o(st_beats), .dbg_st_o(cst)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      n_ctx_we <= 0; n_sfwd <= 0; n_busy_rise <= 0; n_done <= 0; n_mem_exam <= 0;
      ctx_d <= 0; sf_d <= 0; busy_d <= 0; done_d <= 0;
      for (ki = 0; ki < MAX_NTOK; ki = ki + 1) ctx_tok[ki] <= 8'd0;
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
    end
  end

  task automatic diverge(input string c, input string d);
    begin
      $display("FIRST_DIVERGENCE %s %s", c, d);
      fails = fails + 1;
      #20 $finish;
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
    tok_v = 0; tok = 0; fire = 0; retire = 0;
    mem_we = 0; mem_addr = 0; mem_wdata = 0;
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk); rst_n = 1;
    repeat (4) @(posedge clk);

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    $display("WMEM_INIT n=%0d", NPARAM);
    exam = 1;

    retire <= 1; @(posedge clk); retire <= 0;
    @(posedge clk);
    for (bi = 0; bi < QLEN; bi = bi + 1) begin
      @(posedge clk);
      tmo = 0;
      while (!tok_r && tmo < 4000) begin @(posedge clk); tmo++; end
      if (!tok_r) diverge("QSE_STALL", "tok_ready");
      tok_v <= 1; tok <= QBYTES[bi];
      @(posedge clk); tok_v <= 0;
    end
    @(posedge clk); fire <= 1; @(posedge clk); fire <= 0;

    tmo = 0;
    while (!qse_v && tmo < 8000) begin @(posedge clk); tmo++; end
    if (!qse_v) diverge("QSE_FIELD_MISMATCH", "no valid");
    $display("QSE eid=%0d iid=%0d rid=%0d xid=%0d", qe, qi, qr, qx);
    if (qe !== 8'd1 || qi !== 8'd1 || qr !== 8'd0 || qx !== 8'd0)
      diverge("QSE_FIELD_MISMATCH", "not install-chiller 1,1,0,0");
    if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "qse");

    tmo = 0;
    while (!retr_done && tmo < 400000) begin
      @(posedge clk);
      if (n_host !== 16'd0) diverge("HOST_SEMANTIC_LEAK", "retrieval");
      tmo++;
    end
    if (!retr_done) diverge("RETRIEVAL_DONE", "timeout");
    @(posedge clk);
    $display("HEAP cid=%0d %0d %0d %0d %0d %0d %0d %0d",
      top_cid[0], top_cid[1], top_cid[2], top_cid[3],
      top_cid[4], top_cid[5], top_cid[6], top_cid[7]);
    if (top_cid[0] !== 16'd65 || top_cid[1] !== 16'd66 || top_cid[2] !== 16'd67)
      diverge("TOPK_MISMATCH", "not 65,66,67");
    for (i = 3; i < K; i = i + 1)
      if (top_cid[i] >= 16'd1 && top_cid[i] <= 16'd443)
        diverge("TOPK_MISMATCH", "unexpected valid pad");
    for (i = 0; i < K; i = i + 1)
      if (top_id[i][31:16] != 16'd0 && top_cid[i] <= 16'd443 && top_cid[i] >= 16'd1)
        diverge("CLASS_ID_NID_CONFUSION", "hi bits");

    g = 0;
    while (!chain_done && !core_done && g < TO) begin @(posedge clk); g++; end
    if (!core_done && !chain_done) diverge("LM_DONE", "timeout");
    g = 0;
    while (!chain_done && g < 64) begin @(posedge clk); g++; end
    repeat (4) @(posedge clk);

    $display("HIER u_u6/u_enc/u_fwd/u_lm06 present");
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
    $display("CHAIN ctx_beats=%0d sfwd_beats=%0d pred=%0d cst=%0d",
      ctx_beats, st_beats, pred, cst);
    $display("HOST n_or=%0d mem_exam=%0d", n_host, n_mem_exam);

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
    if (n_sfwd < 1) diverge("START_FWD", "zero pulses");
    if (n_host !== 0 || n_mem_exam !== 0) diverge("HOST_SEMANTIC_LEAK", "counters");

    $display("PRED_OBS core=%0d (not HOLD_A oracle; not OUT=653 claim)", pred);
    $display("SEMANTIC_LM_CLAIM=NO CLASS=LM_CHECKPOINT_CONTEXT_MISMATCH");
    $display("SOC_TOP=NOT_INSTANTIATED (native_ctx_bind still in ab_core; P8)");
    $display("BIT=NO PROGRAM=NO QHEAD=NO HOLD_A_ORACLE_RETARGET=NO U8R=NO");
    $display("U8_UNIFIED_SOC_XSIM_PASS");
    $finish;
  end
endmodule
