import { expect, test } from "@playwright/test";

/**
 * R7 units: Tab 13 Bằng chứng (§21) and Giải thích (§22).
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
  "Silicon pass",
];

async function openEvidence(page: import("@playwright/test").Page) {
  await page.goto("/studio");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId("tab-evidence").click();
  await expect(page.getByTestId("tab-evidence")).toHaveAttribute("aria-current", "page");
}

test.describe("bằng chứng và giải thích", () => {
  test("1842 is fully traceable and never styled as BOARD silicon", async ({ page }) => {
    await openEvidence(page);

    await expect(page.getByText("MÔ HÌNH / TWIN MODE")).toBeVisible();
    await expect(page.getByText("Dữ liệu hiện tại không phải silicon evidence.")).toBeVisible();
    await expect(page.getByText("FULLY_TRACEABLE").first()).toBeVisible();
    await expect(page.getByTestId("evidence-table").getByText("M_L1")).toBeVisible();
    await expect(page.getByTestId("evidence-table").getByText("DERIVED").first()).toBeVisible();
    await expect(page.getByTestId("evidence-table").getByText("Gradient estimate")).toBeVisible();
    await expect(page.getByText("eam03e-a0-signsgd-v1")).toBeVisible();
    await expect(page.getByText("không có ở lane này")).toBeVisible();
    await expect(page.getByText("litescope", { exact: false })).toHaveCount(0);
    await expect(page.getByText("BOARD PASS")).toHaveCount(0);
  });

  test("1841 is only partially traceable", async ({ page }) => {
    await openEvidence(page);

    await page.getByTestId("evidence-interaction").selectOption("1841");
    await expect(page.getByText("PARTIALLY_TRACEABLE").first()).toBeVisible();
    await expect(page.getByTestId("evidence-trace").getByText("Thiếu").first()).toBeVisible();
    await expect(page.getByTestId("evidence-table").getByText("d_pos")).toBeVisible();
  });

  test("Giải thích uses live collapsed rank, not the stale glossary", async ({ page }) => {
    await page.goto("/studio");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.getByTestId("tab-metrics").click();
    await page.getByRole("button", { name: "Giải thích" }).first().click();
    await expect(page.getByRole("dialog")).toContainText("AUC = 0.500");
    await expect(page.getByRole("dialog")).not.toContainText("0.742");
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({ page }) => {
    await openEvidence(page);
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-metrics").click();
    await page.getByRole("button", { name: "Giải thích" }).first().click();
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });
});
