import { createHash } from 'node:crypto';
import { readFile, readdir, lstat } from 'node:fs/promises';
import { resolve } from 'node:path';

// Hash the complete playable payload, including the worker and its SQLite WASM.
// Metadata is excluded so writing the identity cannot change the identity.
export async function identifyBuild(directory) {
  const files = [];
  async function visit(relative = '') {
    for (const name of (await readdir(resolve(directory, relative))).sort()) {
      const path = relative ? `${relative}/${name}` : name;
      if (!relative && name === 'build-info.json') continue;
      const absolute = resolve(directory, path);
      const info = await lstat(absolute);
      if (info.isSymbolicLink()) throw new Error(`Build contains a symlink: ${path}`);
      if (info.isDirectory()) await visit(path);
      else if (info.isFile()) {
        const bytes = await readFile(absolute);
        files.push({ path, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex') });
      } else throw new Error(`Build contains a non-file entry: ${path}`);
    }
  }
  await visit();
  const buildId = createHash('sha256').update(JSON.stringify(files)).digest('hex').slice(0, 16);
  return { buildId, payloadFiles: files };
}
