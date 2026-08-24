import { awaiting, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Btn, Kpi, Panel, PanelTitle, Pill } from "../ui";
import { Funnel } from "../viz";

/**
 * Bộ nhớ (§15). Funnel and events come from the recorded interaction.
 * Occupancy is withheld: no page/block source exists on this lane.
 *
 * Owner: gb-ux-product.
 */
function vn(n: number): string {
  return n.toLocaleString("vi-VN");
}

export function EamTab() {
  const { setTab, level } = useStudio();
  const header = useStudioHeader();
  const retrieval = sessionView.retrieval;
  const events = sessionView.memoryEvents;
  const selected = retrieval?.selectedEpisodeId ?? null;

  const funnelSteps = retrieval
    ? [
        ...retrieval.stages.map((s) => ({ label: s.label, n: s.count })),
        ...(selected ? [{ label: `Episode #${selected}`, n: 1 }] : []),
      ]
    : [];

  if (!retrieval) {
    return (
      <Panel>
        <PanelTitle>Chưa có truy hồi</PanelTitle>
        <p className="text-[13px] text-muted">{awaiting("eamHitRate").why}</p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        <EvidenceBadge provenance={retrieval.provenance} />
      </div>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2">
            <Kpi
              label="Ký ức được chọn"
              value={selected ? `#${selected}` : "không khớp"}
              sub="Từ phễu truy hồi đã ghi"
              tone="text-mem"
            />
            <Kpi
              label="Bước lọc"
              value={String(retrieval.stages.length)}
              sub="Không vẽ 800.000 ô"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {retrieval.stages.map((s) => (
              <Kpi key={s.label} label={s.label} value={vn(s.count)} />
            ))}
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi label="ep_id" value={selected ?? "null"} />
            <Kpi label="hit" value={selected ? "1" : "0"} />
            <Kpi label="events" value={String(events.length)} />
            <Kpi label="src" value={retrieval.provenance.source} />
          </div>
        }
      />

      <div className="grid gap-3 lg:grid-cols-[1.1fr_1fr]">
        <Panel>
          <PanelTitle>Phễu truy hồi</PanelTitle>
          <Funnel steps={funnelSteps} />
        </Panel>
        <Panel>
          <PanelTitle>Ký ức được chọn</PanelTitle>
          {selected ? (
            <dl className="space-y-2 text-[13px]">
              <div>
                <div className="text-caption text-subtle">Episode</div>
                #{selected}
              </div>
              <div>
                <div className="text-caption text-subtle">Học tại</div>
                không ghi trong tương tác này
              </div>
              <div>
                <div className="text-caption text-subtle">Cue / payload</div>
                không ghi — chỉ có mã episode
              </div>
              <div>
                <div className="text-caption text-subtle">Trạng thái</div>
                {events.some((e) => e.kind === "HIT") ? "HIT trong nhật ký" : "Không có HIT"}
              </div>
            </dl>
          ) : (
            <p className="text-[13px] text-muted">Phễu không chọn episode nào.</p>
          )}
          {selected ? (
            <Btn className="mt-3" onClick={() => setTab("model")}>
              Xem chỗ ký ức vào mô hình
            </Btn>
          ) : null}
        </Panel>
      </div>

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Bản đồ cue</PanelTitle>
          {selected ? (
            <svg viewBox="0 0 420 160" className="h-40 w-full" role="img" aria-label={`Episode ${selected}, không có cue được ghi.`}>
              <circle cx="210" cy="80" r="32" fill="#2dd4bf22" stroke="#2dd4bf" />
              <text x="210" y="84" textAnchor="middle" fill="#e8eef4" fontSize="12">
                #{selected}
              </text>
            </svg>
          ) : (
            <p className="text-[13px] text-muted">Không có episode để vẽ.</p>
          )}
          <p className="mt-2 text-caption text-subtle">
            Chỉ hiện episode được chọn. Không có danh sách cue trong bản ghi — không bịa nhãn.
          </p>
        </Panel>
        <Panel>
          <PanelTitle>Mật độ DDR</PanelTitle>
          <p className="text-[13px] text-muted">{awaiting("ddrUsage").why}</p>
          <p className="mt-2 text-caption text-subtle">
            Không vẽ page/block giả. {awaiting("ddrUsage").needs}.
          </p>
        </Panel>
      </div>

      <Panel>
        <PanelTitle>Nhật ký bộ nhớ</PanelTitle>
        {events.length === 0 ? (
          <p className="text-[13px] text-muted">Không có sự kiện bộ nhớ.</p>
        ) : (
          <table className="w-full text-left text-[13px]">
            <thead className="text-caption uppercase text-subtle">
              <tr>
                <th className="py-2">Loại</th>
                <th>Episode</th>
                <th>Địa chỉ</th>
                <th>Nguồn</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {events.map((e) => (
                <tr key={e.eventId} className="border-t border-line">
                  <td className="py-2">
                    <Pill tone={e.kind === "HIT" ? "ok" : e.kind === "MISS" ? "bad" : "mem"}>{e.kind}</Pill>
                  </td>
                  <td className="font-mono">{e.episodeId ? `#${e.episodeId}` : "—"}</td>
                  <td className="font-mono tabular">
                    {e.address === null ? "—" : `0x${e.address.toString(16)}`}
                  </td>
                  <td>
                    <EvidenceBadge provenance={e.provenance} />
                  </td>
                  <td>
                    <button
                      type="button"
                      className="text-caption text-cyan underline"
                      onClick={() => setTab("waveform")}
                    >
                      Mở sóng
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        {level === "rtl" ? (
          <p className="mt-2 text-caption text-subtle">axi_rnw / hit chỉ khi nguồn là BOARD. Bản ghi này là SYNTHETIC.</p>
        ) : null}
      </Panel>
    </div>
  );
}
