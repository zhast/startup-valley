#!/usr/bin/env node
// DEV-only reproducibility check. Rebuilds only the six declared coffee exports
// with the existing mechanical builder; the retained source must not change.
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const prefix = 'game/tests/fixtures/furniture-calibration/kits/coffee-service-south-v4';
const source = 'game/assets/source/overnight-20260904/kits/coffee-service-south-v4.png';
const files = [source, ...['', '-espresso', '-grinder', '-mug', '-plant', '-paper-4x'].map(part => `${prefix}${part}.png`)];
const digest = path => createHash('sha256').update(readFileSync(resolve(repo, path))).digest('hex');
const before = Object.fromEntries(files.map(path => [path, digest(path)]));
const run = spawnSync('bash', ['dev/tools/build_coffee_service_south_kit.sh'], { cwd: repo, encoding: 'utf8' });
if (run.status !== 0) {
  process.stderr.write(run.stderr || run.stdout || 'Coffee builder failed.\n');
  process.exit(run.status || 1);
}
const after = Object.fromEntries(files.map(path => [path, digest(path)]));
const changed = files.filter(path => before[path] !== after[path]);
const result = {
  checkedAtUtc: new Date().toISOString(),
  checks: files.length + 1,
  failures: changed.map(path => `Non-deterministic or mutated file: ${path}`),
  builderExitCode: run.status,
  files: files.map(path => ({ path, beforeSha256: before[path], afterSha256: after[path] })),
  sourceUnchanged: before[source] === after[source],
  semanticEditing: false,
  runtimeApproved: false,
};
const output = resolve(repo, 'game/tests/output/coffee-south-kit');
mkdirSync(output, { recursive: true });
writeFileSync(resolve(output, 'rebuild-results.json'), `${JSON.stringify(result, null, 2)}\n`);
console.log(`Coffee deterministic rebuild: ${result.checks} checks, ${result.failures.length} failures; source unchanged=${result.sourceUnchanged}.`);
if (changed.length) console.error(result.failures.join('\n'));
process.exitCode = changed.length ? 1 : 0;
