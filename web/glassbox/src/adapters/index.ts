/**
 * The only place the app decides which implementation of the ports it gets.
 *
 * SPEC §34: UI -> feature interface -> adapter -> transport.
 * FRONTEND_PASS and BACKEND_PASS are both signed. Default remains fixture so
 * Playwright and Storybook run with no backend process. HTTP is opt-in via
 * VITE_GLASSBOX_TRANSPORT=http.
 *
 * Owner: gb-frontend-architecture.
 */
import type { GlassBoxPorts } from "@/lib/contract";
import { fixturePorts } from "./fixture";
import { createHttpPorts } from "./http";

export function transportName(): "http" | "fixture" {
  return import.meta.env.VITE_GLASSBOX_TRANSPORT === "http" ? "http" : "fixture";
}

export function getPorts(): GlassBoxPorts {
  if (transportName() === "http") {
    return createHttpPorts(import.meta.env.VITE_GLASSBOX_API ?? "http://127.0.0.1:8787");
  }
  return fixturePorts;
}
