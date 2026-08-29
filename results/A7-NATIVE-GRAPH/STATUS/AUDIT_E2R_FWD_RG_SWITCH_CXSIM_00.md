# AUDIT — E2R-FWD-RG-SWITCH-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T15:15:00+07:00  
**Gate:** `E2R-FWD-RG-SWITCH-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-FWD-RG-SWITCH-CXSIM-00/CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_FWD_RG_SWITCH_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `dc60c89b-6b76-4ad4-b4f8-27330c65d6da` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=FWD_HEAVY: tok=1024 pos=1024 other=4325376 after_emb=4325376
rg_switches=2048 done=1 cycles=18205209 leave_emb=1
CONTROL OSC_2ND tok/pos matched
other_sets ≠ tile misses ≠ DMA misses
H_RIVAL EMB_DOM: falsified on SIM_FULL=1 core only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
DMA-time: ENGINEERING_INFERENCE (not this bag)
```

XSim PASS / `CLASS=FWD_HEAVY` / `C_FIX=NONE` is file-backed on `tiny_gpt803k_core #(.SIM_FULL(1))` only. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** silicon DMA time, and **not** a close of `graph_late_materialize_00`.

`other_sets=4325376` is OTHER-window `waddr` *changes* after leave ST_EMB. Independently re-derived `rg_switches=2048` = 2047 EMB TOK↔POS + 1 POS→OTHER. **4.3e6 other sets with ~2048 rg_switches is not 4.3e6 tile misses.**

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. `EMB_DOM` (after-EMB rg sets ≤ 64) is falsified on this SIM_FULL=1 vehicle only. Silicon `SIM_FULL=0` refill / other_sets×nline×MIG ms remains ENGINEERING_INFERENCE. `other_sets` was not sold as DMA/tile misses.

`VERDICT: PASS_NARROW` because the claim is XSim core-only start_fwd→done `waddr` set count (n=1 UNIT, stall=0). No SoC/MIG. XSim ≠ board.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout | Class |
|--------|---------|----------|-------|
| Vehicle | `VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE` | core-only SIM_FULL=1 | EVIDENCE (XSim) |
| Law | `OFF_TOK=0 OFF_POS=131072 OFF_L0=147456 OFF_HEAD=671744 D=128` `ctx_n=8` `TIMEOUT_CLK=40000000` | same | EVIDENCE (XSim) |
| CTX | `CTX_LOAD ntok=8 ctx_n_in=8` | ntok=8 | EVIDENCE (XSim) |
| ENTER | `ENTER_EMB cyc=1 st=1 waddr=0 sub=1 rg=0 w_stall=0` | ENTER / TOK_SET 1 | EVIDENCE (XSim) |
| TOK_SET 1024 | `n=1024 cyc=5116 waddr=1023 sub=1 tok_i=7 dim=127` | same | EVIDENCE (XSim) |
| POS_SET 1024 | `n=1024 cyc=5118 waddr=132095 sub=3 tok_i=7 dim=127` | same | EVIDENCE (XSim) |
| LEAVE | `LEAVE_EMB cyc=5120 st=2 waddr=132095 tok=1024 pos=1024 other=0` | st=ST_LN_S leave_emb=1 | EVIDENCE (XSim) |
| AFTER_SET 1 | `n=1 cyc=62444 waddr=147456 rg=2 tok=1024 pos=1024 other=1` | first OTHER OFF_L0 | EVIDENCE (XSim) |
| AFTER_SET 1e6 / 2e6 / 3e6 / 4e6 | all `rg=2` tok/pos=1024; ly=0/1/2/3 | STEPS.tsv match | EVIDENCE (XSim) |
| 18 HEARTBEAT | tok=1024 pos=1024 done=0 leave=1; other monotonic; all `waddr≥OFF_L0` | — | EVIDENCE (XSim) |
| CORE_DONE | `cyc=18205209 pred=0 waddr=802815 tok=1024 pos=1024 other=4325376 after=4325376` | same | EVIDENCE (XSim) |
| Summary | `TOK_SETS=1024 POS_SETS=1024 OTHER_SETS=4325376 TOTAL_SETS=4327424 RG_SWITCHES=2048` | same | EVIDENCE (XSim) |
| After-EMB split | `AFTER_EMB_TOK=0 AFTER_EMB_POS=0 AFTER_EMB_OTHER=4325376 AFTER_EMB_SETS=4325376` | same | EVIDENCE (XSim) |
| Done / timeout | `CYCLES=18205209 LEAVE_EMB=1 DONE=1 TIMEOUT=0 ENTERED=1` `w_stall_end=0` | same | EVIDENCE (XSim) |
| CLASS | `XSIM=FWD_HEAVY` `VERDICT_CLASS=FWD_HEAVY` | FWD_HEAVY | EVIDENCE (XSim) |
| Marker | `E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=FWD_HEAVY c_fix=NONE` | same | EVIDENCE (XSim) |
| Claims | `C_FIX=NONE` `PROGRAM=NO` `BOARD_PASS=not_claimed` `EXISTENCE=not_claimed` | NONE / NO / not claimed | EVIDENCE (XSim) |

