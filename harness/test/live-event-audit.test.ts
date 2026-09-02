import assert from "node:assert/strict";
import test from "node:test";

import { auditLiveEvents } from "../src/live-event-audit.js";
import type { WorkerEvent } from "../src/types.js";

test("live audit accepts early zero-usage events and selects post-tool usage", () => {
  const events: WorkerEvent[] = [
    { type: "job.started" },
    { type: "agent.thinking" },
    { type: "usage.updated", inputTokens: 0, outputTokens: 0, cost: 0 },
    { type: "tool.started", tool: "write_file", label: "Write file" },
    { type: "artifact.created", artifactId: "artifact-1", name: "hello.md" },
    { type: "tool.completed", tool: "write_file", ok: true },
    { type: "usage.updated", inputTokens: 827, outputTokens: 52, cost: 0.000854 },
    { type: "job.completed", summary: "Delivered hello.md" },
  ];

  assert.deepEqual(auditLiveEvents(events), events[6]);
});
