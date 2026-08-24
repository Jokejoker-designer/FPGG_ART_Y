import type { Meta, StoryObj } from "@storybook/react-vite";
import { SettingsTab } from "./settings";

/**
 * Workspace settings. No LiteScope / BOARD claim.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Cài đặt",
  component: SettingsTab,
} satisfies Meta<typeof SettingsTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Workspace: Story = {};
