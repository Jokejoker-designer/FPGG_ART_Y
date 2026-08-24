import type { Meta, StoryObj } from "@storybook/react-vite";
import { WaveformTab } from "./waveform";

/**
 * §18 digital waveform from WaveformSource fixture. No LiteScope.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Sóng FPGA",
  component: WaveformTab,
} satisfies Meta<typeof WaveformTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Capture1842: Story = {};
