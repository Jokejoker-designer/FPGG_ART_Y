import { useMemo, useState } from "react";
import type { HiddenStage } from "@/lib/contract";
import { buildFacts, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { HiddenHeatmap } from "../charts/hidden-heatmap";
import { Projection2DChart } from "../charts/projection-2d";
import { Explain } from "../explain";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Kpi, Panel, PanelTitle, Pill } from "../ui";

/**
 * Biểu diễn (§12).
 *
 * This tab answers how input became internal state. It does not rank output
 * tokens and does not claim a dimension has a meaning. Before/after uses two
 * recorded stages; if AFTER_UPDATE is absent the toggle is disabled.
 *
 * Owner: gb-ux-product.
 */
export function ForwardTab() {
  const { level } = useStudio();
  const header = useStudioHeader();
  const all = sessionView.representation;
  const hasAfter = all.some((v) => v.stage === "AFTER_UPDATE");
  const [stage, setStage] = useState<HiddenStage>("BEFORE_UPDATE");
  const effectiveStage: HiddenStage = hasAfter ? stage : "BEFORE_UPDATE";
  const vectors = useMemo(
    () => all.filter((v) => v.stage === effectiveStage),
    [all, effectiveStage],
  );
  const anchor = vectors.find((v) => v.role === "ANCHOR") ?? vectors[0] ?? null;

  if (all.length === 0) {
    return (
      <Panel>
        <PanelTitle>Chưa có biểu diễn</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi trạng thái nội bộ. Không vẽ heatmap giả.
        </p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        {anchor ? <EvidenceBadge provenance={anchor.provenance} /> : null}
        <div className="ml-auto flex rounded-lg border border-line p-0.5">
          <button
            type="button"
            onClick={() => setStage("BEFORE_UPDATE")}
            className={
              effectiveStage === "BEFORE_UPDATE"
                ? "rounded-md bg-cyan/15 px-2 py-1 text-caption text-cyan"
                : "rounded-md px-2 py-1 text-caption text-muted"
            }
          >
            Trước khi học
          </button>
          <button
            type="button"
            disabled={!hasAfter}
            onClick={() => setStage("AFTER_UPDATE")}
            className={
              effectiveStage === "AFTER_UPDATE"
                ? "rounded-md bg-learn/15 px-2 py-1 text-caption text-learn"
                : "rounded-md px-2 py-1 text-caption text-muted disabled:opacity-40"
            }
          >
            Sau khi học
          </button>
        </div>
      </div>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <Kpi label="Độ phức tạp bên trong" value={`${buildFacts.hiddenDim} số`} sub="không phải chữ" />
            <Kpi
              label="Các số còn khác nhau?"
              value={
                anchor?.effectiveRank
                  ? anchor.effectiveRank.value <= 4
                    ? "Gần như không"
                    : "Có"
                  : "Chưa đo"
              }
              sub={
                anchor?.effectiveRank
                  ? `rank ${anchor.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : undefined
              }
              tone={
                anchor?.effectiveRank && anchor.effectiveRank.value <= 4 ? "text-bad" : "text-ok"
              }
            />
            <Kpi
              label="Có bị kẹt số không?"
              value={
                anchor?.saturation
                  ? `${(anchor.saturation.value * 100).toFixed(1)}%`
                  : "chưa đo"
              }
              sub="tỉ lệ chạm trần số học"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            <Kpi label="Chiều" value={String(buildFacts.hiddenDim)} />
            <Kpi
              label="Max |h|"
              value={anchor?.maxAbs ? String(anchor.maxAbs.value) : "chưa đo"}
              sub={anchor?.maxAbs?.provenance.source}
            />
            <Kpi
              label="Mean |h|"
              value={anchor?.meanAbs ? String(anchor.meanAbs.value) : "chưa đo"}
              sub={anchor?.meanAbs?.provenance.source}
            />
            <Kpi
              label="Saturation"
              value={
                anchor?.saturation
                  ? `${(anchor.saturation.value * 100).toFixed(1)}%`
                  : "chưa đo"
              }
            />
            <Kpi
              label="Effective rank"
              value={
                anchor?.effectiveRank
                  ? `${anchor.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : "chưa đo"
              }
              tone={
                anchor?.effectiveRank && anchor.effectiveRank.value <= 4 ? "text-bad" : "text-ok"
              }
            />
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi label="h_idx" value="[4:0]" sub="32 lanes" />
            <Kpi
              label="max_abs"
              value={anchor?.maxAbs ? String(anchor.maxAbs.value) : "—"}
            />
            <Kpi
              label="sat"
              value={anchor?.saturation ? anchor.saturation.value.toFixed(3) : "—"}
            />
            <Kpi
              label="rank"
              value={anchor?.effectiveRank ? String(anchor.effectiveRank.value) : "—"}
            />
          </div>
        }
      />

      <Panel>
        <PanelTitle
          hint={level === "rtl" ? "h[31:0]" : "Không gán nghĩa cho từng chiều"}
          action={level !== "easy" ? <Explain id="rank" /> : undefined}
        >
          {level === "easy" ? "AI đang biến câu thành số" : "Trạng thái nội bộ"}
        </PanelTitle>
        {level === "easy" ? (
          <p className="mb-3 text-[13px] leading-relaxed text-muted">
            Câu được nén thành {buildFacts.hiddenDim} ô. Ô sáng hơn là số lớn hơn. Không chiều nào
            mang một nghĩa tiếng Việt riêng.
          </p>
        ) : null}
        <HiddenHeatmap vectors={vectors} />
      </Panel>

      <When
        easy={null}
        research={
          <Panel>
            <PanelTitle hint="MINH HỌA 2D">Quan hệ A / P / N</PanelTitle>
            <Projection2DChart projection={sessionView.projection} stage={effectiveStage} />
          </Panel>
        }
        rtl={
          <Panel>
            <PanelTitle hint="projection DERIVED">A / P / N</PanelTitle>
            <Projection2DChart projection={sessionView.projection} stage={effectiveStage} />
          </Panel>
        }
      />
    </div>
  );
}
