# NG-06R-EPOCH closeout (XSim engineering)

**Gate:** `ng06_epoch`  
**Agent:** `a7-ng-scientific`  
**Evidence class:** XSIM (not BOARD)  
**Marker:** `NG06R_EPOCH_ENGINEERING_PASS`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | wide-dispatch DONE_ENG; delayed events can apply stale work |
| UNKNOWN | does query/path epoch + DROP_STALE stop stale expand without permanent semantic kill? |
| H_CANDIDATE | H-epoch — mismatch drop sufficient for query-scoped prune |
| H_RIVAL | silent kill of live paths / wipe unrelated priors (HS-07) |
| FALSIFIER | DROP_STALE==0 under mixed-epoch OR priors wiped OR permanent ctx kill |
| UNIT | mixed-epoch query/seed bags (not 100k cycles as 100k queries) |
| CONTROL | matched-epoch share regress; no N_WAY law change |
| METRICS | DROP_STALE, alive contexts, prior_ok, node_alive |

## Verdict

H-epoch **supported** under XSim bags. H_RIVAL **falsified** for this unknown (alive=256, prior_ok=1, node_alive=1, DROP_STALE≫0).

## Results (FACT / XSim)

| Bag | Horizon | DROP_STALE | Notes |
|-----|---------|------------|-------|
| share seed0 `0xE06A701` | 100000 | 396171 | grants=204167 alive=256 prior_ok=1 bumps=48 |
| share seed1 `0xE06A711` | 100000 | 396545 | grants=204353 alive=256 |
| share seed2 `0xE06A721` | 100000 | 395506 | grants=203879 alive=256 |
| prune seed0 `0xE06B702` | 100000 | 50026 | bombs=25166 node_alive=1 |
| prune seed1 `0xE06B712` | 100000 | 49855 | bombs=25178 node_alive=1 |
| prune unit | short | — | `A7NG04_PRUNE_PASS` |
| share matched | short | 0 | `A7NG06_SHARE_XSIM_PASS` multi=1 |

## SHA256

See `SHA256.txt`. Share RTL: `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6`.

Prior wide control SHA `4C604278…` is **superseded** by epoch-port share (expected interface change). Matched-epoch behavior regresses clean.

## Out of scope (not implemented)

TermGen, BRAM-WM, reset_00 scrub FSM, integrate_fit, more PEs, TRAIN-V2, HNSW, BOARD_PASS, frozen 01R/02M/LM-06/A0.3 overwrite.
