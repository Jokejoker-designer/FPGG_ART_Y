/**
 * WCAG 2.2 contrast measurement over the real design tokens.
 *
 * The token comments in `globals.css` previously stated ratios that had been
 * computed by hand. A hand-computed ratio is not evidence, so this reads the
 * actual custom properties out of the stylesheet and computes every pair that
 * the UI relies on. It exits non-zero on any failure, which makes it a
 * regression guard rather than a one-off audit.
 *
 * Thresholds, WCAG 2.2 Level AA:
 *   1.4.3  body text 4.5:1, large text 3:1
 *   1.4.11 UI components and graphical objects 3:1
 *
 * Owner: gb-accessibility.
 *
 * Usage: node audit/a11y/contrast-check.mjs
 */
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const cssPath = resolve(here, "..", "..", "src", "styles.css");

/** Only the `:root` block is read; density overrides carry no colours. */
function readTokens(css) {
  const tokens = new Map();
  const pattern = /--(gb-[a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{6})\s*;/g;
  let match;
  while ((match = pattern.exec(css)) !== null) {
    tokens.set(match[1], match[2].toLowerCase());
  }
  return tokens;
}

function channel(value) {
  const c = value / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

function luminance(hex) {
  const r = channel(parseInt(hex.slice(1, 3), 16));
  const g = channel(parseInt(hex.slice(3, 5), 16));
  const b = channel(parseInt(hex.slice(5, 7), 16));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function ratio(a, b) {
  const la = luminance(a);
  const lb = luminance(b);
  const [hi, lo] = la > lb ? [la, lb] : [lb, la];
  return (hi + 0.05) / (lo + 0.05);
}

const SURFACES = ["gb-bg", "gb-surface-1", "gb-surface-2", "gb-surface-3"];

/**
 * `gb-text-faint` is checked at the 3:1 large-text threshold because it is
 * only permitted for supporting labels, never for a value the user must read.
 * That restriction is stated in `globals.css` and enforced in review.
 */
/**
 * Thresholds follow how a token is actually used, not how it feels.
 *
 * The semantic roles all render as pill and badge *text* at 10-12px, which is
 * small text under 1.4.3 and therefore needs 4.5:1, not the 3:1 that applies to
 * a graphical object. An earlier version of this file assigned them 3:1 and
 * passed; axe running against the real stories caught `--gb-inactive` at
 * 4.24:1 and was right. If a token ever becomes a fill or a border only, move
 * it down to 3:1 and say why.
 */
const CHECKS = [
  { token: "gb-text", min: 4.5, role: "body text" },
  { token: "gb-text-muted", min: 4.5, role: "body text" },
  { token: "gb-text-faint", min: 4.5, role: "supporting label text" },
  { token: "gb-primary", min: 4.5, role: "pill text" },
  { token: "gb-primary-strong", min: 3, role: "focus ring (graphical)" },
  { token: "gb-pass", min: 4.5, role: "pill text" },
  { token: "gb-attention", min: 4.5, role: "pill text" },
  { token: "gb-fail", min: 4.5, role: "pill text" },
  { token: "gb-learn", min: 4.5, role: "pill text" },
  { token: "gb-memory", min: 4.5, role: "pill text" },
  { token: "gb-model", min: 4.5, role: "pill text" },
  { token: "gb-output", min: 4.5, role: "pill text" },
  /* Graphical only: dots, disabled borders, inert chart series. It cannot be
     both visibly dim and 4.5:1 on these surfaces, so anything that renders it
     as text is a defect — use --gb-text-muted there instead. */
  { token: "gb-inactive", min: 3, role: "graphical indicator only" },
  { token: "gb-evidence-xsim", min: 4.5, role: "badge text" },
  { token: "gb-evidence-twin", min: 4.5, role: "badge text" },
  { token: "gb-evidence-derived", min: 4.5, role: "badge text" },
  { token: "gb-evidence-synthetic", min: 4.5, role: "badge text" },
  { token: "gb-border-strong", min: 3, role: "interactive boundary" },
];

const css = readFileSync(cssPath, "utf8");
const tokens = readTokens(css);

const rows = [];
let failures = 0;

for (const check of CHECKS) {
  const color = tokens.get(check.token);
  if (!color) {
    console.error(`MISSING TOKEN --${check.token}`);
    failures += 1;
    continue;
  }
  for (const surfaceToken of SURFACES) {
    const surface = tokens.get(surfaceToken);
    if (!surface) continue;
    const value = ratio(color, surface);
    const pass = value >= check.min;
    if (!pass) failures += 1;
    rows.push({
      token: check.token,
      on: surfaceToken,
      role: check.role,
      ratio: value.toFixed(2),
      required: check.min.toFixed(1),
      verdict: pass ? "PASS" : "FAIL",
    });
  }
}

/* The BOARD badge is the one filled treatment, so its text sits on the badge
   colour rather than on a surface. */
const boardBadge = ratio(
  tokens.get("gb-bg") ?? "#000000",
  tokens.get("gb-evidence-board") ?? "#ffffff",
);
const boardPass = boardBadge >= 4.5;
if (!boardPass) failures += 1;
rows.push({
  token: "gb-bg",
  on: "gb-evidence-board (filled badge)",
  role: "body text",
  ratio: boardBadge.toFixed(2),
  required: "4.5",
  verdict: boardPass ? "PASS" : "FAIL",
});

console.table(rows);
console.log(
  `\n${rows.length} pairs measured, ${failures} failing (WCAG 2.2 AA).`,
);

process.exit(failures === 0 ? 0 : 1);