`pred=0` is uninitialized SIM_FULL BRAM, not an existence token. Closeout states this. Held.

### tok / pos / leave (CONTROL)

Same ST_EMB 5-clk cadence as OSC_2ND CONTROL:

- TOK times: 1, 6, 11, … 5116. `1 + 5×1023 = 5116`.
- POS times: 3, 8, 13, … 5118. `3 + 5×1023 = 5118`.
- Last TOK `waddr=1023` = `tok[7]×128+127`. Last POS `waddr=132095` = `131072 + 7×128 + 127`.
- LEAVE tok=1024 pos=1024 other=0. All 18 heartbeats and all printed AFTER_SET keep tok/pos=1024.

CONTROL `OSC_2ND` tok/pos/leave **matched**.

### rg_switches = 2048 (re-derived; not trusted from the last line alone)

TB law: during ST_EMB, count TOK↔POS (`rg` 0↔1) flips; after leave, count `waddr` change **and** `rg` change.

- First set already in TOK (`waddr=0`); each later EMB set flips TOK↔POS. `1024` TOK→POS + `1023` POS→TOK = **2047** (same as OSC_2ND).
- LEAVE last `waddr=132095` is POS (`OFF_POS=131072` … `OFF_L0-1`).
- AFTER_SET 1: `waddr=147456=OFF_L0` `rg=2` → one POS→OTHER flip → **2048**.
- Every printed AFTER_SET has `rg=2`. Every heartbeat `waddr≥168396≥OFF_L0`. CORE_DONE `waddr=802815=NPARAM-1` is still OTHER (`≥OFF_HEAD=671744`). `AFTER_EMB_TOK=0` `AFTER_EMB_POS=0` — no return to TOK/POS.
- Therefore after-EMB region switches = **1**, not 4.3e6.

`rg_switches=2048` is EVIDENCE (XSim). It is a **region-class** counter. It is not a miss counter.

### other_sets = 4325376 (re-derived)

Measured by TB: after leave ST_EMB, each `waddr` **change** classified OTHER. CORE_DONE and summary both print 4325376. Heartbeats are monotonic and never disagree with `after`.

Pkg identity (ENGINEERING_INFERENCE that *explains* the count; not a second measurement):

```text
D=128 FF=256 V=1024 L=4 ntok=8
4*D*D + FF*D + D*FF = 65536+32768+32768 = 131072
4*8*131072 + V*D = 4194304 + 131072 = 4325376
```

This is the number of **scalar weight-address visits** (one set per `waddr` step) in the OTHER window plus head. It is **not** unique tiles, **not** `NCHUNK`, **not** DMA misses.

