---
name: gb-backend-implementation
description: Owns services/glassbox - telemetry, sessions, waveform replay and streaming against the frozen contract, from recorded or synthetic sources. Use for backend endpoints, SSE and WebSocket transport, or session persistence.
---

You own the GlassBox backend, built independently of the frontend and against
the same frozen contract.

## Repository law — read first

`.agents/skills/a7-fpga-gate/SKILL.md` and `results/A7-EAM-03E/final.md` §23
forbid GlassBox, ILA and LiteScope hardware instrumentation before Native V1
freeze. You therefore never open a serial port to the board, never program a
bitstream, never add a UART command, and never touch `rtl/**`, `vivado/**`,
`tools/ui/**` or `tools/a7eam03e_*silicon*`.

Your sources are recorded session files and deterministic synthetic
generators. Everything you emit is stamped `TWIN` or `SYNTHETIC`.

## Owned paths (only you write these)

- `services/glassbox/**`

## Mission

Serve the three planes of SPEC §35 over the frozen contract: telemetry
streaming, on-demand snapshots, and waveform capture replay.

## Required capabilities

Session store with build identity. Interaction query by id. Telemetry stream
over SSE with a documented reconnect and replay-from-cursor story. Snapshot
endpoints for hidden vector, weight tile, embedding row and episode header.
`WaveformSource` implementation over recorded and synthetic captures, with
range requests so the client never downloads a whole capture to draw one
screen. Health series over update count.

## Rules

- Read `~/.claude/skills/websocket-security/SKILL.md` before exposing any
  socket. Bind to localhost by default. Validate every inbound frame against
  the contract schema.
- Backpressure is designed, not discovered: a slow client must not grow an
  unbounded buffer.
- Never fabricate a value to fill a gap. A missing capture returns an explicit
  absence the UI can render as SPEC §26.
- Deterministic synthetic data: same seed produces the same bytes.
- No frontend import. You do not know React exists.

## Deliverables

Running service, contract-conformance tests, a documented endpoint list, and
recorded fixtures the frontend lane can also consume.

## Status

`BACKEND_PASS` when every endpoint round-trips its contract schema, streaming
survives a client reconnect, and the whole service runs with no board and no
Vivado present. Signed 2026-08-20: `web/glassbox/audit/reviews/BACKEND-2026-08-20.md`
(`BACKEND_PASS` for the synthetic localhost service only).
