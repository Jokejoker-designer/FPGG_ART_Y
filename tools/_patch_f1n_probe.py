#!/usr/bin/env python3
"""One-shot F1n probe patch for arty_a7_ng_native_v1_ab_soc_top.sv"""
from pathlib import Path

p = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv")
t = p.read_text(encoding="utf-8")


def must_replace(t, old, new, tag):
    if old not in t:
        # help debug
        key = old.split("\n")[0][:60]
        idx = t.find(key[:20]) if len(key) > 20 else -1
        raise SystemExit(f"FAIL {tag}: missing block. nearby idx={idx}\nOLD[0]={old[:120]!r}")
    return t.replace(old, new, 1)


# Discover actual F1m sync / clock names from file
import re

m = re.search(
    r"// F1m:.*?\n  sync_bits #\(\.WIDTH\(3\)\) u_f1m_probe_sync \(\n"
    r"    \.clk\((\w+)\), \.rst_n\((\w+)\),\n"
    r"    \.async_in\(\{sticky_core_busy, sticky_wdma_done, sticky_wdma_busy\}\),\n"
    r"    \.sync_out\(\{core_busy_100, wdma_done_100, wdma_busy_100\}\)\n"
    r"  \);",
    t,
)
if not m:
    # try alternate port names sync_bits vs sync_bits
    m = re.search(
        r"// F1m:.*?\n  (\w+) #\(\.WIDTH\(3\)\) (\w+) \(\n"
        r"    \.clk\((\w+)\), \.rst_n\((\w+)\),\n"
        r"    \.async_in\(\{sticky_core_busy, sticky_wdma_done, sticky_wdma_busy\}\),\n"
        r"    \.sync_out\(\{core_busy_100, wdma_done_100, wdma_busy_100\}\)\n"
        r"  \);",
        t,
    )
    if not m:
        raise SystemExit("Cannot find F1m sync block")
    sync_mod, sync_inst, clk100, rst100 = m.group(1), m.group(2), m.group(3), m.group(4)
    f1m_block = m.group(0)
else:
    clk100, rst100 = m.group(1), m.group(2)
    sync_mod = "sync_bits"
    sync_inst = "u_f1m_probe_sync"
    f1m_block = m.group(0)

print(f"F1m sync: mod={sync_mod} clk={clk100} rst={rst100}")

# Also discover sync module name from F1l
m2 = re.search(r"(\w+) #\(\.WIDTH\(3\)\) u_f1l_probe_sync", t)
if m2:
    sync_mod = m2.group(1)
    print(f"sync module from F1l: {sync_mod}")

# Discover async_in vs async_in naming
if ".async_in(" in f1m_block:
    ain, aout = "async_in", "sync_out"
elif ".async_in(" in t[t.find("u_f1m"): t.find("u_f1m") + 300]:
    ain, aout = "async_in", "sync_out"
else:
    # sniff
    snip = t[t.find("u_f1m_probe_sync") : t.find("u_f1m_probe_sync") + 280]
    print("SNIP:", snip)
    if ".async_in(" in snip:
        ain, aout = "async_in", "sync_out"
    elif ".din(" in snip:
        ain, aout = "din", "dout"
    else:
        raise SystemExit("unknown sync port names")

print(f"ports {ain}/{aout}")

# 1) Declarations
t = must_replace(
    t,
    "  logic sticky_wdma_busy, sticky_wdma_done, sticky_core_busy; // F1m probe",
    "  logic sticky_wdma_busy, sticky_wdma_done, sticky_core_busy; // F1m probe\n"
    "  logic w_stall; // F1n from tiny_gpt803k via ab_core\n"
    "  logic sticky_w_stall; // F1n probe\n"
    "  logic [7:0] latched_phase; // F1n: phase while core_busy",
    "decl",
)

# 2) Reset
t = must_replace(
    t,
    "      sticky_core_busy <= 1'b0;",
    "      sticky_core_busy <= 1'b0;\n"
    "      sticky_w_stall   <= 1'b0;\n"
    "      latched_phase    <= 8'd0;",
    "reset",
)

