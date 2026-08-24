import type { Meta, StoryObj } from "@storybook/react-vite";
import { InputTab } from "./input";

/**
 * §11 token/byte strip, detail drawer, embedding barcode.
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Tab/Dữ liệu vào",
  component: InputTab,
} satisfies Meta<typeof InputTab>;

export default meta;
type Story = StoryObj<typeof meta>;

export const DeHieu: Story = {};
export const Trong: Story = {
  render: () => (
    <div className="p-4">
      <InputTab />
    </div>
  ),
};
