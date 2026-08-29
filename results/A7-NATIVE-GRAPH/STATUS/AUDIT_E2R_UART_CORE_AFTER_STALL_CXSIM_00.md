# AUDIT — E2R-UART-CORE-AFTER-STALL-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T14:38:00+07:00  
**Gate:** `E2R-UART-CORE-AFTER-STALL-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-UART-CORE-AFTER-STALL-CXSIM-00/CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_UART_CORE_AFTER_STALL_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `ba4453be-6720-457e-a5a2-bea602ea76ac` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=CORE_PRED: SEL_A=51 SEL_B=52 SEL_C=54 SEL_D=55
H_CANDIDATE PRINT_DEAD: falsified on this hb_next replica only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
REARM STILL_STALL: not re-classed
```

XSim PASS / `CLASS=CORE_PRED` / `C_FIX=NONE` is file-backed on a copied `hb_next` + `have_pending` stepper. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** silicon `CORE_DONE`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. REARM `STILL_STALL` (`W_STALL` / `PHASE=01`, no `CORE_DONE`) is not re-classed as `CORE_DONE` or `CORE_PRED`.

`VERDICT: PASS_NARROW` because the claim is XSim replica-only (n=1 UNIT). TB-driven `pred_ok`. No SoC/MIG instance. XSim ≠ board.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

Walk of the copied `hb_next` (SoC order 51,52,53,54,55 after ATOM 69/70; other `*_ok`=0; ATOM 69/70=0; `bind_ok`=0; BOOT `mask[0]` sent first):

| Step | Drive / mask | Function hit | Raw log | Closeout | Class |
|------|--------------|--------------|---------|----------|-------|
| SETUP_PRE | mask empty, all ok=0 | `!mask[0]` → **0** | `STEP=SETUP_PRE nxt_sel=0 … core_done=0 pred_ready=0` | SETUP_PRE **0** | EVIDENCE (XSim) |
| A | stall=1 phase=1 core=0 pred=0 mask51=0 | `w_stall && !mask[51]` → **51** | `STEP=A nxt_sel=51 … mask51=0 … core_done=0` | A **51** | EVIDENCE (XSim) |
| B | after send 51 | `phase && !mask[52]` → **52** | `STEP=B nxt_sel=52 … mask51=1 mask52=0 … core_done=0` | B **52** | EVIDENCE (XSim) |
| C | raise `core_done` after send 52; `pred_nz`=0 | skip 53; `core_done && !mask[54]` → **54** | `STEP=C nxt_sel=54 … mask51=1 mask52=1 mask54=0 … core_done=1 pred_ready=0` | C **54** | EVIDENCE (XSim) |
| D | raise `pred_ready` after send 54 | `pred_ok && !mask[55]` → **55** | `STEP=D nxt_sel=55 … mask54=1 mask55=0 … core_done=1 pred_ready=1` | D **55** | EVIDENCE (XSim) |
| Summary | | | `SEL_SETUP=0 SEL_A=51 SEL_B=52 SEL_C=54 SEL_D=55` | same | EVIDENCE (XSim) |
| CLASS | | | `XSIM=CORE_PRED` `VERDICT_CLASS=CORE_PRED` | CORE_PRED | EVIDENCE (XSim) |
| Marker | | | `E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS verdict=CORE_PRED c_fix=NONE` | same | EVIDENCE (XSim) |
| Claims | | | `C_FIX=NONE` `PROGRAM=NO` `BOARD_PASS=not_claimed` `EXISTENCE=not_claimed` `NO_SOC_TOP NO_MIG` | NONE / NO / not claimed | EVIDENCE (XSim) |

`STEPS.tsv` matches those five rows. `mask[55]` stays 0 because D is observe-only (no send after 55).

PRINT_DEAD = `core_done=1` and never 54/55. At C, `core_done=1` and `nxt_sel=54`; at D, `nxt_sel=55`. Falsified on this replica.

