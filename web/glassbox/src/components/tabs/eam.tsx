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
  useStudio((s) => s.session);
  const { setTab, level } = useStudio();
  const header = useStudioHeader();
  const retrieval = sessionView.retrieval;
  const events = sessionView.memoryEvents ?? [];
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

      <div className="grid items-start gap-3 lg:grid-cols-[1.1fr_1fr]">
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

      <Panel data-testid="eam-memory-log">
        <PanelTitle
          hint={`${events.length} sự kiện đã ghi`}
          action={events[0] ? <EvidenceBadge provenance={events[0].provenance} /> : null}
        >
          Nhật ký bộ nhớ
        </PanelTitle>
        {events.length === 0 ? (
          <p className="rounded-lg border border-line bg-surface px-3 py-3 text-[13px] text-fg">
            Không có sự kiện bộ nhớ.
          </p>
        ) : (
          <ul className="divide-y divide-line overflow-hidden rounded-xl border border-line">
            {events.map((e) => (
              <li
                key={e.eventId}
                className="grid min-h-12 grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 bg-surface px-3 py-2.5 sm:grid-cols-[5.5rem_7rem_minmax(0,1fr)_auto_auto]"
              >
                <Pill tone={e.kind === "HIT" ? "ok" : e.kind === "MISS" ? "bad" : "mem"}>
                  {e.kind}
                </Pill>
                <span className="font-mono text-[13px] text-fg">
                  {e.episodeId ? `#${e.episodeId}` : "—"}
                </span>
                <span className="hidden font-mono text-[13px] tabular text-muted sm:inline">
                  {e.address === null ? "—" : `0x${e.address.toString(16)}`}
                </span>
                <span className="hidden sm:inline">
                  <EvidenceBadge provenance={e.provenance} />
                </span>
                <button
                  type="button"
                  className="justify-self-end text-caption text-cyan underline"
                  onClick={() => setTab("waveform")}
                >
                  Mở sóng
                </button>
              </li>
            ))}
          </ul>
        )}
        {level === "rtl" ? (
          <p className="mt-2 text-caption text-subtle">
            axi_rnw / hit chỉ khi nguồn là BOARD. Bản ghi này là SYNTHETIC.
          </p>
        ) : null}
      </Panel>

      <div className="grid items-start gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Bản đồ cue</PanelTitle>
          {selected ? (
            <div className="flex items-center gap-3">
              <div
                className="grid size-16 shrink-0 place-items-center rounded-full border border-mem bg-mem/15 font-mono text-xs text-fg"
                role="img"
                aria-label={`Episode ${selected}, không có cue được ghi.`}
              >
                #{selected}
              </div>
              <p className="text-[13px] text-muted">
                Chỉ hiện episode được chọn. Không có danh sách cue trong bản ghi — không bịa nhãn.
              </p>
            </div>
          ) : (
            <p className="text-[13px] text-muted">Không có episode để vẽ.</p>
          )}
        </Panel>
        <Panel>
          <PanelTitle>Mật độ DDR</PanelTitle>
          <p className="text-[13px] text-muted">{awaiting("ddrUsage").why}</p>
          <p className="mt-2 text-caption text-subtle">
            Không vẽ page/block giả. {awaiting("ddrUsage").needs}.
          </p>
        </Panel>
      </div>
    </div>
  );
}
