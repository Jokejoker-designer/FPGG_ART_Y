# AUDIT — E2R-EMB-RG-SWITCH-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T14:56:00+07:00  
**Gate:** `E2R-EMB-RG-SWITCH-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-EMB-RG-SWITCH-CXSIM-00/CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_EMB_RG_SWITCH_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `7ef152e0-0472-4017-a123-e2790e686e23` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=OSC_2ND: tok_sets=1024 pos_sets=1024 rg_switches=2047 leave_emb=1
H_RIVAL HOLD_RG: falsified on SIM_FULL=1 core only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
1.18e6 DMA / 20 min: ENGINEERING_INFERENCE (not this bag)
```

XSim PASS / `CLASS=OSC_2ND` / `C_FIX=NONE` is file-backed on `tiny_gpt803k_core #(.SIM_FULL(1))` only. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** silicon DMA time, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. `HOLD_RG` (rg_switches ≤ 2) is falsified on this SIM_FULL=1 vehicle only. Silicon `SIM_FULL=0` refill / nline×count×MIG ms remains ENGINEERING_INFERENCE.

`VERDICT: PASS_NARROW` because the claim is XSim core-only ST_EMB `waddr` set count (n=1 UNIT, stall=0). No SoC/MIG. XSim ≠ board.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout | Class |
|--------|---------|----------|-------|
| Vehicle | `VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE` | core-only SIM_FULL=1 | EVIDENCE (XSim) |
| Law | `OFF_TOK=0 OFF_POS=131072 OFF_L0=147456 D=128` `ctx_n=8` `TIMEOUT_CLK=100000` | same | EVIDENCE (XSim) |
| CTX | `CTX_LOAD ntok=8 ctx_n_in=8` | ntok=8 | EVIDENCE (XSim) |
| ENTER | `ENTER_EMB cyc=1 st=1 waddr=0 sub=1 rg=0 w_stall=0` | ENTER / TOK_SET 1 | EVIDENCE (XSim) |
| TOK_SET 1 | `n=1 cyc=1 waddr=0 sub=1 tok_i=0 dim=0` | same | EVIDENCE (XSim) |
| POS_SET 1 | `n=1 cyc=3 waddr=131072 sub=3 tok_i=0 dim=0` | same | EVIDENCE (XSim) |
| TOK_SET 2 | `n=2 cyc=6 waddr=1 sub=1 tok_i=0 dim=1` | same | EVIDENCE (XSim) |
| TOK_SET 1024 | `n=1024 cyc=5116 waddr=1023 sub=1 tok_i=7 dim=127` | same | EVIDENCE (XSim) |
| POS_SET 1024 | `n=1024 cyc=5118 waddr=132095 sub=3 tok_i=7 dim=127` | same | EVIDENCE (XSim) |
| LEAVE | `LEAVE_EMB cyc=5120 st=2 waddr=132095 sub=0 emb_cycles=5119` | st=ST_LN_S leave_emb=1 | EVIDENCE (XSim) |
| Summary | `TOK_SETS=1024 POS_SETS=1024 RG_SWITCHES=2047 EMB_CYCLES=5119 LEAVE_EMB=1 TIMEOUT=0 ENTERED=1` | same | EVIDENCE (XSim) |
| CLASS | `XSIM=OSC_2ND` `VERDICT_CLASS=OSC_2ND` | OSC_2ND | EVIDENCE (XSim) |
| Marker | `E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=OSC_2ND c_fix=NONE` | same | EVIDENCE (XSim) |
| Claims | `C_FIX=NONE` `PROGRAM=NO` `BOARD_PASS=not_claimed` `EXISTENCE=not_claimed` | NONE / NO / not claimed | EVIDENCE (XSim) |

`STEPS.tsv` matches ENTER / POS_SET1 / TOK_SET2 / last POS / LEAVE.

Independent cadence (not trusting the last-line counters alone):

- ST_EMB sub loop is 5 clk (0 set TOK, 1, 2 set POS, 3, default write+inc). RTL `tiny_gpt803k_core.sv` ST_EMB case.
- TOK times: 1, 6, 11, 16, … 5116. `1 + 5×1023 = 5116`.
- POS times: 3, 8, 13, 18, … 5118. `3 + 5×1023 = 5118`.
- Last TOK `waddr=1023` = `tok[7]×128+127` with packed ctx tokens 0..7. Last POS `waddr=132095` = `131072 + 7×128 + 127`.
- First set is already in TOK (`waddr=0`); each later set flips TOK↔POS. `1024` TOK→POS + `1023` POS→TOK = **2047**.
- `8×128 = 1024`. Preregistered `OSC_2ND` window is ±16; this run hit exact 1024/1024, so the window did not save a near-miss.

Core `$display` `EMB t=195000 dim=0` / `t=245000 dim=1` is DUT ST_EMB, not TB-only.

`HOLD_RG` = rg_switches ≤ 2. Measured 2047. Falsified **on SIM_FULL=1**. `w_stall=0` throughout (`ENTER` and `w_stall_end=0`). That is not silicon DMA.

