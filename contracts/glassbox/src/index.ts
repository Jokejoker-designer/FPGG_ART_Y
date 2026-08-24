/**
 * Frozen contract shared by the GlassBox frontend and backend.
 *
 * Owner: the `gb-backend-contract` subagent. Both lanes consume this and
 * neither edits it. A breaking change bumps CONTRACT_VERSION in primitives.ts
 * and is announced in the turn report so both lanes can react.
 *
 * Relative imports carry an explicit `.ts` extension so this package runs
 * unbundled under `node --test` as well as through the Next bundler.
 */
export * from "./primitives.ts";
export * from "./telemetry.ts";
export * from "./snapshot.ts";
export * from "./waveform.ts";
export * from "./session.ts";
export * from "./ports.ts";
