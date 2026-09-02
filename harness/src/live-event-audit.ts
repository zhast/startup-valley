import type { WorkerEvent } from "./types.js";

type UsageEvent = Extract<WorkerEvent, { type: "usage.updated" }>;

function requireEvent(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

export function auditLiveEvents(events: WorkerEvent[]): UsageEvent {
  const eventTypes = events.map((event) => event.type);
  const indexOf = (type: WorkerEvent["type"]): number => eventTypes.indexOf(type);
  const startedIndex = indexOf("job.started");
  const toolStartedIndex = indexOf("tool.started");
  const toolCompletedIndex = indexOf("tool.completed");
  const artifactIndex = indexOf("artifact.created");
  const completedIndex = indexOf("job.completed");
  const positiveUsageIndex = events.findIndex((event, index) =>
    index > toolStartedIndex
      && event.type === "usage.updated"
      && event.inputTokens > 0
      && event.outputTokens > 0,
  );

  requireEvent(startedIndex === 0, "Expected job.started as the first event");
  requireEvent(toolStartedIndex > startedIndex, "Expected a tool.started event");
  requireEvent(toolCompletedIndex > toolStartedIndex, "Expected a tool.completed event after tool.started");
  requireEvent(artifactIndex > toolStartedIndex, "Expected artifact.created after tool work began");
  requireEvent(positiveUsageIndex > toolStartedIndex, "Expected nonzero usage.updated after tool work began");
  requireEvent(completedIndex > positiveUsageIndex, "Expected job.completed after nonzero usage.updated");
  requireEvent(
    !events.some((event) => event.type === "job.failed" || event.type === "job.blocked"),
    "The live job failed or was blocked",
  );

  const usage = events[positiveUsageIndex];
  requireEvent(usage?.type === "usage.updated", "Expected a nonzero usage event");
  requireEvent(usage.cost !== undefined && Number.isFinite(usage.cost), "Expected an estimated cost in the usage event");
  return usage;
}
