import { expect, test } from "@playwright/test";

/**
 * R3 units: Tab 5 So sánh (§13) and Tab 6 Học (§14).
 * Runs against the TanStack shell on fixtures. Owner: gb-playwright-e2e.
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

async function openTab(page: import("@playwright/test").Page, id: "compare" | "learning") {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId(`tab-${id}`).click();
  await expect(page.getByTestId(`tab-${id}`)).toHaveAttribute("aria-current", "page");
}

test.describe("so sánh và học", () => {
  test("compare uses recorded A/P/N and violated, not margin sign", async ({ page }) => {
    await openTab(page, "compare");

    await expect(page.getByText("FPGA nào đang dùng?").first()).toBeVisible();
    await expect(page.getByText("Board hiện tại dùng chip gì?").first()).toBeVisible();
    await expect(page.getByText("Giá máy lạnh bao nhiêu?").first()).toBeVisible();
    await expect(page.getByText("Cần học thêm").first()).toBeVisible();
    await expect(page.getByText("1320").first()).toBeVisible();
    await expect(page.getByText("4810").first()).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("research labels cosine as ĐO / EVAL and does not invent dH", async ({ page }) => {
    await openTab(page, "compare");
    await page.getByRole("button", { name: "Research" }).first().click();
    await expect(page.getByText("ĐO / EVAL").first()).toBeVisible();
    await expect(page.getByText("không dùng").first()).toBeVisible();
    await expect(page.getByText("gradient", { exact: false })).toHaveCount(0);
  });

  test("learning shows write facts and a clickable timeline, no gradient column", async ({
    page,
  }) => {
    await openTab(page, "learning");

    await expect(page.getByRole("img", { name: /Ma trận Δ Wh 32 nhân 32/ })).toBeVisible();
    await expect(page.getByText("Nhật ký ghi")).toBeVisible();
    await expect(page.getByRole("columnheader", { name: "trước" })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: "Δ" })).toBeVisible();
    await expect(page.getByRole("columnheader", { name: "sau" })).toBeVisible();
    await expect(page.getByText("Không vẽ gradient giả")).toBeVisible();

    const step = page.getByRole("button", { name: /Vi phạm ngưỡng/ });
    await expect(step).toBeVisible();
    await step.click();
    await expect(page.getByText("Đang chọn: Vi phạm ngưỡng")).toBeVisible();
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({ page }) => {
    await openTab(page, "compare");
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-learning").click();
    await expect(page.getByTestId("tab-learning")).toHaveAttribute("aria-current", "page");
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });

  test("keyboard 5 and 6 open compare then learning", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.locator("body").click();
    await page.keyboard.press("5");
    await expect(page.getByTestId("tab-compare")).toHaveAttribute("aria-current", "page");
    await page.keyboard.press("6");
    await expect(page.getByTestId("tab-learning")).toHaveAttribute("aria-current", "page");
  });
});
