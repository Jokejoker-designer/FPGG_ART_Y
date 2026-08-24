// a7ng_multi_agent_share.sv — NG-06R-WIDE + NG-06R-EPOCH
// Law: a7ng-share-v1 (HS-09) + query/path epoch DROP_STALE (HS-06/07).
// Banked queues + credit/backpressure + multi-grant + fair RR + same-cycle enq/deq.
// Compact exact allocator: ready_lane_mask→compact; nonempty_bank_mask→compact; pair k↔k.
// Stale: entry.query_epoch != active_query_epoch → DROP_STALE (dequeue, no grant, no ctx kill).
// On-chip hotset feed (no DDR). No extra PEs. No global learned wipe on epoch mismatch.
`timescale 1ns / 1ps

module a7ng_multi_agent_share #(
  parameter int unsigned N_PHYS       = 16,
  parameter int unsigned N_LOG        = 256,
  parameter int unsigned N_WAY        = 16,
  parameter int unsigned N_BANKS      = 16,
  parameter int unsigned QDEPTH       = 8,
  parameter int unsigned CREDIT_MAX   = 1,
  parameter int unsigned HOTSET_DEPTH = 256,
  parameter int unsigned EPOCH_W      = 16
) (
  input  logic                       clk,
  input  logic                       rst_n,

  // Active query epoch (host/epoch_mgr). Matched work may grant; mismatch → DROP_STALE.
  input  logic [EPOCH_W-1:0]         active_query_epoch_i,

  input  logic [N_WAY-1:0]           push_i,
  input  logic [7:0]                 log_id_i   [N_WAY],
  input  logic signed [15:0]         score_i    [N_WAY],
  input  logic [31:0]                node_id_i  [N_WAY],
  input  logic [EPOCH_W-1:0]         query_epoch_i [N_WAY],
  input  logic [EPOCH_W-1:0]         path_epoch_i  [N_WAY],
  output logic [N_WAY-1:0]           push_ready_o,

  input  logic [N_PHYS-1:0]          lane_req_i,
  input  logic [N_PHYS-1:0]          lane_done_i,
  // AUTHORITATIVE wide dispatch (util / jobs-per-cycle / lane feed)
  output logic [N_PHYS-1:0]          lane_grant_o,
  output logic [7:0]                 grant_log_o   [N_PHYS],
  output logic signed [15:0]         grant_score_o [N_PHYS],
  output logic [31:0]                grant_node_o  [N_PHYS],
  output logic [EPOCH_W-1:0]         grant_qepoch_o [N_PHYS],
  output logic [EPOCH_W-1:0]         grant_pepoch_o [N_PHYS],

  // DEBUG / COMPATIBILITY ONLY — mirrors FIRST grant of the cycle.
  output logic                       pop_valid_o,
  output logic [7:0]                 pop_log_o,
  output logic signed [15:0]         pop_score_o,
  output logic [31:0]                pop_node_o,

  input  logic                       fail_i,
  input  logic [7:0]                 fail_log_i,
  output logic [N_LOG-1:0]           ctx_alive_o,

  output logic [15:0]                q_count_o,
  output logic [7:0]                 phys_lanes_o,
  output logic [15:0]                logical_ctx_o,
  output logic [7:0]                 n_way_o,

  output logic [N_PHYS-1:0]          lane_busy_o,
  output logic [4:0]                 jobs_per_cycle_o,
  output logic                       scheduler_idle_o,
  output logic                       scheduler_conflict_o,
  output logic [15:0]                queue_occupancy_o,
  output logic                       queue_full_o,
  output logic [31:0]                starvation_count_o,
  output logic [31:0]                drop_stale_o,

  input  logic                       hot_we_i,
  input  logic [7:0]                 hot_addr_i,
  input  logic [7:0]                 hot_log_i,
  input  logic signed [15:0]         hot_score_i,
  input  logic [31:0]                hot_node_i,
  input  logic [EPOCH_W-1:0]         hot_query_epoch_i,
  input  logic [EPOCH_W-1:0]         hot_path_epoch_i,
  input  logic                       hot_feed_en_i,
  output logic [7:0]                 hot_ptr_o
);
  localparam int unsigned PTR_W   = $clog2(QDEPTH);
  localparam int unsigned BANK_W  = $clog2(N_BANKS);
  localparam int unsigned ENQ_MAX = N_WAY * 2;

  assign phys_lanes_o  = N_PHYS[7:0];
  assign logical_ctx_o = N_LOG[15:0];
  assign n_way_o       = N_WAY[7:0];

  logic [N_LOG-1:0] ctx_alive;
  assign ctx_alive_o = ctx_alive;

  // Prefer distributed for multi-port banked queues (BRAM needs single R/W)
  (* ram_style = "distributed" *) logic [7:0]              q_log    [N_BANKS][QDEPTH];
  (* ram_style = "distributed" *) logic signed [15:0]      q_score  [N_BANKS][QDEPTH];
  (* ram_style = "distributed" *) logic [31:0]             q_node   [N_BANKS][QDEPTH];
  (* ram_style = "distributed" *) logic [EPOCH_W-1:0]      q_qepoch [N_BANKS][QDEPTH];
  (* ram_style = "distributed" *) logic [EPOCH_W-1:0]      q_pepoch [N_BANKS][QDEPTH];
  logic [PTR_W:0]     wr_ptr  [N_BANKS];
  logic [PTR_W:0]     rd_ptr  [N_BANKS];
  logic [PTR_W:0]     occ     [N_BANKS];

  logic [1:0]        credit [N_PHYS];
  logic [N_PHYS-1:0] lane_busy_r;
  assign lane_busy_o = lane_busy_r;

  logic [1:0]        cred_tmp [N_PHYS];
  logic [PTR_W:0]    wr_d_tmp [N_BANKS];
  logic [PTR_W:0]    rd_d_tmp [N_BANKS];
  logic [N_PHYS-1:0] busy_tmp;

  logic [BANK_W-1:0] rr_bank;
  logic [3:0]        rr_lane;

  (* ram_style = "distributed" *) logic [7:0]         hot_log   [HOTSET_DEPTH];
  (* ram_style = "distributed" *) logic signed [15:0] hot_score [HOTSET_DEPTH];
  (* ram_style = "distributed" *) logic [31:0]        hot_node  [HOTSET_DEPTH];
  (* ram_style = "distributed" *) logic [EPOCH_W-1:0] hot_qep   [HOTSET_DEPTH];
  (* ram_style = "distributed" *) logic [EPOCH_W-1:0] hot_pep   [HOTSET_DEPTH];
  logic [7:0]         hot_ptr;
  assign hot_ptr_o = hot_ptr;

  logic [31:0] starve_cnt;
  logic [31:0] drop_stale_cnt;
  logic [15:0] starve_wait [N_PHYS];
  assign starvation_count_o = starve_cnt;
  assign drop_stale_o       = drop_stale_cnt;

  logic [15:0] occ_sum;
  logic        any_full, any_work;
  always_comb begin
    occ_sum  = 16'd0;
    any_full = 1'b0;
    any_work = 1'b0;
    for (int b = 0; b < N_BANKS; b++) begin
      occ_sum = occ_sum + {{(16-PTR_W-1){1'b0}}, occ[b]};
      if (occ[b] >= QDEPTH[PTR_W:0]) any_full = 1'b1;
      if (occ[b] != 0) any_work = 1'b1;
    end
  end
  assign q_count_o         = occ_sum;
  assign queue_occupancy_o = occ_sum;
  assign queue_full_o      = any_full;

  logic [1:0] credit_v [N_PHYS];
  always_comb begin
    for (int i = 0; i < N_PHYS; i++) begin
      credit_v[i] = credit[i];
      if (lane_done_i[i] && (credit[i] < CREDIT_MAX[1:0]))
        credit_v[i] = credit[i] + 2'd1;
    end
  end

  // Compact exact grant plan
  logic [N_PHYS-1:0]  ready_lane_mask;
  logic [N_BANKS-1:0] nonempty_bank_mask;
  logic [N_BANKS-1:0] drain_bank;
  logic [N_BANKS-1:0] stale_bank;
  logic [3:0]         lane_sel  [N_WAY];
  logic [BANK_W-1:0]  bank_sel  [N_WAY];
  logic [4:0]         n_lane_c;
  logic [4:0]         n_bank_c;
  logic [4:0]         gnt_n;
  logic [4:0]         stale_n;
  logic [N_PHYS-1:0]  gnt;
  logic [7:0]         gnt_log   [N_PHYS];
  logic signed [15:0] gnt_score [N_PHYS];
  logic [31:0]        gnt_node  [N_PHYS];
  logic [EPOCH_W-1:0] gnt_qep   [N_PHYS];
  logic [EPOCH_W-1:0] gnt_pep   [N_PHYS];
  logic [BANK_W-1:0]  gnt_bank  [N_WAY];
  logic [3:0]         gnt_lane  [N_WAY];
  logic [PTR_W:0]     occ_post_pop [N_BANKS];
  logic [4:0]         demand_n;
  logic               demand_any;

  always_comb begin
    ready_lane_mask    = '0;
    nonempty_bank_mask = '0;
    drain_bank         = '0;
    stale_bank         = '0;
    n_lane_c           = 5'd0;
    n_bank_c           = 5'd0;
    gnt_n              = 5'd0;
    stale_n            = 5'd0;
    gnt                = '0;
    demand_n           = 5'd0;
    demand_any         = 1'b0;
    for (int w = 0; w < N_WAY; w++) begin
      lane_sel[w] = '0;
      bank_sel[w] = '0;
      gnt_bank[w] = '0;
      gnt_lane[w] = '0;
    end
    for (int i = 0; i < N_PHYS; i++) begin
      gnt_log[i]   = 8'd0;
      gnt_score[i] = 16'sd0;
      gnt_node[i]  = 32'd0;
      gnt_qep[i]   = '0;
      gnt_pep[i]   = '0;
      if (lane_req_i[i] && (credit_v[i] != 2'd0)) begin
        ready_lane_mask[i] = 1'b1;
        demand_any         = 1'b1;
        demand_n           = demand_n + 5'd1;
      end
    end
    for (int b = 0; b < N_BANKS; b++) begin
      occ_post_pop[b] = occ[b];
      if (occ[b] != 0) begin
        automatic logic [7:0] hl = q_log[b][rd_ptr[b][PTR_W-1:0]];
        automatic logic [EPOCH_W-1:0] he = q_qepoch[b][rd_ptr[b][PTR_W-1:0]];
        if (!ctx_alive[hl])
          drain_bank[b] = 1'b1;
        else if (he != active_query_epoch_i)
          stale_bank[b] = 1'b1;
        else
          nonempty_bank_mask[b] = 1'b1;
      end
    end

    for (int s = 0; s < N_PHYS; s++) begin
      automatic logic [3:0] li = rr_lane + s[3:0];
      if (li >= N_PHYS[3:0]) li = li - N_PHYS[3:0];
      if (ready_lane_mask[li] && (n_lane_c < N_WAY[4:0])) begin
        lane_sel[n_lane_c] = li;
        n_lane_c           = n_lane_c + 5'd1;
      end
    end

    for (int t = 0; t < N_BANKS; t++) begin
      automatic logic [BANK_W-1:0] bi = rr_bank + t[BANK_W-1:0];
      if (bi >= N_BANKS[BANK_W-1:0]) bi = bi - N_BANKS[BANK_W-1:0];
      if (nonempty_bank_mask[bi] && (n_bank_c < N_WAY[4:0])) begin
        bank_sel[n_bank_c] = bi;
        n_bank_c           = n_bank_c + 5'd1;
      end
    end

    begin
      automatic logic [4:0] n_pair = n_lane_c;
      if (n_bank_c < n_pair) n_pair = n_bank_c;
      for (int k = 0; k < N_WAY; k++) begin
        if (k[4:0] < n_pair) begin
          automatic logic [3:0] li = lane_sel[k];
          automatic logic [BANK_W-1:0] bi = bank_sel[k];
          automatic logic [PTR_W-1:0] rp = rd_ptr[bi][PTR_W-1:0];
          gnt[li]          = 1'b1;
          gnt_lane[k]      = li;
          gnt_bank[k]      = bi;
          gnt_log[li]      = q_log[bi][rp];
          gnt_score[li]    = q_score[bi][rp];
          gnt_node[li]     = q_node[bi][rp];
          gnt_qep[li]      = q_qepoch[bi][rp];
          gnt_pep[li]      = q_pepoch[bi][rp];
          occ_post_pop[bi] = occ_post_pop[bi] - 1'b1;
          gnt_n            = gnt_n + 5'd1;
        end
      end
    end

    for (int b = 0; b < N_BANKS; b++) begin
      if (drain_bank[b] || stale_bank[b])
        occ_post_pop[b] = occ_post_pop[b] - 1'b1;
      if (stale_bank[b])
        stale_n = stale_n + 5'd1;
    end
  end

  assign jobs_per_cycle_o     = gnt_n;
  assign scheduler_conflict_o = demand_any && any_work && (demand_n > gnt_n) &&
                                (gnt_n == N_WAY[4:0]);
  assign scheduler_idle_o     = (gnt_n == 5'd0) && !(any_work && demand_any);

  logic               enq_v     [ENQ_MAX];
  logic [BANK_W-1:0]  enq_bank  [ENQ_MAX];
  logic [7:0]         enq_log   [ENQ_MAX];
  logic signed [15:0] enq_score [ENQ_MAX];
  logic [31:0]        enq_node  [ENQ_MAX];
  logic [EPOCH_W-1:0] enq_qep   [ENQ_MAX];
  logic [EPOCH_W-1:0] enq_pep   [ENQ_MAX];
  logic [4:0]         enq_n;
  logic [4:0]         hot_n;
  logic [PTR_W:0]     occ_fill [N_BANKS];

  always_comb begin
    enq_n = 5'd0;
    hot_n = 5'd0;
    for (int k = 0; k < ENQ_MAX; k++) begin
      enq_v[k]     = 1'b0;
      enq_bank[k]  = '0;
      enq_log[k]   = '0;
      enq_score[k] = '0;
      enq_node[k]  = '0;
      enq_qep[k]   = '0;
      enq_pep[k]   = '0;
    end
    for (int b = 0; b < N_BANKS; b++) occ_fill[b] = occ_post_pop[b];

    for (int w = 0; w < N_WAY; w++) begin
      automatic logic [BANK_W-1:0] pb = log_id_i[w][BANK_W-1:0];
      push_ready_o[w] = (occ_fill[pb] < QDEPTH[PTR_W:0]);
      if (push_i[w] && ctx_alive[log_id_i[w]] && (occ_fill[pb] < QDEPTH[PTR_W:0])) begin
        enq_v[enq_n]     = 1'b1;
        enq_bank[enq_n]  = pb;
        enq_log[enq_n]   = log_id_i[w];
        enq_score[enq_n] = score_i[w];
        enq_node[enq_n]  = node_id_i[w];
        enq_qep[enq_n]   = query_epoch_i[w];
        enq_pep[enq_n]   = path_epoch_i[w];
        occ_fill[pb]     = occ_fill[pb] + 1'b1;
        enq_n            = enq_n + 5'd1;
      end
    end

    if (hot_feed_en_i) begin
      automatic logic [7:0] hp = hot_ptr;
      for (int w = 0; w < N_WAY; w++) begin
        automatic logic [BANK_W-1:0] pb = rr_bank + w[BANK_W-1:0];
        if (pb >= N_BANKS[BANK_W-1:0]) pb = pb - N_BANKS[BANK_W-1:0];
        if (occ_fill[pb] < QDEPTH[PTR_W:0]) begin
          enq_v[enq_n]     = 1'b1;
          enq_bank[enq_n]  = pb;
          enq_log[enq_n]   = hot_log[hp];
          enq_score[enq_n] = hot_score[hp];
          enq_node[enq_n]  = hot_node[hp];
          enq_qep[enq_n]   = hot_qep[hp];
          enq_pep[enq_n]   = hot_pep[hp];
          occ_fill[pb]     = occ_fill[pb] + 1'b1;
          enq_n            = enq_n + 5'd1;
          hot_n            = hot_n + 5'd1;
          hp               = hp + 8'd1;
        end
      end
    end
  end

  // BRAM-friendly init (do NOT clear arrays in async reset — that blocks BRAM inference)
  // Default epoch=1 so matched-epoch wide bags (active=1) regress cleanly.
  initial begin
    for (int h = 0; h < HOTSET_DEPTH; h++) begin
      hot_log[h]   = h[7:0];
      hot_score[h] = 16'sd100 + h[7:0];
      hot_node[h]  = 32'hA000_0000 + h;
      hot_qep[h]   = 16'd1;
      hot_pep[h]   = 16'd1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ctx_alive      <= {N_LOG{1'b1}};
      rr_bank        <= '0;
      rr_lane        <= 4'd0;
      hot_ptr        <= 8'd0;
      starve_cnt     <= 32'd0;
      drop_stale_cnt <= 32'd0;
      lane_grant_o   <= '0;
      pop_valid_o    <= 1'b0;
      pop_log_o      <= '0;
      pop_score_o    <= '0;
      pop_node_o     <= '0;
      for (int i = 0; i < N_PHYS; i++) begin
        credit[i]          <= CREDIT_MAX[1:0];
        lane_busy_r[i]     <= 1'b0;
        starve_wait[i]     <= 16'd0;
        grant_log_o[i]     <= '0;
        grant_score_o[i]   <= '0;
        grant_node_o[i]    <= '0;
        grant_qepoch_o[i]  <= '0;
        grant_pepoch_o[i]  <= '0;
      end
      for (int b = 0; b < N_BANKS; b++) begin
        wr_ptr[b] <= '0;
        rd_ptr[b] <= '0;
        occ[b]    <= '0;
      end
    end else begin
      logic first_pop;
      int ei;

      for (int b = 0; b < N_BANKS; b++) begin
        wr_d_tmp[b] = '0;
        rd_d_tmp[b] = '0;
      end
      for (int i = 0; i < N_PHYS; i++) begin
        cred_tmp[i] = credit_v[i];
        busy_tmp[i] = lane_busy_r[i];
      end
      lane_grant_o <= '0;
      pop_valid_o  <= 1'b0;
      first_pop     = 1'b1;

      // Explicit fail only — epoch DROP_STALE must NOT clear ctx_alive (HS-07).
      if (fail_i) ctx_alive[fail_log_i] <= 1'b0;

      if (hot_we_i) begin
        hot_log[hot_addr_i]   <= hot_log_i;
        hot_score[hot_addr_i] <= hot_score_i;
        hot_node[hot_addr_i]  <= hot_node_i;
        hot_qep[hot_addr_i]   <= hot_query_epoch_i;
        hot_pep[hot_addr_i]   <= hot_path_epoch_i;
      end

      for (int w = 0; w < N_WAY; w++) begin
        if (w < gnt_n) begin
          logic [3:0] ln;
          logic [BANK_W-1:0] bk;
          ln = gnt_lane[w];
          bk = gnt_bank[w];
          lane_grant_o[ln]    <= 1'b1;
          grant_log_o[ln]     <= gnt_log[ln];
          grant_score_o[ln]   <= gnt_score[ln];
          grant_node_o[ln]    <= gnt_node[ln];
          grant_qepoch_o[ln]  <= gnt_qep[ln];
          grant_pepoch_o[ln]  <= gnt_pep[ln];
          busy_tmp[ln]         = 1'b1;
          starve_wait[ln]     <= 16'd0;
          if (cred_tmp[ln] != 2'd0) cred_tmp[ln] = cred_tmp[ln] - 2'd1;
          rd_d_tmp[bk] = rd_d_tmp[bk] + 1'b1;
          if (first_pop) begin
            pop_valid_o <= 1'b1;
            pop_log_o   <= gnt_log[ln];
            pop_score_o <= gnt_score[ln];
            pop_node_o  <= gnt_node[ln];
            first_pop    = 1'b0;
          end
        end
      end

      for (int b = 0; b < N_BANKS; b++)
        if (drain_bank[b] || stale_bank[b]) rd_d_tmp[b] = rd_d_tmp[b] + 1'b1;

      if (stale_n != 5'd0)
        drop_stale_cnt <= drop_stale_cnt + {{(32-5){1'b0}}, stale_n};

      for (int i = 0; i < N_PHYS; i++)
        if (lane_done_i[i] && !gnt[i]) busy_tmp[i] = 1'b0;

      for (ei = 0; ei < ENQ_MAX; ei++) begin
        if (ei < enq_n && enq_v[ei]) begin
          logic [BANK_W-1:0] pb;
          logic [PTR_W-1:0]  wp;
          pb = enq_bank[ei];
          wp = wr_ptr[pb][PTR_W-1:0] + wr_d_tmp[pb][PTR_W-1:0];
          q_log[pb][wp]    <= enq_log[ei];
          q_score[pb][wp]  <= enq_score[ei];
          q_node[pb][wp]   <= enq_node[ei];
          q_qepoch[pb][wp] <= enq_qep[ei];
          q_pepoch[pb][wp] <= enq_pep[ei];
          wr_d_tmp[pb]      = wr_d_tmp[pb] + 1'b1;
        end
      end

      for (int b = 0; b < N_BANKS; b++) begin
        wr_ptr[b] <= wr_ptr[b] + wr_d_tmp[b];
        rd_ptr[b] <= rd_ptr[b] + rd_d_tmp[b];
        begin
          int nxt;
          nxt = int'(occ[b]) - int'(rd_d_tmp[b]) + int'(wr_d_tmp[b]);
          if (nxt < 0) nxt = 0;
          if (nxt > int'(QDEPTH)) nxt = int'(QDEPTH);
          occ[b] <= nxt[PTR_W:0];
        end
      end

      for (int i = 0; i < N_PHYS; i++) begin
        credit[i]      <= cred_tmp[i];
        lane_busy_r[i] <= busy_tmp[i];
      end
      hot_ptr <= hot_ptr + {{(8-5){1'b0}}, hot_n};

      if (gnt_n != 5'd0) begin
        rr_lane <= gnt_lane[gnt_n - 1] + 4'd1;
        rr_bank <= gnt_bank[gnt_n - 1] + 1'b1;
      end else if (enq_n != 5'd0) begin
        rr_bank <= rr_bank + 1'b1;
      end

      for (int i = 0; i < N_PHYS; i++) begin
        if (lane_req_i[i] && (credit_v[i] != 2'd0) && !gnt[i] && any_work) begin
          if (starve_wait[i] >= 16'd1024) begin
            starve_cnt     <= starve_cnt + 32'd1;
            starve_wait[i] <= 16'd0;
          end else
            starve_wait[i] <= starve_wait[i] + 16'd1;
        end else
          starve_wait[i] <= 16'd0;
      end
    end
  end
endmodule
