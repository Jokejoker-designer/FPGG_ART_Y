/**
 * The single place a screen gets a number from.
 *
 * Two kinds of thing live here, and keeping them apart is the point of the
 * module. `measured` values come from the frozen contract and carry their
 * provenance, so §25 travels with the figure. `AWAITING` names a metric the
 * product wants to show but that **no source currently produces** — and says
 * which hardware signal would produce it.
 *
 * That second list exists because the imported UI rendered every one of these
 * as a confident number stamped BOARD. On the 03E lane the board answers with
 * one 20-byte reply per PAIR transaction: `d1`, `dH`, `cue`, three flags,
 * `nA`, `nB`, `seed_lo`. `docs/contracts/A7-EAM-03E-UI.md` records that `dH`
 * and `cue` are unusable on this bitstream, so the live surface is `d1` plus
 * three flags. Everything else on this screen has to come from a recorded or
 * generated session, or be marked as awaiting silicon.
 *
 * When the backend holds a live link, the `measured` selectors keep their
 * shape and an entry moves out of `AWAITING`. Nothing in a component changes.
 *
 * Owner: gb-frontend-architecture.
 */
import {
  HIDDEN_DIM,
  type EmbeddingRow,
  type Interaction,
  type MeasuredFloat,
  type MeasuredInt,
  type Projection2D,
  type Session,
} from "@/lib/contract";
import { useStudio } from "@/lib/store";

/** What a metric is waiting for, in the operator's language and the RTL's. */
export interface AwaitingSignal {
  /** Vietnamese label shown in place of the number. */
  readonly label: string;
  /** The hardware signal or command that would supply it. */
  readonly needs: string;
  /** Why it cannot be derived from what the wire already carries. */
  readonly why: string;
}

/**
 * Metrics with no source on the 03E lane. Rendering any of these as a number
 * is an overclaim; the UI shows the label and the requirement instead.
 */
export const AWAITING: Record<string, AwaitingSignal> = {
  eamHitRate: {
    label: "Tỉ lệ truy hồi ký ức",
    needs: "Episode memory trên bo (lane 01R/02M), chưa có trên 03E",
    why: "Bitstream 03E không có bộ nhớ liên tưởng nào để đo tỉ lệ HIT.",
  },
  ddrUsage: {
    label: "Mức dùng DDR",
    needs: "Đếm giao dịch AXI/MIG đưa ra qua telemetry",
    why: "Reply 20 byte không mang thông tin bộ nhớ ngoài.",
  },
  tokenPerSec: {
    label: "Token mỗi giây",
    needs: "Đường sinh token của mô hình ngôn ngữ",
    why: "Lane 03E không có mô hình ngôn ngữ, nên không có token nào để đếm.",
  },
  tempC: {
    label: "Nhiệt độ die",
    needs: "XADC qua một lệnh UART mới",
    why: "Không có lệnh nào trên bit hiện tại đọc XADC.",
  },
  vccint: {
    label: "Điện áp lõi",
    needs: "XADC qua một lệnh UART mới",
    why: "Không có lệnh nào trên bit hiện tại đọc XADC.",
  },
  recall: {
    label: "Recall",
    needs: "Tập đánh giá có nhãn chạy trên bo",
    why: "Cần nhiều giao dịch có nhãn; chưa có đường chạy tự động trên silicon.",
  },
  exactMatch: {
    label: "Khớp chính xác",
    needs: "Đường trả lời của mô hình",
    why: "Không có câu trả lời nào từ bo để so khớp.",
  },
  falsePositive: {
    label: "Báo sai dương",
    needs: "Truy hồi ký ức có nhãn đúng/sai",
    why: "Không có truy hồi trên lane này.",
  },
  uartLink: {
    label: "Đường UART",
    needs: "Trạng thái cổng do backend nắm",
    why: "Frontend không được mở serial; hướng phụ thuộc đi qua adapter.",
  },
  ethLink: {
    label: "Đường Ethernet",
    needs: "Không có trong thiết kế hiện tại",
    why: "Bo không chạy stack Ethernet trong lane này.",
  },
};

export type AwaitingKey = keyof typeof AWAITING;

export function awaiting(key: AwaitingKey): AwaitingSignal {
  return AWAITING[key]!;
}

/* ------------------------------------------------------------------ measured */

function activeInteraction(session: Session): Interaction {
  const id = useStudio.getState().activeInteractionId;
  return (
    session.interactions.find((row) => row.interactionId === id) ??
    session.interactions[0]!
  );
}

function snapshot() {
  const { session, embeddingRows, projection } = useStudio.getState();
  return { session, interaction: activeInteraction(session), embeddingRows, projection };
}

