# RESULTS — U3R-ROOFLINE-REMEASURE-05

Measurement only. Canonical harness = U1 MIG_XSIM.

```text
PHYS=4 WAVE=16 N=64 bytes=1024 beats=64
T_QUERY=275  T_RUN=157  cand/cycle=0.232727
II_STEADY=40
outstanding_HW=2  AR_OVERLAP=3
```

Per-wave (U1 `P3P4_WAVEn`):

| w | C_D | C_T | C_L | C_G | t_accept |
| -: | ---: | ---: | ---: | ---: | ---: |
| 0 | 119 | 33 | 31 | 23 | 41 |
| 1 | 0 | 33 | 31 | 31 | 77 |
| 2 | 0 | 33 | 31 | 21 | 117 |
| 3 | 0 | 33 | 31 | 49 | 157 |

```text
C_D after W0     = 0  (DDR RTT hidden)
C_T_MAX          = 33
C_L_MAX          = 31
C_G_MAX          = 49 (W3 final Global; G_SORT=28)
II_STEADY        = 40 = accept gaps 36/40/40
```

**Limiter (steady):** C_T=33 TermGen fold6, not FETCH_SERVICE.

Blueprint: do **not** auto-open TermGen/full-scan microopt. Sparse retrieval is the architecture next step.

U3R = **PASS**. NEXT = U3Q-QUERY-REPRESENTATION-AUTHORITY-00.
