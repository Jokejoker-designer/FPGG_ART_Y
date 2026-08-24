/**
 * §8.1 "Process flow → animated stage flow". The large pipeline at the centre
 * of Tab 1.
 *
 * The animation is driven by stage state, never by a timer: a stage pulses only
 * while it is `active`. §8.2 forbids animation that is not driven by actual
 * data, so a recorded interaction whose stages are all `complete` shows a still
 * pipeline, and that is the correct result rather than a missing feature.
 *
 * Reduced motion is handled by the `prefers-reduced-motion` block in
 * `globals.css`, which collapses animation duration rather than shortening it.
 *
 * Owner: gb-scientific-dataviz.
 */
import { Link } from "@tanstack/react-router";
import type { Phase, StageTiming } from "@/lib/contract";
import { PHASE_ORDER } from "@/lib/contract";
import { PHASE_TOKEN, tokenVar } from "@/design/tokens";
import { EvidenceBadge } from "@/components/ui/evidence-badge";

/** §9 uses the user-facing verbs, not the internal phase names. */
const PHASE_LABEL: Record<Phase, string> = {
  INPUT: "Đọc",
  ENCODE: "Biểu diễn",
  COMPARE: "So sánh",
  LEARN: "Học",
  MEMORY: "Bộ nhớ",
  MODEL: "Mô hình",
  OUTPUT: "Trả lời",
};

const STATE_LABEL: Record<StageTiming["state"], string> = {
  waiting: "đang chờ",
  active: "đang chạy",
  complete: "xong",
  error: "lỗi",
};

const STATE_GLYPH: Record<StageTiming["state"], string> = {
  waiting: "\u25CB",
  active: "\u25B6",
  complete: "\u2713",
  error: "\u2715",
};

export interface PipelineTarget {
  readonly phase: Phase;
  readonly href: string;
  readonly label: string;
}

export function ProcessPipeline({
  stages,
  targets = [],
}: {
  stages: readonly StageTiming[];
  /** Only phases whose tab exists; anything else renders as text. */
  targets?: readonly PipelineTarget[];
}) {
  const byPhase = new Map(stages.map((stage) => [stage.phase, stage]));
  const targetByPhase = new Map(targets.map((t) => [t.phase, t]));
  const provenance = stages.find((s) => s.durationMs)?.durationMs?.provenance;

  return (
    <figure className="flex flex-col gap-4">
      <figcaption className="flex items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">
          Tiến trình của tương tác này
        </span>
        {provenance ? <EvidenceBadge provenance={provenance} /> : null}
      </figcaption>

      <ol className="flex flex-wrap items-stretch gap-2">
        {PHASE_ORDER.map((phase, index) => {
          const stage = byPhase.get(phase);
          const state = stage?.state ?? "waiting";
          const color = tokenVar(PHASE_TOKEN[phase]);
          const target = targetByPhase.get(phase);
          const dimmed = state === "waiting";

          const body = (
            <span className="flex min-w-24 flex-col items-start gap-1">
              <span className="flex items-center gap-1.5">
                <span
                  aria-hidden="true"
                  className={state === "active" ? "gb-stage-active" : undefined}
                  style={{
                    color: state === "error" ? "var(--gb-fail)" : color,
                  }}
                >
                  {STATE_GLYPH[state]}
                </span>
                <span
                  className="text-sm font-medium"
                  style={{
                    color: dimmed ? "var(--gb-text-muted)" : color,
                  }}
                >
                  {PHASE_LABEL[phase]}
                </span>
              </span>
              <span className="gb-num text-[11px] text-ink-muted">
                {stage?.durationMs
                  ? `${stage.durationMs.value} ms`
                  : STATE_LABEL[state]}
              </span>
            </span>
          );

          return (
            <li key={phase} className="flex items-center gap-2">
              {target ? (
                <Link
                  to={target.href}
                  title={`Mở ${target.label}`}
                  className="rounded-control border px-3 py-2 hover:bg-surface-3"
                  style={{ borderColor: "var(--gb-border)" }}
                >
                  {body}
                </Link>
              ) : (
                <span
                  className="rounded-control border px-3 py-2"
                  style={{ borderColor: "var(--gb-border)" }}
                >
                  {body}
                </span>
              )}
              {index < PHASE_ORDER.length - 1 ? (
                <span aria-hidden="true" className="text-ink-faint">
                  {"\u2192"}
                </span>
              ) : null}
            </li>
          );
        })}
      </ol>

      {/* §28: the same information as a table, for screen readers and for
          anyone who needs the numbers rather than the shape. */}
      <table className="gb-sr-only">
        <caption>Thời lượng từng chặng của tiến trình</caption>
        <thead>
          <tr>
            <th scope="col">Chặng</th>
            <th scope="col">Trạng thái</th>
            <th scope="col">Thời lượng</th>
          </tr>
        </thead>
        <tbody>
          {PHASE_ORDER.map((phase) => {
            const stage = byPhase.get(phase);
            return (
              <tr key={phase}>
                <th scope="row">{PHASE_LABEL[phase]}</th>
                <td>{STATE_LABEL[stage?.state ?? "waiting"]}</td>
                <td>
                  {stage?.durationMs
                    ? `${stage.durationMs.value} mili giây`
                    : "chưa có số đo"}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </figure>
  );
}
