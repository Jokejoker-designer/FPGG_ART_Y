import { useEffect, useState, type ComponentType } from "react";
import { Cpu } from "lucide-react";
import { Link } from "@tanstack/react-router";
import { OBS_CAPTURE, SILICON_WATERMARK, shaShort } from "./session";
import { BoardChat } from "./chat";
import { UartFooter } from "./footer";
import { PipelineGraph } from "./pipeline";
import { SourceBadge, SourceLegend } from "./source-badge";

function Fact({ label, value, alert }: { label: string; value: string; alert?: boolean }) {
  return (
    <div className="min-w-0">
      <div className="obs-kicker">{label}</div>
      <div className={alert ? "obs-mono text-[12px] text-bad" : "obs-mono text-[12px] text-fg"}>
        {value}
      </div>
    </div>
  );
}

function GlassBoxSlot() {
  const [Dock, setDock] = useState<ComponentType | null>(null);
  useEffect(() => {
    void import("./client-dock").then((mod) => {
      setDock(() => mod.ClientDock);
    });
  }, []);
  return (
    <div className="h-full">
      {Dock ? (
        <Dock />
      ) : (
        <p className="px-3 py-6 text-sm text-muted" role="status">
          Đang nạp GlassBox…
        </p>
      )}
    </div>
  );
}

export function Observatory() {
  const predLabel = OBS_CAPTURE.pred === null ? "∅" : String(OBS_CAPTURE.pred);
  const bramPct = Math.round((OBS_CAPTURE.bramUsed / OBS_CAPTURE.bramLimit) * 100);

  return (
    <div className="obs-shell" data-testid="obs-shell">
      <a href="#obs-graph" className="gb-sr-only">
        Bỏ qua tới pipeline
      </a>

      <header className="obs-header" data-testid="obs-header">
        <div className="flex min-w-0 items-center gap-3">
          <span className="grid size-8 place-items-center rounded-md border border-cyan/40 bg-cyan/10">
            <Cpu className="size-4 text-cyan" />
          </span>
          <div className="min-w-0 leading-tight">
            <p className="obs-kicker">01 Status · Native AI GlassBox</p>
            <h1 className="text-sm font-semibold">Native AI Observatory</h1>
            <p className="truncate text-[11px] text-subtle">
              {OBS_CAPTURE.board} · {OBS_CAPTURE.part}
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <SourceBadge source="ALERT" />
          <span className="text-[12px] text-muted">COM12 closed</span>
          <span className="obs-mono text-[12px] text-fg">{OBS_CAPTURE.jtag}</span>
        </div>

        <SourceLegend />

        <Link
          to="/studio"
          className="rounded-lg border border-line px-2.5 py-1 text-caption text-muted hover:text-fg"
        >
          Studio đầy đủ
        </Link>

        <div className="ml-auto flex flex-wrap items-end gap-x-5 gap-y-1">
          <Fact label="BIT" value={shaShort(OBS_CAPTURE.bitSha)} />
          <Fact label="LAST" value={OBS_CAPTURE.lastStage} alert />
          <Fact label="PRED" value={predLabel} />
          <Fact label="WNS" value={`+${OBS_CAPTURE.wnsNs.toFixed(3)} ns`} />
          <Fact label="BRAM" value={`${OBS_CAPTURE.bramUsed}/${OBS_CAPTURE.bramLimit} (${bramPct}%)`} />
          <Fact label="CLK" value={`${OBS_CAPTURE.clockMhz} MHz`} />
        </div>
      </header>

      <section id="obs-graph" className="obs-graph flex min-h-0 flex-col border-r border-line">
        <div className="shrink-0 border-b border-line px-3 py-1.5">
          <div className="mb-1.5 flex flex-wrap items-center justify-between gap-2">
            <p className="obs-kicker">
              02 UART heartbeat · {OBS_CAPTURE.run} {OBS_CAPTURE.rev}
            </p>
            <div className="flex items-center gap-1.5">
              <SourceBadge source="BOARD" />
              <SourceBadge source="XSIM" />
              <SourceBadge source="STALL" />
            </div>
          </div>
          <PipelineGraph />
        </div>

        <div className="relative min-h-0 flex-1">
          <div className="absolute inset-0">
            <GlassBoxSlot />
          </div>
          <div className="obs-watermark" data-testid="obs-watermark" aria-hidden="true">
            {SILICON_WATERMARK}
          </div>
        </div>
      </section>

      <aside className="obs-chat min-h-0 border-line bg-card">
        <BoardChat />
      </aside>

      <footer className="obs-footer bg-surface">
        <UartFooter />
      </footer>
    </div>
  );
}
