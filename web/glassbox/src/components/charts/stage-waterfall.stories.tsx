import type { Meta, StoryObj } from "@storybook/react-vite";
import { StageWaterfall, type WaterfallRow } from "./stage-waterfall";

/**
 * The extreme story is the point: one stage taking two thirds of the wall clock
 * is the real shape of this workload, and the chart has to stay readable when
 * the other bars are slivers.
 *
 * Owner: gb-storybook-component-qa.
 */
const AT = "2026-08-20T10:32:15.481+07:00";
const ms = (value: number) => ({
  value,
  unit: "ms",
  provenance: { source: "SYNTHETIC" as const, capturedAt: AT },
});

const ROWS: WaterfallRow[] = [
  { label: "Đọc", durationMs: ms(0.8), token: "primary" },
  { label: "Biểu diễn", durationMs: ms(4.3), token: "primary-strong" },
  { label: "So sánh", durationMs: ms(1.4), token: "attention" },
  { label: "Học", durationMs: ms(11.9), token: "learn" },
  { label: "Bộ nhớ", durationMs: ms(8.7), token: "memory" },
  { label: "Mô hình", durationMs: ms(61.2), token: "model" },
  { label: "Trả lời", durationMs: ms(5.6), token: "output" },
];

const meta = {
  title: "Đồ thị/Thác thời lượng",
  component: StageWaterfall,
} satisfies Meta<typeof StageWaterfall>;

export default meta;
type Story = StoryObj<typeof meta>;

export const BayChang: Story = {
  args: { rows: ROWS, title: "Thời gian từng chặng" },
};

/** §26. A stage that never ran states that, rather than drawing a zero bar. */
export const CoChangChuaChay: Story = {
  args: {
    title: "Thời gian từng chặng",
    rows: [
      { label: "Đọc", durationMs: ms(0.7), token: "primary" },
      { label: "Biểu diễn", durationMs: ms(4.1), token: "primary-strong" },
      { label: "So sánh", durationMs: ms(1.3), token: "attention" },
      { label: "Học", durationMs: null, token: "learn" },
      { label: "Bộ nhớ", durationMs: ms(8.4), token: "memory" },
      { label: "Mô hình", durationMs: ms(26.7), token: "model", failed: true },
      { label: "Trả lời", durationMs: null, token: "output" },
    ],
  },
};

export const HoanToanRong: Story = {
  args: { rows: [], title: "Thời gian từng chặng" },
};

/** One stage dominating, which is the real distribution for this workload. */
export const MotChangApDao: Story = {
  args: {
    title: "Thời gian từng chặng",
    rows: [
      { label: "Đọc", durationMs: ms(0.2), token: "primary" },
      { label: "Biểu diễn", durationMs: ms(0.4), token: "primary-strong" },
      { label: "So sánh", durationMs: ms(0.1), token: "attention" },
      { label: "Học", durationMs: ms(0.3), token: "learn" },
      { label: "Bộ nhớ", durationMs: ms(0.5), token: "memory" },
      { label: "Mô hình", durationMs: ms(984.2), token: "model" },
      { label: "Trả lời", durationMs: ms(0.6), token: "output" },
    ],
  },
};

/** §16 reuse: the same chart carries the model-layer breakdown. */
export const CacLopMoHinh: Story = {
  args: {
    title: "Thời gian từng lớp mô hình",
    rows: [
      { label: "Embedding", durationMs: ms(3.1), token: "primary" },
      { label: "Layer 1", durationMs: ms(14.2), token: "model" },
      { label: "Attention", durationMs: ms(9.4), token: "model" },
      { label: "Layer 2", durationMs: ms(15.8), token: "model" },
      { label: "Memory context", durationMs: ms(6.2), token: "memory" },
      { label: "LM head", durationMs: ms(12.5), token: "output" },
    ],
  },
};

export const KhongMau: Story = {
  args: { rows: ROWS, title: "Thời gian từng chặng" },
  decorators: [
    (Story) => (
      <div style={{ filter: "grayscale(1)" }}>
        <Story />
      </div>
    ),
  ],
};
