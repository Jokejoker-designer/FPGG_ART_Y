/**
 * A fixed property of the build, as opposed to something measured during a run.
 *
 * §25 puts a provenance badge on every *metric*. A parameter count or a law id
 * is not a metric: it does not come from BOARD, XSIM or TWIN, it is a property
 * of the artifact being observed. Rendering it through `Metric` would attach a
 * provenance it does not have and blur a distinction the product exists to
 * keep. So build facts get their own quieter treatment and no badge.
 *
 * Owner: gb-design-system.
 */
export function BuildFact({
  label,
  value,
  title,
}: {
  label: string;
  value: string;
  title?: string;
}) {
  return (
    <div className="flex flex-col gap-1" title={title}>
      <span className="text-xs text-ink-muted">{label}</span>
      <span
        className="gb-num text-ink"
        style={{ fontSize: "var(--gb-text-size-value)" }}
      >
        {value}
      </span>
    </div>
  );
}

export function formatCount(value: number): string {
  return value.toLocaleString("vi-VN");
}
