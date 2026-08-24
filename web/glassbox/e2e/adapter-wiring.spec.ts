import { expect, test } from "@playwright/test";

/**
 * Adapter boundary after BACKEND_PASS. Default transport is fixture.
 * Components must not open a WebSocket. Settings reads ConnectionState
 * from ports via the store.
 *
 * Owner: gb-playwright-e2e.
 */
test.describe("adapter wiring (fixture default)", () => {
  test("hydrate through ports; settings shows SYNTHETIC and no serial", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.getByTestId("tab-settings").click();
    await expect(page.getByRole("heading", { name: "Nguồn dữ liệu" })).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await expect(page.getByText("chưa kết nối", { exact: true })).toBeVisible();
    await expect(page.locator("#gb-main").getByText("#1842", { exact: true })).toBeVisible();
    await expect(page.getByText("LiteScope capture groups")).toHaveCount(0);
  });
});
