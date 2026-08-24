import { useMemo, useState } from "react";
import { toast } from "sonner";
import { artifacts } from "@/lib/data";
import { buildFacts, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { downloadArtifact } from "@/lib/export";
import { Explain } from "../explain";
import { EvidenceBadge } from "../ui/evidence-badge";
import { StudioState } from "../ui/studio-state";
import { Btn, Panel, PanelTitle, Pill } from "../ui";

/**
 * Bằng chứng (§21). Table from recorded EvidenceMetadata only.
 * SYNTHETIC/TWIN never use BOARD pill fill.
 *
 * Owner: gb-ux-product.
 */
const TRACE_Q: Record<string, string> = {
  input: "Người dùng đưa gì vào?",
  representation: "FPGA tạo biểu diễn nào?",
  decisionMetric: "Metric nào dẫn tới quyết định?",
  learningDecision: "Có học không, vì sao?",
  changedValues: "Giá trị nào đổi?",
  memoryAccess: "Bộ nhớ đọc/ghi gì?",
  modelContext: "Mô hình nhận ngữ cảnh nào?",
  selectedToken: "Token nào được chọn, cycle nào?",
};

export function EvidenceTab() {
  const header = useStudioHeader();
  const list = sessionView.interactions;
  const [id, setId] = useState(list[0]?.interactionId ?? "");
  const current = useMemo(
    () => list.find((i) => i.interactionId === id) ?? list[0] ?? null,
    [id, list],
  );
  const [preview, setPreview] = useState(artifacts[0]!.name);
  const selected = artifacts.find((a) => a.name === preview) ?? artifacts[0]!;
  const rows = current?.evidence ?? [];
  const audit = current?.traceability;
  const source = header.activeSource;
  const notBoard = !header.live;

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <label className="flex items-center gap-2 text-[13px] text-muted">
          Tương tác
          <select
            className="rounded-md border border-line bg-raised px-2 py-1 font-mono text-xs text-fg"
            value={id}
            onChange={(e) => setId(e.target.value)}
            data-testid="evidence-interaction"
          >
            {list.map((i) => (
              <option key={i.interactionId} value={i.interactionId}>
                #{i.interactionId}
              </option>
            ))}
          </select>
        </label>
        <Pill tone={header.live ? "board" : "warn"}>{source}</Pill>
        {audit ? (
          <Pill tone={audit.verdict === "FULLY_TRACEABLE" ? "ok" : "warn"}>{audit.verdict}</Pill>
        ) : null}
      </div>

      {audit?.verdict === "PARTIALLY_TRACEABLE" ? <StudioState kind="partial-trace" /> : null}

      {notBoard ? (
        <Panel className="border-warn/40">
          <PanelTitle>MÔ HÌNH / TWIN MODE</PanelTitle>
          <p className="text-[13px] text-warn">
            Dữ liệu hiện tại không phải silicon evidence. SYNTHETIC và TWIN không được tô như BOARD.
          </p>
        </Panel>
      ) : null}

      <Panel>
        <PanelTitle>Các loại nguồn</PanelTitle>
        <ul className="flex flex-wrap gap-2 text-[13px]">
          <li>
            <EvidenceBadge
              provenance={{ source: "BOARD", capturedAt: header.time }}
            />{" "}
            đo trên FPGA
          </li>
          <li>
            <EvidenceBadge
              provenance={{ source: "XSIM", capturedAt: header.time }}
            />{" "}
            mô phỏng RTL
          </li>
          <li>
            <EvidenceBadge
              provenance={{ source: "TWIN", capturedAt: header.time }}
            />{" "}
            mô hình host
          </li>
          <li>
            <EvidenceBadge
              provenance={{
                source: "DERIVED",
                derivedFrom: ["nguồn gốc"],
                capturedAt: header.time,
              }}
            />{" "}
            tính từ số đã đo
          </li>
          <li>
            <EvidenceBadge
              provenance={{ source: "SYNTHETIC", capturedAt: header.time }}
            />{" "}
            sinh sẵn, không phải đo
          </li>
        </ul>
      </Panel>

      <Panel>
        <PanelTitle action={<Explain id="gradient" />}>Bảng nguồn của tương tác này</PanelTitle>
        {rows.length === 0 ? (
          <p className="text-[13px] text-muted">Không có hàng bằng chứng được ghi.</p>
        ) : (
          <table className="w-full text-left text-[13px]" data-testid="evidence-table">
            <thead className="text-caption uppercase text-subtle">
              <tr>
                <th className="py-2">Metric</th>
                <th>Nguồn</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.metric} className="border-t border-line">
                  <td className="py-2">{r.metric}</td>
                  <td>
                    <EvidenceBadge provenance={r.provenance} />
                    {r.provenance.source === "DERIVED" && r.provenance.derivedFrom ? (
                      <span className="ml-2 text-caption text-subtle">
                        từ {r.provenance.derivedFrom.join(", ")}
                      </span>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Panel>

      <Panel>
        <PanelTitle>Truy vết đủ 8 câu?</PanelTitle>
        {audit ? (
          <ul className="space-y-1 text-[13px]" data-testid="evidence-trace">
            {audit.answered.map((q) => (
              <li key={q}>Có · {TRACE_Q[q] ?? q}</li>
            ))}
            {audit.missing.map((q) => (
              <li key={q} className="text-muted">
                Thiếu · {TRACE_Q[q] ?? q}
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-[13px] text-muted">Chưa chọn tương tác.</p>
        )}
      </Panel>

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Artifacts có thể xuất</PanelTitle>
          <ul className="space-y-2">
            {artifacts.map((a) => (
              <li
                key={a.name}
                className="flex items-center justify-between rounded-xl border border-line bg-surface px-3 py-2"
              >
                <button type="button" onClick={() => setPreview(a.name)} className="min-w-0 text-left">
                  <div className="font-mono text-xs">{a.name}</div>
                  <div className="text-caption text-subtle">
                    {a.kind} · {a.size}
                  </div>
                </button>
                <Btn
                  className="h-8 shrink-0 text-xs"
                  onClick={() => {
                    const result = downloadArtifact(a.name);
                    if (result.ok)
                      toast.message(`Đã tải ${result.name}`, {
                        description: `${source} · không tự nhận BOARD`,
                      });
                    else toast.message("Không xuất được", { description: result.reason });
                  }}
                >
                  Tải
                </Btn>
              </li>
            ))}
          </ul>
          <p className="mt-2 text-caption text-subtle">Đang xem: {selected.name}</p>
        </Panel>
        <Panel>
          <PanelTitle>Nhận dạng bản dựng</PanelTitle>
          <dl className="grid gap-2 font-mono text-xs">
            <div>bitstream {header.bitstream ?? "chưa có"}</div>
            <div>source {header.sourceSha ?? "chưa có"}</div>
            <div>model {buildFacts.modelVersion}</div>
            <div>clock {header.clock}</div>
            <div>
              WNS{" "}
              {buildFacts.wnsNs === null
                ? "chưa đo"
                : `${buildFacts.wnsNs > 0 ? "+" : ""}${buildFacts.wnsNs} ns`}
            </div>
            <div>learning-law {buildFacts.learningLawId}</div>
            <div>memory-law {buildFacts.memoryLawId ?? "không có ở lane này"}</div>
            <div>timing {buildFacts.timingStatus ?? "chưa ghi"}</div>
          </dl>
        </Panel>
      </div>
    </div>
  );
}
