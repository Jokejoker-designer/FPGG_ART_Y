# LM06-NTOK8-KNOWNNESS-DIFF-00 — RESULTS

**PROGRAM=NO.** Core-only SIM_FULL=1. No graph / MIG / COM12 / JTAG / bit / full-chip / Gate14.  
G5 remains **FAIL_LM_ORACLE_MISMATCH + FAIL_LM_KNOWNNESS**. **NOT** Teacher-Off.  
`tiny_gpt803k_core.sv` **unedited** SHA `29D230FC…`.

Oracle frozen **before** XSim: `checkpoints.json` / `ORACLE_SHA.txt`.  
WMEM SHA `C204E559…3001E0`. CONTROL `forward([1])=744`. UNIT tokens `[2,0,1,3,4,5,6,7]` ref pred **549** logit0 **1648634**.

## Verdict

**FAIL** — first non-vacuous deterministic divergence is **layer-0 LN (n1), token 1 dim 0**.  
Do **not** patch frozen core in this gate.

## Control

`CONTROL_PASS pred=744` — image + TB `mem_we` init is not the bug.

## First X (act read)

| Class | Result |
|-------|--------|
| Consumed ard X | **none** (`ard_consumed=0`) |
| Any ard X | `cyc=398` `st=ST_EMB_POS=1` `sub=1` `aaddr=128` `tok=1 dim=1` |
| wrd/acc/logit/pred X | 0 |

Vacuous: `act_ram128k16` has **no reset**; EMB_POS `sub=1` still points `aaddr` at the previous write cell. Value is **not** consumed (`ST_EMB_TOK sub=2` ard known). Not a TB arbitrary-zero issue.

`x_unknown_consumed = 0`. Residual `ard_any=7168` is unconsumed port-A traffic on unread/X cells.

## First deterministic mismatch (non-vacuous)

```text
PLANE EMB mismatches=0
FIRST_MISMATCH N1_L0 tk=1 d=0 addr=16512 rtl=-16 exp=-20
PLANE N1_L0 mismatches=512 first=128
UNIT pred=60 oracle=549 logit0_rtl=363484 logit0_ref=1648634
```

- Embedding **bit-exact** vs `a7lm06_fixed_ref.embed`.
- Token 0 n1 matches (python `n1[0][0]=16` = RTL `LNO q=16`).
- Token 1: same live `ard=-5` as python `emb[1][0]=-5`, but LN out RTL **-16** vs ref **-20**.
- RTL `LNO` for that beat: `mu=-1 sc=4 q=-16` → `(-5-(-1))*16/4=-16`.
- Python `-20` implies **mu=0** on the same vector (`(-5-0)*16/4=-20`).

**Invariant broken:** per-token `mu = sum(x)//D` (Python) vs RTL `ST_LN_S` + `floordiv_s48` (`tiny_gpt803k_core.sv` approx **lines 456–488**, then `ST_LN_O` 544–589).  
CONTROL ntok=1 never exercises token 1. Divergence starts at **ntok≥2 LN token 1**.

Core edit **not done**. Next (not opened): prereg a dedicated LN-mu/floor-div gate.

## Attempts kept

| File | What |
|------|------|
| `unit_xvlog_attempt1_D_redecl.log` | svh `D` clash |
| `unit_xsim_attempt2_watchdog.log` | fork `wait(st)` hung; CONTROL 744; UNIT logit0 seen |
| `unit_xsim.log` / `unit_xsim_attempt3_n1_div.log` | this FAIL |

G5 bags not overwritten.

STOP. PROGRAM=NO.
