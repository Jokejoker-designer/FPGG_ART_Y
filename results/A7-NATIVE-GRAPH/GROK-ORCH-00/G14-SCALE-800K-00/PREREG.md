# PREREG — G14-SCALE-800K-00

```text
UNKNOWN     = As N grows 256 → 800k, are candidates/query and DDR bytes/query
              bounded, or do they track N (full scan)?
H_CANDIDATE = C9 path stays K=8; SOA path (if used as the 800k store) fetches all N.
H_RIVAL     = a hidden sparse index already bounds cands independent of N.
FALSIFIER   = RTL edit; bit; program; invent 800k BOARD numbers;
              close M10 while cands/query ≈ N; silent N/A.
UNIT        = one query at a declared N
CONTROL     = N=64 MIG_XSIM already: cands=64, bytes=1024, full_scan=YES
LADDER      = 256, 4096, 16384, 65536, 262144, 800000
```

PASS M10 only if 800k cands/query stay **bounded** (not ~linear in N).
If the query must touch ~800k records, **HS-13 FAIL** for retrieval.

```text
RTL_EDIT = NO
BIT      = NO
PROGRAM  = NO
```
