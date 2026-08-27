/**
 * Silicon capture for Observatory. Source: E2R-HB-UART-00 r3 CLOSEOUT.
 * Do not invent pred=664. Do not treat XSim as BOARD.
 */

export type SourceId =
  | "BOARD"
  | "XSIM"
  | "SYNTHETIC"
  | "TWIN"
  | "STALL"
  | "ALERT"
  | "ACTIVE"
  | "AI_RESPONSE";

export type StageStatus = "complete" | "last" | "expected" | "idle";

export interface PipelineStage {
  id: string;
  label: string;
  status: StageStatus;
  source: SourceId;
}

export interface UartLine {
  i: number;
  ascii: string;
  hex: string;
  source: SourceId;
}

export const OBS_CAPTURE = {
  run: "E2R-HB-UART-00",
  rev: "r3",
  capturedAt: "2026-08-25 15:56",
  jtag: "210319BE776EA",
  uart: "COM12",
  baud: 115200,
  comOpen: false,
  bitSha: "261C0CA1E147F2AE37F85C08321430CE653E34E8DC0A425788B0C0442B05504F",
  lastStage: "CORE_START",
  pred: null as number | null,
  wnsNs: 6.87,
  uiWnsNs: 2.464,
  unsafeCdc: 0,
  bramUsed: 104,
  bramLimit: 135,
  simFull: 0,
  clockMhz: 12.5,
  part: "xc7a100tcsg324-1",
  board: "Arty A7-100T",
} as const;

export const PIPELINE: PipelineStage[] = [
  { id: "BOOT", label: "BOOT", status: "complete", source: "BOARD" },
  { id: "MIG_OK", label: "MIG_OK", status: "complete", source: "BOARD" },
  { id: "WMEM_OK", label: "WMEM_OK", status: "complete", source: "BOARD" },
  { id: "SOA_OK", label: "SOA_OK", status: "complete", source: "BOARD" },
  { id: "CORE_START", label: "CORE_START", status: "last", source: "STALL" },
  { id: "BIND_DONE", label: "BIND_DONE", status: "expected", source: "XSIM" },
  { id: "LM_ACTIVE", label: "LM_ACTIVE", status: "expected", source: "XSIM" },
  { id: "PRED_VALID", label: "PRED_VALID", status: "expected", source: "XSIM" },
];

const ASCII = [
  "BOOT",
  "MIG_OK",
  "WMEM_OK",
  "SOA_OK",
  "CORE_START",
  "BOOT",
  "MIG_OK",
  "WMEM_OK",
  "SOA_OK",
  "CORE_START",
];

function toHex(text: string): string {
  return [...text]
    .map((ch) => ch.charCodeAt(0).toString(16).toUpperCase().padStart(2, "0"))
    .join(" ");
}

export const UART_LINES: UartLine[] = ASCII.map((ascii, i) => ({
  i: i + 1,
  ascii,
  hex: toHex(ascii),
  source: ascii === "CORE_START" ? "STALL" : "BOARD",
}));

export function shaShort(sha: string, n = 8): string {
  return `${sha.slice(0, n)}…`;
}

export const SILICON_WATERMARK = "KHÔNG PHẢI DỮ LIỆU SILICON";
