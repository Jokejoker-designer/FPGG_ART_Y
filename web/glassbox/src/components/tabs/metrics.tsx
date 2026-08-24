import { awaiting, buildFacts, measured, sessionView } from "@/lib/metrics";
import { HealthLines } from "../charts/health-lines";
import { Explain } from "../explain";
import { useStudioHeader } from "@/lib/studio-header";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Kpi, Panel, PanelTitle, Pill } from "../ui";

/**
 * Sức khỏe (§19).
 *
 * The imported version of this tab concluded "Representation đang ổn định. AI
 * vẫn phân biệt được các câu khác nhau, không bị xẹp." That is the opposite of
 * what this program measured: Phase S is recorded as `STABILITY_FAIL` on 11 of
 * 11 seeds, effective rank collapses toward 1, and AUC returns to chance.
 *
 * §19 exists precisely to catch that, and `a7-fpga-gate` states the rule this
 * tab now enforces: a metric that improves because the thing it measures
 * collapsed is a FAIL. So the verdict is read from the series, the collapse
 * alert is rendered from the numbers, and the baselines that beat the learned
 * model are shown rather than hidden.
 *
 * Owner: gb-ux-product.
 */
const VERDICT: Record<
  string,
  { text: string; tone: "ok" | "warn" | "bad"; easy: string }
> = {
  HEALTHY: {
    text: "TỐT",
    tone: "ok",
    easy: "AI vẫn phân biệt được các câu khác nhau.",
  },
  WATCH: {
    text: "CẦN THEO DÕI",
    tone: "warn",
    easy: "Có dấu hiệu các trạng thái bên trong đang giống nhau dần.",
  },
  COLLAPSING: {
    text: "ĐANG SỤP",
    tone: "bad",
    easy: "Các trạng thái bên trong đang trở nên gần giống nhau. Khả năng phân biệt đang mất dần.",
  },
  COLLAPSED: {
    text: "ĐÃ SỤP",
    tone: "bad",
    easy: "AI vẫn thay đổi trọng số, nhưng các trạng thái bên trong đã gần như giống nhau. Nó không còn phân biệt được dữ liệu khác nhau.",
  },
  UNKNOWN: {
    text: "CHƯA RÕ",
    tone: "warn",
    easy: "Chưa đủ số đo để kết luận.",
  },
};

