# Codex audit correction — do not close G5 from attempt 4

**PROGRAM=NO.** No board / Gate14 / COM12 / JTAG / bit / full-chip.  
**TEACHER_OFF=not_claimed.** **HS-02=not_claimed.** **BOARD_PASS=not_claimed.**

## Attempt 4 (closing log before this correction)

File: `unit_xsim_attempt4_narrow_framing_OUT0.log`  
SHA: `1ADDE44822B596C506F9676F1CD7F6A63CA82CBBCCA5EFD4F7CC4CDFEA774969`

Raw TinyGPT `$display`: `ATTQK`/`ATTO`/`ADD`/`HEAD`/`logit0` = **X**.  
C10 `OUT=0` and TB `CELLS=9` still printed PASS.

**Classification: PASS_NARROW_FRAMING / FAIL_LM_KNOWNNESS**

`OUT=0` is consistent with argmax/default under X (`pred <= 8'd0` at reset; ST_ARG on X logits). It is **not** meaningful LM-06 output. Do not close G5. Do not call Teacher-Off.

Glue OOC LUT123 / FF231 / WNS+74.167 remains **glue only**, not full-chip.

## This rerun (before XSim)

Independent frozen-ref `python/ref/a7lm06_fixed_ref.py` + `tests/xsim/a7lm06_wmem.hex`  
WMEM SHA `C204E559…3001E0` (802816 words).  
Sanity `forward([1]) = 744` matches frozen `a7lm06_expected.txt`.

| Query | pack | tokens | oracle OUT | query SHA |
|-------|------|--------|------------|-----------|
| HOLD_A | `0706050403010002` | 2,0,1,3,4,5,6,7 | **549** | `80E38F6F…` |
| UNREL | `0f0e0d0c0b0a0908` | 8..15 | **861** | `F4168CF7…` |
| CONTRA | same pack as A | same | **549** | `2FA36770…` |
| HOLD_B | `0f0e0d0c090b080a` | 10,8,11,9,12..15 | **237** | `CA08C0D9…` |

Oracle frozen in `ORACLE.json` / `g5_lm_oracle.svh` **before** this XSim.
