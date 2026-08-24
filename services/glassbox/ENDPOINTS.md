# GlassBox service endpoints

Bind: `127.0.0.1` only. Source: `SYNTHETIC`. No serial port, no WebSocket, no LiteScope, no BOARD claim.

Reconnect: `GET /v1/telemetry` is SSE. Send `Last-Event-ID` or `?fromCursor=` with the last received `cursor`. The next event is the following stored frame. The producer is a finite recorded list; it does not buffer unbounded live samples.

| Method | Path | Contract body |
|---|---|---|
| GET | `/v1/health` | `{ ok, bind, source, serial }` |
| GET | `/v1/endpoints` | This list plus the reconnect sentence |
| GET | `/v1/connection` | `ConnectionState` (`connected: false`, `SYNTHETIC`) |
| GET | `/v1/session` | `Session` |
| GET | `/v1/interactions` | `InteractionSummary[]` |
| GET | `/v1/interactions/:id` | `Interaction` or 404 |
| GET | `/v1/health-series` | `HealthSeries` |
| GET | `/v1/hidden/:id` | `HiddenVector[]` |
| GET | `/v1/embeddings/:id` | `EmbeddingRow[]` (bytes the interaction actually read) |
| GET | `/v1/projection/:id` | `Projection2D` or 204 |
| GET | `/v1/weights/:id` | `WeightWrite[]` (empty when no update ran) |
| GET | `/v1/episode/:id` | `RetrievalFunnel` episode header, or 204 when retrieval is absent |
| GET | `/v1/waveform/:id` | `WaveformResult` (capture or explicit absence) |
| GET | `/v1/waveform/:id/range?from=&to=` | `WaveformResult` sliced by cycle |
| GET | `/v1/telemetry` | SSE `TelemetryFrame` |
