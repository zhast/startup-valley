#!/usr/bin/env node
// DEV-only byte-exact repeat check of the existing opaque-plate builder.
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const prefix = 'game/tests/fixtures/character-concepts/overnight-v1';
const files = ['lawyer', 'creative'].flatMap(role => [
  `game/assets/source/overnight-20260904/characters/${role}-portrait-v3.png`,
  `${prefix}/${role}-portrait-v3.png`, `${prefix}/${role}-portrait-v3-4x.png`,
]).concat([`${prefix}/native-pair.png`, `${prefix}/pair-4x.png`]);
const hash = path => createHash('sha256').update(readFileSync(resolve(repo, path))).digest('hex');
const before = Object.fromEntries(files.map(path => [path, hash(path)]));
const run = spawnSync('bash', ['dev/tools/build_specialist_portraits.sh'], { cwd: repo, encoding: 'utf8' });
const failures = run.status === 0 ? [] : [`Builder exited ${run.status}: ${run.stderr}`];
const after = Object.fromEntries(files.map(path => [path, hash(path)]));
for (const path of files) if (before[path] !== after[path]) failures.push(`Non-deterministic or modified file: ${path}`);
const result = {
  checkedAtUtc: new Date().toISOString(), checks: files.length + 1, failures,
  files: files.map(path => ({ path, beforeSha256: before[path], afterSha256: after[path] })),
  intentionallyOpaque: true, cutoutRecovered: false, employeeRegistered: false,
};
const output = resolve(repo, 'game/tests/output/specialist-portrait-review');
mkdirSync(output, { recursive: true });
writeFileSync(resolve(output, 'rebuild-results.json'), `${JSON.stringify(result, null, 2)}\n`);
console.log(`Specialist portrait rebuild: ${result.checks} checks, ${failures.length} failures; opaque plates only.`);
process.exitCode = failures.length ? 1 : 0;
