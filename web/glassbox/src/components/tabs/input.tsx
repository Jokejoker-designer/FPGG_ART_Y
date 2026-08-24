import { sessionView } from "@/lib/metrics";
import { useStudioHeader } from "@/lib/studio-header";
import { useStudio } from "@/lib/store";
import { EmbeddingBarcode } from "../charts/embedding-barcode";
import { When } from "../level";
import { EvidenceBadge } from "../ui/evidence-badge";
import { Panel, PanelTitle, Pill } from "../ui";

/**
 * Dữ liệu vào (§11).
 *
 * The encoder consumes UTF-8 bytes, not word tokens. The imported table
 * invented token IDs and stamped the board. This screen walks the recorded
 * `InputEvent.tokens` and only shows an embedding row for a byte that was
 * actually read.
 *
 * Owner: gb-ux-product.
 */
function hexByte(byte: number): string {
  return `0x${byte.toString(16).toUpperCase().padStart(2, "0")}`;
}

export function InputTab() {
  const { selectedToken, setSelectedToken, level } = useStudio();
  const header = useStudioHeader();
  const event = sessionView.inputEvent;
  const tokens = event?.tokens ?? [];
  const selected = tokens[selectedToken] ?? tokens[0] ?? null;
  const embedding =
    selected == null
      ? null
      : (sessionView.embeddingRows.find((row) => row.byte === selected.byte) ?? null);

  if (!event || tokens.length === 0) {
    return (
      <Panel>
        <PanelTitle>Chưa có dữ liệu vào</PanelTitle>
        <p className="text-[13px] text-muted">
          Tương tác này không ghi byte đầu vào. Không suy ra bảng token.
        </p>
      </Panel>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone={header.live ? "board" : "warn"}>{header.activeSource}</Pill>
        <EvidenceBadge provenance={event.provenance} />
      </div>

      <Panel>
        <PanelTitle>
          {level === "easy" ? "Câu bạn vừa gửi" : level === "rtl" ? "byte stream" : "Câu gốc"}
        </PanelTitle>
        <p className="text-lg text-fg">{event.text}</p>
        <div className="mt-4 flex flex-wrap gap-1.5" role="list" aria-label="Dải byte đầu vào">
          {tokens.map((tok, i) => (
            <button
              key={`${tok.position}-${tok.byte}`}
              type="button"
              role="listitem"
              onClick={() => setSelectedToken(i)}
              title={hexByte(tok.byte)}
              className={
                i === selectedToken
                  ? "min-w-10 rounded-lg bg-cyan px-2 py-1 text-center text-bg"
                  : "min-w-10 rounded-lg border border-line bg-surface px-2 py-1 text-center"
              }
            >
              <span className="block text-sm leading-none">
                {tok.char ?? "·"}
              </span>
              <span className="mt-1 block font-mono text-micro opacity-80">
                {level === "easy" ? tok.byte : hexByte(tok.byte)}
              </span>
            </button>
          ))}
        </div>
        <When
          easy={
            <p className="mt-4 text-[13px] text-muted">
              Mỗi ký tự được đổi thành số trước khi đi vào phần học của FPGA. Bấm vào ô để xem số
              đó.
            </p>
          }
          research={
            <p className="mt-4 text-caption text-subtle">
              {tokens.length} byte UTF-8 · continuation byte hiện dấu · không bịa glyph
            </p>
          }
          rtl={
            <p className="mt-4 font-mono text-caption text-muted">
              valid_in × {tokens.length} · i_byte[7:0] · embeddingRow = byte
            </p>
          }
        />
      </Panel>

      <div className="grid gap-3 lg:grid-cols-[1fr_1.1fr]">
        <Panel>
          <PanelTitle>Chi tiết byte</PanelTitle>
          {selected ? (
            <dl className="space-y-2 text-[13px]">
              <div className="flex justify-between gap-3 border-b border-line/60 py-1.5">
                <dt className="text-subtle">Ký tự</dt>
                <dd className="font-mono">{selected.char ?? "continuation · không hiện chữ"}</dd>
              </div>
              <div className="flex justify-between gap-3 border-b border-line/60 py-1.5">
                <dt className="text-subtle">UTF-8</dt>
                <dd className="font-mono">{hexByte(selected.byte)}</dd>
              </div>
              <div className="flex justify-between gap-3 border-b border-line/60 py-1.5">
                <dt className="text-subtle">Vị trí</dt>
                <dd className="font-mono">{selected.position}</dd>
              </div>
              <div className="flex justify-between gap-3 py-1.5">
                <dt className="text-subtle">Embedding row</dt>
                <dd className="font-mono">E[{selected.embeddingRow}]</dd>
              </div>
            </dl>
          ) : (
            <p className="text-[13px] text-muted">Chưa chọn byte nào.</p>
          )}
        </Panel>
        <Panel>
          <PanelTitle hint="chỉ byte đã đọc">Hàng embedding</PanelTitle>
          <EmbeddingBarcode
            row={embedding}
            emptyText="Byte này chưa có hàng embedding được ghi lại."
          />
        </Panel>
      </div>
    </div>
  );
}
