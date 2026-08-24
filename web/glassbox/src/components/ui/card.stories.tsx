import type { Meta, StoryObj } from "@storybook/react-vite";
import { Card, CardHeader, CardNote, CardTitle } from "./card";
import { Pill } from "./pill";
import { Metric } from "./metric";

/**
 * Density is the state worth covering here: §7.6 promises a research density
 * that exposes more telemetry, and the card is where that padding lives. Use
 * the Density toolbar to switch.
 *
 * Owner: gb-storybook-component-qa.
 */
const AT = "2026-08-20T10:32:15.481+07:00";

const meta = {
  title: "Nền tảng/Thẻ",
  component: Card,
} satisfies Meta<typeof Card>;

export default meta;
type Story = StoryObj<typeof meta>;

export const CoTieuDeVaNhan: Story = {
  args: {
    children: (
      <>
        <CardHeader>
          <CardTitle>Board hiện tại dùng chip gì?</CardTitle>
          <Pill tone="learn">ĐÃ HỌC</Pill>
        </CardHeader>
        <p className="text-sm text-ink">Arty A7 sử dụng FPGA Artix-7.</p>
      </>
    ),
  },
};

export const CoChiSo: Story = {
  args: {
    children: (
      <>
        <CardTitle>Kết quả so sánh</CardTitle>
        <div className="mt-3 grid grid-cols-3 gap-4">
          <Metric
            label="Khoảng cách tới ví dụ đúng"
            metric={{
              value: 1_320,
              provenance: { source: "SYNTHETIC", capturedAt: AT },
            }}
          />
          <Metric
            label="Khoảng cách tới ví dụ sai"
            metric={{
              value: 4_810,
              provenance: { source: "SYNTHETIC", capturedAt: AT },
            }}
          />
          <Metric
            label="Biên phân biệt"
            metric={{
              value: 3_490,
              provenance: {
                source: "DERIVED",
                derivedFrom: ["d_pos", "d_neg"],
                capturedAt: AT,
              },
            }}
          />
        </div>
      </>
    ),
  },
};

/** §26. An empty card still explains itself and offers a way forward. */
export const TrangThaiRong: Story = {
  args: {
    children: (
      <>
        <CardTitle>Không có waveform cho tương tác này</CardTitle>
        <CardNote>Capture không được bật khi sự kiện xảy ra.</CardNote>
      </>
    ),
  },
};

/** Long real-world Vietnamese text rather than a truncated sample. */
export const NoiDungDai: Story = {
  args: {
    children: (
      <>
        <CardTitle>Cảnh báo về chất lượng biểu diễn</CardTitle>
        <CardNote>
          AI vẫn đang thay đổi trọng số nhưng các trạng thái bên trong đang trở
          nên gần giống nhau. Khả năng phân biệt dữ liệu đang mất dần, nên các
          chỉ số phía sau có thể trông tốt hơn thực tế.
        </CardNote>
      </>
    ),
  },
};
