/**
 * §35.2 snapshot plane — on-demand state.
 *
 * Vectors and tiles live here, requested per interaction, so the telemetry
 * stream stays small. §14: if the source does not expose an exact gradient,
 * this contract has no field to put one in.
 */
import { z } from "zod";
import {
  EventId,
  InteractionId,
  MeasuredFloat,
  MeasuredInt,
  Provenance,
} from "./primitives.ts";

/** Encoder hidden width for the current law. 32 coordinates, h0..h31. */
export const HIDDEN_DIM = 32;

/**
 * §12 before/after toggle. The spec allows an animated transition only when it
 * is generated from recorded states, so the two states are distinct records
 * rather than one record plus an interpolation. An interaction that did not
 * update has no `AFTER_UPDATE` record at all.
 */
export const HiddenStage = z.enum(["BEFORE_UPDATE", "AFTER_UPDATE"]);
export type HiddenStage = z.infer<typeof HiddenStage>;

export const HiddenVector = z.object({
  interactionId: InteractionId,
  role: z.enum(["ANCHOR", "POSITIVE", "NEGATIVE"]),
  stage: HiddenStage,
  /** §12 heatmap row. Fixed length so the grid never silently ragged. */
  values: z.array(z.number().int()).length(HIDDEN_DIM),
  maxAbs: MeasuredInt,
  meanAbs: MeasuredFloat,
  saturation: MeasuredFloat,
  effectiveRank: MeasuredInt,
  provenance: Provenance,
});
export type HiddenVector = z.infer<typeof HiddenVector>;

/**
 * §11. One entry per input byte. `char` may be a partial UTF-8 sequence, so it
 * is nullable rather than lossily rendered.
 */
export const InputToken = z.object({
  position: z.number().int().nonnegative(),
  byte: z.number().int().min(0).max(255),
  char: z.string().nullable(),
  embeddingRow: z.number().int().min(0).max(255),
});
export type InputToken = z.infer<typeof InputToken>;

export const InputEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  text: z.string(),
  tokens: z.array(InputToken),
  provenance: Provenance,
});
export type InputEvent = z.infer<typeof InputEvent>;

/**
 * §11 embedding visualisation. One row of `E` for a byte the input actually
 * used. Rows for bytes the interaction never read are not fabricated: the
 * detail drawer for such a byte shows an absence.
 */
export const EMBED_DIM = 32;

export const EmbeddingRow = z.object({
  byte: z.number().int().min(0).max(255),
  values: z.array(z.number().int()).length(EMBED_DIM),
  provenance: Provenance,
});
export type EmbeddingRow = z.infer<typeof EmbeddingRow>;

/**
 * §12 2D projection. Explicitly illustrative: the badge `MINH HỌA 2D` is
 * mandatory wherever this renders, and the real decision is computed on the
 * full vector. It is therefore always `DERIVED` and must name the vectors it
 * came from, which the `Provenance` refinement already enforces.
 */
export const ProjectedPoint = z.object({
  role: z.enum(["ANCHOR", "POSITIVE", "NEGATIVE"]),
  stage: HiddenStage,
  x: z.number().finite(),
  y: z.number().finite(),
});
export type ProjectedPoint = z.infer<typeof ProjectedPoint>;

export const Projection2D = z
  .object({
    interactionId: InteractionId,
    points: z.array(ProjectedPoint),
    /** Human-readable note on how the two axes were obtained. */
    method: z.string().min(1),
    provenance: Provenance,
  })
  .superRefine((value, ctx) => {
    if (value.provenance.source !== "DERIVED") {
      ctx.addIssue({
        code: "custom",
        path: ["provenance", "source"],
        message:
          "a 2D projection is always DERIVED from the full vectors (§12)",
      });
    }
  });
export type Projection2D = z.infer<typeof Projection2D>;

