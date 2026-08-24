/**
 * The adapter boundary. The frontend depends on these interfaces and never on
 * a transport: SPEC §34 requires UI -> feature interface -> adapter ->
 * transport, so a React component may not import serial, SSE or WebSocket code.
 *
 * A fixture implementation and a live implementation are interchangeable here.
 * That interchangeability is what lets the two lanes reach FRONTEND_PASS and
 * BACKEND_PASS independently before any wiring happens.
 */
import type { InteractionId } from "./primitives.ts";
import type { HealthSeries, TelemetryFrame } from "./telemetry.ts";
import type {
  EmbeddingRow,
  HiddenVector,
  Projection2D,
} from "./snapshot.ts";
import type {
  ConnectionState,
  Interaction,
  InteractionSummary,
  Session,
} from "./session.ts";
import type { WaveformSource } from "./waveform.ts";

export interface SessionPort {
  getSession(): Promise<Session>;
  listInteractions(limit?: number): Promise<InteractionSummary[]>;
  getInteraction(id: InteractionId): Promise<Interaction | null>;
  getConnectionState(): Promise<ConnectionState>;
}

export interface TelemetryPort {
  /**
   * Resumable stream. `fromCursor` replays without gaps after a reconnect;
   * the client throttles for display rather than the producer dropping data.
   */
  subscribe(
    onFrame: (frame: TelemetryFrame) => void,
    options?: { fromCursor?: string; signal?: AbortSignal },
  ): Promise<void>;
}

export interface SnapshotPort {
  getHiddenVectors(id: InteractionId): Promise<HiddenVector[]>;
  /**
   * Rows of `E` for the bytes this interaction actually read. A byte the
   * interaction never touched has no row, and the caller renders that absence
   * rather than a zero row.
   */
  getEmbeddingRows(id: InteractionId): Promise<EmbeddingRow[]>;
  /** §12. Illustration only; null when there is nothing to project. */
  getProjection(id: InteractionId): Promise<Projection2D | null>;
  getHealthSeries(): Promise<HealthSeries>;
}

/** Everything the UI is allowed to reach, in one injectable object. */
export interface GlassBoxPorts {
  session: SessionPort;
  telemetry: TelemetryPort;
  snapshot: SnapshotPort;
  waveform: WaveformSource;
}
