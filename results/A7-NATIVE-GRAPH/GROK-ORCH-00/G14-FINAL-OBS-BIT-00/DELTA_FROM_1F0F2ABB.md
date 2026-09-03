# DELTA vs frozen bit 1F0F2ABB fileset

```text
SOURCE_COMMIT = 29596ac03be7828078e5379d935d7baf81187ede
TOP           = arty_a7_ng_native_v1_ab_soc_top
PART          = xc7a100tcsg324-1
SIM_FULL      = 0
PHYS          = 4
```

| File | vs 1F0F2ABB SOURCE_SHA | Class |
|------|------------------------|-------|
| TinyGPT | IDENTICAL 75706E2C | frozen |
| BIND | IDENTICAL C5F57AD1 | frozen |
| STORE | IDENTICAL BE987C43 | frozen epoch |
| LPG | IDENTICAL A3B8B77C | frozen |
| CUE/HEAP/WF/BOOT/G1/G2/G3/CDC/DMA/TILE | IDENTICAL | frozen |
| GLUE | OBS_DELTA | teacher_active / ext_llm_active live |
| COFIT | OBS_DELTA | export those ports |
| ABCORE | OBS_DELTA | n_host_* no longer tied off |
| TOP | OBS_DELTA | C12 wires into sched |
| CFRAME_SCHED | OBS_DELTA | C12 dump C0–C12 |

No epoch / C9 / scorer / Top-K / TinyGPT / WDMA / DDR-key / oracle change.
