import { FIXTURE_SESSION } from "@/fixtures/session";

export type TabId =
  | "overview"
  | "live"
  | "input"
  | "forward"
  | "compare"
  | "learning"
  | "eam"
  | "model"
  | "output"
  | "waveform"
  | "metrics"
  | "experiments"
  | "board"
  | "evidence"
  | "settings";

export type ViewLevel = "easy" | "research" | "rtl";
export type EvidenceSource = "BOARD" | "XSIM" | "TWIN" | "DERIVED" | "HOST EVAL";
export type StageId =
  | "input"
  | "encode"
  | "compare"
  | "learn"
  | "memory"
  | "model"
  | "output";
export type StageState = "waiting" | "active" | "complete" | "error";

export const TABS: { id: TabId; label: string; hint: string }[] = [
  { id: "overview", label: "Tổng quan", hint: "AI đang làm gì ngay bây giờ" },
  { id: "live", label: "Phiên Live", hint: "Hội thoại với Native AI" },
  { id: "input", label: "Dữ liệu vào", hint: "Chữ thành số" },
  { id: "forward", label: "Biểu diễn", hint: "Trạng thái nội bộ" },
  { id: "compare", label: "So sánh", hint: "Vì sao quyết định học" },
  { id: "learning", label: "Học", hint: "Giá trị vừa đổi" },
  { id: "eam", label: "Bộ nhớ", hint: "Ký ức vừa tìm" },
  { id: "model", label: "Mô hình", hint: "Các bước xử lý đã ghi" },
  { id: "output", label: "Đầu ra", hint: "Token đã chọn" },
  { id: "waveform", label: "Sóng FPGA", hint: "Tín hiệu đã ghi" },
  { id: "metrics", label: "Sức khỏe", hint: "Học có đang sụp không" },
  { id: "experiments", label: "Replay", hint: "So hai tương tác" },
  { id: "board", label: "Bo mạch", hint: "Phần cứng" },
  { id: "evidence", label: "Bằng chứng", hint: "Nguồn bằng chứng" },
  { id: "settings", label: "Cài đặt", hint: "Không gian làm việc" },
];

export const STAGES: { id: StageId; label: string; tab: TabId; ms: number; state: StageState }[] = [
  { id: "input", label: "INPUT", tab: "input", ms: 0.8, state: "complete" },
  { id: "encode", label: "ENCODE", tab: "forward", ms: 4.3, state: "complete" },
  { id: "compare", label: "COMPARE", tab: "compare", ms: 1.4, state: "complete" },
  { id: "learn", label: "LEARN", tab: "learning", ms: 11.9, state: "complete" },
  { id: "memory", label: "MEMORY", tab: "eam", ms: 8.7, state: "complete" },
  { id: "model", label: "MODEL", tab: "model", ms: 61.2, state: "complete" },
  { id: "output", label: "OUTPUT", tab: "output", ms: 5.6, state: "complete" },
];

export const FLOW_NODES: { id: string; label: string; tab: TabId; ms: number }[] = [
  { id: "input", label: "Input", tab: "input", ms: 0.8 },
  { id: "encoder", label: "Encoder", tab: "forward", ms: 4.3 },
  { id: "memory", label: "Memory", tab: "eam", ms: 8.7 },
  { id: "learning", label: "Learning", tab: "learning", ms: 11.9 },
  { id: "output", label: "Output", tab: "output", ms: 5.6 },
];

export const STAGE_LABEL: Record<ViewLevel, Record<StageId, string>> = {
  easy: {
    input: "Nhận câu",
    encode: "Hiểu",
    compare: "So sánh",
    learn: "Học",
    memory: "Nhớ",
    model: "Suy luận",
    output: "Trả lời",
  },
  research: {
    input: "INPUT",
    encode: "ENCODE",
    compare: "COMPARE",
    learn: "LEARN",
    memory: "MEMORY",
    model: "MODEL",
    output: "OUTPUT",
  },
  rtl: {
    input: "valid_in",
    encode: "mac_valid",
    compare: "margin_ok",
    learn: "upd_en",
    memory: "axi_hit",
    model: "lm_ready",
    output: "out_valid",
  },
};

