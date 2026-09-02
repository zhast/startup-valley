import assert from "node:assert/strict";
import test from "node:test";

import { parseJobSpec, parseRequest } from "../src/validation.js";

test("protocol and job schemas accept a bounded work order", () => {
  const spec = parseJobSpec({
    jobId: "job-1",
    employeeId: "mira",
    projectId: "company",
    title: "Design note",
    assignment: "Write a design note",
    acceptanceCriteria: ["A Markdown file exists"],
    tokenBudget: 4000,
    attachedStudioPath: "references/design-note.md",
  });
  const request = parseRequest({ kind: "request", id: "1", method: "job.start", params: { spec } });
  assert.equal(request.method, "job.start");
  assert.equal(spec.attachedStudioPath, "references/design-note.md");
});

test("schemas reject unbounded or misshapen input", () => {
  assert.throws(
    () => parseJobSpec({ jobId: "../bad", employeeId: "mira", projectId: "company", assignment: "x", acceptanceCriteria: [], tokenBudget: 12 }),
    /Invalid job specification/u,
  );
  assert.throws(() => parseRequest({ kind: "request", id: "1", method: "shell", params: {} }), /Invalid protocol request/u);
});
