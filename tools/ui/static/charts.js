/* Hand-rolled SVG charts. No build step, no dependencies, no CDN.

   Accessibility decisions that shaped this file:
   - Series are separated by dash pattern and marker shape, not colour. On a dark
     background every series colour has to clear 3:1 against the panel, which
     forces them all into a narrow luminance band, so no two of them can reach
     3:1 from each other. Colour cannot be the encoding here.
   - Each chart gets role="img" and an aria-label that states the *trend*, which
     is the one sentence a sighted operator takes from it.
   - Figures with no other on-screen presentation (Wh delta, E delta, gradients,
     state timelines) also emit a <details> data table of the non-zero cells. */

const NS = "http://www.w3.org/2000/svg";

function el(name, attrs, text) {
  const n = document.createElementNS(NS, name);
  for (const k in attrs || {}) if (attrs[k] !== null && attrs[k] !== undefined) n.setAttribute(k, attrs[k]);
  if (text !== undefined) n.textContent = text;
  return n;
}

function frame(box, W, H) {
  box.innerHTML = "";
  const svg = el("svg", { viewBox: `0 0 ${W} ${H}`, role: "img" });
  box.appendChild(svg);
  return svg;
}

function empty(box, msg, action) {
  box.innerHTML = "";
  const d = document.createElement("div");
  d.className = "empty";
  d.appendChild(Object.assign(document.createElement("span"), { textContent: msg }));
  if (action) {
    const b = document.createElement("button");
    b.className = "btn ghost";
    b.type = "button";
    b.textContent = action.label;
    b.addEventListener("click", action.onClick);
    d.appendChild(b);
  }
  box.appendChild(d);
}

function fmt(v) {
  const a = Math.abs(v);
  if (a >= 1e6) return (v / 1e6).toFixed(1) + "M";
  if (a >= 1000) return Math.round(v).toLocaleString("vi-VN");
  if (a >= 1) return String(Math.round(v * 10) / 10);
  if (a === 0) return "0";
  return v.toFixed(3);
}

function marker(svg, kind, x, y, color) {
  if (kind === "square") return svg.appendChild(el("rect", { x: x - 2.6, y: y - 2.6, width: 5.2, height: 5.2, fill: color }));
  if (kind === "triangle") return svg.appendChild(el("polygon", { points: `${x},${y - 3.2} ${x + 3},${y + 2.4} ${x - 3},${y + 2.4}`, fill: color }));
  return svg.appendChild(el("circle", { cx: x, cy: y, r: 2.6, fill: color }));
}

function describe(svg, label) {
  svg.setAttribute("aria-label", label);
}

function trendOf(s) {
  if (s.points.length < 2) return `${s.name}: chưa đủ dữ liệu`;
  const a = s.points[0][1], b = s.points[s.points.length - 1][1];
  if (b === a) return `${s.name}: không đổi ở ${fmt(a)} qua ${s.points.length} điểm`;
  const dir = b > a ? "tăng từ %s lên %s" : "giảm từ %s xuống %s";
  return `${s.name}: ` + dir.replace("%s", fmt(a)).replace("%s", fmt(b))
    + ` qua ${s.points.length} điểm`;
}

/* Non-zero cells as a real table. A 1024-cell dump is conformant but useless;
   sign(g) is sparse by construction and the non-zero subset is what a sighted
   operator reads off the figure too. */
function dataTable(box, caption, rows, cols, values, rowName, colName) {
  const nz = [];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const v = values[r * cols + c] || 0;
      if (v !== 0) nz.push([rowName(r), colName(c), v]);
    }
  }
  const d = document.createElement("details");
  d.className = "dataview";
  d.innerHTML = `<summary>Bảng số liệu: ${caption} — ${nz.length} ô khác 0 trong ${rows * cols}</summary>`;
  if (nz.length) {
    const w = document.createElement("div");
    w.className = "table-wrap";
    w.innerHTML = `<table><caption>${caption}</caption><thead><tr>`
      + `<th scope="col">hàng</th><th scope="col">cột</th><th scope="col" class="num">giá trị</th>`
      + `</tr></thead><tbody>`
      + nz.slice(0, 400).map(([a, b, v]) =>
        `<tr><th scope="row">${a}</th><td>${b}</td><td class="num">${v}</td></tr>`).join("")
      + `</tbody></table>`;
    d.appendChild(w);
  }
  box.appendChild(d);
}

