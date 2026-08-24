/**
 * §8.1 "Long-horizon learning → line chart vs update count".
 *
 * The X axis is update count, never wall-clock time, so a paused session does
 * not stretch the curve. Two Y axes because the series have incompatible units:
 * AUC and saturation are ratios in [0,1], effective rank is a count out of 32.
 *
 * §19 and `a7-fpga-gate`: "A metric that improves because the thing it measures
 * collapsed is a FAIL." Rank and saturation are therefore drawn beside AUC
 * rather than on a separate screen, so a rising AUC next to a collapsing rank
 * is visible in one glance.
 *
 * Owner: gb-scientific-dataviz.
 */
import { useState } from "react";
import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { HealthSeries } from "@/lib/contract";

export function HealthLines({
  series,
  hiddenDim,
}: {
  series: HealthSeries;
  hiddenDim: number;
}) {
  const rows = series.points.map((point) => ({
    updateCount: point.updateCount,
    auc: point.auc?.value ?? null,
    ap: point.averagePrecision?.value ?? null,
    saturation: point.hiddenSaturation?.value ?? null,
    rank: point.effectiveRank?.value ?? null,
  }));

  const [tableOpen, setTableOpen] = useState(false);

  if (rows.length === 0) {
    return (
      <p className="text-sm text-muted">
        Chưa có chuỗi sức khỏe nào được ghi lại cho phiên này.
      </p>
    );
  }

  return (
    <figure className="space-y-2">
      <div style={{ width: "100%", height: 260 }}>
        <ResponsiveContainer>
          <LineChart data={rows} margin={{ top: 8, right: 8, left: -12, bottom: 0 }}>
            <CartesianGrid stroke="var(--color-line)" strokeDasharray="3 3" />
            <XAxis
              dataKey="updateCount"
              stroke="var(--color-subtle)"
              tick={{ fontSize: 11 }}
              label={{
                value: "số lần cập nhật",
                position: "insideBottom",
                offset: -2,
                fill: "var(--color-subtle)",
                fontSize: 11,
              }}
            />
            <YAxis
              yAxisId="ratio"
              domain={[0, 1]}
              stroke="var(--color-subtle)"
              tick={{ fontSize: 11 }}
            />
            <YAxis
              yAxisId="rank"
              orientation="right"
              domain={[0, hiddenDim]}
              stroke="var(--color-subtle)"
              tick={{ fontSize: 11 }}
            />
            <Tooltip
              contentStyle={{
                background: "var(--color-card)",
                border: "1px solid var(--color-line)",
                borderRadius: 8,
                fontSize: 12,
              }}
            />
            <Legend wrapperStyle={{ fontSize: 11 }} />
            <Line
              yAxisId="ratio"
              type="monotone"
              dataKey="auc"
              name="AUC"
              stroke="var(--color-cyan)"
              strokeWidth={2}
              dot={{ r: 2 }}
            />
            <Line
              yAxisId="ratio"
              type="monotone"
              dataKey="ap"
              name="AP"
              stroke="var(--color-model)"
              strokeWidth={1.5}
              strokeDasharray="4 2"
              dot={false}
            />
            <Line
              yAxisId="ratio"
              type="monotone"
              dataKey="saturation"
              name="Saturation"
              stroke="var(--color-bad)"
              strokeWidth={2}
              dot={{ r: 2 }}
            />
            <Line
              yAxisId="rank"
              type="monotone"
              dataKey="rank"
              name={`Effective rank /${hiddenDim}`}
              stroke="var(--color-learn)"
              strokeWidth={2}
              dot={{ r: 2 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <button
        type="button"
        className="rounded-md border border-line px-2 py-1 text-[12px] text-fg"
        onClick={() => setTableOpen((o) => !o)}
        data-testid="health-table-toggle"
      >
        {tableOpen ? "Ẩn bảng số" : "Hiện bảng số"}
      </button>
      {tableOpen ? (
        <table className="w-full text-left text-[12px]" data-testid="health-value-table">
          <caption className="mb-1 text-left text-caption text-subtle">
            Sức khỏe học theo số lần cập nhật
          </caption>
          <thead className="text-caption uppercase text-subtle">
            <tr>
              <th scope="col" className="py-1">Số lần cập nhật</th>
              <th scope="col">AUC</th>
              <th scope="col">AP</th>
              <th scope="col">Saturation</th>
              <th scope="col">Effective rank</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.updateCount} className="border-t border-line">
                <th scope="row" className="py-1 font-mono">
                  {row.updateCount}
                </th>
                <td className="font-mono">{row.auc ?? "chưa có"}</td>
                <td className="font-mono">{row.ap ?? "chưa có"}</td>
                <td className="font-mono">{row.saturation ?? "chưa có"}</td>
                <td className="font-mono">{row.rank ?? "chưa có"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}

      {/* §28: the values as a table, not only as geometry. */}
      <table className="gb-sr-only">
        <caption>Sức khỏe học theo số lần cập nhật</caption>
        <thead>
          <tr>
            <th scope="col">Số lần cập nhật</th>
            <th scope="col">AUC</th>
            <th scope="col">AP</th>
            <th scope="col">Saturation</th>
            <th scope="col">Effective rank</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.updateCount}>
              <th scope="row">{row.updateCount}</th>
              <td>{row.auc ?? "chưa có"}</td>
              <td>{row.ap ?? "chưa có"}</td>
              <td>{row.saturation ?? "chưa có"}</td>
              <td>{row.rank ?? "chưa có"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
