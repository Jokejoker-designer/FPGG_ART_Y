import { expect, test } from "@playwright/test";

/**
 * R6 units: Tab 11 Sức khỏe (§19) and Tab 12 Replay (§20).
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
];

async function openTab(page: import("@playwright/test").Page, id: "metrics" | "experiments") {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId(`tab-${id}`).click();
  await expect(page.getByTestId(`tab-${id}`)).toHaveAttribute("aria-current", "page");
}

test.describe("sức khỏe và replay", () => {
  test("health verdict is collapse and beating baselines stay visible", async ({ page }) => {
    await openTab(page, "metrics");

    await expect(page.getByText("Cảnh báo: Representation Collapse")).toBeVisible();
    await expect(page.getByText("ĐÃ SỤP").first()).toBeVisible();
    await expect(page.getByText("Histogram byte L1")).toBeVisible();
    await expect(page.getByText("0.880")).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("replay compares recorded 1841 and 1842, not invented #500", async ({ page }) => {
    await openTab(page, "experiments");

    await expect(page.getByText("Không bịa Interaction #500")).toBeVisible();
    await expect(page.getByRole("combobox").first()).toHaveValue("1841");
    await expect(page.getByText("MISS").first()).toBeVisible();
    await expect(page.getByText("#488271").first()).toBeVisible();
    await expect(page.getByText("1320").first()).toBeVisible();
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({ page }) => {
    await openTab(page, "metrics");
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-experiments").click();
    await expect(page.getByTestId("tab-experiments")).toHaveAttribute("aria-current", "page");
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });
});
