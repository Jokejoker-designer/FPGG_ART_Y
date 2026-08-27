import { expect, test } from "@playwright/test";

/**
 * R4 units: Tab 7 Bộ nhớ (§15) and Tab 8 Mô hình (§16).
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

async function openTab(page: import("@playwright/test").Page, id: "eam" | "model") {
  await page.goto("/studio");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId(`tab-${id}`).click();
  await expect(page.getByTestId(`tab-${id}`)).toHaveAttribute("aria-current", "page");
}

test.describe("bộ nhớ và mô hình", () => {
  test("funnel uses recorded stages and does not invent cue labels", async ({ page }) => {
    await openTab(page, "eam");

    await expect(page.getByRole("heading", { name: "Phễu truy hồi" })).toBeVisible();
    await expect(page.getByText("800.000", { exact: true })).toBeVisible();
    await expect(page.getByText("Postings khớp cue")).toBeVisible();
    await expect(page.getByText("#488271").first()).toBeVisible();
    await expect(page.getByText("HIT", { exact: true })).toBeVisible();
    await expect(page.getByText("chip FPGA board")).toHaveCount(0);
    await expect(page.getByText("Cue binding")).toHaveCount(0);
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
    await expect(page.getByText(/Không vẽ page\/block giả/)).toBeVisible();
  });

  test("model pipeline and Layer 1 come from recorded events", async ({ page }) => {
    await openTab(page, "model");

    await expect(
      page.getByText("Embedding → Layer 1 → Attention → Layer 2 → Memory context → LM head"),
    ).toBeVisible();
    await expect(page.getByText("Episode #488271 → Context → Model")).toBeVisible();
    await expect(page.getByText("14.2 ms").first()).toBeVisible();

    await page.getByRole("button", { name: "Research" }).first().click();
    await expect(page.getByText("18.240").first()).toBeVisible();
    await expect(page.getByText("Không phải “AI đang nghĩ”")).toBeVisible();
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({ page }) => {
    await openTab(page, "eam");
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-model").click();
    await expect(page.getByTestId("tab-model")).toHaveAttribute("aria-current", "page");
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });

  test("keyboard 7 and 8 open memory then model", async ({ page }) => {
    await page.goto("/studio");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.locator("body").click();
    await page.keyboard.press("7");
    await expect(page.getByTestId("tab-eam")).toHaveAttribute("aria-current", "page");
    await page.keyboard.press("8");
    await expect(page.getByTestId("tab-model")).toHaveAttribute("aria-current", "page");
  });
});
