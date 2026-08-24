import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import type { CaptureGroup, SignalTrace, WaveformCapture } from "@/lib/contract";
import { downloadArtifact } from "@/lib/export";
import { sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { EvidenceBadge } from "../ui/evidence-badge";
import { StudioState } from "../ui/studio-state";
import { Btn, Panel, PanelTitle, Pill } from "../ui";
import { WaveformView, valueAtCycle } from "../viz";

/**
 * Sóng FPGA (§18). Viewer over WaveformSource fixture. No LiteScope core.
 *
 * Owner: gb-waveform-glassbox.
 */
const GROUP_LABEL: Record<CaptureGroup, string> = {
  INPUT: "Đầu vào",
  FORWARD: "Biểu diễn",
  LEARNING: "Học",
  DDR_MEMORY: "Bộ nhớ",
  OUTPUT: "Đầu ra",
};

const STORE_KEY: Record<CaptureGroup, string> = {
  INPUT: "INPUT",
  FORWARD: "FORWARD",
  LEARNING: "LEARNING",
  DDR_MEMORY: "MEMORY",
  OUTPUT: "OUTPUT",
};

function inspectorValue(capture: WaveformCapture, signalId: string, cycle: number): string {
  const signal = capture.signals.find((s) => s.id === signalId);
  const value = valueAtCycle(capture, signalId, cycle);
  if (value === null || !signal) return "—";
  if (signal.kind === "ENUM" && signal.enumLabels) {
    return signal.enumLabels[String(value)] ?? String(value);
  }
  if (signal.kind === "BIT") return String(value);
  return `0x${value.toString(16)}`;
}

export function WaveformTab() {
  const {
    groups,
    toggleGroup,
    selectedSignal,
    setSelectedSignal,
    level,
    requestCaptureNext,
    captureNextRequested,
    setTab,
  } = useStudio();
  const header = useStudioHeader();
  const list = sessionView.interactions;
  const [id, setId] = useState(list[0]?.interactionId ?? header.id);
  const selectedInteraction = list.find((row) => row.interactionId === id) ?? list[0];
  const result = selectedInteraction?.waveform ?? {
    available: false as const,
    absence: {
      interactionId: id,
      reason: "SOURCE_UNAVAILABLE" as const,
      detail: "Không có waveform trên session đang mở.",
    },
  };
  const firstCaptured = list.find((row) => row.waveform.available)?.interactionId;
  const [windowed, setWindowed] = useState<SignalTrace[] | null>(null);
  useEffect(() => {
    if (!result.available) {
      setWindowed(null);
      return;
    }
    const capture = result.capture;
    const worker = new Worker(new URL("../../workers/waveform-window.ts", import.meta.url), {
      type: "module",
    });
    worker.onmessage = (event: MessageEvent<SignalTrace[]>) => {
      setWindowed(event.data);
      worker.terminate();
    };
    worker.onerror = () => {
      setWindowed(capture.traces);
      worker.terminate();
    };
    worker.postMessage({
      traces: capture.traces,
      from: capture.cycles.startCycle,
      to: capture.cycles.endCycle,
    });
    return () => worker.terminate();
  }, [result]);
  const [cursorCycle, setCursorCycle] = useState(512);
  const capture = result.available ? result.capture : null;
  const visibleIds = useMemo(() => {
    if (!capture) return [];
    const hidden = new Set<CaptureGroup>();
    (Object.keys(STORE_KEY) as CaptureGroup[]).forEach((g) => {
      if (groups[STORE_KEY[g]] === false) hidden.add(g);
    });
    return capture.signals.filter((s) => !hidden.has(s.group)).map((s) => s.id);
  }, [capture, groups]);

  const picker = (
    <label className="mb-3 flex items-center gap-2 text-[13px] text-muted">
      Tương tác
      <select
        className="rounded-md border border-line bg-raised px-2 py-1 font-mono text-xs text-fg"
        value={id}
        onChange={(e) => setId(e.target.value)}
        data-testid="waveform-interaction"
      >
        {list.map((i) => (
          <option key={i.interactionId} value={i.interactionId}>
            #{i.interactionId}
          </option>
        ))}
      </select>
    </label>
  );

  if (!result.available || !capture) {
    return (
      <div className="space-y-3">
        {picker}
        <StudioState
          kind="no-waveform"
          primary={{
            label: firstCaptured ? `Xem tương tác #${firstCaptured}` : "Mở Replay",
            onClick: () => {
              if (firstCaptured) setId(firstCaptured);
              else setTab("experiments");
            },
          }}
          secondary={{
            label: "Bật capture cho lần sau",
            onClick: requestCaptureNext,
          }}
        >
          <p className="mt-2 text-[13px] text-muted">
            {result.available ? "" : `${result.absence.reason}. `}
            Không vẽ sóng giả.
            {captureNextRequested ? " Đã ghi yêu cầu — bit này không có lệnh capture." : ""}
          </p>
        </StudioState>
        <Btn onClick={() => setTab("evidence")}>Xem bằng chứng của tương tác</Btn>
      </div>
    );
  }

  const selected =
    capture.signals.find((s) => s.id === selectedSignal)?.id ??
    capture.signals[0]?.id ??
    "";

  return (
    <div className="space-y-3">
      {picker}
      {capture.overflow ? <StudioState kind="capture-overflow" /> : null}
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{capture.provenance.source}</Pill>
        <EvidenceBadge provenance={capture.provenance} />
        <span className="text-caption text-subtle">
          {capture.clockMhz} MHz · {capture.cycles.endCycle.toLocaleString("vi-VN")} cycle ·{" "}
          {capture.settings.mode} · trigger {capture.settings.trigger}
        </span>
      </div>

      <Panel>
        <PanelTitle>Cài đặt bản ghi</PanelTitle>
        <dl className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4 text-[13px]">
          <div>
            <div className="text-caption text-subtle">Pre-trigger</div>
            {capture.settings.preTriggerSamples.toLocaleString("vi-VN")}
          </div>
          <div>
            <div className="text-caption text-subtle">Post-trigger</div>
            {capture.settings.postTriggerSamples.toLocaleString("vi-VN")}
          </div>
          <div>
            <div className="text-caption text-subtle">RLE</div>
            {capture.settings.rle ? "bật trong bản ghi" : "tắt trong bản ghi"}
          </div>
          <div>
            <div className="text-caption text-subtle">Xuất được</div>
            {capture.exportFormats.join(", ")}
          </div>
        </dl>
        <p className="mt-2 text-caption text-subtle">
          Không có LiteScope trên bit này. Đây là WaveformSource SYNTHETIC — xem, không trang bị capture.
        </p>
        <Btn
          className="mt-3"
          onClick={() => {
            const out = downloadArtifact(`waveform-${id}.vcd`);
            if (out.ok) toast.message(`Đã xuất ${out.name}`, { description: "SYNTHETIC · không phải BOARD" });
            else toast.message("Không xuất được", { description: out.reason });
          }}
        >
          Xuất VCD từ bản ghi
        </Btn>
      </Panel>

      <div className="grid gap-3 lg:grid-cols-[220px_1fr_260px]">
        <Panel className="h-fit">
          <PanelTitle>{level === "easy" ? "Nhóm" : "Nhóm tín hiệu"}</PanelTitle>
          <div className="space-y-3">
            {(Object.keys(GROUP_LABEL) as CaptureGroup[]).map((g) => (
              <div key={g}>
                <label className="flex items-center gap-2 text-[13px]">
                  <input
                    type="checkbox"
                    checked={groups[STORE_KEY[g]] !== false}
                    onChange={() => toggleGroup(STORE_KEY[g])}
                  />
                  {level === "easy" ? GROUP_LABEL[g] : g}
                </label>
                {level !== "easy" ? (
                  <div className="mt-1 space-y-0.5 pl-5">
                    {capture.signals
                      .filter((s) => s.group === g)
                      .map((s) => (
                        <button
                          key={s.id}
                          type="button"
                          onClick={() => setSelectedSignal(s.id)}
                          className="block font-mono text-caption text-muted hover:text-cyan"
                        >
                          {level === "rtl" ? (s.rtlName ?? s.id) : s.id}
                        </button>
                      ))}
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        </Panel>
        <Panel>
          <PanelTitle>Sóng số</PanelTitle>
          <ol className="mb-2 flex flex-wrap gap-1" aria-label="Mốc sự kiện">
            {capture.annotations.map((a) => (
              <li key={a.kind}>
                <button
                  type="button"
                  className="rounded-md border border-line px-2 py-0.5 text-caption hover:border-cyan"
                  onClick={() => setCursorCycle(a.cycle)}
                >
                  {a.label}
                </button>
              </li>
            ))}
          </ol>
          <WaveformView
            capture={windowed ? { ...capture, traces: windowed } : capture}
            visibleSignalIds={visibleIds}
            selectedSignalId={selected}
            cursorCycle={cursorCycle}
            onCursor={setCursorCycle}
            level={level}
          />
        </Panel>
        <Panel>
          <PanelTitle>{level === "easy" ? "Đang xem lúc" : "Chi tiết tín hiệu"}</PanelTitle>
          <div className="font-mono text-sm text-cyan">
            {level === "rtl"
              ? (capture.signals.find((s) => s.id === selected)?.rtlName ?? selected)
              : capture.signals.find((s) => s.id === selected)?.label ?? selected}
          </div>
          <dl className="mt-3 space-y-1.5 text-[13px]">
            <div className="flex justify-between">
              <dt className="text-muted">Giá trị</dt>
              <dd className="font-mono">{inspectorValue(capture, selected, cursorCycle)}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted">Cycle</dt>
              <dd className="font-mono">{cursorCycle.toLocaleString("vi-VN")}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted">Clock</dt>
              <dd>{capture.clockMhz} MHz</dd>
            </div>
          </dl>
        </Panel>
      </div>
    </div>
  );
}
