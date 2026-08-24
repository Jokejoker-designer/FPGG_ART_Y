/**
 * §35.3 waveform plane — cycle-accurate capture.
 *
 * REPOSITORY LAW. `.agents/skills/a7-fpga-gate/SKILL.md` and
 * `results/A7-EAM-03E/final.md` §23 make GlassBox, ILA and LiteScope a hard
 * stop before Native V1 freeze. This file therefore describes the *shape* of a
 * capture and the `WaveformSource` port. No implementation here talks to
 * hardware, and none may be added before the freeze. Pre-freeze sources are
 * recorded files or deterministic synthetic generators, stamped accordingly.
 */
import { z } from "zod";
import { CycleRange, InteractionId, Provenance } from "./primitives.ts";

/** §18 capture groups. Five groups, fixed, because the sidebar mirrors them. */
export const CaptureGroup = z.enum([
  "INPUT",
  "FORWARD",
  "LEARNING",
  "DDR_MEMORY",
  "OUTPUT",
]);
export type CaptureGroup = z.infer<typeof CaptureGroup>;

export const SignalKind = z.enum(["BIT", "BUS", "ENUM"]);
export type SignalKind = z.infer<typeof SignalKind>;

export const SignalDescriptor = z.object({
  id: z.string().min(1),
  /** Display label. §2.1 keeps raw RTL names out of beginner screens. */
  label: z.string().min(1),
  /** Exact signal name, shown only at RTL presentation level. */
  rtlName: z.string().min(1).nullable(),
  group: CaptureGroup,
  kind: SignalKind,
  width: z.number().int().positive(),
  /** Value-to-name map for ENUM signals such as an FSM state. */
  enumLabels: z.record(z.string(), z.string()).optional(),
});
export type SignalDescriptor = z.infer<typeof SignalDescriptor>;

/**
 * A run-length encoded transition list. Storing transitions rather than one
 * sample per cycle is what makes a long capture renderable (§29).
 */
export const SignalTrace = z.object({
  signalId: z.string().min(1),
  transitions: z.array(
    z.object({
      cycle: z.number().int().nonnegative(),
      value: z.number().int(),
    }),
  ),
});
export type SignalTrace = z.infer<typeof SignalTrace>;

/** §18 mandatory annotation lane above the raw waveform. */
export const WaveformAnnotationKind = z.enum([
  "USER_INPUT_ACCEPTED",
  "HIDDEN_COMPLETE",
  "MARGIN_VIOLATION",
  "UPDATE_STARTED",
  "EPISODE_HIT",
  "LM_CONTEXT_LOADED",
  "TOKEN_EMITTED",
]);
export type WaveformAnnotationKind = z.infer<typeof WaveformAnnotationKind>;

export const WaveformAnnotation = z.object({
  kind: WaveformAnnotationKind,
  cycle: z.number().int().nonnegative(),
  label: z.string().min(1),
});
export type WaveformAnnotation = z.infer<typeof WaveformAnnotation>;

/** §18 trigger presets, named for operators rather than for signals. */
export const TriggerPreset = z.enum([
  "USER_SENT_QUESTION",
  "LEARNING_STARTED",
  "WEIGHT_CHANGED",
  "SATURATION_OCCURRED",
  "MEMORY_HIT",
  "MEMORY_MISS",
  "TOKEN_EMITTED",
  "ERROR",
  "CUSTOM",
]);
export type TriggerPreset = z.infer<typeof TriggerPreset>;

export const CaptureSettings = z.object({
  preTriggerSamples: z.number().int().nonnegative(),
  postTriggerSamples: z.number().int().nonnegative(),
  rle: z.boolean(),
  subsampling: z.number().int().positive(),
  mode: z.enum(["SINGLE", "AUTO"]),
  trigger: TriggerPreset,
});
export type CaptureSettings = z.infer<typeof CaptureSettings>;

export const ExportFormat = z.enum(["VCD", "CSV", "SR", "JSON_EVENTS"]);
export type ExportFormat = z.infer<typeof ExportFormat>;

export const WaveformCapture = z.object({
  captureId: z.string().min(1),
  interactionId: InteractionId,
  clockMhz: z.number().positive(),
  cycles: CycleRange,
  settings: CaptureSettings,
  signals: z.array(SignalDescriptor),
  traces: z.array(SignalTrace),
  annotations: z.array(WaveformAnnotation),
  /** §26: true when the buffer wrapped and part of the record is gone. */
  overflow: z.boolean(),
  exportFormats: z.array(ExportFormat),
  provenance: Provenance,
});
export type WaveformCapture = z.infer<typeof WaveformCapture>;

/** §26. Absence is a first-class answer, never an interpolated waveform. */
export const WaveformAbsence = z.object({
  interactionId: InteractionId,
  reason: z.enum([
    "CAPTURE_DISABLED",
    "NO_TRIGGER_MATCH",
    "SOURCE_UNAVAILABLE",
    "PRE_FREEZE_NOT_PERMITTED",
  ]),
  detail: z.string().max(240),
});
export type WaveformAbsence = z.infer<typeof WaveformAbsence>;

export const WaveformResult = z.union([
  z.object({ available: z.literal(true), capture: WaveformCapture }),
  z.object({ available: z.literal(false), absence: WaveformAbsence }),
]);
export type WaveformResult = z.infer<typeof WaveformResult>;

/**
 * The port both lanes code against. A range request exists so a client never
 * downloads a whole capture to paint one screen (§29).
 */
export interface WaveformSource {
  readonly kind: "RECORDED" | "SYNTHETIC";
  listCaptures(interactionId: InteractionId): Promise<string[]>;
  getCapture(captureId: string): Promise<WaveformResult>;
  getRange(
    captureId: string,
    from: number,
    to: number,
  ): Promise<WaveformResult>;
}
