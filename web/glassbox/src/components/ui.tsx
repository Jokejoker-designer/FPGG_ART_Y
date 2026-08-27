import type { ButtonHTMLAttributes, HTMLAttributes, ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Panel({
  className,
  children,
  ...rest
}: {
  className?: string;
  children: ReactNode;
} & HTMLAttributes<HTMLElement>) {
  return (
    <section
      className={cn(
        "rounded-2xl border border-line bg-card p-4 shadow-[var(--shadow-panel)]",
        className,
      )}
      {...rest}
    >
      {children}
    </section>
  );
}

export function PanelTitle({
  children,
  hint,
  action,
}: {
  children: ReactNode;
  hint?: string;
  action?: ReactNode;
}) {
  return (
    <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
      <h2 className="min-w-0 text-sm font-medium tracking-tight text-fg">{children}</h2>
      <div className="ml-auto flex shrink-0 items-center gap-2">
        {hint ? <span className="text-caption text-subtle">{hint}</span> : null}
        {action}
      </div>
    </div>
  );
}

export function Btn({
  variant = "ghost",
  className,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "ghost" | "soft" | "danger";
}) {
  return (
    <button
      type="button"
      className={cn(
        "inline-flex h-9 items-center justify-center gap-1.5 rounded-lg px-3 text-sm font-medium transition-[opacity,background-color,border-color,transform] duration-150 ease-[var(--ease-out)] disabled:opacity-40 active:scale-[0.98]",
        variant === "primary" && "bg-cyan text-bg hover:brightness-110",
        variant === "ghost" && "border border-line bg-raised text-fg hover:border-cyan/40",
        variant === "soft" && "bg-cyan/12 text-cyan hover:bg-cyan/20",
        variant === "danger" && "bg-bad/15 text-bad hover:bg-bad/25",
        className,
      )}
      {...props}
    />
  );
}

export function Pill({
  tone = "mute",
  children,
  className,
}: {
  tone?: "mute" | "ok" | "warn" | "bad" | "cyan" | "learn" | "mem" | "board";
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2 py-0.5 text-micro font-medium tracking-wide uppercase",
        tone === "mute" && "bg-raised text-muted",
        tone === "ok" && "bg-ok/15 text-ok",
        tone === "warn" && "bg-warn/15 text-warn",
        tone === "bad" && "bg-bad/15 text-bad",
        tone === "cyan" && "bg-cyan/15 text-cyan",
        tone === "learn" && "bg-learn/15 text-learn",
        tone === "mem" && "bg-mem/15 text-mem",
        tone === "board" && "bg-ok/12 text-ok",
        className,
      )}
    >
      {children}
    </span>
  );
}

export function Kpi({
  label,
  value,
  sub,
  tone,
}: {
  label: string;
  value: ReactNode;
  sub?: string;
  tone?: string;
}) {
  return (
    <div className="rounded-xl border border-line bg-surface px-3 py-2.5">
      <div className="text-caption text-subtle">{label}</div>
      <div className={cn("mt-1 font-mono text-lg tabular leading-none", tone)}>{value}</div>
      {sub ? <div className="mt-1 text-caption text-muted">{sub}</div> : null}
    </div>
  );
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="block space-y-1.5">
      <span className="text-xs text-muted">{label}</span>
      {children}
    </label>
  );
}

export function Toggle({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
      className={cn(
        "relative h-6 w-10 rounded-full transition-colors duration-150",
        checked ? "bg-cyan" : "bg-raised",
      )}
    >
      <span
        className={cn(
          "absolute top-0.5 left-0.5 block size-5 rounded-full bg-fg transition-transform duration-150",
          checked && "translate-x-4",
        )}
      />
    </button>
  );
}

export function Range({
  value,
  min,
  max,
  onChange,
}: {
  value: number;
  min: number;
  max: number;
  onChange: (n: number) => void;
}) {
  return (
    <input
      type="range"
      min={min}
      max={max}
      value={value}
      onChange={(e) => onChange(Number(e.target.value))}
      className="h-1.5 w-full cursor-pointer appearance-none rounded-full bg-raised accent-cyan"
    />
  );
}

export function Row({ k, v }: { k: string; v: ReactNode }) {
  return (
    <div className="flex justify-between gap-3 border-b border-line/60 py-1.5 text-[13px]">
      <dt className="text-subtle">{k}</dt>
      <dd className="font-mono text-fg">{v}</dd>
    </div>
  );
}

export const inputClass =
  "h-10 w-full rounded-lg border border-line bg-surface px-3 text-sm text-fg outline-none transition-colors duration-150 focus:border-cyan";
