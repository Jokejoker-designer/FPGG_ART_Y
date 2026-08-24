# BRAM_OWNERSHIP_POST_ROUTE — integrate_fit (2026-08-22)

**Gate:** `integrate_fit` (IMPLEMENT)  
**Device:** Digilent Arty A7-100T `xc7a100tcsg324-1` (135 Block RAM Tiles)  
**Authority:** MEM-00 / LM06-Q0 audit + prior INTEGRATE measures + NG-03 MIG util  
**Unknown:** ownership-audited tile cut ≤130 meets R6 numeric gates?

## Source facts (do not overwrite)

| Artifact | Provenance | Value |
|----------|------------|------:|
| LM-06 BRAM | `build/out/a7lm06_utilization_route.rpt` / Q0 | **132** |
| A0.3 BRAM | A03 route util | **3** |
| 01R / 02M | frozen util | 56 / 52 |
| Naive glue | HS-11 | **243/135 FAIL** |
| Banks+scorer | `fit_banks_util.rpt` post-route | **0** |
| MIG (NG-03) | NG-03 closeout post-route | **0** BRAM |
| WM-00 OOC | `BRAM-WM-00` util_route | **0** BRAM; **WNS=−290.499 OPEN** (not bankable) |
| MAS OOC LUT | FIT_NOTE_NG06 | ~522k LUT ≈ **824%** — excluded from cut |

Frozen SHA control (pre-measure): LM-06 / 01R / 02M / A0.3 MATCH expected TERMGEN control.

## Ownership table (required columns)

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? |
|-----------|----------:|------|-------|-------------|------------|---------------|
| LM-06 `u_w` | 64 | weight staging | LM | within run | limited | weights already DDR; buffer may shrink if shape-sized |
| LM-06 `u_snap` | 2 | snapshot | LM | within run | no | optional |
| LM-06 `u_a` | 66 | activation scratch | LM | transient | **YES** vs graph | **partial** |
| Graph hotset / shared cut | ≤64 on-chip (was 66) | query/path WM | GRAPH | transient | phase-mux w/ `u_a` | overflow → DDR |
| Episode/index banks DEPTH=16 | 0 | DDR-mapped windows | GRAPH | no (DDR auth) | n/a | **yes** (primary store) |
| WM-00 working set | 0 | LUT/FF intent | GRAPH | no | n/a | DDR feed |
| Digilent AXI MIG buffers | 0 | DDR PHY/AXI | always | yes | no | n/a |
| A0.3 encoder | 3 | encoder | — | — | — | **not concurrent** on this cut |
| `multi_agent_share` full OOC | — | epoch share | — | — | — | **excluded** (LUT illegal) |
| Debug / ILA | 0 claimed | — | — | — | — | off in measure |

## Declared tile cut (this experiment)

```text
residual (u_w + u_snap)     = 66  always-on
shared (DDR-spill u_a cut)  = 64  exclusive owner FSM (GRAPH|HOLD|LM)
A0.3 concurrent             =  0  DROP (narrow)
banks + 16PE scorer         =  0
MIG (cited NG-03)           =  0
--------------------------------
composed target             = 130  (prefer <=130; device 135)
```

Owner invariant: exactly one writer on shared pool; HOLD ⇒ `we=0`.

## Prior falsifiers (still stand)

- `u_a_phase_share` full-66 + A0.3 → **135/135 LIMIT** (need ≤134 then; now prefer ≤130)
- Naive 243/135 **HS-11 FAIL**
- WM-00 WNS=−290.499 **not** sold as timing bankable

## What this audit does not claim

- Not Native V1 BOARD_PASS  
- Not functional DDR act-spill RTL (capacity proxy only)  
- Not concurrent encoder + LM + graph on one bit  
- Not 100 MHz SoC with WM-00 combinational path closed  
