import { randomUUID } from "node:crypto";
import { readFile, readdir, stat, writeFile } from "node:fs/promises";
import { basename, extname, relative } from "node:path";

import { Type } from "typebox";
import { defineTool, type ToolDefinition } from "@earendil-works/pi-coding-agent";

import type { ApprovalBroker } from "./approval-broker.js";
import type { Artifact } from "./types.js";
import { safeFetchText } from "./network-guard.js";
import { JobPathGuard } from "./path-guard.js";

const MAX_TEXT_BYTES = 200_000;
const MAX_LIST_ENTRIES = 500;
const MAX_SEARCH_FILES = 500;

export interface ToolFactoryOptions {
  jobId: string;
  jobRoot: string;
  studioRoot: string;
  approvalBroker: ApprovalBroker;
  onArtifact: (artifact: Artifact) => void;
  onApproval: (approvalId: string, action: string) => void;
}

function mediaType(path: string): string {
  switch (extname(path).toLowerCase()) {
    case ".md":
      return "text/markdown";
    case ".json":
      return "application/json";
    case ".html":
      return "text/html";
    case ".css":
      return "text/css";
    case ".js":
    case ".mjs":
      return "text/javascript";
    case ".ts":
      return "text/typescript";
    default:
      return "text/plain";
  }
}

function textResult(text: string, details: Record<string, unknown> = {}) {
  return { content: [{ type: "text" as const, text }], details };
}

function stripHtml(html: string): string {
  return html
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/giu, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/giu, " ")
    .replace(/<[^>]+>/gu, " ")
    .replace(/&amp;/gu, "&")
    .replace(/&lt;/gu, "<")
    .replace(/&gt;/gu, ">")
    .replace(/&quot;/gu, '"')
    .replace(/&#39;/gu, "'")
    .replace(/\s+/gu, " ")
    .trim();
}

async function collectFiles(root: string, limit: number): Promise<string[]> {
  const results: string[] = [];
  const queue = [root];
  while (queue.length > 0 && results.length < limit) {
    const directory = queue.shift();
    if (!directory) break;
    const entries = await readdir(directory, { withFileTypes: true });
    for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
      if (entry.isSymbolicLink()) continue;
      const child = `${directory}/${entry.name}`;
      if (entry.isDirectory()) queue.push(child);
      else if (entry.isFile()) results.push(child);
      if (results.length >= limit) break;
    }
  }
  return results;
}

