import { expect, test } from "@playwright/test";

/**
 * R5 units: Tab 9 Đầu ra (§17) and Tab 10 Sóng FPGA (§18).
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

async function openTab(page: import("@playwright/test").Page, id: "output" | "waveform") {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
  await page.getByTestId(`tab-${id}`).click();
  await expect(page.getByTestId(`tab-${id}`)).toHaveAttribute("aria-current", "page");
}

test.describe("đầu ra và sóng FPGA", () => {
  test("output tokens and Artix probability come from recorded events", async ({ page }) => {
    await openTab(page, "output");

    await expect(page.getByText("Arty A7 sử dụng FPGA Artix-7.").first()).toBeVisible();
    await page.getByRole("list", { name: "Dòng token đầu ra" }).getByRole("listitem").filter({ hasText: "Artix" }).click();
    await expect(page.getByText("72%")).toBeVisible();
    await expect(page.getByText("SELECTED")).toBeVisible();
    await expect(page.getByText(/8\.223\.401|8223401/)).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);

    await page.getByRole("button", { name: "Xem vì sao token này xuất hiện" }).click();
    await expect(page.getByText("Episode #488271")).toBeVisible();
  });

  test("waveform is SYNTHETIC fixture, not LiteScope hardware", async ({ page }) => {
    await openTab(page, "waveform");

    await expect(page.getByText("BOARD / LiteScope")).toHaveCount(0);
    await expect(page.getByRole("img", { name: "Sóng số từ bản ghi SYNTHETIC" })).toBeVisible();
    await expect(page.getByRole("list", { name: "Mốc sự kiện" })).toBeVisible();
    await page.getByRole("button", { name: "Vi phạm ngưỡng phân biệt" }).click();
    await expect(page.getByText("2.260")).toBeVisible();
    await expect(page.getByText("Không có LiteScope trên bit này")).toBeVisible();
  });

  test("forbidden copy is absent on both units at 1440 and 1280", async ({ page }) => {
    await openTab(page, "output");
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }

    await page.getByTestId("tab-waveform").click();
    await expect(page.getByTestId("tab-waveform")).toHaveAttribute("aria-current", "page");
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });

  test("keyboard 9 opens đầu ra", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
    await page.locator("body").click();
    await page.keyboard.press("9");
    await expect(page.getByTestId("tab-output")).toHaveAttribute("aria-current", "page");
  });
});
