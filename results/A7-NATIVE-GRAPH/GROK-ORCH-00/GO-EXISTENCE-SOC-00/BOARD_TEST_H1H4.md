# Board window — test H1–H4 (pred=371 vs 664)

When human returns COM12: **arm UART first**, then program **one** named bit.  
AI does not stamp BOARD_PASS. Do not mix 744. Do not program LONGBOOT / pulse-stall bits as a “fix”.

Golden A-FAST (SIM_FULL=1 only): pack `3b392b291b190b09` = `[9,11,25,27,41,43,57,59]` → **pred=664**.  
Hex SHA `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F`.

Stop listen on `pred=` or 90 s after `CORE_DONE` (not a blind 600 s). If no `CORE_DONE` in ~30 s, **stall** — same class as PHASE=01.

## Order (one unknown each program)

### T0 — Repro (optional, 2 min)

Program **371 bit** `B64B2649…` (level-hold).  
- Still `pred=371` → 371 is stable silicon, not a one-shot.  
- Other pred / stall → do not treat 371 as the baseline.

### T1 — H1 (3× GO / leftover cmds)

Program **1-GO wait-busy + grant-on-miss** bit  
`arty_a7_ng_native_v1_grok_orch_grant_miss_00.bit` (when `BIT_OK`).

| UART | Meaning |
|------|---------|
| `pred=664` | H1 **supported** (3× GO was enough to move argmax). H2/H3/H4 weaker. |
| `pred=371` | H1 **not sufficient**. Go T2. |
| `PHASE=01` no pred | grant/r_path still deadlocks — not a 371-vs-664 test. |

Also record `CMD_EMPTY` / `SBUSY_PEND` after `CORE_DONE` (H1 leftover).

### T2 — H2 (pack / topk)

Need UART `PACK=` 16 hex (current SoC ties `.ctx_pack_o()`).  
Until that bit exists: **cannot close H2**.  
When printed: equal `3B392B291B190B09` → H2 false. Else 371 may be **correct** argmax of another prefix.

### T3 — H3 (flash vs hex)

Silicon `WMEM_OK` = 802816 B from QSPI `@0x40_0000`, not “matches hex”.  
On board: do **not** guess. Compare to last sealed T2-SPI/WMEM closeout SHA vs `9A6BBC7A…`. If no live hash, H3 stays **MISSING**.

### T4 — H4 (SIM_FULL=0 numerics)

**No board required.** XSim `tiny_gpt` / A-FAST-style **`SIM_FULL=0`**, 1 GO/line, same hex, same pack, print `pred`.  
- `664` → H4 false.  
- `371` → tiling path, not MIG 3× GO.

## Bits (do not mix)

| SHA / file | Role |
|------------|------|
| `B64B2649…` existence | 371 repro only |
| `125978D3…` pulse | PHASE=01 stall — **not** a 371 test |
| `157D6B73…` wait-busy | PHASE=01 stall — **not** a 371 test |
| `grant_miss_00.bit` | T1 H1 when BIT_OK |

Default when COM12 returns: **skip T0 if time-tight → T1 grant-miss**.

## Update 2026-08-30 (do not invert)

| Test | Result | Class |
|------|--------|--------|
| T1 grant-soa silicon | `pred=733` GRANT=1 CORE_DONE (bit `00517465`) | EVIDENCE — 1-GO completed; 733 ≠ 664; **do not reprogram this bit** |
| T4 H4 XSim SIM_FULL=0 | `H4_PRED=664` `pack=3b392b291b190b09` | EVIDENCE — H4 **FALSIFIED** |
| T2 H2 pack UART | was tied off; next bit `GO-H2PACK-SOC-00` | pending **BIT_OK** then named token |
| T3 H3 flash SHA | last sealed hex `9A6BBC7A…`; live 2026-08-30 hash MISSING | MISSING |

Next board program: **only** `GO-H2PACK-SOC-00` after BIT_OK. T2 first (PACK= hex). T3 only if PACK matches A-FAST.
