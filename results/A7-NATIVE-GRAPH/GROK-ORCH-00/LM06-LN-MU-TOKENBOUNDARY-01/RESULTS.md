# LM06-LN-MU-TOKENBOUNDARY-01 — RESULTS

**PROGRAM=NO.** Core-only SIM_FULL=1 XSim. No graph / MIG / COM12 / JTAG / bit / full-chip / Gate14.  
G5 remains **FAIL_LM_ORACLE_MISMATCH + FAIL_LM_KNOWNNESS**. **NOT** Teacher-Off. G5 regression is a **later separate gate** — not run here.  
G5 / G1–G4 / WMEM / law bags **not overwritten**.

Parent: `LM06-NTOK8-KNOWNNESS-DIFF-00` FAIL — EMB exact, consumed-X=0, first miss L0 N1 tok1 d0 RTL −16 vs ref −20 (μ RTL −1 vs ref 0).

Oracle frozen **before** any core edit: `ORACLE.json` / `ln_oracle.svh` / `oracle_emb.hex` / `oracle_n1_l0.hex`.  
WMEM SHA `C204E559…3001E0`. Law `lm06-signsgd-v1`. CONTROL `forward([1])=744`. UNIT tokens `[2,0,1,3,4,5,6,7]` pack `0706050403010002` ref pred **549** logit0 **1648634**.

## One unknown (prereg)

For ntok=8, is the first LN μ mismatch **H1** (stale / missing / duplicate sample, or skipped `ST_LN_S` at token boundary — acc / BRAM latency / schedule) or **H2** (same 128-sample signed sum, wrong `floordiv_s48` numerator / quotient / timing)?

Do **not** assume H2. Core edit only after first invariant proof.

## Trace contract (each token, L0 ten=0)

- 128 accepted `ST_LN_S` samples, `aaddr` dim 0..127 unique
- signed `acc` immediately before `fd_go` (sum before division)
- `fd_n`, `fd_q`, latched μ
- `acc==0` at first sample of the token
- BRAM `sub=0/1/2` latency

## Attempt 1 — unpatched FAIL, H1 proved

Core SHA **BEFORE** `29D230FC…12290C9E`. Log `unit_xsim_attempt1_H1_proof.log` SHA `C3C0D01B…D582D663`.

```text
CONTROL_PASS pred=744
PLANE EMB mismatches=0
FIRST_MISMATCH N1_L0 tk=1 d=0 rtl=-16 exp=-20
PLANE N1_L0 mismatches=512 first=128
TOK_TRACE t=0 nsamp=128 dup=0 acc0=1 sum=-36 or_sum=-36 mu=-1 or_mu=-1
TOK_TRACE t=1 nsamp=0 dup=0 acc0=0 sum=0 or_sum=96 mu=2147483647 or_mu=0
H1_MISS_SAMPLES tok=1 nsamp=0 want=128
… tok=2..7 nsamp=0 …
H1_PROOF tok1 never entered ST_LN_S
UNIT pred=60 oracle=549 logit0=363484 ref=1648634
LM06_LN_MU_TOKENBOUNDARY_FAIL fails=10
```

| Token | nsamp | unique 0..127 | acc0 | signed sum | fd_q / μ | vs python |
|-------|------:|---------------|------|-----------:|---------:|-----------|
| 0 | **128** | yes, dup=0 | 1 | **−36** | **−1** | bit-exact |
| 1–7 | **0** | never `ST_LN_S` | n/a | n/a | never ran | H1 |

**H1 CONFIRMED. H2 REJECTED.** Floordiv never ran for tok1–7. Tok0 `fd_q` matched `sum//128`. Root: `ST_LN_O` dim wrap with remaining tokens only did `tok_i <= tok_i + 1` and **stayed in `ST_LN_O`**, reusing tok0 μ/scale. Same schedule applies at `ten=6` n2. Not a signed-division bug.

512 N1 misses = 4 tokens whose python μ=0 (tok 1,3,4,7) plus the other three that also skipped `ST_LN_S`.

## Minimal patch (after proof only)

