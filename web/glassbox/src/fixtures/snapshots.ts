/**
 * §35.2 snapshot-plane fixtures: embedding rows and the 2D projection.
 *
 * These live outside `Interaction` on purpose. §35 keeps the three planes
 * separate and merges them only by explicit identifiers, so a screen that wants
 * a vector has to ask for it rather than finding it already loaded. That is
 * also what keeps the telemetry stream small.
 *
 * Owner: gb-frontend-architecture.
 */
import {
  EMBED_DIM,
  EmbeddingRow,
  Projection2D,
  type HiddenVector,
} from "@/lib/contract";
import { FIXTURE_SESSION } from "./session";
import { createRng, rngInt } from "./prng";
import { FIXTURE_CAPTURED_AT, SYNTHETIC, derived } from "./provenance";

/** Rows of E for the bytes an interaction actually read. */
function buildEmbeddingRows(bytes: readonly number[]): EmbeddingRow[] {
  return [...new Set(bytes)]
    .sort((a, b) => a - b)
    .map((byte) => {
      const rng = createRng(0xe0_0000 + byte);
      const values = Array.from({ length: EMBED_DIM }, () =>
        rngInt(rng, -127, 127),
      );
      return EmbeddingRow.parse({ byte, values, provenance: SYNTHETIC });
    });
}

const EMBEDDING_ROWS: Record<string, EmbeddingRow[]> = Object.fromEntries(
  FIXTURE_SESSION.interactions.map((interaction) => [
    interaction.interactionId,
    buildEmbeddingRows(
      interaction.input.flatMap((event) =>
        event.tokens.map((token) => token.byte),
      ),
    ),
  ]),
);

/**
 * Two fixed random axes, seeded once, applied to the full 32-dimensional
 * vector. This is deliberately the crudest defensible projection: §12 requires
 * the result to be labelled `MINH HỌA 2D`, and a method that looks
 * sophisticated would invite the reader to trust the picture over the numbers.
 * The method string says exactly this on screen.
 */
const PROJECTION_METHOD =
  "Chiếu vector 32 chiều lên hai trục ngẫu nhiên cố định. Chỉ để hình dung.";

const PROJECTION_SEED = 0x2d_1234;

function projectionAxes(): [number[], number[]] {
  const rng = createRng(PROJECTION_SEED);
  const axis = () => Array.from({ length: 32 }, () => rng() * 2 - 1);
  return [axis(), axis()];
}

function dot(a: readonly number[], b: readonly number[]): number {
  let sum = 0;
  for (let i = 0; i < a.length; i += 1) sum += (a[i] ?? 0) * (b[i] ?? 0);
  return sum;
}

function buildProjection(vectors: readonly HiddenVector[], interactionId: string) {
  if (vectors.length === 0) return null;
  const [ax, ay] = projectionAxes();

  /* Normalised into a stable box so the chart never has to rescale between
     interactions, which would make two screens visually incomparable. */
  const raw = vectors.map((vector) => ({
    role: vector.role,
    stage: vector.stage,
    x: dot(vector.values, ax),
    y: dot(vector.values, ay),
  }));
  const span = Math.max(
    ...raw.flatMap((point) => [Math.abs(point.x), Math.abs(point.y)]),
    1,
  );

  return Projection2D.parse({
    interactionId,
    points: raw.map((point) => ({
      role: point.role,
      stage: point.stage,
      x: Number((point.x / span).toFixed(4)),
      y: Number((point.y / span).toFixed(4)),
    })),
    method: PROJECTION_METHOD,
    provenance: derived(["h[ANCHOR]", "h[POSITIVE]", "h[NEGATIVE]"]),
  });
}

const PROJECTIONS: Record<string, Projection2D | null> = Object.fromEntries(
  FIXTURE_SESSION.interactions.map((interaction) => [
    interaction.interactionId,
    buildProjection(interaction.representation, interaction.interactionId),
  ]),
);

export function embeddingRowsFor(interactionId: string): EmbeddingRow[] {
  return EMBEDDING_ROWS[interactionId] ?? [];
}

export function projectionFor(interactionId: string): Projection2D | null {
  return PROJECTIONS[interactionId] ?? null;
}

export const SNAPSHOT_FIXTURE_CAPTURED_AT = FIXTURE_CAPTURED_AT;
