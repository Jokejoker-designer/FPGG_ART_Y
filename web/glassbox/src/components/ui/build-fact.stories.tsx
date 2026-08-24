import type { Meta, StoryObj } from "@storybook/react-vite";
import { BuildFact, formatCount } from "./build-fact";
import { Metric } from "./metric";

/**
 * The comparison story is the reason this component exists: a build fact must
 * be visibly a different kind of thing from a measurement, so nobody reads a
 * parameter count as something that was observed on silicon.
 *
 * Owner: gb-storybook-component-qa.
 */
const meta = {
  title: "Nền tảng/Thông tin bản build",
  component: BuildFact,
} satisfies Meta<typeof BuildFact>;

export default meta;
type Story = StoryObj<typeof meta>;

export const ThamSoMoHinh: Story = {
  args: {
    label: "Tham số mô hình ngôn ngữ",
    value: formatCount(802_816),
    title: "Không cộng với tham số bộ mã hóa.",
  },
};

export const ThamSoBoMaHoa: Story = {
  args: {
    label: "Tham số bộ mã hóa",
    value: formatCount(9_216),
    title: "E 256×32 cộng Wh 32×32 theo luật hiện hành.",
  },
};

export const LuatHoc: Story = {
  args: { label: "Luật học", value: "eam03e-a0-signsgd-v1" },
};

export const KhongCoGiaTri: Story = {
  args: { label: "Ký ức được dùng", value: "không tìm thấy" },
};

/** Side by side with a measurement, which is how the distinction is judged. */
export const SoSanhVoiChiSo: Story = {
  args: { label: "Tham số mô hình ngôn ngữ", value: formatCount(802_816) },
  render: () => (
    <div className="flex gap-8">
      <BuildFact
        label="Tham số mô hình ngôn ngữ"
        value={formatCount(802_816)}
      />
      <Metric
        label="Giá trị đã thay đổi"
        metric={{
          value: 286,
          provenance: {
            source: "SYNTHETIC",
            capturedAt: "2026-08-20T10:32:15.481+07:00",
          },
        }}
      />
    </div>
  ),
};
