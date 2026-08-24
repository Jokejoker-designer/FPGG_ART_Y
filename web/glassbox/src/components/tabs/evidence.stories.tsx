import type { Meta, StoryObj } from "@storybook/react-vite";
import { EvidenceTab } from "./evidence";

/**
 * §21 evidence table from recorded metadata.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Bằng chứng",
  component: EvidenceTab,
} satisfies Meta<typeof EvidenceTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const DayDuTruyVet: Story = {};
