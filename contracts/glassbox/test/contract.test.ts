/**
 * Round-trip and invariant tests for the frozen GlassBox contract.
 *
 * These exist to prove the schema actually rejects the things SPEC §25, §24
 * and §15 say must be impossible. A schema that only accepts happy data is
 * not a contract.
 */
import assert from "node:assert/strict";
import { test } from "node:test";

import {
  CONTRACT_VERSION,
  DeviceUtilization,
  EmbeddingRow,
  ParameterCounts,
  Projection2D,
  Provenance,
  PHASE_ORDER,
  usagePercent,
  RetrievalFunnel,
  TelemetrySample,
  WaveformResult,
  measured,
} from "../src/index.ts";
import { z } from "zod";

const AT = "2026-08-20T10:32:15.481+07:00";

test("contract version is pinned", () => {
  assert.equal(CONTRACT_VERSION, "glassbox-contract-v0.4.0");
});

test("utilisation keeps counts beside the percentage", () => {
  const util = DeviceUtilization.parse({
    part: "xc7a100tcsg324-1",
    reportPath: "results/A7-EAM-03E/A01T_CLOSE/a7eam03e_utilization_route.rpt",
    rows: [
      { resource: "Slice LUTs", used: 7_713, available: 63_400 },
      { resource: "DSPs", used: 0, available: 240 },
    ],
  });

  const luts = util.rows[0]!;
  assert.equal(usagePercent(luts), 12.17);

  /* a7-fpga-gate makes DSP = 0 a hard gate. A view that renders this as busy
     is a defect, so the zero has to survive the round trip rather than being
     treated as a missing value. */
  const dsp = util.rows[1]!;
  assert.equal(dsp.used, 0);
  assert.equal(usagePercent(dsp), 0);
});

test("utilisation cannot report a percentage without the counts", () => {
  const result = DeviceUtilization.safeParse({
    part: "xc7a100tcsg324-1",
    reportPath: "some/report.rpt",
    rows: [{ resource: "Slice LUTs", used: 7_713 }],
  });
  assert.equal(result.success, false);
});

test("a 2D projection may not claim to be anything but DERIVED (§12)", () => {
  const base = {
    interactionId: "1842",
    points: [{ role: "ANCHOR", stage: "BEFORE_UPDATE", x: 0.1, y: -0.4 }],
    method: "hai trục ngẫu nhiên cố định theo hạt giống",
  };

  const asBoard = Projection2D.safeParse({
    ...base,
    provenance: { source: "BOARD", capturedAt: AT },
  });
  assert.equal(asBoard.success, false);

  const asDerived = Projection2D.safeParse({
    ...base,
    provenance: {
      source: "DERIVED",
      derivedFrom: ["h[ANCHOR]", "h[POSITIVE]", "h[NEGATIVE]"],
      capturedAt: AT,
    },
  });
  assert.equal(asDerived.success, true);
});

test("an embedding row is fixed width so a barcode cannot go ragged", () => {
  const short = EmbeddingRow.safeParse({
    byte: 65,
    values: [1, 2, 3],
    provenance: { source: "SYNTHETIC", capturedAt: AT },
  });
  assert.equal(short.success, false);

  const exact = EmbeddingRow.safeParse({
    byte: 65,
    values: Array.from({ length: 32 }, (_, i) => i - 16),
    provenance: { source: "SYNTHETIC", capturedAt: AT },
  });
  assert.equal(exact.success, true);
});

test("parameter counts are kept separate and no total is expressible", () => {
  const counts = ParameterCounts.parse({ lm: 802_816, encoder: 9_216 });
  assert.equal(counts.lm, 802_816);
  assert.equal(counts.encoder, 9_216);

  /* a7-fpga-gate forbids summing these. A stray `total` must be stripped
     rather than silently carried through to a screen. */
  const withTotal = ParameterCounts.parse({
    lm: 802_816,
    encoder: 9_216,
    total: 812_032,
  } as unknown);
  assert.equal("total" in withTotal, false);
});

