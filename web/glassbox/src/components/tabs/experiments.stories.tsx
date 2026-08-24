import type { Meta, StoryObj } from "@storybook/react-vite";
import { ExperimentsTab } from "./experiments";

/**
 * §20 two recorded interactions, no invented #500.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Replay",
  component: ExperimentsTab,
} satisfies Meta<typeof ExperimentsTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const HaiTuongTac: Story = {};
