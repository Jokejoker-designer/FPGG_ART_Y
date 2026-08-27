import { useMemo, useState, type FormEvent } from "react";
import { OBS_CAPTURE, shaShort, type SourceId } from "./session";
import { SourceBadge } from "./source-badge";

interface Msg {
  id: string;
  role: "user" | "board";
  text: string;
  source: SourceId;
  time: string;
}

function nowStamp(): string {
  const t = new Date();
  return `${String(t.getHours()).padStart(2, "0")}:${String(t.getMinutes()).padStart(2, "0")}`;
}

function diagnose(raw: string): Pick<Msg, "text" | "source"> {
  const q = raw.trim().toLowerCase();
  if (!q) {
    return { text: "Empty command.", source: "ALERT" };
  }
  if (/(pred|664|token|output|trả lời|ai_response)/.test(q)) {
    return {
      text: "pred chưa phát trên UART. LAST_STAGE = CORE_START. Không có AI_RESPONSE.",
      source: "STALL",
    };
  }
  if (/(stage|pipeline|hang|stall|tới đâu|bao xa)/.test(q)) {
    return {
      text: "BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START. Stall after CORE_START. BIND_DONE not fired.",
      source: "BOARD",
    };
  }
  if (/(bit|sha|bitstream)/.test(q)) {
    return {
      text: `Bit ${OBS_CAPTURE.rev} SHA256 ${OBS_CAPTURE.bitSha}`,
      source: "BOARD",
    };
  }
  if (/(wns|timing|cdc|bram)/.test(q)) {
    return {
      text: `WNS +${OBS_CAPTURE.wnsNs.toFixed(3)} ns · CDC ${OBS_CAPTURE.unsafeCdc} · BRAM ${OBS_CAPTURE.bramUsed}/${OBS_CAPTURE.bramLimit} · SIM_FULL=${OBS_CAPTURE.simFull}`,
      source: "BOARD",
    };
  }
  if (/(com|uart|jtag|serial)/.test(q)) {
    return {
      text: `${OBS_CAPTURE.uart} @ ${OBS_CAPTURE.baud} closed. JTAG ${OBS_CAPTURE.jtag}. Capture ${OBS_CAPTURE.capturedAt}.`,
      source: "ALERT",
    };
  }
  if (/(xsim|mô phỏng|sim)/.test(q)) {
    return {
      text: "XSim: CORE_START → BIND_DONE → LM_ACTIVE → PRED_VALID. Not silicon.",
      source: "XSIM",
    };
  }
  if (/(weight|poke|mwr|0x30|ghi trọng)/.test(q)) {
    return {
      text: "Host weight poke blocked on Native V1. UART 0x30 / JTAG mwr is not learning evidence.",
      source: "ALERT",
    };
  }
  return {
    text: `No matching telemetry. LAST_STAGE=${OBS_CAPTURE.lastStage}. pred=∅.`,
    source: "STALL",
  };
}

const OPENING: Msg = {
  id: "sys-0",
  role: "board",
  text: `Capture ${OBS_CAPTURE.run} ${OBS_CAPTURE.rev}. LAST_STAGE=${OBS_CAPTURE.lastStage}. pred=∅. COM12 closed — replay only.`,
  source: "ALERT",
  time: "15:56",
};

export function BoardChat() {
  const [msgs, setMsgs] = useState<Msg[]>([OPENING]);

  const pending = useMemo(
    () => msgs.some((m) => m.role === "user") && OBS_CAPTURE.pred === null,
    [msgs],
  );

  function send(raw: string) {
    const text = raw.trim();
    if (!text) return;
    const user: Msg = { id: `u-${Date.now()}`, role: "user", text, source: "ACTIVE", time: nowStamp() };
    const answer = diagnose(text);
    const board: Msg = {
      id: `b-${Date.now()}`,
      role: "board",
      text: answer.text,
      source: answer.source,
      time: nowStamp(),
    };
    setMsgs((prev) => [...prev, user, board]);
  }

  function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    send(String(fd.get("cmd") ?? ""));
    e.currentTarget.reset();
  }

  return (
    <section
      data-testid="obs-chat"
      data-ready="1"
      className="flex h-full min-h-0 flex-col"
    >
      <header className="border-b border-line px-3 py-2">
        <div className="flex items-start justify-between gap-2">
          <div>
            <p className="obs-kicker">03 Console</p>
            <h2 className="text-sm font-medium tracking-tight text-fg">Phiên Live</h2>
            <p className="text-[11px] text-subtle">Host không sinh next-token.</p>
          </div>
          <SourceBadge source={pending ? "STALL" : OBS_CAPTURE.comOpen ? "BOARD" : "ALERT"} />
        </div>
      </header>
      <div className="min-h-0 flex-1 space-y-3 overflow-y-auto px-3 py-3 gbx-scroll">
        {msgs.map((m) => (
          <article
            key={m.id}
            className={m.role === "user" ? "ml-8 md:ml-12" : "mr-6 md:mr-10"}
            data-testid={m.role === "board" ? "obs-chat-board" : "obs-chat-user"}
          >
            <div
              className={
                m.role === "user"
                  ? "rounded-2xl rounded-tr-md bg-cyan/15 px-3 py-2 text-sm"
                  : "rounded-2xl rounded-tl-md border border-line bg-surface px-3 py-2 text-sm obs-mono leading-5"
              }
            >
              {m.text}
            </div>
            <div className="mt-1 flex flex-wrap items-center gap-2 text-caption text-subtle">
              <span>
                {m.role === "user" ? "Bạn" : "Native AI"} · <span className="obs-mono">{m.time}</span>
              </span>
              <SourceBadge source={m.source} />
            </div>
          </article>
        ))}
      </div>
      <form className="shrink-0 border-t border-line p-3" onSubmit={onSubmit}>
        <div className="flex gap-2">
          <input
            name="cmd"
            placeholder="LAST_STAGE · BIT · UART · WNS"
            className="h-11 min-w-0 flex-1 rounded-lg border border-line bg-surface px-3 text-sm outline-none focus:border-cyan"
            aria-label="Lệnh gửi tới FPGA"
            autoComplete="off"
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                send(e.currentTarget.value);
                e.currentTarget.form?.reset();
              }
            }}
          />
          <button
            type="submit"
            className="inline-flex h-11 items-center justify-center rounded-lg bg-cyan px-4 text-sm font-medium text-bg hover:brightness-110"
          >
            Gửi
          </button>
        </div>
        <p className="mt-2 obs-mono text-[11px] text-subtle">
          bit {shaShort(OBS_CAPTURE.bitSha)} · {OBS_CAPTURE.uart} @{OBS_CAPTURE.baud}
        </p>
      </form>
    </section>
  );
}
