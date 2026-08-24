import type { Preview } from "@storybook/react-vite";
import "../src/styles.css";

const preview: Preview = {
  parameters: {
    backgrounds: { default: "glassbox", values: [{ name: "glassbox", value: "#070b10" }] },
    a11y: { test: "error" },
  },
  decorators: [
    (Story) => (
      <div className="min-h-screen bg-bg p-4 text-fg" data-density="comfortable">
        <Story />
      </div>
    ),
  ],
};

export default preview;
