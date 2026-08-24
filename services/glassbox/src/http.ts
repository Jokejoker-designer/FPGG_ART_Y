/**
 * Localhost-only HTTP + SSE. No WebSocket: telemetry is SSE with
 * Last-Event-ID / fromCursor resume so a reconnect does not invent frames.
 *
 * websocket-security was read before considering a socket. SSE stays on GET
 * to 127.0.0.1; Origin is allow-listed. There is no Upgrade handshake.
 */
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
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
import { createSyntheticPorts } from "./store.ts";

const HOST = "127.0.0.1";
const PORT = 8787;

export const ENDPOINTS = [
  "GET /v1/health",
  "GET /v1/endpoints",
  "GET /v1/connection",
  "GET /v1/session",
  "GET /v1/interactions",
  "GET /v1/interactions/:id",
  "GET /v1/health-series",
  "GET /v1/hidden/:id",
  "GET /v1/embeddings/:id",
  "GET /v1/projection/:id",
  "GET /v1/weights/:id",
  "GET /v1/episode/:id",
  "GET /v1/waveform/:id",
  "GET /v1/waveform/:id/range?from=&to=",
  "GET /v1/telemetry  (SSE; Last-Event-ID or ?fromCursor=)",
] as const;

function corsOrigin(req: IncomingMessage): string {
  const origin = req.headers.origin;
  if (
    origin === "http://127.0.0.1:3110" ||
    origin === "http://localhost:3110" ||
    origin === "http://127.0.0.1:3000" ||
    origin === "http://localhost:3000" ||
    origin === "http://127.0.0.1:8080" ||
    origin === "http://localhost:8080" ||
    origin === "http://127.0.0.1:3111" ||
    origin === "http://localhost:3111"
  ) {
    return origin;
  }
  return "http://127.0.0.1";
}

function corsHeaders(req: IncomingMessage): Record<string, string> {
  return {
    "access-control-allow-origin": corsOrigin(req),
    "access-control-allow-headers": "Last-Event-ID",
    "access-control-allow-methods": "GET, OPTIONS",
  };
}

function json(req: IncomingMessage, res: ServerResponse, status: number, body: unknown): void {
  const text = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(text),
    "cache-control": "no-store",
    ...corsHeaders(req),
  });
  res.end(text);
}

function empty(req: IncomingMessage, res: ServerResponse, status: number): void {
  res.writeHead(status, { "cache-control": "no-store", ...corsHeaders(req) });
  res.end();
}

function notFound(req: IncomingMessage, res: ServerResponse): void {
  json(req, res, 404, { error: "not_found" });
}

export function startServer(port = PORT): Promise<{ close: () => Promise<void>; port: number }> {
  const ports = createSyntheticPorts();

  const server = createServer(async (req, res) => {
    try {
      await route(req, res, ports);
    } catch (error) {
      json(req, res, 500, { error: error instanceof Error ? error.message : "internal" });
    }
  });

  return new Promise((resolve) => {
    server.listen(port, HOST, () => {
      const address = server.address();
      const bound = typeof address === "object" && address ? address.port : port;
      resolve({
        port: bound,
        close: () =>
          new Promise((done, fail) => {
            server.close((err) => (err ? fail(err) : done()));
          }),
      });
    });
  });
}

