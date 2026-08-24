/**
 * Loads the studio cache through GlassBoxPorts. Screens keep reading
 * sessionView; this file is the only place that talks to a transport.
 */
import { getPorts } from "./index";
import type { Interaction } from "@/lib/contract";
import type { ChatMsg } from "@/lib/data";
import { rememberSession } from "@/lib/session-idb";
import { useStudio } from "@/lib/store";

function recordedChat(interaction: Interaction): ChatMsg[] {
  const time = interaction.startedAt.slice(11, 19) || "00:00:00";
  const learn = interaction.learning[0];
  return [
    { id: "m1", role: "user", text: interaction.question, time },
    {
      id: "m2",
      role: "ai",
      text: interaction.answer ?? "Không có câu trả lời từ bo.",
      time,
      meta: [
        interaction.latencyMs ? `${interaction.latencyMs.value} ms` : null,
        interaction.tokenCount ? `${interaction.tokenCount.value} token` : null,
        "SYNTHETIC",
      ]
        .filter(Boolean)
        .join(" · "),
      learned: Boolean(learn?.updateEnabled),
    },
  ];
}

export async function hydrateFromPorts(): Promise<void> {
  const ports = getPorts();
  const session = await ports.session.getSession();
  const connection = await ports.session.getConnectionState();
  const activeInteractionId =
    session.interactions[0]?.interactionId ?? useStudio.getState().activeInteractionId;
  const embeddingRows = await ports.snapshot.getEmbeddingRows(activeInteractionId);
  const projection = await ports.snapshot.getProjection(activeInteractionId);
  const interaction =
    session.interactions.find((row) => row.interactionId === activeInteractionId) ??
    session.interactions[0];
  useStudio.setState({
    session,
    connection,
    activeInteractionId,
    embeddingRows,
    projection,
    chat: interaction ? recordedChat(interaction) : [],
  });
  try {
    await rememberSession(session);
  } catch {
    /* IndexedDB is optional replay cache. A failure must not invent a session. */
  }
}
