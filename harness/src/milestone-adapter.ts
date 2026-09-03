import type { MilestoneDefinition } from "./journey.js";
import { copyFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { JobPathGuard } from "./path-guard.js";
import type { Artifact } from "./types.js";

export interface MilestoneEvidence {
  kind: "local-artifacts";
  documents: Array<{ path: string; content: string }>;
  externalActionPerformed: false;
}

/** Future service adapters can provide evidence through this boundary. They must
 * not bypass the work-order, evaluation, or transactional reward lifecycle. */
export interface MilestoneAdapter {
  collect(definition: MilestoneDefinition, read: (path: string) => Promise<{ content: string }>): Promise<MilestoneEvidence>;
}

export class ArtifactMilestoneAdapter implements MilestoneAdapter {
  async collect(definition: MilestoneDefinition, read: (path: string) => Promise<{ content: string }>): Promise<MilestoneEvidence> {
    const documents: MilestoneEvidence["documents"] = [];
    for (const path of definition.files) {
      const artifact = await read(path);
      if (!artifact.content.trim()) throw new Error(`Required artifact is empty: ${path}`);
      documents.push({ path, content: artifact.content });
    }
    return { kind: "local-artifacts", documents, externalActionPerformed: false };
  }
}

/** Originals remain immutable handoffs; a new job edits its own working copies.
 * This avoids paying to regenerate unchanged files on every bounded revision. */
export async function prepareRevisionFiles(sourceRoot: string, targetRoot: string, artifacts: Artifact[], required: readonly string[], onCopy: (artifact: Artifact) => void): Promise<void> {
  const source = new JobPathGuard(sourceRoot);
  const target = new JobPathGuard(targetRoot);
  await Promise.all([source.initialize(), target.initialize()]);
  for (const artifact of artifacts.filter((item) => required.includes(item.relativePath))) {
    const from = await source.resolve(artifact.relativePath);
    for (const path of [`handoffs/${artifact.relativePath}`, artifact.relativePath]) {
      const to = await target.resolve(path, true);
      await mkdir(dirname(to), { recursive: true });
      await copyFile(from, to);
    }
    onCopy(artifact);
  }
}