/* ------------------------------------------------------------------ lines */
/* series: [{name, color, points:[[x,y]], dash, marker}] */
export function lineChart(box, series, opts = {}) {
  const W = 760, H = opts.height || 250;
  const m = { l: 60, r: 54, t: 12, b: 34 };
  const pts = series.flatMap((s) => s.points);
  if (!pts.length) { empty(box, opts.empty || "chưa có dữ liệu", opts.action); return; }

  const svg = frame(box, W, H);
  let xlo = Math.min(...pts.map((p) => p[0])), xhi = Math.max(...pts.map((p) => p[0]));
  let ylo = Math.min(...pts.map((p) => p[1])), yhi = Math.max(...pts.map((p) => p[1]));
  if (opts.y0) ylo = Math.min(0, ylo);
  const pad = (yhi - ylo) * 0.08 || 1;
  ylo -= pad; yhi += pad;
  if (xlo === xhi) xhi = xlo + 1;

  const X = (v) => m.l + ((v - xlo) / (xhi - xlo)) * (W - m.l - m.r);
  const Y = (v) => H - m.b - ((v - ylo) / (yhi - ylo)) * (H - m.t - m.b);

  for (let i = 0; i <= 4; i++) {
    const v = ylo + (i / 4) * (yhi - ylo);
    svg.appendChild(el("line", { x1: m.l, y1: Y(v), x2: W - m.r, y2: Y(v), stroke: "#ffffff26" }));
    svg.appendChild(el("text", { x: m.l - 8, y: Y(v) + 4, fill: "#98a2c6", "text-anchor": "end" }, fmt(v)));
  }
  if (ylo < 0 && yhi > 0) {
    svg.appendChild(el("line", { x1: m.l, y1: Y(0), x2: W - m.r, y2: Y(0), stroke: "#73798b", "stroke-width": 1.5, "stroke-dasharray": "3 3" }));
  }
  (opts.marks || []).forEach((mk) => {
    svg.appendChild(el("line", { x1: m.l, y1: Y(mk.y), x2: W - m.r, y2: Y(mk.y), stroke: mk.color || "#ffc36b", "stroke-dasharray": "5 4", "stroke-width": 1.3 }));
    svg.appendChild(el("text", { x: m.l + 4, y: Y(mk.y) - 5, fill: mk.color || "#ffc36b" }, mk.label || ""));
  });

  // step counts and epoch budgets are integers; a tick reading "11.3 bước" is wrong
  const xInt = pts.every((p) => Number.isInteger(p[0]));
  for (let i = 0; i <= 4; i++) {
    const raw = xlo + (i / 4) * (xhi - xlo);
    const v = xInt ? Math.round(raw) : raw;
    svg.appendChild(el("text", { x: X(raw), y: H - 12, fill: "#98a2c6", "text-anchor": "middle" }, fmt(v)));
  }
  if (opts.xlabel) svg.appendChild(el("text", { x: (W + m.l) / 2, y: H - 1, fill: "#98a2c6", "text-anchor": "middle" }, opts.xlabel));

  series.forEach((s) => {
    if (!s.points.length) return;
    const d = s.points.map((p, i) => `${i ? "L" : "M"}${X(p[0]).toFixed(1)},${Y(p[1]).toFixed(1)}`).join("");
    svg.appendChild(el("path", { d, fill: "none", stroke: s.color, "stroke-width": 2, "stroke-dasharray": s.dash || null, "stroke-linejoin": "round" }));
    if (s.points.length <= 80) s.points.forEach((p) => marker(svg, s.marker, X(p[0]), Y(p[1]), s.color));
    const last = s.points[s.points.length - 1];
    svg.appendChild(el("text", { x: X(last[0]) + 7, y: Y(last[1]) + 4, fill: s.color, "font-size": 10 }, s.shortName || s.name));
  });

  describe(svg, `${opts.caption || "Đồ thị"}. ` + series.filter((s) => s.points.length).map(trendOf).join(". ") + ".");
}

