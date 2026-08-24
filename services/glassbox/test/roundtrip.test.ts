import assert from "node:assert/strict";
import { after, test } from "node:test";
import {
  ConnectionState,
  EmbeddingRow,
  HealthSeries,
  HiddenVector,
  Interaction,
  InteractionSummary,
  Projection2D,
  RetrievalFunnel,
  Session,
  TelemetryFrame,
  WaveformResult,
  WeightWrite,
} from "@glassbox/contracts";
import { startServer } from "../src/http.ts";
import { parsedSession } from "../src/store.ts";

const handle = await startServer(0);
const base = `http://127.0.0.1:${handle.port}`;

after(async () => {
  await handle.close();
});

function sseFrames(raw: string) {
  return raw
    .split("\n\n")
    .map((block) => block.split("\n").find((line) => line.startsWith("data: ")))
    .filter((line): line is string => Boolean(line))
    .map((line) => TelemetryFrame.parse(JSON.parse(line.slice(6))));
}

test("synthetic session parses the frozen contract", () => {
  const session = parsedSession();
  assert.equal(session.build.bitstreamSha256, null);
  assert.equal(session.health.verdict, "COLLAPSED");
  assert.ok(session.interactions.length >= 2);
});

test("HTTP endpoints round-trip contract schemas", async () => {
  const session = Session.parse(await (await fetch(`${base}/v1/session`)).json());
  assert.equal(session.sessionId, "ses-backend-synthetic-01");
  assert.equal(session.build.bitstreamSha256, null);

  const connection = ConnectionState.parse(await (await fetch(`${base}/v1/connection`)).json());
  assert.equal(connection.activeSource, "SYNTHETIC");
  assert.equal(connection.connected, false);

  const catalog = await (await fetch(`${base}/v1/endpoints`)).json() as { endpoints: string[] };
  assert.ok(catalog.endpoints.some((row) => row.includes("/v1/weights/")));
  assert.ok(catalog.endpoints.some((row) => row.includes("/v1/episode/")));

  const summaries = InteractionSummary.array().parse(
    await (await fetch(`${base}/v1/interactions`)).json(),
  );
  assert.ok(summaries.length >= 2);

  const first = summaries.find((row) => row.interactionId === "9001");
  assert.ok(first);
  const interaction = Interaction.parse(
    await (await fetch(`${base}/v1/interactions/${first.interactionId}`)).json(),
  );
  assert.equal(interaction.interactionId, first.interactionId);

  HiddenVector.array().parse(await (await fetch(`${base}/v1/hidden/${first.interactionId}`)).json());
  EmbeddingRow.array().parse(await (await fetch(`${base}/v1/embeddings/${first.interactionId}`)).json());
  Projection2D.parse(await (await fetch(`${base}/v1/projection/${first.interactionId}`)).json());
  const writes = WeightWrite.array().parse(
    await (await fetch(`${base}/v1/weights/${first.interactionId}`)).json(),
  );
  assert.ok(writes.length > 0);
  RetrievalFunnel.parse(await (await fetch(`${base}/v1/episode/${first.interactionId}`)).json());
  HealthSeries.parse(await (await fetch(`${base}/v1/health-series`)).json());

  const wave = WaveformResult.parse(
    await (await fetch(`${base}/v1/waveform/${first.interactionId}`)).json(),
  );
  assert.equal(wave.available, true);
});

test("waveform range slices cycles; missing capture is an absence", async () => {
  const ranged = WaveformResult.parse(
    await (await fetch(`${base}/v1/waveform/9001/range?from=70&to=90`)).json(),
  );
  assert.equal(ranged.available, true);
  if (ranged.available) {
    assert.equal(ranged.capture.cycles.startCycle, 70);
    assert.equal(ranged.capture.cycles.endCycle, 90);
    for (const trace of ranged.capture.traces) {
      assert.ok(trace.transitions.every((t) => t.cycle >= 70 && t.cycle <= 90));
    }
  }

  const absent = WaveformResult.parse(await (await fetch(`${base}/v1/waveform/9000`)).json());
  assert.equal(absent.available, false);
  if (!absent.available) {
    assert.equal(absent.absence.reason, "PRE_FREEZE_NOT_PERMITTED");
  }

  const emptyWrites = WeightWrite.array().parse(await (await fetch(`${base}/v1/weights/9000`)).json());
  assert.equal(emptyWrites.length, 0);

  const noEpisode = await fetch(`${base}/v1/episode/9000`);
  assert.equal(noEpisode.status, 204);
});

test("SSE telemetry frames parse and resume from cursor and Last-Event-ID", async () => {
  const frames = sseFrames(await (await fetch(`${base}/v1/telemetry`)).text());
  assert.ok(frames.length >= 2);

  const resumed = sseFrames(
    await (await fetch(`${base}/v1/telemetry?fromCursor=${frames[0]!.cursor}`)).text(),
  );
  assert.equal(resumed.length, frames.length - 1);
  assert.equal(resumed[0]?.cursor, frames[1]?.cursor);

  const headerResume = sseFrames(
    await (
      await fetch(`${base}/v1/telemetry`, {
        headers: { "Last-Event-ID": frames[0]!.cursor },
      })
    ).text(),
  );
  assert.equal(headerResume.length, frames.length - 1);
});

test("missing interaction is an absence, not a fabricated row", async () => {
  const res = await fetch(`${base}/v1/interactions/0`);
  assert.equal(res.status, 404);
});
