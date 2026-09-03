# LN-FIX-AFAST-REGRESSION-00 — RESULTS

**PROGRAM=NO.** Core-only SIM_FULL=1. No graph / MIG / COM12 / JTAG / bit / P&R / full-chip / cofit.  
G5 FAIL and G5 R1 bags **not overwritten**. G1–G5 source SHA **unchanged**.

Oracle frozen **before** A/B XSim: `ORACLE.json` SHA `DFD19D41…1500D6`.  
Do **not** hardcode 664 as patched acceptance.

## Frozen inputs

| Item | Value |
|------|--------|
| Pack / ctx | `64'h3b392b291b190b09` `ctx_idx=0` `ctx_n=8` |
| Tokens | `[9, 11, 25, 27, 41, 43, 57, 59]` |
| WMEM | `C204E559…3001E0` (this gate; G5/LN-MU image) |
| Python ref | `05FACAF4…E8EEA870` law `lm06-signsgd-v1` |
| Python oracle | **pred=249** **logit0=1623245** |
| Sanity | `forward([1])=744` logit0 `−1090663` |
| Old core | `29D230FC…12290C9E` historical **664** |
| New core | `75706E2C…E8EFB5FB` |
| A-FAST historical WMEM cite | `9A6BBC7A…` — **not used**; current hex is C204E559 |

## A/B XSim (same TB, same WMEM, same pack)

Attempt1 plusarg `ARM=OLD` — xsim split `=`; preserved. Attempt2 `xvlog -d ARM_OLD`.

| Arm | CONTROL | A-FAST pred | logit0 | vs Python 249 / 1623245 | vs historical 664 |
|-----|---------|-------------|--------|-------------------------|-------------------|
| OLD `29D230FC` | **744** | **664** | **1310985** | mismatch (H1 LN) | **HISTORICAL_664_REPRO** |
| NEW `75706E2C` | **744** | **249** | **1623245** | **bit-exact** | ≠ 664 |

OLD logit0 `1310985` matches GO-H4 `H4_PRED=664` SMX logit0 (same pack, unpatched LN).  
NEW L0 N1 tok1+ re-enters `ST_LN_S` (per-token μ). CONTROL ntok=1 unchanged **744** both arms.

```text
AFAST_ARM=OLD pred=664 logit0=1310985
HISTORICAL_664_REPRO old_pred=664
AFAST_ARM=NEW pred=249 logit0=1623245 python_pred=249 python_logit0=1623245
SEMANTIC_CHANGE_EXACT pred=249 python=249 historical_664_old_sha=29D230FC
LN_FIX_AFAST_REGRESSION_PASS arm=NEW fails=0 pred=249
```

Logs: `unit_xsim_old.log` SHA `20020E8B…9A52ECA9`  
`unit_xsim_new.log` SHA `AA2E77D8…3EA606C9`

## Verdict

**PASS** — patched core **equals independent Python** on the exact A-FAST pack/tokens.  
**SEMANTIC_CHANGE_EXACT** — patched pred **249 ≠ 664**. 664 remains **historical old-SHA** (`29D230FC`) evidence. Acceptance **not** retargeted to 664. Law/weights **not** edited.

G1 `2219DA29` G2 `06143862` G3 `2177073D` G4 `D1BF0340` G5 glue `7FECB8B8` **unchanged**.

## Not this gate

No P&R, bit, board, Teacher-Off, cofit. XSim ≠ silicon. Native-V1 UART `pred=664` is a **different** existence number (old core / old LN schedule). Do not mix with LM-06 Python 249.

STOP for Codex / human **before cofit**. PROGRAM=NO.
