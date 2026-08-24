// a7ng_wide_alloc_ooc.sv — OOC timing vehicle for NG-06R-WIDE compact allocator
// N_WAY=16 @ 100 MHz. Exact pair-k semantics; 2-stage pipeline for 100 MHz closure.
// Stage0: compact ready lanes + nonempty banks (RR). Stage1: pair k↔k → grant.
// Functional share depth/hotset evidence remains XSim of a7ng_multi_agent_share.
`timescale 1ns / 1ps

module a7ng_wide_alloc_ooc #(
  parameter int unsigned N_PHYS  = 16,
  parameter int unsigned N_WAY   = 16,
  parameter int unsigned N_BANKS = 16
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic [N_PHYS-1:0]          lane_req_i,
  input  logic [N_PHYS-1:0]          lane_done_i,
  input  logic [N_BANKS-1:0]         bank_occ_i,
  input  logic [N_PHYS-1:0]          credit_ok_i,
  output logic [N_PHYS-1:0]          lane_grant_o,
  output logic [4:0]                 jobs_per_cycle_o,
  output logic [3:0]                 gnt_lane_o [N_WAY],
  output logic [3:0]                 gnt_bank_o [N_WAY]
);
  localparam int unsigned BANK_W = $clog2(N_BANKS);

  logic [3:0]        rr_lane;
  logic [BANK_W-1:0] rr_bank;

  // ---- Stage 0 comb: compact ----
  logic [3:0]        s0_lane_sel [N_WAY];
  logic [BANK_W-1:0] s0_bank_sel [N_WAY];
  logic [4:0]        s0_n_lane, s0_n_bank;

  always_comb begin
    s0_n_lane = 5'd0;
    s0_n_bank = 5'd0;
    for (int w = 0; w < N_WAY; w++) begin
      s0_lane_sel[w] = '0;
      s0_bank_sel[w] = '0;
    end
    for (int s = 0; s < N_PHYS; s++) begin
      automatic logic [3:0] li = rr_lane + s[3:0];
      if (li >= N_PHYS[3:0]) li = li - N_PHYS[3:0];
      if (lane_req_i[li] && credit_ok_i[li] && (s0_n_lane < N_WAY[4:0])) begin
        s0_lane_sel[s0_n_lane] = li;
        s0_n_lane              = s0_n_lane + 5'd1;
      end
    end
    for (int t = 0; t < N_BANKS; t++) begin
      automatic logic [BANK_W-1:0] bi = rr_bank + t[BANK_W-1:0];
      if (bi >= N_BANKS[BANK_W-1:0]) bi = bi - N_BANKS[BANK_W-1:0];
      if (bank_occ_i[bi] && (s0_n_bank < N_WAY[4:0])) begin
        s0_bank_sel[s0_n_bank] = bi;
        s0_n_bank              = s0_n_bank + 5'd1;
      end
    end
  end

  // ---- Stage 0 regs ----
  logic [3:0]        r0_lane_sel [N_WAY];
  logic [BANK_W-1:0] r0_bank_sel [N_WAY];
  logic [4:0]        r0_n_lane, r0_n_bank;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r0_n_lane <= 5'd0;
      r0_n_bank <= 5'd0;
      for (int w = 0; w < N_WAY; w++) begin
        r0_lane_sel[w] <= '0;
        r0_bank_sel[w] <= '0;
      end
    end else begin
      r0_n_lane <= s0_n_lane;
      r0_n_bank <= s0_n_bank;
      for (int w = 0; w < N_WAY; w++) begin
        r0_lane_sel[w] <= s0_lane_sel[w];
        r0_bank_sel[w] <= s0_bank_sel[w];
      end
    end
  end

  // ---- Stage 1 comb: pair k↔k ----
  logic [N_PHYS-1:0] s1_gnt;
  logic [4:0]        s1_gnt_n;
  logic [3:0]        s1_gnt_lane [N_WAY];
  logic [BANK_W-1:0] s1_gnt_bank [N_WAY];

  always_comb begin
    s1_gnt   = '0;
    s1_gnt_n = 5'd0;
    for (int w = 0; w < N_WAY; w++) begin
      s1_gnt_lane[w] = '0;
      s1_gnt_bank[w] = '0;
    end
    begin
      automatic logic [4:0] n_pair = r0_n_lane;
      if (r0_n_bank < n_pair) n_pair = r0_n_bank;
      for (int k = 0; k < N_WAY; k++) begin
        if (k[4:0] < n_pair) begin
          automatic logic [3:0] li = r0_lane_sel[k];
          automatic logic [BANK_W-1:0] bi = r0_bank_sel[k];
          s1_gnt[li]     = 1'b1;
          s1_gnt_lane[k] = li;
          s1_gnt_bank[k] = bi;
          s1_gnt_n       = s1_gnt_n + 5'd1;
        end
      end
    end
  end

  // ---- Stage 1 regs + RR update ----
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr_lane          <= 4'd0;
      rr_bank          <= '0;
      lane_grant_o     <= '0;
      jobs_per_cycle_o <= 5'd0;
      for (int w = 0; w < N_WAY; w++) begin
        gnt_lane_o[w] <= '0;
        gnt_bank_o[w] <= '0;
      end
    end else begin
      lane_grant_o     <= s1_gnt;
      jobs_per_cycle_o <= s1_gnt_n;
      for (int w = 0; w < N_WAY; w++) begin
        gnt_lane_o[w] <= s1_gnt_lane[w];
        gnt_bank_o[w] <= s1_gnt_bank[w];
      end
      if (s1_gnt_n != 5'd0) begin
        rr_lane <= s1_gnt_lane[s1_gnt_n - 1] + 4'd1;
        rr_bank <= s1_gnt_bank[s1_gnt_n - 1] + 1'b1;
      end else if (lane_done_i != '0) begin
        rr_lane <= rr_lane + 4'd1;
      end
    end
  end
endmodule

module a7ng_wide_dispatch_ooc_top (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] lane_req_i,
  input  logic [15:0] lane_done_i,
  input  logic [15:0] bank_occ_i,
  input  logic [15:0] credit_ok_i,
  output logic [15:0] lane_grant_o,
  output logic [4:0]  jobs_per_cycle_o,
  output logic [3:0]  gnt_lane0_o,
  output logic [3:0]  gnt_bank0_o
);
  logic [3:0] gnt_lane [16];
  logic [3:0] gnt_bank [16];

  (* keep_hierarchy = "yes" *)
  a7ng_wide_alloc_ooc #(.N_PHYS(16), .N_WAY(16), .N_BANKS(16)) u_alloc (
    .clk(clk), .rst_n(rst_n),
    .lane_req_i(lane_req_i), .lane_done_i(lane_done_i),
    .bank_occ_i(bank_occ_i), .credit_ok_i(credit_ok_i),
    .lane_grant_o(lane_grant_o), .jobs_per_cycle_o(jobs_per_cycle_o),
    .gnt_lane_o(gnt_lane), .gnt_bank_o(gnt_bank)
  );

  assign gnt_lane0_o = gnt_lane[0];
  assign gnt_bank0_o = gnt_bank[0];
endmodule
