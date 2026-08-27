import { cn } from "@/lib/utils";
import { PIPELINE } from "./session";
import { SourceBadge } from "./source-badge";

const STATUS_GLYPH = {
  complete: "\u2713",
  last: "\u25B6",
  expected: "\u25CB",
  idle: "\u25CB",
} as const;

export function PipelineGraph() {
  return (
    <ol
      data-testid="obs-pipeline"
      className="flex items-stretch gap-0 overflow-x-auto gbx-scroll"
    >
      {PIPELINE.map((stage, index) => {
        const last = index === PIPELINE.length - 1;
        const silicon = stage.source === "BOARD" || stage.source === "STALL";
        return (
          <li key={stage.id} className="flex min-w-0 flex-1 items-stretch">
            <div
              data-testid={`stage-${stage.id}`}
              className={cn(
                "flex min-w-[4.5rem] flex-1 items-center justify-between gap-1 rounded-lg border px-2 py-1",
                stage.status === "last" && "border-bad/55 bg-bad/10 gbx-active",
                stage.status === "complete" && "border-ok/40 bg-ok/8",
                stage.status === "expected" && "border-dashed border-xsim/50 bg-card",
              )}
            >
              <div className="flex min-w-0 items-center gap-1">
                <span
                  aria-hidden="true"
                  className={cn(
                    "text-[10px]",
                    stage.status === "complete" && "text-ok",
                    stage.status === "last" && "text-bad",
                    stage.status === "expected" && "text-xsim",
                  )}
                >
                  {STATUS_GLYPH[stage.status]}
                </span>
                <span
                  className={cn(
                    "obs-mono truncate text-[10px] font-medium",
                    silicon ? "text-fg" : "text-muted",
                  )}
                >
                  {stage.label}
                </span>
              </div>
              <SourceBadge source={stage.source} />
            </div>
            {last ? null : (
              <span
                aria-hidden="true"
                className={cn(
                  "mx-0.5 self-center text-[11px] text-ink-faint",
                  index < 4 ? "text-ok" : "text-xsim/70",
                )}
              >
                →
              </span>
            )}
          </li>
        );
      })}
    </ol>
  );
}