function buildMeasured(interaction: Interaction) {
  const compare = interaction.compare[0] ?? null;
  const learning = interaction.learning[0] ?? null;
  const anchor =
    interaction.representation.find(
      (v) => v.role === "ANCHOR" && v.stage === "BEFORE_UPDATE",
    ) ?? null;
  return {
    dPos: compare?.dPos ?? null,
    dNeg: compare?.dNeg ?? null,
    marginL1: compare?.marginL1 ?? null,
    marginCosine: compare?.marginCosine ?? null,
    dH: compare?.dH ?? null,
    marginThreshold: compare?.marginThreshold ?? null,
    violated: compare?.violated ?? null,
    weightsTotal: learning?.learnedValueCount ?? null,
    weightsChanged: learning?.changedCount ?? null,
    weightsUp: learning?.increasedCount ?? null,
    weightsDown: learning?.decreasedCount ?? null,
    clipped: learning?.clippedCount ?? null,
    learnMs: learning?.durationMs ?? null,
    updateEnabled: learning?.updateEnabled ?? false,
    effectiveRank: anchor?.effectiveRank ?? null,
    saturation: anchor?.saturation ?? null,
    maxAbsHidden: anchor?.maxAbs ?? null,
    latencyMs: interaction.latencyMs,
    tokensOut: interaction.tokenCount,
  } satisfies Record<string, MeasuredInt | MeasuredFloat | boolean | number | null>;
}

/**
 * Everything a screen may render as a number. `null` means the recorded
 * interaction genuinely has no value, which is a state the UI must show rather
 * than fill in. Reads the port-hydrated store so HTTP and fixture stay one API.
 */
export const measured = new Proxy({} as ReturnType<typeof buildMeasured>, {
  get(_target, key: string) {
    return buildMeasured(snapshot().interaction)[key as keyof ReturnType<typeof buildMeasured>];
  },
});

/* --------------------------------------------------------------- build facts */

/**
 * Properties of the artifact, not measurements of a run. These deliberately
 * carry no provenance badge: giving one to a parameter count would invent an
 * observation. See `components/ui/build-fact.tsx`.
 */
function buildFactsFrom(session: Session) {
  return {
    modelVersion: session.build.modelVersion,
    learningLawId: session.build.learningLawId,
    memoryLawId: session.build.memoryLawId,
    paramsLm: session.build.parameters.lm,
    paramsEncoder: session.build.parameters.encoder,
    clockMhz: session.build.clockMhz,
    timingStatus: session.build.timingStatus,
    wnsNs: session.build.wnsNs,
    tnsNs: session.build.tnsNs,
    whsNs: session.build.whsNs,
    thsNs: session.build.thsNs,
    timingEndpoints: session.build.timingEndpoints,
    utilization: session.build.utilization,
    bitstreamSha256: session.build.bitstreamSha256,
    sourceSha256: session.build.sourceSha256,
    hiddenDim: HIDDEN_DIM,
  };
}

export const buildFacts = new Proxy({} as ReturnType<typeof buildFactsFrom>, {
  get(_target, key: string) {
    return buildFactsFrom(snapshot().session)[key as keyof ReturnType<typeof buildFactsFrom>];
  },
});

/* -------------------------------------------------------------- session view */

function buildSessionView(
  session: Session,
  interaction: Interaction,
  embeddingRows: EmbeddingRow[],
  projection: Projection2D | null,
) {
  return {
    health: session.health,
    interactions: session.interactions,
    retrieval: interaction.retrieval,
    memoryEvents: interaction.memory,
    modelEvents: interaction.model,
    outputEvents: interaction.output,
    inputEvent: interaction.input[0] ?? null,
    representation: interaction.representation,
    waveform: interaction.waveform,
    evidenceRows: interaction.evidence,
    traceability: interaction.traceability,
    stages: interaction.stages,
    compare: interaction.compare[0] ?? null,
    learningEvent: interaction.learning[0] ?? null,
    embeddingRows,
    projection,
  };
}

export const sessionView = new Proxy({} as ReturnType<typeof buildSessionView>, {
  get(_target, key: string) {
    const { session, interaction, embeddingRows, projection } = snapshot();
    return buildSessionView(session, interaction, embeddingRows, projection)[
      key as keyof ReturnType<typeof buildSessionView>
    ];
  },
});

/** §17 selected token and the cycle it was emitted on, when recorded. */
export const outputSelection = new Proxy(
  {} as { token: string | null; cycle: number | null },
  {
    get(_target, key: "token" | "cycle") {
      const last = snapshot().interaction.output.at(-1);
      const value = { token: last?.selectedText ?? null, cycle: last?.cycle ?? null };
      return value[key];
    },
  },
);

/** §9 plain-language state, derived rather than typed as a string constant. */
export function learningStatus(): string {
  const { interaction } = snapshot();
  if (interaction.stages.some((s) => s.state === "error"))
    return "Dừng giữa tiến trình";
  if (buildMeasured(interaction).updateEnabled) return "Đang học";
  if (interaction.mode === "FROZEN") return "Đã đóng băng";
  return "Không cần học thêm";
}
