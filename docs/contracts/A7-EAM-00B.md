# A7-EAM-00B — BRAM silicon proof

**Status:** BOARD_PASS 2026-08-19. `results/A7-EAM-00/ladder_00b.json` `pass:true`. Bit `build/out/arty_a7_eam00b.bit` SHA `7CBB0CFC…`. WNS +0.449 TNS 0 WHS +0.032. CFGBVS=VCCO / 3.3. Frozen LM bits unchanged.  
**Parent:** `A7-EAM-00.md` (`eam00-hamming-ema-v1`)  
**Part:** `xc7a100tcsg324-1` / Arty A7-100, 100 MHz, UART 115200  
**Bit:** `build/out/arty_a7_eam00b.bit` only. Never write `arty_a7_lm*.bit`.

## Actual silicon record width (immutable 00B)

Nominal RTL entry is 256 bits. **00B silicon is not.**

`report_ram_utilization` on `a7eam00b_post_route.dcp`:

- array `u_link/u_core/u_mem/mem` = **4096 × 171** = **700,416 bits**
- 19 × RAMB36E1 @ 4K×9; 0 RAMB18; 0 LUTRAM

00S (OOC, `out_vector` is a top port) is the full **4096 × 256** = 28×RAMB36 + 1×RAMB18.

85 bits were deleted after TDP infer (`mem_reg_8..15`, `mem_reg_27`, `mem_reg_28`) by constant-propagation because the board UART does not observe `out_vector` / `out_confidence` / `out_way`, and `flags[15:1]` / `tag[15:8]` are RTL zeros.

**EAM-01 DDR must use a declared persist width, not “00B used 32-byte rows”.**  
Full write-up: `results/A7-EAM-00/RAM_WIDTH.md`.

UART is transport. The FPGA must perform set-select, scan, popcount, winner,
hit/miss, allocate, evict, EMA and counter update. The host may send only
`key`, `context_vec`, `context_token`, `command`.

## Host must not send

way · internal BRAM address · eviction decision · precomputed match result

## UART

Host frame: `A5 cmd n payload[n] xor` (xor of preceding bytes).

| cmd | n | meaning |
|----:|--:|---------|
| `0x01` | 0 | PING |
| `0x02` | 25 | MAP — query + `auto_update=1` (learn/EMA) |
| `0x03` | 25 | PROBE — query + `auto_update=0` (recall only) |
| `0x04` | 0 | SOFT — epoch++ |
| `0x05` | 0 | CLR — zero HIT/MISS/QRY |
| `0x06` | 0 | STAT |

Payload 25 = `key[8] le` + `vec[16] le` + `token`.

FPGA reply (20 B, **no way / no BRAM addr**):

`5A kind flags token hamming cycles hit_cnt[4] miss_cnt[4] qry_cnt[4] epoch xor`

| kind | |
|------|--|
| `0x81` | PONG |
| `0x82` | RESULT |
| `0x83` | STAT/ACK |
| `0x8E` | ERR |

`flags[0]=hit`, `[1]=result`, `[2]=idle`.

## Board ladder (hard to fake)

Mappings are generated **after** the bitstream SHA is recorded (`secrets`).

1. RESET / PING / CLR  
2. 48 random MAP → 48 MISS (token = teacher on miss is allowed)  
3. 48 PROBE of the same keys with **token=0, vec=0** → 48 HIT, hamming=0, **stored** token  
4. Fill one set with 16 MAP then a 17th competing key → 17th MISS (evict)  
5. PROBE all 17 with dummy teacher → exactly 16 HIT, 17th is HIT, one original MISS  
6. Teacher disconnected: only PROBE survivors → still HIT  
7. SOFT → PROBE old survivors → MISS  
8. MAP a new key → PROBE new (dummy teacher) HIT; old still MISS  

## Config DRC

Arty A7-100 bank 0 is 3.3 V. Required (Digilent master XDC):

```tcl
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

Severity if missing: bitstream I/O-standard of bank 0 is undefined (config
pins / DCI). Not a logic bug, but must be set before program. Not ignorable
for a board bit.

## Close

`results/A7-EAM-00/ladder_00b.json` with `pass:true` and all steps true.
No MIG. No LM-07. Frozen LM bits SHA-locked.
