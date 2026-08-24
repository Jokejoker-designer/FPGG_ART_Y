import { expect, test } from "@playwright/test";

/**
 * Tab 2 Tương tác (§10).
 *
 * §10's first requirement is that this reads as a product, so the assertions
 * are about the conversation and its metadata being legible, and about the
 * absence cases telling the truth rather than showing an empty bubble.
 *
 * Owner: gb-playwright-e2e.
 */

test.describe("tương tác", () => {
  test("§10 shows the question, the answer and the message metadata", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1842");

    await expect(page.getByText("Board hiện tại dùng chip gì?")).toBeVisible();
    await expect(page.getByText("Arty A7 sử dụng FPGA Artix-7.")).toBeVisible();
    await expect(page.getByText("token").first()).toBeVisible();
    /* Also present in the inspector as "Tìm thấy Episode #488271", so the
       metadata line is matched exactly. */
    await expect(
      page.getByText("Episode #488271", { exact: true }),
    ).toBeVisible();
    await expect(page.getByText("ĐÃ HỌC")).toBeVisible();
  });

  test("§26 an interaction with no answer says why instead of showing nothing", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1841");

    await expect(
      page.getByText("Tương tác này chưa tạo ra câu trả lời."),
    ).toBeVisible();
    await expect(
      page.getByText(
        "Chặng mô hình đã dừng giữa tiến trình, nên không có token nào được sinh.",
      ),
    ).toBeVisible();
    await expect(page.getByText("KHÔNG CẦN HỌC THÊM")).toBeVisible();
  });

  test("§10 the inspector reports mode, teacher, memory and evidence source", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1842");

    const inspector = page
      .getByRole("heading", { name: "Bên trong tương tác này" })
      .locator("../..");

    await expect(inspector.getByText("Chế độ")).toBeVisible();
    await expect(inspector.getByText("Đang huấn luyện")).toBeVisible();
    await expect(inspector.getByText("Teacher")).toBeVisible();
    await expect(inspector.getByText("Kết quả bộ nhớ")).toBeVisible();
    await expect(
      inspector.getByText("Tìm thấy Episode #488271"),
    ).toBeVisible();
    await expect(inspector.getByText("Nguồn bằng chứng")).toBeVisible();
  });

  test("§10 a memory miss is distinct from no memory access", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1841");
    await expect(
      page.getByText("Không tìm thấy ký ức phù hợp"),
    ).toBeVisible();
  });

  test("§24 the inspector states how much evidence is missing", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1841");
    await expect(page.getByText("TRACE CHƯA ĐẦY ĐỦ").first()).toBeVisible();
    await expect(
      page.getByText(/Thiếu bằng chứng cho/),
    ).toBeVisible();

    await page.goto("/tuong-tac?i=1842");
    await expect(page.getByText(/Thiếu bằng chứng cho/)).toHaveCount(0);
  });

  test("§10 the primary call to action opens the inside of this interaction", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1842");
    await page
      .getByRole("link", { name: "Xem bên trong tương tác này" })
      .click();
    await expect(page).toHaveURL(/\/tong-quan\?i=1842$/);
  });

  test("§6.3 earlier interactions in the session stay navigable", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1842");
    await expect(
      page.getByRole("heading", {
        name: "Các tương tác trước trong phiên này",
      }),
    ).toBeVisible();

    await page
      .getByRole("link", { name: /Board này có bao nhiêu chân GPIO/ })
      .click();
    await expect(page).toHaveURL(/\/tuong-tac\?i=1841$/);
  });

  test("§25 every metric beside the message carries a provenance badge", async ({
    page,
  }) => {
    await page.goto("/tuong-tac?i=1842");

    /* The latency figure is DERIVED from the stage timings; the token count is
       SYNTHETIC in this phase. Neither may appear bare. */
    await expect(page.getByText("DERIVED").first()).toBeVisible();
    await expect(page.getByText("SYNTHETIC").first()).toBeVisible();
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });
});
