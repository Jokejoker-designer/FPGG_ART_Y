/**
 * Local replay cache (SPEC §34). Stores the session the ports already
 * returned. Does not invent a second interaction.
 */
import type { Session } from "@/lib/contract";

const DB_NAME = "glassbox-replay";
const STORE = "sessions";

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE)) {
        db.createObjectStore(STORE, { keyPath: "sessionId" });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

export async function rememberSession(session: Session): Promise<void> {
  if (typeof indexedDB === "undefined") return;
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(STORE, "readwrite");
    tx.objectStore(STORE).put({
      sessionId: session.sessionId,
      openedAt: session.openedAt,
      session,
    });
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function listRememberedSessions(): Promise<{ sessionId: string; openedAt: string }[]> {
  if (typeof indexedDB === "undefined") return [];
  const db = await openDb();
  const rows = await new Promise<{ sessionId: string; openedAt: string }[]>((resolve, reject) => {
    const tx = db.transaction(STORE, "readonly");
    const req = tx.objectStore(STORE).getAll();
    req.onsuccess = () => {
      const values = (req.result as { sessionId: string; openedAt: string }[]) ?? [];
      resolve(values.map((row) => ({ sessionId: row.sessionId, openedAt: row.openedAt })));
    };
    req.onerror = () => reject(req.error);
  });
  db.close();
  return rows;
}
