// a7ng_cue_soa_wavefront.sv — SOA stage-1: 3 column planes + post-fetch 104b pack
// Gate: ddr_cue_soa_00r_axi_liveness attempt 7. Direct cue_wavefront-class plane_engine.
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

  localparam int unsigned IDX_W  = $clog2(WAVE);
  localparam int unsigned CNT_W  = $clog2(WAVE + 1);
  localparam int unsigned MAX_ID_BEATS    = (MAX_CANDS + 3) / 4;
  localparam int unsigned MAX_CUE_BEATS   = (MAX_CANDS + 1) / 2;
  localparam int unsigned MAX_PRIOR_BEATS = (MAX_CANDS + 15) / 16;
  localparam int unsigned BEAT_BYTES      = 16;

  typedef enum logic [2:0] {
    SOA_IDLE,
    SOA_FETCH_ID,
    SOA_FETCH_CUE,
    SOA_FETCH_PRIOR,
    SOA_DRAIN,
    SOA_DONE
  } soa_phase_e;

  (* ram_style = "distributed" *) logic [127:0] id_beats_mem   [MAX_ID_BEATS];
  (* ram_style = "distributed" *) logic [127:0] cue_beats_mem  [MAX_CUE_BEATS];
  (* ram_style = "distributed" *) logic [127:0] prior_beats_mem[MAX_PRIOR_BEATS];

  (* ram_style = "distributed" *) logic [127:0] rec0 [WAVE];
  (* ram_style = "distributed" *) logic [127:0] rec1 [WAVE];

  logic [CNT_W-1:0] cnt0, cnt1;
  logic             fill_sel, drain_sel;
  logic [31:0]      target, base_q, delivered;
  logic             running;
  logic [31:0]      cyc, waves, mm, cerr, swaps, empty_st, full_st, cr_cyc, fill_acc, fill_eps;
  logic [31:0]      id_bcnt, cue_bcnt, prior_bcnt;
  soa_phase_e       phase;
  logic             need_pack;
  logic             pf_start;
  logic             pf_arm;
  logic [27:0]      pf_base;
  logic [5:0]       pf_target;
  logic [31:0]      acc_txns_q, acc_credit_q, ret_beats_q, ret_txns_q, out_txns_q, unpack_q;
  logic [31:0]      pf_ar_txns;
  logic             start_d;
  wire              start_pulse = start_i & ~start_d;

  logic         pf_ar_valid, pf_ar_ready;
  logic [27:0]  pf_ar_addr;
  logic [7:0]   pf_ar_len;
  logic [3:0]   pf_ar_id;
  logic [2:0]   pf_ar_size;
  logic         pf_r_valid, pf_r_ready, pf_r_last;
  logic [127:0] pf_r_data;
  logic [127:0] pf_beats [MAX_CUE_BEATS];
  logic         pf_running, pf_done, pf_idle_pf;
  logic         pf_done_pulse;
  logic [5:0]   pf_returned;
  logic [5:0]   pf_issued;
  logic         plane_active;

  wire [5:0] id_beats_exp    = 6'((target + 32'd3) >> 2);
  wire [5:0] cue_beats_exp   = 6'((target + 32'd1) >> 1);
  wire [5:0] prior_beats_exp = 6'((target + 32'd15) >> 4);

  wire pf_idle = pf_idle_pf && !plane_active && bridge_idle_i;
  wire r_fire  = pf_r_valid && pf_r_ready;

  wire ar_plane_ok =
      (phase == SOA_FETCH_ID) ||
      ((phase == SOA_FETCH_CUE) && (id_bcnt == 32'(id_beats_exp))) ||
      ((phase == SOA_FETCH_PRIOR) &&
       (id_bcnt == 32'(id_beats_exp)) &&
       (cue_bcnt == 32'(cue_beats_exp)));

  assign pf_ar_ready = ar_ready_i;
  assign ar_valid_o  = pf_ar_valid && ar_plane_ok;
  assign ar_addr_o   = pf_ar_addr;
  assign ar_len_o    = pf_ar_len;
  assign ar_id_o     = pf_ar_id;
  assign ar_size_o   = pf_ar_size;
  assign pf_r_valid  = r_valid_i;
  assign pf_r_last   = r_last_i;
  assign pf_r_data   = r_data_i;
  assign r_ready_o   = pf_r_ready;
  assign plane_fetch_idle_o = pf_idle;

  wire bank_full0 = (cnt0 == CNT_W'(WAVE));
  wire bank_full1 = (cnt1 == CNT_W'(WAVE));
  wire drain_full = drain_sel ? bank_full1 : bank_full0;

  assign running_o        = running;
  assign done_o           = !running && (delivered >= target) && (target != 32'd0);
  assign cycles_o         = cyc;
  assign waves_o          = waves;
  assign cand_accepted_o  = target;
  assign cand_delivered_o = delivered;
  assign cand_queued_o    = 32'(cnt0) + 32'(cnt1);
  assign cand_inflight_o  = 32'd0;
  assign cand_pruned_o    = 32'd0;
  assign conserve_err_o   = cerr;
  assign data_mismatch_o  = mm;
  assign swap_count_o     = swaps;
  assign buffer_empty_stall_o = empty_st;
  assign buffer_full_stall_o  = full_st;
  assign cons_ready_cycles_o  = cr_cyc;
  assign fill_cycles_o    = fill_acc;
  assign fill_episodes_o  = fill_eps;
  assign occ_fill_o       = fill_sel ? 16'(cnt1) : 16'(cnt0);
  assign occ_drain_o      = drain_sel ? 16'(cnt1) : 16'(cnt0);
  assign soa_id_beats_o   = id_bcnt;
  assign soa_cue_beats_o  = cue_bcnt;
  assign soa_prior_beats_o = prior_bcnt;
  assign bytes_id_o       = id_bcnt * 32'(BEAT_BYTES);
  assign bytes_cue_o      = cue_bcnt * 32'(BEAT_BYTES);
  assign bytes_prior_o    = prior_bcnt * 32'(BEAT_BYTES);
  assign bytes_total_o    = bytes_id_o + bytes_cue_o + bytes_prior_o;
  assign accepted_txns_o         = acc_txns_q;
  assign accepted_beat_credit_o  = acc_credit_q;
  assign returned_beats_o          = ret_beats_q;
  assign returned_transactions_o   = ret_txns_q;
  assign outstanding_txns_o        = out_txns_q;
  assign unpack_beats_o            = unpack_q;

  logic [127:0] wave_rec_c [WAVE];
  always_comb begin
    for (int k = 0; k < int'(WAVE); k++) begin
      wave_rec_c[k] = drain_sel ? rec1[k] : rec0[k];
      wave_rec_o[k] = drain_sel ? rec1[k] : rec0[k];
    end
  end
  assign wave_base_id_o = base_q + delivered;

  wire do_wave = running && phase == SOA_DRAIN && drain_full && cons_ready_i;
  assign wave_valid_o = do_wave;

  a7ng_soa_plane_engine #(
    .MAX_BEATS(MAX_CUE_BEATS), .MAX_OUT(MAX_OUT), .MAX_BURST(MAX_BURST)
  ) u_pf (
    .clk(clk), .rst_n(rst_n),
    .start_i(pf_start),
    .burst_i(burst_i), .outstanding_i(outstanding_i),
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

  function automatic logic [63:0] golden_cue64(input logic [31:0] nid);
    logic [31:0] c32;
    c32 = 32'hDDFE_0000 + nid;
    return {c32, ~c32};
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
    return pack_desc(nid, golden_cue64(nid), 8'h01);
  endfunction

  function automatic logic [31:0] id_at(input int unsigned pi);
    int unsigned bi, slot;
    bi   = pi / 4;
    slot = pi % 4;
    return id_beats_mem[bi][slot*32 +: 32];
  endfunction

  function automatic logic [63:0] cue_at(input int unsigned pi);
    int unsigned bi, slot;
    bi   = pi / 2;
    slot = pi % 2;
    return cue_beats_mem[bi][slot*64 +: 64];
  endfunction

  function automatic logic [7:0] prior_at(input int unsigned pi);
    int unsigned bi, slot;
    bi   = pi / 16;
    slot = pi % 16;
    return prior_beats_mem[bi][slot*8 +: 8];
  endfunction

  wire prior_ar_illegal = pf_ar_valid && ar_ready_i &&
                          (phase != SOA_FETCH_PRIOR) &&
                          (pf_ar_addr >= NG_DDR_PRIOR_BASE) &&
                          (pf_ar_addr < (NG_DDR_PRIOR_BASE + 28'h0100_0000));

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (rst_n && prior_ar_illegal)
      $error("illegal_prior_skip: PRIOR AR before ID/CUE beats id=%0d cue=%0d phase=%0d",
             id_bcnt, cue_bcnt, phase);
  end
`endif

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt0 <= '0; cnt1 <= '0;
      fill_sel <= 1'b0; drain_sel <= 1'b0;
      delivered <= '0; target <= '0; base_q <= '0;
      running <= 1'b0;
      cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
      empty_st <= '0; full_st <= '0; cr_cyc <= '0; fill_acc <= '0; fill_eps <= '0;
      id_bcnt <= '0; cue_bcnt <= '0; prior_bcnt <= '0;
      phase <= SOA_IDLE;
      need_pack <= 1'b0;
      pf_start <= 1'b0;
      pf_arm <= 1'b0;
      plane_active <= 1'b0;
      pf_base <= '0;
      pf_target <= '0;
      acc_txns_q <= '0; acc_credit_q <= '0; ret_beats_q <= '0;
      ret_txns_q <= '0; out_txns_q <= '0; unpack_q <= '0;
    end else begin
      automatic logic [CNT_W-1:0] c0, c1;
      automatic logic             f_sel, d_sel;
      automatic logic [31:0]      del, mmadd;
      automatic int unsigned      k0, pi;
      automatic soa_phase_e       nphase;
      automatic logic [5:0]       bi;
      automatic logic             plane_done;

      start_d <= start_i;
      pf_start <= 1'b0;
      if (pf_arm && pf_idle) begin
        pf_start <= 1'b1;
        pf_arm   <= 1'b0;
        plane_active <= 1'b1;
      end

      c0 = cnt0; c1 = cnt1;
      f_sel = fill_sel; d_sel = drain_sel;
      del = delivered;
      mmadd = 32'd0;
      nphase = phase;

      if (start_pulse) begin
        cnt0 <= '0; cnt1 <= '0;
        fill_sel <= 1'b0; drain_sel <= 1'b0;
        base_q <= base_node_i;
        delivered <= '0;
        target <= total_recs_i;
        running <= 1'b1;
        cyc <= '0; waves <= '0; mm <= '0; cerr <= '0; swaps <= '0;
        empty_st <= '0; full_st <= '0; cr_cyc <= '0; fill_acc <= '0; fill_eps <= '0;
        id_bcnt <= '0; cue_bcnt <= '0; prior_bcnt <= '0;
        phase <= SOA_FETCH_ID;
        need_pack <= 1'b0;
        pf_base <= NG_DDR_NODE_BASE + (base_node_i << 2);
        pf_target <= 6'((total_recs_i + 32'd3) >> 2);
        pf_arm <= 1'b1;
        plane_active <= 1'b0;
        acc_txns_q <= '0; acc_credit_q <= '0; ret_beats_q <= '0;
        ret_txns_q <= '0; out_txns_q <= '0; unpack_q <= '0;
      end else if (running) begin
        cyc <= cyc + 32'd1;
        if (cons_ready_i)
          cr_cyc <= cr_cyc + 32'd1;

        if (phase == SOA_DRAIN &&
            (delivered + 32'(cnt0) + 32'(cnt1) != target))
          cerr <= cerr + 32'd1;

        plane_done = pf_done_pulse && plane_active && !pf_running;

        if (plane_done) begin
          acc_txns_q   <= acc_txns_q + pf_ar_txns;
          acc_credit_q <= acc_credit_q + 32'(pf_issued);
          ret_beats_q  <= ret_beats_q + 32'(pf_returned);
          ret_txns_q   <= ret_txns_q + pf_ar_txns;
          unpack_q     <= unpack_q + 32'(pf_returned);
          plane_active <= 1'b0;

          unique case (phase)
            SOA_FETCH_ID: begin
              if ((pf_returned == id_beats_exp) && (pf_issued == id_beats_exp)) begin
                for (bi = 0; bi < MAX_ID_BEATS; bi++)
                  id_beats_mem[bi] <= pf_beats[bi];
                id_bcnt <= 32'(pf_returned);
                nphase = SOA_FETCH_CUE;
                pf_base <= NG_DDR_CUE64_BASE + (base_q << 3);
                pf_target <= cue_beats_exp;
                pf_arm <= 1'b1;
              end
            end
            SOA_FETCH_CUE: begin
              if ((pf_returned == cue_beats_exp) && (pf_issued == cue_beats_exp) &&
                  (id_bcnt == 32'(id_beats_exp))) begin
                for (bi = 0; bi < MAX_CUE_BEATS; bi++)
                  cue_beats_mem[bi] <= pf_beats[bi];
                cue_bcnt <= 32'(pf_returned);
                nphase = SOA_FETCH_PRIOR;
                pf_base <= NG_DDR_PRIOR_BASE + base_q[27:0];
                pf_target <= prior_beats_exp;
                pf_arm <= 1'b1;
              end
            end
            SOA_FETCH_PRIOR: begin
              if ((pf_returned == prior_beats_exp) && (pf_issued == prior_beats_exp) &&
                  (id_bcnt == 32'(id_beats_exp)) &&
                  (cue_bcnt == 32'(cue_beats_exp))) begin
                for (bi = 0; bi < MAX_PRIOR_BEATS; bi++)
                  prior_beats_mem[bi] <= pf_beats[bi];
                prior_bcnt <= 32'(pf_returned);
                nphase = SOA_DRAIN;
                need_pack <= 1'b1;
              end
            end
            default: ;
          endcase
        end

        out_txns_q <= pf_running ? 32'd1 : 32'd0;

        if (phase == SOA_DRAIN && need_pack && del < target) begin
          for (k0 = 0; k0 < int'(WAVE); k0++) begin
            pi = int'(del) + k0;
            if (pi < int'(target)) begin
              if (f_sel)
                rec1[k0] <= pack_desc(id_at(pi), cue_at(pi), prior_at(pi));
              else
                rec0[k0] <= pack_desc(id_at(pi), cue_at(pi), prior_at(pi));
            end
          end
          if (f_sel) c1 = CNT_W'(WAVE);
          else       c0 = CNT_W'(WAVE);
          fill_acc <= fill_acc + 32'd1;
          fill_eps <= fill_eps + 32'd1;
          f_sel = ~f_sel;
          swaps <= swaps + 32'd1;
          need_pack <= 1'b0;
        end

        if (do_wave) begin
          for (k0 = 0; k0 < int'(WAVE); k0++) begin
            pi = int'(del) + k0;
            if (pi < int'(target)) begin
              if (wave_rec_c[k0] != golden_desc(base_q + 32'(pi)))
                mmadd = mmadd + 32'd1;
            end
          end
          if (d_sel) c1 = '0;
          else       c0 = '0;
          d_sel = ~d_sel;
          del   = del + 32'(WAVE);
          waves <= waves + 32'd1;
          if (del + 32'(WAVE) < target)
            need_pack <= 1'b1;
        end else if (phase == SOA_DRAIN && cons_ready_i && (del < target) && !drain_full) begin
          empty_st <= empty_st + 32'd1;
        end

        if (mmadd != 32'd0)
          mm <= mm + mmadd;

        cnt0 <= c0; cnt1 <= c1;
        fill_sel <= f_sel; drain_sel <= d_sel;
        delivered <= del;
        phase <= nphase;

        if (phase == SOA_DRAIN && del >= target && c0 == '0 && c1 == '0 && !need_pack) begin
          running <= 1'b0;
          phase <= SOA_DONE;
        end
      end
    end
  end
endmodule