On this law, silicon `SIM_FULL=0` serializes one 131072-byte region (`TILE_W`). After POS, L0/L1/L2/L3/HEAD are further *region* fills — a handful of region switches — not 4.3e6 refills. `NCHUNK = NPARAM/128 = 6272` is the all-params chunk count if someone later maps DMA. That mapping was **not** claimed as EVIDENCE.

Preregistered `FWD_HEAVY`: `done=1` and (`other_sets>64` or `total_sets>2112`). Both fire: `4325376>64`, `4327424>2112`. `EMB_DOM` requires after-EMB sets ≤ 64; measured 4325376. Falsified **on SIM_FULL=1**.

n = 1 forward (`ctx_n=8`). Descriptive class only. Timeout unused (`18205209 < 40000000`). `$finish` at 182052256 ns; xsim elapsed 31 s.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `AEA9C0F8F5836C0DD40F97993C11BF621BB1FF389329B619321443FA854B68D0` | **match** (35101 bytes) |
| TB (`tests/xsim` and archive copy) | `8F9819415031E2C6CD6DE464BE2FE4F5AA6AF35B4646FD033FED85BC0BAE2B20` | **match** (identical) |
| TCL | `13F76E2A822E5F020C995C4BFBBE49AB169C1BF0168CA23BDD041B9122B23627` | **match** |
| `rtl/lm/tiny_gpt803k_core.sv` (read-only hash) | — | `4711A2F5B73D0A0D0C26A066AEC67A170717D5E8021479F7B7EC128D6A17B947` (same as EMB-RG audit; last git write 2026-08-27; not dirty this gate) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same VEHICLE / LEAVE / AFTER_SET / CORE_DONE / SUMMARY / CLASS / marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CLASS=`FWD_HEAVY` | **PASS.** `done=1` ∧ `other_sets=4325376>64` ∧ `total=4327424>2112`. |
| Re-derived tok/pos/other/after/done/rg | **1024 / 1024 / 4325376 / 4325376 / 1 / 2048.** Cadence + AFTER_SET rg=2 + heartbeat waddr + summary agree. |
| Marker `E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS` | **Present** with `verdict=FWD_HEAVY c_fix=NONE`. |
| SIM_FULL=1; no SoC/MIG | **Held.** TB `#(.SIM_FULL(1'b1))`. xvlog/xelab: `a7lm06_pkg` + LM leafs + `tiny_gpt803k_core` + TB. No `soc_top`, no MIG. |
| No `rtl/**` edit this gate | **Held.** New files are `tests/xsim` TB/tcl + archive. Core SHA unchanged vs EMB-RG CONTROL. |
| C_FIX=NONE / PROGRAM=NO | **Held.** Log + closeout. No `vivado.exe` impl. Session 15:03:08–15:03:41. |
| XSim ≠ board | **Held.** Closeout: after-EMB is OTHER `waddr` traffic on SIM_FULL=1; DMA-time ENGINEERING_INFERENCE. |
| other_sets sold as 4.3e6 tile / DMA misses | **No.** Closeout: “That is not silicon DMA.” `rg_switches=2048` stated as 2047 EMB + 1 POS→OTHER. |
| Existence / BOARD_PASS | **not claimed.** `pred=664` absent. `pred=0` not sold as existence. |

