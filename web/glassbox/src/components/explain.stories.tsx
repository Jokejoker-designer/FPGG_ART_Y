import type { Meta, StoryObj } from "@storybook/react-vite";
import { Explain } from "../explain";

/**
 * §22 Giải thích with live numbers.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Feature/Giải thích",
  component: Explain,
  args: { id: "rank" },
} satisfies Meta<typeof Explain>;

export default meta;
type Story = StoryObj<typeof meta>;

export const RankDaSup: Story = { args: { id: "rank" } };
export const GradientKhongCo: Story = { args: { id: "gradient" } };
