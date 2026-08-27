# E2R F1w EXCL — STOP: other vivado.exe

**Sealed:** 2026-08-27
**Do not program. Do not start a second exclusive writer while the resume PID is live.**

## Exclusive attempt (this gate)

| Item | Value |
|------|-------|
| Writer | `vivado.exe` PID **207056** |
| Start | 2026-08-27 09:12:13 +07 |
| Death | 2026-08-27 09:22:25 +07 exit `4294967295` |
| Cause | Force-killed by sibling terminal `972633` (`KILL leftover PID=207056`) |
| TCL | `vivado/tcl/build_e2r_uart_mgo_hb_fix_00_excl.tcl` |
| Build dir | `build/e2r_uart_mgo_hb_fix_00_f1w_excl/` (xpr only; no DCP/bit) |
| Synth | killed during Technology Mapping |
| Bit | ABSENT |

Also killed in the same sweep: 122116, 199484, 209204, 207344 (synth helper children).

## Live competing writer (HARD STOP)

| Item | Value |
|------|-------|
| PID | **198988** |
| Parent | 209256 |
| Start | 2026-08-27 09:22:27 +07 |
| Command | `vivado -mode batch -notrace -source ...\build_e2r_uart_mgo_hb_fix_00_resume.tcl` |
| Outdir | `results/A7-NATIVE-GRAPH/E2R-UART-MGO-HB-FIX-00/` (**CONCURRENT_BUILD_INVALID**) |
| DCP source | concurrent `e2r_post_synth.dcp` |

Authority `E2R_F1W_CONCURRENT_BUILD_INVALID.md`: do **not** program any bit from that folder or `build/e2r_uart_mgo_hb_fix_00_f1w/`.

## RTL verify (pre-kill; still valid)

SOC_TOP_SHA256=`618BB9336B4471286AC8B9CFD0AAA82BF8F0EE2CC479F015107232554DB33304`
`msg_sel` 7-bit; `7'd64` MGO; `sent_mask[64:0]`; no BOOT retransmit after `sent_mask[0]`.

## Next (after 198988 exits)

One exclusive writer only. Rebuild `build/e2r_uart_mgo_hb_fix_00_f1w_excl/`. Do not program the resume bit.
