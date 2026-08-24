# Fit finding — ng06_epoch vivado VERIFY (late)

**Agent:** a7-vivado-gate (`6e339875-aa87-4bad-899f-6e052fe0898c`)  
**Gate:** `ng06_epoch` already DONE_ENG — this closes `verify.vivado=PASS` only.

## FACT

| Leaf | LUT | FF | DSP |
|------|----:|---:|----:|
| wide_dispatch OOC | 1579 | 152 | 0 |
| ctx_prune | 35 | 74 | 0 |
| multi_agent_share | **522451** | 36121 | 0 |

Share OOC ≈ **824%** of xc7a100t LUT budget — **not** a VERIFY_ONLY fail; file under later `integrate_fit` / HS-11.

Frozen 01R/02M/LM-06/A0.3 MATCH. SILICON_DEFERRED. No BOARD_PASS.

Active OPEN remains `bram_wm_00` (do not reopen epoch).
