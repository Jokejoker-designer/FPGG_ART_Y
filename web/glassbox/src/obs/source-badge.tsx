import { cn } from "@/lib/utils";
import type { SourceId } from "./session";

const COPY: Record<SourceId, { title: string; hint: string }> = {
  BOARD: { title: "BOARD", hint: "UART silicon — 100% physical board" },
  XSIM: { title: "XSIM", hint: "RTL simulation — not silicon" },
  SYNTHETIC: { title: "SYNTHETIC", hint: "Generated data — not silicon" },
  TWIN: { title: "TWIN", hint: "Host digital twin — not silicon" },
  STALL: { title: "STALL", hint: "Pipeline stall" },
  ALERT: { title: "ALERT", hint: "Link down or hardware alert" },
  ACTIVE: { title: "ACTIVE", hint: "Active stream" },
  AI_RESPONSE: { title: "AI_RESPONSE", hint: "FPGA-generated output" },
};

/**
 * Chip fills follow the locked palette:
 * Green 500 BOARD, Blue 500 XSIM, Amber 500 SYNTHETIC/TWIN,
 * Red 500 STALL/ALERT, Cyan 400 ACTIVE/AI_RESPONSE.
 */
const TONE: Record<SourceId, string> = {
  BOARD: "bg-ok text-[#052e16]",
  XSIM: "bg-xsim text-white",
  SYNTHETIC: "bg-warn text-[#3b2503]",
  TWIN: "bg-warn text-[#3b2503]",
  STALL: "bg-bad text-white",
  ALERT: "bg-bad text-white",
  ACTIVE: "bg-cyan text-[#083344]",
  AI_RESPONSE: "bg-cyan text-[#083344]",
};

const LEGEND: SourceId[] = ["BOARD", "XSIM", "TWIN", "STALL", "ACTIVE"];

export function SourceBadge({
  source,
  className,
}: {
  source: SourceId;
  className?: string;
}) {
  const copy = COPY[source];
  return (
    <span
      data-testid={`badge-${source}`}
      title={copy.hint}
      className={cn(
        "inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.08em]",
        TONE[source],
        className,
      )}
    >
      {copy.title}
    </span>
  );
}

export function SourceLegend({ className }: { className?: string }) {
  return (
    <ul
      data-testid="obs-legend"
      className={cn("flex flex-wrap items-center gap-1.5", className)}
      aria-label="Source badges"
    >
      {LEGEND.map((id) => (
        <li key={id}>
          <SourceBadge source={id} />
        </li>
      ))}
    </ul>
  );
}
