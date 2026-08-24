`timescale 1ns / 1ps
// a7ng_bram_consol.sv — ONE consolidation: WM phase-share of wt+act banks
// into a single TinyGPT-sized shared BRAM pool (default 132 tiles).
//
// Observation: additive TinyGPT(132)+UA_wt_ua(128)=260 > 135 (HS-11 LIMIT).
// Unknown: does one WM share collapse that to max(132,128)=132 ≤ 135 Prefer WNS≥0?
// H_candidate: shared pool post-route ≤135 / Prefer WNS≥0 ⇒ co-fit PASS_NARROW.
// H_rival: paper headroom; invent pe_alive; hand-edit mig.prj.
// Not BOARD_PASS. Not HS-22 closed (TinyGPT answer-path not in this proxy).
// Digilent AXI MIG: not required for WM-share lever (mig.prj untouched).
module a7ng_bram_consol #(
  parameter int unsigned SHARED_TILES = 132  // TinyGPT LM-06 BRAM footprint
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [3:0]  sw,
  input  logic [3:0]  btn,
  output logic [3:0]  led,
  output logic [1:0]  owner_o,
  output logic        dual_owner_err_o
);
  // Owner FSM: GRAPH | HOLD | LM — exactly one WE authority on shared pool
  typedef enum logic [1:0] {
    OWN_GRAPH = 2'd0,
    OWN_LM    = 2'd1,
    OWN_HOLD  = 2'd2
  } owner_e;

  owner_e owner;
  owner_e owner_next_after_hold;
  logic [7:0] tick;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick <= 8'd0;
      owner <= OWN_GRAPH;
      owner_next_after_hold <= OWN_LM;
    end else begin
      tick <= tick + 8'd1;
      if (tick == 8'hFF) begin
        unique case (owner)
          OWN_GRAPH: begin
            owner <= OWN_HOLD;
            owner_next_after_hold <= OWN_LM;
          end
          OWN_LM: begin
            owner <= OWN_HOLD;
            owner_next_after_hold <= OWN_GRAPH;
          end
          OWN_HOLD: owner <= owner_next_after_hold;
          default: owner <= OWN_GRAPH;
        endcase
      end
    end
  end

  assign owner_o = owner;

  logic owner_is_lm;
  logic owner_is_graph;
  assign owner_is_lm    = (owner == OWN_LM);
  assign owner_is_graph = (owner == OWN_GRAPH);

  // HOLD ⇒ we=0; GRAPH/LM exclusive — models phase share of wt+act (not additive)
  logic sh_we;
  assign sh_we = owner_is_lm ? sw[2] : (owner_is_graph ? sw[1] : 1'b0);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) dual_owner_err_o <= 1'b0;
    else if (owner_is_lm && owner_is_graph) dual_owner_err_o <= 1'b1;
  end

  logic [9:0]  addr;
  logic [35:0] din;
  assign addr = {tick[1:0], tick, sw[0]};
  assign din  = {4'b0, tick, tick, tick, sw, btn};

  logic [35:0] sh_dout [0:SHARED_TILES-1];
  logic [35:0] sh_xor;

  genvar si;
  generate
    for (si = 0; si < SHARED_TILES; si++) begin : g_shared
      a7ng_bram_consol_tile u_tile (
        .clk (clk),
        .en  (1'b1),
        .we  (sh_we),
        .addr(addr ^ {1'b0, owner_is_lm, si[7:0]}),
        .din (din ^ {owner_is_lm, si[6:0], tick, 4'hC}),
        .dout(sh_dout[si])
      );
    end
  endgenerate

  always_comb begin
    sh_xor = '0;
    for (int i = 0; i < SHARED_TILES; i++) sh_xor ^= sh_dout[i];
  end

  assign led = sh_xor[3:0] ^ {2'b0, dual_owner_err_o, owner_is_lm};
endmodule
