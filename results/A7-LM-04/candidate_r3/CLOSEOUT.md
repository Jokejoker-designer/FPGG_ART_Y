# A7-LM-04 R3 — HOLD (2026-08-18)

Frozen recipe evaluated once on HELDOUT-R3. **Do not retune.**

| | |
|--|--|
| Status | **`FAILED_CONFIRMATION_ORACLE`** — confirmation ended; not waiting |
| R2 | `VALIDATION_PASS_WITH_KNOWN_ERRATA` (immutable) |
| LM-05 | **HOLD** |
| Recipe SHA | `d1be0eee2235f30abd48788199b8eabe2b07e8b1b0d53b5d2fdc3086eb9aa7e3` |
| HELDOUT-R3 SHA | `b77c4635971cc2a8ebf2f49b629aff4704c10f42bed174fbdb70f05dc8802294` |
| n / seed / init | 128 / 41 / 17,19,23 |
| Prefixes vs R2 | disjoint |
| `heldout_used_for_tuning` | false |

## Oracle (pre-silicon, frozen recipe, once)

| Seed | last_loss | drop | acc1 | classes | Wilson LB | collapse |
|------|-----------|------|------|---------|-----------|----------|
| 17 | 2032→2048 | −0.79% | 0.0% | 0 | 0.000 | FAIL (degrade; pred 166 dominates) |
| 19 | 2048→1792 | 12.5% | 12.5% | 1 | 0.078 | FAIL (constant-class; pred 36 = 84%) |
| 23 | 2048→2016 | 1.56% | 1.6% | 1 | 0.004 | FAIL |
| median | | **1.56%** | | | | **FAIL** |

Gates not met: median CE drop ≥20%, acc >12.5%, Wilson LB >12.5%, ≥6/8 classes, no class >50%, no seed degrade.

This is why R2’s 5% gate was not scientific confirmation. The same recipe on a new balanced 128-row set and new seeds does not learn the eight k values.

## Hardware

RTL `tile_valid` / `command_id` / `tile_index` is in `tensor_microseq`. Ladder R3 has no K=513 retry.

| | |
|--|--|
| Bit | `build/out/arty_a7_lm04r3.bit` |
| SHA256 | `FAC912B3DB543C312565FAA58A457A568E091F156592E4DC82987E92FB8E0318` |
| WNS / TNS / WHS | **+0.301 / 0 / +0.024** |
| FAIL / R2 bits | unchanged |

This bit does **not** waive the quality FAIL. First-try K=513 is not yet proven on silicon (board not programmed after oracle FAIL).

## Claim rule

Do not emit `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`. A later close needs a **new** recipe and a **new** confirmation set (R4), frozen before any look, not a silent edit of R3. On this manifest `k513_first_try` is `NOT_RUN`, not a silicon fail.