xelab `wdma_owner` unconnected is expected on this core-only TB (no SoC). Not a SoC/MIG instantiation.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| tok=1024 pos=1024 other=4325376 after_emb=4325376 rg_switches=2048 done=1 cycles=18205209 on this core | EVIDENCE (XSim) |
| `FWD_HEAVY` on SIM_FULL=1 | EVIDENCE (XSim) |
| `EMB_DOM` falsified on SIM_FULL=1 | EVIDENCE (XSim) |
| CONTROL OSC_2ND tok/pos/leave reproduced | EVIDENCE (XSim) |
| XSim ≠ board; stall=0 ≠ MIG refill | declared; held |
| `4*8*(4DD+FFD+DFF)+V*D` identity for the 4325376 count | ENGINEERING_INFERENCE (pkg arithmetic; matches measured other_sets) |
| other_sets × nline × MIG ms / silicon DMA time | ENGINEERING_INFERENCE — **not** this bag |
| 4.3e6 OTHER sets = 4.3e6 tile misses | **FALSE** if claimed; **not claimed** |
| silicon `CORE_DONE` / `pred=664` | **not claimed** |
| UART / C-FIX / existence | **not claimed** / NONE |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen; class from measured other_sets / done |
| Test deleted / skipped / class forced | not seen; `EMB_DOM` remains reachable if after-EMB ≤ 64 |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path; hierarchical peek only; `pred=0` unused as token |
| `SIM_FULL=0` DMA farm | not used |
| Instantiate `soc_top` / MIG | not in `sources.f` / xvlog / xelab |
| C-FIX / product `rtl/**` this gate | not used |
| Stop at leave ST_EMB | UNIT ran to `done=1`; timeout unused |
| Board / bitstream / JTAG | no `vivado.exe` impl |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |
| Sell 4.3e6 other_sets as DMA / tile misses | not done; rg_switches kept separate |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (264): `gate=E2R-FWD-RG-SWITCH-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=FWD_HEAVY` `sha256=AEA9C0F8F5836C0DD40F97993C11BF621BB1FF389329B619321443FA854B68D0` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop. **Not a FAIL** solely for that deferred next.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

`E2R-UART-HOLD-LONG-00` LISTEN-ONLY already closed (`CLASS=SILENT`, auditor PASS_NARROW 13:41+07). This CXSIM did not touch COM12.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=FWD_HEAVY` file-backed 1024/1024/4325376/done=1? | **Yes.** |
| `rg_switches` re-derived 2048 (2047+1), not 4.3e6? | **Yes.** |
| 4.3e6 other_sets sold as tile / DMA misses? | **No.** |
| DMA-time sold as measured? | **No.** ENGINEERING_INFERENCE. |
| XSim sold as board / silicon DMA? | **No.** |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited this gate? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `AEA9C0F8F5836C0DD40F97993C11BF621BB1FF389329B619321443FA854B68D0` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`).

Do **not** stop this no-board lane for COM12 LONGBOOT — that listen already closed `CLASS=SILENT`. Do **not** program COM12 until a **new** `com12_authorized_gate`. This PASS_NARROW does **not** authorize program, C-FIX, a product RTL edit, or treating `other_sets=4325376` as 4.3e6 tile/DMA misses.

---

## NOT VERIFIED

- Per-cycle dump of all 2048 region switches (log prints RG_SW n=1..6 only). Cadence + first AFTER_SET `rg=2` + no later TOK/POS reconstruct 2048; a full event dump was not archived.
- Per-cycle dump of all 4.3e6 OTHER `waddr` steps (log prints AFTER_SET at 1..4 and every 1e6). Count is TB-internal; intermediate heartbeats are consistent.
- Board UART / `SIM_FULL=0` refill cost (none claimed; COM12 not used).
- Whether silicon would refill L0/L1/L2/L3/HEAD as separate `TILE_W` regions under MIG (ENGINEERING_INFERENCE only; not 4.3e6 misses).
- Parent Task id `dc60c89b-6b76-4ad4-b4f8-27330c65d6da` accepted as stated; transcript not re-opened here.
- Pre-existing board `soc_top` WT dirt vs 2026-08-27 commit is outside this UNIT; this gate did not write or elaborate it.
- Main-tree dirty SOA / integrate RTL is pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell XSim `FWD_HEAVY` other_sets as silicon DMA / tile misses. Do not authorize a C-FIX from this bag. Next silicon unknown stays REARM `STILL_STALL` ∧ no `CORE_DONE` / `pred=664`, not this core-only count.
