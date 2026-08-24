"use client";

import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { hydrateFromPorts } from "@/adapters/hydrate";
import { transportName } from "@/adapters";
import { StudioShell } from "@/components/shell";
import { StudioState } from "@/components/ui/studio-state";

export const Route = createFileRoute("/")({ component: Home });

/**
 * The shell is a client instrument (Zustand + keyboard). Mounting it only
 * after hydration avoids a dead SSR tree whose buttons do not change tab.
 * Session bytes come from GlassBoxPorts, never from a component fetch.
 */
function Home() {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    let cancelled = false;
    void hydrateFromPorts()
      .then(() => {
        if (!cancelled) setReady(true);
      })
      .catch((cause: unknown) => {
        if (cancelled) return;
        const message = cause instanceof Error ? cause.message : "hydrate failed";
        setError(
          transportName() === "http"
            ? `Không đọc được dịch vụ SYNTHETIC (${message}). Không bịa số từ fixture.`
            : message,
        );
      });
    return () => {
      cancelled = true;
    };
  }, []);
  if (error) {
    return (
      <div className="p-6" role="alert">
        <StudioState kind="error">
          <p className="mt-2 text-sm text-muted">{error}</p>
        </StudioState>
      </div>
    );
  }
  if (!ready) {
    return (
      <div className="p-6" role="status">
        <StudioState kind="loading" />
      </div>
    );
  }
  return <StudioShell />;
}
