import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { cn } from "@/lib/utils";
import type { WaveformCapture } from "@/lib/contract";
import { FLOW_LABEL, FLOW_NODES, hidden, memCells, type TabId } from "@/lib/data";
import { useStudio } from "@/lib/store";

export function ClientChart({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  const [on, setOn] = useState(false);
  useEffect(() => setOn(true), []);
  if (!on) return <div className={cn("h-44 animate-pulse rounded-lg bg-surface", className)} />;
  return <>{children}</>;
}

export function HeatRow({
  label,
  values,
  max = 1.2,
}: {
  label: string;
  values: number[];
  max?: number;
}) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-16 shrink-0 text-caption text-muted">{label}</span>
      <div className="grid flex-1 gap-px" style={{ gridTemplateColumns: "repeat(32, minmax(0,1fr))" }}>
        {values.map((v, i) => {
          const t = Math.min(1, Math.abs(v) / max);
          const bg =
            v >= 0 ? `rgba(34,211,238,${0.12 + t * 0.85})` : `rgba(248,113,113,${0.12 + t * 0.85})`;
          return (
            <div key={i} title={`h${i} = ${v.toFixed(3)}`} className="h-5 rounded-sm" style={{ background: bg }} />
          );
        })}
      </div>
    </div>
  );
}

export function WeightHeat({ data }: { data: number[][] }) {
  return (
    <div className="overflow-hidden rounded-lg border border-line">
      <div className="grid" style={{ gridTemplateColumns: "repeat(32, minmax(0,1fr))" }}>
        {data.flatMap((row, r) =>
          row.map((v, c) => {
            const t = Math.min(1, Math.abs(v) / 0.55);
            const bg =
              v === 0
                ? "transparent"
                : v > 0
                  ? `rgba(167,139,250,${0.2 + t * 0.8})`
                  : `rgba(45,212,191,${0.2 + t * 0.8})`;
            return (
              <div
                key={`${r}-${c}`}
                title={`Wh[${r},${c}] Δ ${v}`}
                className="aspect-square"
                style={{ background: bg }}
              />
            );
          }),
        )}
      </div>
    </div>
  );
}

export function Scatter2d() {
  const pts = useMemo(() => {
    const pack = (arr: number[], color: string, name: string) => {
      const x = arr.slice(0, 16).reduce((a, b) => a + b, 0);
      const y = arr.slice(16).reduce((a, b) => a + b, 0);
      return { x, y, color, name };
    };
    return [
      pack(hidden.anchor, "#22d3ee", "Anchor"),
      pack(hidden.positive, "#34d399", "Positive"),
      pack(hidden.negative, "#f87171", "Negative"),
    ];
  }, []);
  const xs = pts.map((p) => p.x);
  const ys = pts.map((p) => p.y);
  const minX = Math.min(...xs) - 1;
  const maxX = Math.max(...xs) + 1;
  const minY = Math.min(...ys) - 1;
  const maxY = Math.max(...ys) + 1;
  const sx = (x: number) => ((x - minX) / (maxX - minX)) * 100;
  const sy = (y: number) => 100 - ((y - minY) / (maxY - minY)) * 100;
  return (
    <div className="relative h-48 rounded-lg border border-line bg-surface">
      <svg viewBox="0 0 100 100" className="h-full w-full">
        <line x1="8" y1="92" x2="94" y2="92" stroke="#2a3441" strokeWidth="0.4" />
        <line x1="8" y1="8" x2="8" y2="92" stroke="#2a3441" strokeWidth="0.4" />
        {pts.map((p) => (
          <g key={p.name}>
            <circle cx={sx(p.x)} cy={sy(p.y)} r="3.2" fill={p.color} />
            <text x={sx(p.x) + 4} y={sy(p.y) - 3} fill={p.color} fontSize="4.2" fontFamily="IBM Plex Sans">
              {p.name}
            </text>
          </g>
        ))}
      </svg>
      <span className="absolute right-2 top-2 rounded-full border border-line bg-card px-2 py-0.5 text-micro uppercase tracking-wide text-warn">
        Minh họa 2D
      </span>
    </div>
  );
}

