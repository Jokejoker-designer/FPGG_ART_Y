import { sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Btn, Kpi, Panel, PanelTitle, Pill } from "../ui";
import { Waterfall } from "../viz";

/**
 * Mô hình xử lý (§16). Stages and timings from recorded ModelEvent only.
 * Does not treat activations as thought.
 *
 * Owner: gb-ux-product.
 */
function vn(n: number): string {
  return n.toLocaleString("vi-VN");
}

function msOf(v: { value: number } | null | undefined): string {
  return v ? `${v.value.toFixed(1)} ms` : "chưa đo";
}

export function ModelTab() {
  const { setTab, level } = useStudio();
  const header = useStudioHeader();
  const events = sessionView.modelEvents;
  const first = events[0] ?? null;
  const injected = events.find((e) => e.contextEpisodeId);
  const layer1 = events.find((e) => e.stage === "Layer 1") ?? events.find((e) => e.layerIndex === 1);

  if (events.length === 0) {
    return (
      <Panel>
        <PanelTitle>Chưa có đường mô hình</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi sự kiện mô hình. Lane 03E trên bo không có mô hình ngôn ngữ.
        </p>
      </Panel>
    );
  }

  const waterfall = events.map((e) => ({
    label: e.stage,
    ms: e.durationMs.value,
  }));

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        {first ? <EvidenceBadge provenance={first.provenance} /> : null}
      </div>

      <Panel>
        <PanelTitle>Đường xử lý</PanelTitle>
        <p className="text-[13px] text-muted">{events.map((e) => e.stage).join(" → ")}</p>
        <p className="mt-2 text-caption text-subtle">
          Đây là các bước đã ghi — không phải “AI đang nghĩ”.
        </p>
      </Panel>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2">
            <Kpi
              label="Thời gian Layer 1"
              value={layer1 ? msOf(layer1.durationMs) : "chưa đo"}
              sub={layer1?.durationMs.provenance.source}
            />
            <Kpi
              label="Ký ức vào mô hình"
              value={injected?.contextEpisodeId ? `#${injected.contextEpisodeId}` : "không"}
              sub="Memory context"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {events.map((e) => (
              <Kpi
                key={e.eventId}
                label={e.stage}
                value={msOf(e.durationMs)}
                sub={e.macCycles ? `${vn(e.macCycles.value)} MAC` : undefined}
              />
            ))}
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {events.map((e) => (
              <Kpi
                key={e.eventId}
                label={e.stage.replace(/ /g, "_")}
                value={msOf(e.durationMs)}
                sub={e.layerIndex === null ? "layer —" : `layer ${e.layerIndex}`}
              />
            ))}
          </div>
        }
      />

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Thời gian từng bước</PanelTitle>
          <Waterfall rows={waterfall} />
        </Panel>
        <Panel>
          <PanelTitle>Ký ức vào mô hình</PanelTitle>
          {injected?.contextEpisodeId ? (
            <>
              <p className="text-sm">
                Episode #{injected.contextEpisodeId} → Context → Model
              </p>
              <p className="mt-2 text-[13px] text-muted">
                Bước “{injected.stage}” ghi mã episode này. Không suy nội dung payload.
              </p>
              <Btn className="mt-3" onClick={() => setTab("eam")}>
                Về bộ nhớ
              </Btn>
            </>
          ) : (
            <p className="text-[13px] text-muted">Không có bước nào ghi contextEpisodeId.</p>
          )}
        </Panel>
      </div>

      {level !== "easy" && layer1 ? (
        <Panel>
          <PanelTitle>{layer1.stage}</PanelTitle>
          <dl className="grid gap-2 sm:grid-cols-2 text-[13px]">
            <div>
              <div className="text-caption text-subtle">Thời gian</div>
              {msOf(layer1.durationMs)}
            </div>
            <div>
              <div className="text-caption text-subtle">Saturation</div>
              {layer1.saturation
                ? `${(layer1.saturation.value * 100).toFixed(1)}%`
                : "chưa đo"}
            </div>
            <div>
              <div className="text-caption text-subtle">DDR</div>
              {layer1.ddrBytes ? `${vn(layer1.ddrBytes.value)} B` : "chưa đo"}
            </div>
            <div>
              <div className="text-caption text-subtle">MAC</div>
              {layer1.macCycles ? vn(layer1.macCycles.value) : "chưa đo"}
            </div>
            <div>
              <div className="text-caption text-subtle">Activation norm</div>
              {layer1.activationNorm ? vn(layer1.activationNorm.value) : "chưa đo"}
            </div>
            <div>
              <div className="text-caption text-subtle">Stalls</div>
              {layer1.stalls ? vn(layer1.stalls.value) : "chưa đo"}
            </div>
            <div>
              <div className="text-caption text-subtle">Layer index</div>
              {layer1.layerIndex ?? "—"}
            </div>
          </dl>
          <EvidenceBadge provenance={layer1.provenance} />
        </Panel>
      ) : null}
    </div>
  );
}