n = 1 embedding (`ctx_n=8`). Descriptive class only. Not a cycle farm. `$finish` at 51366 ns. Timeout unused.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `BEE33A7775A1B6105E5729890F928829B8E2F71BB925A4E7F11EEBA8CE4C687C` | **match** (3225 bytes) |
| TB (`tests/xsim` and archive copy) | `FBAA8C05CD61A7CA02D5FE9589B86706B7B5F6EEB24D64B4E2FA84AC5A2AFDF3` | **match** (identical) |
| TCL | `88BF75DBAF124AE16BE5D670624C078EF4533D10167E2C8461B8E2E32BECF9EF` | **match** |
| `rtl/lm/tiny_gpt803k_core.sv` (read-only hash) | — | `4711A2F5B73D0A0D0C26A066AEC67A170717D5E8021479F7B7EC128D6A17B947` (last git write 2026-08-27; not dirty this gate) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same VEHICLE / TOK_SET / POS_SET / SUMMARY / CLASS / marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CLASS=`OSC_2ND` | **PASS.** tok_sets=1024 ∧ pos_sets=1024 ∧ leave_emb=1. |
| Re-derived tok/pos/rg/leave from raw log | **1024 / 1024 / 2047 / 1.** Cadence + last waddr + summary agree. |
| Marker `E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS` | **Present** with `verdict=OSC_2ND c_fix=NONE`. |
| SIM_FULL=1; no SoC/MIG | **Held.** TB `#(.SIM_FULL(1'b1))`. xvlog/xelab: `a7lm06_pkg` + LM leafs + `tiny_gpt803k_core` + TB. No `soc_top`, no MIG. |
| No `rtl/**` edit this gate | **Held.** New files are `tests/xsim` TB/tcl + archive. `tiny_gpt803k_core.sv` clean vs 2026-08-27 commit. Board `soc_top` WT dirty vs that commit is **before** this UNIT and was not compiled. |
| C_FIX=NONE / PROGRAM=NO | **Held.** Log + closeout. No `vivado.exe` impl. Session 14:47:33–14:47:36. |
| XSim ≠ board | **Held.** Closeout: HOLD_RG falsified on SIM_FULL=1 only; nline×count×MIG ms ENGINEERING_INFERENCE. |
| 1.18e6 DMA / 20 min | **ENGINEERING_INFERENCE.** Dispatch `8*128*(1024+128)=1,179,648`. Not measured here (stall=0). Not sold as EVIDENCE. |
| Existence / BOARD_PASS | **not claimed.** `pred=664` absent. |

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| tok_sets=1024 pos_sets=1024 rg_switches=2047 leave_emb=1 on this core | EVIDENCE (XSim) |
| `OSC_2ND` on SIM_FULL=1 | EVIDENCE (XSim) |
| `HOLD_RG` falsified on SIM_FULL=1 | EVIDENCE (XSim) |
| XSim ≠ board; stall=0 ≠ MIG refill | declared; held |
| Silicon `SIM_FULL=0` would refill on each switch | ENGINEERING_INFERENCE (RTL comment + prior POS nline=128); **not** this bag |
| 1.18e6 chunks / ~20 min at 1 ms/chunk | ENGINEERING_INFERENCE |
| silicon `CORE_DONE` / `pred=664` | **not claimed** |
| UART / C-FIX / existence | **not claimed** / NONE |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen; class from measured tok/pos counts |
| Test deleted / skipped / class forced | not seen; `HOLD_RG` remains reachable if rg_switches≤2 and counts miss the ±16 window |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path; hierarchical peek only |
| `SIM_FULL=0` DMA farm | not used |
| Instantiate `soc_top` / MIG | not in `sources.f` / xelab |
| C-FIX / product `rtl/**` this gate | not used |
| Stop before leave ST_EMB without `NO_EMB` | leave_emb=1; timeout unused |
| Board / bitstream / JTAG | no `vivado.exe` impl |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |
| Sell 1.18e6 / 20 min as measured | not done; labeled ENGINEERING_INFERENCE |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (261): `gate=E2R-EMB-RG-SWITCH-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=OSC_2ND` `sha256=BEE33A7775A1…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=OSC_2ND` file-backed 1024/1024/2047/leave=1? | **Yes.** |
| `HOLD_RG` falsified only on SIM_FULL=1? | **Yes.** |
| 1.18e6 / 20 min sold as measured? | **No.** ENGINEERING_INFERENCE. |
| XSim sold as board / silicon DMA? | **No.** |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited this gate? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `BEE33A7775A1B6105E5729890F928829B8E2F71BB925A4E7F11EEBA8CE4C687C` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`). This PASS_NARROW does **not** authorize program, C-FIX, a product RTL edit, or treating `OSC_2ND` as measured silicon DMA time.

---

## NOT VERIFIED

- Per-cycle dump of all 2047 region switches (log prints RG_SW n=1..6 only). Cadence + last waddr reconstruct 2047; a full event dump was not archived.
- Board UART / `SIM_FULL=0` refill cost (none claimed; COM12 not used).
- Whether silicon `w_stall` rises on every TOK↔POS flip under MIG (ENGINEERING_INFERENCE only).
- Parent Task id `7ef152e0-0472-4017-a123-e2790e686e23` accepted as stated; transcript not re-opened here.
- Pre-existing board `soc_top` WT dirt vs 2026-08-27 commit is outside this UNIT; this gate did not write or elaborate it.
- Main-tree dirty SOA / integrate RTL is pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell XSim `OSC_2ND` as silicon DMA / 20 min. Do not authorize a C-FIX from this bag. Next silicon unknown stays REARM `STILL_STALL` ∧ no `CORE_DONE` / `pred=664`, not this core-only count.
