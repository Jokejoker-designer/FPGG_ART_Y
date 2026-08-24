/**
 * Artifact export.
 *
 * An exported file outlives the screen it came from. Once it is on disk nobody
 * can tell it apart from a real closeout artifact, so this module is the
 * strictest place in the product about provenance.
 *
 * The imported version wrote files claiming `evidence: BOARD`,
 * `M_L1: +3490 (DERIVED from BOARD)` and `Trace: FULLY TRACEABLE`, plus a
 * hardcoded weight-delta CSV with float deltas like `+0.018` and a fabricated
 * VCD with invented transitions. None of that was measured. The learning law is
 * signSGD, so a real delta is an integer of ±1, and a VCD requires a capture
 * this bitstream cannot produce.
 *
 * Every file written here starts with a provenance header, and anything with no
 * source is refused rather than approximated.
 *
 * Owner: gb-frontend-architecture.
 */
import { artifacts } from "./data";
import { buildFacts, measured, sessionView } from "./metrics";
import { studioHeaderFromStore } from "./studio-header";

function save(name: string, content: string, type: string) {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}

/** Prepended to every text artifact so a file on disk states what it is. */
function header(comment: string): string {
  const studio = studioHeaderFromStore();
  return [
    `${comment} Native AI GlassBox Studio export`,
    `${comment} interaction: #${studio.id}`,
    `${comment} source: ${studio.activeSource}`,
    `${comment} law: ${buildFacts.learningLawId}`,
    `${comment} NOT silicon evidence unless source reads BOARD`,
    "",
  ].join("\n");
}

export type ExportResult =
  | { ok: true; name: string }
  | { ok: false; reason: string };

export function downloadArtifact(name: string): ExportResult {
  const art =
    artifacts.find((a) => a.name === name) ??
    (name.startsWith("waveform-") && name.endsWith(".vcd")
      ? { name, kind: "VCD" as const, size: "", sha: "" }
      : undefined);
  if (!art) return { ok: false, reason: "Không có artifact tên này." };

  if (art.kind === "JSON" || art.kind === "JSONL") {
    /* Provenance objects are exported whole rather than flattened to a source
       string, so the file carries the same evidence structure the screen did. */
    const studio = studioHeaderFromStore();
    save(
      name,
      JSON.stringify(
        {
          contract: "glassbox",
          interaction_id: studio.id,
          active_source: studio.activeSource,
          question: studio.question,
          answer: studio.answer,
          d_pos: measured.dPos,
          d_neg: measured.dNeg,
          M_L1: measured.marginL1,
          M_cos: measured.marginCosine,
          dH: measured.dH,
          episode: sessionView.retrieval?.selectedEpisodeId ?? null,
          traceability: sessionView.traceability,
          evidence: sessionView.evidenceRows,
          build: {
            model_version: buildFacts.modelVersion,
            learning_law: buildFacts.learningLawId,
            memory_law: buildFacts.memoryLawId,
            parameters: {
              lm: buildFacts.paramsLm,
              encoder: buildFacts.paramsEncoder,
            },
            timing: {
              status: buildFacts.timingStatus,
              wns_ns: buildFacts.wnsNs,
              tns_ns: buildFacts.tnsNs,
              whs_ns: buildFacts.whsNs,
              ths_ns: buildFacts.thsNs,
            },
            utilization: buildFacts.utilization,
          },
        },
        null,
        2,
      ),
      "application/json",
    );
    return { ok: true, name };
  }

  if (art.kind === "CSV") {
    const writes = sessionView.stages.length > 0 ? measured : null;
    const learning = sessionView.interactions
      .find((i) => i.interactionId === studioHeaderFromStore().id)
      ?.learning[0];

    if (!writes || !learning || learning.writes.length === 0) {
      return {
        ok: false,
        reason:
          "Tương tác này không ghi trọng số nào, nên không có dòng nào để xuất.",
      };
    }

    const rows = learning.writes
      .map((w) => `${w.target},${w.address},${w.before},${w.delta},${w.after}`)
      .join("\n");
    save(
      name,
      `${header("#")}target,address,before,delta,after\n${rows}\n`,
      "text/csv",
    );
    return { ok: true, name };
  }

  if (art.kind === "VCD") {
    /* A VCD is a cycle-accurate record. Writing one without a capture would put
       a fabricated waveform on disk, which is the single worst artifact this
       product could produce. */
    const capture = sessionView.waveform;
    if (!capture.available) {
      return {
        ok: false,
        reason: `Không có bản ghi waveform cho tương tác này (${capture.absence.reason}), nên không thể xuất VCD.`,
      };
    }
    if (!capture.capture.exportFormats.includes("VCD")) {
      return {
        ok: false,
        reason: "Nguồn waveform hiện tại không hỗ trợ xuất VCD.",
      };
    }

    const { capture: cap } = capture;
    const symbols = new Map<string, string>();
    cap.signals.forEach((signal, index) => {
      symbols.set(signal.id, String.fromCharCode(33 + index));
    });

    const declarations = cap.signals
      .map(
        (s) =>
          `$var wire ${s.width} ${symbols.get(s.id)} ${s.rtlName ?? s.id} $end`,
      )
      .join("\n");

    const events = cap.traces
      .flatMap((trace) =>
        trace.transitions.map((t) => ({
          cycle: t.cycle,
          line: `${t.value.toString(2)}${symbols.get(trace.signalId) ?? "!"}`,
        })),
      )
      .sort((a, b) => a.cycle - b.cycle);

    let body = "";
    let cursor = -1;
    for (const event of events) {
      if (event.cycle !== cursor) {
        body += `#${event.cycle}\n`;
        cursor = event.cycle;
      }
      body += `${event.line}\n`;
    }

    save(
      name,
      `${header("$comment")}$timescale 10 ns $end\n$scope module glassbox $end\n${declarations}\n$upscope $end\n$enddefinitions $end\n${body}`,
      "text/plain",
    );
    return { ok: true, name };
  }

  const rank = measured.effectiveRank;
  const margin = measured.marginL1;
  const closeout = studioHeaderFromStore();
  save(
    name,
    `${header("<!--")}
# Closeout Interaction #${closeout.id}

- Board: ${closeout.board}
- Nguồn dữ liệu: ${closeout.activeSource}
- Luật học: ${buildFacts.learningLawId}
- M_L1: ${margin ? `${margin.value} (${margin.provenance.source}${margin.provenance.derivedFrom ? ` từ ${margin.provenance.derivedFrom.join(", ")}` : ""})` : "chưa đo"}
- Effective rank: ${rank ? `${rank.value}/${buildFacts.hiddenDim} (${rank.provenance.source})` : "chưa đo"}
- Timing: ${buildFacts.timingStatus}${buildFacts.wnsNs === null ? "" : ` · WNS ${buildFacts.wnsNs} ns · TNS ${buildFacts.tnsNs}`}
- Truy vết: ${sessionView.traceability.verdict}${sessionView.traceability.missing.length > 0 ? ` · thiếu ${sessionView.traceability.missing.join(", ")}` : ""}
`,
    "text/markdown",
  );
  return { ok: true, name };
}
