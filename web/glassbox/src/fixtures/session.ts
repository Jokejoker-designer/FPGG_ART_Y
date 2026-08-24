/**
 * The deterministic session every screen reads during the pre-freeze phase.
 *
 * Sample content follows SPEC §31. Provenance follows §31's last line and §25:
 * nothing here claims BOARD, because no board measurement took place. Values
 * computed from other fixture values are stamped DERIVED and name their
 * inputs, so the evidence tab tells the truth about its own data.
 *
 * Owner: gb-frontend-architecture.
 */
import {
  HIDDEN_DIM,
  Session,
  TRACEABILITY_QUESTIONS,
  type HealthSeries,
  type HiddenVector,
  type Interaction,
  type InputToken,
  type LearningEvent,
  type MemoryEvent,
  type ModelEvent,
  type OutputEvent,
  type StageTiming,
  type TokenCandidate,
  type TraceabilityAudit,
  type WeightWrite,
} from "@/lib/contract";
import { createRng, rngInt } from "./prng";
import {
  FIXTURE_CAPTURED_AT,
  SYNTHETIC,
  derivedFloat,
  derivedInt,
  TWIN,
  synthFloat,
  synthInt,
} from "./provenance";
import { waveformResultFor } from "./waveform";

const QUESTION = "Board hiện tại dùng chip gì?";
const ANSWER = "Arty A7 sử dụng FPGA Artix-7.";
const HIDDEN_RAIL = 32_767;

/**
 * §9 waterfall, verbatim. Total latency is derived from these rather than
 * quoted separately, so the header figure and the chart can never disagree.
 */
const STAGE_MS: ReadonlyArray<readonly [StageTiming["phase"], number]> = [
  ["INPUT", 0.8],
  ["ENCODE", 4.3],
  ["COMPARE", 1.4],
  ["LEARN", 11.9],
  ["MEMORY", 8.7],
  ["MODEL", 61.2],
  ["OUTPUT", 5.6],
];

function completedStages(): StageTiming[] {
  return STAGE_MS.map(([phase, ms]) => ({
    phase,
    state: "complete" as const,
    durationMs: synthFloat(ms, "ms"),
  }));
}

function totalLatencyMs(): number {
  return Number(STAGE_MS.reduce((sum, [, ms]) => sum + ms, 0).toFixed(1));
}

/**
 * §11. One entry per UTF-8 byte, not per character, because that is what the
 * encoder consumes. Continuation bytes carry `char: null` rather than a
 * lossily rendered glyph.
 */
function tokenizeUtf8(text: string): InputToken[] {
  const bytes = new TextEncoder().encode(text);
  const tokens: InputToken[] = [];
  let charStart = 0;
  for (let i = 0; i < bytes.length; i += 1) {
    const byte = bytes[i] ?? 0;
    const isContinuation = (byte & 0xc0) === 0x80;
    if (!isContinuation) charStart = i;
    let char: string | null = null;
    if (!isContinuation) {
      let length = 1;
      if (byte >= 0xf0) length = 4;
      else if (byte >= 0xe0) length = 3;
      else if (byte >= 0xc0) length = 2;
      char = new TextDecoder().decode(bytes.slice(charStart, charStart + length));
    }
    tokens.push({ position: i, byte, char, embeddingRow: byte });
  }
  return tokens;
}

/**
 * Hidden state for one role. Saturation is measured from the values rather
 * than asserted, so the number on screen always describes the vector on
 * screen. Effective rank is a property of the state trajectory, not of a
 * single vector, so it stays SYNTHETIC and is never presented as derived from
 * what the heatmap shows.
 */
function hiddenVector(
  interactionId: string,
  role: HiddenVector["role"],
  stage: HiddenVector["stage"],
  seed: number,
  railCount: number,
): HiddenVector {
  const rng = createRng(seed);
  const values: number[] = [];
  for (let i = 0; i < HIDDEN_DIM; i += 1) {
    values.push(rngInt(rng, -18_400, 24_800));
  }
  for (let i = 0; i < railCount; i += 1) {
    values[i * 7 + 3] = HIDDEN_RAIL;
  }

  const absolutes = values.map((v) => Math.abs(v));
  const maxAbs = Math.max(...absolutes);
  const meanAbs =
    absolutes.reduce((sum, v) => sum + v, 0) / absolutes.length;
  const saturated = values.filter((v) => Math.abs(v) >= HIDDEN_RAIL).length;

  return {
    interactionId,
    role,
    stage,
    values,
    maxAbs: derivedInt(maxAbs, [`h[${role}]`]),
    meanAbs: derivedFloat(Number(meanAbs.toFixed(1)), [`h[${role}]`]),
    saturation: derivedFloat(
      Number((saturated / HIDDEN_DIM).toFixed(4)),
      [`h[${role}]`],
    ),
    effectiveRank: synthInt(role === "ANCHOR" ? 19 : 18, `/${HIDDEN_DIM}`),
    provenance: SYNTHETIC,
  };
}

