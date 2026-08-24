import { expect, test } from "@playwright/test";

/**
 * R8 units: §26 states and §27/§28 responsive + accessibility.
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

async function ready(page: import("@playwright/test").Page) {
  await page.goto("/");
  await expect(page.getByTestId("tab-overview")).toBeVisible({ timeout: 15_000 });
}

test.describe("trạng thái, layout và a11y", () => {
  test("disconnected banner opens recorded session, never fake live numbers", async ({ page }) => {
    await ready(page);

    await expect(page.getByTestId("studio-state-disconnected")).toBeVisible();
    await expect(page.getByText("FPGA chưa kết nối")).toBeVisible();
    await page.getByRole("button", { name: "Mở session" }).click();
    await expect(page.getByTestId("tab-experiments")).toHaveAttribute("aria-current", "page");
    await expect(page.getByText("Không bịa Interaction #500")).toBeVisible();
  });

  test("waveform 1841 is an empty capture, not a drawn fake wave", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-waveform").click();
    await page.getByTestId("waveform-interaction").selectOption("1841");
    await expect(page.getByTestId("studio-state-no-waveform")).toBeVisible();
    await expect(page.getByText("Không có waveform cho tương tác này")).toBeVisible();
    await expect(page.getByText("Capture không được bật khi sự kiện xảy ra.")).toBeVisible();
    await page.getByRole("button", { name: "Bật capture cho lần sau" }).click();
    await expect(page.getByText("Đã ghi yêu cầu capture cho lần sau")).toBeVisible();
    await expect(page.getByText("LiteScope groups")).toHaveCount(0);
  });

  test("partial trace banner appears on 1841 evidence", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-evidence").click();
    await page.getByTestId("evidence-interaction").selectOption("1841");
    await expect(page.getByTestId("studio-state-partial-trace")).toBeVisible();
    await expect(page.getByText("Trace chưa đầy đủ")).toBeVisible();
  });

  test("bracket keys reach Bằng chứng and skip link targets main", async ({ page }) => {
    await ready(page);
    await page.keyboard.press("]");
    await expect(page.getByTestId("tab-live")).toHaveAttribute("aria-current", "page");
    for (let i = 0; i < 12; i += 1) await page.keyboard.press("]");
    await expect(page.getByTestId("tab-evidence")).toHaveAttribute("aria-current", "page");

    await page.getByTestId("skip-to-main").focus();
    await page.keyboard.press("Enter");
    await expect(page.locator("#gb-main")).toBeFocused();
  });

  test("1280 uses an insight drawer; 1440 keeps the rail open", async ({ page }, testInfo) => {
    await ready(page);
    const width = testInfo.project.use.viewport?.width ?? 0;
    if (width >= 1440) {
      await expect(page.getByTestId("open-insight")).toBeHidden();
      await expect(page.getByTestId("insight-rail")).toBeVisible();
    } else {
      await expect(page.getByTestId("open-insight")).toBeVisible();
      await page.getByTestId("open-insight").click();
      await expect(page.getByTestId("insight-rail")).toBeVisible();
      await expect(page.getByRole("heading", { name: "Insight nhanh" })).toBeVisible();
    }
  });

  test("health chart values are a table and reduced-motion is honored", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-metrics").click();
    await page.getByTestId("health-table-toggle").click();
    await expect(page.getByTestId("health-value-table")).toContainText("512");
    await expect(page.getByTestId("health-value-table")).toContainText("0.5");

    await page.emulateMedia({ reducedMotion: "reduce" });
    const motion = await page.evaluate(() => {
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const probe = document.createElement("div");
      probe.className = "gbx-active";
      document.body.appendChild(probe);
      const value = getComputedStyle(probe).animationDuration;
      probe.remove();
      return { reduce, value };
    });
    expect(motion.reduce).toBe(true);
    const seconds = Number.parseFloat(motion.value);
    expect(Number.isFinite(seconds) && seconds < 0.05).toBeTruthy();
  });

  test("waveform cursor moves with arrow keys", async ({ page }) => {
    await ready(page);
    await page.getByTestId("tab-waveform").click();
    const cursor = page.getByTestId("waveform-cursor");
    await expect(cursor).toBeVisible();
    await cursor.focus();
    const before = await cursor.getAttribute("aria-valuenow");
    await page.keyboard.press("ArrowRight");
    const after = await cursor.getAttribute("aria-valuenow");
    expect(Number(after)).toBeGreaterThan(Number(before));
  });

  test("forbidden copy is absent on both units", async ({ page }) => {
    await ready(page);
    let body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
    await page.getByTestId("tab-waveform").click();
    body = await page.locator("body").innerText();
    for (const phrase of FORBIDDEN) {
      expect(body, phrase).not.toContain(phrase);
    }
  });
});
