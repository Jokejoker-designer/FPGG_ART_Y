# LIMIT — TinyGPT still ABSENT on consol CONTROL (xc7a100t)

**Gate:** `tinygpt_consol`  
**Agent:** `a7-vivado-gate`  
**Device:** Digilent Arty A7-100T `xc7a100tcsg324-1`  
**Evidence_class:** `POST_ROUTE_FIT_LIMIT`  
**board_pass:** false  
**hs22_closed:** false  

## Why LIMIT / fit FAIL (not invent)

| Blocker | Evidence |
|---------|----------|
| CONTROL consol TinyGPT hier | **0** hits (`tiny_gpt` / `mac_array` / `gemv` / `pe_alive`) |
| CONTROL consol DSP | **0 / 240** (`control_consol_util.rpt`) |
| CONTROL consol BRAM | **132 / 135** (headroom **3** — cannot ADD TinyGPT weight bank) |
| Frozen TinyGPT LM-06 BRAM/DSP | **132 / 154** (standalone footprint CONTROL) |
| Naive additive consol+TinyGPT BRAM | **264 / 135** (overshoot **129**) — HS-11 FAIL if stacked without share |
| Co-fit projection | 132≤135 = prior BRAM-CONSOL ENGINEERING_INFERENCE only — **not** TinyGPT fabric |
| New TinyGPT+consol SoC bit | **null** |
| pe_alive | **0** (not invented) |

## What this gate claims

- UNKNOWN closed: **TinyGPT/DSP answer path is not instantiated on consol CONTROL**; H_CANDIDATE new bit **absent**.
- Selling consol capacity proxy as TinyGPT = H_RIVAL — **refused**.
- Frozen LM-06 / 01R / 02M / A0.3 / UA / mig SHA **MATCH** (HS-20). CONTROL consol `83A438B5…` **MATCH**.

## What this gate does NOT claim

- New integrated SoC bit with TinyGPT on the answer path
- HS-22 LM participation closed
- Co-fit projection as measured TinyGPT+consol P&R
- `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS

## Non-overwrite (HS-20)

No write to `build/out/arty_a7_lm06.bit` or other frozen release bits. Archive only under `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/`.
