/**
 * Synthetic waveform captures.
 *
 * REPOSITORY LAW. `.agents/skills/a7-fpga-gate/SKILL.md` and
 * `results/A7-EAM-03E/final.md` §23 make LiteScope a hard stop before Native
 * V1 freeze. Nothing here reads hardware. These captures are generated from a
 * fixed seed, stamped SYNTHETIC, and exist so Tab 10 can be built and tested
 * before the capture plane is permitted to exist.
 *
 * Owner: gb-frontend-architecture (fixture data). The viewer that renders it
 * is owned by gb-waveform-glassbox.
 */
import type {
  CaptureGroup,
  SignalDescriptor,
  SignalTrace,
  WaveformAnnotation,
  WaveformCapture,
  WaveformResult,
  WaveformSource,
} from "@/lib/contract";
import { createRng, rngInt } from "./prng";
import { FIXTURE_CAPTURED_AT, SYNTHETIC } from "./provenance";

const CLOCK_MHZ = 100;
const CAPTURE_CYCLES = 12_000;

interface SignalSeed {
  id: string;
  label: string;
  rtlName: string | null;
  group: CaptureGroup;
  kind: SignalDescriptor["kind"];
  width: number;
  enumLabels?: Record<string, string>;
}

/** §18 five capture groups, with beginner labels separate from RTL names. */
const SIGNAL_SEEDS: readonly SignalSeed[] = [
  { id: "in_valid", label: "Nhận dữ liệu vào", rtlName: "i_valid", group: "INPUT", kind: "BIT", width: 1 },
  { id: "in_byte", label: "Byte đang đọc", rtlName: "i_byte", group: "INPUT", kind: "BUS", width: 8 },
  { id: "in_pos", label: "Vị trí ký tự", rtlName: "i_pos", group: "INPUT", kind: "BUS", width: 6 },
  { id: "in_mode", label: "Chế độ học", rtlName: "learn_eff", group: "INPUT", kind: "BIT", width: 1 },
  {
    id: "enc_state",
    label: "Trạng thái bộ mã hóa",
    rtlName: "enc_state",
    group: "FORWARD",
    kind: "ENUM",
    width: 4,
    enumLabels: { "0": "IDLE", "1": "EISS", "2": "ELAT", "3": "HWR", "4": "PACC", "5": "DONE" },
  },
  { id: "enc_addr", label: "Địa chỉ embedding", rtlName: "e_ra", group: "FORWARD", kind: "BUS", width: 8 },
  { id: "mac_valid", label: "Nhân tích lũy", rtlName: "mac_valid", group: "FORWARD", kind: "BIT", width: 1 },
  { id: "hid_sat", label: "Chạm giới hạn số học", rtlName: "h_sat", group: "FORWARD", kind: "BIT", width: 1 },
  { id: "cmp_phase", label: "Pha so sánh", rtlName: "apn_phase", group: "LEARNING", kind: "ENUM", width: 2, enumLabels: { "0": "A", "1": "P", "2": "N" } },
  { id: "d_pos", label: "Khoảng cách tới ví dụ đúng", rtlName: "d1_pos", group: "LEARNING", kind: "BUS", width: 16 },
  { id: "d_neg", label: "Khoảng cách tới ví dụ sai", rtlName: "d1_neg", group: "LEARNING", kind: "BUS", width: 16 },
  { id: "violation", label: "Vi phạm ngưỡng", rtlName: "margin_viol", group: "LEARNING", kind: "BIT", width: 1 },
  { id: "upd_en", label: "Cho phép cập nhật", rtlName: "upd_en", group: "LEARNING", kind: "BIT", width: 1 },
  { id: "upd_addr", label: "Địa chỉ đang ghi", rtlName: "upd_wa", group: "LEARNING", kind: "BUS", width: 13 },
  { id: "ddr_req", label: "Yêu cầu bộ nhớ", rtlName: "axi_arvalid", group: "DDR_MEMORY", kind: "BIT", width: 1 },
  { id: "ddr_stall", label: "Chờ bộ nhớ", rtlName: "axi_stall", group: "DDR_MEMORY", kind: "BIT", width: 1 },
  { id: "ep_id", label: "Ký ức được chọn", rtlName: "episode_id", group: "DDR_MEMORY", kind: "BUS", width: 20 },
  { id: "ep_hit", label: "Tìm thấy ký ức", rtlName: "ep_hit", group: "DDR_MEMORY", kind: "BIT", width: 1 },
  { id: "lm_stage", label: "Giai đoạn mô hình", rtlName: "lm_stage", group: "OUTPUT", kind: "ENUM", width: 3, enumLabels: { "0": "EMB", "1": "L1", "2": "ATTN", "3": "L2", "4": "CTX", "5": "HEAD" } },
  { id: "tok_valid", label: "Token đã sinh", rtlName: "tok_valid", group: "OUTPUT", kind: "BIT", width: 1 },
  { id: "tok_id", label: "Mã token", rtlName: "tok_id", group: "OUTPUT", kind: "BUS", width: 12 },
];

const SIGNALS: readonly SignalDescriptor[] = SIGNAL_SEEDS.map((seed) => {
  const base: SignalDescriptor = {
    id: seed.id,
    label: seed.label,
    rtlName: seed.rtlName,
    group: seed.group,
    kind: seed.kind,
    width: seed.width,
  };
  return seed.enumLabels ? { ...base, enumLabels: seed.enumLabels } : base;
});