/* ------------------------------------------------------------------- bars */
export function barChart(box, values, opts = {}) {
  if (!values.length) { empty(box, opts.empty || "chưa có dữ liệu", opts.action); return; }
  const W = 760, H = opts.height || 200;
  const m = { l: 58, r: 12, t: 12, b: opts.tickLabels ? 74 : 24 };
  const svg = frame(box, W, H);
  let lo = Math.min(0, ...values), hi = Math.max(0, ...values);
  if (opts.symmetric) { const a = Math.max(Math.abs(lo), Math.abs(hi)) || 1; lo = -a; hi = a; }
  if (opts.ymax !== undefined) hi = opts.ymax;
  if (lo === hi) hi = lo + 1;
  const Y = (v) => H - m.b - ((v - lo) / (hi - lo)) * (H - m.t - m.b);
  const bw = (W - m.l - m.r) / values.length;

  [lo, (lo + hi) / 2, hi].forEach((v) => {
    svg.appendChild(el("line", { x1: m.l, y1: Y(v), x2: W - m.r, y2: Y(v), stroke: "#ffffff26" }));
    svg.appendChild(el("text", { x: m.l - 7, y: Y(v) + 4, fill: "#98a2c6", "text-anchor": "end" }, fmt(v)));
  });
  (opts.marks || []).forEach((mk) => {
    svg.appendChild(el("line", { x1: m.l, y1: Y(mk.y), x2: W - m.r, y2: Y(mk.y), stroke: mk.color || "#ffc36b", "stroke-dasharray": "5 4" }));
    svg.appendChild(el("text", { x: m.l + 4, y: Y(mk.y) - 4, fill: mk.color || "#ffc36b" }, mk.label || ""));
  });

  const zero = Y(Math.max(lo, Math.min(0, hi)));
  values.forEach((v, i) => {
    const y = Y(v), h = Math.max(1, Math.abs(zero - y));
    const c = opts.colorAt ? opts.colorAt(i, v) : "#6ba4ff";
    const r = el("rect", { x: m.l + i * bw + bw * 0.12, y: Math.min(y, zero), width: Math.max(1, bw * 0.76), height: h, fill: c, rx: 1.5 });
    r.appendChild(el("title", {}, `${opts.labelAt ? opts.labelAt(i) : i}: ${v}`));
    svg.appendChild(r);
    // sign as a glyph so the bar direction is not the only cue
    if (opts.signGlyph && v !== 0 && bw > 9) {
      svg.appendChild(el("text", {
        x: m.l + i * bw + bw / 2, y: v > 0 ? Math.min(y, zero) - 3 : Math.max(y, zero) + 10,
        fill: c, "text-anchor": "middle", "font-size": 9, "aria-hidden": "true",
      }, v > 0 ? "+" : "\u2212"));
    }
  });
  // named categories need visible labels, not just <title> tooltips
  if (opts.tickLabels) {
    values.forEach((_, i) => {
      const x = m.l + i * bw + bw / 2;
      const t = el("text", { x: 0, y: 0, fill: "#98a2c6", "text-anchor": "end", "font-size": 10,
        transform: `translate(${x.toFixed(1)},${H - m.b + 12}) rotate(-38)` },
        opts.labelAt ? opts.labelAt(i) : String(i));
      svg.appendChild(t);
    });
  }
  if (opts.xlabel) svg.appendChild(el("text", { x: (W + m.l) / 2, y: H - 4, fill: "#98a2c6", "text-anchor": "middle" }, opts.xlabel));

  const nz = values.filter((v) => v !== 0).length;
  const pos = values.filter((v) => v > 0).length;
  describe(svg, `${opts.caption || "Biểu đồ cột"}: ${values.length} cột, ${nz} khác 0 `
    + `(${pos} dương, ${nz - pos} âm), lớn nhất ${fmt(Math.max(...values.map(Math.abs)))}.`);
  if (opts.table) {
    dataTable(box, opts.caption || "biểu đồ", 1, values.length, values,
      () => "giá trị", (c) => (opts.labelAt ? opts.labelAt(c) : String(c)));
  }
}

