/**
 * Token access for code that cannot use Tailwind classes.
 *
 * `src/app/globals.css` is the single source of truth for every value here.
 * Canvas surfaces (waveform, 32x32 delta maps) need real colour strings, so
 * they resolve the same custom properties at runtime instead of duplicating
 * hex codes. A hardcoded colour anywhere in a component is a design-system
 * violation.
 *
 * Owner: gb-design-system.
 */
import type { EvidenceSource } from "@/lib/contract";

export const COLOR_TOKENS = [
  "bg",
  "surface-1",
  "surface-2",
  "surface-3",
  "border",
  "border-strong",
  "text",
  "text-muted",
  "text-faint",
  "primary",
  "primary-strong",
  "primary-dim",
  "pass",
  "attention",
  "fail",
  "learn",
  "memory",
  "model",
  "output",
  "inactive",
  "evidence-board",
  "evidence-xsim",
  "evidence-twin",
  "evidence-derived",
  "evidence-synthetic",
  "evidence-stall",
  "evidence-active",
] as const;

export type ColorToken = (typeof COLOR_TOKENS)[number];

/** For inline styles and SVG attributes. */
export function tokenVar(token: ColorToken): string {
  return `var(--gb-${token})`;
}

/**
 * For Canvas, which needs a concrete colour. Resolved from the live cascade so
 * a density or theme change is picked up without a second source of truth.
 * Returns an empty string during server rendering, where no cascade exists.
 */
export function resolveToken(
  token: ColorToken,
  element?: Element | null,
): string {
  if (typeof window === "undefined") return "";
  const target = element ?? document.documentElement;
  return getComputedStyle(target).getPropertyValue(`--gb-${token}`).trim();
}

/**
 * §25 and §28. Every provenance badge carries a glyph and a word, so the
 * distinction survives greyscale, colour blindness and a screen reader.
 * `authoritative` is what the UI keys visual weight off — never the colour.
 */
export interface EvidencePresentation {
  readonly label: string;
  readonly glyph: string;
  readonly token: ColorToken;
  readonly authoritative: boolean;
  /** Plain Vietnamese, shown in the evidence drawer and as the badge title. */
  readonly explanation: string;
}

export const EVIDENCE_PRESENTATION: Record<
  EvidenceSource,
  EvidencePresentation
> = {
  BOARD: {
    label: "BOARD",
    glyph: "\u25C6",
    token: "evidence-board",
    authoritative: true,
    explanation: "UART silicon. Bằng chứng vật lý.",
  },
  XSIM: {
    label: "XSIM",
    glyph: "\u25C7",
    token: "evidence-xsim",
    authoritative: false,
    explanation: "Mô phỏng RTL. Không phải silicon.",
  },
  TWIN: {
    label: "TWIN",
    glyph: "\u25B3",
    token: "evidence-twin",
    authoritative: false,
    explanation: "Bản sao số trên host. Không phải silicon.",
  },
  DERIVED: {
    label: "DERIVED",
    glyph: "\u0192",
    token: "evidence-derived",
    authoritative: false,
    explanation: "Tính từ nguồn khác. Không đo trực tiếp.",
  },
  SYNTHETIC: {
    label: "SYNTHETIC",
    glyph: "\u25CB",
    token: "evidence-synthetic",
    authoritative: false,
    explanation: "Generated data. Not silicon.",
  },
};

/** Observatory source copy. Short commercial labels; colour is locked in CSS. */
export const OBS_SOURCE_COPY = {
  BOARD: "UART silicon. Physical board.",
  XSIM: "RTL simulation. Not silicon.",
  SYNTHETIC: "Generated data. Not silicon.",
  TWIN: "Host digital twin. Not silicon.",
  STALL: "Pipeline stall.",
  ALERT: "Link down or hardware alert.",
  ACTIVE: "Active stream.",
  AI_RESPONSE: "FPGA-generated output.",
} as const;

/** §6.2 stage colours, so the process strip and the tab accents agree. */
export const PHASE_TOKEN = {
  INPUT: "primary",
  ENCODE: "primary-strong",
  COMPARE: "attention",
  LEARN: "learn",
  MEMORY: "memory",
  MODEL: "model",
  OUTPUT: "output",
} as const satisfies Record<string, ColorToken>;
