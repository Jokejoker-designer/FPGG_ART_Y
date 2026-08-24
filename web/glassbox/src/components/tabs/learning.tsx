import { useMemo, useState } from "react";
import { measured, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Kpi, Panel, PanelTitle, Pill } from "../ui";
import { HistChart } from "../viz";

/**
 * Học (§14). Only observable update facts. No gradient column.
 *
 * Owner: gb-ux-product.
 */
function num(m: { value: number } | null): string {
  return m ? new Intl.NumberFormat("vi-VN").format(m.value) : "chưa đo";
}

function src(m: { provenance: { source: string } } | null): string | undefined {
  return m?.provenance.source;
}

export function LearningTab() {
  const { level, setTab } = useStudio();
  const header = useStudioHeader();
  const compare = sessionView.compare;
  const learn = sessionView.learningEvent;
  const writes = learn?.writes ?? [];
  const [picked, setPicked] = useState(0);
  const needUpdate = compare?.violated ?? false;

  const hist = [
    { bin: "âm", n: writes.filter((w) => w.delta < 0).length },
    { bin: "0", n: writes.filter((w) => w.delta === 0).length },
    { bin: "dương", n: writes.filter((w) => w.delta > 0).length },
  ];

  const whGrid = useMemo(() => {
    const grid = Array.from({ length: 32 }, () => Array.from({ length: 32 }, () => 0));
    for (const w of writes) {
      if (w.target !== "Wh") continue;
      const r = Math.floor(w.address / 32);
      const c = w.address % 32;
      if (r < 32 && c < 32) grid[r]![c] = w.delta;
    }
    return grid;
  }, [writes]);
  const whTouched = writes.filter((w) => w.target === "Wh").length;
  const eTouched = writes.filter((w) => w.target === "E");

  if (!learn) {
    return (
      <Panel>
        <PanelTitle>Chưa có lần học</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi sự kiện LEARN. Không bịa gradient hay Δw.
        </p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        <EvidenceBadge provenance={learn.provenance} />
        <button type="button" className="text-caption text-cyan underline" onClick={() => setTab("compare")}>
          Xem quyết định so sánh
        </button>
      </div>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <Kpi
              label="Chỗ được chỉnh"
              value={num(measured.weightsChanged)}
              sub={src(measured.weightsChanged)}
              tone="text-learn"
            />
            <Kpi
              label="Thời gian học"
              value={measured.learnMs ? `${measured.learnMs.value} ms` : "chưa đo"}
              sub={src(measured.learnMs)}
            />
            <Kpi
              label="Vì sao ghi?"
              value={needUpdate ? "Ngưỡng bị vi phạm" : "Teacher vẫn ghi"}
              sub="Quyết định nằm ở tab So sánh"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-6">
            <Kpi label="Giá trị học" value={num(measured.weightsTotal)} sub={src(measured.weightsTotal)} />
            <Kpi label="Thay đổi" value={num(measured.weightsChanged)} tone="text-learn" />
            <Kpi label="Tăng" value={num(measured.weightsUp)} tone="text-ok" />
            <Kpi label="Giảm" value={num(measured.weightsDown)} />
            <Kpi label="Clipped" value={num(measured.clipped)} />
            <Kpi
              label="Thời gian"
              value={measured.learnMs ? `${measured.learnMs.value} ms` : "chưa đo"}
            />
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-6">
            <Kpi label="learn_en" value={header.teacherOn ? "1" : "0"} />
            <Kpi label="upd_en" value={measured.updateEnabled ? "1" : "0"} tone="text-learn" />
            <Kpi label="wr_burst" value={num(measured.weightsChanged)} />
            <Kpi label="clip_flag" value={num(measured.clipped)} />
            <Kpi label="teacher" value={header.teacherOn ? "1" : "0"} />
            <Kpi label="duration" value={measured.learnMs ? String(measured.learnMs.value) : "—"} sub="ms" />
          </div>
        }
      />

      <Panel>
        <PanelTitle>Tóm tắt nhân quả</PanelTitle>
        <p className="text-[13px] text-muted">
          {needUpdate
            ? "AI cập nhật vì khoảng cách với ví dụ đúng chưa tốt hơn ví dụ sai đủ mức yêu cầu."
            : "Cặp đúng đã đủ xa cặp sai; lần ghi này chỉ xảy ra nếu teacher vẫn bật."}{" "}
          FPGA không xuất gradient — bảng bên dưới là hướng, địa chỉ, trước, Δ, sau.
        </p>
      </Panel>

      <div className="grid gap-3 lg:grid-cols-[1.1fr_1fr]">
        <Panel>
          <PanelTitle hint="Wh 32×32 · Δ only">Heatmap Δ trọng số</PanelTitle>
          {whTouched === 0 ? (
            <p className="text-[13px] text-muted">Không có lần ghi Wh trong tương tác này.</p>
          ) : (
            <div
              className="grid overflow-hidden rounded-lg border border-line"
              style={{ gridTemplateColumns: "repeat(32, minmax(0,1fr))" }}
              role="img"
              aria-label={`Ma trận Δ Wh 32 nhân 32, ${whTouched} ô khác 0.`}
            >
              {whGrid.flatMap((row, r) =>
                row.map((v, c) => (
                  <div
                    key={`${r}-${c}`}
                    title={`Wh[${r},${c}] Δ ${v}`}
                    className="aspect-square"
                    style={{
                      background:
                        v === 0
                          ? "transparent"
                          : v > 0
                            ? "color-mix(in oklab, var(--gb-learn) 70%, transparent)"
                            : "color-mix(in oklab, var(--gb-memory) 70%, transparent)",
                    }}
                  />
                )),
              )}
            </div>
          )}
          <p className="mt-2 text-caption text-subtle">
            Chỉ các ô thật sự được ghi. Không vẽ gradient giả.
          </p>
        </Panel>
        <Panel>
          <PanelTitle>Hàng embedding đổi</PanelTitle>
          {eTouched.length === 0 ? (
            <p className="text-[13px] text-muted">Không có lần ghi E.</p>
          ) : (
            <ul className="space-y-1 font-mono text-xs">
              {eTouched.map((w, i) => (
                <li key={`${w.address}-${i}`}>
                  E[{w.address}] {w.before} → {w.after} (Δ {w.delta})
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle>Phân bố cập nhật</PanelTitle>
          <HistChart data={hist} />
        </Panel>
        <Panel>
          <PanelTitle>Timeline học</PanelTitle>
          {learn.timeline.length === 0 ? (
            <p className="text-[13px] text-muted">Không có mốc.</p>
          ) : (
            <ol className="space-y-2">
              {learn.timeline.map((e, i) => (
                <li key={`${e.at}-${e.label}`}>
                  <button
                    type="button"
                    onClick={() => setPicked(i)}
                    className={
                      i === picked
                        ? "flex w-full gap-3 rounded-lg border border-cyan bg-cyan/10 px-2 py-1.5 text-left"
                        : "flex w-full gap-3 rounded-lg border border-transparent px-2 py-1.5 text-left hover:bg-raised"
                    }
                  >
                    <span className="mt-1 size-2 shrink-0 rounded-full bg-learn" />
                    <span>
                      <span className="block text-[13px]">
                        {i + 1}. {e.label}
                      </span>
                      <span className="block text-xs text-muted">{e.at}</span>
                    </span>
                  </button>
                </li>
              ))}
            </ol>
          )}
          {learn.timeline[picked] ? (
            <p className="mt-2 text-caption text-subtle">
              Đang chọn: {learn.timeline[picked]!.label}
            </p>
          ) : null}
        </Panel>
      </div>

      <Panel>
        <PanelTitle hint="trước · Δ · sau">Nhật ký ghi</PanelTitle>
        {writes.length === 0 ? (
          <p className="text-[13px] text-muted">Không có lần ghi.</p>
        ) : (
          <table className="w-full text-left text-xs">
            <thead className="text-subtle">
              <tr>
                <th className="py-1">đích</th>
                <th>địa chỉ</th>
                <th>trước</th>
                <th>Δ</th>
                <th>sau</th>
              </tr>
            </thead>
            <tbody>
              {writes.map((w, i) => (
                <tr key={`${w.target}-${w.address}-${i}`} className="border-t border-line font-mono">
                  <td className="py-1.5 text-cyan">{w.target}</td>
                  <td>0x{w.address.toString(16)}</td>
                  <td>{w.before}</td>
                  <td>{w.delta}</td>
                  <td>{w.after}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Panel>
    </div>
  );
}
