/**
 * Deterministic pseudo-random source for fixtures.
 *
 * Fixtures must be byte-identical on every run: a Playwright snapshot, a
 * Storybook story and a reviewer's local check have to see the same numbers.
 * `Math.random()` is therefore banned in `src/fixtures/**`.
 *
 * Owner: gb-frontend-architecture.
 */

/** mulberry32. Small, fast, and stable across engines for a fixed seed. */
export function createRng(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Inclusive integer in [min, max]. */
export function rngInt(rng: () => number, min: number, max: number): number {
  return min + Math.floor(rng() * (max - min + 1));
}

/** Pick without mutating the source array. */
export function rngPick<T>(rng: () => number, items: readonly T[]): T {
  const item = items[Math.floor(rng() * items.length)];
  if (item === undefined) {
    throw new Error("rngPick called with an empty list");
  }
  return item;
}
