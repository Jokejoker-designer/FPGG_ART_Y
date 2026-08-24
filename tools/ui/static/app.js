import { lineChart, barChart, heatmap, stateTimeline, empty } from "/charts.js";

const $ = (id) => document.getElementById(id);
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const enc = new TextEncoder();
const blen = (s) => enc.encode(s).length;
const MAXB = 46;

const C = getComputedStyle(document.documentElement);
const col = (n) => C.getPropertyValue(n).trim() || "#6ba4ff";

async function api(path, body) {
  const opt = body === undefined ? {} : {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
  };
  const r = await fetch(path, opt);
  const j = await r.json().catch(() => ({ error: "phản hồi không phải JSON" }));
  if (!r.ok || j.error) {
    const e = new Error(j.error || `HTTP ${r.status}`);
    e.code = j.code;
    throw e;
  }
  return j;
}

const S = {
  state: null, records: [], inspect: null, math: null, evidence: null,
  stage: 0, boardIo: null, lastSticky: [0, 0, 0, 0], follow: true,
  bench: null, busy: false, sse: "…",
};

/* ---------------------------------------------------- toasts + announcements */

function toast(msg, kind = "") {
  const d = document.createElement("div");
  d.className = "toast " + kind;
  d.textContent = msg;
  $("toasts").appendChild(d);
  setTimeout(() => d.remove(), kind === "bad" ? 8000 : 4000);
}

/* One coalesced status channel. A naive aria-live on the metrics would queue an
   announcement every 40ms during auto-training and lock a screen reader out. */
let lastAnn = 0, pendingAnn = null, annTimer = null;
function announce(msg, urgent = false) {
  if (urgent) { $("srStatus").textContent = msg; lastAnn = Date.now(); return; }
  pendingAnn = msg;
  if (annTimer) return;
  annTimer = setTimeout(() => {
    annTimer = null; lastAnn = Date.now();
    $("srStatus").textContent = pendingAnn; pendingAnn = null;
  }, Math.max(0, 2000 - (Date.now() - lastAnn)));
}

function fieldError(id, msg) {
  const inp = $(id), box = $("err" + id.slice(2));
  if (!inp || !box) return;
  inp.setAttribute("aria-invalid", msg ? "true" : "false");
  box.textContent = msg || "";
}

function banner(key, html, kind = "bad") {
  let b = document.querySelector(`[data-banner="${key}"]`);
  if (!b) {
    b = document.createElement("div");
    b.className = "banner " + (kind === "warn" ? "warn" : "");
    b.dataset.banner = key;
    $("banners").appendChild(b);
  }
  b.innerHTML = html;
  return b;
}
const clearBanner = (key) => document.querySelector(`[data-banner="${key}"]`)?.remove();

/* -------------------------------------------------------------------- tabs */

let tab = "train";
function setTab(name) {
  tab = name;
  [...$("tabs").children].forEach((b) => b.setAttribute("aria-expanded", String(b.dataset.tab === name)));
  document.querySelectorAll("section.tab").forEach((s) => s.classList.toggle("active", s.id === "tab-" + name));
  try { localStorage.setItem("a7tab", name); } catch { /* private mode */ }
  if (location.hash.slice(1) !== name) location.hash = name;
  if (name === "math") loadMath();
  if (name === "evidence") loadEvidence();
  if (name === "board") { scanPorts(); pollIo(); }
  redraw();
}
$("tabs").addEventListener("click", (e) => {
  const b = e.target.closest("button[data-tab]");
  if (b) setTab(b.dataset.tab);
});
window.addEventListener("hashchange", () => {
  const h = location.hash.slice(1);
  if (h && h !== tab && $("tab-" + h)) setTab(h);
});

/* ------------------------------------------------------------------ header */

function renderChips() {
  const st = S.state;
  if (!st) return;
  const b = st.board;
  const err = st.board_error;
  const status = [
    b ? (err
      ? `<span class="chip bad" title="${esc(err)}">BOARD LỖI</span>`
      : `<span class="chip ok">BOARD ${esc(b.port)} · ${esc(b.ident || "?")}</span>`)
      : `<span class="chip off">chưa có board</span>`,
    `<span class="chip ${st.in_sync ? "ok" : "warn"}">in_sync <b>${st.in_sync ? "có" : "không"}</b></span>`,
    st.divergences ? `<span class="chip bad">lệch <b>${st.divergences}</b></span>` : "",
    st.training ? `<span class="chip ok">đang huấn luyện</span>` : "",
    `<span class="chip ${S.sse === "live" ? "off" : "warn"}">SSE ${esc(S.sse)}</span>`,
  ];
  const ctx = [
    `<span class="chip">seed <b>${esc(st.seed)}</b></span>`,
    `<span class="chip ${st.freeze ? "warn" : (st.learn ? "ok" : "off")}">${st.freeze ? "ĐÓNG BĂNG" : (st.learn ? "HỌC" : "ĐO")}</span>`,
    `<span class="chip">bước <b>${st.step_no}</b></span>`,
  ];
  $("zoneStatus").innerHTML = status.filter(Boolean).join("");
  $("zoneCtx").innerHTML = ctx.join("");

  const mode = st.freeze ? "frozen" : (st.learn ? "learn" : "measure");
  [...$("segMode").children].forEach((b2) => b2.setAttribute("aria-pressed", String(b2.dataset.mode === mode)));

  $("modeWarn").innerHTML = mode === "learn" ? "" :
    `<div class="banner warn"><span class="grow">Đang ở chế độ <b>${mode === "frozen" ? "ĐÓNG BĂNG" : "ĐO"}</b> — trọng số sẽ <b>không đổi</b>.</span>
     <button class="btn" type="button" data-act="enable-learn">Bật học</button></div>`;
  $("btnReward").classList.toggle("inert", mode !== "learn");
  $("btnPunish").classList.toggle("inert", mode !== "learn");

  $("btnStop").disabled = !st.training;
  $("btnTrain").disabled = !!st.training || S.busy;
  const lock = !!st.training || S.busy;
  ["btnReward", "btnPunish", "btnSeed", "btnSeedGolden", "btnSeedBad"].forEach((k) => { $(k).disabled = lock; });

  if (err) {
    banner("boarderr", `<span class="grow">Liên kết board lỗi: <b>${esc(err)}</b>. Các bước tiếp theo chỉ còn TWIN.</span>
      <button class="btn" type="button" data-act="reconnect">Kết nối lại</button>
      <button class="btn ghost" type="button" data-act="dismiss" data-key="boarderr">Bỏ qua</button>`);
  } else clearBanner("boarderr");
}

$("banners").addEventListener("click", async (e) => {
  const b = e.target.closest("[data-act]");
  if (!b) return;
  const act = b.dataset.act;
  if (act === "dismiss") clearBanner(b.dataset.key);
  if (act === "enable-learn") await setMode("learn");
  if (act === "stop-train") await api("/api/train/stop", {});
  if (act === "reconnect") setTab("board");
});
$("modeWarn").addEventListener("click", async (e) => {
  if (e.target.closest('[data-act="enable-learn"]')) await setMode("learn");
});

/* --------------------------------------------------------------- pipeline */

