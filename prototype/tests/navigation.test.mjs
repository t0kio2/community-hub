import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

test("ログインユーザー領域からメンバー画面へリンクする", async () => {
  const html = await readFile(new URL("../tenant.html", import.meta.url), "utf8");

  assert.match(html, /<a class="account-card" href="#members"/);
});
