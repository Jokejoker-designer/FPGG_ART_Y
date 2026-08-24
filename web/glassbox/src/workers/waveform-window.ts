/**
 * Off-main-thread range filter for RLE traces (SPEC §29 / §34).
 * Does not invent samples; it only keeps recorded transitions in [from, to].
 */
export type WindowRequest = {
  traces: { signalId: string; transitions: { cycle: number; value: number }[] }[];
  from: number;
  to: number;
};

addEventListener("message", (event: MessageEvent<WindowRequest>) => {
  const { traces, from, to } = event.data;
  const sliced = traces.map((trace) => ({
    signalId: trace.signalId,
    transitions: trace.transitions.filter((row) => row.cycle >= from && row.cycle <= to),
  }));
  postMessage(sliced);
});
