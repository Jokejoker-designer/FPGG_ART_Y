# P2-PERSIST-GEN-FAST-00 — RESULTS

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / G5 / Teacher-Off.  
XSim ≠ board. UNIT = mapping. Host reward-only.

Parent G3 SERIAL-TOPK-01: **PASS_FUNCTIONAL_PHYSICAL** (LUT 559 / FF 634 / WNS +69.879). That bag is not overwritten.

## Unknown

Can an isolated persist/generation core (TB models DDR; FPGA owns address / GEN / digest) prove the seven G4 preregister cells, keep G1/G2/G3 source SHA, and meet LUT≤1000 FF≤1000 BRAM≤1 DSP=0 with clean timing?

## Source SHA (locked)

| File | SHA256 | Note |
|------|--------|------|
| G1 `a7ng_feedback_resolver.sv` | `2219DA29…F3F5F7` | **unchanged** |
| G2 `a7ng_context_delta.sv` | `06143862…BBA800` | **unchanged** |
| G3 `a7ng_causal_learn_fast.sv` | `2177073D…F70EF6` | **unchanged** (not instantiated; query/insert law copied) |
| G3 TB | `167F5C6D…408767` | **unchanged** |
| G4 preregister | `9774C0AE…066B70` | law |
| DUT `a7ng_persist_gen_fast.sv` | `37550110…5B4084` | this gate |
| TB `tb_a7ng_persist_gen_fast.sv` | `A93F6132…E3D531` | this gate |

G3 has no persist ports; this DUT instantiates G1+G2+`a7ng_scorer_lane` and owns working-set + stamps + GEN.

## XSim (seven cells)

Vivado 2026.1. Clock 12.5 MHz (`#40`). `PERSIST_GEN_FAST_XSIM_PASS fails=0 CELLS=7`  
`unit_xsim.log` SHA `ED5DC76C…ECF67F`

| Cell | Observed | Result |
|------|----------|--------|
| FLUSH_RELOAD | A hold rank=2 score=42; kill drops learned effect; reload GEN=1 SDIG=`0000000001000001` restored; score=42 | PASS |
| FREEZE_BLOCKS_WRITE | host reward under freeze → ACK_DROP=5; no C7; C8/C9 unchanged | PASS |
| TRAIN_RESET_FORGETS_A | GEN 1→2; A hold score=39 (not learned-authoritative); remnants not visible | PASS |
| RUN_B_NE_A | ADIG=`0000000001000001` BDIG=`0000001008030208`; B hold score=42; A hold 39 | PASS |
| GEN0_NEVER_VISIBLE | TB-preloaded gen-0 record; live GEN=1; A score=39 | PASS |
| ROOT_INVALIDATE_BEFORE_WRAP | WRAP_LIMIT=6 surrogate of `2^32-1-256`; GEN stays 6 (not 0); A not resurrected | PASS |
| POWER_REPROGRAM_AUTHORITY | FPGA rst, DDR held; boot restores GEN=1 and A rank=2 score=42 | PASS |

C8 `GEN`/`SDIG` and C11 `ADIG`/`BDIG` are FPGA combo/state. Host sent `query_id` + `reward`/`txn_echo` only.

### Preserved FAIL / incomplete runs

| Attempt | Artifact | What |
|---------|----------|------|
| 1 hang | `unit_xsim_attempt1_hang.log` SHA `BF87A987…0DD550` | `slot_i` was 4-bit; P_FLUSH never reached 16 |
| 2 SDIG X | `unit_xsim_attempt2_sdigX.log` SHA `35FFB2CE…B33A90` | cells 7/7 but C8 low byte X from `8'(di)`; B C9 used unrelated ROM (unlearned score 50). **Not** the closing log |

## OOC (`xc7a100tcsg324-1`, 80.000 ns)

```text
LUT = 1272   (LUTRAM=0)     target <=1000  MISS +272
FF  = 1066                  target <=1000  MISS +66
BRAM= 0                     target <=1     met
DSP = 0                     target  0      met
WNS = +69.929  TNS=0
WHS = +0.110   THS=0
```

Hierarchy (route util): top 1075 LUT / 926 FF; `u_g1` 61/79; `u_g2` 96/7; `u_scorer` 46/54.  
Combo 16-way C8 digest + persist FSM + 16 stamps sit in the wrapper.

Timing **clean**. Resource **miss**.

## Verdict

**PASS_FUNCTIONAL / FAIL_PHYSICAL**

Do **not** open G5 / Teacher-Off / full-chip / board. Do **not** program `A0219207…`.  
Do **not** declare §14 reset/retrain PASS or BOARD_PASS. `pred=664` is not C8/C11.

STOP for Codex audit.
