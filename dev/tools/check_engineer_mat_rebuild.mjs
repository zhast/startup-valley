#!/usr/bin/env node
// DEV-only replay of the frozen builder. No image editing or new generation.
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const names = ['north-v1', 'north-v2', 'east-v1', 'south-v1', 'south-v2', 'west-v1'];
const files = names.flatMap(id => [
  `game/assets/source/overnight-20260904/roles/engineer-mat-${id}.png`,
  `game/tests/fixtures/furniture-calibration/engineer-mat-v1/${id}.png`,
  `game/tests/fixtures/furniture-calibration/engineer-mat-v1/${id}-8x.png`,
]);
const hash = p => createHash('sha256').update(readFileSync(resolve(repo, p))).digest('hex');
const pixels = p => {
  const decoded = spawnSync('magick', [resolve(repo, p), '-depth', '8', 'RGBA:-'], { maxBuffer: 8 * 1024 * 1024 });
  if (decoded.status !== 0) throw new Error(`Cannot decode ${p}`);
  return createHash('sha256').update(decoded.stdout).digest('hex');
};
const before = Object.fromEntries(files.map(p => [p, hash(p)]));
const beforePixels = Object.fromEntries(files.map(p => [p, pixels(p)]));
const result = spawnSync('bash', ['dev/tools/build_engineer_mats.sh'], { cwd: repo, encoding: 'utf8' });
const failures = result.status === 0 ? [] : [`Builder exit ${result.status}: ${result.stderr}`];
const after = Object.fromEntries(files.map(p => [p, hash(p)]));
const afterPixels = Object.fromEntries(files.map(p => [p, pixels(p)]));
for (const path of files) {
  if (beforePixels[path] !== afterPixels[path]) failures.push(`Changed decoded pixels: ${path}`);
  // Enlarged proof files retain creation metadata in the frozen builder.
  // Original masters and native exports must remain byte-identical as well.
  if (!path.endsWith('-8x.png') && before[path] !== after[path]) failures.push(`Changed source/native file: ${path}`);
}
const output = resolve(repo, 'game/tests/output/engineer-mat-composition');
mkdirSync(output, { recursive: true });
writeFileSync(resolve(output, 'rebuild-results.json'), JSON.stringify({
  checkedAtUtc: new Date().toISOString(), checks: files.length + 13, failures,
  files: files.map(path => ({ path, beforeSha256: before[path], afterSha256: after[path],
    beforePixelSha256: beforePixels[path], afterPixelSha256: afterPixels[path],
    reviewDerivativeMetadataChanged: path.endsWith('-8x.png') && before[path] !== after[path] })),
  intentionallyOpaque: true, imageGeneration: false, runtimeApproved: false,
}, null, 2) + '\n');
console.log(`Engineer mat rebuild: ${files.length + 13} checks, ${failures.length} failures.`);
process.exitCode = failures.length ? 1 : 0;
