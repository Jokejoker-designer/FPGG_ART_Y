# PREREG — G14-FINAL-OBS-BIT-00

```text
UNKNOWN     = Can UART C12 report live teacher/ext_llm/n_host_* (not hardcoded 0) so HS-02 OPEN_BOARD can close on one unique bit?
ROOT CAUSE  = n_host_* were computed then tied off at ab_core; UART never sampled them
FALSIFIER   = poke host_cue_i → C12 n_cue stays 0; or UART C12 is constant 0 independent of host_* wires
EXPECTED    = poke increments n_host; silicon exam C12 all zero because host ports are live-tied 0
REGRESSION  = frozen oracle 653/689/237/60; no scorer/TopK/TinyGPT/epoch/WDMA/key/sdig change
PROGRAM     = NO until unique SHA != 1F0F2ABB and != 9CA2B30D
```

Refuse GUI regenerate:

```text
9CA2B30DCCD8A7AA2F348C3C4E2BDFCDAF9A9A67CBE0956EB0A8EBB532BADC80
build/.../arty_a7_ng_native_v1_ab_soc_top.bit
```

Frozen BOARD evidence remains `1F0F2ABB`. Do not program either until this obs bit is unique and authorized.