export function DistBars({ pos, neg }: { pos: number; neg: number }) {
  const max = Math.max(pos, neg, 1);
  return (
    <div className="space-y-3">
      <BarRow label="Đúng" value={pos} max={max} tone="bg-ok" />
      <BarRow label="Sai" value={neg} max={max} tone="bg-bad" />
    </div>
  );
}

function BarRow({
  label,
  value,
  max,
  tone,
}: {
  label: string;
  value: number;
  max: number;
  tone: string;
}) {
  return (
    <div>
      <div className="mb-1 flex justify-between text-xs text-muted">
        <span>{label}</span>
        <span className="font-mono tabular text-fg">{value}</span>
      </div>
      <div className="h-2.5 overflow-hidden rounded-full bg-raised">
        <div className={cn("h-full rounded-full", tone)} style={{ width: `${(value / max) * 100}%` }} />
      </div>
    </div>
  );
}

export function MarginGauge({ value }: { value: number }) {
  const pct = Math.max(0, Math.min(100, ((value + 4000) / 8000) * 100));
  return (
    <div>
      <div className="mb-2 flex justify-between text-caption text-subtle">
        <span>Cần học</span>
        <span>Ngưỡng</span>
        <span>Đã phân biệt tốt</span>
      </div>
      <div className="relative h-3 rounded-full bg-gradient-to-r from-bad via-warn to-ok">
        <div
          className="absolute top-1/2 h-5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-fg"
          style={{ left: `${pct}%` }}
        />
      </div>
      <div className="mt-2 text-center font-mono text-xl tabular text-ok">+{value}</div>
    </div>
  );
}

export function Funnel({ steps }: { steps: { label: string; n: number }[] }) {
  const max = steps[0]?.n ?? 1;
  return (
    <div className="space-y-2">
      {steps.map((s) => (
        <div key={s.label} className="flex items-center gap-3">
          <div
            className="h-8 rounded-md bg-mem/25 text-center text-caption leading-8 text-mem"
            style={{ width: `${Math.max(18, (Math.log10(s.n + 1) / Math.log10(max + 1)) * 100)}%` }}
          >
            {s.n.toLocaleString("vi-VN")}
          </div>
          <span className="text-xs text-muted">{s.label}</span>
        </div>
      ))}
    </div>
  );
}

export function DensityMap() {
  const cells = useMemo(
    () => Array.from({ length: 96 }, (_, i) => ((Math.sin(i * 1.7) + 1) / 2) * (i % 7 === 0 ? 1 : 0.55)),
    [],
  );
  return (
    <div className="grid grid-cols-12 gap-0.5">
      {cells.map((v, i) => (
        <div key={i} className="h-3 rounded-sm" style={{ background: `rgba(45,212,191,${0.08 + v * 0.7})` }} />
      ))}
    </div>
  );
}

export function MemoryGrid() {
  return (
    <div>
      <div className="grid grid-cols-16 gap-0.5" style={{ gridTemplateColumns: "repeat(16, minmax(0,1fr))" }}>
        {memCells.map((s, i) => (
          <div
            key={i}
            title={s}
            className={cn(
              "aspect-square rounded-sm",
              s === "hit" && "bg-ok",
              s === "miss" && "bg-bad/80",
              s === "occ" && "bg-mem/55",
              s === "free" && "bg-raised",
            )}
          />
        ))}
      </div>
      <div className="mt-2 flex flex-wrap gap-3 text-caption text-muted">
        <span className="flex items-center gap-1">
          <i className="size-2 rounded-sm bg-ok" /> HIT
        </span>
        <span className="flex items-center gap-1">
          <i className="size-2 rounded-sm bg-bad/80" /> MISS
        </span>
        <span className="flex items-center gap-1">
          <i className="size-2 rounded-sm bg-mem/55" /> Occupied
        </span>
        <span className="flex items-center gap-1">
          <i className="size-2 rounded-sm bg-raised" /> Free
        </span>
      </div>
    </div>
  );
}

