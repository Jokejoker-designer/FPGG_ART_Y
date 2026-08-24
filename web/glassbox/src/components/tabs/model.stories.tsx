import type { Meta, StoryObj } from "@storybook/react-vite";
import { ModelTab } from "./model";

/**
 * §16 recorded pipeline, layer waterfall, memory-context injection.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Mô hình",
  component: ModelTab,
} satisfies Meta<typeof ModelTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Layer1: Story = {};
