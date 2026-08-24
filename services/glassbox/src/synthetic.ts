/**
 * Deterministic synthetic session for the backend lane.
 *
 * Independent of `web/glassbox` fixtures. Same contract, different generator,
 * so FRONTEND_PASS and BACKEND_PASS can move without sharing source files.
 * Everything is SYNTHETIC. No BOARD claim.
 */
import {
  HIDDEN_DIM,
  Session,
  TRACEABILITY_QUESTIONS,
  type EmbeddingRow,
  type HiddenVector,
  type Projection2D,
  type Provenance,
  type TelemetryFrame,
  type WaveformResult,
} from "@glassbox/contracts";

export const AT = "2026-08-20T12:00:00.000+07:00";

const SYNTHETIC: Provenance = { source: "SYNTHETIC", capturedAt: AT };

function synthInt(value: number, unit?: string) {
  return unit ? { value, provenance: SYNTHETIC, unit } : { value, provenance: SYNTHETIC };
}

function synthFloat(value: number, unit?: string) {
  return unit ? { value, provenance: SYNTHETIC, unit } : { value, provenance: SYNTHETIC };
}

function derivedInt(value: number, from: string[]) {
  return {
    value,
    provenance: { source: "DERIVED" as const, derivedFrom: from, capturedAt: AT },
  };
}

function hidden(
  interactionId: string,
  role: HiddenVector["role"],
  stage: HiddenVector["stage"],
  seed: number,
): HiddenVector {
  const values = Array.from({ length: HIDDEN_DIM }, (_, i) => ((seed + i * 17) % 4001) - 2000);
  const maxAbs = Math.max(...values.map((v) => Math.abs(v)));
  const meanAbs = values.reduce((s, v) => s + Math.abs(v), 0) / values.length;
  return {
    interactionId,
    role,
    stage,
    values,
    maxAbs: synthInt(maxAbs),
    meanAbs: synthFloat(Number(meanAbs.toFixed(2))),
    saturation: synthFloat(0.03),
    effectiveRank: synthInt(8, `/${HIDDEN_DIM}`),
    provenance: SYNTHETIC,
  };
}

function waveformFor(interactionId: string, present: boolean): WaveformResult {
  if (!present) {
    return {
      available: false,
      absence: {
        interactionId,
        reason: "PRE_FREEZE_NOT_PERMITTED",
        detail: "LiteScope/ILA capture is forbidden before Native V1 freeze.",
      },
    };
  }
  return {
    available: true,
    capture: {
      captureId: `syn-${interactionId}`,
      interactionId,
      clockMhz: 100,
      cycles: { startCycle: 0, endCycle: 240 },
      settings: {
        preTriggerSamples: 16,
        postTriggerSamples: 224,
        rle: true,
        subsampling: 1,
        mode: "SINGLE",
        trigger: "USER_SENT_QUESTION",
      },
      signals: [
        {
          id: "i_valid",
          label: "Nhận dữ liệu vào",
          rtlName: "i_valid",
          group: "INPUT",
          kind: "BIT",
          width: 1,
        },
        {
          id: "upd_en",
          label: "Cho phép cập nhật",
          rtlName: "upd_en",
          group: "LEARNING",
          kind: "BIT",
          width: 1,
        },
      ],
      traces: [
        { signalId: "i_valid", transitions: [{ cycle: 0, value: 0 }, { cycle: 8, value: 1 }, { cycle: 40, value: 0 }] },
        { signalId: "upd_en", transitions: [{ cycle: 0, value: 0 }, { cycle: 80, value: 1 }, { cycle: 120, value: 0 }] },
      ],
      annotations: [
        { kind: "USER_INPUT_ACCEPTED", cycle: 8, label: "Câu hỏi vào" },
        { kind: "UPDATE_STARTED", cycle: 80, label: "Bắt đầu ghi" },
      ],
      overflow: false,
      exportFormats: ["JSON_EVENTS"],
      provenance: SYNTHETIC,
    },
  };
}

