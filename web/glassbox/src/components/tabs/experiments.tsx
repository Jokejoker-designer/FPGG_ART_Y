import { useEffect, useMemo, useState } from "react";
import { sessionView } from "@/lib/metrics";
import { listRememberedSessions } from "@/lib/session-idb";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Btn, Panel, PanelTitle, Pill } from "../ui";
import { HeatRow } from "../viz";

/**
 * Replay (§20). Compares two recorded interactions. Does not invent #500.
 *
 * Owner: gb-ux-product.
 */
function cell(value: string | number | null | undefined): string {
  if (value === null || value === undefined || value === "") return "chưa đo";
  return String(value);
}

export function ExperimentsTab() {
  const { startReplay, setTab, stageStates, session } = useStudio();
  const header = useStudioHeader();
  const [saved, setSaved] = useState<{ sessionId: string; openedAt: string }[]>([]);
  useEffect(() => {
    void listRememberedSessions().then(setSaved).catch(() => setSaved([]));
  }, [session.sessionId]);
  const list = sessionView.interactions;
  const [beforeId, setBeforeId] = useState(list[1]?.interactionId ?? list[0]?.interactionId ?? "");
  const [afterId, setAfterId] = useState(list[0]?.interactionId ?? "");
  const before = list.find((i) => i.interactionId === beforeId);
  const after = list.find((i) => i.interactionId === afterId);

  const beforeH = before?.representation.find((v) => v.role === "ANCHOR");
  const afterBefore = after?.representation.find((v) => v.role === "ANCHOR" && v.stage === "BEFORE_UPDATE");
  const afterAfter = after?.representation.find((v) => v.role === "ANCHOR" && v.stage === "AFTER_UPDATE");
  const writes = after?.learning[0]?.writes.filter((w) => w.target === "Wh") ?? [];
  const memBefore = before?.memory.some((e) => e.kind === "HIT")
    ? `#${before.retrieval?.selectedEpisodeId ?? "?"}`
    : before
      ? "MISS"
      : "chưa đo";
  const memAfter = after?.retrieval?.selectedEpisodeId
    ? `#${after.retrieval.selectedEpisodeId}`
    : after
      ? "MISS"
      : "chưa đo";

  const rows = useMemo(
    () => [
      ["d_pos", before?.compare[0]?.dPos?.value, after?.compare[0]?.dPos?.value],
      ["d_neg", before?.compare[0]?.dNeg?.value, after?.compare[0]?.dNeg?.value],
      ["Margin", before?.compare[0]?.marginL1?.value, after?.compare[0]?.marginL1?.value],
      [
        "Rank",
        beforeH?.effectiveRank?.value,
        afterAfter?.effectiveRank?.value ?? afterBefore?.effectiveRank?.value,
      ],
      [
        "Saturation",
        beforeH?.saturation ? `${(beforeH.saturation.value * 100).toFixed(1)}%` : null,
        afterAfter?.saturation
          ? `${(afterAfter.saturation.value * 100).toFixed(1)}%`
          : afterBefore?.saturation
            ? `${(afterBefore.saturation.value * 100).toFixed(1)}%`
            : null,
      ],
      ["Memory", memBefore, memAfter],
      ["Answer", before?.answer ?? "không có", after?.answer ?? "không có"],
    ],
    [before, after, beforeH, afterAfter, afterBefore, memBefore, memAfter],
  );

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        {after?.compare[0] ? <EvidenceBadge provenance={after.compare[0].provenance} /> : null}
      </div>

      <Panel>
        <PanelTitle>Chọn hai tương tác</PanelTitle>
        <div className="flex flex-wrap gap-3 text-[13px]">
          <label>
            Trước
            <select
              className="ml-2 h-8 rounded-lg border border-line bg-surface px-2"
              value={beforeId}
              onChange={(e) => setBeforeId(e.target.value)}
            >
              {list.map((i) => (
                <option key={i.interactionId} value={i.interactionId}>
                  #{i.interactionId}
                </option>
              ))}
            </select>
          </label>
          <label>
            Sau
            <select
              className="ml-2 h-8 rounded-lg border border-line bg-surface px-2"
              value={afterId}
              onChange={(e) => setAfterId(e.target.value)}
            >
              {list.map((i) => (
                <option key={`a-${i.interactionId}`} value={i.interactionId}>
                  #{i.interactionId}
                </option>
              ))}
            </select>
          </label>
          <Btn
            variant="primary"
            onClick={() => {
              startReplay();
              setTab("overview");
            }}
          >
            Chạy lại các bước
          </Btn>
        </div>
        <p className="mt-2 text-caption text-subtle">
          Chỉ các interaction_id có trong phiên. Không bịa Interaction #500.
          {saved[0]
            ? ` Bản lưu máy: ${saved.map((row) => row.sessionId).join(", ")}.`
            : " Chưa có bản IndexedDB (hoặc trình duyệt chặn lưu)."}
        </p>
      </Panel>

      <Panel>
        <PanelTitle>
          Trước / sau · #{beforeId || "—"} → #{afterId || "—"}
        </PanelTitle>
        <table className="w-full text-left text-[13px]">
          <thead className="text-subtle">
            <tr>
              <th className="py-1">Metric</th>
              <th>Trước</th>
              <th>Sau</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(([name, a, b]) => (
              <tr key={String(name)} className="border-t border-line">
                <td className="py-1.5">{name}</td>
                <td className="font-mono">{cell(a)}</td>
                <td className="font-mono">{cell(b)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Trạng thái ẩn (Anchor)</PanelTitle>
          {afterBefore && afterAfter ? (
            <div className="space-y-2">
              <HeatRow label="Trước học" values={afterBefore.values} />
              <HeatRow label="Sau học" values={afterAfter.values} />
            </div>
          ) : (
            <p className="text-[13px] text-muted">Tương tác sau không có cặp BEFORE/AFTER.</p>
          )}
        </Panel>
        <Panel>
          <PanelTitle>Δ Wh đã ghi</PanelTitle>
          {writes.length === 0 ? (
            <p className="text-[13px] text-muted">Không có lần ghi Wh trên tương tác sau.</p>
          ) : (
            <p className="text-[13px] text-muted">
              {writes.length} ô Wh đổi trên #{afterId}. Xem tab Học để thấy ma trận đầy đủ.
            </p>
          )}
          <Btn className="mt-3" onClick={() => setTab("learning")}>
            Mở nhật ký học
          </Btn>
        </Panel>
      </div>

      <Panel>
        <PanelTitle>Bộ nhớ</PanelTitle>
        <p className="text-[13px]">
          #{beforeId}: {memBefore}. #{afterId}: {memAfter}
          {memBefore === memAfter ? " · không đổi loại kết quả." : memAfter.startsWith("#") ? " · có HIT sau." : " · mất HIT."}
        </p>
      </Panel>

      <Panel>
        <PanelTitle>Replay bước xử lý</PanelTitle>
        <ol className="flex flex-wrap gap-2">
          {Object.entries(stageStates).map(([id, state]) => (
            <li key={id}>
              <Pill tone={state === "active" ? "cyan" : state === "complete" ? "ok" : "mute"}>
                {id} · {state}
              </Pill>
            </li>
          ))}
        </ol>
        <Btn className="mt-3" onClick={() => setTab("waveform")}>
          Mở sóng cùng interaction
        </Btn>
      </Panel>
    </div>
  );
}
