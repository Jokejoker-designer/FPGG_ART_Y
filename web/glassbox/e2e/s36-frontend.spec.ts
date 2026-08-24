import { expect, test } from "@playwright/test";

/**
 * R9: SPEC §36 observable checks on the fixture studio.
 * Owner: gb-playwright-e2e.
 */

const FORBIDDEN = [
  "Lorem ipsum",
  "Feature 1",
  "TODO",
  "Developer note",
  "Mockup",
  "bộ não AI",
  "AI suy nghĩ",
  "ý thức",
  "LiteScope capture groups",
  "snapshot silicon Interaction #1842 (BOARD)",
];

async function ready(page: import("@playwright/test").Page) {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
}

test.describe("§36 frontend audit", () => {
  test("live transcript is the recorded interaction, not ILA/LiteScope", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-live").click();
    await expect(page.getByText("Board hiện tại dùng chip gì?").first()).toBeVisible();
    await expect(page.getByText("ILA Basic")).toHaveCount(0);
    await expect(page.getByText("LiteScope là lớp capture")).toHaveCount(0);
    await expect(page.getByText("Episode #488271")).toHaveCount(0);
  });

  test("easy mode follows the process without FPGA jargon on overview", async ({ page }) => {
    await ready(page);
    await expect(page.getByText("AI vừa học từ tương tác này").or(page.getByText("Tổng quan"))).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await expect(page.getByTestId("tab-input")).toBeVisible();
    await expect(page.getByTestId("tab-learning")).toBeVisible();
    await expect(page.getByTestId("tab-waveform")).toBeVisible();
  });

  test("research mode shows exact numbers with provenance, not TWIN-as-BOARD", async ({ page }) => {
    await ready(page);
    await page.getByRole("banner").getByRole("button", { name: "Research" }).click();
    await page.getByTestId("tab-compare").click();
    await expect(page.getByText("1320").first()).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await page.getByTestId("tab-metrics").click();
    await expect(page.getByText("Cảnh báo: Representation Collapse")).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("waveform evidence stays under simplified copy and empty 1841 does not draw", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-waveform").click();
    await expect(page.getByTestId("waveform-cursor")).toBeVisible();
    await page.getByTestId("waveform-interaction").selectOption("1841");
    await expect(page.getByText("Không có waveform cho tương tác này")).toBeVisible();
  });

  test("before/after learning and memory funnel stay on one interaction", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-learning").click();
    await expect(page.getByRole("columnheader", { name: "trước" })).toBeVisible();
    await page.getByTestId("tab-eam").click();
    await expect(page.getByText("#488271").first()).toBeVisible();
    await expect(page.getByTestId("tab-episode")).toHaveCount(0);
  });

  test("output traces to model/memory and settings never claim BOARD", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-output").click();
    await expect(page.getByText("Artix").first()).toBeVisible();
    await page.getByTestId("tab-settings").click();
    await expect(page.locator("#gb-main").getByText("SYNTHETIC", { exact: true })).toBeVisible();
    await expect(page.getByText("chưa kết nối", { exact: true })).toBeVisible();
    await expect(page.getByText("LiteScope")).toHaveCount(0);
  });

  test("forbidden overclaim and mockup copy is absent at 1440 and 1280", async ({ page }) => {
    await ready(page);
    const tabs = ["overview", "live", "learning", "eam", "output", "waveform", "metrics", "settings"] as const;
    for (const id of tabs) {
      await page.getByTestId(`tab-${id}`).click();
      const body = await page.locator("body").innerText();
      for (const phrase of FORBIDDEN) {
        expect(body, `${id}: ${phrase}`).not.toContain(phrase);
      }
    }
  });
});
