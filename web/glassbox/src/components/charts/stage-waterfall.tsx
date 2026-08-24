/**
 * §8.1 "Stage duration → waterfall / Gantt-like timeline". The bottom band of
 * Tab 1 and the model-layer chart of Tab 8.
 *
 * Bars are offset by the cumulative duration of the preceding stages, which is
 * what makes it a waterfall rather than a bar chart: the reader can see that
 * MODEL dominates the wall clock, not just that its number is the largest.
 *
 * SVG rather than Canvas: seven to a dozen bars is small data, and SVG keeps
 * the labels selectable and the geometry inspectable.
 *
 * Owner: gb-scientific-dataviz.
 */
import type { MeasuredFloat } from "@/lib/contract";
import { tokenVar, type ColorToken } from "@/design/tokens";
import { EvidenceBadge } from "@/components/ui/evidence-badge";

export interface WaterfallRow {
  readonly label: string;
  readonly durationMs: MeasuredFloat | null;
  readonly token: ColorToken;
  /** Rendered as a hairline outline rather than a fill. */
  readonly failed?: boolean;
}

const ROW_HEIGHT = 26;
const LABEL_WIDTH = 104;
const VALUE_WIDTH = 76;
const TRACK_WIDTH = 460;

export function StageWaterfall({
  rows,
  title,
  emptyText = "Chưa có số đo thời lượng cho tương tác này.",
}: {
  rows: readonly WaterfallRow[];
  title: string;
  emptyText?: string;
}) {
  const measured = rows.filter((row) => row.durationMs !== null);
  const total = measured.reduce(
    (sum, row) => sum + (row.durationMs?.value ?? 0),
    0,
  );
  const provenance = measured[0]?.durationMs?.provenance;

  if (measured.length === 0) {
    return (
      <figure className="flex flex-col gap-2">
        <figcaption className="text-sm font-semibold text-ink">
          {title}
        </figcaption>
        <p className="text-sm text-ink-muted">{emptyText}</p>
      </figure>
    );
  }

  /* Cumulative offsets, computed once, so a bar's x position is its real start
     in the interaction rather than a decorative indent. */
  let cursor = 0;
  const bars = rows.map((row) => {
    const value = row.durationMs?.value ?? 0;
    const start = cursor;
    if (row.durationMs) cursor += value;
    return { row, start, value };
  });

  const height = rows.length * ROW_HEIGHT + 8;
  const scale = total > 0 ? TRACK_WIDTH / total : 0;

  return (
    <figure className="flex flex-col gap-3">
      <figcaption className="flex flex-wrap items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">{title}</span>
        <span className="flex items-center gap-2">
          <span className="gb-num text-xs text-ink-muted">
            tổng {total.toFixed(1)} ms
          </span>
          {provenance ? <EvidenceBadge provenance={provenance} /> : null}
        </span>
      </figcaption>

      <svg
        role="img"
        aria-label={`${title}. Tổng ${total.toFixed(1)} mili giây.`}
        viewBox={`0 0 ${LABEL_WIDTH + TRACK_WIDTH + VALUE_WIDTH} ${height}`}
        className="w-full"
        style={{ maxHeight: height * 1.6 }}
      >
        {bars.map(({ row, start, value }, index) => {
          const y = index * ROW_HEIGHT + 4;
          const color = tokenVar(row.token);
          const width = Math.max(value * scale, value > 0 ? 2 : 0);
          return (
            <g key={row.label}>
              <text
                x={LABEL_WIDTH - 8}
                y={y + ROW_HEIGHT / 2}
                textAnchor="end"
                dominantBaseline="middle"
                fontSize="11"
                fill="var(--gb-text-muted)"
              >
                {row.label}
              </text>

              {row.durationMs === null ? (
                <text
                  x={LABEL_WIDTH + 4}
                  y={y + ROW_HEIGHT / 2}
                  dominantBaseline="middle"
                  fontSize="11"
                  fill="var(--gb-text-muted)"
                >
                  chưa có số đo
                </text>
              ) : (
                <>
                  <rect
                    x={LABEL_WIDTH + start * scale}
                    y={y + 5}
                    width={width}
                    height={ROW_HEIGHT - 12}
                    rx={3}
                    fill={row.failed ? "transparent" : color}
                    stroke={row.failed ? "var(--gb-fail)" : "none"}
                    strokeWidth={row.failed ? 1.5 : 0}
                    strokeDasharray={row.failed ? "3 2" : undefined}
                  />
                  <text
                    x={LABEL_WIDTH + TRACK_WIDTH + 8}
                    y={y + ROW_HEIGHT / 2}
                    dominantBaseline="middle"
                    fontSize="11"
                    fill="var(--gb-text)"
                    style={{ fontVariantNumeric: "tabular-nums" }}
                  >
                    {value.toFixed(1)} ms
                  </text>
                </>
              )}
            </g>
          );
        })}
      </svg>

      {/* §28: chart values reachable as a table. */}
      <table className="gb-sr-only">
        <caption>{title}</caption>
        <thead>
          <tr>
            <th scope="col">Chặng</th>
            <th scope="col">Bắt đầu</th>
            <th scope="col">Thời lượng</th>
          </tr>
        </thead>
        <tbody>
          {bars.map(({ row, start, value }) => (
            <tr key={row.label}>
              <th scope="row">{row.label}</th>
              <td>
                {row.durationMs
                  ? `${start.toFixed(1)} mili giây`
                  : "không áp dụng"}
              </td>
              <td>
                {row.durationMs
                  ? `${value.toFixed(1)} mili giây`
                  : "chưa có số đo"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