/**
 * §14. Only observable update facts. There is no gradient here because the
 * source does not expose one, and §14 forbids drawing a fake one.
 * 141 increased + 145 decreased = 286 changed, matching §14's summary cards.
 */
function weightWrites(): WeightWrite[] {
  const rng = createRng(0x0286_5eed);
  const writes: WeightWrite[] = [];
  const push = (target: WeightWrite["target"], address: number, delta: number) => {
    const before = rngInt(rng, -96, 96);
    writes.push({ target, address, before, delta, after: before + delta });
  };

  for (let i = 0; i < 141; i += 1) {
    push(i % 5 === 0 ? "Wh" : "E", rngInt(rng, 0, i % 5 === 0 ? 1023 : 8191), 1);
  }
  for (let i = 0; i < 145; i += 1) {
    push(i % 5 === 0 ? "Wh" : "E", rngInt(rng, 0, i % 5 === 0 ? 1023 : 8191), -1);
  }
  return writes;
}

function learningEvent(interactionId: string): LearningEvent {
  const writes = weightWrites();
  const increased = writes.filter((w) => w.delta > 0).length;
  const decreased = writes.filter((w) => w.delta < 0).length;
  return {
    eventId: `evt-${interactionId}-learn`,
    interactionId,
    updateEnabled: true,
    /* E 256x32 = 8192 plus Wh 32x32 = 1024. Never summed with the LM head. */
    learnedValueCount: synthInt(9_216),
    changedCount: derivedInt(writes.length, ["writes"]),
    increasedCount: derivedInt(increased, ["writes"]),
    decreasedCount: derivedInt(decreased, ["writes"]),
    clippedCount: synthInt(0),
    durationMs: synthFloat(12.4, "ms"),
    writes,
    timeline: [
      { label: "So sánh xong", at: "2026-08-20T10:32:15.489+07:00" },
      { label: "Vi phạm ngưỡng", at: "2026-08-20T10:32:15.491+07:00" },
      { label: "Cho phép cập nhật", at: "2026-08-20T10:32:15.492+07:00" },
      { label: "Ghi 286 giá trị", at: "2026-08-20T10:32:15.498+07:00" },
      { label: "Cập nhật hoàn tất", at: "2026-08-20T10:32:15.504+07:00" },
    ],
    provenance: SYNTHETIC,
  };
}

function memoryEvents(interactionId: string): MemoryEvent[] {
  const kinds: MemoryEvent["kind"][] = ["READ", "READ", "HIT", "UPDATE"];
  return kinds.map((kind, index) => ({
    eventId: `evt-${interactionId}-mem-${index}`,
    interactionId,
    kind,
    episodeId: kind === "READ" ? null : "488271",
    address: 0x2f_00_00 + index * 64,
    provenance: SYNTHETIC,
  }));
}

/** §16 pipeline. Layer 1 figures follow the §16 example card. */
function modelEvents(interactionId: string): ModelEvent[] {
  const stages: ReadonlyArray<
    readonly [string, number | null, number, number | null, number | null]
  > = [
    ["Embedding", null, 3.1, null, 8_192],
    ["Layer 1", 1, 14.2, 18_240, 43_008],
    ["Attention", null, 9.4, 11_700, 20_480],
    ["Layer 2", 2, 15.8, 19_100, 43_008],
    ["Memory context", null, 6.2, null, 12_288],
    ["LM head", null, 12.5, 24_600, 32_768],
  ];
  return stages.map(([stage, layerIndex, ms, mac, ddr], index) => ({
    eventId: `evt-${interactionId}-model-${index}`,
    interactionId,
    stage,
    layerIndex,
    durationMs: synthFloat(ms, "ms"),
    activationNorm: synthFloat(stage === "Layer 1" ? 1_842.6 : 1_460.2),
    saturation: synthFloat(stage === "Layer 1" ? 0.004 : 0.002),
    macCycles: mac === null ? null : synthInt(mac),
    ddrBytes: ddr === null ? null : synthInt(ddr, "B"),
    stalls: synthInt(index === 4 ? 214 : 12),
    contextEpisodeId: stage === "Memory context" ? "488271" : null,
    provenance: SYNTHETIC,
  }));
}

