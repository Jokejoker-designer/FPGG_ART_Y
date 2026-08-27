#!/usr/bin/env python3
"""F1n: wire w_stall + latched PHASE UART probes into soc_top."""
from pathlib import Path
import re
import shutil

SOC = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv")
bak = SOC.with_suffix(".sv.f1m_bak")
if not bak.exists():
    shutil.copy2(SOC, bak)

t = SOC.read_text(encoding="utf-8")
if "sticky_w_stall" in t:
    raise SystemExit("already patched")


def repl(old, new, tag):
    global t
    if old not in t:
        raise SystemExit(f"FAIL {tag}: not found\n{old[:160]!r}")
    t = t.replace(old, new, 1)
    print("OK", tag)


repl(
    "  logic sticky_wdma_busy, sticky_wdma_done, sticky_core_busy; // F1m probe",
    "  logic sticky_wdma_busy, sticky_wdma_done, sticky_core_busy; // F1m probe\n"
    "  logic w_stall; // F1n from tiny_gpt803k via ab_core\n"
    "  logic sticky_w_stall; // F1n probe\n"
    "  logic [7:0] latched_phase; // F1n: phase while core_busy",
    "decl",
)

repl(
    "      sticky_core_busy <= 1'b0;",
    "      sticky_core_busy <= 1'b0;\n"
    "      sticky_w_stall   <= 1'b0;\n"
    "      latched_phase    <= 8'd0;",
    "reset",
)

repl(
    "      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) sticky_core_busy <= 1'b1;",
    "      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) sticky_core_busy <= 1'b1;\n"
    "      // F1n: W_STALL sticky + latched phase (after Q_GO/FWD; sticky+UART only)\n"
    "      if (sticky_qgo && (sticky_fwd || start_fwd) && w_stall) sticky_w_stall <= 1'b1;\n"
    "      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) latched_phase <= phase;",
    "set",
)

repl(
    "    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred), .phase_o(phase),",
    "    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred), .phase_o(phase),\n"
    "    .w_stall_o(w_stall),",
    "port",
)

# UART domain decls — find the F1m line
m = re.search(r"  logic wdma_busy_100, wdma_done_100, core_busy_100;.*", t)
if not m:
    raise SystemExit("FAIL uart100 decl")
repl(
    m.group(0),
    m.group(0)
    + "\n  logic w_stall_100, phase_valid_100; // F1n\n"
    + "  logic [7:0] phase_100; // F1n latched phase",
    "uart_decl",
)

repl(
    """  sync_bits #(.WIDTH(3)) u_f1m_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_core_busy, sticky_wdma_done, sticky_wdma_busy}),
    .sync_out({core_busy_100, wdma_done_100, wdma_busy_100})
  );""",
    """  sync_bits #(.WIDTH(3)) u_f1m_probe_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sticky_core_busy, sticky_wdma_done, sticky_wdma_busy}),
    .sync_out({core_busy_100, wdma_done_100, wdma_busy_100})
  );
  // F1n: W_STALL sticky + latched PHASE → UART (after CORE_BUSY)
  sync_bits #(.WIDTH(1)) u_f1n_wstall_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_w_stall),
    .sync_out(w_stall_100)
  );
  sync_bits #(.WIDTH(1)) u_f1n_phase_valid_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(sticky_core_busy),
    .sync_out(phase_valid_100)
  );
  sync_bits #(.WIDTH(8)) u_f1n_phase_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in(latched_phase),
    .sync_out(phase_100)
  );""",
    "cdc",
)

# comments + mask width
repl(
    "  //          41 CORE_BUSY … 42 PRED_NZ … 43 CORE_DONE … 44 PRED",
    "  //          41 CORE_BUSY … 42 W_STALL … 43 PHASE=HH … 44 PRED_NZ … 45 CORE_DONE … 46 PRED",
    "cmt",
)
# tolerate non-ellipsis comment from dump: "41 CORE_BUSY . 42 PRED_NZ . 43 CORE_DONE . 44 PRED"
if "42 W_STALL" not in t:
    repl(
        "41 CORE_BUSY . 42 PRED_NZ . 43 CORE_DONE . 44 PRED",
        "41 CORE_BUSY . 42 W_STALL . 43 PHASE=HH . 44 PRED_NZ . 45 CORE_DONE . 46 PRED",
        "cmt2",
    )

repl(
    "  logic [44:0] sent_mask; // sticky: bit i set after message i completed",
    "  logic [46:0] sent_mask; // sticky: bit i set after message i completed",
    "mask_w",
)

# hex helper before hb_char
repl(
    "  function automatic logic [7:0] hb_char(input logic [5:0] sel, input logic [5:0] i);",
    "  function automatic logic [7:0] hex_nib(input logic [3:0] n);\n"
    "    return (n < 4'd10) ? (8'(\"0\") + 8'(n)) : (8'(\"A\") + 8'(n - 4'd10));\n"
    "  endfunction\n\n"
    "  function automatic logic [7:0] hb_char(input logic [5:0] sel, input logic [5:0] i);",
    "hex_nib",
)

# Insert W_STALL + PHASE, renumber PRED_NZ and CORE_DONE
old_tail = """      6'd42: unique case (i) // PRED_NZ (F1l)
        6'd0: return "P"; 6'd1: return "R"; 6'd2: return "E"; 6'd3: return "D";
        6'd4: return "_"; 6'd5: return "N"; 6'd6: return "Z";
        default: return 8'h00;
      endcase
      6'd43: unique case (i) // CORE_DONE (F1l)
        6'd0: return "C"; 6'd1: return "O"; 6'd2: return "R"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "O"; 6'd7: return "N";
        6'd8: return "E";
        default: return 8'h00;
      endcase"""