test("phase order is the causal order of the process strip", () => {
  assert.deepEqual(PHASE_ORDER, [
    "INPUT",
    "ENCODE",
    "COMPARE",
    "LEARN",
    "MEMORY",
    "MODEL",
    "OUTPUT",
  ]);
});

test("BOARD provenance round-trips unchanged", () => {
  const input = { source: "BOARD", capturedAt: AT } as const;
  const parsed = Provenance.parse(input);
  assert.deepEqual(parsed, input);
});

test("DERIVED provenance without a source list is rejected (§25)", () => {
  const result = Provenance.safeParse({ source: "DERIVED", capturedAt: AT });
  assert.equal(result.success, false);
  if (!result.success) {
    assert.match(result.error.issues[0]!.message, /derived from/i);
  }
});

test("DERIVED provenance naming its inputs is accepted", () => {
  const result = Provenance.safeParse({
    source: "DERIVED",
    derivedFrom: ["d_pos@BOARD", "d_neg@BOARD"],
    capturedAt: AT,
  });
  assert.equal(result.success, true);
});

test("non-DERIVED provenance may not smuggle a derivedFrom list", () => {
  const result = Provenance.safeParse({
    source: "BOARD",
    derivedFrom: ["something"],
    capturedAt: AT,
  });
  assert.equal(result.success, false);
});

test("a metric cannot be represented without provenance", () => {
  const MeasuredInt = measured(z.number().int());
  const result = MeasuredInt.safeParse({ value: 1320 });
  assert.equal(result.success, false);
});

test("a telemetry sample round-trips with absent phases left explicitly null", () => {
  const sample = {
    eventId: "evt-1842-compare",
    interactionId: "1842",
    emittedAt: AT,
    phase: "COMPARE",
    mode: "TRAIN",
    teacherOn: true,
    learn: true,
    freeze: false,
    dPos: { value: 1320, provenance: { source: "SYNTHETIC", capturedAt: AT } },
    dNeg: { value: 4810, provenance: { source: "SYNTHETIC", capturedAt: AT } },
    marginL1: {
      value: 3490,
      provenance: {
        source: "DERIVED",
        derivedFrom: ["dPos", "dNeg"],
        capturedAt: AT,
      },
    },
    updateCount: null,
    changedValues: null,
    hiddenSaturation: null,
    effectiveRank: null,
    episodeId: null,
    candidateCount: null,
    outputTokenId: null,
    provenance: { source: "SYNTHETIC", capturedAt: AT },
  };

  const parsed = TelemetrySample.parse(sample);
  assert.deepEqual(TelemetrySample.parse(parsed), parsed);
  assert.equal(parsed.updateCount, null);
});

test("a retrieval funnel may not widen (§15)", () => {
  const provenance = { source: "SYNTHETIC" as const, capturedAt: AT };
  const widening = RetrievalFunnel.safeParse({
    interactionId: "1842",
    stages: [
      { label: "episodes", count: 9 },
      { label: "postings", count: 126 },
    ],
    selectedEpisodeId: null,
    provenance,
  });
  assert.equal(widening.success, false);

  const narrowing = RetrievalFunnel.safeParse({
    interactionId: "1842",
    stages: [
      { label: "episodes", count: 800000 },
      { label: "postings", count: 126 },
      { label: "candidates", count: 9 },
      { label: "full-key checks", count: 3 },
    ],
    selectedEpisodeId: "488271",
    provenance,
  });
  assert.equal(narrowing.success, true);
});

test("a missing waveform is representable as an explicit absence (§26)", () => {
  const absent = WaveformResult.parse({
    available: false,
    absence: {
      interactionId: "1842",
      reason: "PRE_FREEZE_NOT_PERMITTED",
      detail: "Capture plane is out of scope until Native V1 is frozen.",
    },
  });
  assert.equal(absent.available, false);
});

test("a waveform result cannot claim availability without a capture", () => {
  const result = WaveformResult.safeParse({ available: true });
  assert.equal(result.success, false);
});
