# P2-TEACHER-OFF-SOC-XSIM-00 — RESULTS

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / Gate14 / BOARD_PASS.  
XSim ≠ board. **NOT** Teacher-Off. **NOT** HS-02. **NOT** §14.

G1–G4 SHA unchanged. `tiny_gpt803k_core` unedited. Glue OOC LUT123/FF231 is **glue only**, not full-chip.

## Verdict (this correction)

**FAIL** — `FAIL_LM_ORACLE_MISMATCH` + residual `FAIL_LM_KNOWNNESS` (`x_ard≠0`).

Do **not** close G5. Do **not** call Teacher-Off.

Attempt 4 (pre-correction) remains **PASS_NARROW_FRAMING / FAIL_LM_KNOWNNESS** (`OUT=0` under X logits).

## Attempt 4 — kept

`unit_xsim_attempt4_narrow_framing_OUT0.log` SHA `1ADDE448…774969`  
`logit0=x`, `HEAD wrd=x`, C10 `OUT=0`, TB still printed CELLS=9. Default/argmax-under-X, not LM output.

## Oracle frozen BEFORE attempt 5

`ORACLE.json` SHA `2F890F8B…C9DBCF`  
WMEM `tests/xsim/a7lm06_wmem.hex` SHA `C204E559…3001E0` (802816).  
Sanity `forward([1])=744` = frozen LM-06 golden.

| Query | pack | oracle OUT |
|-------|------|------------|
| HOLD_A | `0706050403010002` | 549 |
| UNREL | `0f0e0d0c0b0a0908` | 861 |
| CONTRA | same as A | 549 |
| HOLD_B | `0f0e0d0c090b080a` | 237 |

## Attempt 5 — XSim after image load

`unit_xsim_attempt5_oracle_mismatch.log` SHA `47B3EADA…707EDC`  
Marker: `TEACHER_OFF_SOC_XSIM_FAIL fails=5`

```text
WMEM_INIT ok n=802816 readback0=-6
EMB_POS wrd=-3 (known)
ATTQK/ATTO/ADD numeric
HEAD wrd=6
SMX logit0=1233976   ← not X
```

| Query | C9 pack vs freeze | C10 LMST LMDN | FPGA OUT | oracle | LMST rise |
|-------|-------------------|---------------|----------|--------|-----------|
| HELD_A | MATCH | 1 1 | **60** | 549 | 1 unique |
| UNREL | MATCH | 1 1 | **22** | 861 | 2 unique |
| CONTRA | MATCH | 1 1 | **60** | 549 | 3 unique |
| HELD_B | MATCH | 1 1 | **155** | 237 | 4 unique |

Same pack → same FPGA OUT (A=CONTRA=60). Different pack → different OUT. Image loaded. Unique LMST→LMDN. **Not** sticky reuse. **Not** `OUT=0`.

```text
X_UNKNOWN wrd=0 ard=8196 acc=0 logit=0 pred=0 lmst_rise=5
```

`x_ard=8196` = act-ram reads still X (core unedited; TB does not poke act). Fail knownness.

FPGA OUT ≠ independent `a7lm06_fixed_ref.forward` on the same tokens/wmem. Isolated LM-06 golden remains **ntok=1 / pred=744** only. ntok=8 Native ctx is **not** bit-exact vs that Python law.

## What passed (framing only — not G5 close)

LIVE_MODE 5→8 DROP=5. Host ingress 0. mem_we_exam=0. Stub `D65F3524…` cited not instantiated. SCALE named, `ran_40=0`. C9 live typed packs. Glue OOC not full-chip.

## STOP

Cannot declare Teacher-Off / HS-02 / BOARD_PASS. Next unknown (later gate, not opened): either reconcile Python vs RTL ntok=8, or a separately frozen RTL-core-only oracle — **not** this close.

PROGRAM=NO.
