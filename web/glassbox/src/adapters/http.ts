/**
 * Live transport for GlassBoxPorts. Components never import this file.
 *
 * GET + SSE only. No WebSocket (websocket-security: no Upgrade handshake).
 * Every payload is parsed with the frozen Zod schemas. Default app selection
 * stays fixture until VITE_GLASSBOX_TRANSPORT=http.
 *
 * Owner: gb-frontend-architecture.
 */
import {
  ConnectionState,
  EmbeddingRow,
  HealthSeries,
  HiddenVector,
  Interaction,
  InteractionSummary,
  Projection2D,
  Session,
  TelemetryFrame,
  WaveformResult,
  type GlassBoxPorts,
  type InteractionId,
} from "@/lib/contract";

const DEFAULT_API = "http://127.0.0.1:8787";

async function readJson(url: string): Promise<unknown> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`glassbox http ${res.status} ${url}`);
  }
  return res.json();
}

async function readOrNull(url: string): Promise<unknown | null> {
  const res = await fetch(url);
  if (res.status === 404 || res.status === 204) return null;
  if (!res.ok) throw new Error(`glassbox http ${res.status} ${url}`);
  return res.json();
}

function parseSseFrames(raw: string) {
  return raw
    .split("\n\n")
    .map((block) => block.split("\n").find((line) => line.startsWith("data: ")))
    .filter((line): line is string => Boolean(line))
    .map((line) => TelemetryFrame.parse(JSON.parse(line.slice(6))));
}

export function createHttpPorts(baseUrl = DEFAULT_API): GlassBoxPorts {
  const root = baseUrl.replace(/\/$/, "");

  const sessionPort = {
    async getSession() {
      return Session.parse(await readJson(`${root}/v1/session`));
    },
    async listInteractions(limit?: number) {
      const rows = InteractionSummary.array().parse(await readJson(`${root}/v1/interactions`));
      return limit === undefined ? rows : rows.slice(0, limit);
    },
    async getInteraction(id: InteractionId) {
      const body = await readOrNull(`${root}/v1/interactions/${id}`);
      return body === null ? null : Interaction.parse(body);
    },
    async getConnectionState() {
      return ConnectionState.parse(await readJson(`${root}/v1/connection`));
    },
  };

  return {
    session: sessionPort,
    snapshot: {
      async getHiddenVectors(id) {
        return HiddenVector.array().parse(await readJson(`${root}/v1/hidden/${id}`));
      },
      async getEmbeddingRows(id) {
        return EmbeddingRow.array().parse(await readJson(`${root}/v1/embeddings/${id}`));
      },
      async getProjection(id) {
        const body = await readOrNull(`${root}/v1/projection/${id}`);
        return body === null ? null : Projection2D.parse(body);
      },
      async getHealthSeries() {
        return HealthSeries.parse(await readJson(`${root}/v1/health-series`));
      },
    },
    waveform: {
      kind: "SYNTHETIC",
      async listCaptures(interactionId) {
        const result = WaveformResult.parse(await readJson(`${root}/v1/waveform/${interactionId}`));
        return result.available ? [result.capture.captureId] : [];
      },
      async getCapture(captureId) {
        const session = await sessionPort.getSession();
        for (const row of session.interactions) {
          const ids = await this.listCaptures(row.interactionId);
          if (ids.includes(captureId)) {
            return WaveformResult.parse(await readJson(`${root}/v1/waveform/${row.interactionId}`));
          }
        }
        return WaveformResult.parse({
          available: false,
          absence: {
            interactionId: "0",
            reason: "SOURCE_UNAVAILABLE",
            detail: `No capture named ${captureId} on the HTTP store.`,
          },
        });
      },
      async getRange(captureId, from, to) {
        const session = await sessionPort.getSession();
        for (const row of session.interactions) {
          const ids = await this.listCaptures(row.interactionId);
          if (ids.includes(captureId)) {
            return WaveformResult.parse(
              await readJson(`${root}/v1/waveform/${row.interactionId}/range?from=${from}&to=${to}`),
            );
          }
        }
        return this.getCapture(captureId);
      },
    },
    telemetry: {
      async subscribe(onFrame, options) {
        const url = new URL(`${root}/v1/telemetry`);
        if (options?.fromCursor) url.searchParams.set("fromCursor", options.fromCursor);
        if (typeof EventSource === "undefined") {
          const headers: Record<string, string> = {};
          if (options?.fromCursor) headers["Last-Event-ID"] = options.fromCursor;
          const raw = await (await fetch(url, { headers, signal: options?.signal })).text();
          for (const frame of parseSseFrames(raw)) {
            if (options?.signal?.aborted) return;
            onFrame(frame);
          }
          return;
        }
        await new Promise<void>((resolve) => {
          const source = new EventSource(url);
          const stop = () => {
            source.close();
            resolve();
          };
          options?.signal?.addEventListener("abort", stop, { once: true });
          source.onmessage = (event) => {
            onFrame(TelemetryFrame.parse(JSON.parse(event.data)));
          };
          source.onerror = stop;
        });
      },
    },
  };
}
