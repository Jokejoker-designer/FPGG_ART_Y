# RESULTS — G14-SCALE-800K-00

```text
RTL_EDIT   = NO
BIT_BUILD  = NO
PROGRAM    = NO
GATE14_PASS = NO
```

Two paths. Do not mix them.

## Path C9 (Gate14 exam)

| N | cands/query | DDR bytes/query | latency/query | full_scan? |
|--:|--:|--:|--:|--|
| 32 (DEPTH) | 8 | 0 AXI (exam) | not SOA | **NO** |

Cannot host 800k records. `DEPTH=32`. K=8 minheap.

## Path SOA (`u_soa` existence query)

Measured:

| N | cands/query | DDR bytes/query | latency (elig cyc) | full_scan? | class |
|--:|--:|--:|--:|--|--|
| 64 | 64 | 1024 | 1699 | **YES** | MIG_XSIM MEASURE-01 |
| 256 | 256 | 4096 | 3629 | **YES** | MIG_XSIM this gate |

`bytes = 16 × N`. `cands = N`. Linear.

Extrapolated (16×N, cands=N). **Not run.** Label EXTRAPOLATED:

| N | cands/query | DDR bytes/query | latency/query | full_scan? | class |
|--:|--:|--:|--:|--|--|
| 4096 | 4096 | 65,536 | ~42k cyc* | YES | EXTRAPOLATED |
| 16384 | 16384 | 262,144 | ~166k cyc* | YES | EXTRAPOLATED |
| 65536 | 65536 | 1,048,576 | ~660k cyc* | YES | EXTRAPOLATED |
| 262144 | 262144 | 4,194,304 | ~2.6M cyc* | YES | EXTRAPOLATED |
| **800000** | **800000** | **12,800,000** | **~8.0M cyc*** | **YES** | EXTRAPOLATED |

\*lat(N) ≈ 1056 + 10.05×N from {64→1699, 256→3629}. Not a BOARD number.

N=256 artifact SHA256: `4F6EDA24EC0A2F025C232D24BBB85D0D53A4072BC5F65D931BEF9D75E83E7F7E`

```text
SCALE_CANDS_PER_QUERY=256
SCALE_BYTES_PER_QUERY=4096
SCALE_LATENCY_CYCLES=3629
SCALE_FULL_SCAN=YES_16B_TIMES_N
```

## HS-13

SOA as an 800k knowledge store **touches 800k records/query**. That is a linear scan.

```text
HS13_SOA_800K = FAIL
```

C9 K=8 is bounded but is **not** an 800k store.

## M10

User rule: PASS only if 800k cands stay bounded. They do **not** on SOA.

```text
M10_800K_EXECUTED     = NO
M10_CANDS_BOUNDED     = NO  (SOA cands = N)
M10_BOX_TICK          = OPEN
M10_SILENT_NA         = REFUSED
```

800k not simulated. Report exists as EXTRAPOLATED full-scan. That is not a sparse-retrieval PASS.