`rtl/lm/tiny_gpt803k_core.sv` `ST_LN_O` ~582. No law / weights / ATT / MV / HEAD / `floordiv_s48` change.

```text
-                                end else
+                                end else begin
+                                    // Per-token LN: recompute mu/var. Staying in
+                                    // ST_LN_O reuses tok0 mu (H1 token boundary).
                                     tok_i <= tok_i + 7'd1;
+                                    acc   <= 64'sd0;
+                                    sub   <= 4'd0;
+                                    st    <= ST_LN_S;
+                                end
```

Core SHA **AFTER** `75706E2C…E8EFB5FB`. Full diff: `RTL_DIFF.txt`.

## Attempt 2 — patched PASS

Log `unit_xsim.log` SHA `DAC227E9…DD981A67`. Vivado 2026.1 XSim snapshot `lnmu_s00`.

```text
CONTROL_PASS pred=744
PLANE EMB mismatches=0
PLANE N1_L0 mismatches=0
TOK_TRACE t=0 nsamp=128 dup=0 acc0=1 sum=-36 or_sum=-36 mu=-1 or_mu=-1
TOK_TRACE t=1 nsamp=128 dup=0 acc0=1 sum=96  or_sum=96  mu=0  or_mu=0
TOK_TRACE t=2 nsamp=128 dup=0 acc0=1 sum=-67 or_sum=-67 mu=-1 or_mu=-1
TOK_TRACE t=3 nsamp=128 dup=0 acc0=1 sum=102 or_sum=102 mu=0  or_mu=0
TOK_TRACE t=4 nsamp=128 dup=0 acc0=1 sum=71  or_sum=71  mu=0  or_mu=0
TOK_TRACE t=5 nsamp=128 dup=0 acc0=1 sum=-43 or_sum=-43 mu=-1 or_mu=-1
TOK_TRACE t=6 nsamp=128 dup=0 acc0=1 sum=-34 or_sum=-34 mu=-1 or_mu=-1
TOK_TRACE t=7 nsamp=128 dup=0 acc0=1 sum=40  or_sum=40  mu=0  or_mu=0
UNIT pred=549 oracle=549 logit0=1648634 ref=1648634
LM06_LN_MU_TOKENBOUNDARY_PASS fails=0
```

Consumed X on `ST_LN_S` sub=2: **0** (`FAIL consumed X` not fired; `fails=0`). Parent already showed EMB consumed-X=0.

## Acceptance

| Check | Result |
|-------|--------|
| CONTROL ntok=1 pred | **744** |
| ntok8 EMB mismatch | **0** |
| every token 128 unique samples, acc0, sum/μ bit-exact | **8/8** |
| N1_L0 mismatch | **0** |
| logit0 / pred | **1648634 / 549** |
| consumed X (LN_S) | **0** |

## Synth / resource / timing

**Not measured this gate.** SIM_FULL=1 OOC is **not silicon** (1M-word behavioral WMEM). No full-chip. Patch adds **no new FSM state, operator, memory, or divider** — only a token-boundary transition that already-existing `tok_i` / `acc` / `sub` / `st` registers take. Resource/timing delta vs parent core is therefore **not claimed**; do not treat this XSim as a QoR number.

## Preserved FAIL

| Bag | Status |
|-----|--------|
| `P2-TEACHER-OFF-SOC-XSIM-00/` | FAIL_LM_ORACLE_MISMATCH + FAIL_LM_KNOWNNESS — **not closed**, not re-run |
| `LM06-NTOK8-KNOWNNESS-DIFF-00/` | FAIL first N1 tok1 — **kept** |
| this bag attempt1 | H1_PROOF FAIL — **kept** |

G1 `2219DA29…` G2 `06143862…` G3 `2177073D…` G4 `D1BF0340…` **unchanged**.

## Verdict

**PASS_FUNCTIONAL** (core-only XSim, H1 schedule fix).  
**NOT** PASS_PHYSICAL. **NOT** Teacher-Off. **NOT** G5. XSim ≠ board. `pred=664` is a different Native-V1 existence number — do not mix with LM-06 744/549.

STOP for Codex audit. PROGRAM=NO.
