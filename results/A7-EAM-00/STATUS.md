# A7-EAM-00 / 00S / 00B status

**00S CLOSED**. **00B BOARD_PASS**. **00G** development sweep (not a close).  
LM-07 not started. Frozen LM bits SHA-locked. EAM bits: `arty_a7_eam00b.bit`, `arty_a7_eam00g.bit`.

| Object | Status |
|--------|--------|
| 00S | PASS `gates_00s.json` WNS +0.800 (OOC) |
| 00B bit | `build/out/arty_a7_eam00b.bit` SHA `7CBB0CFCC9F3A05D7EF2993AF3F7283CD63508D0C1806A3074560B511E292C8D` |
| 00B timing | WNS **+0.449** TNS **0** WHS **+0.032** @ 100 MHz |
| CFGBVS | **VCCO / 3.3** — DRC report 0 checks (warning gone) |
| 00B ladder | **PASS** `ladder_00b.json` all 17 steps true |
| Frozen LM | 00–06 + 06c3 SHA match after program |

## 00B ladder (host sends only key/vec/token/cmd)

Mappings drawn with `secrets` **after** bit SHA.

| Step | Result |
|------|--------|
| PING / CLR | true |
| 48 MAP → MISS | true |
| 48 PROBE dummy teacher → HIT, token match, hamming=0 | true |
| fill 16 + 17th evict MISS | true |
| 16 survive, 17th HIT, one original gone | true |
| teacher disconnect recall | true |
| SOFT → old unavailable | true |
| new MAP + recall; old still gone | true |

## Record width (before calling 00B immutable)

| | Width | BRAM |
|--|------:|------|
| RTL nominal | 256 b | — |
| 00S OOC | **256** | 28×36 + 1×18 |
| 00B/00G board | **171** | 19×36 |

00B UART never loads `out_vector`. Synth infers 4K×256 then deletes 85 bits. Token/key/evict/epoch remain. **Do not treat 00B as a 32-byte store.** Detail: `RAM_WIDTH.md`.

## CFGBVS note

Missing `CFGBVS`/`CONFIG_VOLTAGE` is a **bitstream/bank-0 I/O** warning, not core logic. Arty A7-100 is 3.3 V → `CFGBVS VCCO` + `CONFIG_VOLTAGE 3.3` (Digilent master XDC). Set in `arty_a7_100.xdc` + `a7eam00b.xdc`. `write_bitstream` DRC: 0 errors, 0 CWs. Do not ignore on a board bit.

## 00G predev (not a close)

Silicon sweep n=256, HIT_MAX×{0,1,2,4,8}, flips {0,1,2,4,8} × {any,tag,set} + unrelated.  
FPGA `best_d` == twin, 0 disagree.

| Probe | T=8 TP | T=8 FP | best | margin | collision |
|-------|--------|--------|------|--------|-----------|
| exact | 1.00 | — | 0 | 41 | 0 |
| tag 8-flip (same set) | 1.00 | — | 8 | 33 | 0 |
| any 8-flip | 0.30 | — | 31 | 20 | 0 |
| set 1-flip (wrong bucket) | 0.00 | — | 41 | 14 | 0 |
| unrelated | — | **0.00** | 39 | 16 | 0 |

Reject of strangers at T≤8 is excellent at this density. Recall of A′ only if A′ stays in `key[7:0]`. That is why this Hamming+set metric is not a reason to jump to 256 MB DDR.

## Native boundary

FPGA does set-select, scan, popcount, winner, hit/miss, allocate, evict, EMA, counters. Reply has no way / no BRAM address.
