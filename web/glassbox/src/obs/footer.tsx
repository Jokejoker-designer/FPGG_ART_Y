import { OBS_CAPTURE, UART_LINES } from "./session";
import { SourceBadge } from "./source-badge";

export function UartFooter() {
  return (
    <section data-testid="obs-footer" className="border-t border-line">
      <header className="flex flex-wrap items-center justify-between gap-2 px-3 py-1">
        <div className="flex flex-wrap items-baseline gap-x-2">
          <p className="obs-kicker">04 UART</p>
          <h2 className="text-sm font-medium tracking-tight text-fg">Capture log</h2>
          <p className="text-[11px] text-subtle">
            {OBS_CAPTURE.uart} · {OBS_CAPTURE.baud}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="obs-mono text-[11px] text-subtle">{UART_LINES.length} lines</span>
          <SourceBadge source="BOARD" />
        </div>
      </header>
      <div className="obs-dump-wrap gbx-scroll">
        <div className="obs-dump obs-dump-head" aria-hidden="true">
          <span>#</span>
          <span>ASCII</span>
          <span>HEX</span>
          <span>SRC</span>
        </div>
        <div data-testid="obs-uart-ascii">
          <div data-testid="obs-uart-hex">
            {UART_LINES.map((line) => (
              <div
                key={line.i}
                className={line.source === "STALL" ? "obs-dump obs-dump-stall" : "obs-dump"}
              >
                <span className="text-subtle">{String(line.i).padStart(2, "0")}</span>
                <span>{line.ascii}</span>
                <span>{line.hex}</span>
                <SourceBadge source={line.source} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
