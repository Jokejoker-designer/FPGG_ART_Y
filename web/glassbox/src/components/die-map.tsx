/**
 * Device floorplan view for the Board tab.
 *
 * Two layers, both honest. `resource` shows the device's column mix, which is a
 * property of the silicon and needs no measurement. `util` shades each resource
 * type by the **device-level** percentage from the routed report, so a resource
 * with zero instances renders as unused. For this design that is immediately
 * legible: the DSP columns stay dark, because the report says 0 of 240.
 *
 * There is no activity layer. The imported version animated tiles from a replay
 * timer and cited "chiếu strobe LiteScope (BOARD)". No LiteScope exists, and
 * §8.2 forbids animation that is not driven by real data. When a telemetry
 * plane exists on silicon, an activity layer can be added against it.
 *
 * Owner: gb-scientific-dataviz.
 */
import { useState } from "react";
import type { DeviceUtilization } from "@/lib/contract";
import {
  CLOCK_REGIONS,
  DIE_COLS,
  DIE_ROWS,
  DIE_TILES,
  resourceColor,
  usageForKind,
  utilFill,
  utilLegend,
  type DieLayer,
  type DieTile,
} from "@/lib/die";
import { Btn, Panel, PanelTitle, Pill } from "./ui";

const CW = 18;
const CH = 14;
const PAD_L = 36;
const PAD_T = 22;
const W = PAD_L + DIE_COLS * CW + 8;
const H = PAD_T + DIE_ROWS * CH + 22;

export function DieMap({
  utilization,
  compact = false,
}: {
  utilization: DeviceUtilization | null;
  compact?: boolean;
}) {
  const [layer, setLayer] = useState<DieLayer>("resource");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selected = DIE_TILES.find((t) => t.id === selectedId) ?? null;
  const legend = utilLegend(utilization);

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        {(
          [
            ["resource", "Tài nguyên"],
            ["util", "Mức dùng"],
          ] as const
        ).map(([id, label]) => (
          <Btn
            key={id}
            variant={layer === id ? "primary" : "ghost"}
            className="h-8 text-xs"
            onClick={() => setLayer(id)}
          >
            {label}
          </Btn>
        ))}
        {utilization ? (
          <Pill tone="cyan">{utilization.part}</Pill>
        ) : (
          <Pill tone="warn">chưa nạp báo cáo</Pill>
        )}
      </div>

      <div className="overflow-x-auto rounded-xl border border-line bg-[#070b10]">
        <svg
          viewBox={`0 0 ${W} ${H}`}
          className="w-full"
          style={{ minHeight: compact ? 220 : 320 }}
          role="img"
          aria-label={
            utilization
              ? `Sơ đồ tài nguyên ${utilization.part}. Mức dùng đọc từ báo cáo route.`
              : "Sơ đồ tài nguyên thiết bị. Chưa nạp báo cáo mức dùng."
          }
        >
          <rect width={W} height={H} fill="#070b10" />

          {CLOCK_REGIONS.map((cr) => {
            const x = cr.startsWith("X0") ? 0 : 14;
            const y = Number(cr.slice(-1));
            return (
              <g key={cr}>
                <rect
                  x={PAD_L + x * CW}
                  y={PAD_T + (DIE_ROWS - (y + 1) * 5) * CH}
                  width={14 * CW}
                  height={5 * CH}
                  fill="none"
                  stroke="#243040"
                  strokeDasharray="3 3"
                />
                <text
                  x={PAD_L + x * CW + 4}
                  y={PAD_T + (DIE_ROWS - (y + 1) * 5) * CH + 10}
                  fill="#8b99a9"
                  fontSize="7"
                  fontFamily="IBM Plex Mono"
                >
                  {cr}
                </text>
              </g>
            );
          })}

          {DIE_TILES.map((t) => {
            const usage = usageForKind(t.kind, utilization);
            const fill =
              layer === "resource"
                ? resourceColor(t.kind)
                : utilFill(usage.percent);
            const x = PAD_L + t.c * CW;
            const y = PAD_T + (DIE_ROWS - 1 - t.r) * CH;
            return (
              <rect
                key={t.id}
                x={x + 0.6}
                y={y + 0.6}
                width={CW - 1.2}
                height={CH - 1.2}
                rx={1.2}
                fill={fill}
                stroke={selectedId === t.id ? "#e8eef4" : "transparent"}
                strokeWidth={selectedId === t.id ? 1.2 : 0}
                style={{ cursor: "pointer" }}
                onClick={() => setSelectedId(t.id)}
              >
                <title>
                  {t.site} · {t.cr} · {t.kind}
                  {usage.row
                    ? ` · ${t.kind} toàn thiết bị ${usage.row.used}/${usage.row.available}`
                    : ""}
                </title>
              </rect>
            );
          })}

          <text x={PAD_L} y={14} fill="#8b99a9" fontSize="8" fontFamily="IBM Plex Sans">
            {utilization?.part ?? "thiết bị"} · sơ đồ cột · Y↑
          </text>
        </svg>
      </div>

      <div className="flex flex-wrap gap-3 text-caption text-muted">
        {layer === "resource" ? (
          (["CLB", "BRAM", "DSP", "IO", "CMT"] as const).map((kind) => (
            <Legend key={kind} c={resourceColor(kind)} t={kind} />
          ))
        ) : (
          legend.map((row) => (
            <Legend
              key={row.label}
              c={row.color}
              t={`${row.label} ${row.detail}`}
            />
          ))
        )}
      </div>

      {selected ? (
        <TileCard tile={selected} utilization={utilization} />
      ) : null}

      {/* The imported footnote already made the right disclaimer about thermal
          heatmaps; the LiteScope claim beside it did not survive. */}
      <p className="text-caption leading-relaxed text-subtle">
        Đây là sơ đồ chỗ ngồi của tài nguyên trên chip, không phải ảnh nhiệt —
        XADC chỉ có một cảm biến die, và không có số toggle-rate cho từng CLB.
        Lưới cột là sơ đồ, không phải bản đổ bitstream. Mức dùng là số toàn
        thiết bị đọc từ{" "}
        <span className="font-mono">
          {utilization?.reportPath ?? "chưa có báo cáo"}
        </span>
        , không phải số theo từng ô.
      </p>
    </div>
  );
}