/**
 * §17. `Arty → A7 → sử → dụng → Artix → - → 7` is seven steps. Candidates are
 * PROBABILITY and sum to 1, so a percentage label is not a lie. A source that
 * emitted unnormalised logits would use kind SCORE instead.
 */
function outputEvents(interactionId: string): OutputEvent[] {
  const steps: ReadonlyArray<readonly [string, number]> = [
    ["Arty", 4_101],
    ["A7", 4_102],
    ["sử", 2_210],
    ["dụng", 2_211],
    ["Artix", 4_110],
    ["-", 45],
    ["7", 55],
  ];

  return steps.map(([text, tokenId], step) => {
    const candidates: TokenCandidate[] =
      text === "Artix"
        ? [
            { tokenId: 4_110, text: "Artix", kind: "PROBABILITY", amount: 0.72 },
            { tokenId: 4_120, text: "FPGA", kind: "PROBABILITY", amount: 0.11 },
            { tokenId: 4_130, text: "AMD", kind: "PROBABILITY", amount: 0.07 },
            { tokenId: 4_140, text: "board", kind: "PROBABILITY", amount: 0.04 },
            { tokenId: 0, text: "còn lại", kind: "PROBABILITY", amount: 0.06 },
          ]
        : [
            { tokenId, text, kind: "PROBABILITY", amount: 0.81 },
            { tokenId: 0, text: "còn lại", kind: "PROBABILITY", amount: 0.19 },
          ];

    return {
      eventId: `evt-${interactionId}-out-${step}`,
      interactionId,
      step,
      selectedTokenId: tokenId,
      selectedText: text,
      candidates,
      cycle: 8_218_441 + step * 1_240,
      provenance: SYNTHETIC,
    };
  });
}

/** §24. Computed from what is actually present, never asserted. */
function auditTraceability(
  present: Partial<Record<(typeof TRACEABILITY_QUESTIONS)[number], boolean>>,
): TraceabilityAudit {
  const answered = TRACEABILITY_QUESTIONS.filter((q) => present[q] === true);
  const missing = TRACEABILITY_QUESTIONS.filter((q) => present[q] !== true);
  return {
    answered: [...answered],
    missing: [...missing],
    verdict: missing.length === 0 ? "FULLY_TRACEABLE" : "PARTIALLY_TRACEABLE",
  };
}

function fullInteraction(): Interaction {
  const id = "1842";
  const learning = learningEvent(id);
  return {
    interactionId: id,
    startedAt: FIXTURE_CAPTURED_AT,
    mode: "TRAIN",
    teacherOn: true,
    question: QUESTION,
    answer: ANSWER,
    latencyMs: derivedFloat(totalLatencyMs(), ["stages[].durationMs"], "ms"),
    tokenCount: synthInt(7),
    stages: completedStages(),
    input: [
      {
        eventId: `evt-${id}-input`,
        interactionId: id,
        text: QUESTION,
        tokens: tokenizeUtf8(QUESTION),
        provenance: SYNTHETIC,
      },
    ],
    /* §12 before/after. Both states are recorded, so the toggle compares two
       measurements rather than interpolating one. The AFTER seeds differ, and
       the positive pair gains a railed coordinate, which is the saturation
       story this program actually measured. */
    representation: [
      hiddenVector(id, "ANCHOR", "BEFORE_UPDATE", 0x00a1_1842, 1),
      hiddenVector(id, "POSITIVE", "BEFORE_UPDATE", 0x00b2_1842, 1),
      hiddenVector(id, "NEGATIVE", "BEFORE_UPDATE", 0x00c3_1842, 0),
      hiddenVector(id, "ANCHOR", "AFTER_UPDATE", 0x00a1_1843, 1),
      hiddenVector(id, "POSITIVE", "AFTER_UPDATE", 0x00b2_1843, 2),
      hiddenVector(id, "NEGATIVE", "AFTER_UPDATE", 0x00c3_1843, 0),
    ],
    compare: [
      {
        eventId: `evt-${id}-compare`,
        interactionId: id,
        anchorText: "FPGA nào đang dùng?",
        positiveText: QUESTION,
        negativeText: "Giá máy lạnh bao nhiêu?",
        dPos: synthInt(1_320),
        dNeg: synthInt(4_810),
        marginL1: derivedInt(3_490, ["dPos", "dNeg"]),
        /* §13: cosine is an EVAL measurement, never a training authority. */
        marginCosine: derivedFloat(0.0145, ["h[ANCHOR]", "h[POSITIVE]"]),
        /* dH is unusable on this law; absence is explicit, not zero-filled. */
        dH: null,
        marginThreshold: 512,
        violated: true,
        provenance: SYNTHETIC,
      },
    ],
    learning: [learning],
    memory: memoryEvents(id),
    retrieval: {
      interactionId: id,
      stages: [
        { label: "Tổng số ký ức", count: 800_000 },
        { label: "Postings khớp cue", count: 126 },
        { label: "Ứng viên", count: 9 },
        { label: "Kiểm tra khóa đầy đủ", count: 3 },
      ],
      selectedEpisodeId: "488271",
      provenance: SYNTHETIC,
    },
    model: modelEvents(id),
    output: outputEvents(id),
    waveform: waveformResultFor(id),
    evidence: [
      { metric: "d_pos", provenance: SYNTHETIC },
      { metric: "d_neg", provenance: SYNTHETIC },
      {
        metric: "M_L1",
        provenance: {
          source: "DERIVED",
          derivedFrom: ["d_pos", "d_neg"],
          capturedAt: FIXTURE_CAPTURED_AT,
        },
      },
      {
        metric: "M_cos",
        provenance: {
          source: "DERIVED",
          derivedFrom: ["h[ANCHOR]", "h[POSITIVE]"],
          capturedAt: FIXTURE_CAPTURED_AT,
        },
      },
      { metric: "Waveform", provenance: SYNTHETIC },
      { metric: "Weight delta", provenance: SYNTHETIC },
      { metric: "AUC", provenance: SYNTHETIC },
      { metric: "Gradient estimate", provenance: TWIN },
    ],
    traceability: auditTraceability({
      input: true,
      representation: true,
      decisionMetric: true,
      learningDecision: true,
      changedValues: true,
      memoryAccess: true,
      modelContext: true,
      selectedToken: true,
    }),
  };
}

