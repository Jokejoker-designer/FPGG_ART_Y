# LIMIT — TinyGPT cannot fit with wt+u_a on xc7a100t (BRAM)

**Gate:** `tinygpt_soc`  
**Agent:** `a7-vivado-gate`  
**Device:** Digilent Arty A7-100T `xc7a100tcsg324-1`  
**Evidence_class:** `POST_ROUTE_FIT_LIMIT`  
**board_pass:** false  

## Why LIMIT / fit FAIL (not invent)

| Blocker | Evidence |
|---------|----------|
| CONTROL UA SoC BRAM | **128 / 135** (`control_ua_util.rpt`; headroom **7**) |
| Frozen TinyGPT LM-06 BRAM | **132 / 135** (`frozen_lm06_utilization_route.rpt`) |
| Additive BRAM | **260 / 135** (overshoot **125**) — HS-11 architectural FAIL |
| DSP | UA **0** + LM-06 **154** = **154 / 240** (DSP alone would fit; BRAM does not) |
| TinyGPT on UA hier | **0 hits** (`tiny_gpt` / `mac_array` / `gemv`) |
| pe_alive | **0** (prior UART; not invented this gate) |

## What this gate claims

- UNKNOWN closed: **TinyGPT cannot be added alongside retained wt+u_a** under BRAM≤135 without a memory-consolidation redesign (new unknown).
- H_CANDIDATE (new bit with TinyGPT/DSP + pe_alive **and** wt+u_a) **falsified** by measured post-route footprints.
- H_RIVAL (invent pe_alive; claim fit without fabric; overwrite frozen) **did not fire**.
- Frozen LM-06 / 01R / 02M / A0.3 SHA **MATCH** (HS-20). CONTROL UA `4451AFD9…` **MATCH**.

## What this gate does NOT claim

- New integrated SoC bit with TinyGPT on the answer path
- HS-22 LM participation closed
- Semantic HS-02 / held-out retrieval
- `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS
- Selling additive util>device as PASS

## Non-overwrite (HS-20)

No write to `build/out/arty_a7_lm06.bit` or other frozen release bits. Archive only under `results/A7-NATIVE-GRAPH/TINYGPT-SOC/`.