export function buildSession(): Session {
  const id = "9001";
  const emptyId = "9000";
  const session = Session.parse({
    sessionId: "ses-backend-synthetic-01",
    openedAt: AT,
    build: {
      bitstreamSha256: null,
      sourceSha256: null,
      modelVersion: "glassbox-backend-synthetic",
      learningLawId: "eam03e-a0-signsgd-v1",
      memoryLawId: null,
      parameters: { lm: 802_816, encoder: 9_216 },
      utilization: null,
      clockMhz: 100,
      timingStatus: "UNKNOWN",
      wnsNs: null,
      tnsNs: null,
      whsNs: null,
      thsNs: null,
      timingEndpoints: null,
    },
    interactions: [
      {
        interactionId: id,
        startedAt: AT,
        mode: "TRAIN",
        teacherOn: true,
        question: "Board hiện tại dùng chip gì?",
        answer: null,
        latencyMs: synthFloat(22.4, "ms"),
        tokenCount: synthInt(0),
        stages: [
          { phase: "INPUT", state: "complete", durationMs: synthFloat(0.8, "ms") },
          { phase: "ENCODE", state: "complete", durationMs: synthFloat(4.2, "ms") },
          { phase: "COMPARE", state: "complete", durationMs: synthFloat(1.4, "ms") },
          { phase: "LEARN", state: "complete", durationMs: synthFloat(12.0, "ms") },
          { phase: "MEMORY", state: "waiting", durationMs: null },
          { phase: "MODEL", state: "waiting", durationMs: null },
          { phase: "OUTPUT", state: "waiting", durationMs: null },
        ],
        input: [
          {
            eventId: `evt-${id}-in`,
            interactionId: id,
            text: "Board hiện tại dùng chip gì?",
            tokens: [
              { position: 0, byte: 66, char: "B", embeddingRow: 66 },
              { position: 1, byte: 111, char: "o", embeddingRow: 111 },
            ],
            provenance: SYNTHETIC,
          },
        ],
        representation: [
          hidden(id, "ANCHOR", "BEFORE_UPDATE", 11),
          hidden(id, "POSITIVE", "BEFORE_UPDATE", 22),
          hidden(id, "NEGATIVE", "BEFORE_UPDATE", 33),
        ],
        compare: [
          {
            eventId: `evt-${id}-cmp`,
            interactionId: id,
            anchorText: "FPGA nào đang dùng?",
            positiveText: "Board hiện tại dùng chip gì?",
            negativeText: "Giá máy lạnh bao nhiêu?",
            dPos: synthInt(1400),
            dNeg: synthInt(4100),
            marginL1: derivedInt(2700, ["dPos", "dNeg"]),
            marginCosine: null,
            dH: null,
            marginThreshold: 512,
            violated: true,
            provenance: SYNTHETIC,
          },
        ],
        learning: [
          {
            eventId: `evt-${id}-lrn`,
            interactionId: id,
            updateEnabled: true,
            learnedValueCount: synthInt(9216),
            changedCount: synthInt(4),
            increasedCount: synthInt(2),
            decreasedCount: synthInt(2),
            clippedCount: synthInt(0),
            durationMs: synthFloat(12.0, "ms"),
            writes: [
              { target: "E", address: 12, before: 10, delta: 1, after: 11 },
              { target: "E", address: 13, before: 4, delta: -1, after: 3 },
              { target: "Wh", address: 0, before: 2, delta: 1, after: 3 },
              { target: "Wh", address: 1, before: 8, delta: -2, after: 6 },
            ],
            timeline: [{ label: "Cho phép cập nhật", at: AT }],
            provenance: SYNTHETIC,
          },
        ],
        memory: [],
        retrieval: {
          interactionId: id,
          stages: [
            { label: "Ứng viên", count: 4 },
            { label: "Lọc", count: 2 },
            { label: "Chọn", count: 1 },
          ],
          selectedEpisodeId: "ep-syn-12",
          provenance: SYNTHETIC,
        },
        model: [],
        output: [],
        waveform: waveformFor(id, true),
        evidence: [{ metric: "d_pos", provenance: SYNTHETIC }],
        traceability: {
          answered: ["input", "representation", "decisionMetric", "learningDecision", "changedValues"],
          missing: ["memoryAccess", "modelContext", "selectedToken"],
          verdict: "PARTIALLY_TRACEABLE",
        },
      },
      {
        interactionId: emptyId,
        startedAt: AT,
        mode: "EVAL",
        teacherOn: false,
        question: "GPIO nào đang rảnh?",
        answer: null,
        latencyMs: null,
        tokenCount: null,
        stages: TRACEABILITY_QUESTIONS.includes("input")
          ? [
              { phase: "INPUT", state: "complete", durationMs: synthFloat(0.6, "ms") },
              { phase: "ENCODE", state: "waiting", durationMs: null },
              { phase: "COMPARE", state: "waiting", durationMs: null },
              { phase: "LEARN", state: "waiting", durationMs: null },
              { phase: "MEMORY", state: "waiting", durationMs: null },
              { phase: "MODEL", state: "waiting", durationMs: null },
              { phase: "OUTPUT", state: "waiting", durationMs: null },
            ]
          : [],
        input: [
          {
            eventId: `evt-${emptyId}-in`,
            interactionId: emptyId,
            text: "GPIO nào đang rảnh?",
            tokens: [{ position: 0, byte: 71, char: "G", embeddingRow: 71 }],
            provenance: SYNTHETIC,
          },
        ],
        representation: [hidden(emptyId, "ANCHOR", "BEFORE_UPDATE", 1)],
        compare: [],
        learning: [],
        memory: [],
        retrieval: null,
        model: [],
        output: [],
        waveform: waveformFor(emptyId, false),
        evidence: [],
        traceability: {
          answered: ["input"],
          missing: [
            "representation",
            "decisionMetric",
            "learningDecision",
            "changedValues",
            "memoryAccess",
            "modelContext",
            "selectedToken",
          ],
          verdict: "PARTIALLY_TRACEABLE",
        },
      },
    ],
    health: {
      points: [
        {
          updateCount: 0,
          auc: synthFloat(0.6),
          averagePrecision: synthFloat(0.58),
          effectiveRank: synthInt(26, `/${HIDDEN_DIM}`),
          hiddenSaturation: synthFloat(0.02),
          maxAbsWh: synthInt(40),
          marginL1: synthInt(-800),
        },
        {
          updateCount: 64,
          auc: synthFloat(0.5),
          averagePrecision: synthFloat(0.5),
          effectiveRank: synthInt(1, `/${HIDDEN_DIM}`),
          hiddenSaturation: synthFloat(0.9),
          maxAbsWh: synthInt(120),
          marginL1: synthInt(0),
        },
      ],
      verdict: "COLLAPSED",
      baselines: [
        { label: "Chưa huấn luyện", auc: synthFloat(0.6), beatsLearnedModel: true },
      ],
    },
  });
  return session;
}

