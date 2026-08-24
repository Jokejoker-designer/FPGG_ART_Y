/**
 * The only way to put a number on screen.
 *
 * §25 requires provenance on every displayed metric. Rather than trusting each
 * screen to remember a badge, this component accepts the wrapped contract type
 * and renders the badge itself, so a metric without provenance is not
 * expressible in JSX.
 *
 * Owner: gb-design-system.
 */
import type { MeasuredFloat, MeasuredInt } from "@/lib/contract";
import { EvidenceBadge } from "./evidence-badge";

type Measured = MeasuredInt | MeasuredFloat;

function formatValue(value: number, fractionDigits?: number): string {
  return value.toLocaleString("vi-VN", {
    minimumFractionDigits: fractionDigits ?? 0,
    maximumFractionDigits: fractionDigits ?? (Number.isInteger(value) ? 0 : 2),
  });
}

export function Metric({
  label,
  metric,
  fractionDigits,
  emptyText = "chưa có",
}: {
  label: string;
  metric: Measured | null;
  fractionDigits?: number;
  emptyText?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <span className="text-xs text-ink-muted">{label}</span>
      {metric === null ? (
        <span className="text-sm text-ink-faint">{emptyText}</span>
      ) : (
        <span className="flex flex-wrap items-center gap-2">
          <span
            className="gb-num font-medium text-ink"
            style={{ fontSize: "var(--gb-text-size-value)" }}
          >
            {formatValue(metric.value, fractionDigits)}
            {metric.unit ? (
              <span className="ml-1 text-xs text-ink-muted">{metric.unit}</span>
            ) : null}
          </span>
          <EvidenceBadge provenance={metric.provenance} />
        </span>
      )}
    </div>
  );
}

/** Inline variant for use inside a sentence or a table cell. */
export function MetricValue({
  metric,
  fractionDigits,
}: {
  metric: Measured;
  fractionDigits?: number;
}) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="gb-num text-ink">
        {formatValue(metric.value, fractionDigits)}
        {metric.unit ? (
          <span className="ml-0.5 text-xs text-ink-muted">{metric.unit}</span>
        ) : null}
      </span>
      <EvidenceBadge provenance={metric.provenance} />
    </span>
  );
}
