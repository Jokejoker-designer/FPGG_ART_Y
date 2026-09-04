// a7ng_cue_soa_wavefront.sv — DDR-WAVE-PINGPONG-00
// Dual-bank AOS wave prefetch. MAX_INFLIGHT_WAVES=2. Same AXI RID for
// overlapping bursts; sequential R maps to bank ownership. No cross-ID
// order assumption. AR(N+1) may issue before LAST_R(N).
// Field-split banks (not 128b distributed RAM) — XSim ID-lag guard.
// Product reducer remains min-heap. PROGRAM=NO.
`timescale 1ns / 1ps

module a7ng_cue_soa_wavefront #(
  parameter int unsigned WAVE       = 16,
  parameter int unsigned MAX_CANDS  = 64,
  parameter int unsigned MAX_OUT    = 8,
  parameter int unsigned MAX_BURST  = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic         bridge_idle_i,
  input  logic [4:0]   burst_i,
  input  logic [3:0]   outstanding_i,
  input  logic [31:0]  base_node_i,
  input  logic [31:0]  total_recs_i,
  output logic         ar_valid_o,
  input  logic         ar_ready_i,
  output logic [27:0]  ar_addr_o,
  output logic [7:0]   ar_len_o,
  output logic [3:0]   ar_id_o,
  output logic [2:0]   ar_size_o,
  input  logic         r_valid_i,
  output logic         r_ready_o,
  input  logic [127:0] r_data_i,
  input  logic         r_last_i,
  input  logic         cons_ready_i,
  output logic         wave_valid_o,
  output logic [127:0] wave_rec_o [WAVE],
  output logic [31:0]  wave_base_id_o,
  output logic         running_o,
  output logic         done_o,
  output logic [31:0]  cycles_o,
  output logic [31:0]  waves_o,
  output logic [31:0]  cand_accepted_o,
  output logic [31:0]  cand_delivered_o,
  output logic [31:0]  cand_queued_o,
  output logic [31:0]  cand_inflight_o,
  output logic [31:0]  cand_pruned_o,
  output logic [31:0]  conserve_err_o,
  output logic [31:0]  data_mismatch_o,
  output logic [31:0]  swap_count_o,
  output logic [31:0]  buffer_empty_stall_o,
  output logic [31:0]  buffer_full_stall_o,
  output logic [31:0]  cons_ready_cycles_o,
  output logic [31:0]  fill_cycles_o,
  output logic [31:0]  fill_episodes_o,
  output logic [15:0]  occ_fill_o,
  output logic [15:0]  occ_drain_o,
  output logic [31:0]  soa_id_beats_o,
  output logic [31:0]  soa_cue_beats_o,
  output logic [31:0]  soa_prior_beats_o,
  output logic [31:0]  bytes_id_o,
  output logic [31:0]  bytes_cue_o,
  output logic [31:0]  bytes_prior_o,
  output logic [31:0]  bytes_total_o,
  output logic         plane_fetch_idle_o,
  output logic [31:0]  accepted_txns_o,
  output logic [31:0]  accepted_beat_credit_o,
  output logic [31:0]  returned_beats_o,
  output logic [31:0]  returned_transactions_o,
  output logic [31:0]  outstanding_txns_o,
  output logic [31:0]  unpack_beats_o
);
  import a7ng_pkg::*;

  localparam int unsigned BEAT_BYTES = 16;
  localparam int unsigned IDX_W = $clog2(WAVE);
  localparam int unsigned CNT_W = $clog2(WAVE + 1);
  localparam int unsigned MAX_INFLIGHT_WAVES = 2;
  localparam logic [3:0]  WAVE_RID = 4'd0;

  typedef enum logic [2:0] {
    ST_IDLE  = 3'd0,
    ST_ARM   = 3'd1,
    ST_FETCH = 3'd2,
    ST_HOLD  = 3'd3,
    ST_DONE  = 3'd4
  } st_t;

  st_t st;

  logic [31:0] r0_nid [WAVE];
  logic [63:0] r0_cue [WAVE];
  logic [7:0]  r0_prior [WAVE];
  logic [31:0] r1_nid [WAVE];
  logic [63:0] r1_cue [WAVE];
  logic [7:0]  r1_prior [WAVE];

  logic [CNT_W-1:0] cnt0, cnt1;
  logic             fill_sel, drain_sel;
  logic [31:0]      next_node, issued, returned, delivered, target, base_q, pending;
  logic [3:0]       in_flight;
  logic             running;
  logic [31:0]      cyc, waves, mm, cerr, swaps, empty_st, full_st, cr_cyc;
  logic [31:0]      aos_beats, acc_txns_q, ret_beats_q;
  logic [31:0]      drop_q, dup_q, overwrite_q, ooo_q, ar_overlap_n, out_hw;
  logic             start_d;
  wire              start_pulse = start_i & ~start_d;

  logic        ar_valid_q;
  logic [27:0] ar_addr_q;
  logic [7:0]  ar_len_q;
  logic [4:0]  this_burst_q;

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = 32'hDDFE_0000 + nid;
    return {c32, c32};
  endfunction

  function automatic logic [127:0] pack_desc(
      input logic [31:0] nid, input logic [63:0] cue64, input logic [7:0] prior
  );
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[95:32]   = cue64;
    b[103:96]  = prior;
    return b;
  endfunction

  function automatic logic [127:0] golden_desc(input logic [31:0] nid);
    return pack_desc(nid, golden_cue64(nid), 8'h03);
  endfunction

  wire bank_full0 = (cnt0 == CNT_W'(WAVE));
  wire bank_full1 = (cnt1 == CNT_W'(WAVE));
  wire fill_full  = fill_sel  ? bank_full1 : bank_full0;
  wire drain_full = drain_sel ? bank_full1 : bank_full0;

  assign running_o        = running;
  assign done_o           = !running && (delivered >= target) && (target != 32'd0);
  assign cycles_o         = cyc;
  assign waves_o          = waves;
  assign cand_accepted_o  = issued;
  assign cand_delivered_o = delivered;
  assign cand_queued_o    = 32'(cnt0) + 32'(cnt1);
  assign cand_inflight_o  = pending;
  assign cand_pruned_o    = 32'd0;
  assign conserve_err_o   = cerr;
  assign data_mismatch_o  = mm;
  assign swap_count_o     = swaps;
  assign buffer_empty_stall_o = empty_st;
  assign buffer_full_stall_o  = full_st;
  assign cons_ready_cycles_o  = cr_cyc;
  assign fill_cycles_o    = 32'd0;
  assign fill_episodes_o  = waves;
  assign occ_fill_o       = fill_sel  ? 16'(cnt1) : 16'(cnt0);
  assign occ_drain_o      = drain_sel ? 16'(cnt1) : 16'(cnt0);
  assign soa_id_beats_o   = aos_beats;
  assign soa_cue_beats_o  = 32'd0;
  assign soa_prior_beats_o = 32'd0;
  assign bytes_id_o       = aos_beats * 32'(BEAT_BYTES);
  assign bytes_cue_o      = 32'd0;
  assign bytes_prior_o    = 32'd0;
  assign bytes_total_o    = bytes_id_o;
  assign accepted_txns_o        = acc_txns_q;
  assign accepted_beat_credit_o = aos_beats;
  assign returned_beats_o       = ret_beats_q;
  assign returned_transactions_o = acc_txns_q;
  assign outstanding_txns_o     = {28'd0, in_flight};
  assign unpack_beats_o         = aos_beats;
  assign wave_base_id_o         = base_q + delivered;
  assign plane_fetch_idle_o     = !running && !ar_valid_q && (in_flight == 4'd0) &&
                                  (pending == 32'd0) && bridge_idle_i;

  integer wi;
  always_comb begin
    for (wi = 0; wi < int'(WAVE); wi++) begin
      if (drain_sel)
        wave_rec_o[wi] = pack_desc(r1_nid[wi], r1_cue[wi], r1_prior[wi]);
      else
        wave_rec_o[wi] = pack_desc(r0_nid[wi], r0_cue[wi], r0_prior[wi]);
    end
  end

  wire do_wave = running && drain_full && cons_ready_i;
  assign wave_valid_o = do_wave;

  assign ar_valid_o = ar_valid_q;
  assign ar_addr_o  = ar_addr_q;
  assign ar_len_o   = ar_len_q;
  assign ar_id_o    = WAVE_RID;
  assign ar_size_o  = 3'd4;

  wire do_ar = ar_valid_q && ar_ready_i;
  wire do_r  = r_valid_i && r_ready_o;
  assign r_ready_o = running && !fill_full;

  wire [4:0] burst_c = (burst_i == 5'd0) ? 5'd1 :
                       ((burst_i > 5'(MAX_BURST)) ? 5'(MAX_BURST) : burst_i);
  wire [3:0] out_c   = 4'(MAX_INFLIGHT_WAVES);

  wire [15:0] remain16 = (issued[15:0] < target[15:0]) ? (target[15:0] - issued[15:0]) : 16'd0;
  wire [4:0]  wave_cap = (remain16 < 16'(WAVE)) ? 5'(remain16[4:0]) : 5'(WAVE);
  wire [4:0]  this_burst_c = (remain16 == 16'd0) ? 5'd0 :
                             ((wave_cap < burst_c) ? wave_cap : burst_c);
  wire [15:0] held16  = 16'(cnt0) + 16'(cnt1) + pending[15:0];
  wire [15:0] room16  = (held16 < 16'(2 * WAVE)) ? (16'(2 * WAVE) - held16) : 16'd0;
  wire issue_ok_c = running && (this_burst_c != 5'd0) && (in_flight < out_c) &&
                    (room16 >= 16'(this_burst_c));

  always_comb begin
    if (!running && (delivered >= target) && (target != 32'd0))
      st = ST_DONE;
    else if (!running)
      st = ST_IDLE;
    else if ((in_flight != 4'd0) || ar_valid_q)
      st = ST_FETCH;
    else if (drain_full)
      st = ST_HOLD;
    else
      st = ST_ARM;
  end

  wire [27:0] aos_base = NG_DDR_NODE_BASE + {base_q[23:0], 4'b0000};
  wire        mig_ar_fire = ar_valid_o && ar_ready_i;

`ifndef SYNTHESIS
  logic first_ar_seen;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      first_ar_seen <= 1'b0;
    else if (start_pulse)
      first_ar_seen <= 1'b0;
    else if (mig_ar_fire && !first_ar_seen) begin
      first_ar_seen <= 1'b1;
      if (ar_addr_o != (NG_DDR_NODE_BASE + {base_node_i[23:0], 4'b0000}) &&
          ar_addr_o != aos_base) begin
        $error("first_ar_not_aos_base: got=0x%08h expect=0x%08h",
               ar_addr_o, NG_DDR_NODE_BASE + {base_node_i[23:0], 4'b0000});
        $fatal(1, "AOS first AR must be NODE_BASE + base*16");
      end
    end
  end
`endif

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt0 <= '0; cnt1 <= '0;
      fill_sel <= 1'b0; drain_sel <= 1'b0;
      next_node <= '0; issued <= '0; returned <= '0; delivered <= '0;
      target <= '0; base_q <= '0; pending <= '0;
      in_flight <= '0; running <= 1'b0;
      cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
      empty_st <= '0; full_st <= '0; cr_cyc <= '0;
      aos_beats <= '0; acc_txns_q <= '0; ret_beats_q <= '0;
      drop_q <= '0; dup_q <= '0; overwrite_q <= '0; ooo_q <= '0;
      ar_overlap_n <= '0; out_hw <= '0;
      ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; this_burst_q <= '0;
      start_d <= 1'b0;
    end else begin
      start_d <= start_i;
      if (start_pulse) begin
        cnt0 <= '0; cnt1 <= '0;
        fill_sel <= 1'b0; drain_sel <= 1'b0;
        next_node <= base_node_i; base_q <= base_node_i;
        issued <= '0; returned <= '0; delivered <= '0;
        target <= total_recs_i; pending <= '0;
        in_flight <= '0; running <= 1'b1;
        cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
        empty_st <= '0; full_st <= '0; cr_cyc <= '0;
        aos_beats <= '0; acc_txns_q <= '0; ret_beats_q <= '0;
        drop_q <= '0; dup_q <= '0; overwrite_q <= '0; ooo_q <= '0;
        ar_overlap_n <= '0; out_hw <= '0;
        ar_valid_q <= 1'b0; ar_addr_q <= '0; ar_len_q <= '0; this_burst_q <= '0;
      end else if (running) begin
        automatic logic [CNT_W-1:0] c0, c1, pre;
        automatic logic             f_sel, d_sel;
        automatic logic [31:0]      iss, ret, del, pb, mmadd;
        automatic logic [3:0]       nf;
        automatic int unsigned      k0;
        automatic logic [31:0]      nid_w;
        automatic logic [IDX_W-1:0] idx;

        c0 = cnt0; c1 = cnt1;
        f_sel = fill_sel; d_sel = drain_sel;
        iss = issued; ret = returned; del = delivered; pb = pending; nf = in_flight;
        mmadd = 32'd0;

        cyc <= cyc + 32'd1;
        if (cons_ready_i)
          cr_cyc <= cr_cyc + 32'd1;

        if (issued != (delivered + 32'(cnt0) + 32'(cnt1) + pending))
          cerr <= cerr + 32'd1;

        if (do_ar) begin
          next_node <= next_node + 32'(this_burst_q);
          iss = iss + 32'(this_burst_q);
          pb  = pb + 32'(this_burst_q);
          if (nf != 4'd0)
            ar_overlap_n <= ar_overlap_n + 32'd1;
          nf  = nf + 4'd1;
          acc_txns_q <= acc_txns_q + 32'd1;
          ar_valid_q <= 1'b0;
        end else if (!ar_valid_q) begin
          ar_valid_q   <= issue_ok_c;
          ar_addr_q    <= NG_DDR_NODE_BASE + {next_node[23:0], 4'b0000};
          this_burst_q <= this_burst_c;
          ar_len_q     <= (this_burst_c == 5'd0) ? 8'd0 : 8'(this_burst_c - 5'd1);
        end

        if (do_r) begin
          pre = f_sel ? c1 : c0;
          if (pre >= CNT_W'(WAVE))
            overwrite_q <= overwrite_q + 32'd1;
          idx = pre[IDX_W-1:0];
          nid_w = r_data_i[31:0];
          if (f_sel) begin
            r1_nid[idx]   <= nid_w;
            r1_cue[idx]   <= r_data_i[95:32];
            r1_prior[idx] <= r_data_i[103:96];
            c1 = pre + 1'b1;
          end else begin
            r0_nid[idx]   <= nid_w;
            r0_cue[idx]   <= r_data_i[95:32];
            r0_prior[idx] <= r_data_i[103:96];
            c0 = pre + 1'b1;
          end
          ret = ret + 32'd1;
          pb  = pb - 32'd1;
          aos_beats   <= aos_beats + 32'd1;
          ret_beats_q <= ret_beats_q + 32'd1;
          if (r_last_i && (nf > 4'd0))
            nf = nf - 4'd1;
          if ((f_sel ? c1 : c0) == CNT_W'(WAVE)) begin
            f_sel = ~f_sel;
            swaps <= swaps + 32'd1;
          end
        end else if (r_valid_i && !r_ready_o) begin
          full_st <= full_st + 32'd1;
        end

        if (do_wave) begin
          if (!drain_full)
            dup_q <= dup_q + 32'd1;
          for (k0 = 0; k0 < int'(WAVE); k0++) begin
            if ((del + 32'(k0)) < target) begin
              if (d_sel) begin
                if (pack_desc(r1_nid[k0], r1_cue[k0], r1_prior[k0]) !=
                    golden_desc(base_q + del + 32'(k0)))
                  mmadd = mmadd + 32'd1;
              end else begin
                if (pack_desc(r0_nid[k0], r0_cue[k0], r0_prior[k0]) !=
                    golden_desc(base_q + del + 32'(k0)))
                  mmadd = mmadd + 32'd1;
              end
            end
          end
          if (d_sel) c1 = '0;
          else       c0 = '0;
          d_sel = ~d_sel;
          del   = del + 32'(WAVE);
          waves <= waves + 32'd1;
        end else if (cons_ready_i && (delivered < target)) begin
          empty_st <= empty_st + 32'd1;
        end

        if (mmadd != 32'd0)
          mm <= mm + mmadd;

        cnt0 <= c0; cnt1 <= c1;
        fill_sel <= f_sel; drain_sel <= d_sel;
        issued <= iss; returned <= ret; delivered <= del; pending <= pb; in_flight <= nf;
        if (32'(nf) > out_hw)
          out_hw <= 32'(nf);

        if ((del >= target) && (pb == 32'd0) && (nf == 4'd0) &&
            (c0 == '0) && (c1 == '0)) begin
          running <= 1'b0;
          ar_valid_q <= 1'b0;
          if (iss != del)
            drop_q <= drop_q + (iss - del);
        end
      end else begin
        ar_valid_q <= 1'b0;
      end
    end
  end
endmodule
