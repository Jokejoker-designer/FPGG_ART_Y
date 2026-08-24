// a7ng_ddr_feed_pp.sv — ping-pong DDR→WM feeder (double buffer + burst + outstanding)
// While PEs consume active bank, DDR fills inactive; swap when active empty & fill ready.
// Law: a7ng-ddr-feed-wm01-v0. HS-14 FPGA addresses. No LM-06.
`timescale 1ns / 1ps

module a7ng_ddr_feed_pp #(
  parameter int unsigned BANK_DEPTH = 32,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_i,
  input  logic [4:0]  burst_i,
  input  logic [3:0]  outstanding_i,
  input  logic [31:0] base_node_i,
  input  logic [31:0] total_recs_i,
  output logic        ar_valid_o,
  input  logic        ar_ready_i,
  output logic [31:0] ar_addr_o,
  output logic [7:0]  ar_len_o,
  output logic [3:0]  ar_id_o,
  input  logic        r_valid_i,
  output logic        r_ready_o,
  input  logic [127:0] r_data_i,
  input  logic        r_last_i,
  input  logic        pe_pop_i,
  output logic        pe_valid_o,
  output logic [127:0] pe_data_o,
  output logic        done_o,
  output logic [31:0] empty_stall_o,
  output logic [31:0] full_stall_o,
  output logic [31:0] pe_stall_o,
  output logic [31:0] pe_busy_o,
  output logic [31:0] cycles_o,
  output logic [31:0] recs_consumed_o,
  output logic [31:0] drop_o,
  output logic [15:0] occ_active_o,
  output logic [15:0] occ_fill_o,
  output logic        active_bank_o,
  output logic        running_o
);
  localparam int unsigned IDX_W = $clog2(BANK_DEPTH);

  (* ram_style = "distributed" *) logic [127:0] bank0 [BANK_DEPTH];
  (* ram_style = "distributed" *) logic [127:0] bank1 [BANK_DEPTH];

  logic              active;
  logic [IDX_W:0]    cnt0, cnt1, rd0, rd1, wr0, wr1;
  logic [31:0]       next_node, issued, returned, target;
  logic              running;
  logic [3:0]        in_flight;
  logic [3:0]        rid_q;
  logic [31:0]       empty_st, full_st, pe_st, pe_bs, cyc, cons, drops;
  logic [31:0]       pending_beats;

  wire [IDX_W:0] cnt_act  = active ? cnt1 : cnt0;
  wire [IDX_W:0] cnt_fill = active ? cnt0 : cnt1;
  wire           act_empty = (cnt_act == '0);

  assign pe_valid_o      = running && !act_empty;
  assign pe_data_o       = active ? bank1[rd1[IDX_W-1:0]] : bank0[rd0[IDX_W-1:0]];
  assign done_o          = !running && (cons >= target) && (target != 32'd0);
  assign empty_stall_o   = empty_st;
  assign full_stall_o    = full_st;
  assign pe_stall_o      = pe_st;
  assign pe_busy_o       = pe_bs;
  assign cycles_o        = cyc;
  assign recs_consumed_o = cons;
  assign drop_o          = drops;
  assign occ_active_o    = 16'(cnt_act);
  assign occ_fill_o      = 16'(cnt_fill);
  assign active_bank_o   = active;
  assign running_o       = running;
  assign r_ready_o       = running && (cnt_fill < BANK_DEPTH[IDX_W:0]);

  wire [4:0] burst_c = (burst_i == 5'd0) ? 5'd1 :
                       ((burst_i > 5'(MAX_BURST)) ? 5'(MAX_BURST) : burst_i);
  wire [3:0] out_c   = (outstanding_i == 4'd0) ? 4'd1 :
                       ((outstanding_i > 4'(MAX_OUT)) ? 4'(MAX_OUT) : outstanding_i);

  // Narrow remain math (TOTAL board/XSim cells ≪ 2^16) — cuts ui_clk carry depth (HS-12).
  wire [15:0] remain_issue16 =
      (issued[15:0] < target[15:0]) ? (target[15:0] - issued[15:0]) : 16'd0;
  wire [4:0]  this_burst_c =
      (remain_issue16 == 16'd0) ? 5'd0 :
      (remain_issue16 < 16'(burst_c)) ? 5'(remain_issue16[4:0]) : burst_c;

  wire [15:0] fill_occ16  = 16'(cnt_fill) + pending_beats[15:0];
  wire [15:0] fill_room16 =
      (fill_occ16 < 16'(BANK_DEPTH)) ? (16'(BANK_DEPTH) - fill_occ16) : 16'd0;
  wire        issue_ok_c = running && (this_burst_c != 5'd0) && (in_flight < out_c) &&
                           (fill_room16 >= 16'(this_burst_c));

  // 1-cycle AR pipeline: breaks issued→running combo (board WNS fail on clk_pll_i).
  logic        ar_valid_q;
  logic [31:0] ar_addr_q;
  logic [7:0]  ar_len_q;
  logic [3:0]  ar_id_q;
  logic [4:0]  this_burst_q;

  assign ar_valid_o = ar_valid_q;
  assign ar_addr_o  = ar_addr_q;
  assign ar_len_o   = ar_len_q;
  assign ar_id_o    = ar_id_q;

  wire do_ar = ar_valid_q && ar_ready_i;
  wire [4:0] this_burst = this_burst_q;
  wire do_r  = r_valid_i && r_ready_o;
  wire do_pe = pe_pop_i && pe_valid_o;
  // Swap only when fill has data and no orphaned beats mid-flight into fill
  // (pending==0) OR fill bank is full (can't accept more) OR all target returned.
  wire do_swap = running && act_empty && (cnt_fill != '0) &&
                 ((pending_beats == 32'd0) || (cnt_fill == BANK_DEPTH[IDX_W:0]) ||
                  (returned >= target));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active <= 1'b0;
      cnt0 <= '0; cnt1 <= '0; rd0 <= '0; rd1 <= '0; wr0 <= '0; wr1 <= '0;
      next_node <= '0; issued <= '0; returned <= '0; target <= '0;
      running <= 1'b0; in_flight <= '0; rid_q <= '0; pending_beats <= '0;
      empty_st <= '0; full_st <= '0; pe_st <= '0; pe_bs <= '0;
      cyc <= '0; cons <= '0; drops <= '0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; ar_id_q <= '0; this_burst_q <= '0;
    end else if (start_i && !running) begin
      active <= 1'b0;
      cnt0 <= '0; cnt1 <= '0; rd0 <= '0; rd1 <= '0; wr0 <= '0; wr1 <= '0;
      next_node <= base_node_i;
      issued <= '0; returned <= '0; target <= total_recs_i;
      running <= 1'b1; in_flight <= '0; rid_q <= '0; pending_beats <= '0;
      empty_st <= '0; full_st <= '0; pe_st <= '0; pe_bs <= '0;
      cyc <= '0; cons <= '0; drops <= '0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; ar_id_q <= '0; this_burst_q <= '0;
    end else if (running) begin
      automatic logic [3:0]  nf;
      automatic logic [31:0] pb;
      automatic logic [IDX_W:0] c0, c1, r0, r1, w0, w1;
      automatic logic        act;
      nf  = in_flight;
      pb  = pending_beats;
      c0  = cnt0; c1 = cnt1; r0 = rd0; r1 = rd1; w0 = wr0; w1 = wr1;
      act = active;

      cyc <= cyc + 32'd1;

      // AR pipe: after accept, drop valid and recompute next cycle from updated
      // issued (avoids stale issue_ok_c queuing one extra burst at remain==burst).
      if (do_ar) begin
        next_node    <= next_node + 32'(this_burst);
        issued       <= issued + 32'(this_burst);
        rid_q        <= rid_q + 4'd1;
        nf = nf + 4'd1;
        pb = pb + 32'(this_burst);
        ar_valid_q   <= 1'b0;
      end else if (!ar_valid_q) begin
        ar_valid_q   <= issue_ok_c;
        ar_addr_q    <= next_node;
        this_burst_q <= this_burst_c;
        ar_len_q     <= (this_burst_c == 5'd0) ? 8'd0 : 8'(this_burst_c - 5'd1);
        ar_id_q      <= rid_q;
      end

      if (do_r) begin
        if (act) begin
          bank0[w0[IDX_W-1:0]] <= r_data_i;
          w0 = w0 + 1'b1;
          c0 = c0 + 1'b1;
        end else begin
          bank1[w1[IDX_W-1:0]] <= r_data_i;
          w1 = w1 + 1'b1;
          c1 = c1 + 1'b1;
        end
        returned <= returned + 32'd1;
        pb = pb - 32'd1;
        if (r_last_i)
          nf = nf - 4'd1;
      end else if (r_valid_i && !r_ready_o) begin
        full_st <= full_st + 32'd1;
        drops   <= drops + 32'd1;
      end

      if (do_pe) begin
        if (act) begin
          r1 = r1 + 1'b1;
          c1 = c1 - 1'b1;
        end else begin
          r0 = r0 + 1'b1;
          c0 = c0 - 1'b1;
        end
        pe_bs <= pe_bs + 32'd1;
        cons  <= cons + 32'd1;
      end else if (pe_pop_i && !pe_valid_o && (cons < target)) begin
        pe_st    <= pe_st + 32'd1;
        empty_st <= empty_st + 32'd1;
      end

      // Recompute swap with post-update counts
      if ((act ? c1 : c0) == '0 && (act ? c0 : c1) != '0 &&
          (pb == 32'd0 || (act ? c0 : c1) == BANK_DEPTH[IDX_W:0] ||
           (returned + (do_r ? 32'd1 : 32'd0)) >= target)) begin
        act = ~act;
        if (act) begin
          // now active=1 → bank1 active; clear bank0 as new fill
          r0 = '0; w0 = '0; c0 = '0;
          r1 = '0;
        end else begin
          r1 = '0; w1 = '0; c1 = '0;
          r0 = '0;
        end
      end

      in_flight     <= nf;
      pending_beats <= pb;
      cnt0 <= c0; cnt1 <= c1;
      rd0 <= r0; rd1 <= r1;
      wr0 <= w0; wr1 <= w1;
      active <= act;

      if ((cons + (do_pe ? 32'd1 : 32'd0)) >= target &&
          (act ? c1 : c0) == '0 &&
          (returned + (do_r ? 32'd1 : 32'd0)) >= target &&
          pb == 32'd0 && nf == 4'd0) begin
        running <= 1'b0;
        ar_valid_q <= 1'b0;
      end
    end else begin
      ar_valid_q <= 1'b0;
    end
  end
endmodule