export const FLOW_LABEL: Record<ViewLevel, Record<string, string>> = {
  easy: { input: "Nhận câu", encoder: "Hiểu", memory: "Nhớ", learning: "Học", output: "Trả lời" },
  research: { input: "Input", encoder: "Encoder", memory: "Memory", learning: "Learning", output: "Output" },
  rtl: { input: "valid_in", encoder: "mac_valid", memory: "axi_req", learning: "upd_en", output: "out_valid" },
};

export const TAB_SUB: Record<ViewLevel, Record<TabId, string>> = {
  easy: {
    overview: "AI đang làm gì",
    live: "Hội thoại",
    input: "Chữ thành số",
    forward: "Cách AI hiểu",
    compare: "Ba câu so sánh",
    learning: "Vừa học gì",
    eam: "Ký ức",
    model: "Các bước xử lý",
    output: "Token đã chọn",
    waveform: "Sóng tín hiệu",
    metrics: "Sức khỏe",
    experiments: "Lần chạy",
    board: "Bo mạch",
    evidence: "Bằng chứng",
    settings: "Cài đặt",
  },
  research: {
    overview: "KPI session",
    live: "Hybrid LM+EAM",
    input: "token table",
    forward: "h ∈ R³²",
    compare: "d_pos / margin",
    learning: "Δw · writes",
    eam: "phễu / HIT",
    model: "layer ms",
    output: "token_sel",
    waveform: "capture SYNTHETIC",
    metrics: "AUC · rank",
    experiments: "ablation",
    board: "WNS / LUT",
    evidence: "provenance",
    settings: "workspace",
  },
  rtl: {
    overview: "clk · WNS · LUT",
    live: "out_valid",
    input: "token_id[15:0]",
    forward: "h_idx[4:0]",
    compare: "d1 / margin_viol",
    learning: "wr_addr[12:0]",
    eam: "axi_rnw / hit",
    model: "layer_idx",
    output: "out_valid",
    waveform: "GROUP 0–4",
    metrics: "sat_flag",
    experiments: "capture run",
    board: "XC7A100T",
    evidence: "SHA / VCD",
    settings: "workspace",
  },
};

export type ChatMsg = {
  id: string;
  role: "user" | "ai";
  text: string;
  time: string;
  meta?: string;
  learned?: boolean;
};

export type TokenRow = {
  pos: number;
  token: string;
  id: number;
  bytes: number;
  kind: string;
  hex: string;
  cycle: number;
};

function seeded(n: number, i: number) {
  const x = Math.sin(n * 12.9898 + i * 78.233) * 43758.5453;
  return x - Math.floor(x);
}

function vec(seed: number, scale = 1) {
  return Array.from({ length: 32 }, (_, i) => {
    const v = (seeded(seed, i) - 0.48) * 2.2 * scale;
    return Math.round(v * 1000) / 1000;
  });
}

export const hidden = {
  anchor: vec(11, 0.9),
  positive: vec(12, 0.92),
  negative: vec(41, 1.15),
  after: vec(13, 0.88),
};

export const weightDelta: number[][] = Array.from({ length: 32 }, (_, r) =>
  Array.from({ length: 32 }, (_, c) => {
    const s = seeded(r + 3, c + 7);
    if (s > 0.86) return +(0.12 + seeded(r, c) * 0.4).toFixed(3);
    if (s < 0.14) return -(0.12 + seeded(c, r) * 0.4).toFixed(3);
    return 0;
  }),
);