function Legend({ c, t }: { c: string; t: string }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <i className="size-2 rounded-sm" style={{ background: c }} />
      {t}
    </span>
  );
}

function TileCard({
  tile,
  utilization,
}: {
  tile: DieTile;
  utilization: DeviceUtilization | null;
}) {
  const usage = usageForKind(tile.kind, utilization);
  return (
    <Panel>
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono text-sm text-cyan">{tile.site}</span>
        <Pill>{tile.kind}</Pill>
        <Pill>{tile.cr}</Pill>
      </div>
      <dl className="mt-2 grid gap-1 text-xs sm:grid-cols-2">
        <div className="flex justify-between gap-3">
          <dt className="text-muted">{tile.kind} toàn thiết bị</dt>
          <dd className="font-mono tabular">
            {usage.row
              ? `${usage.row.used}/${usage.row.available} · ${usage.percent}%`
              : "chưa nạp báo cáo"}
          </dd>
        </div>
        <div className="flex justify-between gap-3">
          <dt className="text-muted">Vùng đồng hồ</dt>
          <dd className="font-mono">{tile.cr}</dd>
        </div>
        <div className="sm:col-span-2 text-muted">
          {usage.row?.used === 0
            ? `Thiết kế không dùng ${tile.kind} nào. Ô này trống trên bitstream hiện tại.`
            : "Không có số theo từng ô: báo cáo route chỉ cho tổng theo loại tài nguyên."}
        </div>
      </dl>
    </Panel>
  );
}

export function DieUtilizationTable({
  utilization,
}: {
  utilization: DeviceUtilization | null;
}) {
  if (!utilization) {
    return (
      <Panel>
        <PanelTitle>Mức dùng thiết bị</PanelTitle>
        <p className="text-sm text-muted">
          Chưa nạp báo cáo route nào, nên không có số mức dùng để hiện.
        </p>
      </Panel>
    );
  }

  return (
    <Panel>
      <PanelTitle>Mức dùng thiết bị</PanelTitle>
      <p className="mb-2 text-caption text-subtle">
        Đọc từ <span className="font-mono">{utilization.reportPath}</span>
      </p>
      <table className="w-full text-xs">
        <thead>
          <tr className="text-left text-muted">
            <th scope="col" className="py-1">Tài nguyên</th>
            <th scope="col" className="py-1 text-right">Dùng</th>
            <th scope="col" className="py-1 text-right">Có</th>
            <th scope="col" className="py-1 text-right">%</th>
          </tr>
        </thead>
        <tbody className="font-mono tabular">
          {utilization.rows.map((row) => {
            const pct = Number(((row.used / row.available) * 100).toFixed(2));
            return (
              <tr key={row.resource} className="border-t border-line">
                <th scope="row" className="py-1 font-sans font-normal text-fg">
                  {row.resource}
                </th>
                <td className="py-1 text-right">{row.used}</td>
                <td className="py-1 text-right text-muted">{row.available}</td>
                <td
                  className="py-1 text-right"
                  style={{ color: row.used === 0 ? "var(--color-subtle)" : undefined }}
                >
                  {pct}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </Panel>
  );
}
