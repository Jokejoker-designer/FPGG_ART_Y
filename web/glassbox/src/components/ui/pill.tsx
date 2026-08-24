/**
 * Status pill. §7.5 fully rounded, §28 never colour-only: every tone ships a
 * glyph so the distinction survives greyscale and colour blindness.
 *
 * Owner: gb-design-system.
 */
import type { ReactNode } from "react";

export type PillTone =
  | "neutral"
  | "primary"
  | "pass"
  | "attention"
  | "fail"
  | "learn"
  | "memory";

/**
 * A pill's colour is its text colour at 12px, which is small text under
 * SC 1.4.3 and needs 4.5:1. The neutral tone therefore uses `--gb-text-muted`
 * rather than `--gb-inactive`: a quiet pill still has to be readable, and
 * `--gb-inactive` only clears 3:1, which is a graphical-object threshold.
 */
const TONE: Record<PillTone, { color: string; glyph: string }> = {
  neutral: { color: "var(--gb-text-muted)", glyph: "\u25CF" },
  primary: { color: "var(--gb-primary)", glyph: "\u25B6" },
  pass: { color: "var(--gb-pass)", glyph: "\u2713" },
  attention: { color: "var(--gb-attention)", glyph: "\u26A0" },
  fail: { color: "var(--gb-fail)", glyph: "\u2715" },
  learn: { color: "var(--gb-learn)", glyph: "\u21BB" },
  memory: { color: "var(--gb-memory)", glyph: "\u25C9" },
};

export function Pill({
  tone,
  children,
  title,
}: {
  tone: PillTone;
  children: ReactNode;
  title?: string;
}) {
  const { color, glyph } = TONE[tone];
  return (
    <span
      title={title}
      className="inline-flex items-center gap-1.5 rounded-pill border px-2.5 py-0.5 text-xs font-medium"
      style={{ color, borderColor: color, backgroundColor: "transparent" }}
    >
      <span aria-hidden="true">{glyph}</span>
      {children}
    </span>
  );
}
