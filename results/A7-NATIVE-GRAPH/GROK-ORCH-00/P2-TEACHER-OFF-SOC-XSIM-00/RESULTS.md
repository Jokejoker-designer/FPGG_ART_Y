# P2-TEACHER-OFF-SOC-XSIM-00 — RESULTS

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / BOARD_PASS.  
XSim ≠ board. UNIT = held-out query. TB drives **query tokens / reward / cmds only**.  
FPGA FSM mints MODE (TRAIN=`5`, exam=`8`). Host `MODE`/`cue`/`topk`/`answer` not driven.

Parent G4 SERIAL-STATE-01 = **PASS_FUNCTIONAL_PHYSICAL**. That bag is not overwritten.  
G1/G2/G3/G4 source SHA unchanged. Frozen LM-06 `tiny_gpt803k_core` unedited `#(.SIM_FULL(1))`.

Law: MAIN `PHASE2-SERIAL-G5-PREREG-00/PREREGISTER.md` SHA `98741C62…EFEB58`.

## Unknown

On one Fast RTL instance (G4 persist + new glue + bind + TinyGPT), can TRAIN→FLUSH/KILL/RELOAD→FREEZE emit live C1/C2/C9/C10 from query tokens only, with nine named cells, without a stub / sticky `lm_path` / hardcoded answer?

## Verdict

**PASS_FUNCTIONAL** (9/9 cells; raw CFRAME).  
**NOT** Teacher-Off. **NOT** HS-02. **NOT** §14. **NOT** BOARD_PASS.  
**NOT** PASS_PHYSICAL of the SoC — OOC measured **glue only**.

`pred=664` is never C1/C2/C9/C10 PASS. Stub SoC `D65F3524…` / UART `0x91` / `lm_path=0` is **FAIL CONTROL**, not instantiated.

## Source SHA (this gate)

| File | SHA256 | Note |
|------|--------|------|
| G1 `a7ng_feedback_resolver.sv` | `2219DA29…F3F5F7` | **unchanged** |
| G2 `a7ng_context_delta.sv` | `06143862…BBA800` | **unchanged** |
| G3 `a7ng_causal_learn_fast.sv` | `2177073D…F70EF6` | **unchanged** |
| G4 `a7ng_persist_gen_fast.sv` | `D1BF0340…D4DAC9` | **unchanged** |
| glue `a7ng_teacher_off_glue.sv` | `E67A5EED…ACDA0C` | new; MODE/ANCH/C9/C10 |
| wrapper `a7ng_teacher_off_soc_xsim.sv` | `2E3DB190…FA596E` | persist+glue+bind+TinyGPT |
| `a7ng_native_ctx_bind.sv` | `C5F57AD1…FC94CC` | existing; `grant_lm=1` |
| `tiny_gpt803k_core.sv` | `29D230FC…290C9E` | **unedited**; SIM_FULL=1 |
| TB | `4ACD1911…E9BD0A` | 9 cells |
| final `unit_xsim.log` | `1ADDE448…774969` | C10-clear re-run |

## Preserved FAIL / attempts

| Attempt | File SHA | What |
|---------|----------|------|
| 1 xelab | `0E8FCEDB…B3B328` | dual driver on TB `wd` (`always_ff` + `initial`) |
| 2 xsim | `A8281C2E…13DBD6` | REW hang after FREEZE (`latch_ready` needs `!freeze`; watchdog) |
| 3 xsim | `DBE9DB83…95DC30` | 9/7 TB string PASS **but** C10 `LMST/LMDN` sticky `1` on UNREL/CONTRA |

Attempt 3 is **not** the closing log. TB did not fail sticky C10; **raw CFRAME** does. Glue then clears `LMST/LMDN` on each `C_FIRE`. Closing log = `unit_xsim.log`.

## XSim — raw C1/C2/C9/C10

Marker: `TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9`  
Sim `$finish` at `4369607480 ns`. TinyGPT debug (`EMB_*`/`LNO`/`HEAD`, `wrd=x`) is frozen-core `$display`, not a stub.

Same instance: TRAIN A (MODE=5) → FLUSH → KILL → RELOAD → FREEZE (MODE=8) → exam A → TRESET → TRAIN B (MODE=5) → FLUSH/KILL/RELOAD → FREEZE → exam B.

