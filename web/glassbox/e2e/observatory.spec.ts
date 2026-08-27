import { expect, test } from "@playwright/test";

test.describe("observatory", () => {
  test("four fixed regions, no competing tabs", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("obs-shell")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Native AI Observatory" })).toBeVisible();
    await expect(page.getByTestId("obs-pipeline")).toBeVisible();
    await expect(page.getByTestId("obs-chat")).toBeVisible();
    await expect(page.getByTestId("obs-footer")).toBeVisible();
    await expect(page.getByTestId("tab-overview")).toHaveCount(0);
    await expect(page.getByTestId("obs-legend")).toBeVisible();
  });

  test("silicon stages are BOARD; hang is STALL; tail is XSIM", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("stage-BOOT").getByTestId("badge-BOARD")).toBeVisible();
    await expect(page.getByTestId("stage-CORE_START").getByTestId("badge-STALL")).toBeVisible();
    await expect(page.getByTestId("stage-PRED_VALID").getByTestId("badge-XSIM")).toBeVisible();
    await expect(page.getByTestId("obs-watermark")).toHaveText("KHÔNG PHẢI DỮ LIỆU SILICON");
    await expect(page.getByTestId("obs-header").getByTestId("badge-ALERT")).toBeVisible();
  });

  test("does not claim pred=664 as silicon", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("obs-header")).toContainText("PRED");
    await expect(page.getByTestId("obs-header")).toContainText("∅");
    await expect(page.getByTestId("obs-header")).not.toContainText("664");
  });

  test("UART log is monospace hex + ascii from capture", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("obs-uart-ascii")).toContainText("CORE_START");
    await expect(page.getByTestId("obs-uart-hex")).toContainText("43 4F 52 45");
    const font = await page.getByTestId("obs-uart-hex").evaluate((el) => getComputedStyle(el).fontFamily);
    expect(font.toLowerCase()).toContain("jetbrains mono");
  });

  test("chat does not invent a board answer", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Sơ đồ thiết bị" })).toBeVisible({
      timeout: 20_000,
    });
    await page.getByLabel("Lệnh gửi tới FPGA").fill("pred bao nhiêu");
    await page.getByRole("button", { name: "Gửi" }).click();
    await expect(page.getByText("pred chưa phát trên UART")).toBeVisible();
    await expect(page.getByTestId("obs-chat")).not.toContainText("pred=664");
  });

  test("GlassBox charts are in the first viewport", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Sơ đồ thiết bị" })).toBeVisible({
      timeout: 20_000,
    });
    await expect(page.getByRole("heading", { name: "Sơ đồ thiết bị" })).toBeInViewport();
    await expect(page.getByRole("heading", { name: "Luồng xử lý" })).toBeInViewport();
    await expect(page.getByRole("heading", { name: "Tiến trình tương tác" })).toBeInViewport();
    await expect(page.getByText("Đọc", { exact: true }).first()).toBeVisible();
  });
});
