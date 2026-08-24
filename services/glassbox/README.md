# GlassBox service

Independent backend lane. Does not import the frontend. Does not open COM12,
program a bitstream, or add UART commands.

Bind: `127.0.0.1:8787` (localhost only).

## Endpoints

| Method | Path | Contract |
| --- | --- | --- |
| GET | `/v1/health` | process liveness |
| GET | `/v1/connection` | `ConnectionState` |
| GET | `/v1/session` | `Session` |
| GET | `/v1/interactions` | `InteractionSummary[]` |
| GET | `/v1/interactions/:id` | `Interaction` or 404 |
| GET | `/v1/hidden/:id` | `HiddenVector[]` |
| GET | `/v1/embeddings/:id` | `EmbeddingRow[]` |
| GET | `/v1/projection/:id` | `Projection2D` or 204 |
| GET | `/v1/health-series` | `HealthSeries` |
| GET | `/v1/waveform/:id` | `WaveformResult` |
| GET | `/v1/waveform/:id/range?from=&to=` | ranged `WaveformResult` |
| GET | `/v1/telemetry?fromCursor=` | SSE of `TelemetryFrame` |

Every JSON body is parsed through the frozen Zod schema before it is sent.

## Run

```text
cd services/glassbox
npm install
npm test
npm start
```
