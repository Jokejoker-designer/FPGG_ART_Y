# AUDIT — E2R-ACK-WHILE-R-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-ACK-WHILE-R-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** `results/A7-NATIVE-GRAPH/STATUS/E2R_ACK_WHILE_R_CXSIM_CLOSEOUT.md`  
**Agent archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-ACK-WHILE-R-CXSIM-00/`  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=ACK_ONLY_AFTER_DONE: file-backed on still-in-R-then-complete mux+stub
dest=5 only after done / !m_busy: YES (first dbg dest=5 snap)
dest=5 ∧ in-R (class) on this vehicle: NEVER
dest=5 ∧ in-R without done: 0
ATOM dma_st sold as FACT: NO (CDC FINDING)
C_FIX: NONE
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON SDONE=0: not answered
```

Parent STATUS closeout **already exists** (`STATUS/E2R_ACK_WHILE_R_CXSIM_CLOSEOUT.md`). Auditor did not rewrite it. XSim PASS / `CLASS=ACK_ONLY_AFTER_DONE` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. ATOM `dma_st` is not sold as FACT. Silicon `SDONE=0` is not answered.

`VERDICT: PASS_NARROW` because the claim is XSim-stub dest-vs-in-R only (n=1 query). Grant-rose vs sequential silicon `GRANT=0` remains a disclosed MUX deviation. Residual `s_busy=1` at dest=5 is ui-side after CDC; class follows tile `m_busy` / done.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` / `probe_table.csv` (not the closeout table). Class dest = first `dbg_tile_dst==5` always_ff snap (`IN_R_AT_DEST5`, `BUSY_AT_DEST5`, `S_DONE_BEFORE_DEST5`). Dest=4 occupancy = UNIT snap (`SNAP_*`), not live `FIRST_DESTWAIT` / `DEST_BUSY`.

| Metric | Raw log / CSV | Agent closeout / STATUS | Class |
|--------|---------------|-------------------------|-------|
| Vehicle banner | `STILLR_THEN_COMPLETE s_dma_idle=0` | still-in-R then complete | EVIDENCE |
| dest=4 UNIT snap | `DEST4=1` `IN_R_AT_SNAP=1` `SNAP_SDONE … s_busy=1 m_busy=1 wst=3` `sdone_st=0` `snap_cyc=355` | dest=4 still in-R, sticky=0 | EVIDENCE |
| First `dbg` dest=5 | `DEST5=1` t=30040000 `DEST_BUSY … dest=5 raw=5 in_r=0 … m_busy=0` `snap5_cyc=7` | dest=5 | EVIDENCE |
| `IN_R_AT_DEST5` | `0` (`wst=1` ≠ `W_R`=3) | 0 | EVIDENCE |
| Tile busy at dest=5 | `BUSY_AT_DEST5 s_busy=1 m_busy=0 wst=1` | `m_busy=0` | EVIDENCE |
| Done before dest=5 | `S_DONE_BEFORE_DEST5=1` `S_DONE_AT_DEST5=1` `M_DONE_AT_DEST5=0` | done already seen; `wdma_done`=0 at snap | EVIDENCE |
| Overlap flags | `DEST5_WHILE_IN_R_NODONE=0 DEST5_WHILE_BUSY_NODONE=0` | no dest=5 while in-R/busy without done | EVIDENCE |
| CLASS | `CLASS=ACK_ONLY_AFTER_DONE` + marker | ACK_ONLY_AFTER_DONE | EVIDENCE |
| C_FIX | `C_FIX=NONE` `C_FIX_CONSTITUENT=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |
| EXISTENCE | `EXISTENCE=not_claimed` | Existence NO | EVIDENCE |

TB class law (`tb_e2r_ack_while_r_cxsim_00.sv`): dest=4 seen ∧ in-R at dest=4 snap, then dest=5 seen, and not (`dest5_while_in_r` ∨ `dest5_while_busy_nodone`) → `ACK_ONLY_AFTER_DONE`. Matches.

`dest5_while_in_r` requires `w_st==W_R` ∧ busy ∧ no done seen. First dest=5 snap has `w_st=1` (`W_WAITOWN`), so in-R is 0 regardless of residual `s_busy`. Tile `wdma_busy=0` at that snap is the `!busy` path of H_RIVAL.

`FIRST_DONE_CYC=0` is the live-sticky latch on the dest=4 NBA (same STILLR live-vs-snap: `DEST_BUSY` dest=4 already shows `sdone_st=1` / `sdone_ever=1` because `dest4_seen_ui` unblocks `W_HOLD` inside one 80 ns `core_clk`). UNIT dest=4 snap remains `sdone_st=0`. That row is **not** ROSE (complete-before-dest=4). Closeout correctly uses SNAP for dest=4 occupancy.

