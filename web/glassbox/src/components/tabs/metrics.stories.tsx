import type { Meta, StoryObj } from "@storybook/react-vite";
import { MetricsTab } from "./metrics";

/**
 * §19 collapse alert, health lines, beating baselines.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Sức khỏe",
  component: MetricsTab,
} satisfies Meta<typeof MetricsTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const DaSup: Story = {};
