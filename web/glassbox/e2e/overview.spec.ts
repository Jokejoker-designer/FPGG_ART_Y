import { expect, test } from "@playwright/test";

/**
 * Tab 1 Tổng quan (§9).
 *
 * The §9 acceptance test is "answer what the AI is doing in under five
 * seconds", which is not directly assertable. What is assertable: the four
 * things a reader needs are all present without scrolling, the event banner
 * only appears when a learning event backs it, and no parameter total is ever
 * rendered.
 *
 * Owner: gb-playwright-e2e.
 */

test.describe("tổng quan", () => {
  test("§9 shows the question, the pipeline, the state and the waterfall", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");

    await expect(
      page.getByRole("heading", { name: "Câu hỏi hiện tại" }),
    ).toBeVisible();
    await expect(page.getByText("Board hiện tại dùng chip gì?")).toBeVisible();

    const pipeline = page.getByRole("figure").first();
    await expect(pipeline.getByText("Tiến trình của tương tác này")).toBeVisible();

    await expect(page.getByRole("heading", { name: "Trạng thái" })).toBeVisible();
    /* The title appears twice by design: once as the visible figcaption and
       once as the caption of the §28 screen-reader table. */
    await expect(page.getByText("Thời gian từng chặng").first()).toBeVisible();
  });

  test("§9 the event banner appears only when a learning event backs it", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");
    await expect(page.getByText("AI vừa học từ tương tác này.")).toBeVisible();
    /* Exact and case-sensitive: the state panel label "Giá trị đã thay đổi" is
       a different string with a different job. */
    await expect(
      page.getByText("giá trị đã thay đổi", { exact: true }),
    ).toBeVisible();
    await expect(
      page.getByText(/Episode\s+#488271\s+đã được\s+cập nhật/),
    ).toBeVisible();

    /* 1841 has no learning event, so the claim must be absent entirely rather
       than softened into a different sentence. */
    await page.goto("/tong-quan?i=1841");
    await expect(page.getByText("AI vừa học từ tương tác này.")).toHaveCount(0);
  });

  test("§9 parameter counts are shown separately and never summed", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");

    await expect(page.getByText("802.816")).toBeVisible();
    await expect(page.getByText("9.216")).toBeVisible();

    /* a7-fpga-gate: the combined figure is a forbidden claim, in any format. */
    const text = await page.locator("body").innerText();
    for (const forbidden of ["812.032", "812032", "812,032", "1.6M", "1,6M"]) {
      expect(text.includes(forbidden), `summed figure "${forbidden}" rendered`).toBe(
        false,
      );
    }
  });

  test("§8.1 the waterfall reports a total and offers its values as a table", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");

    await expect(page.getByText(/tổng 93,9 ms|tổng 93.9 ms/)).toBeVisible();

    /* §28: chart values reachable as a table rather than only as geometry. */
    const table = page.getByRole("table", { name: /Thời gian từng chặng/ });
    await expect(table).toBeAttached();
    await expect(
      table.getByRole("rowheader", { name: "Mô hình" }),
    ).toBeAttached();
  });

  test("§26 a stage that never ran says so instead of drawing a zero", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1841");
    await expect(page.getByText("chưa có số đo").first()).toBeVisible();
    await expect(
      page.getByText("Chặng viền đỏ đã dừng vì lỗi, nên các chặng sau không chạy."),
    ).toBeVisible();
  });

  test("§25 the changed-value count carries its provenance", async ({ page }) => {
    await page.goto("/tong-quan?i=1842");

    const statePanel = page
      .getByRole("heading", { name: "Trạng thái" })
      .locator("../..");
    await expect(
      statePanel.getByText("Giá trị đã thay đổi", { exact: true }),
    ).toBeVisible();
    await expect(
      statePanel.getByText(/DERIVED|SYNTHETIC/).first(),
    ).toBeVisible();
  });

  test("§6.3 moving to the conversation keeps the same interaction", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");
    await page.getByRole("link", { name: "Xem cuộc trò chuyện" }).click();
    await expect(page).toHaveURL(/\/tuong-tac\?i=1842$/);
    await expect(page.getByText("Tương tác #1842").first()).toBeVisible();
  });

  test("§9 no pipeline stage is a control without a destination", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");

    /* No phase-owning tab exists yet, so every stage must be inert text. Once
       R2 lands Dữ liệu vào this expectation flips and the test must be updated
       deliberately rather than silently passing. */
    const pipeline = page.getByRole("figure").first();
    await expect(pipeline.getByRole("link")).toHaveCount(0);
  });
});
