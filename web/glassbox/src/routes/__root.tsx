import { createRootRoute, HeadContent, Outlet, Scripts } from "@tanstack/react-router";
import { Toaster } from "sonner";
import appCss from "../styles.css?url";

/**
 * Root document.
 *
 * Removed from the imported version: the Better Auth provider, the preview-host
 * bridge, and the PWA manifest links. This is a local instrument with no
 * accounts and no install flow.
 *
 * Toasts are kept, but only for transient operator feedback such as a mode
 * change. A claim about measured state belongs on screen next to its
 * provenance, where it can be read and checked, not in something that fades.
 *
 * `data-density` starts at `comfortable` per §7.6 and is switched by the shell.
 */
const APP_NAME = "Native AI Observatory";

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: APP_NAME },
      { name: "theme-color", content: "#070B10" },
      {
        name: "description",
        content:
          "Native AI Observatory — Arty A7-100T UART silicon, pipeline, Vivado snapshot.",
      },
    ],
    links: [
      { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" },
      { rel: "stylesheet", href: appCss },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      {
        rel: "preconnect",
        href: "https://fonts.gstatic.com",
        crossOrigin: "anonymous",
      },
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Roboto:wght@400;500;700&family=JetBrains+Mono:wght@400;500;600&display=swap",
      },
    ],
  }),
  component: () => (
    <html lang="vi" data-density="comfortable" suppressHydrationWarning>
      <head>
        <HeadContent />
      </head>
      <body className="bg-bg text-fg antialiased">
        <Outlet />
        <Toaster
          theme="dark"
          position="bottom-right"
          toastOptions={{
            style: {
              background: "var(--color-card)",
              border: "1px solid var(--color-line)",
              color: "var(--color-fg)",
            },
          }}
        />
        <Scripts />
      </body>
    </html>
  ),
});
