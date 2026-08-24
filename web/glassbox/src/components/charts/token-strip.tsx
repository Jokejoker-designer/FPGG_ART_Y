"use client";

/**
 * §8.1 "Input bytes/tokens → token strip". The main visualisation of Tab 3.
 *
 * One cell per UTF-8 byte, not per character, because that is what the encoder
 * consumes. A Vietnamese input makes this visible: `à` occupies two bytes, and
 * the continuation byte is shown as a continuation rather than as a second
 * glyph, which is the whole point of the screen.
 *
 * Keyboard: a roving tabindex with arrow keys, so 30-plus cells cost one tab
 * stop instead of thirty (SC 2.1.1 without wrecking the tab order).
 *
 * Owner: gb-scientific-dataviz.
 */
import { useCallback, useRef } from "react";
import type { InputToken, Provenance } from "@/lib/contract";
import { EvidenceBadge } from "@/components/ui/evidence-badge";

function hex(byte: number): string {
  return `0x${byte.toString(16).toUpperCase().padStart(2, "0")}`;
}

function isContinuation(token: InputToken): boolean {
  return token.char === null;
}

/** Visible stand-in for a byte that carries no glyph of its own. */
const CONTINUATION_GLYPH = "\u2937";

export function TokenStrip({
  tokens,
  selectedPosition,
  onSelect,
  provenance,
}: {
  tokens: readonly InputToken[];
  selectedPosition: number | null;
  onSelect: (position: number) => void;
  provenance: Provenance;
}) {
  const listRef = useRef<HTMLDivElement | null>(null);

  const focusCell = useCallback((position: number) => {
    const el = listRef.current?.querySelector<HTMLButtonElement>(
      `[data-position="${position}"]`,
    );
    el?.focus();
  }, []);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      const current = Number(
        (event.target as HTMLElement).dataset.position ?? "0",
      );
      const last = tokens.length - 1;
      let next: number | null = null;

      if (event.key === "ArrowRight") next = Math.min(current + 1, last);
      else if (event.key === "ArrowLeft") next = Math.max(current - 1, 0);
      else if (event.key === "Home") next = 0;
      else if (event.key === "End") next = last;

      if (next !== null) {
        event.preventDefault();
        onSelect(next);
        focusCell(next);
      }
    },
    [tokens.length, onSelect, focusCell],
  );

  if (tokens.length === 0) {
    return (
      <figure className="flex flex-col gap-2">
        <figcaption className="text-sm font-semibold text-ink">
          Chuỗi byte đưa vào
        </figcaption>
        <p className="text-sm text-ink-muted">
          Tương tác này không ghi lại dữ liệu vào.
        </p>
      </figure>
    );
  }

  const active = selectedPosition ?? 0;

  return (
    <figure className="flex flex-col gap-3">
      <figcaption className="flex flex-wrap items-center justify-between gap-3">
        <span className="text-sm font-semibold text-ink">
          Chuỗi byte đưa vào
        </span>
        <span className="flex items-center gap-2">
          <span className="gb-num text-xs text-ink-muted">
            {tokens.length} byte
          </span>
          <EvidenceBadge provenance={provenance} />
        </span>
      </figcaption>

      <div
        ref={listRef}
        role="listbox"
        aria-label="Từng byte của dữ liệu vào. Dùng mũi tên trái phải để xem."
        aria-orientation="horizontal"
        className="flex flex-wrap gap-1"
        onKeyDown={onKeyDown}
      >
        {tokens.map((token) => {
          const selected = token.position === selectedPosition;
          const continuation = isContinuation(token);
          return (
            <button
              key={token.position}
              type="button"
              role="option"
              aria-selected={selected}
              data-position={token.position}
              tabIndex={token.position === active ? 0 : -1}
              onClick={() => onSelect(token.position)}
              title={`${continuation ? "Byte tiếp nối" : `Ký tự ${token.char}`} · ${hex(token.byte)} · vị trí ${token.position}`}
              className="flex w-11 flex-col items-center gap-0.5 rounded-control border px-1 py-1.5"
              style={{
                borderColor: selected
                  ? "var(--gb-primary)"
                  : "var(--gb-border)",
                backgroundColor: selected
                  ? "var(--gb-primary-dim)"
                  : "var(--gb-surface-2)",
              }}
            >
              <span
                aria-hidden="true"
                className="text-sm leading-none"
                style={{
                  color: continuation
                    ? "var(--gb-text-muted)"
                    : "var(--gb-text)",
                }}
              >
                {continuation ? CONTINUATION_GLYPH : token.char}
              </span>
              <span className="gb-num text-[10px] text-ink-muted">
                {token.byte}
              </span>
              <span className="gb-sr-only">
                {continuation
                  ? `Byte tiếp nối của ký tự trước, giá trị ${token.byte}`
                  : `Ký tự ${token.char}, byte ${token.byte}`}
                , vị trí {token.position}
              </span>
            </button>
          );
        })}
      </div>

      <table className="gb-sr-only">
        <caption>Bảng byte của dữ liệu vào</caption>
        <thead>
          <tr>
            <th scope="col">Vị trí</th>
            <th scope="col">Ký tự</th>
            <th scope="col">Giá trị byte</th>
            <th scope="col">Hex</th>
            <th scope="col">Hàng embedding</th>
          </tr>
        </thead>
        <tbody>
          {tokens.map((token) => (
            <tr key={token.position}>
              <th scope="row">{token.position}</th>
              <td>{token.char ?? "byte tiếp nối"}</td>
              <td>{token.byte}</td>
              <td>{hex(token.byte)}</td>
              <td>E[{token.embeddingRow}]</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}

export { hex as byteHex };