| Tag | C1 MODE | C2 ANCH | C9 TOPK | R1S / R1R / R1O | C10 LMST LMDN OUT |
|-----|---------|---------|---------|-----------------|-------------------|
| TRAIN vis | 5 | (tokens) | KA rank=2 score=42 | typed after learn | LM not started |
| LIVE | **8** (train was 5) | — | — | — | DROP ack=5 |
| HELD_A | 8 | `…00a2` | `0706050403010002` | `22` / `04` / `202` | **1 1 0** |
| UNREL | 8 | `…00a3` ≠ A | `0f0e0d0c0b0a0908` (KA not auth) | `88` / `0a` / `208` | **0 0 0** |
| CONTRA | 8 | `…00a4` ≠ A | `0706050403010002` (qid map LIMIT) | `22` / `04` / `202` | **0 0 0** |
| INGRESS | — | — | — | — | cue=win=addr=tok=w=mode=**0** |
| HELD_B | 8 | `…00b2` ≠ A | `0f0e0d0c090b080a` | `8a` / `0c` / `20a` | **1 1 0** |

K* A = `0x1000` (low-8 `02` at rank 2 in HELD_A pack). K* B = `0x1008` (low-8 `08` at rank 2 in HELD_B pack). Score>39 on taught key after TRAIN.

### Nine cells

| Cell | Result | Evidence |
|------|--------|----------|
| LIVE_MODE | PASS | MODE 5→8 same instance; DROP=5; not localparam `0x91` |
| NATIVE_ANCHOR | PASS | ANCH from tokens; A=`a2` U=`a3` B=`b2` not constant |
| UPDATED_EVIDENCE | PASS | live TOPK/R1R after TRAIN; vis score 39→42 |
| LM_ACTIVE | PASS LIMIT | TinyGPT SIM_FULL=1; LMST then LMDN on HELD_A/B; **OUT=0** (uninit W, `wrd=x`) |
| HOST_INGRESS_ZERO | PASS | live counters all 0 |
| HELD_OUT_EXAM_A | PASS LIMIT | held-out A_exam_ok; UNREL does not treat KA as learned-auth; CONTRA MODE stays 8 |
| BLIND_EXAM_B | PASS | B rank=2 score=42; HOLD_A after B does not keep A auth; ANCH B≠A |
| STUB_NOT_PASS | PASS (CONTROL) | cite `D65F3524…` / `lm_path=0` / `0x91`; DUT uses TinyGPT; `exam_lm_used=1` |
| SCALE_20_THEN_40 | PASS (named) | Fast **mapping-A surrogate**; `ran_40=0`; 40 facts **not run** |

LM-correct + wrong-evidence = FAIL: **not invoked as PASS**. `OUT=0` is not a lucky expected token.

## LIMIT (do not upgrade)

1. **OUT=0** — TinyGPT weights uninitialized in this Fast SIM_FULL store (`wrd=x`, `logit0=x`). LIMIT, not a stub, not an exam answer.
2. **C10 OUT latches** last LM pred; FIRE clears LMST/LMDN only. This run OUT=0 so UNREL/CONTRA OUT=0 is not independent per-query OUT proof. LMST/LMDN per FIRE **are** independent (0 on UNREL/CONTRA).
3. **CONTRA token `A4` maps to persist qid=2** (same slot as HOLD_A). C9 therefore repeats the A pack. This is a Fast token→qid map LIMIT, **not** teacher-on restore (MODE stayed 8; LMST=0).
4. **SCALE** names 20-before-40; this vehicle is 1-mapping-A, not 20 facts.
5. Glue OOC **≠** SoC area. Persist remains G4 LUT700/FF748/1×RAMB18. TinyGPT **not** OOC'd.
6. XSim ≠ board. Do not program `A0219207…`.

## OOC — glue only (`a7ng_teacher_off_glue`)

`xc7a100tcsg324-1`, clock 80.000 ns. **Does not instantiate persist / TopK / TinyGPT.**

```text
LUT   = 123
FF    = 231
RAMB18= 0
DSP   = 0
WNS   = +74.167  TNS=0
WHS   = +0.124   THS=0
Hier  = a7ng_teacher_off_glue only
```

Do **not** add these numbers to G4 persist or LM. Do **not** claim full-chip FITS.

## What this gate must not answer

```text
Teacher-Off / HS-02 / §14 Teacher-off / LM-06 close
BOARD_PASS / NATIVE_V1_*_BOARD_PASS
G1–G4 law edits
40 / 256 / 800k facts
full-chip / COM12 / JTAG / bit
pred=664 as C1/C2/C9/C10
```

STOP for Codex audit. PROGRAM=NO.