async function route(
  req: IncomingMessage,
  res: ServerResponse,
  ports: ReturnType<typeof createSyntheticPorts>,
): Promise<void> {
  const url = new URL(req.url ?? "/", `http://${HOST}`);
  const path = url.pathname;

  if (req.method === "OPTIONS") {
    empty(req, res, 204);
    return;
  }

  if (req.method !== "GET") {
    json(req, res, 405, { error: "method_not_allowed" });
    return;
  }

  if (path === "/v1/health") {
    json(req, res, 200, { ok: true, bind: HOST, source: "SYNTHETIC", serial: false });
    return;
  }
  if (path === "/v1/endpoints") {
    json(req, res, 200, {
      source: "SYNTHETIC",
      reconnect:
        "SSE /v1/telemetry replays from Last-Event-ID or ?fromCursor=. The next frame is cursor+1. No invented samples.",
      bind: HOST,
      endpoints: [...ENDPOINTS],
    });
    return;
  }
  if (path === "/v1/connection") {
    json(req, res, 200, ConnectionState.parse(await ports.session.getConnectionState()));
    return;
  }
  if (path === "/v1/session") {
    json(req, res, 200, Session.parse(await ports.session.getSession()));
    return;
  }
  if (path === "/v1/interactions") {
    json(req, res, 200, InteractionSummary.array().parse(await ports.session.listInteractions()));
    return;
  }
  if (path === "/v1/health-series") {
    json(req, res, 200, HealthSeries.parse(await ports.snapshot.getHealthSeries()));
    return;
  }
  if (path === "/v1/telemetry") {
    await streamTelemetry(req, res, ports, url.searchParams.get("fromCursor") ?? undefined);
    return;
  }

  const interaction = path.match(/^\/v1\/interactions\/([0-9]+)$/);
  if (interaction) {
    const row = await ports.session.getInteraction(interaction[1]!);
    if (!row) {
      notFound(req, res);
      return;
    }
    json(req, res, 200, Interaction.parse(row));
    return;
  }

  const hidden = path.match(/^\/v1\/hidden\/([0-9]+)$/);
  if (hidden) {
    json(req, res, 200, HiddenVector.array().parse(await ports.snapshot.getHiddenVectors(hidden[1]!)));
    return;
  }
  const embeddings = path.match(/^\/v1\/embeddings\/([0-9]+)$/);
  if (embeddings) {
    json(req, res, 200, EmbeddingRow.array().parse(await ports.snapshot.getEmbeddingRows(embeddings[1]!)));
    return;
  }
  const projection = path.match(/^\/v1\/projection\/([0-9]+)$/);
  if (projection) {
    const value = await ports.snapshot.getProjection(projection[1]!);
    if (!value) {
      empty(req, res, 204);
      return;
    }
    json(req, res, 200, Projection2D.parse(value));
    return;
  }
  const weights = path.match(/^\/v1\/weights\/([0-9]+)$/);
  if (weights) {
    const row = await ports.session.getInteraction(weights[1]!);
    const writes = row?.learning.flatMap((event) => event.writes) ?? [];
    json(req, res, 200, WeightWrite.array().parse(writes));
    return;
  }
  const episode = path.match(/^\/v1\/episode\/([0-9]+)$/);
  if (episode) {
    const row = await ports.session.getInteraction(episode[1]!);
    if (!row?.retrieval) {
      empty(req, res, 204);
      return;
    }
    json(req, res, 200, RetrievalFunnel.parse(row.retrieval));
    return;
  }
  const range = path.match(/^\/v1\/waveform\/([0-9]+)\/range$/);
  if (range) {
    const list = await ports.waveform.listCaptures(range[1]!);
    const captureId = list[0];
    if (!captureId) {
      const interactionRow = await ports.session.getInteraction(range[1]!);
      json(
        req,
        res,
        200,
        WaveformResult.parse(
          interactionRow?.waveform ?? {
            available: false,
            absence: {
              interactionId: range[1]!,
              reason: "SOURCE_UNAVAILABLE",
              detail: "No waveform range for this interaction.",
            },
          },
        ),
      );
      return;
    }
    const from = Number(url.searchParams.get("from") ?? 0);
    const to = Number(url.searchParams.get("to") ?? 240);
    json(req, res, 200, WaveformResult.parse(await ports.waveform.getRange(captureId, from, to)));
    return;
  }
  const wave = path.match(/^\/v1\/waveform\/([0-9]+)$/);
  if (wave) {
    const list = await ports.waveform.listCaptures(wave[1]!);
    if (list[0]) {
      json(req, res, 200, WaveformResult.parse(await ports.waveform.getCapture(list[0])));
      return;
    }
    const interactionRow = await ports.session.getInteraction(wave[1]!);
    json(
      req,
      res,
      200,
      WaveformResult.parse(
        interactionRow?.waveform ?? {
          available: false,
          absence: {
            interactionId: wave[1]!,
            reason: "SOURCE_UNAVAILABLE",
            detail: "No waveform for this interaction.",
          },
        },
      ),
    );
    return;
  }

  notFound(req, res);
}

async function streamTelemetry(
  req: IncomingMessage,
  res: ServerResponse,
  ports: ReturnType<typeof createSyntheticPorts>,
  fromCursor?: string,
): Promise<void> {
  res.writeHead(200, {
    "content-type": "text/event-stream; charset=utf-8",
    "cache-control": "no-store",
    connection: "keep-alive",
    ...corsHeaders(req),
  });
  const ac = new AbortController();
  req.on("close", () => ac.abort());
  await ports.telemetry.subscribe(
    (frame) => {
      const parsed = TelemetryFrame.parse(frame);
      res.write(`id: ${parsed.cursor}\n`);
      res.write(`data: ${JSON.stringify(parsed)}\n\n`);
    },
    { fromCursor: req.headers["last-event-id"]?.toString() ?? fromCursor, signal: ac.signal },
  );
  res.end();
}

export const BIND = { host: HOST, port: PORT };
