import { readFile, readdir, stat, open } from 'node:fs/promises';
import { resolve } from 'node:path';
import { loadConfig, isMain } from './lib/config.mjs';

async function readHeader(path, length) {
  const file = await open(path, 'r');
  try {
    const buffer = Buffer.alloc(length);
    const { bytesRead } = await file.read(buffer, 0, length, 0);
    return buffer.subarray(0, bytesRead);
  } finally { await file.close(); }
}

export async function validateExport(directory) {
  const required = ['index.html', 'index.js', 'index.wasm', 'index.pck'];
  const files = [];
  for (const name of required) {
    const path = resolve(directory, name);
    let info;
    try { info = await stat(path); } catch { throw new Error(`Missing ${name}. Export the complete Web project as index.html, not just its PCK.`); }
    if (!info.isFile() || !info.size) throw new Error(`${name} is empty or not a file.`);
    files.push({ name, bytes: info.size });
  }
  const html = await readFile(resolve(directory, 'index.html'), 'utf8');
  if (/\$GODOT_[A-Z_]+/.test(html)) throw new Error('HTML contains unresolved Godot placeholders; it is a template, not an export.');
  if (!html.includes('index.js')) throw new Error('index.html does not reference the matching index.js runtime.');
  // A release pack can be hundreds of megabytes. Validate fixed headers without
  // allocating buffers for every game asset merely to inspect its signature.
  const wasm = await readHeader(resolve(directory, 'index.wasm'), 8);
  if (!wasm.equals(Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]))) throw new Error('index.wasm is not a WebAssembly binary with a complete version-1 header.');
  const pack = await readHeader(resolve(directory, 'index.pck'), 4);
  if (pack.toString() !== 'GDPC') throw new Error('index.pck is not a Godot resource pack.');
  const all = await readdir(directory);
  if (all.some(name => /service\.worker|service-worker/.test(name))) throw new Error('PWA output detected. Disable PWA for the baseline build.');
  return { files, totalBytes: files.reduce((total, file) => total + file.bytes, 0) };
}

if (isMain(import.meta.url)) {
  try {
    const config = await loadConfig();
    const result = await validateExport(config.dist);
    for (const file of result.files) console.log(`${file.name}: ${(file.bytes / 1048576).toFixed(2)} MiB`);
    console.log('Export structure passed. Browser playtesting is still required.');
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
