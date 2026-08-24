import { useState } from "react";
import { explainTopic, type ExplainTopic } from "@/lib/explain-rules";
import { Btn } from "./ui";

/**
 * §22 Giải thích. Frozen rules + live numbers.
 *
 * Owner: gb-ux-product.
 */
export function Explain({ id }: { id: ExplainTopic }) {
  const [open, setOpen] = useState(false);
  const g = explainTopic(id);
  return (
    <div className="relative inline-block">
      <Btn variant="soft" className="h-7 px-2 text-[11px]" onClick={() => setOpen(!open)}>
        Giải thích
      </Btn>
      {open ? (
        <div
          role="dialog"
          aria-label={g.title}
          className="absolute right-0 z-30 mt-2 w-72 rounded-lg border border-line bg-card p-3 text-left shadow-[var(--shadow-panel)]"
        >
          <div className="text-xs font-medium text-fg">{g.title}</div>
          <p className="mt-1 text-[12px] leading-relaxed text-muted">{g.body}</p>
        </div>
      ) : null}
    </div>
  );
}