`DEST_BUSY` t=30120000 `dest=5 in_r=1 wst=3` is **after** the first dest=5 snap (t=30040000 `in_r=0`). Those `in_r`/`w_st` rows are ui-domain samples on `core_clk` (they flicker 3/1 every other cycle) and are **not** class — agent closeout already refuses them. Class claim “dest=5 ∧ in-R never” means the first `dbg` dest=5 snap / `DEST5_WHILE_IN_R_NODONE`, not every later `DEST_BUSY` sample.

Raw `TILE.dst` became 5 two core cycles before `dbg_tile_dst` (`t=29880000` dest=4 raw=5). Documented `dst_s1` delay. FINDING only. At `t=29960000` raw=5 already has `m_busy=0 m_done=1`.

One query, `snap5_cyc=7`. Not a cycle farm.

---

## dest=5 only after done / !busy

File-backed on the class snap:

- First `dbg` dest=5 at t=30040000: `m_busy=0`, `IN_R_AT_DEST5=0`, `S_DONE_BEFORE_DEST5=1`.
- Tile `m_busy` already 0 at t=29800000 (dest still 4) — `!busy` before dest=5.
- Tile `m_done=1` at t=29960000 (dest still 4) — done pulse before dest=5.
- Dest=4 UNIT snap still `m_busy=1` sticky=0 — complete is after dest=4 occupancy, before dest=5.

H_CANDIDATE `ACK_WHILE_R` **not supported** on this vehicle. H_RIVAL **supported** on this vehicle.

---

## dest=5 ∧ in-R never (class)

`IN_R_AT_DEST5=0`. `DEST5_WHILE_IN_R_NODONE=0`. First dest=5 `DEST_BUSY` row: `in_r=0`.

Later `DEST_BUSY` / `FIRST_DEST5` dump at t=30120000 shows `dest=5 in_r=1` as a ui-on-core sample after class latch. Not used as class. STATUS “Never dest=5 ∧ in-R on this vehicle” is the class snap, not a claim that every later `DEST_BUSY` `in_r` bit stayed 0.

---

## ATOM `dma_st` not sold as FACT

Dispatch, PREREGISTER, agent closeout, and STATUS: silicon ATOM `dma_st=5` is **FINDING** (unsafe 3b CDC), **not class**, **not FACT**. Class dest is `dbg_tile_dst`. No document equates stub `w_st` to silicon `dma_st` encoding identity.

---

## Silicon `SDONE=0` not answered

Agent Interpretation: this bag **does not prove** silicon ATOM1 dest=5 means the core saw done/idle. XSim stub+CDC ≠ board UART / MIG. STATUS “compatible with core seeing done/idle” is ENGINEERING_INFERENCE from this vehicle, not a silicon measurement.

