`timescale 1ns/1ps
// LM06-WM-00 candidate: LM-06 activation working set as bounded tiles.
//
// Shadows the frozen flat array rtl/lm/act_ram128k16.sv by module name and port
// list. A run compiles EITHER the frozen file OR this one, never both, so no
// frozen LM-06 source is edited and the arithmetic core is literally the same file.
//
// Restructure only. The address map is the frozen one:
//   aa(t,tk,d) = t*ACT_STRIDE + tk*D + d      ACT_STRIDE = 16384, D = 128
// so tile = addr[16:14] is exactly the t-slot and loc = addr[13:0] is the offset
// inside it. Region decode is pure bit slicing: it carries no arithmetic and
// cannot perturb law lm06-signsgd-v1.
//
// Read latency stays one registered cycle and read-during-write stays READ_FIRST
// on both ports, matching the frozen array.
//
// A7NG_WM_ENFORCE_ACT bounds the resident set to NLIVE tiles backed by a separate
// store, with real dirty writeback and real refill. Without the macro every tile
// is resident and the ownership state is instrumentation only.
module act_ram128k16 (
    input  logic               clk,
    input  logic               we_a,
    input  logic [16:0]        addr_a,
    input  logic signed [15:0] wdata_a,
    output logic signed [15:0] rdata_a,
    input  logic [16:0]        addr_b,
    output logic signed [15:0] rdata_b
);
    localparam int NTILE = 8;
    localparam int TW    = 14;
    localparam int TSZ   = 1 << TW;
    localparam int NLIVE = 4;

    wire [2:0]  sel_a = addr_a[16:14];
    wire [TW-1:0] loc_a = addr_a[13:0];
    wire [2:0]  sel_b = addr_b[16:14];
    wire [TW-1:0] loc_b = addr_b[13:0];

`ifdef A7NG_WM_ENFORCE_ACT
    // Bounded resident set. slot_tag[s] is the tile currently occupying slot s.
    logic signed [15:0] slot [0:NLIVE-1][0:TSZ-1];
    logic signed [15:0] bstore [0:NTILE-1][0:TSZ-1];
    logic [2:0] slot_tag [0:NLIVE-1];
    logic       slot_val [0:NLIVE-1];
    logic       slot_dirty [0:NLIVE-1];
    logic [31:0] slot_age [0:NLIVE-1];
    logic [31:0] wm_clk_tick = 32'd0;
    logic [31:0] wm_evict_writebacks = 32'd0;
    logic [31:0] wm_refills = 32'd0;
    logic [31:0] wm_pp_swaps = 32'd0;
    logic        wm_inited = 1'b0;

    function automatic int find_slot(input logic [2:0] t);
        for (int s = 0; s < NLIVE; s++)
            if (slot_val[s] && slot_tag[s] == t) return s;
        return -1;
    endfunction

    // Zero-latency admit: the resident set is repaired before the access is
    // serviced in the same cycle. This is a FUNCTIONAL MODEL of a bounded
    // working set, not synthesizable timed RTL - see the closeout LIMIT.
    task automatic admit(input logic [2:0] t);
        int s, victim;
        s = find_slot(t);
        if (s >= 0) begin
            slot_age[s] = wm_clk_tick;
            return;
        end
        victim = 0;
        for (int k = 0; k < NLIVE; k++) begin
            if (!slot_val[k]) begin
                victim = k;
                break;
            end
            if (slot_age[k] < slot_age[victim]) victim = k;
        end
        if (slot_val[victim] && slot_dirty[victim]) begin
            for (int i = 0; i < TSZ; i++) bstore[slot_tag[victim]][i] = slot[victim][i];
            wm_evict_writebacks = wm_evict_writebacks + 1;
        end
        for (int i = 0; i < TSZ; i++) slot[victim][i] = bstore[t][i];
        slot_tag[victim]   = t;
        slot_val[victim]   = 1'b1;
        slot_dirty[victim] = 1'b0;
        slot_age[victim]   = wm_clk_tick;
        wm_refills  = wm_refills + 1;
        wm_pp_swaps = wm_pp_swaps + 1;
    endtask

    int sa, sb;
    // Blocking assignment throughout so the admit task and the access share one
    // consistent view of the resident set. Both nonblocking reads are scheduled
    // before the blocking write lands, preserving READ_FIRST on both ports.
    always_ff @(posedge clk) begin
        if (!wm_inited) begin
            for (int s = 0; s < NLIVE; s++) begin
                slot_val[s]   = 1'b0;
                slot_dirty[s] = 1'b0;
                slot_tag[s]   = 3'd0;
                slot_age[s]   = 32'd0;
            end
            wm_inited = 1'b1;
        end
        wm_clk_tick = wm_clk_tick + 1;
        admit(sel_a);
        admit(sel_b);
        sa = find_slot(sel_a);
        sb = find_slot(sel_b);
        rdata_a <= slot[sa][loc_a];
        rdata_b <= slot[sb][loc_b];
        if (we_a) begin
            slot[sa][loc_a] = wdata_a;
            slot_dirty[sa]  = 1'b1;
        end
    end
`else
    // Bounded-tile structure, every tile resident. Ownership state and counters
    // are observational: they do not gate data, so they cannot change a result.
    logic signed [15:0] tile [0:NTILE-1][0:TSZ-1];

`ifdef A7NG_WM_MUTANT
    // NEGATIVE CONTROL - deliberately wrong, never a gate candidate.
    // Flips port A read-during-write from READ_FIRST to WRITE_FIRST, which is
    // exactly rival RV1: a plausible slip when a flat array is split into tiles.
    // Its only purpose is to show the equivalence bench can detect a
    // perturbation, so that "all axes MATCH" is not a vacuous result.
    always_ff @(posedge clk) begin
        if (we_a) begin
            tile[sel_a][loc_a] <= wdata_a;
            rdata_a <= wdata_a;
        end else begin
            rdata_a <= tile[sel_a][loc_a];
        end
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

    // Explicit ownership / ping-pong accounting.
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
        // Distinct tiles addressed in this one cycle: the per-cycle residency
        // requirement. This is a MEASUREMENT, never a target.
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
`endif
endmodule
