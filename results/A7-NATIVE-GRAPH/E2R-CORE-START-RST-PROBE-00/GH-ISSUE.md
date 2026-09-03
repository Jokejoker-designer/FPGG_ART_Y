## Summary

Determine whether a second UART `BOOT` in one capture is boot-domain reset/restart (**B**) or hang after `CORE_START` (**A**).

**Do not retarget the oracle. Do not auto-reprogram. GATE14_PASS / BOARD_PASS / EXISTENCE_PASS are not claimed.**

Follow-on from C9 silicon HOLD_A 748: https://github.com/Jokejoker-designer/FPGG_ART_Y/issues/1

## Audit branch

- Branch: `codex-audit/e2r-core-start-rst-probe-00`
- Repo: https://github.com/Jokejoker-designer/FPGG_ART_Y

## Unique bit (programmed once)

SHA `7ECCA0E21BF27DD13451F3EFB4F180A7B15627B610D81BECAE07CA9FFA12E219`

- UART_SLIM=0
- Vivado 2026.1
- WNS 0.651 TNS 0
- Not `A0B338E0`
- JTAG `210319BE776EA` COM12 @115200
- **One** program. Second program = NO.

## DONE-boundary capture

`uart_raw.bin` SHA `7EAB12E74E3E9B8C1CF3F2A4331413A65FFA4E0C0518FFC182C7C3E4290462BC`

| Item | Value |
|------|-------|
| bytes_total | 732 |
| bytes_before_done | **0** |
| BOOT count | **1** |
| Hold after DONE | 180 s |
| Log edited | NO |

Post-DONE markers: `CLK_ALIVE=1`, `RST_CAUSE=0 n=01 f=00`, then `CORE_START` `OWNER_RDY` `Q_GO` … `PHASE=07` `CORE_DONE` `pred=249`.

`RST_REL=0` / `START_SEEN=0` printed **after BOOT before MIG** (`hb_next` fall-through). Not Case 2/4. `Q_GO` proves START consumed.

## Classification

| Rank | This bit after DONE |
|------|---------------------|
| 1 lock / boot-domain restart | closed — did not happen |
| 2 START not in core | closed — `Q_GO` |
| 3 core clock / reset release | closed |
| 4 owner/query FSM | closed — `CORE_DONE` |
| 5–6 TopK / bind / LM | **not opened** |

**Not A. Not B on `7ECCA0E2`.** Archived TILE-DMA BOOT×2 was a **different bit**.

Primary class: `INCONCLUSIVE` for the archive reboot root.

Verdict: `FAILURE MOVED DOWNSTREAM` (`pred=249` observed only).

## Hard stops

- No oracle retarget
- No scorer / minheap / TinyGPT / bind / TopK / LM law change
- No A0B338E0 reuse
- PROGRAM=NO until a new unique SHA is authorized
