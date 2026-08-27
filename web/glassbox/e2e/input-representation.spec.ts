import { expect, test } from "@playwright/test";

/**
 * R2 units: Tab 3 Dữ liệu vào (§11) and Tab 4 Biểu diễn (§12).
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

async function openTab(page: import("@playwright/test").Page, id: "input" | "forward") {
  await page.goto("/studio");
  await expect(page.getByTestId("tab-input")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId(`tab-${id}`).click();
  await expect(page.getByTestId(`tab-${id}`)).toHaveAttribute("aria-current", "page");
}

test.describe("dữ liệu vào và biểu diễn", () => {
  test("byte strip comes from the recorded input, not invented tokens", async ({
    page,
  }) => {
    await openTab(page, "input");

    await expect(page.getByText("Board hiện tại dùng chip gì?").first()).toBeVisible();
    await expect(
      page.getByText("Mỗi ký tự được đổi thành số trước khi đi vào phần học của FPGA."),
    ).toBeVisible();

    const strip = page.getByRole("list", { name: "Dải byte đầu vào" });
    await expect(strip).toBeVisible();
    await strip.getByRole("listitem").nth(1).click();

    await expect(page.getByText("UTF-8")).toBeVisible();
    await expect(page.getByText(/E\[\d+\]/).first()).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("representation heatmap and 2D badge, no invented token ranking", async ({
    page,
  }) => {
    await openTab(page, "forward");

    await expect(page.getByRole("button", { name: "Trước khi học" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Sau khi học" })).toBeVisible();
    await expect(
      page.getByRole("img", { name: /Trạng thái nội bộ theo từng chiều/ }),
    ).toBeVisible();

    await page.getByRole("button", { name: "Research" }).first().click();
    await expect(page.getByText("MINH HỌA 2D").first()).toBeVisible();
    await expect(page.getByText("Pipeline suy luận")).toHaveCount(0);
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({
    page,
  }) => {
    await openTab(page, "input");
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-forward").click();
    await expect(page.getByTestId("tab-forward")).toHaveAttribute("aria-current", "page");
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });

  test("keyboard can reach the input tab and a byte cell", async ({ page }) => {
    await page.goto("/studio");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.locator("body").click();
    await page.keyboard.press("3");
    await expect(page.getByTestId("tab-input")).toHaveAttribute("aria-current", "page");
    await expect(page.getByRole("list", { name: "Dải byte đầu vào" })).toBeVisible();
    await page.getByRole("list", { name: "Dải byte đầu vào" }).getByRole("listitem").first().focus();
    await expect(
      page.getByRole("list", { name: "Dải byte đầu vào" }).getByRole("listitem").first(),
    ).toBeFocused();
  });
});
