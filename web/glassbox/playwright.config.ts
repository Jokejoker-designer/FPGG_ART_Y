import { defineConfig, devices } from "@playwright/test";

/**
 * §27 makes 1440px and 1280px both real targets. Tests run against the
 * TanStack Vite app on fixtures: no backend process, no board, no Vivado.
 *
 * Owner: gb-playwright-e2e.
 */
const PORT = 3110;
const BASE_URL = `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: "./e2e",
  testMatch: [
    "input-representation.spec.ts",
    "compare-learning.spec.ts",
    "memory-model.spec.ts",
    "output-waveform.spec.ts",
    "health-replay.spec.ts",
    "evidence-explain.spec.ts",
    "states-a11y.spec.ts",
    "s36-frontend.spec.ts",
    "adapter-wiring.spec.ts",
    "observatory.spec.ts",
  ],
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

  webServer: {
    command: `npx vite dev --host 127.0.0.1 --port ${PORT}`,
    url: BASE_URL,
    reuseExistingServer: false,
    timeout: 120_000,
  },
});
