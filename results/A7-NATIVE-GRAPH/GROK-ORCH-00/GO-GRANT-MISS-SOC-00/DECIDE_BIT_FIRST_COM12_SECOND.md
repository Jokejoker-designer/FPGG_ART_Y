# DECIDE — BIT_FIRST_COM12_SECOND

**Adopted:** 2026-08-30  
**Tree:** `arty-a7-online-lm-grok-orch-00`  
**Gate:** `GO-GRANT-MISS-SOC-00`

COM12 is **not** held. Physical COM12 may exist; this branch does **not** arm, program, or request it until `PREBUILD_READY`.

`BRIDGE.json` (read 2026-08-30 ~13:32):

| Field | Value |
|-------|--------|
| `com12_authorized_gate` | `E2R-QUALIFY-CDC-RVALID-PROGRAM-00` (**Cursor**, not this gate) |
| `program_authorized` | true for **qualify** bit only |
| researchLane `program` | **false** |
| lock.task | Cursor program qualify; do not kill Grok GO-GRANT-MISS 203704 |

Grok **refuses** that token. A later COM12 window needs a **new** human token naming `GO-GRANT-MISS-SOC-00` / `research/native-ai-v1-grok-orch-00`.

Offline path in flight: Vivado 203704 synth/impl this bag, `PROGRAM=NO`.

Do not program `B64B2649` / `125978D3` / `157D6B73` / close664 / qualify bits. AI does not stamp BOARD_PASS.