export function embeddingsFor(interactionId: string): EmbeddingRow[] {
  const interaction = buildSession().interactions.find((i) => i.interactionId === interactionId);
  const bytes = new Set(interaction?.input.flatMap((e) => e.tokens.map((t) => t.byte)) ?? []);
  return [...bytes].map((byte) => ({
    byte,
    values: Array.from({ length: 32 }, (_, i) => ((byte * 3 + i) % 17) - 8),
    provenance: SYNTHETIC,
  }));
}

export function projectionFor(interactionId: string): Projection2D | null {
  const vectors = buildSession().interactions.find((i) => i.interactionId === interactionId)?.representation;
  if (!vectors?.length) return null;
  return {
    interactionId,
    method: "two leading coordinates of the recorded hidden vector",
    points: vectors.map((v) => ({
      role: v.role,
      stage: v.stage,
      x: v.values[0] ?? 0,
      y: v.values[1] ?? 0,
    })),
    provenance: {
      source: "DERIVED",
      derivedFrom: ["representation.values[0]", "representation.values[1]"],
      capturedAt: AT,
    },
  };
}

export function telemetryFrames(session: Session): TelemetryFrame[] {
  return session.interactions.flatMap((interaction, index) => {
    const compare = interaction.compare[0] ?? null;
    const learn = interaction.learning[0] ?? null;
    return {
      cursor: String(index),
      sample: {
        eventId: `tel-${interaction.interactionId}`,
        interactionId: interaction.interactionId,
        emittedAt: interaction.startedAt,
        phase: interaction.stages.find((s) => s.state === "complete")?.phase ?? "INPUT",
        mode: interaction.mode,
        teacherOn: interaction.teacherOn,
        learn: Boolean(learn?.updateEnabled),
        freeze: interaction.mode === "FROZEN",
        dPos: compare?.dPos ?? null,
        dNeg: compare?.dNeg ?? null,
        marginL1: compare?.marginL1 ?? null,
        updateCount: synthInt(index),
        changedValues: learn?.changedCount ?? null,
        hiddenSaturation: null,
        effectiveRank: null,
        episodeId: null,
        candidateCount: null,
        outputTokenId: null,
        provenance: SYNTHETIC,
      },
    };
  });
}
