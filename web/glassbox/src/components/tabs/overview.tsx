import { usagePercent } from "@/lib/contract";
import { awaiting, buildFacts, learningStatus, measured, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { formatInt } from "@/lib/utils";
import { useStudio } from "@/lib/store";
import { HealthLines } from "../charts/health-lines";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Btn, Kpi, Panel, PanelTitle, Pill } from "../ui";
import { NodeFlow, ResourceBars, Waterfall } from "../viz";

/**
 * Tổng quan (§9).
 *
 * The imported KPI row claimed LM-06, token/s, EAM hit rate and DDR occupancy
 * as if they were live board measurements. The 03E lane has no language model
 * and no episode memory; those slots now name the missing signal instead of
 * inventing a percentage.
 *
 * Owner: gb-ux-product.
 */
const PHASE_TAB: Record<string, "input" | "forward" | "compare" | "learning" | "eam" | "model" | "output" | "live"> = {
  INPUT: "input",
  ENCODE: "forward",
  COMPARE: "compare",
  LEARN: "learning",
  MEMORY: "eam",
  MODEL: "model",
  OUTPUT: "output",
};

const STAGE_LABEL_RTL: Record<string, string> = {
  INPUT: "valid_in",
  ENCODE: "mac_valid",
  COMPARE: "margin_ok",
  LEARN: "upd_en",
  MEMORY: "axi_hit",
  MODEL: "lm_ready",
  OUTPUT: "out_valid",
};