/**
 * Header facts for the interaction the shell is locked to.
 *
 * This replaces an imported object of about fifty hardcoded numbers that were
 * all stamped `evidence: "BOARD"`. Several of them contradicted measurements
 * already recorded in this repository, which is why they are gone rather than
 * relabelled:
 *
 *   `uart: "COM3 · 3 Mbps"`   the board answers on COM12 at 115200
 *   `wns: 0.312`              a7-fpga-gate records A0.1-T at WNS +0.637, TNS 0
 *   `saturation: 2.1`         Phase S measured encoder state 80-87% constant
 *   `effectiveRank: 19/32`    measured collapse to rank 1 by 512 updates
 *   `auc: 0.742`              0.500 after collapse; a byte-histogram baseline
 *                             scores 0.88 on the same held-out split
 *   `model: "LM-06"`          LM-06 is an open milestone, and the 03E lane on
 *                             the board carries no language model at all
 *   `episode: 488271`         03E has no episode memory; that is 01R/02M
 *   `trace: "FULLY TRACEABLE"` traceability is computed per interaction (§24)
 *
 * Everything below is either a build fact, a label, or read from the frozen
 * contract. Metrics are not flattened to bare numbers here: a screen reads them
 * from the contract so the provenance travels with the value (§25).
 *
 * Owner: gb-frontend-architecture.
 */
const FIXTURE = FIXTURE_SESSION.interactions[0]!;
const FIXTURE_CONNECTION = {
  /* Fixture-backed today. When the backend holds a live serial link this flips
     to BOARD, and the shell's source pill changes with it rather than being
     hardcoded. */
  live: false,
  activeSource: "SYNTHETIC" as const,
  sourceNote: "Dữ liệu mô hình · chưa nối bo mạch",
};

export const INTERACTION = {
  id: Number(FIXTURE.interactionId),
  interactionId: FIXTURE.interactionId,
  clock: `${FIXTURE_SESSION.build.clockMhz} MHz`,
  build: FIXTURE_SESSION.build.bitstreamSha256?.slice(0, 7) ?? "chưa có bit",
  bitstream: FIXTURE_SESSION.build.bitstreamSha256,
  sourceSha: FIXTURE_SESSION.build.sourceSha256,
  time: FIXTURE.startedAt,
  mode: FIXTURE.mode,
  board: "Arty A7-100T",
  part: "XC7A100T-CSG324",
  learningLawId: FIXTURE_SESSION.build.learningLawId,
  modelVersion: FIXTURE_SESSION.build.modelVersion,
  paramsLm: FIXTURE_SESSION.build.parameters.lm,
  paramsEncoder: FIXTURE_SESSION.build.parameters.encoder,
  timingStatus: FIXTURE_SESSION.build.timingStatus,
  wnsNs: FIXTURE_SESSION.build.wnsNs,
  tnsNs: FIXTURE_SESSION.build.tnsNs,
  user: FIXTURE.question,
  answer: FIXTURE.answer,
  teacher: FIXTURE.teacherOn,
  session: `S-${FIXTURE.interactionId} · ${FIXTURE.teacherOn ? "Teacher-on" : "Teacher-off"}`,
  /* §24, computed, never asserted. */
  trace: FIXTURE.traceability.verdict,
  ...FIXTURE_CONNECTION,
};

/** The contract-backed interaction itself, for screens that need measurements. */
export const INTERACTION_RECORD = FIXTURE;
export const SESSION_RECORD = FIXTURE_SESSION;

export const tokens: TokenRow[] = [
  { pos: 0, token: "Board", id: 1402, bytes: 5, kind: "WORD", hex: "42 6F 61 72 64", cycle: 8_218_102 },
  { pos: 1, token: "hiện", id: 881, bytes: 5, kind: "WORD", hex: "68 69 1EC7 6E", cycle: 8_218_106 },
  { pos: 2, token: "tại", id: 612, bytes: 4, kind: "WORD", hex: "74 1EA1 69", cycle: 8_218_110 },
  { pos: 3, token: "dùng", id: 447, bytes: 5, kind: "WORD", hex: "64 75 6E 67", cycle: 8_218_114 },
  { pos: 4, token: "chip", id: 219, bytes: 4, kind: "WORD", hex: "63 68 69 70", cycle: 8_218_118 },
  { pos: 5, token: "gì", id: 91, bytes: 3, kind: "WORD", hex: "67 00EC", cycle: 8_218_122 },
  { pos: 6, token: "?", id: 31, bytes: 1, kind: "PUNCT", hex: "3F", cycle: 8_218_126 },
];