export function NodeFlow() {
  const { setTab, stageStates, replaying, level } = useStudio();
  const map: Record<string, "input" | "encode" | "memory" | "learn" | "output"> = {
    input: "input",
    encoder: "encode",
    memory: "memory",
    learning: "learn",
    output: "output",
  };
  return (
    <div className="flex flex-wrap items-center gap-2">
      {FLOW_NODES.map((n, i) => {
        const st = stageStates[map[n.id] ?? "input"];
        const active = replaying && st === "active";
        const label = FLOW_LABEL[level][n.id] ?? n.label;
        return (
          <div key={n.id} className="flex items-center gap-2">
            {i > 0 ? <span className="h-px w-6 bg-line" /> : null}
            <button
              type="button"
              onClick={() => setTab(n.tab)}
              className={cn(
                "min-w-24 rounded-xl border bg-surface px-3 py-2 text-left transition-colors duration-150",
                active ? "gbx-active border-cyan" : "border-line hover:border-cyan/40",
              )}
            >
              <div className="font-mono text-caption text-cyan">{label}</div>
              <div className="font-mono text-caption tabular text-muted">
                {level === "rtl" ? `${Math.round(n.ms * 100)} cyc` : `${n.ms} ms`}
              </div>
            </button>
          </div>
        );
      })}
    </div>
  );
}

const tipStyle = {
  background: "#141c26",
  border: "1px solid #243040",
  fontSize: 12,
  color: "#e8eef4",
  borderRadius: 8,
};

