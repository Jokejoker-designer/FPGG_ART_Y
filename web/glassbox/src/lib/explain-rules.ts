import { buildFacts, measured, sessionView } from "@/lib/metrics";

/**
 * §22 frozen explanation rules. Titles insert the live number; bodies do not
 * invent a second measurement.
 *
 * Owner: gb-ux-product.
 */
export type ExplainTopic = "rank" | "margin" | "sat" | "wns" | "auc" | "gradient";

export function explainTopic(id: ExplainTopic): { title: string; body: string } {
  const last = sessionView.health.points.at(-1);
  const dim = buildFacts.hiddenDim;

  if (id === "rank") {
    const n = last?.effectiveRank?.value ?? measured.effectiveRank?.value ?? null;
    return {
      title: n === null ? "Effective rank = chưa đo" : `Effective rank = ${n}/${dim}`,
      body:
        n !== null && n <= 4
          ? `${dim} chiều nội bộ đang trở nên quá giống nhau. Khi số chiều hiệu dụng giảm mạnh, khó phân biệt các input khác nhau.`
          : `${dim} chiều nội bộ vẫn còn khác nhau đủ để xếp hạng. Khi rank rơi, khả năng phân biệt mất dần.`,
    };
  }

  if (id === "margin") {
    const m = measured.marginL1?.value ?? null;
    const viol = measured.violated;
    return {
      title: m === null ? "Margin = chưa đo" : `Margin = ${m > 0 ? "+" : ""}${m}`,
      body:
        viol === true
          ? "Cờ vi phạm ngưỡng đang bật: ví dụ sai vẫn quá gần so với luật, dù margin L1 có thể dương."
          : viol === false
            ? "Ví dụ đúng đã gần Anchor hơn ví dụ sai đủ mức luật yêu cầu."
            : "Chưa có cờ vi phạm. Không suy quyết định học từ dấu của margin.",
    };
  }

  if (id === "sat") {
    const s = last?.hiddenSaturation?.value ?? measured.saturation?.value ?? null;
    const pct = s === null ? null : Math.round(s * 100);
    return {
      title: pct === null ? "Hidden saturation = chưa đo" : `Hidden saturation = ${pct}%`,
      body:
        pct !== null && pct >= 70
          ? "Các giá trị bên trong đã chạm giới hạn số học trên nhiều chiều. Representation có thể mất thông tin."
          : "Ít chiều chạm trần số học. Saturation tăng là dấu hiệu sắp mất phân biệt.",
    };
  }

  if (id === "wns") {
    const w = buildFacts.wnsNs;
    return {
      title: w === null ? "WNS = chưa đo" : `WNS = ${w > 0 ? "+" : ""}${w} ns`,
      body: "Tín hiệu có đủ thời gian ổn định trước cạnh clock kế tiếp theo báo cáo timing của bitstream này. Đây là build fact, không phải đo runtime trên bo.",
    };
  }

  if (id === "auc") {
    const a = last?.auc?.value ?? null;
    return {
      title: a === null ? "AUC = chưa đo" : `AUC = ${a.toFixed(3)}`,
      body: "Khả năng xếp hạng đúng/sai trên tập đánh giá host. Không phải số đo trực tiếp từ silicon.",
    };
  }

  return {
    title: "Gradient = không có",
    body: "FPGA không xuất gradient. Chỉ có hướng ghi, địa chỉ, trước, Δ, sau. Ước lượng host phải dán TWIN / không phải BOARD.",
  };
}

export function topicForTab(tab: string): ExplainTopic {
  if (tab === "compare" || tab === "learning") return "margin";
  if (tab === "metrics") return "auc";
  if (tab === "board") return "wns";
  if (tab === "forward") return "rank";
  if (tab === "evidence") return "gradient";
  return "sat";
}
