import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, realpath, rename, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { crc32, inflateRawSync } from 'node:zlib';
import { isMain, isWithin, loadConfig } from './lib/config.mjs';

const TEMPLATE_NAMES = ['web_nothreads_debug.zip', 'web_nothreads_release.zip'];
const MAX_ENTRY = 128 * 1024 * 1024;

export function zipDirectory(buffer, archiveSize = buffer.length, bufferOffset = 0) {
  let end = -1;
  for (let i = buffer.length - 22; i >= Math.max(0, buffer.length - 65557); i--) {
    if (buffer.readUInt32LE(i) === 0x06054b50 && i + 22 + buffer.readUInt16LE(i + 20) === buffer.length) { end = i; break; }
  }
  if (end < 0) throw new Error('ZIP end-of-directory record is missing.');
  if (buffer.readUInt16LE(end + 4) || buffer.readUInt16LE(end + 6)) throw new Error('Multi-disk ZIP archives are unsupported.');
  const count = buffer.readUInt16LE(end + 10), size = buffer.readUInt32LE(end + 12), offset = buffer.readUInt32LE(end + 16);
  if (count === 65535 || size === 0xffffffff || offset === 0xffffffff) throw new Error('ZIP64 template archives need an updated setup script.');
  if (offset + size > archiveSize || count > 10000 || size > 4 * 1024 * 1024) throw new Error('Invalid ZIP directory bounds.');
  return { count, size, offset, data: offset >= bufferOffset ? buffer.subarray(offset - bufferOffset, offset - bufferOffset + size) : null };
}

export function parseEntries(directory, expectedCount) {
  const entries = [];
  for (let cursor = 0; cursor < directory.length;) {
    if (cursor + 46 > directory.length || directory.readUInt32LE(cursor) !== 0x02014b50) throw new Error('Malformed ZIP directory entry.');
    const nameLength = directory.readUInt16LE(cursor + 28), extraLength = directory.readUInt16LE(cursor + 30), commentLength = directory.readUInt16LE(cursor + 32);
    const next = cursor + 46 + nameLength + extraLength + commentLength;
    if (next > directory.length) throw new Error('Truncated ZIP directory entry.');
    entries.push({ name: directory.subarray(cursor + 46, cursor + 46 + nameLength).toString(), flags: directory.readUInt16LE(cursor + 8), method: directory.readUInt16LE(cursor + 10), crc: directory.readUInt32LE(cursor + 16), compressedSize: directory.readUInt32LE(cursor + 20), size: directory.readUInt32LE(cursor + 24), offset: directory.readUInt32LE(cursor + 42) });
    cursor = next;
  }
  if (entries.length !== expectedCount || new Set(entries.map(entry => entry.name)).size !== entries.length) throw new Error('ZIP entry count or uniqueness check failed.');
  return entries;
}

export function verifyEntry(entry, compressed) {
  if (entry.flags & 1 || ![0, 8].includes(entry.method)) throw new Error(`Unsupported encrypted/compressed entry: ${entry.name}`);
  if (entry.size > MAX_ENTRY || compressed.length !== entry.compressedSize) throw new Error(`Invalid entry size: ${entry.name}`);
  const data = entry.method === 8 ? inflateRawSync(compressed, { maxOutputLength: MAX_ENTRY }) : compressed;
  if (data.length !== entry.size || crc32(data) !== entry.crc) throw new Error(`ZIP integrity check failed: ${entry.name}`);
  return data;
}

export function verifyTemplateZip(buffer) {
  const directory = zipDirectory(buffer);
  const entries = parseEntries(directory.data, directory.count);
  for (const required of ['godot.js', 'godot.wasm', 'godot.html']) if (!entries.some(entry => entry.name === required)) throw new Error(`Template is missing ${required}.`);
  for (const entry of entries) {
    if (entry.offset + 30 > buffer.length || buffer.readUInt32LE(entry.offset) !== 0x04034b50) throw new Error('Invalid inner ZIP local header.');
    const offset = entry.offset + 30 + buffer.readUInt16LE(entry.offset + 26) + buffer.readUInt16LE(entry.offset + 28);
    const data = verifyEntry(entry, buffer.subarray(offset, offset + entry.compressedSize));
    if (entry.name === 'godot.wasm' && !data.subarray(0, 4).equals(Buffer.from([0, 97, 115, 109]))) throw new Error('Template does not contain a WebAssembly binary.');
  }
}

async function getRelease(version) {
  const response = await fetch(`https://api.github.com/repos/godotengine/godot-builds/releases/tags/${version}-stable`, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`Official release lookup failed (${response.status}). Retry later; no credentials are required.`);
  const release = await response.json();
  if (release.tag_name !== `${version}-stable` || release.prerelease || release.draft) throw new Error('The configured version is not an official stable release.');
  const asset = release.assets.find(item => item.name === `Godot_v${version}-stable_export_templates.tpz`);
  if (!asset || !asset.browser_download_url.startsWith('https://github.com/godotengine/godot-builds/releases/download/')) throw new Error('Official standard export template archive is missing.');
  return { release, asset };
}

