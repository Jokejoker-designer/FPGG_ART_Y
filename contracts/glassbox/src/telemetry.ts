/**
 * §35.1 telemetry plane — low-rate continuous state.
 *
 * This plane is display-throttled by the client (§29). It carries scalars
 * only; anything vector-sized belongs to the snapshot plane so that a slow
 * consumer cannot be flooded.
 */
import { z } from "zod";
import {
  EventId,
  InteractionId,
  MeasuredFloat,
  MeasuredInt,
  Phase,
  Provenance,
  RunMode,
  StageState,
} from "./primitives.ts";

export const StageTiming = z.object({
  phase: Phase,
  state: StageState,
  durationMs: MeasuredFloat.nullable(),
});
export type StageTiming = z.infer<typeof StageTiming>;

export const TelemetrySample = z.object({
  eventId: EventId,
  interactionId: InteractionId,
  emittedAt: z.string().datetime({ offset: true }),
  phase: Phase,
  mode: RunMode,
  teacherOn: z.boolean(),
  learn: z.boolean(),
  freeze: z.boolean(),

  /** §13 comparison scalars. Absent until the COMPARE phase has run. */
  dPos: MeasuredInt.nullable(),
  dNeg: MeasuredInt.nullable(),
  marginL1: MeasuredInt.nullable(),

  /** §14. updateCount is cumulative; changedValues is per interaction. */
  updateCount: MeasuredInt.nullable(),
  changedValues: MeasuredInt.nullable(),

  /** §19 health proxies. Saturation is a ratio in [0,1], not a percentage. */
  hiddenSaturation: MeasuredFloat.nullable(),
  effectiveRank: MeasuredInt.nullable(),

  /** §15 retrieval scalars. */
  episodeId: z.string().min(1).nullable(),
  candidateCount: MeasuredInt.nullable(),

  /** §17. A token id, not a rendered string. */
  outputTokenId: z.number().int().nonnegative().nullable(),

  provenance: Provenance,
});
export type TelemetrySample = z.infer<typeof TelemetrySample>;

/**
 * §19 long-horizon chart. X axis is update count, never wall-clock time, so
 * that a paused session does not distort the curve.
 */
export const HealthPoint = z.object({
  updateCount: z.number().int().nonnegative(),
  auc: MeasuredFloat.nullable(),
  averagePrecision: MeasuredFloat.nullable(),
  effectiveRank: MeasuredInt.nullable(),
  hiddenSaturation: MeasuredFloat.nullable(),
  maxAbsWh: MeasuredInt.nullable(),
  marginL1: MeasuredInt.nullable(),
});
export type HealthPoint = z.infer<typeof HealthPoint>;

/**
 * §19 collapse detector. A metric that improves because the thing it measures
 * collapsed is a failure, so the verdict is computed from rank and saturation
 * together, never from AUC alone.
 */
export const HealthVerdict = z.enum([
  "HEALTHY",
  "WATCH",
  "COLLAPSING",
  "COLLAPSED",
  "UNKNOWN",
]);
export type HealthVerdict = z.infer<typeof HealthVerdict>;

export const HealthSeries = z.object({
  points: z.array(HealthPoint),
  verdict: HealthVerdict,
  /** §19 baselines. Never hide a baseline that beats the learned model. */
  baselines: z.array(
    z.object({
      label: z.string().min(1),
      auc: MeasuredFloat,
      beatsLearnedModel: z.boolean(),
    }),
  ),
});
export type HealthSeries = z.infer<typeof HealthSeries>;

/** Stream envelope. `cursor` lets a reconnecting client resume without gaps. */
export const TelemetryFrame = z.object({
  cursor: z.string().min(1),
  sample: TelemetrySample,
});
export type TelemetryFrame = z.infer<typeof TelemetryFrame>;