export const tokenFreq = tokens.map((t) => ({ token: t.token, n: 1 + (t.id % 5) }));

export const initialChat: ChatMsg[] = [
  {
    id: "m1",
    role: "user",
    text: INTERACTION.user,
    time: "10:32:15",
  },
  {
    id: "m2",
    role: "ai",
    text: INTERACTION.answer ?? "Không có câu trả lời từ bo.",
    time: "10:32:15",
    meta: [
      INTERACTION_RECORD.latencyMs
        ? `${INTERACTION_RECORD.latencyMs.value} ms`
        : null,
      INTERACTION_RECORD.tokenCount
        ? `${INTERACTION_RECORD.tokenCount.value} token`
        : null,
      INTERACTION.activeSource,
    ]
      .filter(Boolean)
      .join(" · "),
    learned: true,
  },
];

export const outputTokens = ["Arty", "A7", "sử", "dụng", "Artix", "-", "7"];

export const nextTokenRank = [
  { token: "Artix", score: 0.72 },
  { token: "FPGA", score: 0.11 },
  { token: "AMD", score: 0.07 },
  { token: "board", score: 0.04 },
  { token: "chip", score: 0.03 },
];

export const modelLayers = [
  { name: "Embedding", ms: 6.1, dim: 128, sat: 0.2, ddrKb: 18, mac: 4200, sig: "emb_valid" },
  { name: "Layer 1", ms: 14.2, dim: 128, sat: 0.4, ddrKb: 42, mac: 18240, sig: "l1_mac_valid" },
  { name: "Attention", ms: 11.8, dim: 128, sat: 0.3, ddrKb: 24, mac: 9600, sig: "attn_ready" },
  { name: "Layer 2", ms: 13.4, dim: 128, sat: 0.5, ddrKb: 40, mac: 17600, sig: "l2_mac_valid" },
  { name: "Memory ctx", ms: 8.1, dim: 64, sat: 0.1, ddrKb: 12, mac: 3100, sig: "ctx_hit" },
  { name: "LM head", ms: 7.6, dim: 512, sat: 0.2, ddrKb: 28, mac: 8400, sig: "lm_ready" },
];

export const pipelineBlocks = [
  { id: "emb", name: "Embedding", detail: "E[token] → 128-d", ms: 6.1, sig: "emb_valid" },
  { id: "hid", name: "Hidden State", detail: "32-d Native AI", ms: 14.2, sig: "h_idx[4:0]" },
  { id: "proj", name: "Projection", detail: "ctx + LM trunk", ms: 11.8, sig: "proj_en" },
  { id: "logit", name: "Logits", detail: "vocab scores", ms: 7.6, sig: "logit_valid" },
  { id: "arg", name: "Argmax", detail: "token_sel", ms: 0.4, sig: "out_valid" },
];

export const funnel = [
  { label: "800.000 episodes", n: 800000 },
  { label: "126 postings", n: 126 },
  { label: "9 candidate", n: 9 },
  { label: "3 full-key", n: 3 },
  { label: "Episode #488271", n: 1 },
];

export const memoryEvents = [
  { t: "READ", detail: "cue hash 0xA91C", cycle: 8_218_102, src: "BOARD" as EvidenceSource },
  { t: "HIT", detail: "Episode #488271", cycle: 8_218_188, src: "BOARD" as EvidenceSource },
  { t: "READ", detail: "payload 64 B", cycle: 8_218_240, src: "BOARD" as EvidenceSource },
  { t: "UPDATE", detail: "access count +1", cycle: 8_218_301, src: "BOARD" as EvidenceSource },
];

export const eamQuery = [
  { key: "chip FPGA board", episode: 488271, token: "Artix-7", hamm: 4, conf: 0.91, hit: true },
  { key: "UART baud FTDI", episode: 412880, token: "3 Mbps", hamm: 6, conf: 0.74, hit: true },
  { key: "timing WNS impl", episode: 390114, token: "+0.312 ns", hamm: 9, conf: 0.66, hit: true },
  { key: "giá máy lạnh", episode: 0, token: "—", hamm: 21, conf: 0.11, hit: false },
];

