# A7-EAM-03E-A0 xsim

**Verdict:** `A7EAM03EA0_XSIM_PASS`  
**Law:** `eam03e-a0-signsgd-v1`  
**DUT:** `eam03e_core` only. No 01R, no 02M, no LM-06.

| Phase | d1(ALPHA,BETA) | d1(ALPHA,OMEGA) |
|-------|----------------:|----------------:|
| After train (BETA=SAME) | **1093** | **2012** |
| After RESEED | 3930 | (erased) |
| After swap (OMEGA=SAME) | 1574 | **451** |

SAME shrinks vs its train partner; DIFF stays larger; reset wipes; swapped labels invert geometry.

Not claimed: unseen paraphrase, 01R retrieval, `dH < 8`.
