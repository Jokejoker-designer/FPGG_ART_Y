/**
 * Device schematic for the die view.
 *
 * Ported from the imported workspace with three corrections, because the
 * original would have told an operator the opposite of the truth.
 *
 * 1. **Utilisation is real now.** The imported version generated `util` per
 *    tile from a `Math.sin` hash and painted 28-96% with hot red regions. The
 *    routed report for this design says 12.17% of LUTs, 3 of 135 block RAM
 *    tiles, and **0 of 240 DSPs**. Per-tile utilisation does not exist in any
 *    report, so it is gone; the device totals are read from the contract.
 *
 * 2. **No pblocks.** The imported version named `PBLOCK_LM`, `PBLOCK_EAM` and
 *    friends and cited "IMPL pblock" as evidence. This design has no floorplan
 *    constraints, no language model and no episode memory on this lane. Tiles
 *    are grouped by resource type, which is a real property of the device.
 *
 * 3. **No LiteScope.** Every group claimed "LiteScope GROUP …" as its evidence
 *    source. LiteScope before Native V1 freeze is a hard stop in
 *    `a7-fpga-gate`, and none exists in the bitstream.
 *
 * What survives is the good part: a schematic 7-series column mix, clock
 * regions, and a hit-testable grid. The layout is a schematic, not a bitstream
 * dump, and the view says so on screen.
 *
 * Owner: gb-scientific-dataviz.
 */
import type { DeviceUtilization, ResourceUsage } from "@/lib/contract";
import { usagePercent } from "@/lib/contract";

export type TileKind = "CLB" | "BRAM" | "DSP" | "IO" | "CMT" | "CFG";
export type DieLayer = "resource" | "util";

export interface DieTile {
  id: string;
  c: number;
  r: number;
  kind: TileKind;
  /** Clock region, schematic. */
  cr: string;
  /** Schematic site name, for orientation only. */
  site: string;
}

export const DIE_COLS = 28;
export const DIE_ROWS = 20;

/** 7-series-style column mix. Schematic, not a bitstream dump. */
const COL_KIND: TileKind[] = [
  "IO", "CLB", "CLB", "CLB", "BRAM", "CLB", "CLB", "DSP",
  "CLB", "CLB", "CLB", "BRAM", "CLB", "CMT", "CLB", "CLB",
  "DSP", "CLB", "CLB", "CLB", "BRAM", "CLB", "CLB", "DSP",
  "CLB", "CLB", "CLB", "IO",
];

function siteName(kind: TileKind, c: number, r: number): string {
  const y = r * 5 + (c % 5);
  if (kind === "BRAM") return `RAMB36_X${Math.floor(c / 8)}Y${r}`;
  if (kind === "DSP") return `DSP48_X${Math.floor(c / 9)}Y${r}`;
  if (kind === "IO") return `IOB_X${c < 14 ? 0 : 1}Y${y}`;
  if (kind === "CMT") return `MMCME2_X0Y${Math.floor(r / 5)}`;
  return `SLICE_X${c}Y${y}`;
}

export const DIE_TILES: DieTile[] = Array.from(
  { length: DIE_COLS * DIE_ROWS },
  (_, i) => {
    const c = i % DIE_COLS;
    const r = Math.floor(i / DIE_COLS);
    const kind = COL_KIND[c] ?? "CLB";
    return {
      id: `${kind}_${c}_${r}`,
      c,
      r,
      kind,
      cr: `X${c < 14 ? 0 : 1}Y${Math.min(3, Math.floor(r / 5))}`,
      site: siteName(kind, c, r),
    };
  },
);

export const CLOCK_REGIONS = [
  "X0Y0", "X0Y1", "X0Y2", "X0Y3",
  "X1Y0", "X1Y1", "X1Y2", "X1Y3",
];

/** Which report row governs a tile kind, so the legend and the fill agree. */
const KIND_TO_RESOURCE: Record<TileKind, string | null> = {
  CLB: "Slice LUTs",
  BRAM: "Block RAM Tile",
  DSP: "DSPs",
  IO: "Bonded IOB",
  CMT: "MMCME2_ADV",
  CFG: null,
};

export interface KindUsage {
  readonly kind: TileKind;
  readonly row: ResourceUsage | null;
  readonly percent: number | null;
}

export function usageForKind(
  kind: TileKind,
  utilization: DeviceUtilization | null,
): KindUsage {
  const name = KIND_TO_RESOURCE[kind];
  if (!utilization || !name) return { kind, row: null, percent: null };
  const row = utilization.rows.find((candidate) => candidate.resource === name);
  if (!row) return { kind, row: null, percent: null };
  return { kind, row, percent: usagePercent(row) };
}

/**
 * Resource-type colour. This is the layer that is always honest, because a
 * device's column mix does not depend on any measurement.
 */
export function resourceColor(kind: TileKind): string {
  switch (kind) {
    case "CLB":
      return "#3d5a73";
    case "BRAM":
      return "#2dd4bf";
    case "DSP":
      return "#fbbf24";
    case "IO":
      return "#64748b";
    case "CMT":
      return "#a78bfa";
    case "CFG":
      return "#475569";
    default: {
      const exhaustive: never = kind;
      return exhaustive;
    }
  }
}

/**
 * Fill for the utilisation layer. Device-level percentage per resource type,
 * so a resource reported as 0 used renders as visibly unused rather than as a
 * warm tile. That is what makes `DSPs 0/240` readable at a glance.
 */
export function utilFill(percent: number | null): string {
  if (percent === null) return "rgba(109,123,138,0.14)";
  if (percent === 0) return "rgba(109,123,138,0.10)";
  if (percent < 5) return `rgba(34,211,238,${0.18 + percent / 40})`;
  if (percent < 20) return `rgba(52,211,153,${0.3 + percent / 120})`;
  if (percent < 50) return `rgba(251,191,36,${0.4 + percent / 200})`;
  return `rgba(248,113,113,${0.5 + percent / 400})`;
}

/** §28: the layer legend states the numbers, so colour is never the only cue. */
export function utilLegend(
  utilization: DeviceUtilization | null,
): Array<{ label: string; color: string; detail: string }> {
  const kinds: TileKind[] = ["CLB", "BRAM", "DSP", "IO", "CMT"];
  return kinds.map((kind) => {
    const usage = usageForKind(kind, utilization);
    return {
      label: kind,
      color: utilFill(usage.percent),
      detail: usage.row
        ? `${usage.row.used}/${usage.row.available} · ${usage.percent}%`
        : "chưa nạp báo cáo",
    };
  });
}
