`timescale 1ns/1ps
// LM06-WM-00 candidate: LM-06 snapshot working set as bounded tiles.
//
// Shadows the frozen flat array rtl/lm/snap_ram4k16.sv by module name and port
// list. Frozen snap map (rtl/lm/snap_ram4k16.sv header):
//   n1   0    + ly*128 + d
//   n2   512  + ly*128 + d
//   attn 1024 + ly*128 + d
//   hid  1536 + ly*256 + hh
// so tile = addr[11:10] selects the n1 / n2 / attn / hid quarter and
// loc = addr[9:0] is the offset inside it. Pure bit slicing, no arithmetic.
//
// Single always_ff and READ_FIRST ordering match the frozen array exactly: the
// read of raddr is evaluated before the write to waddr lands.
//
// A7NG_WM_ENFORCE_SNAP is the Arm B enforced bounded pair: only NLIVE of NTILE
// tiles are resident, backed by a separate store, with real dirty writeback on
// eviction and real refill on admit.
module snap_ram4k16 (
    input  logic               clk,
    input  logic               we,
    input  logic [11:0]        waddr,
    input  logic signed [15:0] wdata,
    input  logic [11:0]        raddr,
    output logic signed [15:0] rdata
);
    localparam int NTILE = 4;
    localparam int TW    = 10;
    localparam int TSZ   = 1 << TW;
    localparam int NLIVE = 2;

    wire [1:0]    sel_w = waddr[11:10];
    wire [TW-1:0] loc_w = waddr[9:0];
    wire [1:0]    sel_r = raddr[11:10];
    wire [TW-1:0] loc_r = raddr[9:0];

`ifdef A7NG_WM_ENFORCE_SNAP
    logic signed [15:0] slot   [0:NLIVE-1][0:TSZ-1];
    logic signed [15:0] bstore [0:NTILE-1][0:TSZ-1];
    logic [1:0]  slot_tag   [0:NLIVE-1];
    logic        slot_val   [0:NLIVE-1];
    logic        slot_dirty [0:NLIVE-1];
    logic [31:0] slot_age   [0:NLIVE-1];
    logic [31:0] wm_clk_tick = 32'd0;
    logic [31:0] wm_evict_writebacks = 32'd0;
    logic [31:0] wm_refills = 32'd0;
    logic [31:0] wm_pp_swaps = 32'd0;
    logic        wm_inited = 1'b0;

    function automatic int find_slot(input logic [1:0] t);
        for (int s = 0; s < NLIVE; s++)
            if (slot_val[s] && slot_tag[s] == t) return s;
        return -1;
    endfunction

    // Zero-latency admit: FUNCTIONAL MODEL of a bounded working set, not
    // synthesizable timed RTL. Declared as such in PREREGISTER amendment A1.
    task automatic admit(input logic [1:0] t);
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

    int sr, sw;
    // Blocking assignment throughout so the admit task and the access share one
    // consistent view of the resident set. READ_FIRST is preserved because the
    // nonblocking read of rdata is scheduled before the blocking write lands.
    always_ff @(posedge clk) begin
        if (!wm_inited) begin
            for (int s = 0; s < NLIVE; s++) begin
                slot_val[s]   = 1'b0;
                slot_dirty[s] = 1'b0;
                slot_tag[s]   = 2'd0;
                slot_age[s]   = 32'd0;
            end
            wm_inited = 1'b1;
        end
        wm_clk_tick = wm_clk_tick + 1;
        admit(sel_r);
        if (we) admit(sel_w);
        sr = find_slot(sel_r);
        rdata <= slot[sr][loc_r];
        if (we) begin
            sw = find_slot(sel_w);
            slot[sw][loc_w] = wdata;
            slot_dirty[sw]  = 1'b1;
        end
    end
`else
    logic signed [15:0] tile [0:NTILE-1][0:TSZ-1];

    always_ff @(posedge clk) begin
        rdata <= tile[sel_r][loc_r];
        if (we) tile[sel_w][loc_w] <= wdata;
    end

    // Observational ownership / ping-pong accounting. Declaration initialisers
    // only: these variables are driven by exactly one always_ff so the
    // instrumentation cannot become a second driver on any data path.
    logic [1:0]  pp_active = 2'd0;
    logic [1:0]  pp_shadow = 2'd0;
    logic [31:0] wm_pp_swaps = 32'd0;
    logic [31:0] wm_live_pair_events = 32'd0;
    logic [31:0] wm_max_live_per_cycle = 32'd0;
    logic [31:0] wm_evict_writebacks = 32'd0;
    logic [31:0] wm_refills = 32'd0;

    always_ff @(posedge clk) begin
        if (we) begin
            if (sel_w != sel_r) begin
                wm_live_pair_events <= wm_live_pair_events + 1;
                if (wm_max_live_per_cycle < 2) wm_max_live_per_cycle <= 2;
            end else if (wm_max_live_per_cycle < 1) begin
                wm_max_live_per_cycle <= 1;
            end
        end else if (wm_max_live_per_cycle < 1) begin
            wm_max_live_per_cycle <= 1;
        end
        if (sel_r != pp_active) begin
            pp_shadow   <= pp_active;
            pp_active   <= sel_r;
            wm_pp_swaps <= wm_pp_swaps + 1;
        end
    end
`endif
endmodule
