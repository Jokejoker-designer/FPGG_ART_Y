import { useStudio } from "@/lib/store";
import { Btn, Field, Panel, PanelTitle, inputClass } from "../ui";

/**
 * Workspace only. No LiteScope groups, no fake BOARD link.
 *
 * Owner: gb-ux-product.
 */
export function SettingsTab() {
  const { level, setLevel, projectName, setProjectName, setTab, connection, activeInteractionId } =
    useStudio();
  return (
    <div className="mx-auto max-w-3xl space-y-3">
      <Panel>
        <PanelTitle>Hồ sơ dự án</PanelTitle>
        <Field label="Tên">
          <input value={projectName} onChange={(e) => setProjectName(e.target.value)} className={inputClass} />
        </Field>
        <p className="mt-2 text-[13px] text-muted">
          Tên chỉ sống trên máy này. Không đổi bitstream hay luật học.
        </p>
      </Panel>
      <Panel>
        <PanelTitle>Hiển thị</PanelTitle>
        <div className="flex flex-wrap gap-2">
          {(["easy", "research", "rtl"] as const).map((lv) => (
            <Btn key={lv} variant={level === lv ? "primary" : "ghost"} onClick={() => setLevel(lv)}>
              {lv === "easy" ? "Người mới" : lv === "research" ? "Chuyên gia" : "RTL"}
            </Btn>
          ))}
        </div>
        <p className="mt-2 text-xs text-muted">Đổi cách trình bày, không đổi nguồn dữ liệu.</p>
      </Panel>
      <Panel>
        <PanelTitle>Nguồn dữ liệu</PanelTitle>
        <dl className="space-y-1 text-[13px]">
          <div className="flex justify-between gap-3">
            <dt className="text-muted">Nguồn đang mở</dt>
            <dd className="font-mono">{connection.activeSource}</dd>
          </div>
          <div className="flex justify-between gap-3">
            <dt className="text-muted">FPGA</dt>
            <dd>{connection.connected ? "đang trả lời" : "chưa kết nối"}</dd>
          </div>
          <div className="flex justify-between gap-3">
            <dt className="text-muted">Tương tác</dt>
            <dd className="font-mono">#{activeInteractionId}</dd>
          </div>
        </dl>
        <p className="mt-2 text-[13px] text-warn">
          SYNTHETIC không được tô như BOARD. Studio không mở cổng serial.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <Btn onClick={() => setTab("evidence")}>Mở bằng chứng</Btn>
          <Btn onClick={() => setTab("experiments")}>Mở session đã lưu</Btn>
        </div>
      </Panel>
    </div>
  );
}
