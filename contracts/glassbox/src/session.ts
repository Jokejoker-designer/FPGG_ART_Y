/**
 * §34 data model. Session is the aggregate root; every screen is locked to one
 * interaction inside it (§6.3) so two charts can never silently show unrelated
 * transactions.
 */
import { z } from "zod";
import {
  BuildIdentity,
  InteractionId,
  MeasuredFloat,
  MeasuredInt,
  Provenance,
  RunMode,
  TraceabilityAudit,
} from "./primitives.ts";
import { HealthSeries, StageTiming } from "./telemetry.ts";
import {
  CompareEvent,
  HiddenVector,
  InputEvent,
  LearningEvent,
  MemoryEvent,
  ModelEvent,
  OutputEvent,
  RetrievalFunnel,
} from "./snapshot.ts";
import { WaveformResult } from "./waveform.ts";

/** §21 evidence table row. One per displayed metric family. */
export const EvidenceMetadata = z.object({
  metric: z.string().min(1),
  provenance: Provenance,
});
export type EvidenceMetadata = z.infer<typeof EvidenceMetadata>;

export const Interaction = z.object({
  interactionId: InteractionId,
  startedAt: z.string().datetime({ offset: true }),
  mode: RunMode,
  teacherOn: z.boolean(),

  /** §10 conversational surface. */
  question: z.string(),
  answer: z.string().nullable(),
  latencyMs: MeasuredFloat.nullable(),
  tokenCount: MeasuredInt.nullable(),

  /** §9 bottom waterfall. */
  stages: z.array(StageTiming),

  input: z.array(InputEvent),
  representation: z.array(HiddenVector),
  compare: z.array(CompareEvent),
  learning: z.array(LearningEvent),
  memory: z.array(MemoryEvent),
  retrieval: RetrievalFunnel.nullable(),
  model: z.array(ModelEvent),
  output: z.array(OutputEvent),
  waveform: WaveformResult,

  evidence: z.array(EvidenceMetadata),
  traceability: TraceabilityAudit,
});
export type Interaction = z.infer<typeof Interaction>;

/** Cheap list row for the interaction picker; avoids loading whole sessions. */
export const InteractionSummary = z.object({
  interactionId: InteractionId,
  startedAt: z.string().datetime({ offset: true }),
  question: z.string(),
  learned: z.boolean(),
  traceability: TraceabilityAudit.shape.verdict,
});
export type InteractionSummary = z.infer<typeof InteractionSummary>;

export const Session = z.object({
  sessionId: z.string().min(1),
  openedAt: z.string().datetime({ offset: true }),
  build: BuildIdentity,
  interactions: z.array(Interaction),
  health: HealthSeries,
});
export type Session = z.infer<typeof Session>;

/** §6.1 right side of the top bar. */
export const ConnectionState = z.object({
  connected: z.boolean(),
  /** §26: the shell must say which plane is actually feeding the screen. */
  activeSource: z.enum(["BOARD", "RECORDED", "SYNTHETIC", "NONE"]),
  detail: z.string().max(240).nullable(),
});
export type ConnectionState = z.infer<typeof ConnectionState>;
