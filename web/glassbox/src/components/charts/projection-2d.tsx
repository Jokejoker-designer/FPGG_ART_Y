/**
 * §8.1 "Representation relationship → 2D projection with `MINH HỌA 2D` badge".
 *
 * The badge and the tooltip are not decoration: a two-dimensional picture of a
 * thirty-two dimensional state is the single easiest place in this product to
 * mislead someone. The badge is rendered unconditionally, the method is stated
 * on screen, and the provenance is structurally forced to `DERIVED` by the
 * contract.
 *
 * Owner: gb-scientific-dataviz.
 */
import type { HiddenStage, Projection2D as Projection } from "@/lib/contract";
import { EvidenceBadge } from "@/components/ui/evidence-badge";
import { hiddenRoleLabel } from "./hidden-heatmap";

const SIZE = 260;
const PAD = 26;

const ROLE_TOKEN = {
  ANCHOR: "var(--gb-primary)",
  POSITIVE: "var(--gb-pass)",
  NEGATIVE: "var(--gb-fail)",
} as const;

/** §28: shape distinguishes the roles, so colour is never the only channel. */
function marker(role: keyof typeof ROLE_TOKEN, x: number, y: number) {
  switch (role) {
    case "ANCHOR":
      return <circle cx={x} cy={y} r={6} />;
    case "POSITIVE":
      return (
        <polygon points={`${x},${y - 7} ${x + 6},${y + 5} ${x - 6},${y + 5}`} />
      );
    case "NEGATIVE":
      return (
        <rect x={x - 5.5} y={y - 5.5} width={11} height={11} rx={1.5} />
      );
    default: {
      const exhaustive: never = role;
      return exhaustive;
    }
  }
}

export function Projection2DChart({
  projection,
  stage,
}: {
  projection: Projection | null;
  /** Which recorded state to draw. */
  stage: HiddenStage;
}) {
  if (!projection) {
    return (
      <figure className="flex flex-col gap-2">
        <figcaption className="text-sm font-semibold text-ink">
          Quan hệ giữa ba trạng thái
        </figcaption>
        <p className="text-sm text-ink-muted">
          Chưa đủ trạng thái nội bộ để dựng hình chiếu.
        </p>
      </figure>
    );
  }

  const points = projection.points.filter((point) => point.stage === stage);
  const toPixel = (value: number) =>
    PAD + ((value + 1) / 2) * (SIZE - PAD * 2);

  return (
    <figure className="flex flex-col gap-3">
      <figcaption className="flex flex-wrap items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">
          Quan hệ giữa ba trạng thái
        </span>
        <span className="flex items-center gap-2">
          <span
            className="rounded-pill border px-2 py-0.5 text-[10px] font-semibold tracking-wider"
            style={{
              color: "var(--gb-attention)",
              borderColor: "var(--gb-attention)",
            }}
            title="Quyết định thực tế được tính trên vector đầy đủ trong FPGA."
          >
            MINH HỌA 2D
          </span>
          <EvidenceBadge provenance={projection.provenance} />
        </span>
      </figcaption>

      {points.length === 0 ? (
        <p className="text-sm text-ink-muted">
          Trạng thái này chưa được ghi lại cho tương tác đang xem.
        </p>
      ) : (
        <svg
          role="img"
          aria-label={`Hình chiếu hai chiều minh họa của ${points.length} trạng thái. Quyết định thực tế được tính trên vector đầy đủ.`}
          viewBox={`0 0 ${SIZE} ${SIZE}`}
          style={{ maxWidth: SIZE }}
          className="w-full"
        >
          <rect
            x={0.5}
            y={0.5}
            width={SIZE - 1}
            height={SIZE - 1}
            rx={8}
            fill="var(--gb-surface-2)"
            stroke="var(--gb-border)"
          />
          <line
            x1={PAD}
            y1={SIZE / 2}
            x2={SIZE - PAD}
            y2={SIZE / 2}
            stroke="var(--gb-border)"
            strokeDasharray="2 3"
          />
          <line
            x1={SIZE / 2}
            y1={PAD}
            x2={SIZE / 2}
            y2={SIZE - PAD}
            stroke="var(--gb-border)"
            strokeDasharray="2 3"
          />

          {points.map((point) => {
            const x = toPixel(point.x);
            const y = SIZE - toPixel(point.y);
            return (
              <g key={point.role} fill={ROLE_TOKEN[point.role]}>
                {marker(point.role, x, y)}
                <text
                  x={x + 10}
                  y={y + 4}
                  fontSize="10"
                  fill="var(--gb-text-muted)"
                >
                  {hiddenRoleLabel[point.role]}
                </text>
              </g>
            );
          })}
        </svg>
      )}

      <p className="text-xs leading-relaxed text-ink-muted">
        {projection.method} Quyết định thực tế được tính trên vector đầy đủ
        trong FPGA.
      </p>

      <table className="gb-sr-only">
        <caption>Toạ độ hình chiếu minh họa</caption>
        <thead>
          <tr>
            <th scope="col">Trạng thái</th>
            <th scope="col">Trục 1</th>
            <th scope="col">Trục 2</th>
          </tr>
        </thead>
        <tbody>
          {points.map((point) => (
            <tr key={point.role}>
              <th scope="row">{hiddenRoleLabel[point.role]}</th>
              <td>{point.x}</td>
              <td>{point.y}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
