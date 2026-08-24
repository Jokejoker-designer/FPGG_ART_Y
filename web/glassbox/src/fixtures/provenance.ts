/**
 * Provenance helpers for fixture data.
 *
 * SPEC §31 last line: values used outside a scientific session must be
 * identified as synthetic. This phase predates Native V1 freeze, so nothing
 * here may claim BOARD. Every fixture value is stamped SYNTHETIC, and values
 * computed from other fixture values are stamped DERIVED with their inputs
 * named, which is what §25 requires.
 *
 * Owner: gb-frontend-architecture.
 */
import type { MeasuredFloat, MeasuredInt, Provenance } from "@/lib/contract";

/** Fixed so fixtures are byte-identical between runs. */
export const FIXTURE_CAPTURED_AT = "2026-08-20T10:32:15.481+07:00";

export const SYNTHETIC: Provenance = {
  source: "SYNTHETIC",
  capturedAt: FIXTURE_CAPTURED_AT,
  note: "Dữ liệu sinh sẵn để dựng giao diện, không đo từ bo mạch.",
};

export const TWIN: Provenance = {
  source: "TWIN",
  capturedAt: FIXTURE_CAPTURED_AT,
  note: "Ước lượng từ mô hình host. Không phải đo silicon.",
};

export function derived(from: readonly string[]): Provenance {
  return {
    source: "DERIVED",
    derivedFrom: [...from],
    capturedAt: FIXTURE_CAPTURED_AT,
  };
}

export function synthInt(value: number, unit?: string): MeasuredInt {
  return unit ? { value, provenance: SYNTHETIC, unit } : { value, provenance: SYNTHETIC };
}

export function synthFloat(value: number, unit?: string): MeasuredFloat {
  return unit ? { value, provenance: SYNTHETIC, unit } : { value, provenance: SYNTHETIC };
}

export function derivedInt(
  value: number,
  from: readonly string[],
  unit?: string,
): MeasuredInt {
  const provenance = derived(from);
  return unit ? { value, provenance, unit } : { value, provenance };
}

export function derivedFloat(
  value: number,
  from: readonly string[],
  unit?: string,
): MeasuredFloat {
  const provenance = derived(from);
  return unit ? { value, provenance, unit } : { value, provenance };
}
