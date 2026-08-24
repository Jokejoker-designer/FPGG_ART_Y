import type { Meta, StoryObj } from "@storybook/react-vite";
import { EvidenceBadge } from "./evidence-badge";
import type { Provenance } from "@/lib/contract";

/**
 * §25 and §32.13. The point of this story is the comparison: BOARD is the only
 * filled treatment, so a reviewer can see at a glance that a TWIN or SYNTHETIC
 * reading cannot be mistaken for silicon evidence.
 *
 * Owner: gb-storybook-component-qa.
 */
const AT = "2026-08-20T10:32:15.481+07:00";

const meta = {
  title: "Nền tảng/Nhãn nguồn bằng chứng",
  component: EvidenceBadge,
} satisfies Meta<typeof EvidenceBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Board: Story = {
  args: { provenance: { source: "BOARD", capturedAt: AT } },
};

export const Xsim: Story = {
  args: { provenance: { source: "XSIM", capturedAt: AT } },
};

export const Twin: Story = {
  args: { provenance: { source: "TWIN", capturedAt: AT } },
};

export const Derived: Story = {
  args: {
    provenance: {
      source: "DERIVED",
      derivedFrom: ["d_pos", "d_neg"],
      capturedAt: AT,
    },
  },
};

export const Synthetic: Story = {
  args: { provenance: { source: "SYNTHETIC", capturedAt: AT } },
};

/** All five together, which is how the distinction is actually judged. */
export const EveryNguon: Story = {
  args: { provenance: { source: "BOARD", capturedAt: AT } },
  render: () => {
    const sources: Provenance[] = [
      { source: "BOARD", capturedAt: AT },
      { source: "XSIM", capturedAt: AT },
      { source: "TWIN", capturedAt: AT },
      { source: "DERIVED", derivedFrom: ["d_pos", "d_neg"], capturedAt: AT },
      { source: "SYNTHETIC", capturedAt: AT },
    ];
    return (
      <div className="flex flex-wrap items-center gap-3">
        {sources.map((provenance) => (
          <EvidenceBadge key={provenance.source} provenance={provenance} />
        ))}
      </div>
    );
  },
};

/**
 * §28. Rendered without colour to prove the glyph and the word carry the
 * distinction on their own.
 */
export const KhongMau: Story = {
  args: { provenance: { source: "BOARD", capturedAt: AT } },
  render: () => {
    const sources: Provenance[] = [
      { source: "BOARD", capturedAt: AT },
      { source: "XSIM", capturedAt: AT },
      { source: "TWIN", capturedAt: AT },
      { source: "DERIVED", derivedFrom: ["h[ANCHOR]"], capturedAt: AT },
      { source: "SYNTHETIC", capturedAt: AT },
    ];
    return (
      <div
        className="flex flex-wrap items-center gap-3"
        style={{ filter: "grayscale(1)" }}
      >
        {sources.map((provenance) => (
          <EvidenceBadge key={provenance.source} provenance={provenance} />
        ))}
      </div>
    );
  },
};
