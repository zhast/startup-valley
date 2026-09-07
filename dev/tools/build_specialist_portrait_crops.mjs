#!/usr/bin/env node
// DEV-only framing alternatives. Crop + uniform point normalize + fixed v3
// palette, no masking/repaint/runtime transform. Original exports are untouched.
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const recipePath = 'dev/art-catalogue/specialist-portrait-crops.json';
const recipe = JSON.parse(readFileSync(resolve(repo, recipePath), 'utf8'));
const relativeOutput = 'game/tests/fixtures/character-concepts/overnight-crops-v1';
const output = resolve(repo, relativeOutput);
mkdirSync(output, { recursive: true });
const hash = path => createHash('sha256').update(readFileSync(resolve(repo, path))).digest('hex');
const run = args => {
  const result = spawnSync('magick', args, { cwd: repo, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(result.stderr || `magick failed: ${result.status}`);
  return result.stdout.trim();
};
const protectedPaths = Object.values(recipe.characters).flatMap(value => [value.source, value.palette]);
const before = Object.fromEntries(protectedPaths.map(path => [path, hash(path)]));
const records = [];
let checks = 0;
const failures = [];
for (const [id, character] of Object.entries(recipe.characters)) {
  for (const [variant, spec] of Object.entries(character.variants)) {
    const [x, y, w, h] = spec.crop;
    if (w * 80 !== h * 64) throw new Error(`${id}/${variant}: crop must be exact4:5; no independent-axis stretch`);
    const native = `${relativeOutput}/${id}-${variant}.png`;
    const command = [character.source, '-crop', `${w}x${h}+${x}+${y}`, '+repage', '-filter', 'point', '-resize', '64x80', '-dither', 'None', '-remap', character.palette, '-strip', '-define', 'png:color-type=2'];
    run([...command, native]);
    const firstHash = hash(native);
    run([...command, native]);
    checks++;
    if (hash(native) !== firstHash) failures.push(`${id}/${variant}: repeat export differs`);
    run([native, '-filter', 'point', '-resize', '400%', '-strip', `${relativeOutput}/${id}-${variant}-4x.png`]);
    const factor = 64 / w;
    const row = {
      id, variant, source: character.source, sourceSha256: before[character.source], palette: character.palette,
      crop: spec.crop, factor, native, sha256: hash(native), dimensions: run(['identify', '-format', '%wx%h', native]),
      opaque: run(['identify', '-format', '%[opaque]', native]), colors: Number(run(['identify', '-format', '%k', native])),
      approximateEyeLine: (character.eye_line_y - y) * factor,
      approximateHairTop: (character.hair_bounds[1] - y) * factor,
      approximateHairWidth: character.hair_bounds[2] * factor,
      paletteNormalization: 'unchanged v3 native palette; dither disabled', padding: [0, 0], runtimeApproved: false,
    };
    checks += 3;
    if (row.dimensions !== '64x80') failures.push(`${id}/${variant}: wrong native dimensions`);
    if (row.opaque !== 'True') failures.push(`${id}/${variant}: must remain an opaque plate`);
    if (row.colors > 32) failures.push(`${id}/${variant}: palette exceeds32`);
    records.push(row);
  }
}
for (const path of protectedPaths) {
  checks++;
  if (hash(path) !== before[path]) failures.push(`Protected source or original v3 changed: ${path}`);
}
const result = { checks, failures, recipe: recipePath, recipeSha256: hash(recipePath), protectedFiles: before, records,
  imageGeneration: false, semanticRepaint: false, masking: false, employeeRegistered: false, runtimeApproved: false };
writeFileSync(resolve(output, 'manifest.json'), `${JSON.stringify(result, null, 2)}\n`);
console.log(`Portrait crop export: ${checks} checks, ${failures.length} failures; four opaque framing alternatives, originals unchanged.`);
process.exitCode = failures.length ? 1 : 0;