n = 1 print sequence. Descriptive class only. Not a cycle farm. `$finish` at 8 ns.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `7F327F091D1889866087B0C4FE2BECB7CA57E1876A1B57BB6B9770BE7D77C86A` | **match** (3194 bytes) |
| TB (`tests/xsim` and archive copy) | `B183AC0254EA9F2FD05E18EE1DFEB06185429C339FFDEA7082C525C2256C02EA` | **match** (identical) |
| TCL | `2754CD8AF1E5C123FBAA95B5A835097715EE058D2CA5913B66FB96DC261C71AE` | **match** |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` (read-only hash) | `8298376EA060D028303A7148591D99416D8F7C56D116E011E7A32543BC3A2CF0` | **match** (not compiled; not instantiated) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same STEP / SEL / CLASS / marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CLASS=`CORE_PRED` on copied `hb_next` replica | **PASS.** After mask 51/52, late `core_done` → 54, then `pred_ready` → 55. |
| sel 51,52,54,55 from raw log + function walk | **51 → 52 → 54 → 55.** Independent of closeout table. |
| Marker `E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS` | **Present** with `verdict=CORE_PRED c_fix=NONE`. |
| No `rtl/**` edit this gate | **Held.** New files are `tests/xsim` TB/tcl + archive. `sources.f` is TB only. Board `soc_top` WT dirty vs 2026-08-27 commit (mtime 2026-08-28 00:57, **before** this UNIT 14:31); this gate hashed it read-only and did not compile it. |
| No SoC / MIG instantiate | **Held.** xvlog analyzed only `tb_e2r_uart_core_after_stall_cxsim_00`. xelab compiled that module only. |
| C_FIX=NONE / PROGRAM=NO | **Held.** Log + closeout. |
| XSim ≠ board | **Held.** Closeout: not silicon UART; not proof REARM would print 54/55. |
| REARM `STILL_STALL` not re-classed as `CORE_DONE` | **Held.** REARM closeout remains `STILL_STALL`; `CORE_DONE` absent; `W_STALL`/`PHASE=01`. This bag does not overwrite that class. |
| Existence / BOARD_PASS / UART RTL fix | **not claimed.** `pred=664` absent. No C-FIX authorized. |

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| sel sequence 51,52,54,55 on this replica | EVIDENCE (XSim) |
| `PRINT_DEAD` falsified on this replica | EVIDENCE (XSim) |
| `pred_ok` / `pred_ready` TB-driven (`bind_100` held 0) | EVIDENCE (XSim stimulus); SoC `pred_ready = bind_100 && (pred_100 != 0)` **not** exercised |
| XSim ≠ board; replica ≠ UART capture | declared; held |
| REARM would have printed 54/55 | **not claimed**; stays NEEDS_EXPERIMENT (REARM still `STILL_STALL`) |
| silicon `CORE_DONE` / `pred=664` | **not claimed** |
| UART RTL fix / C-FIX | **not claimed** / NONE |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen; verdict computed from measured `nxt_sel` |
| Test deleted / skipped / class forced | not seen; 51/52 miss → `NO_STALL`; 54-without-55 → `CORE_ONLY` |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Raise `core_done` before 51/52 | not used; C after send 52 |
| Skip `sent_mask` | not used; BOOT + 51 + 52 + 54 sent |
| Instantiate `soc_top` / MIG | not in `sources.f` |
| C-FIX / UART RTL / product `rtl/**` this gate | not used |
| Re-class REARM `STILL_STALL` as `CORE_DONE` | not done |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 14:31:35–14:31:37 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (258): `gate=E2R-UART-CORE-AFTER-STALL-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=CORE_PRED` `sha256=7F327F091D…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=CORE_PRED` file-backed 51→52→54→55? | **Yes.** |
| `PRINT_DEAD` falsified only on this replica? | **Yes.** |
| REARM `STILL_STALL` re-classed as `CORE_DONE`? | **No.** |
| XSim sold as board / silicon UART? | **No.** |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited this gate? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `7F327F091D1889866087B0C4FE2BECB7CA57E1876A1B57BB6B9770BE7D77C86A` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`). This PASS_NARROW does **not** authorize program, C-FIX, a UART RTL fix, or a re-class of REARM `STILL_STALL`.

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Whether silicon `pred_ready` can rise (`bind_100 && pred_100 != 0`) after `W_STALL`/`PHASE` — TB forced `pred_ok` with `bind_100=0`.
- Whether silicon `core_done_100` ever rises after REARM `PHASE=01` (REARM still `STILL_STALL`).
- Bit-exact copy of every unused `have_pending` / `hb_next` formal (slots 46–68 tied to stub zeros). Path 51/52/54/55 does not depend on those zeros being distinct SoC nets.
- Parent Task id `ba4453be-6720-457e-a5a2-bea602ea76ac` accepted as stated; transcript not re-opened here.
- Pre-existing board `soc_top` WT dirt vs 2026-08-27 commit (mtime 00:57) is outside this UNIT; this gate did not write or elaborate it.
- Main-tree dirty SOA / integrate RTL is pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell replica 54/55 as silicon `CORE_DONE` / `pred=664`. Do not authorize a UART RTL fix from this bag. Next silicon unknown stays REARM `STILL_STALL` ∧ no `CORE_DONE` / `pred=664`, not this replica.
