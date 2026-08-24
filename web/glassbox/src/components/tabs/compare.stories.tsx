import type { Meta, StoryObj } from "@storybook/react-vite";
import { CompareTab } from "./compare";

/**
 * §13 A/P/N, distance bars, margin gauge, learn decision from violated.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/So sánh",
  component: CompareTab,
} satisfies Meta<typeof CompareTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const CanHocThem: Story = {};