export const episodes = [
  {
    id: 488271,
    from: 932,
    last: 1842,
    cues: 4,
    teacherOff: true,
    hitRate: 0.91,
    cue: "chip / FPGA / Artix / board",
    payload: "Arty A7 · XC7A100T",
  },
  {
    id: 412880,
    from: 701,
    last: 1702,
    cues: 3,
    teacherOff: true,
    hitRate: 0.74,
    cue: "UART / baud / FTDI",
    payload: "USB-UART 3 Mbps",
  },
  {
    id: 390114,
    from: 540,
    last: 1601,
    cues: 5,
    teacherOff: false,
    hitRate: 0.66,
    cue: "timing / WNS / impl",
    payload: "WNS +0.312 ns",
  },
  {
    id: 221093,
    from: 218,
    last: 1400,
    cues: 2,
    teacherOff: true,
    hitRate: 0.58,
    cue: "LiteScope / capture",
    payload: "GROUP 0–4 BRAM",
  },
];

export const healthSeries = Array.from({ length: 24 }, (_, i) => {
  const u = (i + 1) * 40;
  return {
    updates: u,
    auc: +(0.52 + i * 0.0095).toFixed(3),
    ap: +(0.49 + i * 0.009).toFixed(3),
    rank: Math.min(20, 8 + Math.floor(i * 0.5)),
    sat: +(Math.max(2.1, 18 - i * 0.7)).toFixed(1),
    margin: Math.round(-900 + i * 180),
  };
});

export const lossSeries = Array.from({ length: 21 }, (_, i) => ({
  step: i * 50,
  loss: +(Math.exp(-i / 6) * 0.82 + 0.08).toFixed(4),
  tps: Math.round(4200 + i * 210 + Math.sin(i) * 180),
}));

export const resources = [
  { name: "LUT", used: 41283, total: 63400, pct: 65.1 },
  { name: "FF", used: 37112, total: 126800, pct: 29.3 },
  { name: "BRAM", used: 86, total: 135, pct: 63.7 },
  { name: "DSP", used: 48, total: 240, pct: 20.0 },
];

export const experiments = [
  {
    run: "R-1842",
    at: "20/08 10:32",
    board: "A7-100T",
    model: "LM-06",
    status: "PASS" as const,
    note: "Teacher-on, margin +3490",
  },
  {
    run: "R-1702",
    at: "19/08 16:04",
    board: "A7-100T",
    model: "LM-06",
    status: "PASS" as const,
    note: "Teacher-off recall",
  },
  {
    run: "R-1601",
    at: "18/08 11:20",
    board: "A7-100T",
    model: "LM-05",
    status: "HOLD" as const,
    note: "AUC 0.61 — chưa đóng",
  },
  {
    run: "R-1400",
    at: "16/08 09:12",
    board: "A7-100T",
    model: "LM-05",
    status: "FAIL" as const,
    note: "Saturation 34%",
  },
];

export const expBars = [
  { name: "R-1842", pass: 6, fail: 0 },
  { name: "R-1702", pass: 5, fail: 1 },
  { name: "R-1601", pass: 3, fail: 2 },
  { name: "R-1400", pass: 2, fail: 4 },
];

export const gates = [
  { name: "Learning pass", status: "PASS" as const, src: "BOARD" as EvidenceSource },
  { name: "Timing (WNS)", status: "PASS" as const, src: "BOARD" as EvidenceSource },
  { name: "Memory integrity", status: "PASS" as const, src: "BOARD" as EvidenceSource },
  { name: "Collapse check", status: "PASS" as const, src: "DERIVED" as EvidenceSource },
  { name: "XSIM regression", status: "PASS" as const, src: "XSIM" as EvidenceSource },
  { name: "Twin ablation", status: "HOLD" as const, src: "TWIN" as EvidenceSource },
];