# 3) Sticky set — tolerate sticky_qgo vs sticky_qgo naming
set_pat = re.search(
    r"if \(sticky_qgo && \(sticky_fwd \|\| start_fwd\) && core_busy\) sticky_core_busy <= 1'b1;",
    t,
)
if not set_pat:
    set_pat = re.search(
        r"if \(sticky_qgo && \(sticky_fwd \|\| start_fwd\) && core_busy\) sticky_core_busy <= 1'b1;",
        t,
    )
if not set_pat:
    raise SystemExit("fail set sticky_core_busy")
old_set = set_pat.group(0)
t = must_replace(
    t,
    old_set,
    old_set
    + "\n"
    + "      // F1n: W_STALL sticky + latched phase (after Q_GO/FWD; sticky+UART only)\n"
    + "      if (sticky_qgo && (sticky_fwd || start_fwd) && w_stall) sticky_w_stall <= 1'b1;\n"
    + "      if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) latched_phase <= phase;",
    "set",
)
# Fix sticky_qgo name if file uses sticky_qgo
if "sticky_qgo && (sticky_fwd || start_fwd) && w_stall" in t and "sticky_qgo && (sticky_fwd || start_fwd) && core_busy) sticky_core_busy" in t:
    # extract actual qgo name from core_busy line
    mq = re.search(
        r"if \((\w+) && \(sticky_fwd \|\| start_fwd\) && core_busy\) sticky_core_busy",
        t,
    )
    if mq and mq.group(1) != "sticky_qgo":
        qn = mq.group(1)
        t = t.replace(
            "if (sticky_qgo && (sticky_fwd || start_fwd) && w_stall)",
            f"if ({qn} && (sticky_fwd || start_fwd) && w_stall)",
        )
        t = t.replace(
            "if (sticky_qgo && (sticky_fwd || start_fwd) && core_busy) latched_phase",
            f"if ({qn} && (sticky_fwd || start_fwd) && core_busy) latched_phase",
        )

# 4) Port connect
t = must_replace(
    t,
    "    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred), .phase_o(phase),",
    "    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred), .phase_o(phase),\n"
    "    .w_stall_o(w_stall),",
    "port",
)

# 5) UART decls
t = must_replace(
    t,
    "  logic wdma_busy_100, wdma_done_100, core_busy_100; // F1m",
    "  logic wdma_busy_100, wdma_done_100, core_busy_100; // F1m\n"
    "  logic w_stall_100, phase_valid_100; // F1n\n"
    "  logic [7:0] phase_100; // F1n latched phase",
    "uart_decl",
)

# 6) Insert F1n CDC after F1m block — re-find after prior edits
m = re.search(
    rf"// F1m:.*?\n  {re.escape(sync_mod)} #\(\.WIDTH\(3\)\) \w+ \(\n"
    rf"    \.clk\({clk100}\), \.rst_n\({rst100}\),\n"
    rf"    \.{ain}\(\{{sticky_core_busy, sticky_wdma_done, sticky_wdma_busy\}}\),\n"
    rf"    \.{aout}\(\{{core_busy_100, wdma_done_100, wdma_busy_100\}}\)\n"
    rf"  \);",
    t,
)
if not m:
    raise SystemExit("fail re-find F1m after edits")
f1m_block = m.group(0)
f1n_cdc = f"""{f1m_block}
  // F1n: W_STALL sticky + latched PHASE → UART (after CORE_BUSY)
  {sync_mod} #(.WIDTH(1)) u_f1n_wstall_sync (
    .clk({clk100}), .rst_n({rst100}),
    .{ain}(sticky_w_stall),
    .{aout}(w_stall_100)
  );
  {sync_mod} #(.WIDTH(1)) u_f1n_phase_valid_sync (
    .clk({clk100}), .rst_n({rst100}),
    .{ain}(sticky_core_busy),
    .{aout}(phase_valid_100)
  );
  {sync_mod} #(.WIDTH(8)) u_f1n_phase_sync (
    .clk({clk100}), .rst_n({rst100}),
    .{ain}(latched_phase),
    .{aout}(phase_100)
  );"""
t = must_replace(t, f1m_block, f1n_cdc, "f1n_cdc")

