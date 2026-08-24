"use client";

import { create } from "zustand";
import { toast } from "sonner";
import type {
  ConnectionState,
  EmbeddingRow,
  Projection2D,
  Session,
} from "@/lib/contract";
import { embeddingRowsFor, projectionFor } from "@/fixtures/snapshots";
import {
  type TabId,
  type ViewLevel,
  type ChatMsg,
  type StageId,
  type StageState,
  initialChat,
  SESSION_RECORD,
  STAGES,
} from "./data";

const FIXTURE_CONNECTION: ConnectionState = {
  connected: false,
  activeSource: "SYNTHETIC",
  detail:
    "Đang dùng dữ liệu mô hình. Chưa kết nối bo mạch, nên các số trên màn hình không phải bằng chứng silicon.",
};

type StudioState = {
  session: Session;
  connection: ConnectionState;
  activeInteractionId: string;
  embeddingRows: EmbeddingRow[];
  projection: Projection2D | null;
  tab: TabId;
  level: ViewLevel;
  connected: boolean;
  sidebarOpen: boolean;
  selectedToken: number;
  selectedEpisode: number;
  selectedSignal: string;
  selectedRun: string;
  cursorNs: number;
  chat: ChatMsg[];
  draft: string;
  teacherOff: boolean;
  frozen: boolean;
  rle: boolean;
  preTrig: number;
  postTrig: number;
  groups: Record<string, boolean>;
  replaying: boolean;
  /** True once a question is recorded and no answer path has produced a reply. */
  awaitingAnswer: boolean;
  stageStates: Record<StageId, StageState>;
  projectName: string;
  retention: string;
  exportFmt: string;
  insightOpen: boolean;
  captureNextRequested: boolean;
  setTab: (tab: TabId) => void;
  setLevel: (level: ViewLevel) => void;
  setSidebar: (open: boolean) => void;
  setSelectedToken: (i: number) => void;
  setSelectedEpisode: (id: number) => void;
  setSelectedSignal: (s: string) => void;
  setSelectedRun: (s: string) => void;
  setCursor: (n: number) => void;
  setDraft: (s: string) => void;
  sendChat: () => void;
  toggleTeacher: () => void;
  toggleFrozen: () => void;
  toggleGroup: (id: string) => void;
  setRle: (v: boolean) => void;
  setPreTrig: (n: number) => void;
  setPostTrig: (n: number) => void;
  setProjectName: (s: string) => void;
  setRetention: (s: string) => void;
  setExportFmt: (s: string) => void;
  setInsightOpen: (open: boolean) => void;
  requestCaptureNext: () => void;
  startReplay: () => void;
};

const completeStates = Object.fromEntries(STAGES.map((s) => [s.id, "complete"])) as Record<
  StageId,
  StageState
>;

let replayTimer: ReturnType<typeof setTimeout> | undefined;

