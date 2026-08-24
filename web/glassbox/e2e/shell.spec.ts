import { expect, test } from "@playwright/test";

/**
 * R0 units under test: the app shell (§6) and the interaction lock (§6.3).
 *
 * These assert on user-visible text and roles rather than on CSS classes, and
 * they run entirely on fixtures. The lock invariant is the one most likely to
 * regress silently as tabs land, which is why it is pinned first.
 *
 * Owner: gb-playwright-e2e.
 */

/** §32 and §30. Anything in this list appearing on screen is a defect. */
const FORBIDDEN = [
  "Lorem ipsum",
  "Feature 1",
  "TODO",
  "Developer note",
  "Mockup",
  "bộ não AI",
  "AI suy nghĩ",
  "ý thức",
  "AI biết chắc",
];

test.describe("shell", () => {
  test("picker offers the recorded interactions and states its data source", async ({
    page,
  }) => {
    await page.goto("/");

    await expect(
      page.getByRole("heading", { name: "Chọn một tương tác để xem bên trong" }),
    ).toBeVisible();

    /* §26 and §32.17: a fixture session must never read as a live board. */
    await expect(page.getByText("FPGA CHƯA KẾT NỐI")).toBeVisible();
    await expect(page.getByText("NGUỒN SYNTHETIC")).toBeVisible();

    await expect(
      page.getByRole("link", { name: /Board hiện tại dùng chip gì/ }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: /Board này có bao nhiêu chân GPIO/ }),
    ).toBeVisible();
  });

  test("choosing an interaction locks the shell to it", async ({ page }) => {
    await page.goto("/");
    await page
      .getByRole("link", { name: /Board hiện tại dùng chip gì/ })
      .click();

    await expect(page).toHaveURL(/\?i=1842$/);
    await expect(page.getByText("Tương tác #1842").first()).toBeVisible();
    await expect(
      page.getByText("Mọi tab đang khóa theo tương tác này"),
    ).toBeVisible();
  });

  test("the locked interaction survives a reload, so a link is shareable", async ({
    page,
  }) => {
    await page.goto("/?i=1842");
    await page.reload();
    await expect(page.getByText("Tương tác #1842").first()).toBeVisible();
  });

  test("§24 traceability is reported per interaction, not assumed", async ({
    page,
  }) => {
    await page.goto("/?i=1842");
    await expect(page.getByText("TRACE ĐẦY ĐỦ").first()).toBeVisible();

    await page.goto("/?i=1841");
    await expect(page.getByText("TRACE CHƯA ĐẦY ĐỦ").first()).toBeVisible();
  });

  test("§25 every displayed metric carries a provenance badge", async ({
    page,
  }) => {
    /* `/` redirects to Tab 1 once an interaction is chosen, so the state panel
       there is where the shell's metrics now live. */
    await page.goto("/tong-quan?i=1842");

    const statePanel = page
      .getByRole("heading", { name: "Trạng thái" })
      .locator("../..");
    await expect(statePanel.getByText("Giá trị đã thay đổi")).toBeVisible();
    await expect(statePanel.getByText("Token đã sinh")).toBeVisible();
    await expect(
      statePanel.getByText(/DERIVED|SYNTHETIC/).first(),
    ).toBeVisible();

    /* Nothing in this phase may claim silicon evidence. */
    await expect(page.getByText("BOARD", { exact: true })).toHaveCount(0);
  });

  test("§6.3 choosing an interaction on / hands off to Tab 1 with the id intact", async ({
    page,
  }) => {
    await page.goto("/?i=1842");
    await expect(page).toHaveURL(/\/tong-quan\?i=1842$/);
  });

  test("§6.2 the process strip reports every stage with its duration", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");
    const strip = page.getByRole("navigation", {
      name: "Tiến trình xử lý của một tương tác",
    });

    for (const label of [
      "Đọc",
      "Biểu diễn",
      "So sánh",
      "Học",
      "Bộ nhớ",
      "Mô hình",
      "Trả lời",
    ]) {
      await expect(strip.getByText(label, { exact: true })).toBeVisible();
    }
    await expect(strip.getByText("61.2 ms", { exact: true })).toBeVisible();

    /* §28: the same figure is available to a screen reader as a sentence, not
       as a bare number next to a colour. */
    await expect(
      strip.getByText("Mô hình: xong, 61.2 mili giây"),
    ).toBeAttached();
  });

  test("§26 a stage with no measurement says so instead of showing zero", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1841");
    const strip = page.getByRole("navigation", {
      name: "Tiến trình xử lý của một tương tác",
    });
    await expect(strip.getByText("đang chờ").first()).toBeVisible();
  });

  test("§27 no horizontal overflow at this project's viewport", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth,
    );
    expect(overflow).toBe(false);
  });

  test("§30 and §32 forbidden copy appears nowhere", async ({ page }) => {
    /* Every route that exists today. This list grows with each round; a new
       tab that is not listed here is not covered. */
    for (const path of [
      "/",
      "/tong-quan?i=1842",
      "/tong-quan?i=1841",
      "/tuong-tac?i=1842",
      "/tuong-tac?i=1841",
    ]) {
      await page.goto(path);
      const text = await page.locator("body").innerText();
      for (const phrase of FORBIDDEN) {
        expect(
          text.toLowerCase().includes(phrase.toLowerCase()),
          `"${phrase}" found on ${path}`,
        ).toBe(false);
      }
    }
  });

  test("§28 the document declares Vietnamese and a reachable focus target", async ({
    page,
  }) => {
    await page.goto("/");
    await expect(page.locator("html")).toHaveAttribute("lang", "vi");

    await page.keyboard.press("Tab");
    const focused = await page.evaluate(
      () => document.activeElement?.tagName ?? null,
    );
    expect(focused).not.toBeNull();
  });

  test("§28 every interaction on the picker is reachable by keyboard alone", async ({
    page,
  }) => {
    await page.goto("/");

    /* Walk the tab order and collect what a keyboard user can actually reach,
       rather than counting anchors in the DOM. */
    const reached = new Set<string>();
    for (let i = 0; i < 12; i += 1) {
      await page.keyboard.press("Tab");
      const href = await page.evaluate(() => {
        const el = document.activeElement as HTMLAnchorElement | null;
        return el?.getAttribute("href") ?? null;
      });
      if (href) reached.add(href);
    }

    expect(reached).toContain("/?i=1842");
    expect(reached).toContain("/?i=1841");
  });

  test("§28 the focused control has a visible focus indicator", async ({
    page,
  }) => {
    await page.goto("/");
    await page.keyboard.press("Tab");

    const outline = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el) return null;
      const style = getComputedStyle(el);
      return { width: style.outlineWidth, style: style.outlineStyle };
    });

    expect(outline).not.toBeNull();
    expect(outline?.style).not.toBe("none");
    expect(parseFloat(outline?.width ?? "0")).toBeGreaterThanOrEqual(2);
  });

  /**
   * §28 reduced motion. R0 could not verify this because nothing animated yet.
   * R1 introduces the §8.1 stage pulse, so the mechanism is now testable.
   *
   * The fixtures are all `complete`, so no live page has an animating stage.
   * These tests therefore assert the stylesheet rule itself against a probe
   * element carrying the real class. That proves the cascade collapses the
   * animation; it does not prove any particular screen animates, which is the
   * point — the pulse is state-driven, not decorative.
   */
  test.describe("reduced motion", () => {
    const probeDuration = async (page: import("@playwright/test").Page) =>
      page.evaluate(() => {
        const probe = document.createElement("span");
        probe.className = "gb-stage-active";
        document.body.append(probe);
        const duration = getComputedStyle(probe).animationDuration;
        probe.remove();
        return duration;
      });

    test("the stage pulse runs when motion is allowed", async ({ page }) => {
      await page.goto("/tong-quan?i=1842");
      expect(await probeDuration(page)).toBe("1.4s");
    });

    /**
     * `emulateMedia` rather than a `test.use({ reducedMotion })` block: the
     * fixture form did not reach the page here, and a silently ineffective
     * emulation would have made this test pass for the wrong reason. The
     * matchMedia assertion below is what proves the emulation actually landed.
     */
    test("the stage pulse is collapsed, not merely shortened", async ({
      page,
    }) => {
      await page.goto("/tong-quan?i=1842");
      await page.emulateMedia({ reducedMotion: "reduce" });

      const matched = await page.evaluate(
        () => window.matchMedia("(prefers-reduced-motion: reduce)").matches,
      );
      expect(matched, "emulation did not reach the page").toBe(true);

      const duration = await probeDuration(page);
      expect(parseFloat(duration)).toBeLessThan(0.001);
    });
  });

  test("§28 the locked view keeps a keyboard route back to the picker", async ({
    page,
  }) => {
    await page.goto("/tong-quan?i=1842");

    let reachedPicker = false;
    for (let i = 0; i < 12; i += 1) {
      await page.keyboard.press("Tab");
      const href = await page.evaluate(
        () => document.activeElement?.getAttribute("href") ?? null,
      );
      if (href === "/") reachedPicker = true;
    }

    expect(reachedPicker).toBe(true);
  });
});