/* ---------------------------------------------------------------- heatmap */
export function heatmap(box, values, rows, cols, opts = {}) {
  if (!values.length) { empty(box, opts.empty || "chưa có dữ liệu", opts.action); return; }
  const cell = opts.cell || 13, gap = 1;
  const W = cols * (cell + gap) + 54, H = rows * (cell + gap) + 26;
  const svg = frame(box, W, H);
  svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
  const amax = opts.amax || Math.max(1, ...values.map((v) => Math.abs(v)));
  const rowName = opts.rowName || ((r) => "r" + r);
  const colName = opts.colName || ((c) => "c" + c);

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const v = values[r * cols + c] || 0;
      const t = Math.min(1, Math.abs(v) / amax);
      let fill = "#141c38";
      if (v > 0) fill = `rgba(53,208,165,${0.15 + 0.85 * t})`;
      else if (v < 0) fill = `rgba(255,122,138,${0.15 + 0.85 * t})`;
      const x = 50 + c * (cell + gap), y = 4 + r * (cell + gap);
      const rc = el("rect", { x, y, width: cell, height: cell, fill, rx: 2 });
      rc.appendChild(el("title", {}, `${rowName(r)}, ${colName(c)} = ${v}`));
      svg.appendChild(rc);
      // sign glyph: the whole point of these figures is the sign, and no two
      // bright hues on this background can reach 3:1 from each other
      if (v !== 0 && cell >= 11 && opts.signGlyph !== false) {
        svg.appendChild(el("text", {
          x: x + cell / 2, y: y + cell / 2 + 3.5, fill: t > 0.55 ? "#0b1020" : "#e8ecf8",
          "font-size": cell * 0.7, "text-anchor": "middle", "aria-hidden": "true",
        }, v > 0 ? "+" : "\u2212"));
      }
    }
    const every = Math.max(1, Math.ceil(rows / 18));
    if (r % every === 0) {
      svg.appendChild(el("text", { x: 45, y: 4 + r * (cell + gap) + cell - 2, fill: "#98a2c6", "text-anchor": "end", "font-size": 9.5 }, rowName(r)));
    }
  }
  svg.appendChild(el("text", { x: 50, y: H - 6, fill: "#98a2c6", "font-size": 9.5 },
    opts.footer || `+ tăng  \u2212 giảm  ·  |max| = ${amax}`));

  const nz = values.filter((v) => v !== 0).length;
  describe(svg, `${opts.caption || "Bản đồ nhiệt"}: ${rows}×${cols}, ${nz} ô khác 0, |max| ${amax}. ${opts.footer || ""}`);
  if (opts.table !== false) dataTable(box, opts.caption || "bản đồ nhiệt", rows, cols, values, rowName, colName);
}

/* --------------------------------------------------------- state timeline */
export function stateTimeline(box, states, tokens, opts = {}) {
  if (!states || !states.length) { empty(box, opts.empty || "chưa có dữ liệu", opts.action); return; }
  const rows = states.length, cols = states[0].length;
  const flat = [];
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) flat.push(states[r][c]);
  const label = (b) => (b >= 0x20 && b <= 0x7e
    ? `'${String.fromCharCode(b)}'` : "0x" + b.toString(16).toUpperCase().padStart(2, "0"));
  heatmap(box, flat, rows, cols, {
    cell: opts.cell || 14,
    amax: 32767,
    signGlyph: false,
    rowName: (r) => (tokens && tokens[r] !== undefined ? `t${r} ${label(tokens[r])}` : `t${r}`),
    colName: (c) => `h[${c}]`,
    caption: opts.caption || "trạng thái h theo từng byte",
    footer: "mỗi hàng là h sau một byte · đậm = gần 32767 (bão hoà)",
    table: false,
  });
}

export { empty };
