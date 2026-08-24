# A7-EAM-00 — BRAM Episodic Associative Memory

**Status:** 00S PASS + 00B BOARD_PASS (research branch; LM-07 not started)  
**Opened:** 2026-08-19 after LM-06 BOARD_PASS  
**Authority:** `Episodic Associative Machine.md`  
**law_id:** `eam00-hamming-ema-v1`  
**Device target:** XC7A100T, 100 MHz core, 1.8 V I/O (board later)  
**Do not:** overwrite LM-00…06 frozen bits; instantiate MIG; claim LM-07.

H1 from the paper: a 4096-entry BRAM table can learn and recall random key→token mappings. This contract is hardware+xsim only. DDR (A7-EAM-01) is out of scope.

## Frozen geometry

```text
Sets S              256     key[7:0]
Ways W               16
Entries           4096
Entry             256 bits / 32 B  (RTL nominal)
                  00S silicon: 4096×256 (28×RAMB36+1×RAMB18)
                  00B/00G silicon: 4096×171 (19×RAMB36) — vec mostly DCE'd
                  See results/A7-EAM-00/RAM_WIDTH.md before EAM-01 DDR.
Key                 64 bit (full, not a truncated fingerprint)
Value vector       128 bit (16 × INT8)
Token                8 bit
Confidence           8 bit
Age                 16 bit
Tag                 16 bit (epoch in [7:0])
Flags               16 bit ([0]=valid)
Hit rule            valid && (hamming <= HIT_MAX)   default HIT_MAX=0 (exact)
Miss allocate       first invalid way, else lowest conf (tie: highest age)
EMA                 v += asr(ctx - v, EMA_SHIFT)    default SHIFT=2
Controller          32 × INT8 state, merge 16-B vector on each result
Clock               100 MHz
Reset               rst_n active-low (project convention)
```

Address: `{set[7:0], way[3:0]}`.

## Packed entry (little-endian fields, MSB first in the 256-bit word)

| Bits | Field |
|------|--------|
| [63:0] | key |
| [191:64] | value vector |
| [199:192] | token |
| [207:200] | confidence |
| [223:208] | age |
| [239:224] | tag (epoch) |
| [255:240] | flags |

## Native query / update ports (`a7eam00_top`)

| Signal | Dir | Width | Meaning |
|--------|-----|------:|---------|
| `clk` | in | 1 | 100 MHz |
| `rst_n` | in | 1 | async-release sync-use, **active-low** |
| `query_key` | in | 64 | latched on `query_start` |
| `query_start` | in | 1 | 1-cycle pulse, ignored if `!idle` |
| `context_vec` | in | 128 | 16×INT8 current context (EMA / miss fill) |
| `context_token` | in | 8 | token written on miss; also teacher on first learn |
| `idle` | out | 1 | accepts a new `query_start` |
| `busy` | out | 1 | `!idle` |
| `result_valid` | out | 1 | 1-cycle pulse; `out_*` held until next start |
| `hit` | out | 1 | valid entry with hamming ≤ HIT_MAX |
| `out_token` | out | 8 | stored token on hit; `context_token` on miss |
| `out_vector` | out | 128 | stored vector **before** EMA on hit; context on miss |
| `out_confidence` | out | 8 | stored / 0 on miss |
| `out_way` | out | 4 | selected or victim way |
| `out_hamming` | out | 7 | best distance (64 if set empty) |
| `ctrl_state` | out | 256 | 32×INT8 recurrent state |
| `ctrl_energy` | out | 16 | INT16 sum of state[0:15] |
| `ctrl_token` | out | 8 | `out_token` on hit, else `state[0]` |

After `result_valid` the core writes (hit: EMA+conf+age; miss: new record) unless `auto_update=0`.

Budget: ~18–22 cycles/query (8 dual-port reads + XOR/pop/fold pipe + winner refetch + write). 00S closed at 100 MHz (WNS +0.800).

## AXI4-Lite slave (32-bit, 8-bit addr)

Standard `s_axil_*` (AW/W/B/AR/R). `AWPROT`/`ARPROT` ignored. `BRESP`/`RRESP` OKAY. Word-aligned.

| Off | Name | Access | Notes |
|----:|------|--------|-------|
| 0x00 | CTRL | W1P | [0] soft reset (epoch++), [1] clear counters, [2] dbg_fetch |
| 0x04 | STATUS | R | [0] idle [1] busy [15:8] last dist [23:16] last way [31] last hit |
| 0x08 | HIT_CNT | R | |
| 0x0C | MISS_CNT | R | |
| 0x10 | QRY_CNT | R | |
| 0x14 | CFG | RW | [7:0] HIT_MAX [11:8] EMA_SHIFT [16] AUTO_UPDATE (1 default) |
| 0x18 | KEY_LO | RW | |
| 0x1C | KEY_HI | RW | |
| 0x20 | DOORBELL | W1P | start query from KEY_*/CTX_* |
| 0x24–0x30 | CTX0–3 | RW | context vector bytes 0–15 |
| 0x34 | CTX_TOKEN | RW | |
| 0x38 | DBG_INDEX | RW | [11:0] `{set,way}` |
| 0x3C | DBG_WSEL | RW | word 0–7 of latched entry |
| 0x40 | DBG_RDATA | R | after CTRL.dbg_fetch |
| 0x44 | DBG_WDATA | RW | write word into latch; CTRL[3] dbg_commit writes BRAM |

## Assumptions

1. BRAM is **inferred** TDP `(* ram_style="block" *)` 256-bit × 4096. Vivado maps to RAMB36. No instantiated `RAMB36E1` primitive (portable xsim).
2. Port A + port B both read during scan (2 ways/cycle). Port B writes during update. AXI debug only when `idle`.
3. `rst_n` **active-low**. Soft reset increments 8-bit epoch in `tag[7:0]`; old valids miss. Epoch wrap (256) is not auto-scrubbed (document; rare).
4. Hamming hit default **exact** (`HIT_MAX=0`) so H1 recall is well-defined.
5. 32-D controller does **not** implement a full vocab softmax. It merges the 16-B value into `state[0:15]` and exposes `ctrl_energy` / `ctrl_token` for later LM glue.
6. 1.8 V is an I/O-bank constraint for a future board wrap, not an RTL parameter.
7. A7-EAM-01 (DDR) is forbidden until this xsim (and later board) recall gate passes.

## xsim close for this slice

`A7EAM00_XSIM_PASS`: learn N random maps (miss then hit), token match, eviction of lowest-conf in a full set, AXI HIT_CNT/MISS_CNT consistent.

## Files

```text
rtl/eam/a7eam00_pkg.sv
rtl/eam/eam_tdp256.sv
rtl/eam/eam_core.sv
rtl/eam/eam_controller.sv
rtl/eam/eam_axil.sv
rtl/eam/a7eam00_top.sv
tests/xsim/tb_a7eam00.sv
tests/xsim/run_a7eam00.tcl
```
