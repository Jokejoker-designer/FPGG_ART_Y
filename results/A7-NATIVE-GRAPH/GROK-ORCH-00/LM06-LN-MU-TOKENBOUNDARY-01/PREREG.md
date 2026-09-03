# LM06-LN-MU-TOKENBOUNDARY-01 — preregister (before data)

**PROGRAM=NO.** Core-only XSim. No graph / MIG / COM12 / JTAG / bit / full-chip / Gate14.  
Do not close G5. Do not run G5 regression here.

Parent: `LM06-NTOK8-KNOWNNESS-DIFF-00` — EMB exact, consumed-X=0, L0 N1 tok1 d0 RTL −16 vs ref −20, mu RTL −1 vs ref 0.

## One unknown

For ntok=8 tokens `[2,0,1,3,4,5,6,7]` on WMEM `C204E559…3001E0`, is the first LN μ mismatch **H1** (stale / missing / duplicate act sample, or skipped mean/var at token boundary — acc/BRAM latency/schedule) or **H2** (same 128-sample signed sum, wrong `floordiv_s48` numerator/quotient/timing)?

Do **not** assume H2.

## Trace (each token, L0 ten=0)

- 128 accepted `ST_LN_S` samples, `aaddr` dim 0..127
- signed `acc` immediately before `fd_go` (sum before division)
- `fd_n`, `fd_q`, latched `mu`
- `acc==0` at first sample of the token
- BRAM `sub=0/1/2` latency

## H1 vs H2

| | H1 | H2 |
|--|----|----|
| LN_S accepts tok1 | ≠128 or aaddr not 0..127 unique | =128 unique |
| sum vs python `sum(emb[t])` | mismatch | match |
| `fd_n` vs that sum | follows bad sum | match sum |
| `fd_q` vs `sum//128` | follows bad sum | mismatch |

## After proof only

Minimal LN **schedule / div handshake** in `tiny_gpt803k_core`. No law, weights, ATT, MV, HEAD changes.

## Acceptance

CONTROL ntok1 pred=744; ntok8 EMB mismatch=0; every token sum/μ/N1 bit-exact (N1 mismatch=0); logit0=1648634 pred=549; consumed X=0.

SHA before/after + RTL diff. SIM_FULL=1 OOC is not silicon; report that. No full-chip.