export function LossChart({ data }: { data: { step: number; loss: number }[] }) {
  return (
    <ClientChart>
      <div className="h-44">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#243040" strokeDasharray="3 3" />
            <XAxis dataKey="step" stroke="#6d7b8a" fontSize={11} />
            <YAxis stroke="#6d7b8a" fontSize={11} />
            <Tooltip contentStyle={tipStyle} />
            <Line type="monotone" dataKey="loss" stroke="#22d3ee" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function TpsChart({ data }: { data: { step: number; tps: number }[] }) {
  return (
    <ClientChart>
      <div className="h-44">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <defs>
              <linearGradient id="tpsFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#22d3ee" stopOpacity={0.35} />
                <stop offset="100%" stopColor="#22d3ee" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke="#243040" strokeDasharray="3 3" />
            <XAxis dataKey="step" stroke="#6d7b8a" fontSize={11} />
            <YAxis stroke="#6d7b8a" fontSize={11} domain={[0, "auto"]} />
            <Tooltip contentStyle={tipStyle} />
            <Area type="monotone" dataKey="tps" stroke="#22d3ee" fill="url(#tpsFill)" strokeWidth={2} />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function ResourceBars({
  data,
}: {
  data: { name: string; pct: number; used: number; total: number }[];
}) {
  return (
    <ClientChart>
      <div className="h-44">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#243040" vertical={false} />
            <XAxis dataKey="name" stroke="#6d7b8a" fontSize={11} />
            <YAxis stroke="#6d7b8a" fontSize={11} domain={[0, 100]} />
            <Tooltip contentStyle={tipStyle} />
            <Bar dataKey="pct" fill="#22d3ee" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function HealthChart({
  data,
}: {
  data: { updates: number; auc: number; sat: number; rank: number }[];
}) {
  return (
    <ClientChart className="h-56">
      <div className="h-56">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#243040" strokeDasharray="3 3" />
            <XAxis dataKey="updates" stroke="#6d7b8a" fontSize={11} />
            <YAxis yAxisId="left" stroke="#6d7b8a" fontSize={11} domain={[0.45, 0.9]} />
            <YAxis yAxisId="right" orientation="right" stroke="#6d7b8a" fontSize={11} />
            <Tooltip contentStyle={tipStyle} />
            <Legend wrapperStyle={{ fontSize: 11, color: "#9aa8b8" }} />
            <Line yAxisId="left" type="monotone" dataKey="auc" stroke="#22d3ee" strokeWidth={2} dot={false} name="AUC" />
            <Line yAxisId="right" type="monotone" dataKey="sat" stroke="#fbbf24" strokeWidth={2} dot={false} name="Sat %" />
            <Line yAxisId="right" type="monotone" dataKey="rank" stroke="#34d399" strokeWidth={2} dot={false} name="Rank" />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function HistChart({ data }: { data: { bin: string; n: number }[] }) {
  return (
    <ClientChart>
      <div className="h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#243040" vertical={false} />
            <XAxis dataKey="bin" stroke="#6d7b8a" fontSize={11} />
            <YAxis stroke="#6d7b8a" fontSize={11} />
            <Tooltip contentStyle={tipStyle} />
            <Bar dataKey="n" fill="#a78bfa" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function FreqChart({ data }: { data: { token: string; n: number }[] }) {
  return (
    <ClientChart>
      <div className="h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} layout="vertical" margin={{ top: 4, right: 8, left: 24, bottom: 0 }}>
            <CartesianGrid stroke="#243040" horizontal={false} />
            <XAxis type="number" stroke="#6d7b8a" fontSize={11} />
            <YAxis type="category" dataKey="token" stroke="#6d7b8a" fontSize={11} width={48} />
            <Tooltip contentStyle={tipStyle} />
            <Bar dataKey="n" fill="#22d3ee" radius={[0, 4, 4, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function GateBars({ data }: { data: { name: string; pass: number; fail: number }[] }) {
  return (
    <ClientChart>
      <div className="h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#243040" vertical={false} />
            <XAxis dataKey="name" stroke="#6d7b8a" fontSize={11} />
            <YAxis stroke="#6d7b8a" fontSize={11} />
            <Tooltip contentStyle={tipStyle} />
            <Bar dataKey="pass" stackId="a" fill="#34d399" radius={[0, 0, 0, 0]} />
            <Bar dataKey="fail" stackId="a" fill="#f87171" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ClientChart>
  );
}

export function valueAtCycle(capture: WaveformCapture, signalId: string, cycle: number): number | null {
  const trace = capture.traces.find((t) => t.signalId === signalId);
  if (!trace || trace.transitions.length === 0) return null;
  let value = trace.transitions[0]!.value;
  for (const t of trace.transitions) {
    if (t.cycle > cycle) break;
    value = t.value;
  }
  return value;
}

export function WaveformView({
  capture,
  visibleSignalIds,
  selectedSignalId,
  cursorCycle,
  onCursor,
  level,
}: {
  capture: WaveformCapture;
  visibleSignalIds: string[];
  selectedSignalId: string;
  cursorCycle: number;
  onCursor: (cycle: number) => void;
  level: "easy" | "research" | "rtl";
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const lanes = useMemo(
    () => capture.signals.filter((s) => visibleSignalIds.includes(s.id)),
    [capture.signals, visibleSignalIds],
  );
  const end = Math.max(1, capture.cycles.endCycle);

  useEffect(() => {
    const c = canvasRef.current;
    if (!c) return;
    const parent = c.parentElement;
    if (!parent) return;
    const w = parent.clientWidth;
    const h = Math.max(220, lanes.length * 28 + 28);
    c.width = w * devicePixelRatio;
    c.height = h * devicePixelRatio;
    c.style.width = `${w}px`;
    c.style.height = `${h}px`;
    const ctx = c.getContext("2d");
    if (!ctx) return;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.scale(devicePixelRatio, devicePixelRatio);
    ctx.fillStyle = "#0e141c";
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = "#243040";
    ctx.lineWidth = 1;
    for (let x = 88; x < w; x += 64) {
      ctx.beginPath();
      ctx.moveTo(x, 8);
      ctx.lineTo(x, h);
      ctx.stroke();
    }
    lanes.forEach((signal, idx) => {
      const y = 20 + idx * 28;
      const trace = capture.traces.find((t) => t.signalId === signal.id);
      ctx.fillStyle = signal.id === selectedSignalId ? "#22d3ee" : "#9aa8b8";
      ctx.font = "11px IBM Plex Mono";
      const name = level === "rtl" ? (signal.rtlName ?? signal.id) : signal.id;
      ctx.fillText(name, 6, y + 4);
      ctx.strokeStyle =
        signal.group === "LEARNING"
          ? "#a78bfa"
          : signal.group === "DDR_MEMORY"
            ? "#2dd4bf"
            : signal.group === "OUTPUT"
              ? "#34d399"
              : "#22d3ee";
      ctx.lineWidth = 1.4;
      ctx.beginPath();
      const transitions = trace?.transitions ?? [];
      const yHigh = y - 8;
      const yLow = y + 8;
      const xOf = (cycle: number) => 88 + (cycle / end) * (w - 108);
      if (transitions.length === 0) {
        ctx.moveTo(88, yLow);
        ctx.lineTo(w - 8, yLow);
      } else {
        transitions.forEach((t, i) => {
          const x0 = xOf(t.cycle);
          const x1 = xOf(transitions[i + 1]?.cycle ?? end);
          const high = t.value !== 0;
          const yv = signal.kind === "BIT" ? (high ? yHigh : yLow) : yHigh - (t.value % 12);
          if (i === 0) ctx.moveTo(x0, yv);
          else ctx.lineTo(x0, yv);
          ctx.lineTo(x1, yv);
        });
      }
      ctx.stroke();
    });
    const cx = 88 + (cursorCycle / end) * (w - 108);
    ctx.strokeStyle = "#fbbf24";
    ctx.setLineDash([3, 3]);
    ctx.beginPath();
    ctx.moveTo(cx, 8);
    ctx.lineTo(cx, h);
    ctx.stroke();
    ctx.setLineDash([]);
  }, [lanes, capture.traces, cursorCycle, selectedSignalId, level, end]);

  return (
    <div
      className="overflow-hidden rounded-lg border border-line bg-surface"
      role="slider"
      aria-label="Con trỏ sóng số từ bản ghi SYNTHETIC. Mũi tên trái phải để dịch cycle."
      aria-valuemin={0}
      aria-valuemax={end}
      aria-valuenow={cursorCycle}
      tabIndex={0}
      data-testid="waveform-cursor"
      onKeyDown={(e) => {
        if (e.key === "ArrowLeft") {
          e.preventDefault();
          onCursor(Math.max(0, cursorCycle - 1));
        }
        if (e.key === "ArrowRight") {
          e.preventDefault();
          onCursor(Math.min(end, cursorCycle + 1));
        }
        if (e.key === "Home") {
          e.preventDefault();
          onCursor(0);
        }
        if (e.key === "End") {
          e.preventDefault();
          onCursor(end);
        }
      }}
      onClick={(e) => {
        const r = e.currentTarget.getBoundingClientRect();
        const x = e.clientX - r.left - 88;
        const cycle = Math.max(0, Math.min(end, Math.round((x / (r.width - 108)) * end)));
        onCursor(cycle);
      }}
    >
      <canvas ref={canvasRef} className="block w-full" />
    </div>
  );
}

export function Waterfall({
  rows,
}: {
  rows: { label: string; ms: number; tab?: TabId }[];
}) {
  const max = Math.max(...rows.map((r) => r.ms), 1);
  const { setTab } = useStudio();
  return (
    <div className="space-y-1.5">
      {rows.map((r) => (
        <button
          key={r.label}
          type="button"
          onClick={() => r.tab && setTab(r.tab)}
          className="flex w-full items-center gap-3 text-left"
        >
          <span className="w-20 font-mono text-caption text-muted">{r.label}</span>
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-raised">
            <div className="h-full rounded-full bg-cyan" style={{ width: `${(r.ms / max) * 100}%` }} />
          </div>
          <span className="w-14 text-right font-mono text-caption tabular text-fg">{r.ms} ms</span>
        </button>
      ))}
    </div>
  );
}
