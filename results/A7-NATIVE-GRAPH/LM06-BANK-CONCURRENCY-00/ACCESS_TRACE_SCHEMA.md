# ACCESS_TRACE_SCHEMA — LM06-BANK-CONCURRENCY-00

## Evidence classes

| Class | Meaning |
|-------|---------|
| `POST_ROUTE_DCP` | Frozen `a7lm06_post_route.dcp` SHA `CE6A6AD7…6022` |
| `RTL_STATIC` | Ports/FSM from frozen `rtl/lm/*`, `rtl/memory/tile_*` |
| `LM06_XSIM_RESEARCH` | Research TB under `results/.../LM06-BANK-CONCURRENCY-00/` — **does not** modify `tests/` or `rtl/` |
| `ENGINEERING_STRESS_ONLY` | Synthetic stress (not used as PASS evidence) |

## Record fields (cycle metadata)

```text
cycle
phase / FSM state (st)
logical_bank_id
port          # A|B|CH[i]|SNAP
op            # RD|WR|RDWR
enable
address
slice_mask    # optional; default FULL_WIDTH
```

Payload dumps are **out of scope** unless debugging a specific collision.

## Research TB behavior

File: `tb_lm06_bank_concurrency_research.sv`

- Instantiates `tiny_gpt803k_core #(.SIM_FULL(1))`
- Replays frozen hex/expected from `tests/xsim/` (cwd)
- **FWD only** (subset of frozen verification; train/corpus omitted to bound runtime)
- Aggregates into `BANK_ACCESS_TRACE_SUMMARY.txt` (not full cycle journal)

### Caveat (FACT label in RESULTS)

`SIM_FULL=1` uses flat `weight_bram803k`, **not** silicon `TILE.u_bank`.  
Act/snap dual-port FSM concurrency is still law-faithful.  
Weight **physical** tile concurrency for silicon must use `RTL_STATIC` + DCP, not this SIM_FULL array.

## Board tensor path

`tile_weight_pingpong` / `tile_activation` are **not** exercised by `tb_a7lm06_core`.  
Their concurrency is `RTL_STATIC` only in this gate.
