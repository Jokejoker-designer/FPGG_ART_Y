/**
 * Shared primitives for the GlassBox contract.
 *
 * Authority: NATIVE_AI_GLASSBOX_UXUI_SPEC.md §25 (data authority) and §24
 * (completeness). The rule this file exists to enforce: a displayed metric
 * without provenance must be unrepresentable.
 */
import { z } from "zod";

export const CONTRACT_VERSION = "glassbox-contract-v0.4.0" as const;

/**
 * §25. BOARD is physical silicon. XSIM is RTL simulation. TWIN is the host
 * reference model. DERIVED is computed from an authoritative value.
 * SYNTHETIC is generated for this pre-freeze phase and is not evidence of
 * anything. These are never interchangeable.
 */
export const EvidenceSource = z.enum([
  "BOARD",
  "XSIM",
  "TWIN",
  "DERIVED",
  "SYNTHETIC",
]);
export type EvidenceSource = z.infer<typeof EvidenceSource>;

/** Sources that may never be styled or labelled as silicon evidence (§32.13). */
export const NON_BOARD_SOURCES: readonly EvidenceSource[] = [
  "XSIM",
  "TWIN",
  "DERIVED",
  "SYNTHETIC",
];

export const Provenance = z
  .object({
    source: EvidenceSource,
    /** Required for DERIVED: what authoritative values this was computed from. */
    derivedFrom: z.array(z.string().min(1)).optional(),
    capturedAt: z.string().datetime({ offset: true }),
    /** Free-text qualifier shown in the evidence drawer, never on a chart axis. */
    note: z.string().max(240).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.source === "DERIVED" && !value.derivedFrom?.length) {
      ctx.addIssue({
        code: "custom",
        path: ["derivedFrom"],
        message: "DERIVED provenance must name what it was derived from (§25)",
      });
    }
    if (value.source !== "DERIVED" && value.derivedFrom?.length) {
      ctx.addIssue({
        code: "custom",
        path: ["derivedFrom"],
        message: "derivedFrom is only meaningful for DERIVED provenance",
      });
    }
  });
export type Provenance = z.infer<typeof Provenance>;

/**
 * Every number that reaches a screen is wrapped. There is deliberately no
 * unwrapped numeric metric in this contract.
 */
export function measured<T extends z.ZodTypeAny>(inner: T) {
  return z.object({
    value: inner,
    provenance: Provenance,
    unit: z.string().max(24).optional(),
  });
}

export const MeasuredInt = measured(z.number().int());
export type MeasuredInt = z.infer<typeof MeasuredInt>;

export const MeasuredFloat = measured(z.number().finite());
export type MeasuredFloat = z.infer<typeof MeasuredFloat>;

/** §6.2 process strip. The order is the causal order and is not configurable. */
export const Phase = z.enum([
  "INPUT",
  "ENCODE",
  "COMPARE",
  "LEARN",
  "MEMORY",
  "MODEL",
  "OUTPUT",
]);
export type Phase = z.infer<typeof Phase>;

export const PHASE_ORDER: readonly Phase[] = [
  "INPUT",
  "ENCODE",
  "COMPARE",
  "LEARN",
  "MEMORY",
  "MODEL",
  "OUTPUT",
];

/** §6.2. Four states per stage, no fifth. */
export const StageState = z.enum(["waiting", "active", "complete", "error"]);
export type StageState = z.infer<typeof StageState>;

/** §6.1 centre of the top bar. */
export const RunMode = z.enum(["TRAIN", "EVAL", "FROZEN"]);
export type RunMode = z.infer<typeof RunMode>;

/** §4. The switch changes presentation, never data authority. */
export const PresentationLevel = z.enum(["DE_HIEU", "RESEARCH", "RTL"]);
export type PresentationLevel = z.infer<typeof PresentationLevel>;

export const Density = z.enum(["comfortable", "research"]);
export type Density = z.infer<typeof Density>;

export const InteractionId = z.string().regex(/^[0-9]+$/, "numeric id string");
export type InteractionId = z.infer<typeof InteractionId>;

export const EventId = z.string().min(1).max(80);
export type EventId = z.infer<typeof EventId>;

/**
 * §23. Cycle bounds are optional because host-side planes have no cycle
 * counter. Absence is explicit, never zero-filled.
 */
