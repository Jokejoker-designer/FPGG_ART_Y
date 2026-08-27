"use client";

import { HIDDEN_DIM, usagePercent } from "@/lib/contract";
import { HealthLines } from "@/components/charts/health-lines";
import { ProcessPipeline } from "@/components/charts/process-pipeline";
import { DieMap } from "@/components/die-map";
import { ModeStrip } from "@/components/level";
import { EvidenceBadge } from "@/components/ui/evidence-badge";
import { Kpi, Panel, PanelTitle } from "@/components/ui";
import { NodeFlow, ResourceBars, Waterfall } from "@/components/viz";
import { awaiting, buildFacts, learningStatus, measured, sessionView } from "@/lib/metrics";
import { useStudio } from "@/lib/store";
import { useStudioHeader } from "@/lib/studio-header";
import { SILICON_WATERMARK } from "./session";
import { SourceBadge } from "./source-badge";

const PHASE_TAB = {
  INPUT: "input",
  ENCODE: "forward",
  COMPARE: "compare",
  LEARN: "learning",
  MEMORY: "eam",
  MODEL: "model",
  OUTPUT: "output",
} as const;

/**
 * First-viewport GlassBox surface. Same Overview/Board charts as Studio,
 * ordered so DieMap, NodeFlow and ProcessPipeline are on screen without a
 * tab bar. Charts are SYNTHETIC (hydrated fixture), never BOARD.
 */
export function GlassBoxInstrument() {
  useStudio((s) => s.session);
  const header = useStudioHeader();
  const teacherOff = useStudio((s) => s.teacherOff);
  const util = buildFacts.utilization;
  const resourceRows =
    util?.rows
      .filter((r) =>
        ["Slice LUTs", "Slice Registers", "Block RAM Tile", "DSPs"].includes(r.resource),
      )
      .map((r) => ({
        name: r.resource === "Block RAM Tile" ? "BRAM" : r.resource.replace("Slice ", ""),
        pct: usagePercent(r),
        used: r.used,
        total: r.available,
      })) ?? [];

  const waterfall = sessionView.stages.map((s) => ({
    label: s.phase,
    ms: s.durationMs?.value ?? 0,
    tab: PHASE_TAB[s.phase as keyof typeof PHASE_TAB],
  }));

  const healthProvenance = sessionView.health.points[0]?.auc?.provenance;
  const health = sessionView.health;
  const lut = util?.rows.find((r) => r.resource === "Slice LUTs");
  const bram = util?.rows.find((r) => r.resource === "Block RAM Tile");

  return (
    <div className="space-y-3">
      <ModeStrip />

      <div className="grid items-start gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle hint="Routed report" action={<SourceBadge source="SYNTHETIC" />}>
            Sơ đồ thiết bị
          </PanelTitle>
          <DieMap utilization={util} />
        </Panel>
        <div className="space-y-3">
          <Panel>
            <PanelTitle hint="valid_in → out_valid" action={<SourceBadge source="SYNTHETIC" />}>
              Luồng xử lý
            </PanelTitle>
            <NodeFlow />
          </Panel>
          <Panel>
            <PanelTitle
              hint="Đọc / Biểu diễn / So sánh / Học — fixture, không phải UART"
              action={<SourceBadge source="SYNTHETIC" />}
            >
              Tiến trình tương tác
            </PanelTitle>
            <ProcessPipeline stages={sessionView.stages} />
          </Panel>
        </div>
      </div>

      <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        <Kpi label="Board" value="Arty A7-100T" sub={header.part} tone="text-cyan" />
        <Kpi
          label="Latency"
          value={measured.latencyMs ? `${measured.latencyMs.value} ms` : "chưa đo"}
          sub={measured.latencyMs?.unit ?? "tổng các giai đoạn"}
        />
        <Kpi
          label="LUT / BRAM"
          value={lut ? `${usagePercent(lut)}%` : "—"}
          sub={
            bram
              ? `BRAM ${usagePercent(bram)}% · ${bram.used}/${bram.available}`
              : awaiting("ddrUsage").why
          }
        />
        <Kpi
          label="Learning"
          value={teacherOff ? "Teacher Off" : learningStatus()}
          sub={teacherOff ? "Không ghi trong phiên này" : header.mode}
          tone="text-learn"
        />
      </div>
      {measured.latencyMs ? <EvidenceBadge provenance={measured.latencyMs.provenance} /> : null}

      <div className="relative overflow-hidden">
        <div className="grid gap-3 lg:grid-cols-2">
          <Panel>
            <PanelTitle hint="LUT / FF / BRAM / DSP" action={<SourceBadge source="SYNTHETIC" />}>
              Mức dùng
            </PanelTitle>
            {resourceRows.length > 0 ? (
              <ResourceBars data={resourceRows} />
            ) : (
              <p className="text-sm text-muted">Chưa nạp báo cáo utilization.</p>
            )}
          </Panel>
          <Panel>
            <PanelTitle
              hint="theo số lần cập nhật"
              action={
                <span className="flex items-center gap-1.5">
                  <SourceBadge source="SYNTHETIC" />
                  {healthProvenance ? <EvidenceBadge provenance={healthProvenance} /> : null}
                </span>
              }
            >
              Sức khỏe học
            </PanelTitle>
            <HealthLines series={health} hiddenDim={HIDDEN_DIM} />
            <p className="mt-2 text-caption text-subtle">
              Kết luận chuỗi: {health.verdict}. Không vẽ token/s — lane không sinh token.
            </p>
          </Panel>
          <Panel className="lg:col-span-2">
            <PanelTitle hint="ms theo giai đoạn" action={<SourceBadge source="SYNTHETIC" />}>
              Waterfall xử lý
            </PanelTitle>
            {waterfall.length > 0 ? (
              <Waterfall rows={waterfall} />
            ) : (
              <p className="text-sm text-muted">Chưa có waterfall.</p>
            )}
          </Panel>
        </div>
        <div className="obs-watermark" aria-hidden="true">
          {SILICON_WATERMARK}
        </div>
      </div>
    </div>
  );
}