export const CompareEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  anchorText: z.string(),
  positiveText: z.string(),
  negativeText: z.string(),
  dPos: MeasuredInt,
  dNeg: MeasuredInt,
  marginL1: MeasuredInt,
  /** §13: cosine is labelled EVAL and is never a training authority. */
  marginCosine: MeasuredFloat.nullable(),
  /** Hamming distance. Unusable on some builds; absence is explicit. */
  dH: MeasuredInt.nullable(),
  marginThreshold: z.number().int(),
  violated: z.boolean(),
  provenance: Provenance,
});
export type CompareEvent = z.infer<typeof CompareEvent>;

/**
 * §14. Only observable update facts: direction, enable, address, before,
 * delta, after. There is intentionally no gradient field.
 */
export const WeightWrite = z.object({
  target: z.enum(["E", "Wh"]),
  address: z.number().int().nonnegative(),
  before: z.number().int(),
  delta: z.number().int(),
  after: z.number().int(),
});
export type WeightWrite = z.infer<typeof WeightWrite>;

export const LearningEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  updateEnabled: z.boolean(),
  learnedValueCount: MeasuredInt,
  changedCount: MeasuredInt,
  increasedCount: MeasuredInt,
  decreasedCount: MeasuredInt,
  clippedCount: MeasuredInt,
  durationMs: MeasuredFloat,
  writes: z.array(WeightWrite),
  /** §14 timeline, each entry clickable in the UI. */
  timeline: z.array(
    z.object({
      label: z.string().min(1),
      at: z.string().datetime({ offset: true }),
    }),
  ),
  provenance: Provenance,
});
export type LearningEvent = z.infer<typeof LearningEvent>;

export const MemoryEventKind = z.enum([
  "READ",
  "WRITE",
  "HIT",
  "MISS",
  "INSERT",
  "UPDATE",
  "EVICT",
]);
export type MemoryEventKind = z.infer<typeof MemoryEventKind>;

export const MemoryEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  kind: MemoryEventKind,
  episodeId: z.string().min(1).nullable(),
  address: z.number().int().nonnegative().nullable(),
  provenance: Provenance,
});
export type MemoryEvent = z.infer<typeof MemoryEvent>;

/** §15 funnel. Stages are ordered and each count must be non-increasing. */
export const RetrievalFunnel = z
  .object({
    interactionId: InteractionId,
    stages: z.array(
      z.object({
        label: z.string().min(1),
        count: z.number().int().nonnegative(),
      }),
    ),
    selectedEpisodeId: z.string().min(1).nullable(),
    provenance: Provenance,
  })
  .superRefine((value, ctx) => {
    for (let i = 1; i < value.stages.length; i += 1) {
      const previous = value.stages[i - 1];
      const current = value.stages[i];
      if (previous && current && current.count > previous.count) {
        ctx.addIssue({
          code: "custom",
          path: ["stages", i, "count"],
          message: "a retrieval funnel stage cannot widen (§15)",
        });
      }
    }
  });
export type RetrievalFunnel = z.infer<typeof RetrievalFunnel>;

export const ModelEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  stage: z.string().min(1),
  layerIndex: z.number().int().nonnegative().nullable(),
  durationMs: MeasuredFloat,
  activationNorm: MeasuredFloat.nullable(),
  saturation: MeasuredFloat.nullable(),
  macCycles: MeasuredInt.nullable(),
  ddrBytes: MeasuredInt.nullable(),
  stalls: MeasuredInt.nullable(),
  contextEpisodeId: z.string().min(1).nullable(),
  provenance: Provenance,
});
export type ModelEvent = z.infer<typeof ModelEvent>;

/**
 * §17. `kind` decides the rendering: a score is never drawn with a percent
 * sign, and a probability is never drawn without normalisation.
 */
export const TokenCandidate = z.object({
  tokenId: z.number().int().nonnegative(),
  text: z.string(),
  kind: z.enum(["PROBABILITY", "SCORE"]),
  amount: z.number().finite(),
});
export type TokenCandidate = z.infer<typeof TokenCandidate>;

export const OutputEvent = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  step: z.number().int().nonnegative(),
  selectedTokenId: z.number().int().nonnegative(),
  selectedText: z.string(),
  candidates: z.array(TokenCandidate),
  cycle: z.number().int().nonnegative().nullable(),
  provenance: Provenance,
});
export type OutputEvent = z.infer<typeof OutputEvent>;