const STAGES = [
  { n: "01", t: "Văn bản → byte", d: "UTF-8, tối đa 46 byte", val: (r) => r ? `${blen(r.a)}B / ${blen(r.b)}B` : "—",
    body: `<h4>Không có tokenizer, không có từ điển</h4>
      <p>Mô hình đọc <b>từng byte thô</b>. "ALPHA" là năm byte 65 76 80 72 65. Không có bước tách từ,
      nên chuỗi UTF-8 nào cũng chạy được — nhưng cũng không có khái niệm "từ".</p>
      <pre>host → FPGA:  A5 <span class="k">22</span> len | slot n bytes... | xor
host → FPGA:  A5 <span class="k">23</span> 01  | same</pre>
      <p>FPGA từ chối chuỗi ngắn hơn 2 byte và cắt ở 46 byte.</p>` },
  { n: "02", t: "Bảng embedding E", d: "256 byte × 32 chiều, INT8", val: () => "8192 INT8",
    body: `<h4>Mỗi mã byte có một vector 32 chiều riêng</h4>
      <p>Toàn bộ 8192 giá trị được <b>sinh trên chip</b> từ seed bằng xorshift32 — không tải trọng số
      từ máy tính. Đổi seed là đổi toàn bộ mô hình.</p>
      <pre>lfsr = xorshift32(lfsr)
E[a]  = signed(lfsr[7:0])        a = 0 … 8191</pre>
      <div class="note bad"><b>Quirk 1 đã đóng băng.</b> Đường đọc trong forward lệch một nhịp:
      <code>e_lat[j] = E[b][j−1]</code>, và <code>e_lat[0]</code> là giá trị sót của
      <code>E[byte_trước][31]</code>. Phần tử <code>E[b][31]</code> không bao giờ dùng khi tiến.
      Bảy số vàng chỉ khớp khi có lệch này.</div>` },
  { n: "03", t: "Hồi quy Wh · h", d: "32×32 INT8, 1024 phép nhân/byte", val: () => "1024 MAC/byte",
    body: `<h4>Đây là phần "nhớ"</h4><p>Trạng thái mới phụ thuộc trạng thái cũ, nên thứ tự byte có
      nghĩa. Nhân được nối tiếp hoá (<code>use_dsp = "no"</code>): mỗi byte tốn khoảng 3×1024 chu kỳ.</p>
      <pre>acc[i] = Σ<sub>j</sub> Wh[i][j] · h[j]</pre>` },
  { n: "04", t: "Trạng thái h", d: "32 × INT16, bão hoà 32767", val: (r) => r ? `bão hoà ${r.twin.sat_a}/32` : "—",
    body: `<h4>Công thức trên giấy và trên silicon khác nhau</h4>
      <pre>h[k] = e3_sat16( (acc[k] + {{8{e[7]}}, e, 8'd0}) >>> 8 )</pre>
      <div class="note bad"><b>Quirk 2 — quan trọng nhất.</b> Trong SystemVerilog, phép ghép
      <code>{...}</code> luôn <b>unsigned</b>, nên cả phép cộng thành unsigned và <code>&gt;&gt;&gt;</code>
      tụt thành dịch logic. Hệ quả: embedding <i>âm</i> biến thành số dương rất lớn, và
      <b>h không bao giờ âm</b> — bị ghim ở 32767. Ở trạng thái chưa huấn luyện, khoảng 24–25 trong 32
      chiều đã bão hoà và chỉ ~11 chiều còn mang tín hiệu. Huấn luyện tiếp làm <code>acc</code> lớn dần
      và bão hoà nốt phần còn lại: đây chính là cơ chế "DIFF collapse".</div>` },
  { n: "05", t: "Chiếu ±1 → cue", d: "64 siêu phẳng, 1 bit mỗi cái", val: (r) => r ? `dH = ${r.twin.dH}` : "—",
    body: `<h4>Nén 32 chiều thành 64 bit</h4>
      <pre>cue[p] = ( Σ<sub>j</sub> ±h[j] )  &gt;  0</pre>
      <div class="note bad"><b>Quirk 3 — đây là dự đoán, chưa được xác nhận.</b> Vế trái là concat
      unsigned nên <code>&gt; 32'sd0</code> thành so sánh unsigned, chỉ còn nghĩa "khác 0". Kết hợp
      quirk 2, <code>cue</code> ra toàn bit 1 và <code>dH</code> luôn 0. Không số vàng nào của A0.1-T
      ràng buộc <code>dH</code> — nên <b>một lần đọc PAIR từ board là đủ phủ định dự đoán này</b>.</div>` },
  { n: "06", t: "Khoảng cách d1", d: "L1 lượng tử hoá, dịch phải 5", val: (r) => r ? `d1 = ${r.twin.d1}` : "—",
    body: `<h4>Thước đo duy nhất chip báo về</h4>
      <pre>d1 = Σ<sub>i</sub> ( |hA[i] − hB[i]| >> 5 )</pre>
      <p>Phép trừ tràn trong 16 bit <i>trước khi</i> lấy trị tuyệt đối. <code>&gt;&gt;5</code> biến d1
      thành bậc thang: chênh lệch nhỏ hơn 32 đọc là 0. Vì <code>h ≥ 0</code>, mỗi chiều góp tối đa
      <code>32767 &gt;&gt; 5 = 1023</code>, nên trần thật của d1 là <b>32736</b> — phép cộng chặn ở
      0xFFFF trong RTL là <b>logic chết</b>.</p>
      <p>Cặp KHÁC chỉ sinh gradient khi <code>d1 &lt; 4096</code>.</p>` },
  { n: "07", t: "SignSGD trên chip", d: "mỗi trọng số dịch 1 LSB", val: (r) => r ? `${r.twin.e_writes} E · ${r.twin.wh_writes} Wh` : "—",
    body: `<h4>Toàn bộ việc học nằm ở đây, và nó chạy trong FPGA</h4>
      <pre>THƯỞNG (SAME):  gA = hA − hB      gB = hB − hA
PHẠT   (DIFF):  đảo dấu, chỉ khi d1 &lt; 4096

E[b][i] -= sat8( sign(g[i]) )     với mọi byte b của chuỗi đó
Wh[i][j] -= sign( g[i] · h<sub>T−1</sub>[j] )   chỉ ở bước cuối</pre>
      <p>Không learning-rate, không số thực, không phép chia. Host chỉ gửi nhãn; chip tự tính gradient
      và tự ghi trọng số.</p>
      <div class="note warn"><code>Wh</code> chỉ cập nhật từ <code>gB</code>, đối chiếu
      <code>h</code> ở bước sát cuối của chuỗi B. Bất đối xứng này nằm trong RTL đã đóng băng.</div>` },
];

function renderPipe() {
  const r = S.records[S.records.length - 1];
  $("pipe").innerHTML = STAGES.map((s, i) => `
    <button type="button" class="stage" data-i="${i}" aria-pressed="${i === S.stage}">
      <span class="n">${s.n}</span><span class="t">${s.t}</span>
      <span class="d">${s.d}</span><span class="v">${esc(s.val(r))}</span>
    </button>${i < STAGES.length - 1 ? '<div class="arrow" aria-hidden="true">→</div>' : ""}`).join("");
  $("stageDetail").innerHTML = STAGES[S.stage].body;
}
$("pipe").addEventListener("click", (e) => {
  const st = e.target.closest(".stage");
  if (st) { S.stage = +st.dataset.i; renderPipe(); }
});

/* --------------------------------------------------------------- metrics */

const real = () => S.records.filter((r) => !r.prime);
const fmtD = (m) => (m === null || m === undefined ? "—" : (m > 0 ? "+" : "") + m);

function lastWith(pred) { return [...real()].reverse().find(pred); }

