import { useStudio } from "@/lib/store";

export function studioHeaderFromStore() {
  const { session, connection, activeInteractionId } = useStudio.getState();
  const interaction =
    session.interactions.find((row) => row.interactionId === activeInteractionId) ??
    session.interactions[0];

  return {
    id: interaction?.interactionId ?? "—",
    live: connection.connected,
    activeSource: connection.activeSource,
    sourceNote: connection.detail ?? "Chưa có nguồn",
    mode: interaction?.mode ?? "EVAL",
    clock: `${session.build.clockMhz} MHz`,
    build: session.build.bitstreamSha256?.slice(0, 7) ?? "chưa có bit",
    bitstream: session.build.bitstreamSha256,
    sourceSha: session.build.sourceSha256,
    time: interaction?.startedAt ?? session.openedAt,
    sessionLabel: `S-${interaction?.interactionId ?? "—"} · ${interaction?.teacherOn ? "Teacher-on" : "Teacher-off"}`,
    question: interaction?.question ?? "",
    answer: interaction?.answer ?? null,
    teacherOn: interaction?.teacherOn ?? false,
    trace: interaction?.traceability.verdict ?? "PARTIALLY_TRACEABLE",
    board: "Arty A7-100T",
    part: session.build.utilization?.part ?? "XC7A100T-CSG324",
  };
}

/** Header fields from the port-hydrated session, not a frozen INTERACTION blob. */
export function useStudioHeader() {
  useStudio((s) => s.session);
  useStudio((s) => s.connection);
  useStudio((s) => s.activeInteractionId);
  return studioHeaderFromStore();
}