export const CycleRange = z.object({
  startCycle: z.number().int().nonnegative(),
  endCycle: z.number().int().nonnegative(),
});
export type CycleRange = z.infer<typeof CycleRange>;

/** §24. Missing hardware evidence is never inferred to complete the story. */
export const Traceability = z.enum(["FULLY_TRACEABLE", "PARTIALLY_TRACEABLE"]);
export type Traceability = z.infer<typeof Traceability>;

/** The eight questions of §24, in order, used to compute traceability. */
export const TRACEABILITY_QUESTIONS = [
  "input",
  "representation",
  "decisionMetric",
  "learningDecision",
  "changedValues",
  "memoryAccess",
  "modelContext",
  "selectedToken",
] as const;

export const TraceabilityAudit = z.object({
  answered: z.array(z.enum(TRACEABILITY_QUESTIONS)),
  missing: z.array(z.enum(TRACEABILITY_QUESTIONS)),
  verdict: Traceability,
});
export type TraceabilityAudit = z.infer<typeof TraceabilityAudit>;

/**
 * Parameter accounting. §9 shows a model parameter figure, and it has to come
 * from data rather than from a literal in a component.
 *
 * `.agents/skills/a7-fpga-gate/SKILL.md` states that these counts are **never
 * summed** and that "1.6M parameter AI" is a forbidden phrase: episodes are
 * learned memory records, not parameters, and the fixed binary projection is
 * not trainable. There is deliberately no `total` field here, so a total is
 * not expressible without someone adding it and explaining why.
 */
export const ParameterCounts = z.object({
  /** Language-model head. */
  lm: z.number().int().nonnegative(),
  /** Encoder: E 256x32 plus Wh 32x32 under the current law. */
  encoder: z.number().int().nonnegative(),
});
export type ParameterCounts = z.infer<typeof ParameterCounts>;

/**
 * Device utilisation for the implemented design.
 *
 * This is a **build fact**, not a measurement: it is a deterministic property
 * of the routed netlist, read from a Vivado utilisation report. It is therefore
 * not wrapped in `measured()` and carries no provenance badge — it names its
 * report instead. Calling it BOARD would imply somebody observed it on silicon.
 *
 * `used` and `available` are both required so a screen can never show a
 * percentage without the counts behind it. A die view that renders a resource
 * as busy when `used` is 0 is a defect: `a7-fpga-gate` makes `DSP = 0` a hard
 * numeric gate for this design.
 */
export const ResourceUsage = z.object({
  resource: z.string().min(1),
  used: z.number().int().nonnegative(),
  available: z.number().int().positive(),
});
export type ResourceUsage = z.infer<typeof ResourceUsage>;

export const DeviceUtilization = z.object({
  part: z.string().min(1),
  /** Path of the report these numbers were read from, relative to repo root. */
  reportPath: z.string().min(1),
  rows: z.array(ResourceUsage).min(1),
});
export type DeviceUtilization = z.infer<typeof DeviceUtilization>;

export function usagePercent(row: ResourceUsage): number {
  return Number(((row.used / row.available) * 100).toFixed(2));
}

/** §21. Shown in the top bar and pinned to every exported artifact. */
export const BuildIdentity = z.object({
  bitstreamSha256: z.string().regex(/^[0-9A-F]{64}$/).nullable(),
  sourceSha256: z.string().regex(/^[0-9a-f]{40,64}$/).nullable(),
  modelVersion: z.string().min(1),
  learningLawId: z.string().min(1),
  memoryLawId: z.string().min(1).nullable(),
  parameters: ParameterCounts,
  /** Null until a routed implementation report has been loaded. */
  utilization: DeviceUtilization.nullable(),
  clockMhz: z.number().positive(),
  /** §26: a build that failed timing may not be presented as reliable. */
  timingStatus: z.enum(["MET", "VIOLATED", "UNKNOWN"]),
  wnsNs: z.number().nullable(),
  tnsNs: z.number().nullable(),
  /**
   * Hold timing. `a7-fpga-gate` requires these to be reported and treats a
   * negative hold slack as a finding, so they are first-class rather than
   * folded into `timingStatus`.
   */
  whsNs: z.number().nullable(),
  thsNs: z.number().nullable(),
  /** Endpoint count the summary was computed over, for context on the slack. */
  timingEndpoints: z.number().int().nonnegative().nullable(),
});
export type BuildIdentity = z.infer<typeof BuildIdentity>;
