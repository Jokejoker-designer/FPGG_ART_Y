import type { Meta, StoryObj } from "@storybook/react-vite";
import { Metric } from "./metric";

/**
 * The state matrix that matters here is absence and extremes: a metric with no
 * measurement must say so rather than render zero, and a large integer must
 * not break the column alignment that §7.4 tabular numerals promise.
 *
 * Owner: gb-storybook-component-qa.
 */
const AT = "2026-08-20T10:32:15.481+07:00";

const meta = {
  title: "Nền tảng/Chỉ số",
  component: Metric,
} satisfies Meta<typeof Metric>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Synthetic: Story = {
  args: {
    label: "Số token",
    metric: {
      value: 7,
      provenance: { source: "SYNTHETIC", capturedAt: AT },
    },
  },
};

export const Derived: Story = {
  args: {
    label: "Thời gian xử lý",
    metric: {
      value: 93.9,
      unit: "ms",
      provenance: {
        source: "DERIVED",
        derivedFrom: ["stages[].durationMs"],
        capturedAt: AT,
      },
    },
    fractionDigits: 1,
  },
};

/** §26. Absence is a state, not a zero. */
export const ChuaCoSoDo: Story = {
  args: {
    label: "Giá trị đã thay đổi",
    metric: null,
    emptyText: "không cập nhật",
  },
};

/** §15 scale. 800.000 must not overflow or lose its grouping. */
export const GiaTriRatLon: Story = {
  args: {
    label: "Tổng số ký ức",
    metric: {
      value: 800_000,
      provenance: { source: "SYNTHETIC", capturedAt: AT },
    },
  },
};

export const GiaTriAm: Story = {
  args: {
    label: "Biên phân biệt M_L1",
    metric: {
      value: -1_258,
      provenance: {
        source: "DERIVED",
        derivedFrom: ["d_pos", "d_neg"],
        capturedAt: AT,
      },
    },
  },
};

/** A long Vietnamese label, which is what real copy looks like. */
export const NhanDai: Story = {
  args: {
    label: "Số chiều hiệu dụng của trạng thái nội bộ",
    metric: {
      value: 19,
      unit: "/32",
      provenance: { source: "SYNTHETIC", capturedAt: AT },
    },
  },
};
