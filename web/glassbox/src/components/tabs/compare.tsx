import { measured, sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { Explain } from "../explain";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Kpi, Panel, PanelTitle, Pill } from "../ui";
import { DistBars, MarginGauge } from "../viz";

/**
 * So sánh (§13). Decision to learn lives here. What actually changed lives
 * on the Học tab. Cosine is ĐO/EVAL, never training authority.
 *
 * Owner: gb-ux-product.
 */
function num(m: { value: number } | null): string {
  return m ? String(m.value) : "chưa đo";
}

export function CompareTab() {
  const { level } = useStudio();
  const header = useStudioHeader();
  const compare = sessionView.compare;
  const needUpdate = compare?.violated ?? false;
  const margin = measured.marginL1?.value ?? 0;
  const dPos = measured.dPos?.value ?? 0;
  const dNeg = measured.dNeg?.value ?? 0;

  if (!compare) {
    return (
      <Panel>
        <PanelTitle>Chưa có so sánh</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi sự kiện COMPARE. Không suy ra quyết định học.
        </p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        <EvidenceBadge provenance={compare.provenance} />
      </div>

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2">
            <Kpi
              label="Có bắt buộc học?"
              value={needUpdate ? "Có" : "Không"}
              sub={needUpdate ? "Ví dụ sai đang quá gần" : "Câu đúng đã đủ gần"}
              tone={needUpdate ? "text-learn" : "text-ok"}
            />
            <Kpi
              label="Mức phân biệt"
              value={num(measured.marginL1)}
              sub={measured.marginL1?.provenance.source}
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            <Kpi label="d_pos" value={num(measured.dPos)} sub={measured.dPos?.provenance.source} />
            <Kpi label="d_neg" value={num(measured.dNeg)} sub={measured.dNeg?.provenance.source} />
            <Kpi label="M_L1" value={num(measured.marginL1)} sub={measured.marginL1?.provenance.source} />
            <Kpi
              label="M_cos"
              value={measured.marginCosine ? String(measured.marginCosine.value) : "chưa đo"}
              sub="ĐO / EVAL"
            />
            <Kpi
              label="dH"
              value={measured.dH ? String(measured.dH.value) : "không dùng"}
              sub="unusable trên bit này"
            />
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi label="d_pos[15:0]" value={num(measured.dPos)} />
            <Kpi label="d_neg[15:0]" value={num(measured.dNeg)} />
            <Kpi label="margin_viol" value={needUpdate ? "1" : "0"} />
            <Kpi label="thr" value={String(compare.marginThreshold)} />
          </div>
        }
      />

      <div className="grid gap-3 lg:grid-cols-3">
        <Panel>
          <PanelTitle>Ba câu đang so sánh</PanelTitle>
          <dl className="space-y-3 text-[13px]">
            <div>
              <div className="text-caption text-subtle">
                {level === "rtl" ? "anchor_txt" : "Câu gốc"}
              </div>
              {compare.anchorText}
            </div>
            <div>
              <div className="text-caption text-ok">
                {level === "rtl" ? "pos_txt" : "Câu đúng"}
              </div>
              {compare.positiveText}
            </div>
            <div>
              <div className="text-caption text-bad">
                {level === "rtl" ? "neg_txt" : "Câu sai"}
              </div>
              {compare.negativeText}
            </div>
          </dl>
        </Panel>
        <Panel>
          <PanelTitle action={level !== "easy" ? <Explain id="margin" /> : undefined}>
            Khoảng cách
          </PanelTitle>
          <DistBars pos={dPos} neg={dNeg} />
        </Panel>
        <Panel>
          <PanelTitle>Mức phân biệt</PanelTitle>
          <MarginGauge value={margin} />
          <div
            className={
              needUpdate
                ? "mt-3 rounded-lg border border-learn/30 bg-learn/10 p-3"
                : "mt-3 rounded-lg border border-ok/30 bg-ok/10 p-3"
            }
          >
            <div className={`text-sm font-medium ${needUpdate ? "text-learn" : "text-ok"}`}>
              {needUpdate ? "Cần học thêm" : "Không cần cập nhật"}
            </div>
            <p className="mt-1 text-xs text-muted">
              {needUpdate
                ? "Ví dụ sai đang quá gần Anchor so với ngưỡng luật yêu cầu."
                : "Ví dụ đúng đã gần Anchor hơn ví dụ sai."}
            </p>
          </div>
        </Panel>
      </div>
    </div>
  );
}