function prevSame(rec) {
  const rs = real();
  const i = rs.lastIndexOf(rec);
  for (let k = i - 1; k >= 0; k--) {
    if (rs[k].a === rec.a && rs[k].b === rec.b && rs[k].same === rec.same) return rs[k];
  }
  return null;
}

function renderMetrics() {
  const ls = lastWith((r) => r.same), ld = lastWith((r) => !r.same);
  const comparable = ls && ld && ls.a === ld.a;
  const margin = ls && ld ? ld.twin.d1 - ls.twin.d1 : null;
  const last = real()[real().length - 1];
  const dOf = (r) => { const p = r && prevSame(r); return p ? r.twin.d1 - p.twin.d1 : null; };

  const cards = [
    { k: "d1 cặp GIỐNG", v: ls ? ls.twin.d1 : "—", d: dOf(ls),
      s: ls ? `${esc(ls.a)} ⇄ ${esc(ls.b)}` : "chưa có cặp GIỐNG", c: "var(--s-same)", better: "down" },
    { k: "d1 cặp KHÁC", v: ld ? ld.twin.d1 : "—", d: dOf(ld),
      s: ld ? `${esc(ld.a)} ⇄ ${esc(ld.b)}` : "chưa có cặp KHÁC", c: "var(--s-diff)", better: "up" },
    { k: "M_L1 = KHÁC − GIỐNG", v: fmtD(margin),
      s: margin === null ? "cần cả hai loại cặp"
        : (!comparable ? "không so sánh được: khác chuỗi neo"
          : (margin > 0 ? "dương — đúng hướng" : "âm — đang học ngược")),
      c: margin === null || !comparable ? "var(--dim)" : (margin > 0 ? "var(--ok)" : "var(--bad)") },
    { k: "twin ↔ board", v: last ? (last.board ? (last.agree ? "khớp" : "LỆCH") : "chỉ twin") : "—",
      s: last && last.board ? `board d1 = ${last.board.d1}` : "chưa có board",
      c: last && last.board ? (last.agree ? "var(--ok)" : "var(--bad)") : "var(--dim)" },
  ];
  $("metrics").innerHTML = cards.map((c) => {
    let d = "";
    if (c.d !== null && c.d !== undefined && c.d !== 0) {
      const good = (c.better === "down") === (c.d < 0);
      d = `<div class="d ${good ? "down" : "up"}">${c.d < 0 ? "▼" : "▲"} ${fmtD(c.d)}</div>`;
    }
    return `<div class="card metric"><div class="v" style="color:${c.c}">${esc(c.v)}</div>${d}
      <div class="k">${c.k}</div><div class="s">${c.s}</div></div>`;
  }).join("");
}

function renderTrainCharts() {
  const rs = real();
  const same = [], diff = [], board = [];
  rs.forEach((r) => {
    (r.same ? same : diff).push([r.step, r.twin.d1]);
    if (r.board) board.push([r.step, r.board.d1]);
  });
  lineChart($("chD1"), [
    { name: "d1 cặp GIỐNG", shortName: "GIỐNG", color: col("--s-same"), points: same, marker: "circle" },
    { name: "d1 cặp KHÁC", shortName: "KHÁC", color: col("--s-diff"), points: diff, dash: "7 3", marker: "square" },
    { name: "board", shortName: "board", color: col("--s-board"), points: board, dash: "2 3", marker: "triangle" },
  ], {
    y0: true, xlabel: "bước", caption: "Khoảng cách d1 theo bước",
    marks: [{ y: 4096, label: "E3_MARG 4096" }],
    empty: "Chưa có bước nào. Nhập hai chuỗi rồi bấm THƯỞNG (Enter) hoặc PHẠT (Shift+Enter).",
    action: { label: "Về ô nhập A", onClick: () => { setTab("train"); $("inA").focus(); } },
  });

  let ls = null, ld = null;
  const ms = [];
  rs.forEach((r) => {
    if (r.same) ls = r.twin.d1; else ld = r.twin.d1;
    if (ls !== null && ld !== null) ms.push([r.step, ld - ls]);
  });
  lineChart($("chMargin"), [{ name: "M_L1", shortName: "M_L1", color: col("--accent"), points: ms, marker: "circle" }], {
    xlabel: "bước", caption: "Biên phân biệt M_L1",
    marks: [{ y: 0, label: "0 — dưới mức này là học ngược", color: col("--bad") }],
    empty: "Cần ít nhất một cặp GIỐNG và một cặp KHÁC.",
  });
}

/* --------------------------------------------------------- records table */

function recRow(r) {
  const d = prevSame(r);
  const delta = d ? r.twin.d1 - d.twin.d1 : null;
  const cls = [r.agree === false ? "diverged" : "", r.prime ? "prime" : "", "clickable"].filter(Boolean).join(" ");
  return `<tr class="${cls}" data-a="${esc(r.a)}" data-b="${esc(r.b)}" tabindex="0">
    <td class="num">${r.step}</td><td class="mono">${esc(r.a)}</td><td class="mono">${esc(r.b)}</td>
    <td><span class="tag ${r.same ? "ok" : "no"}">${r.same ? "GIỐNG" : "KHÁC"}</span></td>
    <td class="num">${r.twin.d1}</td>
    <td class="num ${delta === null ? "" : (delta < 0 ? "down" : "up")}">${delta === null ? "—" : fmtD(delta)}</td>
    <td class="num">${r.board ? r.board.d1 : "—"}</td>
    <td>${r.twin.updated ? `E${r.twin.e_writes}/Wh${r.twin.wh_writes}` : "không ghi"}</td>
    <td class="mono">${esc(r.prime ? "mồi" : r.source)}</td></tr>`;
}

function renderRecords(appendOnly) {
  const body = $("recBody");
  const wrap = $("recWrap");
  const atBottom = wrap.scrollHeight - wrap.scrollTop - wrap.clientHeight < 40;
  if (appendOnly && body.children.length) {
    body.insertAdjacentHTML("beforeend", recRow(S.records[S.records.length - 1]));
    while (body.children.length > 500) body.removeChild(body.firstChild);
  } else {
    body.innerHTML = S.records.slice(-500).map(recRow).join("")
      || `<tr><td colspan="9" class="muted">Chưa có bước nào. Bấm THƯỞNG hoặc PHẠT.</td></tr>`;
  }
  $("recCount").textContent = `${S.records.length} bước`
    + (S.records.length >= 500 ? " (bảng hiển thị 500 gần nhất)" : "");
  if (S.follow && atBottom && document.activeElement !== wrap) wrap.scrollTop = wrap.scrollHeight;
}

