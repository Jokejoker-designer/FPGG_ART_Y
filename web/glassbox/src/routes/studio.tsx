"use client";

import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { hydrateFromPorts } from "@/adapters/hydrate";
import { StudioShell } from "@/components/shell";
import { StudioState } from "@/components/ui/studio-state";

export const Route = createFileRoute("/studio")({ component: StudioPage });

function StudioPage() {
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
        setError(cause instanceof Error ? cause.message : "hydrate failed");
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