async function readRemoteEntry(asset, entry, range) {
  const header = await range(entry.offset, entry.offset + 29);
  if (header.readUInt32LE(0) !== 0x04034b50 || header.readUInt16LE(8) !== entry.method) throw new Error('Invalid outer ZIP local header.');
  const nameLength = header.readUInt16LE(26), extraLength = header.readUInt16LE(28);
  const name = await range(entry.offset + 30, entry.offset + 29 + nameLength);
  if (name.toString() !== entry.name) throw new Error('ZIP local and directory filenames do not match.');
  const offset = entry.offset + 30 + nameLength + extraLength;
  const chunks = entry.compressedSize > 1024 * 1024 ? 4 : 1;
  const chunkSize = Math.ceil(entry.compressedSize / chunks);
  const parts = await Promise.all(Array.from({ length: chunks }, (_, index) => range(offset + index * chunkSize, offset + Math.min(entry.compressedSize, (index + 1) * chunkSize) - 1)));
  return verifyEntry(entry, Buffer.concat(parts));
}

export async function setupWebTemplates() {
  const config = await loadConfig();
  if (!config.godotVersion) throw new Error('Pin godotVersion in godot-web.config.json before setting up templates.');
  const { release, asset } = await getRelease(config.godotVersion);
  async function range(start, end) {
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || end < start || end >= asset.size || end - start > MAX_ENTRY) throw new Error('Invalid template download range.');
    const response = await fetch(asset.browser_download_url, { headers: { Range: `bytes=${start}-${end}` }, signal: AbortSignal.timeout(180000) });
    if (response.status !== 206 || response.headers.get('content-range') !== `bytes ${start}-${end}/${asset.size}`) {
      await response.body?.cancel();
      throw new Error('Official download did not honor a byte range; refusing to download the entire multi-platform archive.');
    }
    const data = Buffer.from(await response.arrayBuffer());
    if (data.length !== end - start + 1) throw new Error('Template download was truncated.');
    return data;
  }
  const tailOffset = Math.max(0, asset.size - 65557);
  const directory = zipDirectory(await range(tailOffset, asset.size - 1), asset.size, tailOffset);
  const entries = parseEntries(directory.data ?? await range(directory.offset, directory.offset + directory.size - 1), directory.count);
  const versionEntry = entries.find(entry => entry.name === 'templates/version.txt');
  if (!versionEntry || (await readRemoteEntry(asset, versionEntry, range)).toString().trim() !== `${config.godotVersion}.stable`) throw new Error('Template archive version does not match the pinned editor.');
  const destination = resolve(config.projectPath, 'web/templates');
  await mkdir(destination, { recursive: true });
  if (!isWithin(await realpath(config.projectPath), await realpath(destination))) throw new Error('Template destination resolves outside the game project.');
  const staging = await mkdtemp(resolve(destination, '.download-'));
  try {
    const outputs = await Promise.all(TEMPLATE_NAMES.map(async name => {
      const entry = entries.find(item => item.name === `templates/${name}`);
      if (!entry) throw new Error(`Official archive is missing ${name}.`);
      let data;
      try {
        const cached = await readFile(resolve(destination, name));
        if (cached.length === entry.size && crc32(cached) === entry.crc) { verifyTemplateZip(cached); data = cached; }
      } catch (error) { if (error.code !== 'ENOENT') console.log(`Rechecking ${name}: ${error.message}`); }
      const reused = Boolean(data);
      data ??= await readRemoteEntry(asset, entry, range);
      verifyTemplateZip(data);
      await writeFile(resolve(staging, name), data);
      console.log(`${reused ? 'Verified existing' : 'Downloaded and verified'} ${name} (${(data.length / 1048576).toFixed(1)} MiB)`);
      return { name, bytes: data.length, crc32: entry.crc.toString(16), sha256: createHash('sha256').update(data).digest('hex') };
    }));
    for (const { name } of outputs) await rename(resolve(staging, name), resolve(destination, name));
    await writeFile(resolve(destination, 'verification.json'), JSON.stringify({ version: config.godotVersion, release: release.html_url, source: asset.browser_download_url, publishedArchiveDigest: asset.digest, verification: 'Selected entries and all inner ZIP members verified by size and CRC32 from the official HTTPS archive. SHA256 values below describe extracted files; the full multi-platform archive digest was not recomputed.', outputs }, null, 2) + '\n');
    console.log(`Templates ready at ${destination}`);
  } finally { await rm(staging, { recursive: true, force: true }); }
}

if (isMain(import.meta.url)) {
  try { await setupWebTemplates(); } catch (error) { console.error(error.message); process.exitCode = 1; }
}
