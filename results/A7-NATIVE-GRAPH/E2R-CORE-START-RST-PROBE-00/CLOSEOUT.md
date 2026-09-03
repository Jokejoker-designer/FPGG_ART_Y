# E2R-CORE-START-RST-PROBE-00 CLOSEOUT

**GATE14_PASS = NO. BOARD_PASS = NO. EXISTENCE_PASS = NO.**

## Bit

| Item | Value |
|------|-------|
| Vivado | 2026.1 (SW 6511674) |
| GIT_HEAD | `cd8c41c` + dirty probe patch on `arty_a7_ng_native_v1_ab_soc_top.sv` |
| UART_SLIM | **0** (synth generic) |
| BIT_SHA256 | `7ECCA0E21BF27DD13451F3EFB4F180A7B15627B610D81BECAE07CA9FFA12E219` |
| Forbidden parent | not `A0B338E0` |
| WNS | 0.651 ns |
| TNS | 0 |
| WHS | 0.010 ns |
| THS | 0 |
| core_WNS / core_TNS | 44.611 / 0 |
| ui_WNS / ui_TNS | 2.019 / 0 |
| RAMB36 | 104 |
| DSP | 19 |
| CDC parser `unsafe` | 5, all **User Ignored** (3 MIG false-path + 2 async-group). `core_clk→sys_clk_pin` = 252 safe / 0 unsafe. Timing: all user constraints met. |
| JTAG | `210319BE776EA` |
| UART | COM12 @115200 |
| PROGRAM | **once** `CORE_START_RST_PROBE_BIT_PROGRAM_PASS` |
| Second program | **NO** |

## Capture (DONE boundary)

| Item | Value |
|------|-------|
| `uart_raw.bin` SHA256 | *(see file hash recorded in RESULTS)* |
| bytes_total | 732 |
| bytes_before_done | **0** |
| bytes_after_done | 732 |
| BOOT count | **1** |
| Duration after DONE | 180 s |
| Log edited | **NO** |

## Discriminators (post-DONE, this bit)

| Check | Result |
|-------|--------|
| Second BOOT | **NO** |
| `n` | 01 (first lock only) |
| `RST_CAUSE` | 0 POR |
| `f` | 00 |
| `CLK_ALIVE` | 1 |
| UART `CORE_START` | YES |
| UART `Q_GO` / `OWNER_RDY` / `CORE_DONE` | YES |
| `START_SEEN` / `RST_REL` at print | 0 / 0 — **printed after BOOT before MIG** (`hb_next` fall-through). Not Case 2/4. `Q_GO` proves `start_q` later. |

## Classification

**Not A** (not stuck after CORE_START). **Not B** (no boot-domain restart on this bit in 180 s).

Primary class: `INCONCLUSIVE` for the *archived* TILE-DMA BOOT×2 root. Live A/B on `7ECCA0E2`: **neither**.

Verdict: `FAILURE MOVED DOWNSTREAM` (observed `pred=249`; law / scorer / TopK / LM not opened).
