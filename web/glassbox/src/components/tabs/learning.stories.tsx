import type { Meta, StoryObj } from "@storybook/react-vite";
import { LearningTab } from "./learning";

/**
 * §14 write log, Wh Δ heatmap, histogram, clickable timeline. No gradient.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Học",
  component: LearningTab,
} satisfies Meta<typeof LearningTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Ghi286: Story = {};
