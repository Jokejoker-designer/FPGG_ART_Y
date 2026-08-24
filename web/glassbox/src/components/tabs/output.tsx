import { useState } from "react";
import { sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Btn, Panel, PanelTitle, Pill } from "../ui";

/**
 * Đầu ra (§17). Tokens and candidates from OutputEvent.
 * Probabilities may use %; scores may not.
 *
 * Owner: gb-ux-product.
 */
export function OutputTab() {
  const { setTab } = useStudio();
  const header = useStudioHeader();
  const events = sessionView.outputEvents;
  const [step, setStep] = useState(() => {
    const artix = events.findIndex((e) => e.selectedText === "Artix");
    return artix >= 0 ? artix : Math.max(0, events.length - 1);
  });
  const [trace, setTrace] = useState(false);
  const current = events[step] ?? null;
  const text = events.map((e) => e.selectedText).join(" ");
  const wave = sessionView.waveform;
  const tokenMark =
    wave.available
      ? wave.capture.annotations.find((a) => a.kind === "TOKEN_EMITTED")
      : null;
  const ctx = sessionView.modelEvents.find((e) => e.contextEpisodeId);

  if (events.length === 0) {
    return (
      <Panel>
        <PanelTitle>Chưa có đầu ra</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi token. Lane 03E trên bo không sinh ngôn ngữ.
        </p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        {current ? <EvidenceBadge provenance={current.provenance} /> : null}
      </div>

      <Panel>
        <PanelTitle>Câu đã ghi</PanelTitle>
        <p className="text-lg">{header.answer ?? text}</p>
        <p className="mt-2 text-[13px] text-muted">
          Đây là chuỗi token trong fixture, không phải câu vừa sinh từ bo.
        </p>
      </Panel>

      <Panel>
        <PanelTitle>Dòng token</PanelTitle>
        <div className="flex flex-wrap gap-1.5" role="list" aria-label="Dòng token đầu ra">
          {events.map((e, i) => (
            <button
              key={e.eventId}
              type="button"
              role="listitem"
              onClick={() => setStep(i)}
              className={
                i === step
                  ? "rounded-md border border-cyan bg-cyan/15 px-2 py-1 font-mono text-sm"
                  : "rounded-md border border-line bg-raised px-2 py-1 font-mono text-sm text-muted hover:text-fg"
              }
            >
              {e.selectedText}
            </button>
          ))}
        </div>
      </Panel>

      {current ? (
        <div className="grid gap-3 lg:grid-cols-2">
          <Panel>
            <PanelTitle>
              Ứng viên bước {current.step + 1}
              {current.candidates[0]?.kind === "SCORE" ? " · điểm (không phải %)" : " · xác suất"}
            </PanelTitle>
            <ul className="space-y-2">
              {current.candidates.map((c) => {
                const pct = c.kind === "PROBABILITY" ? Math.round(c.amount * 100) : null;
                return (
                  <li key={`${c.tokenId}-${c.text}`}>
                    <div className="mb-1 flex justify-between text-xs">
                      <span className="font-mono">{c.text}</span>
                      <span className="font-mono tabular text-muted">
                        {pct === null ? `điểm ${c.amount}` : `${pct}%`}
                      </span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-raised">
                      <div
                        className="h-full bg-ok"
                        style={{
                          width: `${Math.min(100, (c.kind === "PROBABILITY" ? c.amount : c.amount) * 100)}%`,
                        }}
                      />
                    </div>
                  </li>
                );
              })}
            </ul>
          </Panel>
          <Panel>
            <PanelTitle>Sự kiện chọn</PanelTitle>
            <dl className="space-y-2 text-[13px]">
              <div>
                <div className="text-caption text-subtle">SELECTED</div>
                {current.selectedText}
              </div>
              <div>
                <div className="text-caption text-subtle">cycle</div>
                <span className="font-mono">
                  {current.cycle === null ? "chưa đo" : current.cycle.toLocaleString("vi-VN")}
                </span>
              </div>
              <div>
                <div className="text-caption text-subtle">interaction</div>
                #{current.interactionId}
              </div>
            </dl>
            <Btn variant="primary" className="mt-3" onClick={() => setTrace((v) => !v)}>
              {trace ? "Đóng truy vết" : "Xem vì sao token này xuất hiện"}
            </Btn>
          </Panel>
        </div>
      ) : null}

      {trace && current ? (
        <Panel>
          <PanelTitle>Truy vết token</PanelTitle>
          <ul className="space-y-2 text-[13px]">
            <li>
              Ký ức:{" "}
              {sessionView.retrieval?.selectedEpisodeId
                ? `Episode #${sessionView.retrieval.selectedEpisodeId}`
                : "không ghi"}
            </li>
            <li>
              Bước mô hình: {ctx ? `${ctx.stage} · #${ctx.contextEpisodeId}` : "không gắn episode"}
            </li>
            <li>
              Mốc sóng:{" "}
              {tokenMark
                ? `${tokenMark.label} @ cycle ${tokenMark.cycle.toLocaleString("vi-VN")}`
                : "không có annotation TOKEN_EMITTED"}
            </li>
          </ul>
          <div className="mt-3 flex flex-wrap gap-2">
            <Btn onClick={() => setTab("eam")}>Mở bộ nhớ</Btn>
            <Btn onClick={() => setTab("model")}>Mở mô hình</Btn>
            <Btn onClick={() => setTab("waveform")}>Mở sóng</Btn>
          </div>
        </Panel>
      ) : null}
    </div>
  );
}
