/**
 * Card surface. Compound rather than boolean-prop driven, per
 * `vercel-composition-patterns` architecture-avoid-boolean-props.
 *
 * Owner: gb-design-system.
 */
import type { ReactNode } from "react";

export function Card({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <section
      className={`rounded-card border border-line bg-surface-1 ${className}`}
      style={{ padding: "var(--gb-space-card)" }}
    >
      {children}
    </section>
  );
}

export function CardHeader({ children }: { children: ReactNode }) {
  return (
    <header className="mb-3 flex items-baseline justify-between gap-3">
      {children}
    </header>
  );
}

export function CardTitle({
  children,
  id,
}: {
  children: ReactNode;
  id?: string;
}) {
  return (
    <h2 id={id} className="text-sm font-semibold tracking-wide text-ink">
      {children}
    </h2>
  );
}

/** Supporting line under a title. Never used for a value the user must read. */
export function CardNote({ children }: { children: ReactNode }) {
  return <p className="text-xs leading-relaxed text-ink-muted">{children}</p>;
}
