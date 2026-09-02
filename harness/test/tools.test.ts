import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { ApprovalBroker } from "../src/approval-broker.js";
import { createJobTools } from "../src/tools.js";
import type { Artifact } from "../src/types.js";

test("Pi receives only the constrained tool allowlist and writes a real artifact", async () => {
  const jobRoot = await mkdtemp(join(tmpdir(), "startup-valley-tools-"));
  const artifacts: Artifact[] = [];
  const tools = await createJobTools({
    jobId: "job-1",
    jobRoot,
    approvalBroker: new ApprovalBroker(),
    onArtifact: (artifact) => artifacts.push(artifact),
    onApproval: () => {},
  });
  assert.deepEqual(
    tools.map((tool) => tool.name),
    [
      "read_file",
      "write_file",
      "edit_file",
      "list_files",
      "search_files",
      "web_search",
      "web_fetch",
      "create_artifact",
      "request_player_approval",
    ],
  );
  assert.equal(tools.some((tool) => tool.name === "bash" || tool.name === "powershell"), false);
  const writeTool = tools.find((tool) => tool.name === "write_file");
  assert.ok(writeTool);
  await writeTool.execute(
    "call-1",
    { path: "design-note.md", content: "# Design note\n\nA real file." },
    undefined,
    undefined,
    {} as never,
  );
  assert.equal(await readFile(join(jobRoot, "design-note.md"), "utf8"), "# Design note\n\nA real file.");
  assert.equal(artifacts[0]?.relativePath, "design-note.md");
});
