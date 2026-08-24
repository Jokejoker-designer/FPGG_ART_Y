import type { Meta, StoryObj } from "@storybook/react-vite";
import { OutputTab } from "./output";

/**
 * §17 token timeline, candidate bars, selection cycle.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Đầu ra",
  component: OutputTab,
} satisfies Meta<typeof OutputTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const TokenArtix: Story = {};