export function MetricsTab() {
  const header = useStudioHeader();
  const health = sessionView.health;
  const verdict = VERDICT[health.verdict] ?? VERDICT.UNKNOWN!;
  const first = health.points[0];
  const last = health.points.at(-1);
  const beaten = health.baselines.filter((b) => b.beatsLearnedModel);

  const rankTrail = health.points
    .map((p) => p.effectiveRank?.value)
    .filter((v): v is number => v !== undefined && v !== null);
  const satTrail = health.points
    .map((p) => p.hiddenSaturation?.value)
    .filter((v): v is number => v !== undefined && v !== null);
  const aucTrail = health.points
    .map((p) => p.auc?.value)
    .filter((v): v is number => v !== undefined && v !== null);

  const collapsed =
    health.verdict === "COLLAPSED" || health.verdict === "COLLAPSING";

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        {last?.auc ? <EvidenceBadge provenance={last.auc.provenance} /> : null}
      </div>
      {/* §19 collapse alert, rendered from the series rather than asserted. */}
      {collapsed ? (
        <Panel className="border-bad/50">
          <div className="flex flex-wrap items-center gap-2">
            <Pill tone="bad">Cảnh báo: Representation Collapse</Pill>
            <span className="text-caption text-subtle">
              Đọc từ chuỗi sức khỏe của phiên này
            </span>
          </div>
          <dl className="mt-2 grid gap-1 font-mono text-xs sm:grid-cols-3">
            <div>
              <dt className="font-sans text-muted">Effective rank</dt>
              <dd>{rankTrail.join(" → ")}</dd>
            </div>
            <div>
              <dt className="font-sans text-muted">Saturation</dt>
              <dd>
                {satTrail.map((v) => `${Math.round(v * 100)}%`).join(" → ")}
              </dd>
            </div>
            <div>
              <dt className="font-sans text-muted">AUC</dt>
              <dd>{aucTrail.map((v) => v.toFixed(3)).join(" → ")}</dd>
            </div>
          </dl>
          <p className="mt-2 text-[13px] leading-relaxed">
            AI vẫn đang thay đổi trọng số nhưng các trạng thái bên trong đang trở
            nên gần giống nhau. Khả năng phân biệt dữ liệu đang mất dần, nên các
            chỉ số phía sau có thể trông tốt hơn thực tế.
          </p>
        </Panel>
      ) : null}

      <When
        easy={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <Kpi
              label="Học có ổn không?"
              value={verdict.text}
              sub={verdict.easy}
              tone={verdict.tone === "ok" ? "text-ok" : "text-bad"}
            />
            <Kpi
              label="Số chiều còn phân biệt được"
              value={
                last?.effectiveRank
                  ? `${last.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : "chưa đo"
              }
              sub={
                first?.effectiveRank
                  ? `lúc đầu ${first.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : undefined
              }
            />
            <Kpi
              label="Chạm giới hạn số học"
              value={
                last?.hiddenSaturation
                  ? `${Math.round(last.hiddenSaturation.value * 100)}%`
                  : "chưa đo"
              }
              sub="càng cao càng mất thông tin"
            />
          </div>
        }
        research={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi
              label="AUC"
              value={last?.auc ? last.auc.value.toFixed(3) : "chưa đo"}
              sub="HOST EVAL"
              tone={
                last?.auc && last.auc.value <= 0.55 ? "text-bad" : "text-cyan"
              }
            />
            <Kpi
              label="AP"
              value={
                last?.averagePrecision
                  ? last.averagePrecision.value.toFixed(3)
                  : "chưa đo"
              }
            />
            <Kpi
              label="M_L1"
              value={
                measured.marginL1
                  ? `${measured.marginL1.value > 0 ? "+" : ""}${measured.marginL1.value}`
                  : "chưa đo"
              }
              sub="DERIVED từ d_pos, d_neg"
            />
            <Kpi
              label="Effective rank"
              value={
                last?.effectiveRank
                  ? `${last.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : "chưa đo"
              }
              tone={
                last?.effectiveRank && last.effectiveRank.value <= 4
                  ? "text-bad"
                  : undefined
              }
            />
          </div>
        }
        rtl={
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Kpi
              label="rank"
              value={
                last?.effectiveRank
                  ? `${last.effectiveRank.value}/${buildFacts.hiddenDim}`
                  : "n/a"
              }
            />
            <Kpi
              label="sat"
              value={
                last?.hiddenSaturation
                  ? last.hiddenSaturation.value.toFixed(3)
                  : "n/a"
              }
            />
            <Kpi
              label="max|Wh|"
              value={last?.maxAbsWh ? String(last.maxAbsWh.value) : "n/a"}
            />
            <Kpi
              label="law"
              value={buildFacts.learningLawId}
            />
          </div>
        }
      />

      <Panel>
        <PanelTitle
          hint="Trục X = số lần cập nhật"
          action={
            <div className="flex gap-2">
              <Explain id="auc" />
              <Explain id="sat" />
            </div>
          }
        >
          Sức khỏe dài hạn
        </PanelTitle>
        <HealthLines series={health} hiddenDim={buildFacts.hiddenDim} />
      </Panel>

      {/* §19: never hide a baseline that beats the learned model. */}
      <Panel>
        <PanelTitle hint="Cùng tập held-out">So với mốc tham chiếu</PanelTitle>
        {health.baselines.length === 0 ? (
          <p className="text-sm text-muted">Chưa có mốc tham chiếu nào.</p>
        ) : (
          <>
            <table className="w-full text-left text-[13px]">
              <thead className="text-caption text-muted">
                <tr>
                  <th scope="col" className="py-1">Mốc</th>
                  <th scope="col" className="py-1 text-right">AUC</th>
                  <th scope="col" className="py-1 text-right">So với model</th>
                </tr>
              </thead>
              <tbody>
                {health.baselines.map((baseline) => (
                  <tr key={baseline.label} className="border-t border-line">
                    <td className="py-2">{baseline.label}</td>
                    <td className="py-2 text-right font-mono tabular">
                      {baseline.auc.value.toFixed(3)}
                    </td>
                    <td className="py-2 text-right">
                      {baseline.beatsLearnedModel ? (
                        <Pill tone="bad">thắng model</Pill>
                      ) : (
                        <Pill tone="ok">kém hơn model</Pill>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {beaten.length > 0 ? (
              <p className="mt-2 text-[13px] leading-relaxed text-muted">
                <span className="font-mono">{beaten.length}</span> mốc tham chiếu
                đang cho kết quả tốt hơn mô hình đã học. Không ẩn con số này:
                một mô hình học được mà thua histogram byte thì vấn đề nằm ở
                luật học, không ở cách trình bày.
              </p>
            ) : null}
          </>
        )}
      </Panel>

      <Panel>
        <PanelTitle hint="Cần thêm tín hiệu từ RTL">Chưa đo được</PanelTitle>
        <ul className="space-y-2 text-[13px]">
          {(["eamHitRate", "recall", "exactMatch", "falsePositive"] as const).map(
            (key) => {
              const item = awaiting(key);
              return (
                <li key={key} className="border-t border-line pt-2">
                  <div className="flex flex-wrap items-baseline gap-2">
                    <span className="text-fg">{item.label}</span>
                    <Pill tone="warn">chờ tín hiệu</Pill>
                  </div>
                  <p className="mt-0.5 text-caption text-muted">Cần: {item.needs}</p>
                  <p className="text-caption text-subtle">{item.why}</p>
                </li>
              );
            },
          )}
        </ul>
      </Panel>

    </div>
  );
}
