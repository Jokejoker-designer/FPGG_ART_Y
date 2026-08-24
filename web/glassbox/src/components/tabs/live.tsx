import { outputSelection, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { When } from "../level";
import { Btn, Panel, PanelTitle, Pill } from "../ui";

export function LiveTab() {
  const { chat, draft, setDraft, sendChat, teacherOff, toggleTeacher, frozen, toggleFrozen, startReplay, setTab, level } =
    useStudio();
  const header = useStudioHeader();
  return (
    <Panel className="flex min-h-[70vh] flex-col">
      <PanelTitle
        hint={
          level === "easy"
            ? "Replay hội thoại đã ghi"
            : level === "rtl"
              ? "out_valid / token_sel"
              : "Hybrid LM + EAM · SNAPSHOT"
        }
      >
        {level === "easy" ? "Hội thoại đã ghi" : "Phiên Live"}
      </PanelTitle>
      <When
        easy={
          <p className="mb-3 text-[13px] text-muted">
            Đây là bản ghi Interaction #{header.id}. Bo mạch trong lane này không có mô hình
            ngôn ngữ, nên câu bạn gõ được ghi lại mà chưa có đường sinh câu trả lời.
          </p>
        }
        research={
          <p className="mb-3 text-caption text-subtle">
            Nguồn {header.activeSource} · Interaction #{header.id} · câu mới không tạo
            waveform mới và không tạo bằng chứng silicon.
          </p>
        }
        rtl={
          <p className="mb-3 font-mono text-caption text-subtle">
            {outputSelection.cycle === null
              ? "out_valid: chưa ghi nhận cycle"
              : `out_valid @ cyc ${outputSelection.cycle}`}{" "}
            · token_sel={outputSelection.token ?? "chưa có"} · teacher=
            {teacherOff ? 0 : 1}
          </p>
        }
      />
      <div className="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1 gbx-scroll">
        {chat.map((m) => (
          <div key={m.id} className={m.role === "user" ? "ml-8 md:ml-24" : "mr-8 md:mr-24"}>
            <div
              className={
                m.role === "user"
                  ? "rounded-2xl rounded-tr-md bg-cyan/15 px-3 py-2 text-sm"
                  : "rounded-2xl rounded-tl-md border border-line bg-surface px-3 py-2 text-sm"
              }
            >
              {m.text}
            </div>
            <div className="mt-1 flex flex-wrap items-center gap-2 text-caption text-subtle">
              <span>
                {m.role === "user" ? "Bạn" : "Native AI"} · {m.time}
              </span>
              {level !== "easy" && m.meta ? <span className="font-mono">{m.meta}</span> : null}
              {m.learned === true ? (
                <Pill tone="learn">{level === "easy" ? "Đã học" : level === "rtl" ? "upd_en" : "Đã học"}</Pill>
              ) : null}
              {m.learned === false ? <Pill>{level === "easy" ? "Không cần học thêm" : "margin_ok"}</Pill> : null}
            </div>
          </div>
        ))}
      </div>
      {level !== "easy" ? (
        <div className="mt-3 flex flex-wrap gap-1.5">
          {sessionView.outputEvents.map((t) => (
            <span key={t.eventId} className="rounded-md border border-line bg-raised px-2 py-0.5 font-mono text-caption">
              {t.selectedText}
            </span>
          ))}
        </div>
      ) : null}
      <div className="mt-3 border-t border-line pt-3">
        <div className="flex gap-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                sendChat();
              }
            }}
            placeholder={level === "easy" ? "Thử hỏi thêm (mô phỏng, không ghi silicon)…" : "Nhập câu hỏi cho Native AI…"}
            className="h-11 min-w-0 flex-1 rounded-lg border border-line bg-surface px-3 text-sm outline-none focus:border-cyan"
          />
          <Btn variant="primary" className="h-11 px-4" onClick={sendChat}>
            Gửi
          </Btn>
        </div>
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <Btn className="h-8 text-xs" onClick={toggleTeacher}>
            {teacherOff ? "Teacher Off" : "Teacher On"}
          </Btn>
          <Btn className="h-8 text-xs" onClick={startReplay}>
            Replay
          </Btn>
          <Btn className="h-8 text-xs" onClick={toggleFrozen}>
            {frozen ? "Frozen" : "Freeze"}
          </Btn>
          <Btn className="h-8 text-xs" onClick={() => setTab("learning")}>
            {level === "easy" ? "Xem AI vừa học gì" : "Xem bên trong"}
          </Btn>
        </div>
      </div>
    </Panel>
  );
}
