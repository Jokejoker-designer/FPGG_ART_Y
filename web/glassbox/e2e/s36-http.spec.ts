import { expect, test } from "@playwright/test";

/**
 * SPEC §36 on the HTTP adapter + SYNTHETIC backend (ids 9001 / 9000).
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
];

async function ready(page: import("@playwright/test").Page) {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 20_000 });
}

test.describe("§36 HTTP adapter", () => {
  test("hydrate shows backend interaction 9001, not fixture 1842", async ({ page }) => {
    await ready(page);
    await expect(page.getByRole("banner").getByText("#9001")).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await page.getByRole("banner").getByRole("button", { name: "Research" }).click();
    await expect(page.getByText("Không có — lane này không có mô hình ngôn ngữ")).toBeVisible();
    await expect(page.getByText("Arty A7 sử dụng FPGA Artix-7.")).toHaveCount(0);
    await page.getByTestId("tab-live").click();
    await expect(page.getByText("Board hiện tại dùng chip gì?").first()).toBeVisible();
    await expect(page.getByText("ILA Basic")).toHaveCount(0);
  });

  test("research numbers and collapse come from the service", async ({ page }) => {
    await ready(page);
    await page.getByRole("banner").getByRole("button", { name: "Research" }).click();
    await page.getByTestId("tab-compare").click();
    await expect(page.getByText("1400").first()).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await page.getByTestId("tab-metrics").click();
    await expect(page.getByText("Cảnh báo: Representation Collapse")).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("waveform 9001 draws; 9000 is an absence", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-waveform").click();
    await expect(page.getByTestId("waveform-cursor")).toBeVisible({ timeout: 10_000 });
    await page.getByTestId("waveform-interaction").selectOption("9000");
    await expect(page.getByText("Không có waveform cho tương tác này")).toBeVisible();
  });

  test("learning writes and memory funnel stay on 9001", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-learning").click();
    await expect(page.getByRole("columnheader", { name: "trước" })).toBeVisible();
    await page.getByTestId("tab-eam").click();
    await expect(page.getByText("ep-syn-12").first()).toBeVisible();
    await expect(page.getByTestId("tab-episode")).toHaveCount(0);
  });

  test("output absence is shown; settings stay SYNTHETIC", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-output").click();
    await expect(page.getByText("Chưa có đầu ra")).toBeVisible();
    await page.getByTestId("tab-settings").click();
    await expect(page.locator("#gb-main").getByText("SYNTHETIC", { exact: true })).toBeVisible();
    await expect(page.getByText("chưa kết nối", { exact: true })).toBeVisible();
    await expect(page.getByText("#9001").first()).toBeVisible();
  });

  test("forbidden mockup copy is absent at both viewports", async ({ page }) => {
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
