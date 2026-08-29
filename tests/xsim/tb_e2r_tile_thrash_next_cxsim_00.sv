// E2R-TILE-THRASH-NEXT-CXSIM-00 — POS region then TOK addr miss
// Copy of tb_e2r_tile_nline_bound_cxsim_00.sv. ONE change: after first
// stall==0, set addr_a to TOK (OFF_TOK / 0). Completable stub for EVERY
// dma_go (8 R + done + busy clear). Watch for a NEW dest=4 after the
// switch, or timeout >=500_000 dest-clk after switch. Do not require
// TOK region to finish. Print cur_rg / miss / dest4_cnt before and after
// switch. Classify only.
// Vehicle: weight_tile803k #(.SIM_FULL(0)) TILE generate only.
// Same clk for clk and clk_dma. No soc_top, no MIG, no grant bags.
// Force first miss: addr_a=OFF_POS (rg=1) while cur_rg_reset=0. we_a=0.
// UNKNOWN: after first POS stall=0, does TOK addr start a second dest=4?
// Do not force dest/bst. Do not C-FIX. XSim ≠ board.
`timescale 1ns/1ps

module tb_e2r_tile_thrash_next_cxsim_00;
  import a7lm06_pkg::*;

  localparam realtime CLK_HALF = 5.0; // 10 ns → 100 MHz
  localparam int unsigned TO_FIRST = 1000000;
  localparam int unsigned TO_AFTER = 500000;
  localparam logic [2:0] D_IDLE     = 3'd0;
  localparam logic [2:0] D_WAITDONE = 3'd4;
  localparam logic [2:0] D_ACK      = 3'd5;
  localparam logic [3:0] B_WAITACK  = 4'd5;

  logic clk;
  logic rst_n;
  logic we_a;
  logic [19:0] addr_a, addr_b;
  logic signed [7:0] wdata_a, rdata_a, rdata_b;
  logic stall, dirty, dma_owner;
  logic [2:0] cached_rg;
  logic dma_go, dma_wr;
  logic [27:0] dma_addr;
  logic [31:0] dma_bytes;
  logic dma_busy, dma_done;
  logic dma_w_valid, dma_w_ready;
  logic [127:0] dma_w_data;
  logic dma_r_valid, dma_r_ready;
  logic [127:0] dma_r_data;
  logic [3:0] dbg_bst;
  logic [2:0] dbg_dst, dbg_cur_rg;
  logic dbg_miss, dbg_dirty, dbg_req, dbg_req_s1;

  logic [2:0] dest_live;
  logic [3:0] bst_live;
  logic ack_live;
  logic [10:0] nline_live;
  logic [2:0] hold_rg_live;
  logic [10:0] ch_live;

  int unsigned cyc;
  int unsigned r_beats;
  int unsigned dma_go_cyc_cnt;
  int unsigned dma_go_burst_cnt;
  int unsigned dest4_cnt;
  int unsigned dest4_at_switch;
  int unsigned dest4_after_switch;
  int unsigned nline_meas;
  int unsigned stall0_cyc;
  int unsigned switch_cyc;
  int unsigned dest4_2_cyc;
  int unsigned dest4_post_cyc;
  bit saw_d4_1;
  bit saw_d5_1;
  bit saw_idle_after_ack;
  bit saw_d4_2;
  bit saw_stall0;
  bit switched;
  bit saw_d4_after;
  bit classified;
  bit dma_go_d;
  bit dest4_d;
  logic [2:0] dest_after_ack;
  logic [3:0] bst_after_ack;
  logic [3:0] bst_at_d4_2;
  logic [3:0] bst_end;
  logic stall_at_d4_2;
  logic stall_end;
  logic [2:0] cur_rg_before;
  logic [2:0] cur_rg_after;
  logic miss_before;
  logic miss_after;
  logic stall_before;
  logic stall_after;
  string class_s;

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WAIT_DRAIN,
    ST_BEATS,
    ST_PULSE
  } stub_e;
  stub_e stub;

  initial clk = 1'b0;
  always #(CLK_HALF) clk = ~clk;

  assign dma_w_ready = 1'b1;
  assign dest_live = dut.TILE.dst;
  assign bst_live  = dut.TILE.bst;
  assign ack_live  = dut.TILE.ack;
  assign nline_live = dut.TILE.nline_h;
  assign hold_rg_live = dut.TILE.hold_rg;
  assign ch_live = dut.TILE.ch;

  weight_tile803k #(.SIM_FULL(1'b0)) dut (
    .clk(clk), .rst_n(rst_n),
    .clk_dma(clk), .rst_dma_n(rst_n),
    .we_a(we_a), .addr_a(addr_a), .wdata_a(wdata_a), .rdata_a(rdata_a),
    .addr_b(addr_b), .rdata_b(rdata_b),
    .stall(stall), .cached_rg(cached_rg), .dirty(dirty),
    .dma_owner(dma_owner),
    .dma_go(dma_go), .dma_wr(dma_wr), .dma_addr(dma_addr), .dma_bytes(dma_bytes),
    .dma_busy(dma_busy), .dma_done(dma_done),
    .dma_w_valid(dma_w_valid), .dma_w_ready(dma_w_ready), .dma_w_data(dma_w_data),
    .dma_r_valid(dma_r_valid), .dma_r_ready(dma_r_ready), .dma_r_data(dma_r_data),
    .dbg_bst(dbg_bst), .dbg_dst(dbg_dst), .dbg_cur_rg(dbg_cur_rg),
    .dbg_miss(dbg_miss), .dbg_dirty(dbg_dirty),
    .dbg_req(dbg_req), .dbg_req_s1(dbg_req_s1)
  );

  // Completable refill stub for EVERY dma_go. Pulse done, drop busy.
  // Returns to ST_IDLE so a later go is not blocked. No hold-busy falsifier.
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dma_busy   <= 1'b0;
      dma_done   <= 1'b0;
      dma_r_valid <= 1'b0;
      dma_r_data <= 128'd0;
      r_beats    <= 0;
      stub       <= ST_IDLE;
    end else begin
      dma_done <= 1'b0;
      unique case (stub)
        ST_IDLE: begin
          dma_r_valid <= 1'b0;
          if (dma_go) begin
            dma_busy <= 1'b1;
            r_beats  <= 0;
            stub     <= ST_WAIT_DRAIN;
          end
        end
        ST_WAIT_DRAIN: begin
          if (dma_r_ready) begin
            dma_r_valid <= 1'b1;
            dma_r_data  <= {16{8'hA5}};
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
            dma_r_data <= {16{8'(8'hA0 + r_beats[7:0])}};
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

  function automatic int unsigned nline_law(input logic [2:0] rg);
    return (rg == 3'd1) ? 128 : 1024;
  endfunction

  task automatic emit_class(input string cls);
    begin
      class_s = cls;
      classified = 1'b1;
      bst_end = bst_live;
      stall_end = stall;
      dest4_after_switch = dest4_cnt - dest4_at_switch;
      $display("CLASS=%s", cls);
      $display("C_FIX=NONE");
      $display("BOARD_PASS=not_claimed");
      $display("EXISTENCE=not_claimed");
      $display("PROGRAM=NO");
      $display("XSIM=PASS");
      $display("TIMEOUT_FIRST=%0d TIMEOUT_AFTER=%0d", TO_FIRST, TO_AFTER);
      $display("NLINE_MEAS=%0d NLINE_H=%0d NLINE_LAW_HOLD=%0d HOLD_RG=%0d CUR_RG=%0d DBG_CUR_RG=%0d CH=%0d",
               nline_meas, nline_live, nline_law(hold_rg_live),
               hold_rg_live, cached_rg, dbg_cur_rg, ch_live);
      $display("DEST4_CNT=%0d DEST4_AT_SWITCH=%0d DEST4_AFTER_SWITCH=%0d DMA_GO_BURST=%0d DMA_GO_CYC=%0d",
               dest4_cnt, dest4_at_switch, dest4_after_switch,
               dma_go_burst_cnt, dma_go_cyc_cnt);
      $display("STALL0_CYC=%0d SWITCH_CYC=%0d DEST4_POST_CYC=%0d STALL_END=%0d BST_END=%0d",
               stall0_cyc, switch_cyc, dest4_post_cyc, stall_end, bst_end);
      $display("CUR_RG_BEFORE=%0d CUR_RG_AFTER=%0d MISS_BEFORE=%0d MISS_AFTER=%0d STALL_BEFORE=%0d STALL_AFTER=%0d",
               cur_rg_before, cur_rg_after, miss_before, miss_after,
               stall_before, stall_after);
      $display("E2R_TILE_THRASH_NEXT_CXSIM_00_XSIM_PASS class=%s c_fix=NONE dest4_cnt=%0d dest4_after_switch=%0d dma_go_burst=%0d nline=%0d stall_end=%0d stall0_cyc=%0d switch_cyc=%0d dest4_post_cyc=%0d cur_rg_before=%0d cur_rg_after=%0d miss_before=%0d miss_after=%0d dest5=%0d dest0=%0d dest4_2=%0d",
               cls, dest4_cnt, dest4_after_switch, dma_go_burst_cnt, nline_meas,
               stall_end, stall0_cyc, switch_cyc, dest4_post_cyc,
               cur_rg_before, cur_rg_after, miss_before, miss_after,
               saw_d5_1, saw_idle_after_ack, saw_d4_2);
      $finish;
    end
  endtask

  initial begin
    we_a    = 1'b0;
    wdata_a = 8'sd0;
    addr_a  = 20'd0;
    addr_b  = 20'd0;
    rst_n   = 1'b0;
    cyc     = 0;
    dma_go_cyc_cnt = 0;
    dma_go_burst_cnt = 0;
    dest4_cnt = 0;
    dest4_at_switch = 0;
    dest4_after_switch = 0;
    nline_meas = 0;
    stall0_cyc = 0;
    switch_cyc = 0;
    dest4_2_cyc = 0;
    dest4_post_cyc = 0;
    saw_d4_1 = 1'b0;
    saw_d5_1 = 1'b0;
    saw_idle_after_ack = 1'b0;
    saw_d4_2 = 1'b0;
    saw_stall0 = 1'b0;
    switched = 1'b0;
    saw_d4_after = 1'b0;
    classified = 1'b0;
    dma_go_d = 1'b0;
    dest4_d = 1'b0;
    dest_after_ack = 3'd7;
    bst_after_ack = 4'd0;
    bst_at_d4_2 = 4'd0;
    bst_end = 4'd0;
    stall_at_d4_2 = 1'b0;
    stall_end = 1'b1;
    cur_rg_before = 3'd7;
    cur_rg_after = 3'd7;
    miss_before = 1'b0;
    miss_after = 1'b0;
    stall_before = 1'b1;
    stall_after = 1'b0;
    class_s = "NONE";

    $display("VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO");
    $display("MISS_FORCE addr_a=OFF_POS(%0d) then after stall=0 addr_a=OFF_TOK(%0d) we_a=0",
             OFF_POS, OFF_TOK);
    $display("RG_NLINE_LAW POS_rg1=128 else=1024 rg_of(<OFF_POS)=0");
    $display("DST D_IDLE=0 D_GO=1 D_FEED=2 D_DRAIN=3 D_WAITDONE=4 D_ACK=5");
    $display("BST B_IDLE=0 B_FILL=1 B_FWAIT=2 B_FCAP=3 B_REQ=4 B_WAITACK=5 B_STORE=6 B_SWAIT=7 B_NEXT=8");
    $display("WATCH first stall==0 then TOK switch; new dest=4 OR timeout TO_AFTER=%0d; TO_FIRST=%0d; do not finish TOK region",
             TO_AFTER, TO_FIRST);

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);
    // Force first miss: POS region, cur_rg stays TOK=0 until refill completes.
    addr_a = 20'(OFF_POS);

    forever begin
      @(posedge clk);
      cyc = cyc + 1;

      if (dma_go && !dma_go_d) begin
        dma_go_burst_cnt = dma_go_burst_cnt + 1;
        if (dma_go_burst_cnt <= 2 || (dma_go_burst_cnt % 32) == 0 || switched)
          $display("SNAP_GO_BURST cyc=%0d burst=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d dest4=%0d switched=%0d",
                   cyc, dma_go_burst_cnt, dest_live, dbg_dst, bst_live, stall,
                   nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live,
                   dest4_cnt, switched);
      end
      if (dma_go)
        dma_go_cyc_cnt = dma_go_cyc_cnt + 1;
      dma_go_d = dma_go;

      if (dest_live == D_WAITDONE && !dest4_d) begin
        dest4_cnt = dest4_cnt + 1;
        if (nline_meas == 0)
          nline_meas = int'(nline_live);
        if (dest4_cnt == 1) begin
          saw_d4_1 = 1'b1;
          $display("SNAP_D4_1 cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d dest4=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d",
                   cyc, dest_live, dbg_dst, bst_live, stall, dest4_cnt,
                   nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live);
        end else if (dest4_cnt == 2) begin
          saw_d4_2 = 1'b1;
          dest4_2_cyc = cyc;
          bst_at_d4_2 = bst_live;
          stall_at_d4_2 = stall;
          $display("SNAP_D4_2 cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d dest4=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d CONTROL_CHUNK2",
                   cyc, dest_live, dbg_dst, bst_live, stall, dest4_cnt,
                   nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live);
        end else if (switched && !saw_d4_after) begin
          saw_d4_after = 1'b1;
          dest4_post_cyc = cyc;
          dest4_after_switch = dest4_cnt - dest4_at_switch;
          $display("SNAP_D4_AFTER_SWITCH cyc=%0d dest=%0d bst=%0d stall=%0d dest4=%0d dest4_after=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d burst=%0d",
                   cyc, dest_live, bst_live, stall, dest4_cnt, dest4_after_switch,
                   nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live,
                   dma_go_burst_cnt);
        end else if ((dest4_cnt % 32) == 0 || dest4_cnt == nline_meas) begin
          $display("SNAP_D4 cyc=%0d dest4=%0d dest=%0d bst=%0d stall=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d burst=%0d switched=%0d",
                   cyc, dest4_cnt, dest_live, bst_live, stall,
                   nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live,
                   dma_go_burst_cnt, switched);
        end
      end
      dest4_d = (dest_live == D_WAITDONE);

      if (saw_d4_1 && !saw_d5_1 && dest_live == D_ACK) begin
        saw_d5_1 = 1'b1;
        dest_after_ack = dest_live;
        bst_after_ack = bst_live;
        $display("SNAP_D5_1 cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d dest4=%0d burst=%0d ack=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dest4_cnt,
                 dma_go_burst_cnt, ack_live);
      end

      if (saw_d5_1 && !saw_idle_after_ack && dest_live == D_IDLE) begin
        saw_idle_after_ack = 1'b1;
        $display("SNAP_IDLE cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d dest4=%0d burst=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dest4_cnt,
                 dma_go_burst_cnt);
      end

      // ONE change vs NLINE-BOUND: do not stop at first stall=0.
      // Record CONTROL snap, then drive TOK address.
      if (!classified && !switched && stall == 1'b0 && dest4_cnt > 0) begin
        saw_stall0 = 1'b1;
        stall0_cyc = cyc;
        dest4_at_switch = dest4_cnt;
        cur_rg_before = cached_rg;
        miss_before = dbg_miss;
        stall_before = stall;
        $display("SNAP_STALL0_BEFORE_SWITCH cyc=%0d dest=%0d bst=%0d dest4=%0d burst=%0d nline_h=%0d nline_meas=%0d hold_rg=%0d cur_rg=%0d miss=%0d stall=%0d ch=%0d addr_a=%0d",
                 cyc, dest_live, bst_live, dest4_cnt, dma_go_burst_cnt,
                 nline_live, nline_meas, hold_rg_live, cached_rg, dbg_miss,
                 stall, ch_live, addr_a);
        addr_a = 20'(OFF_TOK);
        switched = 1'b1;
        switch_cyc = cyc;
        cur_rg_after = cached_rg;
        miss_after = dbg_miss;
        stall_after = stall;
        $display("SNAP_SWITCH_TOK cyc=%0d addr_a=%0d OFF_TOK=%0d dest4=%0d cur_rg=%0d miss=%0d stall=%0d dest=%0d bst=%0d",
                 cyc, addr_a, OFF_TOK, dest4_cnt, cached_rg, dbg_miss, stall,
                 dest_live, bst_live);
      end

      if (!classified && switched && saw_d4_after) begin
        emit_class("THRASH_NEXT");
      end

      if (!classified && switched && (cyc - switch_cyc) >= TO_AFTER) begin
        $display("TIMEOUT_AFTER_SWITCH cyc=%0d delta=%0d dest=%0d bst=%0d stall=%0d dest4=%0d dest4_at_switch=%0d burst=%0d cur_rg=%0d miss=%0d",
                 cyc, (cyc - switch_cyc), dest_live, bst_live, stall, dest4_cnt,
                 dest4_at_switch, dma_go_burst_cnt, cached_rg, dbg_miss);
        if (saw_d5_1 && dest_live == D_ACK && dest4_cnt <= dest4_at_switch)
          emit_class("ACK_HOLD");
        else
          emit_class("HIT_HOLD");
      end

      if (!classified && !switched && cyc >= TO_FIRST) begin
        $display("TIMEOUT_FIRST cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d dest4=%0d burst=%0d d5_1=%0d dest0=%0d d4_2=%0d nline_h=%0d hold_rg=%0d cur_rg=%0d miss=%0d ch=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dest4_cnt,
                 dma_go_burst_cnt, saw_d5_1, saw_idle_after_ack, saw_d4_2,
                 nline_live, hold_rg_live, cached_rg, dbg_miss, ch_live);
        if (saw_d5_1 && dest_live == D_ACK && dest4_cnt <= 1)
          emit_class("ACK_HOLD");
        else
          emit_class("NO_DONE");
      end
    end
  end
endmodule
