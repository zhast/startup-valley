import { lstat, mkdir, realpath } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep, win32 } from "node:path";

export class JobPathGuard {
  readonly #root: string;
  #canonicalRoot: string | undefined;

  constructor(root: string) {
    this.#root = resolve(root);
  }

  async initialize(): Promise<void> {
    await mkdir(this.#root, { recursive: true });
    this.#canonicalRoot = await realpath(this.#root);
  }

  get canonicalRoot(): string {
    if (!this.#canonicalRoot) throw new Error("Job path guard has not been initialized");
    return this.#canonicalRoot;
  }

  async resolve(relativePath: string, createParents = false): Promise<string> {
    if (!this.#canonicalRoot) await this.initialize();
    const root = this.#canonicalRoot as string;
    if (relativePath.length === 0 || relativePath.includes("\0")) throw new Error("Path must be non-empty and contain no NUL bytes");
    if (isAbsolute(relativePath) || win32.isAbsolute(relativePath) || relativePath.startsWith("\\\\")) {
      throw new Error("Absolute paths are not allowed");
    }

    const normalizedSegments = relativePath.replaceAll("\\", "/").split("/");
    if (normalizedSegments.some((segment) => segment === ".." || segment.length === 0)) {
      throw new Error("Path traversal and empty path segments are not allowed");
    }
    const segments = normalizedSegments.filter((segment) => segment !== ".");
    if (segments.length === 0) throw new Error("Path must identify an item inside the job directory");

    const candidate = resolve(root, ...segments);
    const fromRoot = relative(root, candidate);
    if (fromRoot === ".." || fromRoot.startsWith(`..${sep}`) || isAbsolute(fromRoot)) {
      throw new Error("Path escapes the job directory");
    }

    let current = root;
    const walkCount = createParents ? segments.length - 1 : segments.length;
    for (let index = 0; index < walkCount; index += 1) {
      const segment = segments[index];
      if (!segment) continue;
      current = resolve(current, segment);
      try {
        const metadata = await lstat(current);
        if (metadata.isSymbolicLink()) throw new Error(`Symlink path component is not allowed: ${segment}`);
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
        if (createParents) await mkdir(current);
        else throw new Error(`Path does not exist: ${relativePath}`);
      }
    }

    try {
      const metadata = await lstat(candidate);
      if (metadata.isSymbolicLink()) throw new Error("Symlink targets are not allowed");
      const canonicalCandidate = await realpath(candidate);
      const canonicalRelative = relative(root, canonicalCandidate);
      if (canonicalRelative === ".." || canonicalRelative.startsWith(`..${sep}`) || isAbsolute(canonicalRelative)) {
        throw new Error("Resolved path escapes the job directory");
      }
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      if (!createParents) throw new Error(`Path does not exist: ${relativePath}`);
    }

    return candidate;
  }
}