new_tail = """      6'd42: unique case (i) // W_STALL (F1n)
        6'd0: return "W"; 6'd1: return "_"; 6'd2: return "S"; 6'd3: return "T";
        6'd4: return "A"; 6'd5: return "L"; 6'd6: return "L";
        default: return 8'h00;
      endcase
      6'd43: unique case (i) // PHASE=HH (F1n)
        6'd0: return "P"; 6'd1: return "H"; 6'd2: return "A"; 6'd3: return "S";
        6'd4: return "E"; 6'd5: return "=";
        6'd6: return hex_nib(phase_100[7:4]);
        6'd7: return hex_nib(phase_100[3:0]);
        default: return 8'h00;
      endcase
      6'd44: unique case (i) // PRED_NZ (F1l)
        6'd0: return "P"; 6'd1: return "R"; 6'd2: return "E"; 6'd3: return "D";
        6'd4: return "_"; 6'd5: return "N"; 6'd6: return "Z";
        default: return 8'h00;
      endcase
      6'd45: unique case (i) // CORE_DONE (F1l)
        6'd0: return "C"; 6'd1: return "O"; 6'd2: return "R"; 6'd3: return "E";
        6'd4: return "_"; 6'd5: return "D"; 6'd6: return "O"; 6'd7: return "N";
        6'd8: return "E";
        default: return 8'h00;
      endcase"""

repl(old_tail, new_tail, "hb_char_cases")

# hb_len: replace 42/43 and add new
repl(
    "      6'd41: return 6'd9;   // CORE_BUSY\n"
    "      6'd42: return 6'd7;   // PRED_NZ\n"
    "      6'd43: return 6'd9;   // CORE_DONE\n"
    "      default: return 6'd28; // PRED row",
    "      6'd41: return 6'd9;   // CORE_BUSY\n"
    "      6'd42: return 6'd7;   // W_STALL\n"
    "      6'd43: return 6'd8;   // PHASE=HH\n"
    "      6'd44: return 6'd7;   // PRED_NZ\n"
    "      6'd45: return 6'd9;   // CORE_DONE\n"
    "      default: return 6'd28; // PRED row",
    "hb_len",
)

# hb_next signature + body: expand mask and insert probes
repl(
    "      input logic [44:0] mask,",
    "      input logic [46:0] mask,",
    "hb_next_mask",
)

# Find the argument list end for new params — after core_busy_ok
# Original ends: bind_busy_ok, wdma_busy_ok, wdma_done_ok, core_busy_ok,
#                pred_nz_ok, core_done_ok, pred_ok
repl(
    "      input logic bind_busy_ok, wdma_busy_ok, wdma_done_ok, core_busy_ok,\n"
    "      input logic pred_nz_ok, core_done_ok, pred_ok",
    "      input logic bind_busy_ok, wdma_busy_ok, wdma_done_ok, core_busy_ok,\n"
    "      input logic w_stall_ok, phase_ok,\n"
    "      input logic pred_nz_ok, core_done_ok, pred_ok",
    "hb_next_args",
)

repl(
    "    if (core_busy_ok && !mask[41]) return 6'd41;\n"
    "    if (pred_nz_ok && !mask[42]) return 6'd42;\n"
    "    if (core_done_ok && !mask[43]) return 6'd43;\n"
    "    if (pred_ok    && !mask[44]) return 6'd44;\n"
    "    return 6'd0;",
    "    if (core_busy_ok && !mask[41]) return 6'd41;\n"
    "    if (w_stall_ok && !mask[42]) return 6'd42;\n"
    "    if (phase_ok   && !mask[43]) return 6'd43;\n"
    "    if (pred_nz_ok && !mask[44]) return 6'd44;\n"
    "    if (core_done_ok && !mask[45]) return 6'd45;\n"
    "    if (pred_ok    && !mask[46]) return 6'd46;\n"
    "    return 6'd0;",
    "hb_next_body",
)

# nxt_sel call site
repl(
    "                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,\n"
    "                           pred_nz_100, core_done_100, pred_ready);",
    "                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,\n"
    "                           w_stall_100, phase_valid_100,\n"
    "                           pred_nz_100, core_done_100, pred_ready);",
    "nxt_call",
)

# have_pending
repl(
    "      (core_busy_100 && !sent_mask[41]) ||\n"
    "      (pred_nz_100   && !sent_mask[42]) ||\n"
    "      (core_done_100 && !sent_mask[43]) ||\n"
    "      (pred_ready    && !sent_mask[44]);",
    "      (core_busy_100 && !sent_mask[41]) ||\n"
    "      (w_stall_100   && !sent_mask[42]) ||\n"
    "      (phase_valid_100 && !sent_mask[43]) ||\n"
    "      (pred_nz_100   && !sent_mask[44]) ||\n"
    "      (core_done_100 && !sent_mask[45]) ||\n"
    "      (pred_ready    && !sent_mask[46]);",
    "have_pending",
)

repl("      sent_mask <= 45'd0;", "      sent_mask <= 47'd0;", "mask_rst")
repl(
    "          end else if (&sent_mask[44:0]) begin",
    "          end else if (&sent_mask[46:0]) begin",
    "mask_done",
)

SOC.write_text(t, encoding="utf-8")
print("WROTE", SOC)
print("sticky_w_stall" in t, "phase_valid_100" in t, "6'd46" in t)
