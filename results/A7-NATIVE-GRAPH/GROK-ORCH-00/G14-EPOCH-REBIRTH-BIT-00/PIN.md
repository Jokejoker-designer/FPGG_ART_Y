# PIN — BIT-07 fileset graft

Source worktree (hashes match BIT-07 `SOURCE_SHA.txt`):

`D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` @ `3b6622a` (P0 store; not used)

Pinned into this worktree (one unknown remains: epoch store/pkg):

| File | SHA256 |
|------|--------|
| `tiny_gpt803k_core.sv` | `75706E2C…` BIT-07 |
| `a7ng_cue_soa_mig_top.sv` | `1721C298…` BIT-07 (`PHYS=4`) |
| `a7ng_topk_wavefront_minheap.sv` | `6A651306…` BIT-07 |
| `a7ng_cue_soa_wavefront.sv` | `2F8888AD…` BIT-07 |
| `a7ng_ddr_soa_boot.sv` | `C02C8D9E…` BIT-07 |
| `a7ng_scorer_array.sv` | `DAB22200…` (`PHYS` parameter) |
| `a7ng_ng02_core.sv` | `902C085E…` |
| `a7ng_termgen_array.sv` | `5A869703…` |
| `a7ng_termgen_lane_fold6.sv` | `1A0FAFD4…` |
| `a7ng_termgen_array_fold6.sv` | `E2D8CF2D…` |

**Not** pinned (the unknown):

- `a7ng_pkg.sv` epoch helpers
- `a7ng_learned_prior_store.sv` epoch REBIRTH
- `a7ng_persist_gen_fast.sv` same cookie law (not in C9 SoC fileset)

PROGRAM=NO.
