import type { ReactNode } from "react";
import { STAGE_LABEL, type ViewLevel } from "@/lib/data";
import { useStudio } from "@/lib/store";
import { cn } from "@/lib/utils";

const MODE: Record<
  ViewLevel,
  { title: string; body: string; tone: string; border: string }
> = {
  easy: {
    title: "Dễ hiểu",
    body: "Cùng một lần chạy silicon — đang kể bằng lời. Số kỹ thuật đã ẩn.",
    tone: "text-ok",
    border: "border-ok/35 bg-ok/10",
  },
  research: {
    title: "Research",
    body: "Cùng interaction #1842. Hiện d_pos, rank, AUC, cosine. Nguồn gắn trên từng số.",
    tone: "text-cyan",
    border: "border-cyan/35 bg-cyan/10",
  },
  rtl: {
    title: "RTL",
    body: "Cùng bitstream 7CEBA85. Tín hiệu, cycle, địa chỉ, bit-width — không đổi evidence.",
    tone: "text-warn",
    border: "border-warn/35 bg-warn/10",
  },
};

export function When({
  easy,
  research,
  rtl,
}: {
  easy?: ReactNode;
  research?: ReactNode;
  rtl?: ReactNode;
}) {
  const { level } = useStudio();
  if (level === "easy") return <>{easy}</>;
  if (level === "rtl") return <>{rtl ?? research}</>;
  return <>{research ?? easy}</>;
}

export function ModeStrip() {
  const { level, setLevel } = useStudio();
  const m = MODE[level];
  return (
    <div className={cn("mb-3 rounded-xl border px-3 py-2.5", m.border)}>
      <div className="flex flex-wrap items-center gap-2">
        <div className={cn("text-sm font-medium", m.tone)}>{m.title}</div>
        <p className="min-w-0 flex-1 text-xs leading-relaxed text-muted">{m.body}</p>
        <div className="flex rounded-lg border border-line/80 bg-bg/40 p-0.5">
          {(["easy", "research", "rtl"] as const).map((lv) => (
            <button
              key={lv}
              type="button"
              onClick={() => setLevel(lv)}
              className={cn(
                "rounded-md px-2.5 py-1 text-caption",
                level === lv ? cn("bg-card", MODE[lv].tone) : "text-subtle hover:text-fg",
              )}
            >
              {lv === "easy" ? "Dễ hiểu" : lv === "research" ? "Research" : "RTL"}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

export function stageName(id: keyof typeof STAGE_LABEL.easy, level: ViewLevel) {
  return STAGE_LABEL[level][id];
}
