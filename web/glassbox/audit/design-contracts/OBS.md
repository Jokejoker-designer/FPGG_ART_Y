# Observatory design contract

| Field | Decision |
| --- | --- |
| Screen job | One operating screen over Native V1 silicon + the existing GlassBox instrument. |
| Composition | Reuse GlassBox `Panel`, `Kpi`, `DieMap`, `ProcessPipeline`, `HealthLines`, `ResourceBars`, `Waterfall`, `ModeStrip`, Live chat chrome. Do not redraw those. |
| Primary action | Query LAST_STAGE / SHA / WNS. Do not send next-token or weights. |
| Hierarchy | 01 Status → 02 Pipeline + GlassBox instrument → 03 Console → 04 UART. |
| Navigation | Four fixed regions. No tab bar. Full Studio remains at `/studio`. |
| Type | Inter/Roboto body. JetBrains Mono UART, hex, SHA, stage IDs, telemetry. |
| Badges | Green 500 BOARD, Blue 500 XSIM, Amber 500 SYNTHETIC/TWIN, Red 500 STALL/ALERT, Cyan 400 ACTIVE/AI_RESPONSE. |
| Watermark | On GlassBox SYNTHETIC plots: `KHÔNG PHẢI DỮ LIỆU SILICON`. |
| States | COM12 closed = ALERT. pred=∅. CORE_START hang = STALL. |
| Forbidden | Rebuilding GlassBox charts from scratch, tab bar, host weight poke, invented pred. |
