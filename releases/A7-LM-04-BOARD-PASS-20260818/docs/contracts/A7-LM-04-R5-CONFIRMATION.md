# A7-LM-04 R5 — preregistered confirmation

**Status:** **`BOARD_PASS / FROZEN` — one-shot oracle and silicon confirmation PASS**  
**Frozen:** 2026-08-18, before oracle and board evaluation  
**Authority:** `docs/contracts/A7-LM-04.md` R5 revision  
**law_id:** `lm05-signsgd-v1` — unchanged  
**Geometry:** V=256, C=32, d=64, H=4, L=2, d_ff=128, P=100,352 — unchanged

## Scope

R5 tests counterfactual target-switch online adaptation. From the same initial checkpoint, independent runs train toward target tokens 48, 80, 112 and 144. TRAIN and HELDOUT prefixes are disjoint. The FPGA must compute every forward, loss, gradient and weight update.

This confirmation does not claim 8-way contextual retrieval, conversation or open-domain language modeling. R3 and R4 remain immutable negative results for the retrieval task.

## Frozen recipe

```text
init seeds:       47, 59, 67
targets:          48, 80, 112, 144
TRAIN prefixes:   n=16, seed=1101
HELDOUT prefixes: n=64, seed=1103
training:         one full opcode-0x34 update per TRAIN prefix
epochs:           1
lr:               3
early stop:       forbidden
retry:            forbidden
```

| Artifact | SHA-256 |
|---|---|
| `results/A7-LM-04/candidate_r5/preregister.json` | `28073459cac369e0fbc73a7b93ca1d79a983e2cdf481b57b76cbb532f0a595a2` |
| recipe | `79546f5cbd81b878879fc18a4b0cb551cae918497928090eaf0a4d35526ac5e9` |
| TRAIN prefixes | `17e18696d0186a8e02c4079a8515007d894339afb99d87e6407989b87a5e8e7c` |
| HELDOUT prefixes | `ed7796a7516b03da11411ecd901d3f8145c68d7e001f0035a817489ad4497ad9` |

## Conjunctive quality gates

- all 12 seed/target runs complete without retry;
- held-out accuracy >=90% in every run;
- Wilson 95% lower bound >=80% in every run;
- dominant held-out prediction equals the requested target in every run;
- median held-out CE reduction >=90%;
- four distinct final weight SHA-256 values for the four targets under each init seed;
- confirmation data is not used for tuning.

## Hardware gates retained

- frozen LM-00/01/02/03 bitstream SHA values and `mig.prj` unchanged;
- multi-token forward exact against the Python oracle;
- one-full update fold exact and different from head-only;
- DDR flush/reload fold exact;
- AFTER produces zero writes;
- K257→K511→K513 executes once each in one program, first fold exact;
- DMA underflow, bank hazard, AXI RRESP and AXI BRESP counters all zero;
- requant positive saturation, negative saturation and non-saturation counts exact;
- WNS >=0 and TNS=0.

Only a manifest with every gate true may close LM-04. Until then the claim remains HOLD.

## Frozen result — 2026-08-18

The preregistered oracle was evaluated once and passed. The board ladder was then run once on the frozen R5 bit and every conjunctive gate passed.

| Result | Value |
|---|---|
| bitstream | `build/out/arty_a7_lm04r5.bit` |
| bit SHA-256 | `A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8` |
| WNS / TNS / WHS | `+0.157 / 0 / +0.030 ns` |
| K257 → K511 → K513 | one issue each; first fold exact; no retry/reprogram |
| multi-token spot | `[20,7]`, target 16: pred 140, loss 16, zero writes; exact |
| quality runs | 12/12 exact against the frozen oracle |
| median held-out CE drop | 100% |
| worst accuracy | 98.4375% |
| worst Wilson 95% lower bound | 91.6659% |
| target-specific final state | distinct board folds and oracle SHA values for all targets per seed |
| board manifest | `results/A7-LM-04/candidate_r5/board/MANIFEST.json` SHA `49B5503625A54BC5170A8053EBD52B36B1360C9F3262DFB8F790551F532A68C5` |

Granted claim: `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`, limited to the scope above. R3/R4 remain immutable negative results for 8-way contextual retrieval. R5 does not meet the separate WNS ≥ +0.20 timing condition for LM-05 authorization.
