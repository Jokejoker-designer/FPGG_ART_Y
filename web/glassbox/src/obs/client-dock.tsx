"use client";

import { useEffect } from "react";
import { hydrateFromPorts } from "@/adapters/hydrate";
import { useStudio } from "@/lib/store";
import { GlassBoxInstrument } from "./glass-panels";

export function ClientDock() {
  const setLevel = useStudio((s) => s.setLevel);
  useEffect(() => {
    setLevel("research");
    void hydrateFromPorts().catch(() => {
      /* UART capture still renders. */
    });
  }, [setLevel]);

  return (
    <div className="h-full min-h-0 overflow-y-auto px-3 py-3 gbx-scroll">
      <GlassBoxInstrument />
    </div>
  );
}