/**
 * §24 and §26. A second interaction that is genuinely incomplete: no learning
 * happened and no capture was running. This exists so PARTIALLY_TRACEABLE and
 * the waveform empty state are exercised by real session data.
 */
function partialInteraction(): Interaction {
  const id = "1841";
  return {
    interactionId: id,
    startedAt: "2026-08-20T10:31:02.117+07:00",
    mode: "EVAL",
    teacherOn: false,
    question: "Board này có bao nhiêu chân GPIO?",
    answer: null,
    latencyMs: synthFloat(41.2, "ms"),
    tokenCount: synthInt(0),
    stages: [
      { phase: "INPUT", state: "complete", durationMs: synthFloat(0.7, "ms") },
      { phase: "ENCODE", state: "complete", durationMs: synthFloat(4.1, "ms") },
      { phase: "COMPARE", state: "complete", durationMs: synthFloat(1.3, "ms") },
      { phase: "LEARN", state: "waiting", durationMs: null },
      { phase: "MEMORY", state: "complete", durationMs: synthFloat(8.4, "ms") },
      { phase: "MODEL", state: "error", durationMs: synthFloat(26.7, "ms") },
      { phase: "OUTPUT", state: "waiting", durationMs: null },
    ],
    input: [
      {
        eventId: `evt-${id}-input`,
        interactionId: id,
        text: "Board này có bao nhiêu chân GPIO?",
        tokens: tokenizeUtf8("Board này có bao nhiêu chân GPIO?"),
        provenance: SYNTHETIC,
      },
    ],
    /* No update happened, so there is no AFTER state to record. */
    representation: [hiddenVector(id, "ANCHOR", "BEFORE_UPDATE", 0x00a1_1841, 0)],
    compare: [],
    learning: [],
    memory: [
      {
        eventId: `evt-${id}-mem-0`,
        interactionId: id,
        kind: "MISS",
        episodeId: null,
        address: 0x2e_00_00,
        provenance: SYNTHETIC,
      },
    ],
    retrieval: {
      interactionId: id,
      stages: [
        { label: "Tổng số ký ức", count: 800_000 },
        { label: "Postings khớp cue", count: 4 },
        { label: "Ứng viên", count: 0 },
      ],
      selectedEpisodeId: null,
      provenance: SYNTHETIC,
    },
    model: [],
    output: [],
    waveform: waveformResultFor(id),
    evidence: [{ metric: "d_pos", provenance: SYNTHETIC }],
    traceability: auditTraceability({
      input: true,
      representation: true,
      decisionMetric: false,
      learningDecision: false,
      changedValues: false,
      memoryAccess: true,
      modelContext: false,
      selectedToken: false,
    }),
  };
}

