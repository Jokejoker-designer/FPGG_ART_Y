/**
 * §11 "Embedding visualization: use compact heatmap/barcode".
 *
 * Thirty-two signed values for one byte. A barcode rather than a bar chart
 * because the reader's question is "is this row doing anything", not "what is
 * coordinate 17" — and the exact numbers are one table away for anyone who does
 * ask that.
 *
 * Diverging scale with an explicit zero mark: sign is the information, and a
 * single-hue ramp would hide it.
 *
 * Owner: gb-scientific-dataviz.
 */
import type { EmbeddingRow } from "@/lib/contract";
import { EvidenceBadge } from "@/components/ui/evidence-badge";

const CELL = 12;
const HEIGHT = 34;

function colorFor(value: number, span: number): string {
  if (value === 0) return "var(--gb-surface-3)";
  const magnitude = Math.min(Math.abs(value) / span, 1);
  /* Opacity carries magnitude, hue carries sign. Both are also in the table,
     so nothing depends on colour alone (§28). */
  const alpha = 0.25 + magnitude * 0.75;
  return value > 0
    ? `color-mix(in oklab, var(--gb-primary) ${alpha * 100}%, transparent)`
    : `color-mix(in oklab, var(--gb-attention) ${alpha * 100}%, transparent)`;
}

export function EmbeddingBarcode({
  row,
  emptyText = "Byte này chưa có hàng embedding được ghi lại.",
}: {
  row: EmbeddingRow | null;
  emptyText?: string;
}) {
  if (!row) {
    return (
      <figure className="flex flex-col gap-2">
        <figcaption className="text-sm font-semibold text-ink">
          Hàng embedding
        </figcaption>
        <p className="text-sm text-ink-muted">{emptyText}</p>
      </figure>
    );
  }

  const span = Math.max(...row.values.map((v) => Math.abs(v)), 1);
  const width = row.values.length * CELL;

  return (
    <figure className="flex flex-col gap-2">
      <figcaption className="flex flex-wrap items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">
          Hàng embedding <span className="gb-num">E[{row.byte}]</span>
        </span>
        <EvidenceBadge provenance={row.provenance} />
      </figcaption>

      <svg
        role="img"
        aria-label={`Hàng embedding của byte ${row.byte}, ${row.values.length} chiều, giá trị lớn nhất theo trị tuyệt đối là ${span}.`}
        viewBox={`0 0 ${width} ${HEIGHT}`}
        className="w-full"
        style={{ maxHeight: HEIGHT * 2 }}
      >
        {row.values.map((value, index) => (
          <rect
            key={index}
            x={index * CELL}
            y={4}
            width={CELL - 1.5}
            height={HEIGHT - 8}
            rx={1.5}
            fill={colorFor(value, span)}
            stroke="var(--gb-border)"
            strokeWidth={0.5}
          />
        ))}
      </svg>

      <p className="text-xs text-ink-muted">
        Xanh là giá trị dương, vàng là âm, ô trống là 0. Độ đậm theo độ lớn, tối
        đa <span className="gb-num">{span}</span>.
      </p>

      <table className="gb-sr-only">
        <caption>Giá trị từng chiều của hàng embedding E[{row.byte}]</caption>
        <thead>
          <tr>
            <th scope="col">Chiều</th>
            <th scope="col">Giá trị</th>
          </tr>
        </thead>
        <tbody>
          {row.values.map((value, index) => (
            <tr key={index}>
              <th scope="row">{index}</th>
              <td>{value}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
