/**
 * Fixture implementation of every port.
 *
 * This is what makes the two lanes independent: the UI is fully demonstrable
 * and testable with no backend process running. A live implementation will
 * satisfy the same interfaces, so wiring later replaces this file and touches
 * no component.
 *
 * Owner: gb-frontend-architecture.
 */
import type {
  ConnectionState,
  EmbeddingRow,
  GlassBoxPorts,
  HealthSeries,
  HiddenVector,
  Interaction,
  InteractionSummary,
  Projection2D,
  Session,
  SessionPort,
  SnapshotPort,
  TelemetryFrame,
  TelemetryPort,
} from "@/lib/contract";
import { FIXTURE_SESSION } from "@/fixtures/session";
import { SYNTHETIC } from "@/fixtures/provenance";
import { embeddingRowsFor, projectionFor } from "@/fixtures/snapshots";
import { syntheticWaveformSource } from "@/fixtures/waveform";

/** §29. Display cadence, deliberately far slower than any hardware rate. */
const TELEMETRY_INTERVAL_MS = 400;

const fixtureSessionPort: SessionPort = {
  async getSession(): Promise<Session> {
    return FIXTURE_SESSION;
  },

  async listInteractions(limit?: number): Promise<InteractionSummary[]> {
    const summaries = FIXTURE_SESSION.interactions.map((interaction) => ({
      interactionId: interaction.interactionId,
      startedAt: interaction.startedAt,
      question: interaction.question,
      learned: interaction.learning.some((event) => event.updateEnabled),
      traceability: interaction.traceability.verdict,
    }));
    return limit === undefined ? summaries : summaries.slice(0, limit);
  },

  async getInteraction(id: string): Promise<Interaction | null> {
    return (
      FIXTURE_SESSION.interactions.find(
        (interaction) => interaction.interactionId === id,
      ) ?? null
    );
  },

  async getConnectionState(): Promise<ConnectionState> {
    /* §26 and §32.17: the shell says plainly which plane is feeding it. A
       fixture session must never render as a live board connection. */
    return {
      connected: false,
      activeSource: "SYNTHETIC",
      detail:
        "Đang dùng dữ liệu mô hình. Chưa kết nối bo mạch, nên các số trên màn hình không phải bằng chứng silicon.",
    };
  },
};

const fixtureSnapshotPort: SnapshotPort = {
  async getHiddenVectors(id: string): Promise<HiddenVector[]> {
    const interaction = await fixtureSessionPort.getInteraction(id);
    return interaction?.representation ?? [];
  },

  async getEmbeddingRows(id: string): Promise<EmbeddingRow[]> {
    return embeddingRowsFor(id);
  },

  async getProjection(id: string): Promise<Projection2D | null> {
    return projectionFor(id);
  },

  async getHealthSeries(): Promise<HealthSeries> {
    return FIXTURE_SESSION.health;
  },
};

/**
 * Replays the recorded phases of each interaction as a stream. The cursor is
 * an index, so a reconnecting client resumes without a gap, which is the same
 * contract a live SSE transport must honour.
 */
function buildFrames(): TelemetryFrame[] {
  const frames: TelemetryFrame[] = [];
  for (const interaction of FIXTURE_SESSION.interactions) {
    const compare = interaction.compare[0];
    const learning = interaction.learning[0];
    for (const stage of interaction.stages) {
      const index = frames.length;
      frames.push({
        cursor: `f${index}`,
        sample: {
          eventId: `evt-${interaction.interactionId}-tel-${index}`,
          interactionId: interaction.interactionId,
          emittedAt: interaction.startedAt,
          phase: stage.phase,
          mode: interaction.mode,
          teacherOn: interaction.teacherOn,
          learn: Boolean(learning?.updateEnabled),
          freeze: false,
          dPos: compare?.dPos ?? null,
          dNeg: compare?.dNeg ?? null,
          marginL1: compare?.marginL1 ?? null,
          updateCount: learning?.changedCount ?? null,
          changedValues: learning?.changedCount ?? null,
          hiddenSaturation: interaction.representation[0]?.saturation ?? null,
          effectiveRank: interaction.representation[0]?.effectiveRank ?? null,
          episodeId: interaction.retrieval?.selectedEpisodeId ?? null,
          candidateCount: null,
          outputTokenId: interaction.output[0]?.selectedTokenId ?? null,
          provenance: SYNTHETIC,
        },
      });
    }
  }
  return frames;
}

const FRAMES = buildFrames();

const fixtureTelemetryPort: TelemetryPort = {
  async subscribe(onFrame, options) {
    const startIndex = options?.fromCursor
      ? FRAMES.findIndex((frame) => frame.cursor === options.fromCursor) + 1
      : 0;

    for (let i = Math.max(0, startIndex); i < FRAMES.length; i += 1) {
      if (options?.signal?.aborted) return;
      const frame = FRAMES[i];
      if (frame) onFrame(frame);
      await new Promise<void>((resolve) => {
        const timer = setTimeout(resolve, TELEMETRY_INTERVAL_MS);
        options?.signal?.addEventListener(
          "abort",
          () => {
            clearTimeout(timer);
            resolve();
          },
          { once: true },
        );
      });
    }
  },
};

export const fixturePorts: GlassBoxPorts = {
  session: fixtureSessionPort,
  telemetry: fixtureTelemetryPort,
  snapshot: fixtureSnapshotPort,
  waveform: syntheticWaveformSource,
};
