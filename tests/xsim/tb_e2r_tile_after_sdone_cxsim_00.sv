// E2R-TILE-AFTER-SDONE-CXSIM-00 — first tile chunk after dma_done
// Vehicle: weight_tile803k #(.SIM_FULL(0)) TILE generate only.
// Same clk for clk and clk_dma. No soc_top, no MIG, no grant bags.
// Force miss: addr_a region != cur_rg (rg_of). we_a stays 0.
// Stub DMA: dma_go → busy=1; dest D_DRAIN (dma_r_ready) → 8 R beats;
// then pulse dma_done 1 cycle and clear busy. Do NOT hold busy after done.
// Snap dest==4, then dest==5, then bst after that.
// Do not require stall=0 after one chunk (nline>1 keeps stall).
// UNKNOWN: after dma_done at D_WAITDONE, does bst leave B_REQ?
// Do not force dest/bst. Do not C-FIX. XSim ≠ board.
`timescale 1ns/1ps

module tb_e2r_tile_after_sdone_cxsim_00;
  import a7lm06_pkg::*;

  localparam realtime CLK_HALF = 5.0; // 10 ns → 100 MHz
  localparam int unsigned TO_CYC = 4096;
  localparam int unsigned POST_D5_WATCH = 32;
  localparam logic [2:0] D_WAITDONE = 3'd4;
  localparam logic [2:0] D_ACK      = 3'd5;
  localparam logic [3:0] B_REQ      = 4'd4;
  localparam logic [3:0] B_WAITACK  = 4'd5;
  localparam logic [3:0] B_STORE    = 4'd6;

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

  int unsigned cyc;
  int unsigned post_d5;
  int unsigned r_beats;
  bit saw_d4;
  bit saw_d5;
  bit saw_done_at_d4;
  bit saw_bst_leave_req;
  bit classified;
  bit dma_go_seen;
  logic [3:0] bst_after_d5;
  logic [3:0] bst_max_after_d5;
  logic [2:0] dest_at_d4, dest_at_d5;
  logic [3:0] bst_at_d4, bst_at_d5;
  logic [2:0] dbg_dst_at_d4, dbg_dst_at_d5;
  logic stall_at_d4, stall_at_d5, stall_after;
  logic req_at_d4, req_at_d5, req_after;
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

  // Completable refill stub. Pulse done, drop busy. No hold-busy falsifier.
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

  task automatic emit_class(input string cls);
    begin
      class_s = cls;
      classified = 1'b1;
      $display("CLASS=%s", cls);
      $display("C_FIX=NONE");
      $display("BOARD_PASS=not_claimed");
      $display("EXISTENCE=not_claimed");
      $display("PROGRAM=NO");
      $display("XSIM=PASS");
      $display("E2R_TILE_AFTER_SDONE_CXSIM_00_XSIM_PASS class=%s c_fix=NONE dest4=%0d dest5=%0d bst_after=%0d stall_after=%0d req_after=%0d",
               cls, saw_d4, saw_d5, bst_after_d5, stall_after, req_after);
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
    post_d5 = 0;
    saw_d4  = 1'b0;
    saw_d5  = 1'b0;
    saw_done_at_d4 = 1'b0;
    saw_bst_leave_req = 1'b0;
    classified = 1'b0;
    dma_go_seen = 1'b0;
    bst_after_d5 = 4'd0;
    bst_max_after_d5 = 4'd0;
    dest_at_d4 = 3'd0;
    dest_at_d5 = 3'd0;
    bst_at_d4 = 4'd0;
    bst_at_d5 = 4'd0;
    dbg_dst_at_d4 = 3'd0;
    dbg_dst_at_d5 = 3'd0;
    stall_at_d4 = 1'b0;
    stall_at_d5 = 1'b0;
    stall_after = 1'b0;
    req_at_d4 = 1'b0;
    req_at_d5 = 1'b0;
    req_after = 1'b0;
    class_s = "NONE";

    $display("VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB");
    $display("MISS_FORCE addr_a=OFF_POS(%0d) cur_rg_reset=0 we_a=0", OFF_POS);
    $display("DST D_IDLE=0 D_GO=1 D_FEED=2 D_DRAIN=3 D_WAITDONE=4 D_ACK=5");
    $display("BST B_IDLE=0 B_FILL=1 B_FWAIT=2 B_FCAP=3 B_REQ=4 B_WAITACK=5 B_STORE=6 B_SWAIT=7 B_NEXT=8");

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);
    // Force miss: POS region, cur_rg stays TOK=0 until refill completes.
    addr_a = 20'(OFF_POS);

    forever begin
      @(posedge clk);
      cyc = cyc + 1;
      if (dma_go)
        dma_go_seen = 1'b1;
      if (dma_done && dest_live == D_WAITDONE)
        saw_done_at_d4 = 1'b1;

      if (!saw_d4 && dest_live == D_WAITDONE) begin
        saw_d4 = 1'b1;
        dest_at_d4 = dest_live;
        bst_at_d4 = bst_live;
        dbg_dst_at_d4 = dbg_dst;
        stall_at_d4 = stall;
        req_at_d4 = dbg_req;
        $display("SNAP_D4 cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d req=%0d req_s1=%0d miss=%0d busy=%0d done=%0d r_ready=%0d go_seen=%0d ack=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dbg_req, dbg_req_s1,
                 dbg_miss, dma_busy, dma_done, dma_r_ready, dma_go_seen, ack_live);
      end

      if (saw_d4 && !saw_d5 && dest_live == D_ACK) begin
        saw_d5 = 1'b1;
        dest_at_d5 = dest_live;
        bst_at_d5 = bst_live;
        dbg_dst_at_d5 = dbg_dst;
        stall_at_d5 = stall;
        req_at_d5 = dbg_req;
        bst_after_d5 = bst_live;
        bst_max_after_d5 = bst_live;
        $display("SNAP_D5 cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d req=%0d req_s1=%0d miss=%0d busy=%0d done=%0d ack=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dbg_req, dbg_req_s1,
                 dbg_miss, dma_busy, dma_done, ack_live);
      end

      if (saw_d5 && !classified) begin
        post_d5 = post_d5 + 1;
        if (bst_live > bst_max_after_d5)
          bst_max_after_d5 = bst_live;
        bst_after_d5 = bst_live;
        stall_after = stall;
        req_after = dbg_req;
        if (bst_live >= B_WAITACK)
          saw_bst_leave_req = 1'b1;
        if (saw_bst_leave_req) begin
          $display("SNAP_BST_AFTER cyc=%0d dest=%0d dbg_dst=%0d bst=%0d bst_max=%0d stall=%0d req=%0d ack=%0d watch=%0d",
                   cyc, dest_live, dbg_dst, bst_live, bst_max_after_d5, stall, dbg_req,
                   ack_live, post_d5);
          emit_class("CHUNK_ACK");
        end else if (post_d5 >= POST_D5_WATCH) begin
          $display("SNAP_BST_AFTER cyc=%0d dest=%0d dbg_dst=%0d bst=%0d bst_max=%0d stall=%0d req=%0d ack=%0d watch=%0d",
                   cyc, dest_live, dbg_dst, bst_live, bst_max_after_d5, stall, dbg_req,
                   ack_live, post_d5);
          if (bst_after_d5 == B_REQ && bst_max_after_d5 == B_REQ)
            emit_class("ACK_STUCK");
          else if (bst_after_d5 >= B_WAITACK || bst_max_after_d5 >= B_WAITACK)
            emit_class("CHUNK_ACK");
          else
            emit_class("ACK_STUCK");
        end
      end

      if (!classified && cyc >= TO_CYC) begin
        $display("TIMEOUT cyc=%0d dest=%0d dbg_dst=%0d bst=%0d stall=%0d req=%0d miss=%0d go_seen=%0d d4=%0d d5=%0d done_at_d4=%0d",
                 cyc, dest_live, dbg_dst, bst_live, stall, dbg_req, dbg_miss,
                 dma_go_seen, saw_d4, saw_d5, saw_done_at_d4);
        if (!saw_d4)
          emit_class("NO_MISS");
        else if (!saw_d5)
          emit_class("DEST_STUCK");
        else
          emit_class("ACK_STUCK");
      end
    end
  end
endmodule