# 7) Expand sent_mask 45→47 bits and comments
t = must_replace(
    t,
    "  //          41 CORE_BUSY … 42 PRED_NZ … 43 CORE_DONE … 44 PRED",
    "  //          41 CORE_BUSY … 42 W_STALL … 43 PHASE=HH … 44 PRED_NZ … 45 CORE_DONE … 46 PRED",
    "cmt_sel",
)
t = must_replace(
    t,
    "  logic [44:0] sent_mask; // sticky: bit i set after message i completed",
    "  logic [46:0] sent_mask; // sticky: bit i set after message i completed",
    "mask_w",
)

# Alternate comment style
if "41 CORE_BUSY" in t and "42 W_STALL" not in t:
    t = t.replace(
        "41 CORE_BUSY … 42 PRED_NZ … 43 CORE_DONE … 44 PRED",
        "41 CORE_BUSY … 42 W_STALL … 43 PHASE=HH … 44 PRED_NZ … 45 CORE_DONE … 46 PRED",
    )

# 8) hb_char: insert W_STALL + PHASE before PRED_NZ; renumber PRED_NZ/CORE_DONE
# Find PRED_NZ case and insert before it
pred_nz = re.search(
    r"      6'd42: unique case \(i\) // PRED_NZ \(F1l\).*?endcase",
    t,
    re.S,
)
if not pred_nz:
    pred_nz = re.search(
        r"      6'd42: unique case \(i\) // PRED_NZ.*?endcase",
        t,
        re.S,
    )
if not pred_nz:
    raise SystemExit("fail find PRED_NZ hb_char")

hex_helper_needed = "function automatic logic [7:0] hex_nib" not in t
insert = """      6'd42: unique case (i) // W_STALL (F1n)
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
      endcase"""

# Replace old PRED_NZ block with insert (which includes renumbered PRED_NZ)
# Keep CORE_DONE as next — renumber 43→45
old_pred_nz = pred_nz.group(0)
# Extract body style from old — already hardcoded ASCII matching file style
t = must_replace(t, old_pred_nz, insert, "hb_char_wstall_phase")

# Renumber CORE_DONE 6'd43 → 6'd45
core_done_case = re.search(
    r"      6'd43: unique case \(i\) // CORE_DONE \(F1l\).*?endcase",
    t,
    re.S,
)
if not core_done_case:
    raise SystemExit("fail CORE_DONE case after renumber attempt")
t = must_replace(
    t,
    core_done_case.group(0),
    core_done_case.group(0).replace("6'd43:", "6'd45:", 1),
    "core_done_renum",
)

# 9) Add hex_nib function before hb_char
if hex_helper_needed:
    # find "function automatic logic [7:0] hb_char"
    hb = "  function automatic logic [7:0] hb_char"
    if hb not in t:
        hb = "  function automatic logic [7:0] hb_char"
    if "function automatic logic [7:0] hb_char" not in t:
        # try alternate name
        mhb = re.search(r"  function automatic logic \[7:0\] (\w+)\(", t)
        raise SystemExit(f"no hb_char; found {mhb.group(1) if mhb else None}")
    helper = """  function automatic logic [7:0] hex_nib(input logic [3:0] n);
    return (n < 4'd10) ? (8'("0") + 8'(n)) : (8'("A") + 8'(n - 4'd10));
  endfunction

  function automatic logic [7:0] hb_char"""
    # careful: only first occurrence of function ... hb_char
    idx = t.find("  function automatic logic [7:0] hb_char")
    if idx < 0:
        raise SystemExit("hb_char not found for helper insert")
    t = t[:idx] + helper.replace(
        "  function automatic logic [7:0] hb_char",
        "  function automatic logic [7:0] hb_char",
        1,
    )
    # The helper string already ends with hb_char line — but we duplicated.
    # Fix: replace just by inserting helper BEFORE hb_char
    # Re-read approach:
    raise SystemExit("abort — fix helper insert logic")

print("checkpoint after hb_char edits, continuing with rewritten helper logic...")
p.write_text(t, encoding="utf-8")
print("Wrote intermediate — will finish in part2")
PY