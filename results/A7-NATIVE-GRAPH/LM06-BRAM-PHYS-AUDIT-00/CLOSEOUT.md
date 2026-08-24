# CLOSEOUT — LM06-BRAM-PHYS-AUDIT-00

| Field | Value |
|-------|-------|
| Gate | `LM06-BRAM-PHYS-AUDIT-00` |
| Type | `READ_ONLY_RESEARCH` |
| Result class | **`AUDIT_COMPLETE_NO_PARITY_TILE_GAIN`** |
| Main loop | `ddr_cue_soa_00r_axi_liveness` — **not modified** |
| Lock | Codex Attempt 10 — **not taken / not modified** |
| BOARD_PASS | **not declared** |
| Implementation PASS | **none** |

## ONE UNKNOWN (answered at audit scope)

**Q:** What physically causes 132 RAMB36, and can unused parity/tail/aspect remove ≥1 tile without law/semantics change?

**A:** Footprint is driven primarily by **96 port-bound bit-sliced TDP tiles** plus **34 SDP tiles implementing 104-bit words as (72 full + 32 tail-in-x72-shell)**. Unused parity exists on bit-slices and on the 17 tail tiles, but **no bank has a proven N→N−1 physical remapping** under READ_ONLY evidence. Therefore: **no parity-driven tile gain**.

## Evidence pack

| Artifact | Role |
|----------|------|
| `BRAM_PHYSICAL.tsv` | Per-cell widths, ECC, DIP/DOP signal/const counts, classification |
| `LOGICAL_BANKS.tsv` | Five logical banks + removable=0 |
| `BRAM_CONTROL_GROUPS.tsv` | Owner/mode/width groups |
| `BRAM_LOSS_DECOMPOSITION.md` | Parity vs width/tail vs port |
| `RESULTS.md` | FACT / INFERENCE / NEEDS_EXPERIMENT |
| `DCP_SHA256.txt` | Frozen DCP hash |
| `audit_phys_bram.tcl` / probes | Reproducible READ_ONLY method |
| `vivado_audit_console.log` | Vivado 2026.1 batch log |

## STOP

Human decides whether any **one** NEEDS_EXPERIMENT (E1–E4 in RESULTS) advances.  
Do not auto-chain. Do not open `lm06_wm_ladder` from this closeout.
