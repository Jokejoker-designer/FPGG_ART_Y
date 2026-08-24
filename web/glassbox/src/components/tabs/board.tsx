import { awaiting, buildFacts } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { Explain } from "../explain";
import { DieMap, DieUtilizationTable } from "../die-map";
import { StudioState } from "../ui/studio-state";
import { Kpi, Panel, PanelTitle, Pill } from "../ui";

/**
 * Board tab.
 *
 * Every figure here now comes from a real artefact in this repository or is
 * declared as awaiting silicon. The imported version showed a die temperature,
 * a core voltage, `UART COM3 · 3 Mbps`, an Ethernet address, `DDR Ready`, and a
 * log line reading "LiteScope groups 0–4 armed". None of those exist: the
 * bitstream has no XADC readout command, the board answers on COM12 at 115200,
 * this lane runs no Ethernet stack, and LiteScope before Native V1 freeze is a
 * hard stop in `a7-fpga-gate`.
 *
 * Timing and utilisation are read from the routed reports of the A0.1-T close.
 *
 * Owner: gb-ux-product.
 */
export function BoardTab() {
  const header = useStudioHeader();
  const { wnsNs, tnsNs, whsNs, thsNs, timingEndpoints, timingStatus } = buildFacts;
  const holdFinding = whsNs !== null && whsNs < 0;

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>
          {header.activeSource}
        </Pill>
        <span className="text-[13px] text-muted">{header.board}</span>
        <span className="font-mono text-caption text-subtle">
          {buildFacts.utilization?.part ?? header.part}
        </span>
      </div>
      {timingStatus === "VIOLATED" ? <StudioState kind="timing-invalid" /> : null}

      <Panel>
        <PanelTitle hint="Sơ đồ tài nguyên · số từ báo cáo route">
          Sơ đồ thiết bị
        </PanelTitle>
        <DieMap utilization={buildFacts.utilization} />
      </Panel>

      <div className="grid gap-3 lg:grid-cols-2">
        <Panel>
          <PanelTitle action={<Explain id="wns" />}>Timing</PanelTitle>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Kpi
              label="WNS"
              value={wnsNs === null ? "chưa đo" : `${wnsNs > 0 ? "+" : ""}${wnsNs} ns`}
              tone={wnsNs !== null && wnsNs >= 0 ? "text-ok" : "text-bad"}
            />
            <Kpi
              label="TNS"
              value={tnsNs === null ? "chưa đo" : tnsNs.toFixed(3)}
              tone={tnsNs === 0 ? "text-ok" : "text-bad"}
            />
            <Kpi
              label="WHS"
              value={whsNs === null ? "chưa đo" : `${whsNs > 0 ? "+" : ""}${whsNs} ns`}
              tone={holdFinding ? "text-bad" : "text-ok"}
            />
            <Kpi
              label="THS"
              value={thsNs === null ? "chưa đo" : thsNs.toFixed(3)}
              tone={thsNs === 0 ? "text-ok" : "text-bad"}
            />
          </div>
          <p className="mt-2 text-caption text-subtle">
            {timingStatus === "MET"
              ? "Mọi ràng buộc timing người dùng đặt đều đạt"
              : timingStatus === "VIOLATED"
                ? "Bản build không đạt timing, số đo từ bo không đáng tin"
                : "Chưa có báo cáo timing"}
            {timingEndpoints !== null ? ` · ${timingEndpoints} endpoint` : ""}
            {holdFinding ? " · hold âm là một finding" : ""}
          </p>
        </Panel>

        <Panel>
          <PanelTitle>Nhận dạng bản build</PanelTitle>
          <div className="grid grid-cols-2 gap-3">
            <Kpi
              label="Bitstream"
              value={header.bitstream ? header.build : "chưa có"}
              sub={header.bitstream?.slice(0, 16) ?? "chưa nạp bit nào"}
            />
            <Kpi label="Clock" value={header.clock} />
            <Kpi label="Luật học" value={buildFacts.learningLawId} />
            <Kpi
              label="Luật bộ nhớ"
              value={buildFacts.memoryLawId ?? "không có ở lane này"}
            />
          </div>
        </Panel>
      </div>

      <DieUtilizationTable utilization={buildFacts.utilization} />

      <Panel>
        <PanelTitle hint="Cần thêm tín hiệu từ RTL">Chưa đo được</PanelTitle>
        <p className="mb-2 text-caption leading-relaxed text-subtle">
          Những mục dưới đây thường có trên một bảng điều khiển phần cứng. Bo
          mạch trong lane này không phát ra chúng, nên chỗ của con số là yêu cầu
          cần đáp ứng, không phải một giá trị.
        </p>
        <ul className="space-y-2 text-[13px]">
          {(["tempC", "vccint", "ddrUsage", "uartLink", "ethLink"] as const).map(
            (key) => {
              const item = awaiting(key);
              return (
                <li key={key} className="border-t border-line pt-2">
                  <div className="flex flex-wrap items-baseline gap-2">
                    <span className="text-fg">{item.label}</span>
                    <Pill tone="warn">chờ tín hiệu</Pill>
                  </div>
                  <p className="mt-0.5 text-caption text-muted">
                    Cần: {item.needs}
                  </p>
                  <p className="text-caption text-subtle">{item.why}</p>
                </li>
              );
            },
          )}
        </ul>
      </Panel>
    </div>
  );
}
