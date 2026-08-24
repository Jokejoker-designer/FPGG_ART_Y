import {
  ConnectionState,
  Session,
  type GlassBoxPorts,
  type InteractionId,
  type WaveformResult,
} from "@glassbox/contracts";
import { buildSession, embeddingsFor, projectionFor, telemetryFrames } from "./synthetic.ts";

export function createSyntheticPorts(): GlassBoxPorts {
  const session = buildSession();
  const frames = telemetryFrames(session);

  const sessionPort = {
    async getSession() {
      return session;
    },
    async listInteractions() {
      return session.interactions.map((i) => ({
        interactionId: i.interactionId,
        startedAt: i.startedAt,
        question: i.question,
        learned: (i.learning[0]?.changedCount.value ?? 0) > 0,
        traceability: i.traceability.verdict,
      }));
    },
    async getInteraction(id: InteractionId) {
      return session.interactions.find((i) => i.interactionId === id) ?? null;
    },
    async getConnectionState() {
      return ConnectionState.parse({
        connected: false,
        activeSource: "SYNTHETIC",
        detail: "Backend synthetic store. No serial port is open. Not BOARD.",
      });
    },
  };

  const snapshotPort = {
    async getHiddenVectors(id: InteractionId) {
      return (await sessionPort.getInteraction(id))?.representation ?? [];
    },
    async getEmbeddingRows(id: InteractionId) {
      return embeddingsFor(id);
    },
    async getProjection(id: InteractionId) {
      return projectionFor(id);
    },
    async getHealthSeries() {
      return session.health;
    },
  };

  const waveform: GlassBoxPorts["waveform"] = {
    kind: "SYNTHETIC",
    async listCaptures(interactionId) {
      const result = (await sessionPort.getInteraction(interactionId))?.waveform;
      if (result?.available) return [result.capture.captureId];
      return [];
    },
    async getCapture(captureId) {
      for (const interaction of session.interactions) {
        const wave = interaction.waveform;
        if (wave.available && wave.capture.captureId === captureId) return wave;
      }
      return missingWaveform(captureId);
    },
    async getRange(captureId, from, to) {
      const full = await this.getCapture(captureId);
      if (!full.available) return full;
      const traces = full.capture.traces.map((trace) => ({
        signalId: trace.signalId,
        transitions: trace.transitions.filter((t) => t.cycle >= from && t.cycle <= to),
      }));
      return {
        available: true,
        capture: {
          ...full.capture,
          cycles: { startCycle: from, endCycle: to },
          traces,
        },
      };
    },
  };

  const telemetryPort = {
    async subscribe(
      onFrame: (frame: (typeof frames)[number]) => void,
      options?: { fromCursor?: string; signal?: AbortSignal },
    ) {
      const start = options?.fromCursor ? Number(options.fromCursor) + 1 : 0;
      for (const frame of frames.slice(Number.isFinite(start) ? start : 0)) {
        if (options?.signal?.aborted) return;
        onFrame(frame);
      }
    },
  };

  return {
    session: sessionPort,
    snapshot: snapshotPort,
    waveform,
    telemetry: telemetryPort,
  };
}

function missingWaveform(captureId: string): WaveformResult {
  return {
    available: false,
    absence: {
      interactionId: "0",
      reason: "SOURCE_UNAVAILABLE",
      detail: `No synthetic capture named ${captureId}.`,
    },
  };
}

export function parsedSession(): Session {
  return buildSession();
}
