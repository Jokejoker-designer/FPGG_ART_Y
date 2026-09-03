# RESULTS — G14-FINAL-OBS-BIT-00 (in progress)

```text
C12_HOST_OBS_XSIM = PASS
PROGRAM           = NO
GATE14_PASS       = NO
READY_TO_PROGRAM  = NO   (unique impl SHA not yet)
```

## GUI bit warning

```text
FROZEN  1F0F2ABB…  G14-EPOCH-REBIRTH-BIT-00/*.bit   BOARD E0–E5
REFUSE  9CA2B30D…  Vivado GUI Write Bitstream in g14_epoch_rebirth_bit_00
```

Do not program `9CA2B30D`. It is not the locked SHA.

## Observability (RTL, live)

CFRAME **C12** samples:

| field | source |
|-------|--------|
| teacher_active | live OR of host_cue/winner/addr/mode |
| ext_llm_active | live OR of host_next / host_wren |
| MODE | c1_mode |
| n_host_* | glue counters incrementing on those same wires |

Poke XSim: idle all 0; `host_cue=1` → teacher=1 and n_cue++; `host_next`/`wren` → ext_llm=1. **Not a UART-hardcoded 0 page.**

Law unchanged: epoch, C9, scorer, Top-K, bind, TinyGPT, oracle.
