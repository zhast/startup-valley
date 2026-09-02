import assert from "node:assert/strict";
import { mkdir, mkdtemp, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { JobPathGuard } from "../src/path-guard.js";

test("job path guard accepts rooted files and rejects traversal", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-path-"));
  const guard = new JobPathGuard(root);
  await guard.initialize();
  const target = await guard.resolve("notes/design.md", true);
  await writeFile(target, "hello", "utf8");
  assert.equal(await guard.resolve("notes/design.md"), target);
  await assert.rejects(() => guard.resolve("../escape.txt", true), /traversal/u);
  await assert.rejects(() => guard.resolve("/tmp/escape.txt", true), /Absolute/u);
  await assert.rejects(() => guard.resolve("C:\\escape.txt", true), /Absolute/u);
});

test("job path guard rejects symlink escapes", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-path-"));
  const outside = await mkdtemp(join(tmpdir(), "startup-valley-outside-"));
  await mkdir(join(root, "safe"));
  await symlink(outside, join(root, "safe", "link"));
  const guard = new JobPathGuard(root);
  await guard.initialize();
  await assert.rejects(() => guard.resolve("safe/link/secret.txt", true), /Symlink/u);
});