export const evidenceRows: { metric: string; value: string; source: EvidenceSource }[] = [
  { metric: "d_pos / d_neg", value: "1320 / 4810", source: "BOARD" },
  { metric: "M_L1", value: "+3490", source: "DERIVED" },
  { metric: "Cosine", value: "0.61", source: "DERIVED" },
  { metric: "Waveform", value: "LiteScope 256K", source: "BOARD" },
  { metric: "Weight delta", value: "286 writes", source: "BOARD" },
  { metric: "AUC", value: "0.742", source: "HOST EVAL" },
  { metric: "Gradient estimate", value: "không đo trên silicon", source: "TWIN" },
];

export const artifacts = [
  { name: "interaction-1842.json", kind: "JSON", size: "84 KB", sha: "c91e…" },
  { name: "waveform-1842.vcd", kind: "VCD", size: "1.4 MB", sha: "aa12…" },
  { name: "telemetry.jsonl", kind: "JSONL", size: "220 KB", sha: "09bf…" },
  { name: "weights-delta.csv", kind: "CSV", size: "48 KB", sha: "77d0…" },
  { name: "closeout.md", kind: "MD", size: "12 KB", sha: "e4aa…" },
];

export const waveformGroups = [
  {
    id: "INPUT",
    easy: "Đầu vào",
    signals: ["clk", "rst_n", "valid_in", "token_id[15:0]", "teacher", "train"],
  },
  {
    id: "FORWARD",
    easy: "Suy luận",
    signals: ["ready_fwd", "mac_valid", "h_idx[4:0]", "acc[15:0]", "sat_flag", "layer[1:0]"],
  },
  {
    id: "LEARNING",
    easy: "Học",
    signals: ["learn_en", "d_pos[15:0]", "d_neg[15:0]", "margin_ok", "upd_en", "wr_addr[12:0]"],
  },
  {
    id: "MEMORY",
    easy: "Bộ nhớ",
    signals: ["axi_req", "axi_rnw", "addr[31:0]", "hit", "miss", "ep_id[19:0]"],
  },
  {
    id: "OUTPUT",
    easy: "Đầu ra",
    signals: ["lm_ready", "token_sel[15:0]", "out_valid", "argmax_en"],
  },
];

export const wfMarkers = [
  { t: 0.12, label: "User input accepted", easy: "Nhận câu hỏi", color: "var(--color-cyan)" },
  { t: 0.31, label: "Hidden complete", easy: "Đã hiểu câu", color: "var(--color-ok)" },
  { t: 0.44, label: "Margin check", easy: "So sánh đúng/sai", color: "var(--color-warn)" },
  { t: 0.52, label: "Update started", easy: "Bắt đầu học", color: "var(--color-learn)" },
  { t: 0.71, label: "Episode hit", easy: "Nhớ ra ký ức", color: "var(--color-mem)" },
  { t: 0.88, label: "Token emitted", easy: "Trả lời", color: "var(--color-ok)" },
];

export const learningTimeline = [
  { label: "Compare", easy: "So sánh ví dụ đúng và sai", detail: "d_pos 1320 · d_neg 4810", rtl: "cmp_en @ 8_218_188" },
  { label: "Margin +3490", easy: "Câu đúng đã gần hơn câu sai", detail: "vượt ngưỡng — không bắt buộc học", rtl: "margin_ok=1" },
  { label: "Teacher bật", easy: "Giáo viên vẫn yêu cầu ghi nhớ", detail: "vẫn ghi 286 giá trị (supervised)", rtl: "teacher=1 · train=1" },
  { label: "286 writes", easy: "286 chỗ trong não được chỉnh", detail: "141 tăng · 145 giảm · 0 clip", rtl: "upd_en burst 286" },
  { label: "Update complete", easy: "Học xong trong 12.4 ms", detail: "12.4 ms · BOARD snapshot", rtl: "upd_done @ 8_218_441" },
];

export const updateHist = [
  { bin: "−0.5", n: 12 },
  { bin: "−0.3", n: 41 },
  { bin: "−0.1", n: 92 },
  { bin: "0", n: 8930 },
  { bin: "+0.1", n: 89 },
  { bin: "+0.3", n: 44 },
  { bin: "+0.5", n: 8 },
];

