#!/usr/bin/env python3
"""F1r: SDMA_BUSY / WDMA_BUSY / WDMA_OWN_UI latched probes after TILE_REQ."""
from pathlib import Path

SOC = Path(__file__).resolve().parents[1] / "rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv"
t = SOC.read_text(encoding="utf-8")

# --- declarations ---
old = "  logic latched_tile_req; // F1q: req_s[1] while core_busy\n  logic latched_tile_dma_busy, latched_tile_dma_own; // F1q: dma gate signals"
new = """  logic latched_tile_req; // F1q: req_s[1] while core_busy
  logic latched_tile_dma_busy, latched_tile_dma_own; // F1q: dma gate signals
  logic latched_s_dma_busy, latched_wdma_owner_ui; // F1r: ui-domain dma busy/owner
  logic latched_wdma_busy_f1r; // F1r: core wdma_busy at core_busy"""
assert old in t, "decl block"
t = t.replace(old, new, 1)

old = "      latched_tile_dma_busy <= 1'b0;\n      latched_tile_dma_own <= 1'b0;"
new = """      latched_tile_dma_busy <= 1'b0;
      latched_tile_dma_own <= 1'b0;
      latched_s_dma_busy <= 1'b0;
      latched_wdma_owner_ui <= 1'b0;
      latched_wdma_busy_f1r <= 1'b0;"""
assert old in t, "reset block"
t = t.replace(old, new, 1)

old = """        latched_tile_req <= dbg_tile_req_s1;
        latched_tile_dma_busy <= wdma_busy;
        latched_tile_dma_own <= wdma_owner;"""
new = """        latched_tile_req <= dbg_tile_req_s1;
        latched_tile_dma_busy <= wdma_busy;
        latched_tile_dma_own <= wdma_owner;
        latched_wdma_busy_f1r <= wdma_busy;"""
assert old in t, "core latch block"
t = t.replace(old, new, 1)

# ui-domain latch for s_dma_busy / wdma_owner_ui
anchor = "  // D3: MIG-side RVALID sticky (ui domain)"
ui_latch = """  // F1r: latch ui-domain dma busy/owner while core_busy (ui_clk)
  logic core_busy_ui;
  sync_bits #(.WIDTH(1)) u_core_busy_ui_sync (
    .clk(ui_clk), .rst_n(ui_rst_n),
    .async_in(core_busy),
    .sync_out(core_busy_ui)
  );
  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      latched_s_dma_busy <= 1'b0;
      latched_wdma_owner_ui <= 1'b0;
    end else if (sticky_qgo_ui && core_busy_ui) begin
      latched_s_dma_busy <= s_dma_busy;
      latched_wdma_owner_ui <= wdma_owner_ui;
    end
  end

"""
assert anchor in t, "ui latch anchor"
t = t.replace(anchor, ui_latch + anchor, 1)

# 100 MHz sync for F1r probes
old = """  // F1q: TILE_REQ / TILE_DMA_BUSY / TILE_DMA_OWN → UART (after TILE_BST)
  sync_bits #(.WIDTH(1)) u_f1q_tile_req_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(tile_req_valid_100)
  );
  sync_bits #(.WIDTH(3)) u_f1q_tile_dma_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_tile_dma_own, latched_tile_dma_busy, latched_tile_req}),
    .sync_out({tile_dma_own_lat_100, tile_dma_busy_lat_100, tile_req_100})
  );"""
new = """  // F1q: TILE_REQ / TILE_DMA_BUSY / TILE_DMA_OWN → UART (after TILE_BST)
  sync_bits #(.WIDTH(1)) u_f1q_tile_req_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(tile_req_valid_100)
  );
  sync_bits #(.WIDTH(3)) u_f1q_tile_dma_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_tile_dma_own, latched_tile_dma_busy, latched_tile_req}),
    .sync_out({tile_dma_own_lat_100, tile_dma_busy_lat_100, tile_req_100})
  );
  // F1r: SDMA_BUSY / WDMA_BUSY / WDMA_OWN_UI latched → UART (after TILE_REQ)
  logic sdma_busy_lat_100, wdma_busy_lat_100, wdma_own_ui_lat_100;
  sync_bits #(.WIDTH(3)) u_f1r_dma_src_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({latched_wdma_owner_ui, latched_wdma_busy_f1r, latched_s_dma_busy}),
    .sync_out({wdma_own_ui_lat_100, wdma_busy_lat_100, sdma_busy_lat_100})
  );"""
assert old in t, "f1r sync block"
t = t.replace(old, new, 1)