/**
 * Transitions only, never one sample per cycle. A 12k-cycle capture over 21
 * signals is a few hundred transitions this way, which is what makes the
 * viewer affordable (§29).
 */
function buildTraces(seed: number): SignalTrace[] {
  const rng = createRng(seed);
  return SIGNALS.map((signal) => {
    const transitions: SignalTrace["transitions"] = [];
    const maxValue = signal.width >= 31 ? 0x7fffffff : (1 << signal.width) - 1;
    let cycle = rngInt(rng, 0, 40);
    let value = 0;
    while (cycle < CAPTURE_CYCLES) {
      transitions.push({ cycle, value });
      value =
        signal.kind === "BIT"
          ? value === 0
            ? 1
            : 0
          : rngInt(rng, 0, Math.min(maxValue, 4095));
      cycle += rngInt(rng, 24, 620);
    }
    return { signalId: signal.id, transitions };
  });
}

/** §18 mandatory annotation lane. Cycles follow the causal order of §6.2. */
const ANNOTATIONS: readonly WaveformAnnotation[] = [
  { kind: "USER_INPUT_ACCEPTED", cycle: 40, label: "Người dùng gửi câu hỏi" },
  { kind: "HIDDEN_COMPLETE", cycle: 1_480, label: "Biểu diễn nội bộ hoàn tất" },
  { kind: "MARGIN_VIOLATION", cycle: 2_260, label: "Vi phạm ngưỡng phân biệt" },
  { kind: "UPDATE_STARTED", cycle: 2_390, label: "Bắt đầu cập nhật 286 giá trị" },
  { kind: "EPISODE_HIT", cycle: 5_120, label: "Tìm thấy Episode #488271" },
  { kind: "LM_CONTEXT_LOADED", cycle: 6_040, label: "Nạp ngữ cảnh vào mô hình" },
  { kind: "TOKEN_EMITTED", cycle: 11_260, label: "Sinh token cuối" },
];

function buildCapture(interactionId: string, seed: number): WaveformCapture {
  return {
    captureId: `cap-${interactionId}`,
    interactionId,
    clockMhz: CLOCK_MHZ,
    cycles: { startCycle: 0, endCycle: CAPTURE_CYCLES },
    settings: {
      preTriggerSamples: 1_024,
      postTriggerSamples: 10_976,
      rle: true,
      subsampling: 1,
      mode: "SINGLE",
      trigger: "USER_SENT_QUESTION",
    },
    signals: [...SIGNALS],
    traces: buildTraces(seed),
    annotations: [...ANNOTATIONS],
    overflow: false,
    /* Export is offered only where the source can actually produce it. A
       synthetic source can emit a value dump and an event list, not a
       sigrok archive. */
    exportFormats: ["VCD", "CSV", "JSON_EVENTS"],
    provenance: SYNTHETIC,
  };
}

const CAPTURES: Record<string, WaveformCapture> = {
  "cap-1842": buildCapture("1842", 0x1842_beef),
};

/**
 * §26. Interaction 1841 deliberately has no capture, so the empty state is
 * exercised by real data rather than by a Storybook-only mock.
 */
const ABSENCES: Record<string, WaveformResult> = {
  "1841": {
    available: false,
    absence: {
      interactionId: "1841",
      reason: "CAPTURE_DISABLED",
      detail: "Capture không được bật khi sự kiện xảy ra.",
    },
  },
};

export const syntheticWaveformSource: WaveformSource = {
  kind: "SYNTHETIC",

  async listCaptures(interactionId) {
    const id = `cap-${interactionId}`;
    return CAPTURES[id] ? [id] : [];
  },

  async getCapture(captureId) {
    const capture = CAPTURES[captureId];
    if (!capture) {
      return {
        available: false,
        absence: {
          interactionId: captureId.replace(/^cap-/, ""),
          reason: "SOURCE_UNAVAILABLE",
          detail: "Không tìm thấy bản ghi waveform cho tương tác này.",
        },
      };
    }
    return { available: true, capture };
  },

  async getRange(captureId, from, to) {
    const found = await this.getCapture(captureId);
    if (!found.available) return found;
    const clipped: SignalTrace[] = found.capture.traces.map((trace) => ({
      signalId: trace.signalId,
      transitions: trace.transitions.filter(
        (t) => t.cycle >= from && t.cycle <= to,
      ),
    }));
    return {
      available: true,
      capture: {
        ...found.capture,
        cycles: { startCycle: from, endCycle: to },
        traces: clipped,
        annotations: found.capture.annotations.filter(
          (a) => a.cycle >= from && a.cycle <= to,
        ),
      },
    };
  },
};

export function waveformResultFor(interactionId: string): WaveformResult {
  const absence = ABSENCES[interactionId];
  if (absence) return absence;
  const capture = CAPTURES[`cap-${interactionId}`];
  if (capture) return { available: true, capture };
  return {
    available: false,
    absence: {
      interactionId,
      reason: "SOURCE_UNAVAILABLE",
      detail: "Không tìm thấy bản ghi waveform cho tương tác này.",
    },
  };
}

export const WAVEFORM_FIXTURE_CAPTURED_AT = FIXTURE_CAPTURED_AT;
