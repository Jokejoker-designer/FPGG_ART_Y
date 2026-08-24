import type { Meta, StoryObj } from "@storybook/react-vite";
import { EamTab } from "./eam";

/**
 * §15 retrieval funnel, selected episode, memory events. No fake occupancy.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Bộ nhớ",
  component: EamTab,
} satisfies Meta<typeof EamTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Phieu488271: Story = {};