export const consoleLog = [
  { t: "10:32:15.001", src: "TOK", msg: "7 token · UTF-8 32 B" },
  { t: "10:32:15.009", src: "FWD", msg: "embedding row E[1402]" },
  { t: "10:32:15.048", src: "CMP", msg: "d_pos=1320 d_neg=4810" },
  { t: "10:32:15.061", src: "LRN", msg: "upd_en=1 · 286 writes" },
  { t: "10:32:15.073", src: "EAM", msg: "HIT episode #488271" },
  { t: "10:32:15.134", src: "OUT", msg: "SELECTED Artix · cycle 8218441" },
];

export const rtlWrites = [
  { addr: "0x12C0", delta: "+0.214", en: 1, cycle: 8_218_301 },
  { addr: "0x12C1", delta: "−0.118", en: 1, cycle: 8_218_302 },
  { addr: "0x1314", delta: "+0.091", en: 1, cycle: 8_218_308 },
  { addr: "0x1402", delta: "−0.340", en: 1, cycle: 8_218_311 },
  { addr: "0x15A8", delta: "+0.055", en: 1, cycle: 8_218_319 },
];

export const easyStory = {
  headline: "AI vừa học xong một câu hỏi về chip trên board.",
  bullets: [
    "Bạn hỏi: Board hiện tại dùng chip gì?",
    "AI trả lời: Arty A7 sử dụng FPGA Artix-7.",
    "Câu đúng đã gần hơn câu sai — nên không bắt buộc học thêm.",
    "Teacher vẫn bật, nên 286 giá trị được ghi có kiểm soát.",
    "Ký ức Episode #488271 được cập nhật (HIT).",
  ],
};

export const glossary: Record<string, { title: string; body: string }> = {
  rank: {
    title: "Effective rank = 19/32",
    body: "32 chiều nội bộ của AI đang còn đủ khác nhau. Khi số chiều hiệu dụng giảm mạnh, AI khó phân biệt các input khác nhau.",
  },
  margin: {
    title: "Margin = +3490",
    body: "Ví dụ đúng đang gần Anchor hơn ví dụ sai. Margin dương nghĩa là mô hình đã phân biệt đủ tốt trên tương tác này.",
  },
  sat: {
    title: "Hidden saturation = 2.1%",
    body: "Rất ít giá trị nội bộ chạm giới hạn số học. Saturation cao trên nhiều chiều làm representation mất thông tin.",
  },
  wns: {
    title: "WNS = +0.312 ns",
    body: "Tín hiệu có đủ thời gian ổn định trước cạnh clock kế tiếp theo phân tích timing hiện tại.",
  },
  auc: {
    title: "AUC = 0.742",
    body: "Khả năng xếp hạng đúng/sai trên tập đánh giá host. Không phải số đo trực tiếp từ silicon.",
  },
};

export const compareBefore = {
  id: 500,
  dPos: 3910,
  dNeg: 2900,
  margin: -1010,
  rank: 14,
  sat: 21,
  memory: "MISS",
  answer: "Sai",
};

export const capturePresets = [
  "Khi người dùng gửi câu hỏi",
  "Khi AI bắt đầu học",
  "Khi weight thay đổi",
  "Khi saturation xảy ra",
  "Khi memory HIT",
  "Khi memory MISS",
  "Khi sinh token",
  "Khi có lỗi",
];

export const STAGE_TO_TAB: Record<StageId, TabId> = {
  input: "input",
  encode: "forward",
  compare: "compare",
  learn: "learning",
  memory: "eam",
  model: "model",
  output: "output",
};

export const memCells: Array<"hit" | "miss" | "occ" | "free"> = Array.from({ length: 192 }, (_, i) => {
  if (i === 77 || i === 78 || i === 89) return "hit";
  const r = seeded(9, i);
  if (r > 0.84) return "occ";
  if (r > 0.78) return "miss";
  return "free";
});
