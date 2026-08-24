/**
 * Provenance badge. §25 and §32.13.
 *
 * A non-BOARD source is rendered with a hairline border and a distinct glyph
 * and never with the solid treatment BOARD gets, so a TWIN or SYNTHETIC
 * reading cannot visually masquerade as silicon evidence.
 *
 * Owner: gb-design-system.
 */
import type { Provenance } from "@/lib/contract";
import { EVIDENCE_PRESENTATION, tokenVar } from "@/design/tokens";

export function EvidenceBadge({ provenance }: { provenance: Provenance }) {
  const presentation = EVIDENCE_PRESENTATION[provenance.source];
  const color = tokenVar(presentation.token);
  const derivedFrom = provenance.derivedFrom?.join(", ");
  const title = derivedFrom
    ? `${presentation.explanation} Nguồn: ${derivedFrom}.`
    : presentation.explanation;

  return (
    <span
      title={title}
      className="inline-flex items-center gap-1 rounded-pill px-1.5 py-px text-[10px] font-semibold uppercase tracking-wider"
      style={
        presentation.authoritative
          ? { color: "var(--gb-bg)", backgroundColor: color }
          : { color, border: `1px solid ${color}` }
      }
    >
      <span aria-hidden="true">{presentation.glyph}</span>
      <span>{presentation.label}</span>
      <span className="gb-sr-only">. {title}</span>
    </span>
  );
}
