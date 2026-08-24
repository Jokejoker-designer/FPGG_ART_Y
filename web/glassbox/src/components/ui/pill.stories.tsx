import type { Meta, StoryObj } from "@storybook/react-vite";
import { Pill, type PillTone } from "./pill";

/**
 * §28. The greyscale story is the real check: if two tones become
 * indistinguishable without colour, the glyph mapping is wrong.
 *
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Nền tảng/Nhãn trạng thái",
  component: Pill,
} satisfies Meta<typeof Pill>;

export default meta;
type Story = StoryObj<typeof meta>;

const TONES: Array<{ tone: PillTone; label: string }> = [
  { tone: "pass", label: "TRACE ĐẦY ĐỦ" },
  { tone: "attention", label: "TRACE CHƯA ĐẦY ĐỦ" },
  { tone: "fail", label: "BUILD KHÔNG ĐẠT TIMING" },
  { tone: "learn", label: "ĐANG HỌC" },
  { tone: "memory", label: "TÌM THẤY KÝ ỨC" },
  { tone: "primary", label: "ĐANG ĐO" },
  { tone: "neutral", label: "ĐÃ ĐÓNG BĂNG" },
];

export const Pass: Story = { args: { tone: "pass", children: "TRACE ĐẦY ĐỦ" } };

export const CanhBao: Story = {
  args: { tone: "attention", children: "TRACE CHƯA ĐẦY ĐỦ" },
};

export const Loi: Story = {
  args: { tone: "fail", children: "BUILD KHÔNG ĐẠT TIMING" },
};

export const MoiTone: Story = {
  args: { tone: "pass", children: "TRACE ĐẦY ĐỦ" },
  render: () => (
    <div className="flex flex-wrap gap-2">
      {TONES.map(({ tone, label }) => (
        <Pill key={tone} tone={tone}>
          {label}
        </Pill>
      ))}
    </div>
  ),
};

export const KhongMau: Story = {
  args: { tone: "pass", children: "TRACE ĐẦY ĐỦ" },
  render: () => (
    <div className="flex flex-wrap gap-2" style={{ filter: "grayscale(1)" }}>
      {TONES.map(({ tone, label }) => (
        <Pill key={tone} tone={tone}>
          {label}
        </Pill>
      ))}
    </div>
  ),
};

/** Real copy is sometimes long; the pill must not clip it. */
export const NhanDai: Story = {
  args: {
    tone: "attention",
    children: "KHÔNG CẦN HỌC THÊM CHO TƯƠNG TÁC NÀY",
  },
};