/**
 * §19. The long-horizon curve shows the collapse this program actually
 * measured: rank falls, saturation climbs, and AUC drifts to chance. §19 also
 * forbids hiding a baseline that beats the learned model, so the byte
 * histogram is listed with `beatsLearnedModel: true`.
 */
function healthSeries(): HealthSeries {
  const rows: ReadonlyArray<readonly [number, number, number, number, number, number, number]> = [
    [0, 0.607, 0.58, 26, 0.01, 41, -1_010],
    [64, 0.742, 0.71, 19, 0.021, 63, 3_490],
    [128, 0.688, 0.66, 14, 0.19, 88, 2_180],
    [256, 0.612, 0.59, 8, 0.42, 104, 1_240],
    [384, 0.534, 0.52, 3, 0.78, 118, 640],
    [512, 0.5, 0.5, 1, 1, 127, 0],
  ];

  return {
    points: rows.map(([updateCount, auc, ap, rank, sat, maxWh, margin]) => ({
      updateCount,
      auc: synthFloat(auc),
      averagePrecision: synthFloat(ap),
      effectiveRank: synthInt(rank, `/${HIDDEN_DIM}`),
      hiddenSaturation: synthFloat(sat),
      maxAbsWh: synthInt(maxWh),
      marginL1: synthInt(margin),
    })),
    verdict: "COLLAPSED",
    baselines: [
      {
        label: "Chưa huấn luyện",
        auc: synthFloat(0.607),
        beatsLearnedModel: true,
      },
      {
        label: "Histogram byte L1",
        auc: synthFloat(0.88),
        beatsLearnedModel: true,
      },
      {
        label: "Jaro-Winkler",
        auc: synthFloat(0.79),
        beatsLearnedModel: true,
      },
    ],
  };
}

/**
 * Parsed through the schema at module load, so a fixture that violates the
 * contract fails the build rather than reaching a screen.
 */
export const FIXTURE_SESSION = Session.parse({
  sessionId: "ses-2026-08-20-01",
  openedAt: "2026-08-20T10:28:44.002+07:00",
  build: {
    /* No bitstream is claimed: this phase has no board measurement. */
    bitstreamSha256: null,
    sourceSha256: null,
    modelVersion: "native-ai-glassbox-preview",
    learningLawId: "eam03e-a0-signsgd-v1",
    memoryLawId: null,
    /* Never summed: a7-fpga-gate names the combined figure a forbidden claim. */
    parameters: { lm: 802_816, encoder: 9_216 },
    /**
     * Read from the routed implementation report of the A0.1-T close, not
     * generated. The shape of this design matters for the die view: it uses
     * about an eighth of the LUTs, three block RAM tiles, and **zero DSPs** —
     * `DSP = 0` is a hard numeric gate in `a7-fpga-gate`. Any view that paints
     * this device as dense or DSP-heavy is wrong.
     */
    utilization: {
      part: "xc7a100tcsg324-1",
      reportPath:
        "results/A7-EAM-03E/A01T_CLOSE/a7eam03e_utilization_route.rpt",
      rows: [
        { resource: "Slice LUTs", used: 7_713, available: 63_400 },
        { resource: "LUT as Logic", used: 7_707, available: 63_400 },
        { resource: "LUT as Memory", used: 6, available: 19_000 },
        { resource: "Slice Registers", used: 7_173, available: 126_800 },
        { resource: "Block RAM Tile", used: 3, available: 135 },
        { resource: "RAMB36/FIFO", used: 2, available: 135 },
        { resource: "RAMB18", used: 2, available: 270 },
        { resource: "DSPs", used: 0, available: 240 },
        { resource: "Bonded IOB", used: 8, available: 210 },
        { resource: "BUFGCTRL", used: 1, available: 32 },
        { resource: "MMCME2_ADV", used: 0, available: 6 },
      ],
    },
    clockMhz: 100,
    /**
     * Read from `results/A7-EAM-03E/A01T_CLOSE/a7eam03e_timing_route.rpt`,
     * which states "All user specified timing constraints are met" over 18857
     * endpoints. Hold slack is positive, so there is no hold finding.
     */
    timingStatus: "MET",
    wnsNs: 0.637,
    tnsNs: 0,
    whsNs: 0.037,
    thsNs: 0,
    timingEndpoints: 18_857,
  },
  interactions: [fullInteraction(), partialInteraction()],
  health: healthSeries(),
});
