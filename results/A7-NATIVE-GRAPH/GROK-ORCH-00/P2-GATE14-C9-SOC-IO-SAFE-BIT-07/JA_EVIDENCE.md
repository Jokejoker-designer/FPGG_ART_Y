# JA decision — P2-GATE14-C9-SOC-IO-SAFE-BIT-07

JA_REQUIRED=NO

Parent DRC (BIT-06 `report_drc.rpt`): NSTD-1 and UCIO-1 both named **Problem ports: ja[7:0]**. Build waived those checks. Codex rejected that bit for programming.

## Is JA needed for Gate14 acceptance?

No. Gate14 host path is UART CFRAME (COM12 @ 115200) + TinyGPT OUT.  
`ja[7:0]` was **E2R-LA-PMOD-00 observe-only Pmod JA** (SGO / W_STALL / LM_ACTIVE / BIND_DONE / SOA_R / SOA_AR / QUERY_ACCEPT / CORE_LIVE). Debug LA, not UART protocol.

## Resolution

REMOVED_FROM_PRODUCTION_TOP. Deleted `output logic [7:0] ja` and the `ja_q` IOB register from `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`. Heartbeat/LED still use `*_100`. No replacement unconstrained debug port.

`constraints/e2r_la_pmod_ja.xdc` is **not** in the full-chip fileset.

## Official mapping (unused; recorded only)

Source: `constraints/e2r_la_pmod_ja.xdc` — Digilent Arty A7-100T Pmod JA, LVCMOS33.

| port | PACKAGE_PIN | IOSTANDARD |
|------|-------------|------------|
| ja[0] | G13 | LVCMOS33 |
| ja[1] | B11 | LVCMOS33 |
| ja[2] | A11 | LVCMOS33 |
| ja[3] | D12 | LVCMOS33 |
| ja[4] | D13 | LVCMOS33 |
| ja[5] | B18 | LVCMOS33 |
| ja[6] | A18 | LVCMOS33 |
| ja[7] | K16 | LVCMOS33 |

Not applied. Not assigned to DDR/clock/UART/config.

## Waiver

FORBIDDEN. write_bitstream has no `set_property SEVERITY {Warning} [get_drc_checks NSTD-1|UCIO-1]`.
