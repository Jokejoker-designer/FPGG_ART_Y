import { startServer, BIND } from "./http.ts";

const port = Number(process.env.GLASSBOX_PORT ?? BIND.port);

const handle = await startServer(port);
process.stdout.write(`glassbox-service SYNTHETIC listening on ${BIND.host}:${handle.port}\n`);
process.stdout.write("no serial port, no LiteScope, no BOARD claim\n");