$("recBody").addEventListener("click", (e) => {
  const tr = e.target.closest("tr[data-a]");
  if (!tr) return;
  $("inA").value = tr.dataset.a;
  $("inB").value = tr.dataset.b;
  updateCounts();
  $("inA").focus();
});
$("recBody").addEventListener("keydown", (e) => {
  if (e.key === "Enter") e.target.closest("tr[data-a]")?.click();
});
$("btnFollow").onclick = () => {
  S.follow = !S.follow;
  $("btnFollow").setAttribute("aria-pressed", String(S.follow));
  $("btnFollow").textContent = S.follow ? "⏸ Tạm dừng cuộn" : "▶ Tiếp tục cuộn";
};
$("btnExport").onclick = () => {
  const blob = new Blob([JSON.stringify(S.records, null, 2)], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `a7-studio-session-${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(a.href);
};

function boardLog(txt, cls) {
  const d = document.createElement("div");
  d.innerHTML = `<span class="t">${new Date().toLocaleTimeString("vi-VN")}</span> <span class="${cls || ""}">${esc(txt)}</span>`;
  const box = $("boardLog");
  const at = box.scrollHeight - box.scrollTop - box.clientHeight < 40;
  box.appendChild(d);
  while (box.children.length > 300) box.removeChild(box.firstChild);
  if (at && document.activeElement !== box) box.scrollTop = box.scrollHeight;
}

/* -------------------------------------------------------------- gradient */

function renderGradient() {
  const ins = S.inspect;
  const goTrain = { label: "Về tab Huấn luyện", onClick: () => { setTab("train"); $("inA").focus(); } };
  if (!ins || !ins.available) {
    $("gradMetrics").innerHTML = `<div class="card metric"><div class="v">—</div>
      <div class="k">chưa có bước nào</div><div class="s">bấm THƯỞNG hoặc PHẠT</div></div>`;
    ["chH", "chG", "chGS", "hmWh", "hmE"].forEach((id) =>
      empty($(id), "Chưa có bước nào để mổ.", goTrain));
    return;
  }
  const nz = ins.g_a.filter((v) => v !== 0).length;
  const cards = [
    { k: "d1", v: ins.d1, c: "var(--accent)", s: ins.same ? "cặp GIỐNG" : "cặp KHÁC" },
    { k: "cổng DIFF", v: ins.same ? "n/a" : (ins.gate_open ? "MỞ" : "ĐÓNG"),
      c: ins.same ? "var(--dim)" : (ins.gate_open ? "var(--ok)" : "var(--warn)"), s: `ngưỡng ${ins.margin}` },
    { k: "toạ độ có gradient", v: `${nz}/32`, c: "var(--accent)", s: "phần còn lại không ghi" },
    { k: "đã cập nhật", v: ins.updated ? "CÓ" : "KHÔNG",
      c: ins.updated ? "var(--ok)" : "var(--faint)",
      s: ins.updated ? "chip đã ghi E và Wh" : "learn=0 hoặc freeze=1" },
  ];
  $("gradMetrics").innerHTML = cards.map((c) => `<div class="card metric">
    <div class="v" style="color:${c.c}">${esc(c.v)}</div><div class="k">${c.k}</div>
    <div class="s">${esc(c.s)}</div></div>`).join("");

  const inter = [];
  for (let i = 0; i < 32; i++) { inter.push(ins.a.h[i]); inter.push(ins.b.h[i]); }
  barChart($("chH"), inter, {
    height: 220, ymax: 33500, caption: "Trạng thái cuối h của A và B",
    colorAt: (i) => (i % 2 ? col("--warn") : col("--accent")),
    labelAt: (i) => `${i % 2 ? "B" : "A"}[${i >> 1}]`,
    marks: [{ y: 32767, label: "32767 bão hoà" }],
    xlabel: "32 chiều, mỗi chiều một cặp cột A|B",
  });
  barChart($("chG"), ins.g_a, {
    height: 190, symmetric: true, signGlyph: true, caption: "Gradient thô gA",
    colorAt: (i, v) => (v > 0 ? col("--s-same") : v < 0 ? col("--s-diff") : "#2a3766"),
    labelAt: (i) => `g[${i}]`, xlabel: "chiều 0 … 31", table: true,
  });
  barChart($("chGS"), ins.g_a.map((v) => Math.sign(v)), {
    height: 190, symmetric: true, ymax: 1, signGlyph: true, caption: "Dấu sign(gA) được áp dụng",
    colorAt: (i, v) => (v > 0 ? col("--s-same") : v < 0 ? col("--s-diff") : "#2a3766"),
    labelAt: (i) => `sign(g[${i}])`, xlabel: "chiều 0 … 31", table: true,
  });
  heatmap($("hmWh"), ins.wh_delta_sign, 32, 32, {
    cell: 12, amax: 1, rowName: (r) => `i${r}`, colName: (c) => `j${c}`,
    caption: "Thay đổi Wh", footer: "Wh[i][j] −= sign(g_i · h_{T−1}[j])",
  });
  const bytes = Object.keys(ins.e_rows);
  if (bytes.length) {
    const flat = [];
    bytes.forEach((b) => ins.e_rows[b].delta.forEach((v) => flat.push(v)));
    heatmap($("hmE"), flat, bytes.length, 32, {
      cell: 13, amax: 2, caption: "Thay đổi E theo byte",
      rowName: (r) => `${bytes[r]} '${ins.e_rows[bytes[r]].char}'`,
      colName: (c) => `dim${c}`, footer: "mỗi hàng một byte ký tự",
    });
  } else {
    empty($("hmE"), "Bước này không ghi vào E (learn=0, freeze=1, hoặc cổng DIFF đóng).");
  }
}

/* ------------------------------------------------------------------- math */

async function loadMath() {
  if (!S.math) {
    $("mathGrid").innerHTML = `<div class="card"><p class="muted">đang tải…</p></div>`;
    try { S.math = await api("/api/math"); }
    catch (e) {
      $("mathGrid").innerHTML = `<div class="card"><div class="note bad">Không tải được: ${esc(e.message)}</div>
        <button class="btn" type="button" onclick="location.reload()">Thử lại</button></div>`;
      return;
    }
  }
  const order = ["h_update", "h_update_intended", "sign", "sat8", "abs_shift", "diff_gate", "hinge"];
  $("mathGrid").innerHTML = order.map((k, i) => `
    <div class="card"><h3>${esc(S.math[k].title)}</h3><div class="chart" id="mc_${i}"></div>
    <p class="hint" style="margin-top:10px">${esc(S.math[k].note)}</p></div>`).join("");
  order.forEach((k, i) => {
    const c = S.math[k];
    lineChart($("mc_" + i), [{ name: c.title, shortName: "", color: col("--accent"), points: c.x.map((x, j) => [x, c.y[j]]), marker: "none" }],
      { height: 200, xlabel: "x", caption: c.title });
  });
}

/* --------------------------------------------------------------- evidence */

async function loadEvidence() {
  if (!S.evidence) {
    $("evBody").innerHTML = `<div class="card"><p class="muted">đang tải…</p></div>`;
    try { S.evidence = await api("/api/evidence"); }
    catch (e) {
      $("evBody").innerHTML = `<div class="card"><div class="note bad">Không tải được: ${esc(e.message)}</div></div>`;
      return;
    }
  }
  const e = S.evidence, g = e.twin_golden;
  const rows = Object.keys(g.expected).map((k) => `<tr>
    <td class="mono">${k}</td><td class="num">${g.expected[k]}</td><td class="num">${g.got[k]}</td>
    <td>${g.expected[k] === g.got[k] ? '<span class="tag ok">KHỚP</span>' : '<span class="tag no">LỆCH</span>'}</td></tr>`).join("");

  $("evBody").innerHTML = `
    <div class="note ${g.pass ? "" : "bad"}"><b>Thẩm quyền.</b> ${esc(e.twin_authority)}.
      Bản mô phỏng ${g.pass ? "<b>khớp 7/7</b>" : "<b>KHÔNG khớp</b>"} số vàng
      <code>tests/xsim/tb_a7eam03e.sv</code>, và tái tạo đúng số seed <code>0x22222222</code> trong
      <code>A7-EAM-03E-A02.md</code> (1487 / 229 / M_L1 = −1258).</div>
    <div class="grid g2">
      <div class="card"><h3>Số vàng A0.1-T · twin so với xsim</h3>
        <div class="table-wrap"><table><caption class="vh">So sánh số vàng</caption>
        <thead><tr><th scope="col">phép đo</th><th scope="col" class="num">xsim</th>
        <th scope="col" class="num">twin</th><th scope="col">kết quả</th></tr></thead>
        <tbody>${rows}</tbody></table></div></div>
      <div class="card"><h3>Trạng thái nhánh</h3>
        <dl class="kv">${Object.entries(e.status).map(([k, v]) =>
          `<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join("")}</dl>
        <div class="sep"></div><h3>Host được gửi</h3>
        <p class="muted">${e.host_may_send.map((x) => `<span class="tag ok">${esc(x)}</span>`).join(" ")}</p>
        <h3 style="margin-top:10px">Host bị cấm gửi</h3>
        <p class="muted">${e.host_may_not_send.map((x) => `<span class="tag no">${esc(x)}</span>`).join(" ")}</p></div>
    </div>
    <div class="card"><h3>Ba quirk số học trong RTL đã đóng băng</h3>
      <p class="hint">${esc(e.ablation || "")}. Quirk 3 <b>không</b> được số vàng ràng buộc — đó là dự
        đoán, và một lần đọc PAIR từ board là phủ định được.</p>
      <div class="table-wrap"><table><caption class="vh">Ba quirk</caption>
      <thead><tr><th scope="col" class="num">#</th><th scope="col">ở đâu</th><th scope="col">là gì</th>
      <th scope="col">hệ quả</th></tr></thead><tbody>
      ${e.quirks.map((q) => `<tr><td class="num">${q.id}</td><td class="mono nowrap">${esc(q.where)}</td>
        <td>${esc(q.what)}</td><td>${esc(q.impact)}</td></tr>`).join("")}
      </tbody></table></div></div>
    <div class="card"><h3>Cổng nghiệm thu A0.2-L cho mỗi seed</h3>
      <ol class="muted">${e.gates_a02l.map((x) => `<li>${esc(x)}</li>`).join("")}</ol>
      <div class="note warn">Vì quirk 2 làm <code>h ≥ 0</code> và gần bão hoà, cosine giữa hai vector
        luôn xấp xỉ 1 và <code>M_cos</code> chỉ dao động cỡ ±0.01. Cổng số 3
        (<code>M_cos &gt; 0</code>) do đó rất khó đạt vững chắc khi quirk 2 còn nguyên.</div></div>`;
}

/* -------------------------------------------------------------- benchmark */

function renderBench() {
  const b = S.bench;
  if (!b) {
    $("benchMetrics").innerHTML = `<div class="card metric"><div class="v">—</div>
      <div class="k">chưa chạy</div><div class="s">bấm "Chạy benchmark"</div></div>`;
    empty($("chBase"), "Chưa có kết quả.");
    $("benchGates").innerHTML = `<p class="muted">chưa có</p>`;
    $("benchSeeds").innerHTML = "";
    return;
  }
  const runs = b.runs || [];
  const med = (v) => { const s = [...v].sort((x, y) => x - y); return s[s.length >> 1]; };
  const dAuc = med(runs.map((r) => r.delta_auc));
  const auc = med(runs.map((r) => r.trained.auc));
  const un = med(runs.map((r) => r.untrained.auc));
  const rank = Math.min(...runs.map((r) => r.collapse.effective_rank));
  const cards = [
    { k: "ΔAUC (trung vị)", v: dAuc.toFixed(4), c: dAuc > 0 ? "var(--ok)" : "var(--bad)",
      s: dAuc > 0 ? "huấn luyện có giúp" : "huấn luyện làm xấu đi" },
    { k: "AUC chưa huấn luyện", v: un.toFixed(4), c: "var(--dim)", s: "mốc quyết định" },
    { k: "AUC sau huấn luyện", v: auc.toFixed(4), c: "var(--accent)", s: "trên tập chưa thấy" },
    { k: "hạng hiệu dụng", v: `${rank}/32`, c: rank >= 8 ? "var(--ok)" : "var(--bad)",
      s: rank < 8 ? "biểu diễn đã sụp" : "còn nhiều chiều" },
  ];
  $("benchMetrics").innerHTML = cards.map((c) => `<div class="card metric">
    <div class="v" style="color:${c.c}">${esc(c.v)}</div><div class="k">${c.k}</div>
    <div class="s">${esc(c.s)}</div></div>`).join("");

  const bl = runs[0].baselines || {};
  const names = Object.keys(bl);
  const vals = names.map((n) => med(runs.map((r) => r.baselines[n].auc)));
  const all = [...vals, un, auc];
  const labels = [...names.map((n) => n.replace(/^B\d_/, "")), "TWIN chưa HL", "TWIN sau HL"];
  barChart($("chBase"), all, {
    height: 300, caption: "AUC trung vị: các mốc so với mô hình", ymax: 1,
    colorAt: (i) => (i < vals.length ? "#3a4a7a"
      : (i === vals.length ? col("--warn") : (auc > Math.max(...vals) ? col("--ok") : col("--bad")))),
    labelAt: (i) => labels[i], tickLabels: true,
    marks: [{ y: 0.5, label: "0.5 = đoán bừa" }],
  });

  $("benchGates").innerHTML = `<div class="note ${b.report.screen_verdict === "PROMISING" ? "" : "bad"}">
      <b>Kết luận sàng lọc: ${esc(b.report.screen_verdict)}</b>. ${esc(b.report.authority)}</div>
    <div class="table-wrap"><table><caption class="vh">Cổng benchmark</caption>
    <thead><tr><th scope="col">cổng</th><th scope="col">kết quả</th><th scope="col">số đo</th></tr></thead>
    <tbody>${Object.entries(b.report.gates).map(([k, v]) => {
      const det = Object.entries(v).filter(([kk]) => kk !== "pass" && kk !== "note" && kk !== "why")
        .map(([kk, vv]) => `${kk}=${Array.isArray(vv) ? (vv.length ? vv.join(",") : "—") : vv}`).join("  ");
      return `<tr><td class="mono">${esc(k)}</td>
        <td><span class="tag ${v.pass ? "ok" : "no"}">${v.pass ? "PASS" : "FAIL"}</span></td>
        <td class="mono">${esc(det)}${v.note ? ` · ${esc(v.note)}` : ""}</td></tr>`;
    }).join("")}</tbody></table></div>`;

  $("benchSeeds").innerHTML = `<table><caption class="vh">Chi tiết từng seed</caption>
    <thead><tr><th scope="col">seed</th><th scope="col" class="num">AUC chưa HL</th>
    <th scope="col" class="num">AUC sau HL</th><th scope="col" class="num">ΔAUC</th>
    <th scope="col" class="num">Δ nhãn ngẫu nhiên</th><th scope="col" class="num">trip</th>
    <th scope="col" class="num">d1 mức</th><th scope="col" class="num">hoà</th>
    <th scope="col" class="num">bão hoà</th><th scope="col" class="num">hạng</th></tr></thead>
    <tbody>${runs.map((r) => `<tr><td class="mono">${esc(r.seed)}</td>
      <td class="num">${r.untrained.auc.toFixed(4)}</td><td class="num">${r.trained.auc.toFixed(4)}</td>
      <td class="num ${r.delta_auc > 0 ? "down" : "up"}">${r.delta_auc > 0 ? "+" : ""}${r.delta_auc.toFixed(4)}</td>
      <td class="num">${r.delta_auc_shuffled.toFixed(4)}</td>
      <td class="num">${r.triplet.trip_acc === undefined ? "—" : r.triplet.trip_acc.toFixed(3)}</td>
      <td class="num">${r.trained.levels}</td><td class="num">${r.trained.tie_mass.toFixed(2)}</td>
      <td class="num">${r.collapse.saturation_rate.toFixed(2)}</td>
      <td class="num">${r.collapse.effective_rank}</td></tr>`).join("")}</tbody></table>`;
}

/* ------------------------------------------------------------------ board */

async function scanPorts() {
  try {
    const j = await api("/api/ports");
    const sel = $("selPort"), cur = sel.value;
    sel.innerHTML = j.ports.length
      ? j.ports.map((p) => `<option value="${esc(p.device)}">${esc(p.device)} — ${esc(p.description)}</option>`).join("")
      : '<option value="">không thấy cổng COM nào</option>';
    if (cur) sel.value = cur;
  } catch (e) { boardLog("quét cổng lỗi: " + e.message, "err"); }
}

function ioCell(kind, i, on, sticky) {
  if (kind === "sw") return `<div class="sw ${on ? "on" : ""}"><div class="body"><div class="knob"></div></div>
    <div class="lbl">SW${i}</div><div class="st">${on ? "BẬT" : "TẮT"}</div></div>`;
  if (kind === "led") return `<div class="led ${on ? "on" : ""} ${S.boardIo?.mode !== "live" ? "inferred" : ""}">
    <div class="bulb"></div><div class="lbl">LD${i}</div><div class="st">${on ? "SÁNG" : "TẮT"}</div></div>`;
  return `<div class="btnp ${on ? "on" : ""}"><div class="cap"></div>
    <div class="lbl">BTN${i}${sticky ? "*" : ""}</div><div class="st">${on ? "NHẤN" : "NHẢ"}</div></div>`;
}

function renderIo() {
  const io = S.boardIo;
  if (!io) return;
  const live = io.mode === "live";
  $("ioMode").textContent = live ? "LIVE · CMD 0x2F" : (io.mode === "error" ? "LỖI ĐỌC" : "MÔ HÌNH");
  $("ioMode").className = "io-mode " + (live ? "live" : "model");
  $("boardWidget").classList.toggle("modelled", !live);
  const sw = io.sw || [0, 0, 0, 0], btn = io.btn || [0, 0, 0, 0], led = io.led || [0, 0, 0, 0];
  const st = io.btn_sticky || [0, 0, 0, 0];
  $("ioSw").innerHTML = [3, 2, 1, 0].map((i) => ioCell("sw", i, sw[i])).join("");
  $("ioBtn").innerHTML = [3, 2, 1, 0].map((i) => ioCell("btn", i, btn[i], st[i])).join("");
  $("ioLed").innerHTML = [3, 2, 1, 0].map((i) => ioCell("led", i, led[i])).join("");

  const ledM = io.led_meaning || [], swM = io.sw_meaning || [], btnM = io.btn_meaning || [];
  $("ioMeaning").innerHTML = `
    ${live ? '<div class="note"><b>Đang đọc thật từ bo mạch.</b> SW0 ép freeze, SW1 ép learn (công tắc chỉ có thể yêu cầu, không thể thu hồi). BTN1/2/3 là phím tắt của giao diện.</div>'
      : `<div class="note warn"><b>Đây là mô hình, không phải giá trị thật.</b> ${esc(io.why || "")}
         LED vẽ viền gạch nghĩa là suy ra từ cờ trả về, không đọc được.</div>`}
    <div class="table-wrap"><table><caption class="vh">Ý nghĩa từng chân</caption>
    <thead><tr><th scope="col">chân</th><th scope="col">ý nghĩa</th></tr></thead><tbody>
    ${[0, 1, 2, 3].map((i) => `<tr><td class="mono">SW${i}</td><td>${esc(swM[i] || "—")}</td></tr>`).join("")}
    ${[0, 1, 2, 3].map((i) => `<tr><td class="mono">BTN${i}</td><td>${esc(btnM[i] || "—")}</td></tr>`).join("")}
    ${[0, 1, 2, 3].map((i) => `<tr><td class="mono">LD${i}</td><td>${esc(ledM[i] || "—")}</td></tr>`).join("")}
    </tbody></table></div>`;
}

let ioTimer = null;
async function pollIo() {
  try {
    S.boardIo = await api("/api/board/io");
    renderIo();
    await handleSticky();
  } catch { /* transient */ }
  clearTimeout(ioTimer);
  const live = S.boardIo && S.boardIo.mode === "live";
  if (tab === "board" || live) ioTimer = setTimeout(pollIo, live ? 300 : 2000);
}

async function handleSticky() {
  const io = S.boardIo;
  if (!io || io.mode !== "live" || !io.btn_sticky) return;
  const s = io.btn_sticky;
  try {
    if (s[1] && !S.lastSticky[1]) { boardLog("BTN1 → bước THƯỞNG"); await step(true); }
    if (s[2] && !S.lastSticky[2]) { boardLog("BTN2 → bước PHẠT"); await step(false); }
    if (s[3] && !S.lastSticky[3]) { boardLog("BTN3 → nạp lại seed"); await doSeed(true); }
  } catch (e) { boardLog("phím bo mạch lỗi: " + e.message, "err"); }
  S.lastSticky = s.slice();
}

/* ------------------------------------------------------------- curriculum */

function renderCurriculum() {
  const items = (S.state && S.state.curriculum) || [];
  $("curList").innerHTML = items.length ? items.map((c, i) => `
    <div class="row tight" style="margin-bottom:6px">
      <button class="btn ghost" type="button" data-tog="${i}" style="padding:5px 8px"
        aria-label="Đổi nhãn cặp ${esc(c.a)} và ${esc(c.b)}">
        <span class="tag ${c.same ? "ok" : "no"}">${c.same ? "GIỐNG" : "KHÁC"}</span></button>
      <button class="btn ghost grow mono" type="button" data-load="${i}" style="text-align:left;font-size:12px"
        aria-label="Nạp cặp ${esc(c.a)} và ${esc(c.b)} vào ô nhập">${esc(c.a)} ⇄ ${esc(c.b)}</button>
      <button class="btn ghost" type="button" data-del="${i}" style="padding:6px 10px"
        aria-label="Xoá cặp ${esc(c.a)} và ${esc(c.b)}"><span aria-hidden="true">✕</span></button>
    </div>`).join("") : '<p class="muted">Giáo trình rỗng — thêm ít nhất một cặp GIỐNG và một cặp KHÁC để chạy tự động.</p>';
}

$("curList").addEventListener("click", async (e) => {
  const items = [...(S.state.curriculum || [])];
  const del = e.target.closest("[data-del]"), tog = e.target.closest("[data-tog]"), ld = e.target.closest("[data-load]");
  try {
    if (del) { items.splice(+del.dataset.del, 1); await api("/api/curriculum", { items }); await refresh(); }
    else if (tog) { const i = +tog.dataset.tog; items[i] = { ...items[i], same: !items[i].same }; await api("/api/curriculum", { items }); await refresh(); }
    else if (ld) { const c = items[+ld.dataset.load]; $("inA").value = c.a; $("inB").value = c.b; updateCounts(); $("inA").focus(); }
  } catch (err) { toast(err.message, "bad"); }
});

/* ---------------------------------------------------------------- actions */

function updateCounts() {
  [["inA", "cntA", "errA"], ["inB", "cntB", "errB"]].forEach(([i, c]) => {
    const n = blen($(i).value);
    const el2 = $(c);
    el2.textContent = `${n}/${MAXB} byte`;
    el2.classList.toggle("over", n > MAXB || n < 2);
  });
  const bad = [1, 2].some((_, k) => {
    const n = blen($(k ? "inB" : "inA").value);
    return n < 2 || n > MAXB;
  });
  $("btnReward").disabled = bad || S.busy || !!S.state?.training;
  $("btnPunish").disabled = bad || S.busy || !!S.state?.training;
}
$("inA").addEventListener("input", updateCounts);
$("inB").addEventListener("input", updateCounts);
["inA", "inB"].forEach((k) => $(k).addEventListener("focus", (e) => e.target.select()));

async function step(same) {
  if (S.busy) return;
  const a = $("inA").value, b = $("inB").value;
  for (const [id, v] of [["inA", a], ["inB", b]]) {
    const n = blen(v);
    if (n < 2 || n > MAXB) {
      fieldError(id, `Cần từ 2 đến ${MAXB} byte UTF-8; hiện ${n}.`);
      $(id).focus();
      return;
    }
    fieldError(id, "");
  }
  S.busy = true;
  updateCounts();
  try {
    await api("/api/step", { a, b, verdict: same ? "reward" : "punish" });
    $("inA").focus();
    $("inA").select();
  } catch (e) {
    fieldError("inA", e.message);
    toast("Không chạy được bước: " + e.message, "bad");
    announce("Lỗi: " + e.message, true);
  } finally {
    S.busy = false;
    updateCounts();
    renderChips();
  }
}

$("pairForm").addEventListener("submit", (e) => { e.preventDefault(); step(true); });
$("btnPunish").onclick = () => step(false);
$("btnSwap").onclick = () => { const a = $("inA").value; $("inA").value = $("inB").value; $("inB").value = a; updateCounts(); };
$("btnClear").onclick = () => { $("inA").value = ""; $("inB").value = ""; updateCounts(); $("inA").focus(); };
$("btnHelp").onclick = () => toast("Enter = THƯỞNG · Shift+Enter = PHẠT · Alt+S đổi A↔B · Esc xoá · Space bắt đầu/dừng huấn luyện · 1..7 chuyển tab");

async function setMode(mode) {
  const learn = mode === "learn", freeze = mode === "frozen";
  try { await api("/api/mode", { learn, freeze }); await refresh(); }
  catch (e) { toast(e.message, "bad"); }
}
$("segMode").addEventListener("click", (e) => {
  const b = e.target.closest("button[data-mode]");
  if (b) setMode(b.dataset.mode);
});

async function doSeed(force) {
  const raw = $("inSeed").value.trim();
  if (!/^(0[xX][0-9a-fA-F]{1,8}|\d+)$/.test(raw)) {
    fieldError("inSeed", "Cần một số nguyên 32-bit, ví dụ 0x11111111.");
    return;
  }
  fieldError("inSeed", "");
  const steps = S.state?.step_no || 0;
  if (!force && steps > 0) {
    $("seedConfirm").innerHTML = `<div class="banner warn">
      <span class="grow">Nạp seed sẽ sinh lại toàn bộ trọng số và xoá <b>${steps}</b> bước đã học.</span>
      <button class="btn danger" type="button" data-c="yes">Xác nhận</button>
      <button class="btn ghost" type="button" data-c="no">Huỷ</button></div>`;
    return;
  }
  $("seedConfirm").innerHTML = "";
  try { await api("/api/seed", { seed: raw }); S.records = []; renderRecords(); toast("Đã nạp seed " + raw, "ok"); await refresh(); redraw(); }
  catch (e) { fieldError("inSeed", e.message); }
}
$("seedConfirm").addEventListener("click", (e) => {
  const b = e.target.closest("[data-c]");
  if (!b) return;
  if (b.dataset.c === "yes") doSeed(true); else $("seedConfirm").innerHTML = "";
});
$("btnSeed").onclick = () => doSeed(false);
$("btnSeedGolden").onclick = () => { $("inSeed").value = "0x11111111"; doSeed(false); };
$("btnSeedBad").onclick = () => { $("inSeed").value = "0x22222222"; doSeed(false); };

async function addCur(same) {
  const a = $("inA").value, b = $("inB").value;
  if (blen(a) < 2 || blen(b) < 2) { toast("Mỗi chuỗi cần ít nhất 2 byte", "bad"); return; }
  const items = [...(S.state.curriculum || []), { a, b, same, note: "người dùng thêm" }];
  try { await api("/api/curriculum", { items }); await refresh(); }
  catch (e) { toast(e.message, "bad"); }
}
$("btnCurSame").onclick = () => addCur(true);
$("btnCurDiff").onclick = () => addCur(false);
$("btnCurReset").onclick = async () => {
  await api("/api/curriculum", { items: [
    { a: "ALPHA", b: "BETA.", same: true, note: "golden SAME" },
    { a: "ALPHA", b: "OMEGA", same: false, note: "golden DIFF" }] });
  await refresh();
};

$("btnTrain").onclick = async () => {
  try { await api("/api/train/start", { steps: +$("inSteps").value, delay_ms: +$("inDelay").value }); }
  catch (e) { toast(e.message, "bad"); }
};
$("btnStop").onclick = () => api("/api/train/stop", {});

$("btnScan").onclick = scanPorts;
$("btnConnect").onclick = async () => {
  try {
    const info = await api("/api/board/connect", { port: $("selPort").value, baud: +$("inBaud").value });
    boardLog(`kết nối ${info.port} · ident "${info.ident}" · CMD 0x2F ${info.has_io ? "có" : "không có"}`);
    if (!info.ident_ok) boardLog(`cảnh báo: ident "${info.ident}" không phải "3A0"`, "err");
    toast("Đã kết nối " + info.port, "ok");
    await refresh();
    pollIo();
  } catch (e) { boardLog("kết nối lỗi: " + e.message, "err"); toast(e.message, "bad"); }
};
$("btnDisconnect").onclick = async () => { await api("/api/board/disconnect", {}); boardLog("đã ngắt"); await refresh(); };
$("btnResync").onclick = async () => {
  try {
    const r = await api("/api/board/resync", {});
    boardLog(`resync: in_sync=${r.in_sync} (twin d1=${r.prime.twin.d1}${r.prime.board ? `, board d1=${r.prime.board.d1}` : ""})`);
    await refresh();
  } catch (e) { boardLog("resync lỗi: " + e.message, "err"); toast(e.message, "bad"); }
};
$("btnPing").onclick = async () => {
  try {
    const j = await api("/api/board/ping", {});
    boardLog(`PING 0x01 → ident "${j.ident}" · ${j.rtt_ms} ms · ${j.xfers} giao dịch, ${j.errors} lỗi`);
    toast(`PING ok · ${j.rtt_ms} ms`, "ok");
  } catch (e) { boardLog("PING lỗi: " + e.message, "err"); toast("PING lỗi: " + e.message, "bad"); }
};

$("btnWSet").onclick = async () => {
  try {
    const j = await api("/api/twin/weight", { kind: $("wKind").value, index: +$("wIdx").value, value: +$("wVal").value });
    toast(`twin ${j.kind}[${j.index}] = ${j.value} (không gửi xuống chip)`, "ok");
    await refresh();
  } catch (e) { toast(e.message, "bad"); }
};

$("btnBench").onclick = async () => {
  $("btnBench").disabled = true;
  $("btnBenchStop").disabled = false;
  $("benchProgress").innerHTML = `<p class="muted" style="margin-top:8px">đang chạy… <progress></progress></p>`;
  try {
    await api("/api/bench/start", {
      entities: +$("bEnt").value, seeds: +$("bSeeds").value,
      epochs: +$("bEpochs").value, vn: $("bVn").checked,
    });
  } catch (e) { toast(e.message, "bad"); $("btnBench").disabled = false; $("btnBenchStop").disabled = true; }
};
$("btnBenchStop").onclick = () => api("/api/bench/stop", {});
$("btnEpochSweep").onclick = async () => {
  $("btnEpochSweep").disabled = true;
  try {
    const j = await api("/api/bench/epochs", {});
    lineChart($("chEpoch"), [
      { name: "M_L1", shortName: "M_L1", color: col("--accent"), points: j.rows.map((r) => [r.epochs, r.M_L1]), marker: "circle" },
    ], { xlabel: "số epoch", caption: "M_L1 theo số epoch",
      marks: [{ y: 0, label: "0 — dưới đây là học ngược", color: col("--bad") }] });
    const neg = j.rows.filter((r) => r.M_L1 <= 0).map((r) => r.epochs);
    const coll = j.rows.filter((r) => r.positive_pair_collapsed).map((r) => r.epochs);
    toast(`M_L1 âm ở epoch: ${neg.length ? neg.join(", ") : "không có"}. `
      + `Cặp GIỐNG sụp về d1=0 từ epoch ${coll.length ? coll[0] : "—"}.`);
  } catch (e) { toast(e.message, "bad"); }
  finally { $("btnEpochSweep").disabled = false; }
};

/* -------------------------------------------------------------- keyboard */

document.addEventListener("keydown", (e) => {
  const inField = /^(INPUT|SELECT|TEXTAREA)$/.test(e.target.tagName);
  if (e.altKey && (e.key === "s" || e.key === "S")) { e.preventDefault(); $("btnSwap").click(); return; }
  if (e.key === "Escape") { $("btnClear").click(); return; }
  if (e.key === "?" && !inField) { e.preventDefault(); $("btnHelp").click(); return; }
  if (e.key === "Enter" && e.shiftKey && (e.target === $("inA") || e.target === $("inB"))) {
    e.preventDefault(); step(false); return;
  }
  if (inField) return;
  if (e.key === " ") {
    e.preventDefault();
    (S.state?.training ? $("btnStop") : $("btnTrain")).click();
    return;
  }
  const tabs = [...$("tabs").children];
  if (/^[1-7]$/.test(e.key) && tabs[+e.key - 1]) { e.preventDefault(); setTab(tabs[+e.key - 1].dataset.tab); }
});

/* ------------------------------------------------------------------- sync */

async function refresh() {
  S.state = await api("/api/state");
  renderChips();
  renderCurriculum();
  updateCounts();
}

async function loadInspect() {
  try { S.inspect = await api("/api/inspect"); } catch { S.inspect = null; }
  if (tab === "gradient") renderGradient();
  if (tab === "learn" && S.inspect?.available) {
    stateTimeline($("tlA"), S.inspect.a.states, S.inspect.a.tokens, { caption: "h theo byte, chuỗi A" });
    stateTimeline($("tlB"), S.inspect.b.states, S.inspect.b.tokens, { caption: "h theo byte, chuỗi B" });
  }
}
let insPending = false;
function scheduleInspect() {
  if (insPending) return;
  insPending = true;
  setTimeout(() => { insPending = false; loadInspect(); }, 200);
}

function redraw() {
  renderPipe();
  renderMetrics();
  renderTrainCharts();
  renderRecords();
  if (tab === "gradient") renderGradient();
  if (tab === "board") renderIo();
  if (tab === "bench") renderBench();
}

/* -------------------------------------------------------------------- SSE */

function connectEvents() {
  const es = new EventSource("/api/events");
  es.onopen = () => { S.sse = "live"; renderChips(); };
  es.onmessage = (ev) => {
    let m;
    try { m = JSON.parse(ev.data); } catch { return; }
    if (m.kind === "step") {
      S.records.push(m.record);
      if (S.records.length > 4000) S.records.shift();
      renderRecords(true);
      renderMetrics();
      renderTrainCharts();
      renderPipe();
      scheduleInspect();
      refresh();
      const ls = lastWith((r) => r.same), ld = lastWith((r) => !r.same);
      const mg = ls && ld ? ld.twin.d1 - ls.twin.d1 : null;
      announce(`Bước ${m.record.step}. d1 giống ${ls ? ls.twin.d1 : "chưa có"}, `
        + `d1 khác ${ld ? ld.twin.d1 : "chưa có"}. `
        + (mg === null ? "Chưa đủ cặp để tính biên."
          : `Biên M_L1 ${mg > 0 ? "dương" : "âm"} ${Math.abs(mg)}${mg > 0 ? ", đúng hướng." : ", đang học ngược."}`));
    } else if (m.kind === "divergence") {
      const msg = `Bước ${m.step}: twin d1=${m.twin_d1} vs board d1=${m.board_d1} · dH ${m.twin_dH} vs ${m.board_dH}`;
      boardLog("LỆCH " + msg, "err");
      banner("diverge", `<span class="grow">TWIN và BOARD <b>lệch nhau</b>. ${esc(msg)}</span>
        <button class="btn danger" type="button" data-act="stop-train">Dừng huấn luyện</button>
        <button class="btn ghost" type="button" data-act="dismiss" data-key="diverge">Bỏ qua</button>`);
      announce("Cảnh báo: twin và board lệch nhau ở bước " + m.step, true);
    } else if (m.kind === "bench") {
      $("benchProgress").innerHTML = `<p class="muted" style="margin-top:8px">seed ${m.done}/${m.of}
        <progress value="${m.done}" max="${m.of}"></progress></p>`;
    } else if (m.kind === "bench_done") {
      S.bench = m.result;
      $("btnBench").disabled = false;
      $("btnBenchStop").disabled = true;
      $("benchProgress").innerHTML = "";
      renderBench();
      toast("Benchmark xong: " + m.result.report.screen_verdict, m.result.report.screen_verdict === "PROMISING" ? "ok" : "bad");
    } else if (m.kind === "error") {
      toast("Lỗi server: " + (m.detail || ""), "bad");
      announce("Lỗi server", true);
    } else {
      refresh();
    }
  };
  es.onerror = () => {
    S.sse = "mất kết nối";
    renderChips();
    es.close();
    setTimeout(async () => {
      try { const h = await api("/api/history"); S.records = h.records || []; renderRecords(); } catch { /* retry */ }
      connectEvents();
    }, 3000);
  };
}

/* -------------------------------------------------------------------- boot */

(async function boot() {
  try {
    const saved = location.hash.slice(1) || localStorage.getItem("a7tab") || "train";
    await refresh();
    const h = await api("/api/history");
    S.records = h.records || [];
    await loadInspect();
    connectEvents();
    scanPorts();
    pollIo();
    setTab($("tab-" + saved) ? saved : "train");
  } catch (e) {
    document.body.insertAdjacentHTML("afterbegin",
      `<div class="banner" role="alert" style="margin:20px">Không nối được server: ${esc(e.message)}
       — kiểm tra <code>python tools/ui/a7_studio.py</code> còn chạy không.</div>`);
  }
})();
