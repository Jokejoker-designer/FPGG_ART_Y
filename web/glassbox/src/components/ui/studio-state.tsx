import type { ReactNode } from "react";
import { Card, CardNote, CardTitle } from "./card";
import { Btn } from "../ui";

/**
 * §26 loading / empty / error copy. Actions must have a real destination.
 * None of these arm LiteScope or invent live BOARD values.
 *
 * Owner: gb-ux-product.
 */
export type StudioStateKind =
  | "loading"
  | "disconnected"
  | "no-interaction"
  | "no-waveform"
  | "partial-trace"
  | "capture-overflow"
  | "timing-invalid"
  | "error";

const COPY: Record<StudioStateKind, { title: string; body: string }> = {
  loading: {
    title: "Đang tải studio…",
    body: "Chưa vẽ số đo. Không điền giá trị giả trong lúc chờ.",
  },
  disconnected: {
    title: "FPGA chưa kết nối",
    body: "Bạn vẫn có thể mở các session đã lưu hoặc chạy dữ liệu mô phỏng.",
  },
  "no-interaction": {
    title: "Chọn một tương tác để xem bên trong",
    body: "Mọi tab khóa vào một interaction_id. Chưa chọn thì không suy số từ tab khác.",
  },
  "no-waveform": {
    title: "Không có waveform cho tương tác này",
    body: "Capture không được bật khi sự kiện xảy ra.",
  },
  "partial-trace": {
    title: "Trace chưa đầy đủ",
    body: "Thiếu câu trong hợp đồng 8 câu. Không suy bằng chứng phần cứng để khép chuyện.",
  },
  "capture-overflow": {
    title: "Capture vượt dung lượng",
    body: "Một phần dữ liệu waveform đã bị mất.",
  },
  "timing-invalid": {
    title: "BUILD KHÔNG ĐẠT TIMING",
    body: "Không trình số đo như bằng chứng board đáng tin.",
  },
  error: {
    title: "Đã xảy ra lỗi",
    body: "Studio dừng thay vì đoán số. Tải lại hoặc mở session đã lưu.",
  },
};

export function StudioState({
  kind,
  primary,
  secondary,
  children,
}: {
  kind: StudioStateKind;
  primary?: { label: string; onClick: () => void };
  secondary?: { label: string; onClick: () => void };
  children?: ReactNode;
}) {
  const copy = COPY[kind];
  return (
    <div data-testid={`studio-state-${kind}`}>
    <Card className="border-warn/40">
      <CardTitle>{copy.title}</CardTitle>
      <div className="mt-1">
        <CardNote>{copy.body}</CardNote>
      </div>
      {children}
      {primary || secondary ? (
        <div className="mt-3 flex flex-wrap gap-2">
          {primary ? (
            <Btn variant="primary" onClick={primary.onClick}>
              {primary.label}
            </Btn>
          ) : null}
          {secondary ? (
            <Btn onClick={secondary.onClick}>{secondary.label}</Btn>
          ) : null}
        </div>
      ) : null}
    </Card>
    </div>
  );
}
