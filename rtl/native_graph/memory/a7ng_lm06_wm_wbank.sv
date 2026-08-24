`timescale 1ns/1ps
// LM06-WM-00 candidate: LM-06 weight staging working set as bounded tiles.
//
// Shadows the frozen flat array rtl/lm/weight_bram803k.sv by module name and port
// list. A run compiles EITHER the frozen file OR this one, never both.
//
// Tile granularity is the frozen one from docs/contracts/A7-LM-06-TILE.md: one
// 131,072-byte W region (TOK / POS-slice / L0..L3 / HEAD). tile = addr[19:17],
// loc = addr[16:0]. Pure bit slicing, no arithmetic, so law lm06-signsgd-v1 is
// untouched.
//
// This module does NOT claim the bounded-W result. A bounded single-region W
// working set with evict-and-refill already exists as frozen weight_tile803k
// (SIM_FULL=0) and its bit-exactness against the flat monolith is already
// BOARD-recorded in results/A7-LM-06/hardware_c3/ladder.json. See PREREGISTER
// amendment A1(a). What this module contributes is the same restructure on the
// flat reference path so every equivalence axis is measured on one common core.
module weight_bram803k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [19:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [19:0]        addr_b,
    output logic signed [7:0]  rdata_b
);
    localparam int NTILE = 8;
    localparam int TW    = 17;
    localparam int TSZ   = 1 << TW;

    wire [2:0]    sel_a = addr_a[19:17];
    wire [TW-1:0] loc_a = addr_a[16:0];
    wire [2:0]    sel_b = addr_b[19:17];
    wire [TW-1:0] loc_b = addr_b[16:0];

    logic signed [7:0] tile [0:NTILE-1][0:TSZ-1];

`ifdef A7NG_WM_MUTANT2
    // NEGATIVE CONTROL - deliberately wrong, never a gate candidate.
    // Drops exactly ONE weight write, at one address in one tile: the minimal
    // "lost dirty byte on eviction" defect (rival RV5). Its purpose is to
    // establish the sensitivity floor of the equivalence bench - if the bench
    // cannot see one lost byte out of 802,816 then a MATCH means little.
    localparam int MUT_TILE = 2;
    localparam int MUT_LOC  = 12345;
    always_ff @(posedge clk) begin
        rdata_a <= tile[sel_a][loc_a];
        if (we_a && !(int'(sel_a) == MUT_TILE && int'(loc_a) == MUT_LOC))
            tile[sel_a][loc_a] <= wdata_a;
    end
`else
    always_ff @(posedge clk) begin
        rdata_a <= tile[sel_a][loc_a];
        if (we_a) tile[sel_a][loc_a] <= wdata_a;
    end
`endif
    always_ff @(posedge clk) begin
        rdata_b <= tile[sel_b][loc_b];
    end

    // Observational ownership / ping-pong accounting. Declaration initialisers
    // only: these variables are driven by exactly one always_ff so the
    // instrumentation cannot become a second driver on any data path.
    logic [2:0]  pp_active = 3'd0;
    logic [2:0]  pp_shadow = 3'd0;
    logic [31:0] wm_pp_swaps = 32'd0;
    logic [31:0] wm_live_pair_events = 32'd0;
    logic [31:0] wm_max_live_per_cycle = 32'd0;
    logic [31:0] wm_evict_writebacks = 32'd0;
    logic [31:0] wm_refills = 32'd0;

    always_ff @(posedge clk) begin
        if (sel_a != sel_b) begin
            wm_live_pair_events <= wm_live_pair_events + 1;
            if (wm_max_live_per_cycle < 2) wm_max_live_per_cycle <= 2;
        end else if (wm_max_live_per_cycle < 1) begin
            wm_max_live_per_cycle <= 1;
        end
        if (sel_a != pp_active) begin
            pp_shadow   <= pp_active;
            pp_active   <= sel_a;
            wm_pp_swaps <= wm_pp_swaps + 1;
        end
    end
endmodule