# msg_sel comment + sent_mask width
t = t.replace(
    "  //          45 TILE_REQ=H … 46 TILE_DMA_BUSY=H … 47 TILE_DMA_OWN=H …\n"
    "  //          48 W_STALL … 49 PHASE=HH … 50 PRED_NZ … 51 CORE_DONE … 52 PRED\n"
    "  logic [5:0] msg_sel;\n"
    "  logic [52:0] sent_mask;",
    "  //          45 TILE_REQ=H … 46 SDMA_BUSY=H … 47 WDMA_BUSY=H … 48 WDMA_OWN_UI=H …\n"
    "  //          49 TILE_DMA_BUSY=H … 50 TILE_DMA_OWN=H …\n"
    "  //          51 W_STALL … 52 PHASE=HH … 53 PRED_NZ … 54 CORE_DONE … 55 PRED\n"
    "  logic [5:0] msg_sel;\n"
    "  logic [55:0] sent_mask;",
    1,
)

# Insert hb_char cases 46-48 and renumber 46-52 -> 49-55
old = """      6'd45: unique case (i) // TILE_REQ=H (F1q req_s[1])
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "R"; 6'd6: return "E"; 6'd7: return "Q";
        6'd8: return "=";
        6'd9: return hex_nib({3'b0, tile_req_100});
        default: return 8'h00;
      endcase
      6'd46: unique case (i) // TILE_DMA_BUSY=H (F1q)"""
new = """      6'd45: unique case (i) // TILE_REQ=H (F1q req_s[1])
        6'd0: return "T"; 6'd1: return "I"; 6'd2: return "L"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "R"; 6'd6: return "E"; 6'd7: return "Q";
        6'd8: return "=";
        6'd9: return hex_nib({3'b0, tile_req_100});
        default: return 8'h00;
      endcase
      6'd46: unique case (i) // SDMA_BUSY=H (F1r s_dma_busy ui)
        6'd0: return "S"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, sdma_busy_lat_100});
        default: return 8'h00;
      endcase
      6'd47: unique case (i) // WDMA_BUSY=H (F1r wdma_busy core latched)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "B"; 6'd6: return "U"; 6'd7: return "S";
        6'd8: return "Y"; 6'd9: return "=";
        6'd10: return hex_nib({3'b0, wdma_busy_lat_100});
        default: return 8'h00;
      endcase
      6'd48: unique case (i) // WDMA_OWN_UI=H (F1r wdma_owner_ui ui)
        6'd0: return "W"; 6'd1: return "D"; 6'd2: return "M"; 6'd3: return "A";
        6'd4: return "_"; 6'd5: return "O"; 6'd6: return "W"; 6'd7: return "N";
        6'd8: return "_"; 6'd9: return "U"; 6'd10: return "I"; 6'd11: return "=";
        6'd12: return hex_nib({3'b0, wdma_own_ui_lat_100});
        default: return 8'h00;
      endcase
      6'd49: unique case (i) // TILE_DMA_BUSY=H (F1q)"""
assert old in t, "hb_char insert"
t = t.replace(old, new, 1)

t = t.replace("6'd47: unique case (i) // TILE_DMA_OWN=H (F1q dma_owner)", "6'd50: unique case (i) // TILE_DMA_OWN=H (F1q dma_owner)", 1)
t = t.replace("6'd48: unique case (i) // W_STALL (F1n)", "6'd51: unique case (i) // W_STALL (F1n)", 1)
t = t.replace("6'd49: unique case (i) // PHASE=HH (F1n)", "6'd52: unique case (i) // PHASE=HH (F1n)", 1)
t = t.replace("6'd50: unique case (i) // PRED_NZ (F1l)", "6'd53: unique case (i) // PRED_NZ (F1l)", 1)
t = t.replace("6'd51: unique case (i) // CORE_DONE (F1l)", "6'd54: unique case (i) // CORE_DONE (F1l)", 1)
t = t.replace("6'd52: unique case (i) // NATIVE_V1_EXIST_ROW,pred=DDD  (F2 decimal)", "6'd55: unique case (i) // NATIVE_V1_EXIST_ROW,pred=DDD  (F2 decimal)", 1)

# hb_len
t = t.replace("      6'd45: return 6'd10;  // TILE_REQ=H\n      6'd46: return 6'd15;  // TILE_DMA_BUSY=H\n      6'd47: return 6'd14;  // TILE_DMA_OWN=H\n      6'd48: return 6'd7;   // W_STALL\n      6'd49: return 6'd8;   // PHASE=HH\n      6'd50: return 6'd7;   // PRED_NZ\n      6'd51: return 6'd9;   // CORE_DONE",
              "      6'd45: return 6'd10;  // TILE_REQ=H\n      6'd46: return 6'd11;  // SDMA_BUSY=H\n      6'd47: return 6'd11;  // WDMA_BUSY=H\n      6'd48: return 6'd13;  // WDMA_OWN_UI=H\n      6'd49: return 6'd15;  // TILE_DMA_BUSY=H\n      6'd50: return 6'd14;  // TILE_DMA_OWN=H\n      6'd51: return 6'd7;   // W_STALL\n      6'd52: return 6'd8;   // PHASE=HH\n      6'd53: return 6'd7;   // PRED_NZ\n      6'd54: return 6'd9;   // CORE_DONE", 1)

