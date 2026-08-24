import assert from "node:assert/strict";
import { after, test } from "node:test";
import {
  ConnectionState,
  Session,
  TelemetryFrame,
  WaveformResult,
} from "@glassbox/contracts";
import { startServer } from "../src/http.ts";

/**
 * Mirrors the frontend HTTP adapter against the same routes. Lives here so
 * the frontend package does not import the service.
 */
const handle = await startServer(0);
const root = `http://127.0.0.1:${handle.port}`;

after(async () => {
  await handle.close();
});

test("HTTP client shaped like GlassBoxPorts round-trips session and range", async () => {
  const session = Session.parse(await (await fetch(`${root}/v1/session`)).json());
  const connection = ConnectionState.parse(await (await fetch(`${root}/v1/connection`)).json());
  assert.equal(session.sessionId, "ses-backend-synthetic-01");
  assert.equal(connection.connected, false);
  assert.equal(connection.activeSource, "SYNTHETIC");

  const ranged = WaveformResult.parse(
    await (await fetch(`${root}/v1/waveform/9001/range?from=0&to=10`)).json(),
  );
  assert.equal(ranged.available, true);

  const raw = await (await fetch(`${root}/v1/telemetry`)).text();
  const frames = raw
    .split("\n\n")
    .map((block) => block.split("\n").find((line) => line.startsWith("data: ")))
    .filter((line): line is string => Boolean(line))
    .map((line) => TelemetryFrame.parse(JSON.parse(line.slice(6))));
  assert.ok(frames.length >= 1);
});
