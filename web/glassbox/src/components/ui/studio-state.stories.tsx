import type { Meta, StoryObj } from "@storybook/react-vite";
import { StudioState } from "./studio-state";

/**
 * §26 loading / empty / error surfaces.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "State/StudioState",
  component: StudioState,
} satisfies Meta<typeof StudioState>;

export default meta;
type Story = StoryObj<typeof meta>;

export const DangTai: Story = { args: { kind: "loading" } };
export const FpgaChuaKetNoi: Story = {
  args: {
    kind: "disconnected",
    primary: { label: "Mở session", onClick: () => undefined },
    secondary: { label: "Dùng Twin", onClick: () => undefined },
  },
};
export const ChuaChonTuongTac: Story = { args: { kind: "no-interaction" } };
export const KhongCoSong: Story = {
  args: {
    kind: "no-waveform",
    primary: { label: "Xem tương tác #1842", onClick: () => undefined },
    secondary: { label: "Bật capture cho lần sau", onClick: () => undefined },
  },
};
export const TraceThieu: Story = { args: { kind: "partial-trace" } };
export const CaptureTran: Story = { args: { kind: "capture-overflow" } };
export const TimingHong: Story = { args: { kind: "timing-invalid" } };
export const Loi: Story = { args: { kind: "error" } };
