import type { Meta, StoryObj } from "@storybook/react-vite";
import type { StageTiming } from "@/lib/contract";
import { ProcessPipeline } from "./process-pipeline";

/**
 * `DangChay` is the story that matters: it is the only state in which anything
 * animates, so it is where reduced-motion behaviour can be checked. A recorded
 * interaction is all `complete` and correctly shows a still pipeline.
 *
 * Owner: gb-storybook-component-qa.
 */
const AT = "2026-08-20T10:32:15.481+07:00";
const ms = (value: number): StageTiming["durationMs"] => ({
  value,
  unit: "ms",
  provenance: { source: "SYNTHETIC", capturedAt: AT },
});

const COMPLETE: StageTiming[] = [
  { phase: "INPUT", state: "complete", durationMs: ms(0.8) },
  { phase: "ENCODE", state: "complete", durationMs: ms(4.3) },
  { phase: "COMPARE", state: "complete", durationMs: ms(1.4) },
  { phase: "LEARN", state: "complete", durationMs: ms(11.9) },
  { phase: "MEMORY", state: "complete", durationMs: ms(8.7) },
  { phase: "MODEL", state: "complete", durationMs: ms(61.2) },
  { phase: "OUTPUT", state: "complete", durationMs: ms(5.6) },
];

const meta = {
  title: "Đồ thị/Tiến trình",
  component: ProcessPipeline,
} satisfies Meta<typeof ProcessPipeline>;

export default meta;
type Story = StoryObj<typeof meta>;

export const DaHoanTat: Story = {
  args: { stages: COMPLETE },
};

/** The only animating state. Toggle reduced motion to verify it settles. */
export const DangChay: Story = {
  args: {
    stages: [
      { phase: "INPUT", state: "complete", durationMs: ms(0.8) },
      { phase: "ENCODE", state: "complete", durationMs: ms(4.3) },
      { phase: "COMPARE", state: "active", durationMs: null },
      { phase: "LEARN", state: "waiting", durationMs: null },
      { phase: "MEMORY", state: "waiting", durationMs: null },
      { phase: "MODEL", state: "waiting", durationMs: null },
      { phase: "OUTPUT", state: "waiting", durationMs: null },
    ],
  },
};

export const GiamChuyenDong: Story = {
  args: DangChay.args,
  globals: { a11y: { manual: false } },
  parameters: {
    /* Chromium honours this in the story frame, so the pulse must stop. */
    reducedMotion: "reduce",
  },
};

export const CoLoi: Story = {
  args: {
    stages: [
      { phase: "INPUT", state: "complete", durationMs: ms(0.7) },
      { phase: "ENCODE", state: "complete", durationMs: ms(4.1) },
      { phase: "COMPARE", state: "complete", durationMs: ms(1.3) },
      { phase: "LEARN", state: "waiting", durationMs: null },
      { phase: "MEMORY", state: "complete", durationMs: ms(8.4) },
      { phase: "MODEL", state: "error", durationMs: ms(26.7) },
      { phase: "OUTPUT", state: "waiting", durationMs: null },
    ],
  },
};

/** §26. No stages recorded at all. */
export const ChuaCoSoDo: Story = {
  args: { stages: [] },
};

/** With a tab available a stage becomes a link; without one it is text. */
export const CoDichDenDeMo: Story = {
  args: {
    stages: COMPLETE,
    targets: [
      { phase: "LEARN", href: "/hoc?i=1842", label: "tab Học" },
      { phase: "MEMORY", href: "/bo-nho?i=1842", label: "tab Bộ nhớ" },
    ],
  },
};

export const KhongMau: Story = {
  args: { stages: COMPLETE },
  decorators: [
    (Story) => (
      <div style={{ filter: "grayscale(1)" }}>
        <Story />
      </div>
    ),
  ],
};
