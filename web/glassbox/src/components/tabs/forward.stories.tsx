import type { Meta, StoryObj } from "@storybook/react-vite";
import { ForwardTab } from "./forward";

/**
 * §12 heatmap, vector facts, 2D illustration badge, before/after.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Biểu diễn",
  component: ForwardTab,
} satisfies Meta<typeof ForwardTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const TruocKhiHoc: Story = {};