# hb_next signature + body
old_sig = """      input logic tile_req_ok, tile_dma_busy_ok, tile_dma_own_ok,
      input logic w_stall_ok, phase_ok,"""
new_sig = """      input logic tile_req_ok, sdma_busy_ok, wdma_busy_lat_ok, wdma_own_ui_ok,
      input logic tile_dma_busy_ok, tile_dma_own_ok,
      input logic w_stall_ok, phase_ok,"""
assert old_sig in t, "hb_next sig"
t = t.replace(old_sig, new_sig, 1)

old_body = """    if (tile_req_ok  && !mask[45]) return 6'd45;
    if (tile_dma_busy_ok && !mask[46]) return 6'd46;
    if (tile_dma_own_ok  && !mask[47]) return 6'd47;
    if (w_stall_ok && !mask[48]) return 6'd48;
    if (phase_ok   && !mask[49]) return 6'd49;
    if (pred_nz_ok && !mask[50]) return 6'd50;
    if (core_done_ok && !mask[51]) return 6'd51;
    if (pred_ok    && !mask[52]) return 6'd52;"""
new_body = """    if (tile_req_ok  && !mask[45]) return 6'd45;
    if (sdma_busy_ok && !mask[46]) return 6'd46;
    if (wdma_busy_lat_ok && !mask[47]) return 6'd47;
    if (wdma_own_ui_ok && !mask[48]) return 6'd48;
    if (tile_dma_busy_ok && !mask[49]) return 6'd49;
    if (tile_dma_own_ok  && !mask[50]) return 6'd50;
    if (w_stall_ok && !mask[51]) return 6'd51;
    if (phase_ok   && !mask[52]) return 6'd52;
    if (pred_nz_ok && !mask[53]) return 6'd53;
    if (core_done_ok && !mask[54]) return 6'd54;
    if (pred_ok    && !mask[55]) return 6'd55;"""
assert old_body in t, "hb_next body"
t = t.replace(old_body, new_body, 1)

old_fn = """      input logic [52:0] mask,"""
new_fn = """      input logic [55:0] mask,"""
assert old_fn in t, "hb_next mask width"
t = t.replace(old_fn, new_fn, 1)

old_nxt = """                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           w_stall_100, phase_valid_100,"""
new_nxt = """                           tile_req_valid_100, tile_req_valid_100, tile_req_valid_100, tile_req_valid_100,
                           tile_req_valid_100, tile_req_valid_100,
                           w_stall_100, phase_valid_100,"""
assert old_nxt in t, "nxt_sel call"
t = t.replace(old_nxt, new_nxt, 1)

old_hp = """      (tile_req_valid_100 && !sent_mask[45]) ||
      (tile_req_valid_100 && !sent_mask[46]) ||
      (tile_req_valid_100 && !sent_mask[47]) ||
      (w_stall_100   && !sent_mask[48]) ||
      (phase_valid_100 && !sent_mask[49]) ||
      (pred_nz_100   && !sent_mask[50]) ||
      (core_done_100 && !sent_mask[51]) ||
      (pred_ready    && !sent_mask[52]);"""
new_hp = """      (tile_req_valid_100 && !sent_mask[45]) ||
      (tile_req_valid_100 && !sent_mask[46]) ||
      (tile_req_valid_100 && !sent_mask[47]) ||
      (tile_req_valid_100 && !sent_mask[48]) ||
      (tile_req_valid_100 && !sent_mask[49]) ||
      (tile_req_valid_100 && !sent_mask[50]) ||
      (w_stall_100   && !sent_mask[51]) ||
      (phase_valid_100 && !sent_mask[52]) ||
      (pred_nz_100   && !sent_mask[53]) ||
      (core_done_100 && !sent_mask[54]) ||
      (pred_ready    && !sent_mask[55]);"""
assert old_hp in t, "have_pending"
t = t.replace(old_hp, new_hp, 1)

t = t.replace("sent_mask <= 53'd0;", "sent_mask <= 56'd0;", 1)
t = t.replace("&sent_mask[52:0]", "&sent_mask[55:0]", 1)

SOC.write_text(t, encoding="utf-8")
print("PATCH_OK", SOC)
