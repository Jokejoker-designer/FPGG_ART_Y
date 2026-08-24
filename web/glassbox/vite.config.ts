import { defineConfig } from "vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { nitro } from "nitro/vite";

/**
 * GlassBox Studio dev/build config.
 *
 * Removed from the imported configuration, deliberately: the PGlite bootstrap
 * plugin, the Better Auth OAuth popup middleware, the Grok PWA plugin, and the
 * Vercel Nitro preset. This is a local instrument for one FPGA on one desk. It
 * has no accounts, no database and no deploy target, and each of those brought
 * its own failure modes plus about eleven megabytes of WebAssembly.
 *
 * Binds to 127.0.0.1 rather than 0.0.0.0: the studio will eventually hold an
 * open serial link to the board, and that must not be reachable from the LAN.
 */
export default defineConfig(({ command, isPreview }) => ({
  server: {
    host: "127.0.0.1",
    port: 8080,
    strictPort: true,
  },
  preview: {
    host: "127.0.0.1",
    port: 8081,
    strictPort: true,
  },
  resolve: { tsconfigPaths: true },
  plugins: [
    tailwindcss(),
    tanstackStart(),
    ...(command === "build" || isPreview ? [nitro()] : []),
    viteReact(),
  ],
}));