export const useStudio = create<StudioState>((set, get) => ({
  session: SESSION_RECORD,
  connection: FIXTURE_CONNECTION,
  activeInteractionId: SESSION_RECORD.interactions[0]?.interactionId ?? "1842",
  embeddingRows: embeddingRowsFor(SESSION_RECORD.interactions[0]?.interactionId ?? "1842"),
  projection: projectionFor(SESSION_RECORD.interactions[0]?.interactionId ?? "1842"),
  tab: "overview",
  level: "easy",
  connected: false,
  sidebarOpen: false,
  selectedToken: 4,
  selectedEpisode: 488271,
  selectedSignal: "valid_in",
  selectedRun: "R-1842",
  cursorNs: 512.4,
  chat: initialChat,
  draft: "",
  teacherOff: false,
  frozen: false,
  rle: true,
  preTrig: 256,
  postTrig: 1024,
  groups: {
    INPUT: true,
    FORWARD: true,
    LEARNING: true,
    MEMORY: true,
    OUTPUT: true,
  },
  replaying: false,
  awaitingAnswer: false,
  stageStates: { ...completeStates },
  projectName: "Native AI V1",
  retention: "30",
  exportFmt: "vcd",
  insightOpen: false,
  captureNextRequested: false,
  setTab: (tab) => set({ tab, sidebarOpen: false, insightOpen: false }),
  setLevel: (level) => {
    set({ level });
    toast.message(
      level === "easy" ? "Chế độ Dễ hiểu" : level === "research" ? "Chế độ Research" : "Chế độ RTL",
      {
        description:
          level === "easy"
            ? "Kể bằng lời — ẩn d_pos, cycle, hex."
            : level === "research"
              ? "Hiện rank, margin, AUC. Cùng interaction #1842."
              : "Tín hiệu, địa chỉ, bit-width. Cùng bitstream 7CEBA85.",
      },
    );
  },
  setSidebar: (sidebarOpen) => set({ sidebarOpen }),
  setSelectedToken: (selectedToken) => set({ selectedToken }),
  setSelectedEpisode: (selectedEpisode) => set({ selectedEpisode }),
  setSelectedSignal: (selectedSignal) => set({ selectedSignal }),
  setSelectedRun: (selectedRun) => set({ selectedRun }),
  setCursor: (cursorNs) => set({ cursorNs }),
  setDraft: (draft) => set({ draft }),
  toggleTeacher: () => {
    const next = !get().teacherOff;
    set({ teacherOff: next });
    toast.message(next ? "Teacher Off" : "Teacher On", {
      description: next ? "Recall không ghi trọng số." : "Supervised update được phép.",
    });
  },
  toggleFrozen: () => {
    const next = !get().frozen;
    set({ frozen: next });
    toast.message(next ? "Model đã đóng băng" : "Model mở để học", {
      description: next ? "Mọi update enable bị chặn." : "Learning law LL-06 đang hiệu lực.",
    });
  },
  toggleGroup: (id) => set({ groups: { ...get().groups, [id]: !get().groups[id] } }),
  setRle: (rle) => set({ rle }),
  setPreTrig: (preTrig) => set({ preTrig }),
  setPostTrig: (postTrig) => set({ postTrig }),
  setProjectName: (projectName) => set({ projectName }),
  setRetention: (retention) => set({ retention }),
  setExportFmt: (exportFmt) => set({ exportFmt }),
  setInsightOpen: (insightOpen) => set({ insightOpen }),
  requestCaptureNext: () => {
    set({ captureNextRequested: true });
    toast.message("Đã ghi yêu cầu capture cho lần sau", {
      description:
        "Bit hiện tại không có lệnh capture. Không trang bị LiteScope. Xem WaveformSource đã ghi.",
    });
  },
  /**
   * Records the operator's question. It does **not** produce an answer.
   *
   * The imported version picked a canned reply from a list and stamped it with
   * a latency and token count computed from the length of the input. That is
   * fabricated telemetry (§32.11) and a fabricated conversation (§32.17): the
   * 03E lane on the board has no language model, exposes no tokens, and
   * returns one integer plus three flags per transaction. Until a real answer
   * path exists, an unanswered question is shown as unanswered.
   */
  sendChat: () => {
    const text = get().draft.trim();
    if (!text) return;
    const t = new Date();
    const hh = `${t.getHours()}`.padStart(2, "0");
    const mm = `${t.getMinutes()}`.padStart(2, "0");
    const user: ChatMsg = {
      id: `u-${t.getTime()}`,
      role: "user",
      text,
      time: `${hh}:${mm}`,
    };
    set({ chat: [...get().chat, user], draft: "", awaitingAnswer: true });
  },
  startReplay: () => {
    if (replayTimer) clearTimeout(replayTimer);
    const waiting = Object.fromEntries(STAGES.map((s) => [s.id, "waiting"])) as Record<
      StageId,
      StageState
    >;
    set({ replaying: true, stageStates: waiting });
    toast.message("Replay Interaction #1842", { description: "INPUT → OUTPUT trên cùng interaction_id." });
    let i = 0;
    const tick = () => {
      if (i >= STAGES.length) {
        set({ replaying: false, stageStates: { ...completeStates } });
        /* No provenance claim here. The imported version announced
           "FULLY TRACEABLE · BOARD" on completion, which asserted silicon
           evidence for a replay. Traceability is a property of the recorded
           interaction and is reported on the Evidence tab against its source. */
        toast.message("Replay hoàn tất", {
          description: "Đã chạy lại INPUT → OUTPUT trên cùng interaction_id.",
        });
        return;
      }
      const cur = STAGES[i]!;
      const prev = i > 0 ? STAGES[i - 1] : undefined;
      set((s) => ({
        stageStates: {
          ...s.stageStates,
          ...(prev ? { [prev.id]: "complete" as StageState } : {}),
          [cur.id]: "active",
        },
      }));
      i += 1;
      replayTimer = setTimeout(tick, 520);
    };
    tick();
  },
}));