Silicon `SDONE=0` stays NEEDS_EXPERIMENT (`E2R-ATOMIC-SDONE-PROBE-00`, COM12). H_RIVAL text (“Silicon dest=5 means core saw done/idle”) is the **hypothesis**, not the verdict.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `ADA5C6E36E88624570EF5F795E9EDBB8EDE70EC851F4863DED5BA73F5FA840D5` | **match** |
| TB (`tests/xsim` and archive copy) | `6D7AA58E7B84532969941C629DE54E0C0718B6CB048B0F7701218B186B067812` | **match** (identical) |
| STILLR CONTROL `E2R-SDONE-STILLR-CXSIM-00/xsim.log` | `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7` | **match** (not re-run) |
| `rtl/board/a7ng_wdma_cdc.sv` | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` | **match** (not edited this gate) |

`xsim_stdout.txt` SHA256 `3FA2D2B7830C3A7FB2EC57D92BFBC8DC6F04C9CF9C896AEB8C57DCCC68BF214F` (not claimed; transcript agrees with `xsim.log` body).

xvlog / xelab: no `ERROR` / `CRITICAL WARNING` in stdout. xvlog analyzed `tests/xsim/tb_e2r_ack_while_r_cxsim_00.sv`. `$finish` from that file line 950. Snapshot `e2r_ack_while_r_cxsim_00`. Vivado 2026.1. Session 00:41:49–00:41:51. No `vivado.exe` impl.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest=4 snap in-R (`w_st=3`,`s_busy=1`,`m_busy=1`) sticky=0; dest=5 snap `in_r=0` `m_busy=0` done already seen | EVIDENCE (XSim) |
| `ACK_ONLY_AFTER_DONE` on this still-in-R-then-complete vehicle; `ACK_WHILE_R` not supported here | EVIDENCE (XSim) |
| STILLR CONTROL dest=4 occupancy (SNAP_DONE0, SHA `4F71A710…`) is the dest=4 control | EVIDENCE (XSim CONTROL, not re-run) |
| XSim ≠ board; stub ≠ MIG; `w_st` ≠ silicon `dma_st` encoding identity | declared; held |
| ATOM `dma_st=5` is FACT / class | FALSE_OR_OVERCLAIM if sold; parent and agent do not sell it |
| silicon `SDONE=0` proven / answered | FALSE_OR_OVERCLAIM if sold; parent and agent do not sell it |
| silicon ATOM1 dest=5 means core saw done/idle | ENGINEERING_INFERENCE / NEEDS_EXPERIMENT; agent says **not proven** |

No averaging of XSim with board. Marker `E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS` is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen; `ACK_WHILE_R` and `ACK_ONLY_AFTER_DONE` both legal PASS markers |
| Test deleted / skipped / tolerance widened | not seen; `FAIL_NO_ACK` / `FAIL_NO_DESTWAIT` still legal |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Force dest / `TILE_DST` | not used; `tile_dst` from `dbg_tile_dst_o`; `raw_dst` is hierarchical READ only |
| Complete-before-dest=4 (ROSE) | not used; snap `wst=3` sticky=0; `W_HOLD` gated on `dest4_seen_ui` |
| Hold-busy forever after dest=4 (MUX) | not used; dest=5 occurred; `W_HOLD` pulses done |
| C-FIX / A2 / LiteScope / `r_path_idle=1` / retie `s_dma_idle` | log `C_FIX=NONE`; TB `s_dma_idle=1'b0` |
| Product RTL this gate | TB + tcl + archive only; CDC SHA unchanged vs STILLR |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 00:41:49–00:41:51 |
| Sell ATOM `dma_st` as FACT | not sold |
| `BOARD_PASS` / existence PASS | explicitly not claimed; no `pred=664` |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

`sources.f` compiles `a7ng_cue_soa_mig_top` (graph wrapper, same as STILLR) and does **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or Digilent MIG IP.

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last line (223): `gate=E2R-ACK-WHILE-R-CXSIM-00` `agent=a7-ng-xsim-verify` `result=DISPATCHED` `board=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00; dest=5 vs in-R`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, deferred by EXISTENCE BEFORE QUALITY). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the last jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=ACK_ONLY_AFTER_DONE` file-backed? | **Yes.** dest=5 ∧ `IN_R_AT_DEST5=0` ∧ done/`!m_busy` before dest=5. |
| dest=5 only after done / `!busy`? | **Yes** on the class snap (`m_busy=0`, `S_DONE_BEFORE_DEST5=1`). |
| dest=5 ∧ in-R on this vehicle? | **Never** at first dest=5 snap. Later `DEST_BUSY` `in_r` flicker is FINDING, not class. |
| ATOM `dma_st` sold as FACT? | **No.** CDC FINDING. |
| `C_FIX=NONE`? | **Yes.** |
| Silicon `SDONE=0` answered? | **No.** Compatible inference only; COM12 probe still required. |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent STATUS closeout

Present before this audit: `results/A7-NATIVE-GRAPH/STATUS/E2R_ACK_WHILE_R_CXSIM_CLOSEOUT.md`.  
Log SHA, `ACK_ONLY_AFTER_DONE`, `C_FIX=NONE`, dest=5 after done/`!m_busy`, ATOM `dma_st` FINDING, Existence NO — all match the raw bag. Auditor left it in place.

---

## NOT VERIFIED

- Board UART / COM12 after this XSim (none claimed; board not used).
- Whether silicon ATOM1 dest=5 was same-cycle with done/idle on the programmed bit (next bind, not this bag).
- Whether silicon `dbg_s_done_sticky` / `SDONE` is 0 or 1 at dest=4 ∧ `dma_st=5` (still `E2R-ATOMIC-SDONE-PROBE-00`).
- Whether dirty board-tree `soc_top.sv` bytes beyond the F1/ATOM probe path differ from the programmed bit (out of this gate’s claim).
- Full xvlog/xelab warning catalogs line-by-line (no ERROR / CRITICAL WARNING in stdout).
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell ATOM `dma_st=5` as FACT. Do not sell silicon `SDONE=0` as answered. Next silicon unknown stays dest=4/5 vs done on COM12, not this stub.
