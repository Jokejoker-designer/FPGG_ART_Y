// a7ng_cue_soa_wavefront.sv — R3 AOS-STREAM-ONEOWNER-00
// One 16-byte descriptor per candidate (id + cue64 + prior + pad).
// No three-plane SOA bulk copy, no dual-bank ping-pong.
// Product reducer remains min-heap (not Serial). PROGRAM=NO.
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

  typedef enum logic [2:0] {
    ST_IDLE  = 3'd0,
    ST_ARM   = 3'd1,
    ST_FETCH = 3'd2,
    ST_HOLD  = 3'd3,
    ST_DONE  = 3'd4
  } st_t;

  st_t          st;
  logic         running;
  logic [31:0]  target, base_q, delivered;
  logic [31:0]  cyc, waves, mm, empty_st, cr_cyc;
  logic [31:0]  aos_beats, acc_txns_q, ret_beats_q;
  logic         pf_start, pf_arm, fetch_active;
  logic [27:0]  pf_base;
  logic [5:0]   pf_target;
  logic         start_d;
  wire          start_pulse = start_i & ~start_d;

  logic         pf_ar_valid, pf_ar_ready;
  logic [27:0]  pf_ar_addr;
  logic [7:0]   pf_ar_len;
  logic [3:0]   pf_ar_id;
  logic [2:0]   pf_ar_size;
  logic         pf_r_valid, pf_r_ready, pf_r_last;
  logic [127:0] pf_r_data;
  logic [127:0] pf_beats [WAVE];
  logic         pf_running, pf_done, pf_idle_pf, pf_done_pulse;
  logic [5:0]   pf_returned, pf_issued;
  logic [31:0]  pf_ar_txns;

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

  wire [31:0] remain = (delivered < target) ? (target - delivered) : 32'd0;
  wire [5:0]  wave_n = (remain == 32'd0) ? 6'd0 :
                       ((remain < 32'(WAVE)) ? 6'(remain[5:0]) : 6'(WAVE));
  wire        fetch_done = pf_done_pulse && fetch_active && !pf_running &&
                           (pf_returned == pf_target) && (pf_issued == pf_target);
  wire        do_wave = running && (st == ST_HOLD) && cons_ready_i &&
                        (pf_returned == pf_target) && (pf_target != 6'd0);

  assign running_o        = running;
  assign done_o           = !running && (delivered >= target) && (target != 32'd0);
  assign cycles_o         = cyc;
  assign waves_o          = waves;
  assign cand_accepted_o  = target;
  assign cand_delivered_o = delivered;
  assign cand_queued_o    = 32'd0;
  assign cand_inflight_o  = pf_running ? 32'(pf_target) : 32'd0;
  assign cand_pruned_o    = 32'd0;
  assign conserve_err_o   = 32'd0;
  assign data_mismatch_o  = mm;
  assign swap_count_o     = 32'd0;
  assign buffer_empty_stall_o = empty_st;
  assign buffer_full_stall_o  = 32'd0;
  assign cons_ready_cycles_o  = cr_cyc;
  assign fill_cycles_o    = 32'd0;
  assign fill_episodes_o  = waves;
  assign occ_fill_o       = 16'(pf_returned);
  assign occ_drain_o      = do_wave ? 16'(WAVE) : 16'd0;
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
  assign outstanding_txns_o     = pf_running ? 32'd1 : 32'd0;
  assign unpack_beats_o         = aos_beats;
  assign wave_valid_o           = do_wave;
  assign wave_base_id_o         = base_q + delivered;
  assign plane_fetch_idle_o     = pf_idle_pf && !fetch_active && bridge_idle_i;

  integer wi;
  always_comb begin
    for (wi = 0; wi < int'(WAVE); wi++)
      wave_rec_o[wi] = pf_beats[wi];
  end

  assign ar_valid_o  = pf_ar_valid && (st == ST_FETCH);
  assign pf_ar_ready = ar_ready_i && (st == ST_FETCH);
  assign ar_addr_o   = pf_ar_addr;
  assign ar_len_o    = pf_ar_len;
  assign ar_id_o     = pf_ar_id;
  assign ar_size_o   = pf_ar_size;
  assign pf_r_valid  = r_valid_i;
  assign pf_r_last   = r_last_i;
  assign pf_r_data   = r_data_i;
  assign r_ready_o   = pf_r_ready;

  // One outstanding wave fetch. MAX_BEATS=WAVE so plane buffer is 16×128b, not 64-cand planes.
  a7ng_soa_plane_engine #(
    .MAX_BEATS(WAVE), .MAX_OUT(1), .MAX_BURST(MAX_BURST)
  ) u_pf (
    .clk(clk), .rst_n(rst_n),
    .start_i(pf_start),
    .burst_i(burst_i), .outstanding_i(4'd1),
    .base_byte_i(pf_base), .beat_target_i(pf_target),
    .ar_valid_o(pf_ar_valid), .ar_ready_i(pf_ar_ready),
    .ar_addr_o(pf_ar_addr), .ar_len_o(pf_ar_len),
    .ar_id_o(pf_ar_id), .ar_size_o(pf_ar_size),
    .r_valid_i(pf_r_valid), .r_ready_o(pf_r_ready),
    .r_data_i(pf_r_data), .r_last_i(pf_r_last),
    .beat_data_o(pf_beats),
    .running_o(pf_running), .done_o(pf_done),
    .done_pulse_o(pf_done_pulse),
    .beats_returned_o(pf_returned),
    .beats_issued_o(pf_issued),
    .idle_o(pf_idle_pf),
    .ar_txns_o(pf_ar_txns)
  );

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
      if (ar_addr_o != aos_base) begin
        $error("first_ar_not_aos_base: got=0x%08h expect=0x%08h", ar_addr_o, aos_base);
        $fatal(1, "AOS first AR must be NODE_BASE + base*16");
      end
    end
  end
`endif

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE;
      running <= 1'b0;
      delivered <= '0; target <= '0; base_q <= '0;
      cyc <= '0; waves <= '0; mm <= '0; empty_st <= '0; cr_cyc <= '0;
      aos_beats <= '0; acc_txns_q <= '0; ret_beats_q <= '0;
      pf_start <= 1'b0; pf_arm <= 1'b0; fetch_active <= 1'b0;
      pf_base <= '0; pf_target <= '0;
      start_d <= 1'b0;
    end else begin
      start_d <= start_i;
      pf_start <= 1'b0;

      if (pf_arm && pf_idle_pf && bridge_idle_i) begin
        pf_start <= 1'b1;
        pf_arm <= 1'b0;
        fetch_active <= 1'b1;
      end

      if (start_pulse) begin
        base_q <= base_node_i;
        delivered <= '0;
        target <= total_recs_i;
        running <= 1'b1;
        cyc <= '0; waves <= '0; mm <= '0; empty_st <= '0; cr_cyc <= '0;
        aos_beats <= '0; acc_txns_q <= '0; ret_beats_q <= '0;
        pf_base <= NG_DDR_NODE_BASE + {base_node_i[23:0], 4'b0000};
        pf_target <= (total_recs_i == 32'd0) ? 6'd0 :
                     ((total_recs_i < 32'(WAVE)) ? 6'(total_recs_i[5:0]) : 6'(WAVE));
        pf_arm <= 1'b1;
        fetch_active <= 1'b0;
        st <= ST_ARM;
      end else if (running) begin
        cyc <= cyc + 32'd1;
        if (cons_ready_i)
          cr_cyc <= cr_cyc + 32'd1;

        unique case (st)
          ST_ARM: begin
            if (pf_start)
              st <= ST_FETCH;
          end
          ST_FETCH: begin
            if (fetch_done) begin
              acc_txns_q  <= acc_txns_q + pf_ar_txns;
              ret_beats_q <= ret_beats_q + 32'(pf_returned);
              aos_beats   <= aos_beats + 32'(pf_returned);
              fetch_active <= 1'b0;
              st <= ST_HOLD;
            end
          end
          ST_HOLD: begin
            if (do_wave) begin
              automatic int unsigned k0, pi;
              automatic logic [31:0] mmadd;
              mmadd = 32'd0;
              for (k0 = 0; k0 < int'(WAVE); k0++) begin
                pi = int'(delivered) + k0;
                if (pi < int'(target)) begin
                  if (pf_beats[k0] != golden_desc(base_q + 32'(pi)))
                    mmadd = mmadd + 32'd1;
                end
              end
              if (mmadd != 32'd0)
                mm <= mm + mmadd;
              delivered <= delivered + 32'(WAVE);
              waves <= waves + 32'd1;
              if ((delivered + 32'(WAVE)) < target) begin
                pf_base <= NG_DDR_NODE_BASE +
                           {(base_q[23:0] + delivered[23:0] + 24'(WAVE)), 4'b0000};
                pf_target <= 6'(WAVE);
                pf_arm <= 1'b1;
                st <= ST_ARM;
              end else begin
                running <= 1'b0;
                st <= ST_DONE;
              end
            end else if (cons_ready_i) begin
              empty_st <= empty_st + 32'd1;
            end
          end
          default: ;
        endcase
      end
    end
  end
endmodule
