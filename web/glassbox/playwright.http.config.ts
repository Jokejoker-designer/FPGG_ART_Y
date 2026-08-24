import { defineConfig, devices } from "@playwright/test";

/**
 * Integration phase: fixture Playwright stays on playwright.config.ts.
 * This file starts the SYNTHETIC backend and a Vite app with
 * VITE_GLASSBOX_TRANSPORT=http. No board, no Vivado.
 *
 * Owner: gb-playwright-e2e.
 */
const PORT = 3111;
const BASE_URL = `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: "./e2e",
  testMatch: ["s36-http.spec.ts"],
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  reporter: [["list"]],

  use: {
    baseURL: BASE_URL,
    trace: "retain-on-failure",
  },

  projects: [
    {
      name: "desktop-1440",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1440, height: 900 } },
    },
    {
      name: "laptop-1280",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 800 } },
    },
  ],

  webServer: [
    {
      command: "npm start",
      cwd: "../../services/glassbox",
      url: "http://127.0.0.1:8788/v1/health",
      reuseExistingServer: false,
      timeout: 60_000,
      env: {
        GLASSBOX_PORT: "8788",
      },
    },
    {
      command: `npx vite dev --host 127.0.0.1 --port ${PORT}`,
      url: BASE_URL,
      reuseExistingServer: false,
      timeout: 120_000,
      env: {
        VITE_GLASSBOX_TRANSPORT: "http",
        VITE_GLASSBOX_API: "http://127.0.0.1:8788",
      },
    },
  ],
});
