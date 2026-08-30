// GO-TWOPASS-EMB-00 — bag copy of E2R-EMB-TWO-PASS-00 Test B (close664).
// Sealed two-pass core (ST_EMB_POS then ST_EMB_TOK) + same-clk DMA stub.
// FAIL if first pass reads TOK without miss. Stub ≠ MIG ≠ board. PROGRAM=NO.
`timescale 1ns/1ps
import a7lm06_pkg::*;

module tb_go_twopass_emb_00;
  localparam realtime CLK_HALF = 5.0;
  localparam int unsigned TIMEOUT_CLK = 3000000;
  localparam int EXPECT_SETS = 8 * D;
  localparam logic [2:0] D_WAITDONE = 3'd4;

  logic clk;
  logic rst_n;
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic ctx_we;
  logic [6:0] ctx_idx, ctx_n_in;
  logic [63:0] ctx_pack;
  logic start_fwd, start_train, start_ce, start_corpus;
  logic after_mode, do_snap, do_restore, do_fold;
  logic [9:0] tgt_in;
  logic [3:0] lr_in;
  logic [7:0] corpus_n, corpus_ep;
  logic busy, done;
  logic [9:0] pred;
  logic [15:0] last_loss;
  logic [31:0] ce0, ce1, wr_n, xor32, add32;
  logic [7:0] phase;
  logic w_stall;
  logic dma_busy, dma_done;
  logic dma_w_ready;
  logic dma_r_valid;
  logic [127:0] dma_r_data;
  logic dma_go, dma_wr, dma_owner, dma_w_valid, dma_r_ready;
  logic [27:0] dma_addr;
  logic [31:0] dma_bytes;
  logic [127:0] dma_w_data;
  logic [3:0] dbg_bst;
  logic [2:0] dbg_dst, dbg_rg;
  logic dbg_miss, dbg_dirty, dbg_req, dbg_req_s1;

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WAIT_DRAIN,
    ST_BEATS,
    ST_PULSE
  } stub_e;
  stub_e stub;
  int unsigned r_beats;
  logic [27:0] stub_base;

  function automatic signed [7:0] pattern_byte(input logic [19:0] wa);
    if (wa < 20'(OFF_POS))
      return 8'(8'sh11 + wa[6:0]);
    if (wa < 20'(OFF_L0))
      return 8'(8'sh55 + wa[6:0]);
    return 8'shA5;
  endfunction

  function automatic [127:0] beat_data(input logic [27:0] base, input int beat);
    logic [127:0] d;
    int b;
    logic [19:0] wa;
    begin
      d = 128'd0;
      for (b = 0; b < 16; b = b + 1) begin
        wa = 20'(base - 28'(DDR_WBASE)) + 20'(beat * 16 + b);
        d[8*b +: 8] = pattern_byte(wa);
      end
      return d;
    end
  endfunction

  initial clk = 1'b0;
  always #(CLK_HALF) clk = ~clk;

  assign dma_w_ready = 1'b1;

  int unsigned go_count, done_count, go_while_busy, false_axi, lost_or_dup;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      go_count      <= 0;
      done_count    <= 0;
      go_while_busy <= 0;
      false_axi     <= 0;
    end else begin
      if (dma_go) begin
        go_count <= go_count + 1;
        if (dma_busy)
          go_while_busy <= go_while_busy + 1;
      end
      if (dma_done)
        done_count <= done_count + 1;
    end
  end

  tiny_gpt803k_core #(.SIM_FULL(1'b0)) u_core (
    .clk(clk), .rst_n(rst_n),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n_in), .ctx_pack(ctx_pack),
    .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
    .start_corpus(start_corpus), .after_mode(after_mode),
    .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
    .tgt_in(tgt_in), .lr_in(lr_in), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
    .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
    .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32),
    .phase(phase), .w_stall(w_stall),
    .clk_dma(clk), .rst_dma_n(rst_n),
    .wdma_owner(dma_owner), .wdma_go(dma_go), .wdma_wr(dma_wr),
    .wdma_addr(dma_addr), .wdma_bytes(dma_bytes),
    .wdma_busy(dma_busy), .wdma_done(dma_done),
    .wdma_w_valid(dma_w_valid), .wdma_w_ready(dma_w_ready), .wdma_w_data(dma_w_data),
    .wdma_r_valid(dma_r_valid), .wdma_r_ready(dma_r_ready), .wdma_r_data(dma_r_data),
    .dbg_tile_bst(dbg_bst), .dbg_tile_dst(dbg_dst), .dbg_tile_rg(dbg_rg),
    .dbg_tile_miss(dbg_miss), .dbg_tile_dirty(dbg_dirty),
    .dbg_tile_req(dbg_req), .dbg_tile_req_s1(dbg_req_s1)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dma_busy    <= 1'b0;
      dma_done    <= 1'b0;
      dma_r_valid <= 1'b0;
      dma_r_data  <= 128'd0;
      r_beats     <= 0;
      stub        <= ST_IDLE;
      stub_base   <= 28'd0;
    end else begin
      dma_done <= 1'b0;
      unique case (stub)
        ST_IDLE: begin
          dma_r_valid <= 1'b0;
          if (dma_go) begin
            dma_busy  <= 1'b1;
            r_beats   <= 0;
            stub_base <= dma_addr;
            stub      <= ST_WAIT_DRAIN;
          end
        end
        ST_WAIT_DRAIN: begin
          if (dma_r_ready) begin
            dma_r_valid <= 1'b1;
            dma_r_data  <= beat_data(stub_base, 0);
            r_beats     <= 0;
            stub        <= ST_BEATS;
          end
        end
        ST_BEATS: begin
          if (r_beats == 7) begin
            dma_r_valid <= 1'b0;
            stub        <= ST_PULSE;
          end else begin
            r_beats    <= r_beats + 1;
            dma_r_data <= beat_data(stub_base, r_beats + 1);
          end
        end
        ST_PULSE: begin
          dma_done <= 1'b1;
          dma_busy <= 1'b0;
          stub     <= ST_IDLE;
        end
        default: stub <= ST_IDLE;
      endcase
    end
  end

  function automatic bit is_tok_rg(input logic [19:0] a);
    return (a < 20'(OFF_POS));
  endfunction

  function automatic bit is_pos_rg(input logic [19:0] a);
    return (a >= 20'(OFF_POS)) && (a < 20'(OFF_L0));
  endfunction

  function automatic int rg_id(input logic [19:0] a);
    if (is_tok_rg(a)) return 0;
    if (is_pos_rg(a)) return 1;
    return 2;
  endfunction

  function automatic bit in_emb(input logic [5:0] s);
    return (s == u_core.ST_EMB_POS) || (s == u_core.ST_EMB_TOK);
  endfunction

  initial begin
    int cyc;
    int tok_sets;
    int pos_sets;
    int rg_switches;
    int dest4_pos;
    int dest4_tok;
    int dest4_other;
    int emb_mismatch;
    int first_bad;
    int xz_cells;
    bit entered_emb;
    bit leave_emb;
    bit timed_out;
    bit classified;
    bit saw_pos_miss;
    bit tok_without_miss;
    bit first_miss_tok;
    bit cold_pos_done;
    bit cold_tok_done;
    bit dest4_d;
    bit tile_pass;
    logic [5:0] st_now;
    logic [5:0] st_prev;
    logic [19:0] waddr_now;
    logic [3:0] sub_now;
    logic [3:0] sub_prev;
    int rg_now;
    int rg_prev;
    logic [2:0] dest_live;
    logic [2:0] hold_rg_live;
    logic [2:0] cur_rg_live;
    int ti, di, aa;
    logic signed [7:0] tw, pw;
    logic signed [15:0] golden, got;
    logic signed [31:0] sum32;
    int first_dest4_rg;
    logic stall_end;

    clk = 1'b0;
    rst_n = 1'b0;
    mem_we = 1'b0;
    mem_addr = 20'd0;
    mem_wdata = 8'sd0;
    ctx_we = 1'b0;
    ctx_idx = 7'd0;
    ctx_n_in = 7'd8;
    ctx_pack = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    start_fwd = 1'b0;
    start_train = 1'b0;
    start_ce = 1'b0;
    start_corpus = 1'b0;
    after_mode = 1'b0;
    do_snap = 1'b0;
    do_restore = 1'b0;
    do_fold = 1'b0;
    tgt_in = 10'd0;
    lr_in = 4'd0;
    corpus_n = 8'd0;
    corpus_ep = 8'd0;

    cyc = 0;
    tok_sets = 0;
    pos_sets = 0;
    rg_switches = 0;
    dest4_pos = 0;
    dest4_tok = 0;
    dest4_other = 0;
    emb_mismatch = 0;
    first_bad = -1;
    xz_cells = 0;
    entered_emb = 1'b0;
    leave_emb = 1'b0;
    timed_out = 1'b0;
    classified = 1'b0;
    saw_pos_miss = 1'b0;
    tok_without_miss = 1'b0;
    first_miss_tok = 1'b0;
    cold_pos_done = 1'b0;
    cold_tok_done = 1'b0;
    dest4_d = 1'b0;
    tile_pass = 1'b0;
    st_prev = 6'd0;
    sub_prev = 4'd0;
    rg_prev = 0;
    first_dest4_rg = -1;
    stall_end = 1'b1;

    $display("GO-TWOPASS-EMB-00 START");
    $display("E2R-EMB-TWO-PASS-00 TEST_B START");
    $display("VEHICLE=tiny_gpt803k_core SIM_FULL=0 COLD_TILE same_clk_dma COMPLETABLE_STUB");
    $display("LAW POS_FIRST then TOK DISTINCT_DDR_PATTERNS OFF_TOK=%0d OFF_POS=%0d DDR_WBASE=%0d",
             OFF_TOK, OFF_POS, DDR_WBASE);
    $display("LAW DEST4_POS=128 DEST4_TOK=1024 DEST4_TOTAL=1152 TIMEOUT_CLK=%0d", TIMEOUT_CLK);
    $display("C_FIX=NONE PROGRAM=NO BOARD_PASS=not_claimed");

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);

    @(posedge clk);
    ctx_we <= 1'b1;
    ctx_idx <= 7'd0;
    ctx_n_in <= 7'd8;
    @(posedge clk);
    ctx_we <= 1'b0;
    @(posedge clk);
    $display("CTX_LOAD ntok=%0d", u_core.ntok);

    @(posedge clk);
    start_fwd <= 1'b1;
    @(posedge clk);
    start_fwd <= 1'b0;

    while (!classified && !timed_out) begin
      @(posedge clk);
      #1;
      st_now = u_core.st;
      waddr_now = u_core.waddr;
      sub_now = u_core.sub;
      rg_now = rg_id(waddr_now);
      dest_live = u_core.u_w.TILE.dst;
      hold_rg_live = u_core.u_w.TILE.hold_rg;
      cur_rg_live = u_core.u_w.TILE.cur_rg;
      cyc = cyc + 1;

      if (in_emb(st_now)) begin
        if (!entered_emb) begin
          entered_emb = 1'b1;
          $display("ENTER_EMB cyc=%0d st=%0d waddr=%0d sub=%0d rg=%0d miss=%0b stall=%0b cur_rg=%0d",
                   cyc, st_now, waddr_now, sub_now, rg_now, dbg_miss, w_stall, cur_rg_live);
        end

        if ((st_now == u_core.ST_EMB_POS) && (sub_now == 4'd1) && (sub_prev == 4'd0)) begin
          pos_sets = pos_sets + 1;
          if (pos_sets == 1)
            $display("POS_SET n=1 cyc=%0d waddr=%0d miss=%0b cur_rg=%0d",
                     cyc, waddr_now, dbg_miss, cur_rg_live);
        end
        if ((st_now == u_core.ST_EMB_TOK) && (sub_now == 4'd1) && (sub_prev == 4'd0)) begin
          tok_sets = tok_sets + 1;
          if (tok_sets == 1) begin
            $display("TOK_SET n=1 cyc=%0d waddr=%0d miss=%0b cur_rg=%0d dest4_pos=%0d",
                     cyc, waddr_now, dbg_miss, cur_rg_live, dest4_pos);
            if (!saw_pos_miss || (dbg_miss == 1'b0 && cur_rg_live == 3'd0 && dest4_tok == 0))
              tok_without_miss = 1'b1;
          end
        end

        if (entered_emb && in_emb(st_prev) && (rg_now != rg_prev) &&
            (rg_now < 2) && (rg_prev < 2)) begin
          rg_switches = rg_switches + 1;
          $display("RG_SW n=%0d cyc=%0d prev_rg=%0d now_rg=%0d st=%0d",
                   rg_switches, cyc, rg_prev, rg_now, st_now);
        end

        if ((st_now == u_core.ST_EMB_POS) && dbg_miss && (rg_now == 1))
          saw_pos_miss = 1'b1;

        if ((st_now == u_core.ST_EMB_POS) && is_tok_rg(waddr_now) &&
            (sub_now == 4'd2) && (dbg_miss == 1'b0))
          tok_without_miss = 1'b1;
      end else if (entered_emb && !leave_emb) begin
        leave_emb = 1'b1;
        $display("LEAVE_EMB cyc=%0d st=%0d dest4_pos=%0d dest4_tok=%0d stall=%0b",
                 cyc, st_now, dest4_pos, dest4_tok, w_stall);
      end

      if (in_emb(st_now) && (dest_live == D_WAITDONE) && !dest4_d) begin
        if (hold_rg_live == 3'd1) begin
          dest4_pos = dest4_pos + 1;
          if ((dest4_pos == 1) || (dest4_pos == 128))
            $display("DEST4_POS n=%0d cyc=%0d hold_rg=%0d cur_rg=%0d ch=%0d",
                     dest4_pos, cyc, hold_rg_live, cur_rg_live, u_core.u_w.TILE.ch);
        end else if (hold_rg_live == 3'd0) begin
          dest4_tok = dest4_tok + 1;
          if ((dest4_tok == 1) || (dest4_tok == 1024))
            $display("DEST4_TOK n=%0d cyc=%0d hold_rg=%0d cur_rg=%0d ch=%0d",
                     dest4_tok, cyc, hold_rg_live, cur_rg_live, u_core.u_w.TILE.ch);
        end else
          dest4_other = dest4_other + 1;
        if (first_dest4_rg < 0) begin
          first_dest4_rg = int'(hold_rg_live);
          $display("FIRST_MISS_RG=%0d cyc=%0d (0=TOK 1=POS)", first_dest4_rg, cyc);
          if (hold_rg_live == 3'd0)
            first_miss_tok = 1'b1;
        end
      end
      dest4_d = (dest_live == D_WAITDONE);

      if (!cold_pos_done && (st_now == u_core.ST_EMB_TOK) && (dest4_pos == 128)) begin
        cold_pos_done = 1'b1;
        $display("COLD_POS_DONE dest4_pos=%0d cyc=%0d", dest4_pos, cyc);
      end
      if (!cold_tok_done && leave_emb && (dest4_tok == 1024)) begin
        cold_tok_done = 1'b1;
        $display("COLD_TOK_DONE dest4_tok=%0d cyc=%0d", dest4_tok, cyc);
      end

      if (leave_emb && (w_stall == 1'b0)) begin
        stall_end = 1'b0;
        classified = 1'b1;
      end

      if (cyc >= TIMEOUT_CLK)
        timed_out = 1'b1;

      st_prev = st_now;
      sub_prev = sub_now;
      rg_prev = rg_now;
    end

    $display("DEST4_POS=%0d DEST4_TOK=%0d DEST4_TOTAL=%0d DEST4_OTHER=%0d",
             dest4_pos, dest4_tok, dest4_pos + dest4_tok, dest4_other);
    $display("POS_SETS=%0d TOK_SETS=%0d RG_SWITCHES=%0d STALL_END=%0b LEAVE_EMB=%0b",
             pos_sets, tok_sets, rg_switches, stall_end, leave_emb);
    $display("FIRST_MISS_RG=%0d SAW_POS_MISS=%0b TOK_WITHOUT_MISS=%0b FIRST_MISS_TOK=%0b",
             first_dest4_rg, saw_pos_miss, tok_without_miss, first_miss_tok);

    if (leave_emb) begin
      $display("ACT_PEEK_LEAVE aa1023=%0d", $signed(u_core.u_a.mem[1023]));
      repeat (2) @(posedge clk);
      #1;
      $display("ACT_PEEK_RETIRE aa1023=%0d", $signed(u_core.u_a.mem[1023]));
    end

    if (leave_emb) begin
      for (ti = 0; ti < 8; ti = ti + 1) begin
        for (di = 0; di < D; di = di + 1) begin
          aa = ti * D + di;
          tw = pattern_byte(20'(OFF_TOK) + 20'(u_core.tok[ti]) * 20'(D) + 20'(di));
          pw = pattern_byte(20'(OFF_POS) + 20'(ti) * 20'(D) + 20'(di));
          sum32 = 32'(tw) + 32'(pw);
          golden = sat16(sum32);
          got = u_core.u_a.mem[aa];
          if ($isunknown(got))
            xz_cells = xz_cells + 1;
          else if (got !== golden) begin
            emb_mismatch = emb_mismatch + 1;
            if (first_bad < 0) begin
              first_bad = aa;
              $display("EMB_CELL_MISMATCH aa=%0d tok_i=%0d dim=%0d tok_w=%0d pos_w=%0d golden=%0d got=%0d",
                       aa, ti, di, tw, pw, golden, got);
            end
          end
        end
      end
    end

    $display("EMB_MISMATCH=%0d XZ_CELLS=%0d FIRST_BAD=%0d",
             emb_mismatch, xz_cells, first_bad);
    $display("EMB_EXACT=%0b", (emb_mismatch == 0) && (xz_cells == 0) && leave_emb);

    if (leave_emb && (stall_end == 1'b0) &&
        (dest4_pos == 128) && (dest4_tok == 1024) &&
        (dest4_pos + dest4_tok == 1152) &&
        (emb_mismatch == 0) && (xz_cells == 0) &&
        (rg_switches <= 2) && !tok_without_miss && !first_miss_tok &&
        saw_pos_miss && (first_dest4_rg == 1) &&
        cold_pos_done && cold_tok_done &&
        (pos_sets == EXPECT_SETS) && (tok_sets == EXPECT_SETS))
      tile_pass = 1'b1;

    lost_or_dup = go_while_busy + ((go_count != done_count) ? 1 : 0);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("EXISTENCE=not_claimed");
    $display("PROGRAM=NO");
    $display("POS_REFILL=%0b TOK_REFILL=%0b NEXT_LAYER=%0b",
             cold_pos_done, cold_tok_done, leave_emb);
    $display("GO_COUNT=%0d DONE_COUNT=%0d GO_WHILE_BUSY=%0d LOST_OR_DUP=%0d FALSE_AXI=%0d",
             go_count, done_count, go_while_busy, lost_or_dup, false_axi);
    $display("STUB_NOT_AXI=1 STUB_NE_MIG=1 STUB_NE_BOARD=1");
    if (tile_pass)
      $display("E2R_EMB_TWO_PASS_00_TILE_PASS");
    else
      $display("E2R_EMB_TWO_PASS_00_TILE_FAIL");
    if (tile_pass && (lost_or_dup == 0) && (false_axi == 0) &&
        cold_pos_done && cold_tok_done && leave_emb)
      $display("XSIM3_TRANSPORT_PASS");
    else
      $display("XSIM3_TRANSPORT_FAIL");
    if (tile_pass)
      $display("GO_TWOPASS_EMB_00_UNIT_PASS");
    else
      $display("GO_TWOPASS_EMB_00_UNIT_FAIL");
    $finish;
  end
endmodule
