import { topicForTab } from "@/lib/explain-rules";
import { awaiting, buildFacts, measured, outputSelection, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { cn } from "@/lib/utils";
import { Explain } from "./explain";
import { EvidenceBadge } from "./ui/evidence-badge";
import { Btn, Panel, PanelTitle, Pill, Row } from "./ui";

/**
 * Insight rail (§22). Reads the same measured/session view as the tabs so a
 * number here cannot contradict the tab it sits beside.
 *
 * Owner: gb-ux-product.
 */
const HEALTH_LINE: Record<string, string> = {
  HEALTHY: "Các trạng thái bên trong vẫn khác nhau.",
  WATCH: "Có dấu hiệu các trạng thái đang giống nhau dần.",
  COLLAPSING: "Rank đang rơi, saturation đang tăng. Khả năng phân biệt đang mất.",
  COLLAPSED: "Representation đã sụp. Rank gần 1, AUC về mức ngẫu nhiên.",
  UNKNOWN: "Chưa đủ số đo để kết luận.",
};

export function InsightRail() {
  const { tab, insightOpen, setInsightOpen } = useStudio();
  const header = useStudioHeader();
  return (
    <>
      {insightOpen ? (
        <button
          type="button"
          className="gb-insight-backdrop fixed inset-0 z-30 bg-black/50"
          aria-label="Đóng insight"
          onClick={() => setInsightOpen(false)}
        />
      ) : null}
    <aside
      data-testid="insight-rail"
      className={cn(
        "gb-insight-rail fixed inset-y-0 right-0 z-40 w-80 overflow-y-auto border-l border-line bg-surface p-3 gbx-scroll transition-transform duration-200",
        insightOpen ? "gb-insight-rail-open translate-x-0" : "translate-x-full",
      )}
    >
      <div className="mb-3 flex items-center justify-between">
        <h2 className="text-sm font-medium">Insight nhanh</h2>
        <div className="flex items-center gap-2">
          <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
          <Btn className="gb-insight-close h-8" onClick={() => setInsightOpen(false)} aria-label="Đóng insight">
            Đóng
          </Btn>
        </div>
      </div>
      <div className="mb-3">
        <Explain id={topicForTab(tab)} />
      </div>
      {tab === "overview" || tab === "live" ? <LiveInsight /> : null}
      {tab === "input" ? <InputInsight /> : null}
      {tab === "forward" ? <ForwardInsight /> : null}
      {tab === "compare" ? <CompareInsight /> : null}
      {tab === "learning" ? <LearnInsight /> : null}
      {tab === "eam" ? <MemInsight /> : null}
      {tab === "model" ? <ModelInsight /> : null}
      {tab === "output" ? <OutputInsight /> : null}
      {tab === "waveform" ? <WaveInsight /> : null}
      {tab === "metrics" ? <HealthInsight /> : null}
      {tab === "experiments" ? <ExpInsight /> : null}
      {tab === "board" ? <BoardInsight /> : null}
      {tab === "evidence" ? <EvInsight /> : null}
      {tab === "settings" ? <SetInsight /> : null}
    </aside>
    </>
  );
}

function LiveInsight() {
  const { setTab, level } = useStudio();
  const header = useStudioHeader();
  const last = sessionView.outputEvents.at(-1);
  if (level === "easy") {
    return (
      <Panel>
        <PanelTitle>Tóm tắt</PanelTitle>
        <p className="text-sm">{header.question}</p>
        <p className="mt-2 text-[13px] text-muted">
          {header.answer
            ? `Câu trả lời đã ghi: ${header.answer}. Lane 03E không sinh ngôn ngữ.`
            : "Không có câu trả lời — lane này không có mô hình ngôn ngữ."}
        </p>
        <p className="mt-3 text-[13px] text-muted">
          Đây không phải FPGA đang stream realtime. Bạn đang xem Interaction #{header.id}.
        </p>
        <div className="mt-3 flex gap-2">
          <Btn variant="primary" className="flex-1" onClick={() => setTab("live")}>
            Mở hội thoại
          </Btn>
        </div>
      </Panel>
    );
  }
  if (level === "rtl") {
    return (
      <Panel>
        <PanelTitle>out_valid</PanelTitle>
        <dl>
          <Row k="token_sel" v={outputSelection.token ?? "—"} />
          <Row
            k="cycle"
            v={outputSelection.cycle === null ? "—" : outputSelection.cycle.toLocaleString("en-US")}
          />
          <Row k="clk" v={header.clock} />
          <Row k="upd_en" v={measured.updateEnabled ? "1" : "0"} />
        </dl>
      </Panel>
    );
  }
  return (
    <div className="space-y-3">
      <Panel>
        <PanelTitle>Câu hỏi hiện tại</PanelTitle>
        <p className="text-sm">{header.question}</p>
        <p className="mt-2 text-[13px] text-muted">
          {header.answer ?? "Không có câu trả lời từ bo."}
        </p>
        <div className="mt-3 rounded-lg border border-line bg-raised p-3">
          <div className="text-xs font-medium">
            {measured.weightsChanged && measured.weightsChanged.value > 0
              ? "Phiên này có lần ghi trọng số."
              : "Phiên này không ghi trọng số."}
          </div>
          <div className="mt-1 text-caption text-muted">
            {measured.weightsChanged
              ? `${measured.weightsChanged.value} giá trị · ${measured.weightsChanged.provenance.source}`
              : "không có sự kiện học"}
          </div>
        </div>
        <div className="mt-3 flex gap-2">
          <Btn variant="primary" className="flex-1" onClick={() => setTab("live")}>
            Xem chi tiết
          </Btn>
          <Btn className="flex-1" onClick={() => setTab("experiments")}>
            Replay
          </Btn>
        </div>
      </Panel>
      <Panel>
        <PanelTitle hint="SYNTHETIC">Next token</PanelTitle>
        {last ? (
          <div className="space-y-2">
            {last.candidates.map((t) => (
              <div key={`${t.tokenId}-${t.text}`}>
                <div className="mb-1 flex justify-between text-xs">
                  <span className="font-mono">{t.text}</span>
                  <span className="font-mono tabular text-muted">{t.amount.toFixed(2)}</span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-raised">
                  <div
                    className="h-full bg-ok"
                    style={{ width: `${Math.min(100, t.amount * 100)}%` }}
                  />
                </div>
              </div>
            ))}
            <EvidenceBadge provenance={last.provenance} />
          </div>
        ) : (
          <p className="text-[13px] text-muted">{awaiting("exactMatch").why}</p>
        )}
      </Panel>
    </div>
  );
}

function InputInsight() {
  const { selectedToken, level } = useStudio();
  const event = sessionView.inputEvent;
  const tok = event?.tokens[selectedToken] ?? event?.tokens[0] ?? null;
  if (!tok) {
    return (
      <Panel>
        <PanelTitle>Chữ đang chọn</PanelTitle>
        <p className="text-[13px] text-muted">Không có byte đầu vào được ghi.</p>
      </Panel>
    );
  }
  const hex = `0x${tok.byte.toString(16).toUpperCase().padStart(2, "0")}`;
  if (level === "easy") {
    return (
      <Panel>
        <PanelTitle>Chữ đang chọn</PanelTitle>
        <p className="text-lg">{tok.char ?? "·"}</p>
        <p className="mt-2 text-[13px] text-muted">
          FPGA không đọc chữ — nó nhận số <span className="font-mono text-fg">{tok.byte}</span>.
        </p>
      </Panel>
    );
  }
  return (
    <Panel>
      <PanelTitle>Chi tiết byte</PanelTitle>
      <dl>
        <Row k="Ký tự" v={tok.char ?? "continuation"} />
        <Row k="UTF-8" v={hex} />
        <Row k="Vị trí" v={tok.position} />
        <Row k="Embedding" v={`E[${tok.embeddingRow}]`} />
      </dl>
    </Panel>
  );
}

function ForwardInsight() {
  const { level } = useStudio();
  if (level === "easy") {
    return (
      <Panel>
        <PanelTitle>AI đang tính gì</PanelTitle>
        <p className="text-[13px] leading-relaxed text-muted">
          Câu đang được biến thành {buildFacts.hiddenDim} số nội bộ. Ô sáng hơn là giá trị lớn hơn
          — không phải chữ.
        </p>
      </Panel>
    );
  }
  return (
    <Panel>
      <PanelTitle>{level === "rtl" ? "h bus" : "AI đang tính gì"}</PanelTitle>
      <dl>
        <Row k={level === "rtl" ? "h_idx" : "dim"} v={String(buildFacts.hiddenDim)} />
        <Row
          k={level === "rtl" ? "sat_flag" : "rank"}
          v={
            measured.effectiveRank
              ? `${measured.effectiveRank.value}/${buildFacts.hiddenDim}`
              : "chưa đo"
          }
        />
        <Row
          k={level === "rtl" ? "sat" : "sat"}
          v={
            measured.saturation
              ? `${(measured.saturation.value * 100).toFixed(1)}%`
              : "chưa đo"
          }
        />
      </dl>
    </Panel>
  );
}

function CompareInsight() {
  const { setTab, level } = useStudio();
  const needUpdate = sessionView.compare?.violated ?? false;
  if (level === "easy") {
    return (
      <Panel>
        <PanelTitle>Quyết định</PanelTitle>
        <p className="text-sm font-medium">{needUpdate ? "Cần học thêm" : "Không cần cập nhật"}</p>
        <p className="mt-2 text-[13px] text-muted">
          {needUpdate
            ? "Ví dụ sai đang quá gần câu gốc."
            : "Ví dụ đúng đã gần câu gốc hơn ví dụ sai."}
        </p>
        <Btn variant="primary" className="mt-3 w-full" onClick={() => setTab("learning")}>
          Xem chỗ vừa đổi
        </Btn>
      </Panel>
    );
  }
  return (
    <Panel>
      <PanelTitle>margin_viol</PanelTitle>
      <dl>
        <Row k="violated" v={needUpdate ? "1" : "0"} />
        <Row k="d_pos" v={measured.dPos ? measured.dPos.value : "—"} />
        <Row k="d_neg" v={measured.dNeg ? measured.dNeg.value : "—"} />
        <Row
          k="M_cos"
          v={measured.marginCosine ? `${measured.marginCosine.value} ĐO/EVAL` : "chưa đo"}
        />
      </dl>
    </Panel>
  );
}

function LearnInsight() {
  const { level } = useStudio();
  const writes = sessionView.learningEvent?.writes.length ?? 0;
  if (level === "easy") {
    return (
      <Panel>
        <PanelTitle>Vừa đổi</PanelTitle>
        <p className="text-sm font-medium">
          {measured.weightsChanged
            ? `${measured.weightsChanged.value} giá trị đổi`
            : "Không có lần ghi"}
        </p>
        <p className="mt-2 text-[13px] text-muted">
          Không có gradient trên FPGA — chỉ địa chỉ, trước, Δ, sau.
        </p>
      </Panel>
    );
  }
  return (
    <div className="space-y-3">
      <Panel>
        <PanelTitle>Lần ghi</PanelTitle>
        <div className="rounded-lg border border-line bg-raised p-3">
          <div className="text-sm font-medium">
            upd_en={measured.updateEnabled ? 1 : 0} · Δw=
            {measured.weightsChanged ? measured.weightsChanged.value : "—"}
          </div>
          <p className="mt-1 text-xs text-muted">{writes} dòng nhật ký</p>
        </div>
      </Panel>
      {level === "research" ? (
        <Panel>
          <PanelTitle>Hướng cập nhật</PanelTitle>
          <dl>
            <Row k="tăng" v={measured.weightsUp ? measured.weightsUp.value : "—"} />
            <Row k="giảm" v={measured.weightsDown ? measured.weightsDown.value : "—"} />
            <Row k="clipped" v={measured.clipped ? measured.clipped.value : "—"} />
          </dl>
        </Panel>
      ) : (
        <Panel>
          <PanelTitle>upd bus</PanelTitle>
          <dl>
            <Row k="beats" v={writes} />
            <Row k="clip_flag" v={measured.clipped ? measured.clipped.value : "—"} />
          </dl>
        </Panel>
      )}
    </div>
  );
}

function ModelInsight() {
  const injected = sessionView.modelEvents.find((e) => e.contextEpisodeId);
  const layer1 = sessionView.modelEvents.find((e) => e.stage === "Layer 1");
  return (
    <Panel>
      <PanelTitle>Đường mô hình</PanelTitle>
      <p className="text-sm">
        {injected?.contextEpisodeId
          ? `Episode #${injected.contextEpisodeId} vào bước ${injected.stage}.`
          : "Không có ký ức gắn vào mô hình."}
      </p>
      <p className="mt-2 text-[13px] text-muted">
        Layer 1: {layer1 ? `${layer1.durationMs.value.toFixed(1)} ms` : "chưa đo"}. Không phải suy nghĩ.
      </p>
    </Panel>
  );
}

function MemInsight() {
  const retrieval = sessionView.retrieval;
  return (
    <Panel>
      <PanelTitle hint="SYNTHETIC">Truy hồi hiện tại</PanelTitle>
      {retrieval ? (
        <div className="rounded-lg border border-mem/40 bg-mem/10 p-3">
          <div className="flex items-center justify-between">
            <span className="font-mono text-sm">
              {retrieval.selectedEpisodeId ? `#${retrieval.selectedEpisodeId}` : "MISS"}
            </span>
            <Pill tone={retrieval.selectedEpisodeId ? "ok" : "warn"}>
              {retrieval.selectedEpisodeId ? "HIT · SYNTHETIC" : "MISS"}
            </Pill>
          </div>
          <EvidenceBadge provenance={retrieval.provenance} />
          <p className="mt-2 text-[13px] text-muted">{awaiting("eamHitRate").why}</p>
        </div>
      ) : (
        <p className="text-[13px] text-muted">{awaiting("eamHitRate").why}</p>
      )}
    </Panel>
  );
}

function OutputInsight() {
  const last = sessionView.outputEvents.at(-1);
  return (
    <Panel>
      <PanelTitle>Token đang xem</PanelTitle>
      {last ? (
        <>
          <p className="font-mono text-sm">{last.selectedText}</p>
          <p className="mt-2 text-[13px] text-muted">
            cycle {last.cycle === null ? "chưa đo" : last.cycle.toLocaleString("vi-VN")} ·{" "}
            {last.candidates.length} ứng viên
          </p>
        </>
      ) : (
        <p className="text-[13px] text-muted">Không có sự kiện đầu ra.</p>
      )}
    </Panel>
  );
}

function WaveInsight() {
  const { selectedSignal, cursorNs, level } = useStudio();
  const wave = sessionView.waveform;
  return (
    <Panel>
      <PanelTitle>Tín hiệu đang chọn</PanelTitle>
      <div className="font-mono text-sm text-cyan">{selectedSignal}</div>
      <dl className="mt-2">
        <Row k="Cursor" v={`${cursorNs} ns`} />
        <Row k="Clock" v={`${buildFacts.clockMhz} MHz`} />
        <Row
          k="Capture"
          v={wave.available ? "SYNTHETIC có sẵn" : wave.absence.reason}
        />
      </dl>
      <p className="mt-3 text-xs leading-relaxed text-muted">
        {level === "rtl"
          ? "Không có LiteScope trên bit hiện tại. Viewer đọc WaveformSource fixture."
          : "Sóng này là bản ghi fixture, không phải capture silicon."}
      </p>
    </Panel>
  );
}

function HealthInsight() {
  const health = sessionView.health;
  return (
    <Panel>
      <PanelTitle>Kết luận hiện tại</PanelTitle>
      <p className="text-[13px] leading-relaxed text-fg">
        {HEALTH_LINE[health.verdict] ?? HEALTH_LINE.UNKNOWN}
      </p>
      <p className="mt-3 text-caption text-muted">
        {health.verdict} · AUC / AP là HOST EVAL — không pretends silicon.
      </p>
    </Panel>
  );
}

function ExpInsight() {
  const header = useStudioHeader();
  return (
    <Panel>
      <PanelTitle>Phiên đang khóa</PanelTitle>
      <dl>
        <Row k="Interaction" v={header.id} />
        <Row k="Mode" v={header.mode} />
        <Row k="Trace" v={header.trace} />
      </dl>
      <p className="mt-3 text-xs text-muted">
        Replay đọc session đã ghi. Không mở serial từ frontend.
      </p>
    </Panel>
  );
}

function BoardInsight() {
  const header = useStudioHeader();
  const temp = awaiting("tempC");
  return (
    <Panel>
      <PanelTitle>Sức khỏe board</PanelTitle>
      <dl>
        <Row k="Trạng thái" v={header.live ? "LIVE" : "SNAPSHOT"} />
        <Row k="Nhiệt độ" v={`— · ${temp.needs}`} />
        <Row
          k="WNS"
          v={
            buildFacts.wnsNs === null
              ? "chưa đo"
              : `${buildFacts.wnsNs > 0 ? "+" : ""}${buildFacts.wnsNs} ns`
          }
        />
        <Row k="UART" v={awaiting("uartLink").why} />
      </dl>
    </Panel>
  );
}

function EvInsight() {
  const full = sessionView.interactions[0]?.traceability;
  const partial = sessionView.interactions[1]?.traceability;
  return (
    <Panel>
      <PanelTitle>Nguồn bằng chứng</PanelTitle>
      <p className="text-[13px] leading-relaxed text-muted">
        Chọn #{sessionView.interactions[0]?.interactionId} hoặc #
        {sessionView.interactions[1]?.interactionId} trên tab. Twin và synthetic không được tô như BOARD.
      </p>
      <dl className="mt-3 space-y-1 text-[13px]">
        <Row k={`#${sessionView.interactions[0]?.interactionId ?? "—"}`} v={full?.verdict ?? "chưa có"} />
        <Row k={`#${sessionView.interactions[1]?.interactionId ?? "—"}`} v={partial?.verdict ?? "chưa có"} />
      </dl>
    </Panel>
  );
}

function SetInsight() {
  const { projectName } = useStudio();
  const header = useStudioHeader();
  return (
    <Panel>
      <PanelTitle>Workspace</PanelTitle>
      <dl>
        <Row k="Dự án" v={projectName} />
        <Row k="Nguồn" v={header.activeSource} />
        <Row k="Theme" v="Dark" />
      </dl>
    </Panel>
  );
}