export async function createJobTools(options: ToolFactoryOptions): Promise<ToolDefinition[]> {
  const guard = new JobPathGuard(options.jobRoot);
  const studioGuard = new JobPathGuard(options.studioRoot);
  await Promise.all([guard.initialize(), studioGuard.initialize()]);
  const jobRoot = guard.canonicalRoot;
  const studioRoot = studioGuard.canonicalRoot;

  const isStudioPath = (path: string): boolean => path === "studio" || path.startsWith("studio/");
  const studioRelative = (path: string): string => path.slice("studio/".length);
  const rejectStudioWrite = (path: string): void => {
    if (isStudioPath(path)) throw new Error("Studio files are read-only during a job; write to job scratch for player-approved promotion");
  };

  const registerArtifact = (path: string): Artifact => {
    const artifact: Artifact = {
      artifactId: randomUUID(),
      jobId: options.jobId,
      name: basename(path),
      relativePath: relative(jobRoot, path).replaceAll("\\", "/"),
      mediaType: mediaType(path),
      createdAt: new Date().toISOString(),
    };
    options.onArtifact(artifact);
    return artifact;
  };

  const readTool = defineTool({
    name: "read_file",
    label: "Read file",
    description: "Read a UTF-8 text file from job scratch or the durable read-only studio/ tree.",
    promptSnippet: "Read a text file from job scratch or from studio/.",
    parameters: Type.Object({ path: Type.String({ minLength: 1, maxLength: 1024 }) }),
    execute: async (_id, { path }) => {
      if (path === "studio") throw new Error("Choose a file below studio/");
      const target = isStudioPath(path) ? await studioGuard.resolve(studioRelative(path)) : await guard.resolve(path);
      const metadata = await stat(target);
      if (!metadata.isFile()) throw new Error("The requested path is not a file");
      if (metadata.size > MAX_TEXT_BYTES) throw new Error("File is too large to read");
      return textResult(await readFile(target, "utf8"), { path, bytes: metadata.size });
    },
  });

  const writeTool = defineTool({
    name: "write_file",
    label: "Write file",
    description: "Create or replace a UTF-8 text file in job scratch. Completed artifacts can be promoted into studio/ after player approval.",
    promptSnippet: "Write a text file inside the job workspace.",
    promptGuidelines: ["Use relative paths only. Write requested deliverables into the job workspace."],
    parameters: Type.Object({
      path: Type.String({ minLength: 1, maxLength: 1024 }),
      content: Type.String({ maxLength: MAX_TEXT_BYTES }),
    }),
    executionMode: "sequential",
    execute: async (_id, { path, content }) => {
      rejectStudioWrite(path);
      const target = await guard.resolve(path, true);
      await writeFile(target, content, { encoding: "utf8", flag: "w" });
      const artifact = registerArtifact(target);
      return textResult(`Wrote ${content.length} characters to ${path}`, { path, artifactId: artifact.artifactId });
    },
  });

  const editTool = defineTool({
    name: "edit_file",
    label: "Edit file",
    description: "Replace one exact, unique text occurrence in a UTF-8 file inside this job's workspace.",
    promptSnippet: "Make an exact replacement in a job workspace file.",
    parameters: Type.Object({
      path: Type.String({ minLength: 1, maxLength: 1024 }),
      oldText: Type.String({ minLength: 1, maxLength: MAX_TEXT_BYTES }),
      newText: Type.String({ maxLength: MAX_TEXT_BYTES }),
    }),
    executionMode: "sequential",
    execute: async (_id, { path, oldText, newText }) => {
      rejectStudioWrite(path);
      const target = await guard.resolve(path);
      const original = await readFile(target, "utf8");
      const first = original.indexOf(oldText);
      if (first < 0) throw new Error("oldText was not found");
      if (original.indexOf(oldText, first + oldText.length) >= 0) throw new Error("oldText must identify one unique occurrence");
      const updated = `${original.slice(0, first)}${newText}${original.slice(first + oldText.length)}`;
      if (Buffer.byteLength(updated, "utf8") > MAX_TEXT_BYTES) throw new Error("Edited file would be too large");
      await writeFile(target, updated, "utf8");
      const artifact = registerArtifact(target);
      return textResult(`Edited ${path}`, { path, artifactId: artifact.artifactId });
    },
  });

  const listTool = defineTool({
    name: "list_files",
    label: "List files",
    description: "List files recursively under job scratch or the durable read-only studio/ tree.",
    promptSnippet: "List files in job scratch or studio/.",
    parameters: Type.Object({ path: Type.Optional(Type.String({ minLength: 1, maxLength: 1024 })) }),
    execute: async (_id, { path }) => {
      const requestedPath = path ?? ".";
      const inStudio = isStudioPath(requestedPath);
      const root = requestedPath === "."
        ? jobRoot
        : requestedPath === "studio"
          ? studioRoot
          : inStudio
            ? await studioGuard.resolve(studioRelative(requestedPath))
            : await guard.resolve(requestedPath);
      const metadata = await stat(root);
      if (!metadata.isDirectory()) throw new Error("The requested path is not a directory");
      const files = await collectFiles(root, MAX_LIST_ENTRIES);
      const names = files.map((file) => {
        const name = relative(inStudio ? studioRoot : jobRoot, file).replaceAll("\\", "/");
        return inStudio ? `studio/${name}` : name;
      });
      return textResult(names.length > 0 ? names.join("\n") : "(no files)", { count: names.length });
    },
  });

  const searchTool = defineTool({
    name: "search_files",
    label: "Search files",
    description: "Find fixed text in UTF-8 files under job scratch or the durable read-only studio/ tree. This does not execute a shell command.",
    promptSnippet: "Search text files in job scratch or studio/.",
    parameters: Type.Object({
      query: Type.String({ minLength: 1, maxLength: 500 }),
      path: Type.Optional(Type.String({ minLength: 1, maxLength: 1024 })),
    }),
    execute: async (_id, { query, path }) => {
      const requestedPath = path ?? ".";
      const inStudio = isStudioPath(requestedPath);
      const root = requestedPath === "."
        ? jobRoot
        : requestedPath === "studio"
          ? studioRoot
          : inStudio
            ? await studioGuard.resolve(studioRelative(requestedPath))
            : await guard.resolve(requestedPath);
      const files = await collectFiles(root, MAX_SEARCH_FILES);
      const needle = query.toLocaleLowerCase();
      const matches: string[] = [];
      for (const file of files) {
        const metadata = await stat(file);
        if (metadata.size > MAX_TEXT_BYTES) continue;
        const lines = (await readFile(file, "utf8")).split(/\r?\n/u);
        for (let index = 0; index < lines.length; index += 1) {
          const line = lines[index] ?? "";
          if (line.toLocaleLowerCase().includes(needle)) {
            const name = relative(inStudio ? studioRoot : jobRoot, file).replaceAll("\\", "/");
            matches.push(`${inStudio ? `studio/${name}` : name}:${index + 1}:${line.slice(0, 300)}`);
          }
          if (matches.length >= 200) break;
        }
        if (matches.length >= 200) break;
      }
      return textResult(matches.length > 0 ? matches.join("\n") : "(no matches)", { count: matches.length });
    },
  });

  const webFetchTool = defineTool({
    name: "web_fetch",
    label: "Fetch web page",
    description: "Fetch public HTTP(S) text through the worker's guarded proxy. Local and private network addresses are blocked.",
    promptSnippet: "Fetch a public web page with private-network blocking.",
    parameters: Type.Object({ url: Type.String({ minLength: 8, maxLength: 2048 }) }),
    execute: async (_id, { url }, signal) => {
      const result = await safeFetchText(url, signal);
      return textResult(stripHtml(result.text).slice(0, MAX_TEXT_BYTES), { url: result.url, status: result.status });
    },
  });

  const webSearchTool = defineTool({
    name: "web_search",
    label: "Search the web",
    description: "Search the public web through a guarded text-only proxy.",
    promptSnippet: "Search the public web.",
    parameters: Type.Object({ query: Type.String({ minLength: 1, maxLength: 500 }) }),
    execute: async (_id, { query }, signal) => {
      const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
      const result = await safeFetchText(url, signal);
      return textResult(stripHtml(result.text).slice(0, 30_000), { source: result.url });
    },
  });

  const artifactTool = defineTool({
    name: "create_artifact",
    label: "Create artifact",
    description: "Register an existing job workspace file as a player-visible artifact.",
    promptSnippet: "Register a completed file as a deliverable.",
    parameters: Type.Object({ path: Type.String({ minLength: 1, maxLength: 1024 }) }),
    execute: async (_id, { path }) => {
      rejectStudioWrite(path);
      const target = await guard.resolve(path);
      const metadata = await stat(target);
      if (!metadata.isFile()) throw new Error("Only files can be artifacts");
      const artifact = registerArtifact(target);
      return textResult(`Registered artifact ${artifact.name}`, { artifactId: artifact.artifactId });
    },
  });

  const approvalTool = defineTool({
    name: "request_player_approval",
    label: "Ask player",
    description: "Pause and ask the player to approve a clearly described action.",
    promptSnippet: "Ask the player before a sensitive action.",
    parameters: Type.Object({ action: Type.String({ minLength: 1, maxLength: 1000 }) }),
    executionMode: "sequential",
    execute: async (_id, { action }) => {
      const decision = await options.approvalBroker.request(options.jobId, action, options.onApproval);
      return textResult(decision.approved ? "Player approved the action" : `Player denied the action: ${decision.reason ?? "no reason"}`);
    },
  });

  return [
    readTool,
    writeTool,
    editTool,
    listTool,
    searchTool,
    webSearchTool,
    webFetchTool,
    artifactTool,
    approvalTool,
  ];
}