export function OverviewTab() {
  const { startReplay, teacherOff, level } = useStudio();
  const header = useStudioHeader();
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
    tab: PHASE_TAB[s.phase],
  }));

  const changed = measured.weightsChanged;
  const episode = sessionView.retrieval?.selectedEpisodeId ?? null;
  const health = sessionView.health;
  const lut = util?.rows.find((r) => r.resource === "Slice LUTs");
  const bram = util?.rows.find((r) => r.resource === "Block RAM Tile");

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        <span className="text-[13px] text-muted">{header.sourceNote}</span>
      </div>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi label="Bo mạch" value="Arty A7" sub="chip Artix-7" tone="text-cyan" />
            <Kpi
              label="Tốc độ trả lời"
              value={measured.latencyMs ? `${measured.latencyMs.value} ms` : "chưa đo"}
              sub={measured.latencyMs?.provenance.source}
              tone="text-ok"
            />
            {measured.latencyMs ? <EvidenceBadge provenance={measured.latencyMs.provenance} /> : null}
            <Kpi
              label="Vừa học?"
              value={changed && changed.value > 0 ? "Có" : "Không"}
              sub={changed ? `${changed.value} chỗ được chỉnh` : "không có sự kiện học"}
              tone="text-learn"
            />
            {changed ? <EvidenceBadge provenance={changed.provenance} /> : null}
            <Kpi
              label="Nhớ ra chưa?"
              value={episode ? "Fixture có" : "Không"}
              sub={
                episode
                  ? `Ký ức #${episode} · SYNTHETIC · 03E không có EAM`
                  : awaiting("eamHitRate").why
              }
              tone="text-mem"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4 2xl:grid-cols-7">
            <Kpi label="Board" value="Arty A7-100T" sub={header.part} tone="text-cyan" />
            <Kpi
              label="Encoder"
              value={`${formatInt(buildFacts.paramsEncoder)}`}
              sub={`luật ${buildFacts.learningLawId}`}
            />
            <Kpi
              label="Token/s"
              value="—"
              sub={`${awaiting("tokenPerSec").label}: ${awaiting("tokenPerSec").needs}`}
            />
            <Kpi
              label="Latency"
              value={measured.latencyMs ? `${measured.latencyMs.value} ms` : "chưa đo"}
              sub={measured.latencyMs?.unit ?? "tổng các giai đoạn"}
            />
            {measured.latencyMs ? <EvidenceBadge provenance={measured.latencyMs.provenance} /> : null}
            <Kpi
              label="EAM Hit Rate"
              value="—"
              sub={awaiting("eamHitRate").why}
            />
            <Kpi
              label="DDR Usage"
              value="—"
              sub={awaiting("ddrUsage").why}
            />
            <Kpi
              label="Learning"
              value={teacherOff ? "Teacher Off" : learningStatus()}
              sub={teacherOff ? "Không ghi trong phiên này" : header.mode}
              tone="text-learn"
            />
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4 2xl:grid-cols-7">
            <Kpi label="clk" value={String(buildFacts.clockMhz)} sub="MHz" tone="text-cyan" />
            <Kpi
              label="WNS"
              value={
                buildFacts.wnsNs === null
                  ? "chưa đo"
                  : `${buildFacts.wnsNs > 0 ? "+" : ""}${buildFacts.wnsNs}`
              }
              sub="ns · route report"
              tone="text-ok"
            />
            <Kpi
              label="cycle"
              value={
                sessionView.outputEvents.at(-1)?.cycle?.toLocaleString("en-US") ?? "—"
              }
              sub="selected · SYNTHETIC"
            />
            <Kpi
              label="LUT"
              value={lut ? `${usagePercent(lut)}%` : "—"}
              sub={lut ? `${lut.used} / ${lut.available}` : undefined}
            />
            <Kpi
              label="BRAM"
              value={bram ? `${usagePercent(bram)}%` : "—"}
              sub={bram ? `${bram.used} / ${bram.available}` : undefined}
            />
            <Kpi
              label="bitstream"
              value={buildFacts.bitstreamSha256 ? buildFacts.bitstreamSha256.slice(0, 8) : "chưa gắn"}
              sub={buildFacts.modelVersion}
            />
            <Kpi
              label="upd_en"
              value={measured.updateEnabled ? "1" : "0"}
              sub={`${changed ? changed.value : 0} wr`}
              tone="text-learn"
            />
          </div>
        }
      />

      <Panel>
        <PanelTitle
          hint={
            level === "easy"
              ? "Câu chuyện của lần chạy này"
              : level === "rtl"
                ? "valid_in → out_valid"
                : teacherOff
                  ? "Teacher-off"
                  : "Teacher-on"
          }
          action={
            <Btn className="h-8 text-xs" onClick={startReplay}>
              Replay
            </Btn>
          }
        >
          {level === "rtl" ? "Pipeline strobes" : "Luồng xử lý"}
        </PanelTitle>
        <NodeFlow />
      </Panel>

      <When
        easy={
          <Panel>
            <PanelTitle>Chuyện gì vừa xảy ra</PanelTitle>
            <p className="text-base font-medium">{header.question}</p>
            <ol className="mt-3 space-y-2">
              <li className="flex gap-3 text-[13px] text-muted">
                <span className="font-mono text-cyan">1.</span>
                Câu hỏi đã được ghi. Lane 03E không sinh câu trả lời ngôn ngữ.
              </li>
              <li className="flex gap-3 text-[13px] text-muted">
                <span className="font-mono text-cyan">2.</span>
                {sessionView.compare
                  ? `So sánh: d_pos ${measured.dPos?.value ?? "—"}, d_neg ${measured.dNeg?.value ?? "—"}.`
                  : "Không có sự kiện so sánh."}
              </li>
              <li className="flex gap-3 text-[13px] text-muted">
                <span className="font-mono text-cyan">3.</span>
                {changed
                  ? `${changed.value} giá trị được ghi. Nguồn ${changed.provenance.source}.`
                  : "Không có lần ghi trọng số."}
              </li>
            </ol>
          </Panel>
        }
        research={
          <div className="grid gap-3 lg:grid-cols-[1.2fr_1fr]">
            <Panel>
              <PanelTitle hint="ms theo giai đoạn">Waterfall xử lý</PanelTitle>
              <Waterfall rows={waterfall} />
            </Panel>
            <Panel>
              <PanelTitle>Trạng thái hiện tại</PanelTitle>
              <div className="grid grid-cols-2 gap-3 text-[13px]">
                <div>
                  <div className="text-caption text-subtle">Câu hỏi</div>
                  <div className="mt-1">{header.question}</div>
                </div>
                <div>
                  <div className="text-caption text-subtle">Trả lời</div>
                  <div className="mt-1">
                    {header.answer ?? "Không có — lane này không có mô hình ngôn ngữ"}
                  </div>
                </div>
                <div>
                  <div className="text-caption text-subtle">Δw</div>
                  <div className="mt-1 font-mono tabular">{changed ? changed.value : "—"}</div>
                </div>
                <div>
                  <div className="text-caption text-subtle">Episode</div>
                  <div className="mt-1 font-mono">
                    {episode ? `#${episode} SYNTHETIC` : "không có trên 03E"}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        }
        rtl={
          <Panel>
            <PanelTitle hint={`${buildFacts.clockMhz} MHz`}>Cycle budget</PanelTitle>
            <table className="w-full text-left text-xs">
              <thead className="text-subtle">
                <tr>
                  <th className="py-1">Strobe</th>
                  <th>ms</th>
                  <th>state</th>
                </tr>
              </thead>
              <tbody>
                {sessionView.stages.map((s) => (
                  <tr key={s.phase} className="border-t border-line font-mono">
                    <td className="py-1.5 text-cyan">{STAGE_LABEL_RTL[s.phase] ?? s.phase}</td>
                    <td>{s.durationMs ? s.durationMs.value.toFixed(1) : "—"}</td>
                    <td>{s.state}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Panel>
        }
      />

      <When
        easy={null}
        research={
          <div className="grid gap-3 lg:grid-cols-2">
            <Panel>
              <PanelTitle hint="theo số lần cập nhật">Sức khỏe học</PanelTitle>
              <HealthLines series={health} hiddenDim={buildFacts.hiddenDim} />
              <p className="mt-2 text-caption text-subtle">
                Kết luận chuỗi: {health.verdict}. Không vẽ token/s — lane không sinh token.
              </p>
            </Panel>
            <Panel>
              <PanelTitle>Tài nguyên phần cứng</PanelTitle>
              {resourceRows.length > 0 ? (
                <ResourceBars data={resourceRows} />
              ) : (
                <p className="text-[13px] text-muted">Chưa có báo cáo utilisation.</p>
              )}
              <p className="mt-2 text-caption text-subtle">
                {util?.reportPath ?? "không có report"} · DSP phải là 0 trên luật hiện tại
              </p>
            </Panel>
          </div>
        }
        rtl={
          <Panel>
            <PanelTitle>Resource (impl)</PanelTitle>
            {resourceRows.length > 0 ? <ResourceBars data={resourceRows} /> : null}
            <p className="mt-2 text-caption text-subtle">
              bitstream {buildFacts.bitstreamSha256 ?? "null"} · TNS {buildFacts.tnsNs ?? "—"}
            </p>
          </Panel>
        }
      />
    </div>
  );
}
