/**
 * §8.1 "Hidden vector → heatmap / horizontal bar matrix". The main
 * visualisation of Tab 4.
 *
 * Three rows by thirty-two columns is small data, so this is SVG rather than
 * Canvas: the geometry stays inspectable and the cells stay individually
 * labelled. The 32x32 weight-delta map in a later round is the case that
 * warrants Canvas.
 *
 * §12: column headers are `h0`…`h31` and nothing more. A coordinate is never
 * given a name, because no evidence assigns one.
 *
 * Owner: gb-scientific-dataviz.
 */
import type { HiddenVector } from "@/lib/contract";
import { EvidenceBadge } from "@/components/ui/evidence-badge";

const ROLE_LABEL: Record<HiddenVector["role"], string> = {
  ANCHOR: "Câu gốc",
  POSITIVE: "Ví dụ đúng",
  NEGATIVE: "Ví dụ sai",
};

const CELL = 20;
const ROW_LABEL_WIDTH = 92;
const HEADER_HEIGHT = 16;

/** The arithmetic rail of the current law. A cell at the rail is called out. */
const RAIL = 32_767;

function colorFor(value: number, span: number): string {
  if (value === 0) return "var(--gb-surface-3)";
  const magnitude = Math.min(Math.abs(value) / span, 1);
  const alpha = 0.2 + magnitude * 0.8;
  return value > 0
    ? `color-mix(in oklab, var(--gb-primary) ${alpha * 100}%, transparent)`
    : `color-mix(in oklab, var(--gb-attention) ${alpha * 100}%, transparent)`;
}

export function HiddenHeatmap({
  vectors,
  title = "Trạng thái nội bộ theo từng chiều",
}: {
  vectors: readonly HiddenVector[];
  title?: string;
}) {
  if (vectors.length === 0) {
    return (
      <figure className="flex flex-col gap-2">
        <figcaption className="text-sm font-semibold text-ink">
          {title}
        </figcaption>
        <p className="text-sm text-ink-muted">
          Tương tác này không ghi lại trạng thái nội bộ.
        </p>
      </figure>
    );
  }

  const dim = vectors[0]?.values.length ?? 0;
  const span = Math.max(
    ...vectors.flatMap((v) => v.values.map((x) => Math.abs(x))),
    1,
  );
  const width = ROW_LABEL_WIDTH + dim * CELL;
  const height = HEADER_HEIGHT + vectors.length * CELL + 4;
  const railed = vectors.flatMap((v) =>
    v.values.filter((x) => Math.abs(x) >= RAIL),
  ).length;

  return (
    <figure className="flex flex-col gap-3">
      <figcaption className="flex flex-wrap items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">{title}</span>
        <span className="flex items-center gap-2">
          <span className="gb-num text-xs text-ink-muted">{dim} chiều</span>
          {vectors[0] ? (
            <EvidenceBadge provenance={vectors[0].provenance} />
          ) : null}
        </span>
      </figcaption>

      <svg
        role="img"
        aria-label={`${title}. ${vectors.length} hàng, ${dim} chiều. Giá trị lớn nhất theo trị tuyệt đối là ${span}.`}
        viewBox={`0 0 ${width} ${height}`}
        className="w-full"
      >
        {/* Column ruler every eighth coordinate: enough to locate a cell,
            not so much that it becomes noise. */}
        {Array.from({ length: dim }, (_, index) =>
          index % 8 === 0 ? (
            <text
              key={`h${index}`}
              x={ROW_LABEL_WIDTH + index * CELL}
              y={HEADER_HEIGHT - 5}
              fontSize="9"
              fill="var(--gb-text-muted)"
            >
              h{index}
            </text>
          ) : null,
        )}

        {vectors.map((vector, rowIndex) => {
          const y = HEADER_HEIGHT + rowIndex * CELL;
          return (
            <g key={`${vector.role}-${vector.stage}`}>
              <text
                x={ROW_LABEL_WIDTH - 8}
                y={y + CELL / 2}
                textAnchor="end"
                dominantBaseline="middle"
                fontSize="10"
                fill="var(--gb-text-muted)"
              >
                {ROLE_LABEL[vector.role]}
              </text>
              {vector.values.map((value, index) => {
                const atRail = Math.abs(value) >= RAIL;
                return (
                  <rect
                    key={index}
                    x={ROW_LABEL_WIDTH + index * CELL}
                    y={y + 2}
                    width={CELL - 2}
                    height={CELL - 4}
                    rx={2}
                    fill={colorFor(value, span)}
                    stroke={atRail ? "var(--gb-fail)" : "var(--gb-border)"}
                    strokeWidth={atRail ? 1.5 : 0.5}
                  >
                    <title>{`${ROLE_LABEL[vector.role]} h${index} = ${value}${atRail ? " (chạm giới hạn số học)" : ""}`}</title>
                  </rect>
                );
              })}
            </g>
          );
        })}
      </svg>

      <p className="text-xs text-ink-muted">
        Xanh là dương, vàng là âm, viền đỏ là chiều đã chạm giới hạn số học.
        {railed > 0 ? (
          <>
            {" "}
            Hiện có <span className="gb-num">{railed}</span> chiều chạm giới hạn.
          </>
        ) : (
          " Chưa có chiều nào chạm giới hạn."
        )}
      </p>

      <table className="gb-sr-only">
        <caption>{title}</caption>
        <thead>
          <tr>
            <th scope="col">Hàng</th>
            {Array.from({ length: dim }, (_, index) => (
              <th key={index} scope="col">
                h{index}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {vectors.map((vector) => (
            <tr key={`${vector.role}-${vector.stage}`}>
              <th scope="row">{ROLE_LABEL[vector.role]}</th>
              {vector.values.map((value, index) => (
                <td key={index}>{value}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}

export { ROLE_LABEL as hiddenRoleLabel };
