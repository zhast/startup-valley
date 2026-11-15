import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
const require = createRequire(import.meta.url);
const sharp = require(process.env.SHARP_MODULE || 'sharp');
const source = 'game/assets/source/modular-yard';
const output = 'game/assets/runtime/office/terrain-v1/yard-atlas.png';
const verify = process.argv.includes('--verify');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const lawn = await sharp(`${source}/grass-generated.png`).resize(128, 128, { kernel: 'nearest' }).ensureAlpha().png().toBuffer();
const hedgeSource = await sharp(`${source}/hedges-generated.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const { width, height, channels } = hedgeSource.info;
assert.equal(channels, 4);
const layers = [{ input: lawn, left: 0, top: 0 }, { input: await sharp('game/assets/runtime/office/campus-surround.png').extract({ left: 832, top: 384, width: 32, height: 32 }).png().toBuffer(), left: 128, top: 0 }];
const crops = [];
for (let index = 0; index < 3; index++) {
  let left = width, top = height, right = -1, bottom = -1;
  for (let y = 0; y < height; y++) for (let x = Math.floor(index * width / 3); x < Math.floor((index + 1) * width / 3); x++) {
    if (hedgeSource.data[(y * width + x) * 4 + 3] < 128) continue;
    left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
  }
  assert.ok(right >= left && bottom >= top, `Missing hedge ${index}`);
  const crop = { left, top, width: right - left + 1, height: bottom - top + 1 };
  const resized = await sharp(`${source}/hedges-generated.png`).extract(crop).resize({ width: 48, height: 32, fit: 'inside', kernel: 'nearest' }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  // Binary game alpha; no color repainting or silhouette-specific hand edits.
  for (let i = 3; i < resized.data.length; i += 4) resized.data[i] = resized.data[i] >= 128 ? 255 : 0;
  const target = { left: index * 64 + Math.floor((64 - resized.info.width) / 2), top: 128 + 48 - resized.info.height };
  layers.push({ input: await sharp(resized.data, { raw: resized.info }).png().toBuffer(), ...target });
  crops.push({ source: crop, normalized: [resized.info.width, resized.info.height], atlas: target, groundPivot: [index * 64 + 32, 176] });
}
const result = await sharp({ create: { width: 192, height: 192, channels: 4, background: '#00000000' } }).composite(layers).png({ compressionLevel: 9 }).toBuffer();
if (verify) assert.deepEqual(result, await readFile(output), 'Runtime terrain differs from its source transformation');
else {
  await mkdir('game/assets/runtime/office/terrain-v1', { recursive: true });
  await writeFile(output, result);
}
const files = {};
for (const path of [`${source}/grass-generated.png`, `${source}/hedges-generated.png`, `${source}/grass-before.png`, `${source}/hedge-before.png`, `${source}/grass-prompt.txt`, `${source}/hedges-prompt.txt`, 'dev/art-catalogue/style-profile.json', 'dev/art-catalogue/style-reference-board.png', 'game/assets/runtime/office/campus-surround.png', 'dev/tools/build_village_terrain.mjs', output]) files[path] = hash(await readFile(path));
const derivation = { origin: 'openai_imagegen_with_legacy_stone_crop', styleProfile: 'startup-valley-cozy-pixel-v1', tool: 'built-in image_gen', generationIds: ['exec-aed54b32-dcd3-409e-8c33-03ed8f95a831', 'exec-a296e227-0615-4d00-9233-daee78d4ceb4'], editReferences: { source: 'game/assets/runtime/office/campus-surround.png', grassCrop: [192, 192, 256, 256], hedgeCrop: [192, 0, 448, 64], styleBoard: 'dev/art-catalogue/style-reference-board.png' }, lawn: { resize: [128, 128], kernel: 'nearest' }, paving: { crop: [832, 384, 32, 32], transform: 'none', provenance: 'Pre-existing project art; original generation history not established by this change.' }, hedges: { crops, alphaThreshold: 128, kernel: 'nearest', runtimeScale: 1, cellCanvas: [64, 64], groundPivot: [32, 48] }, files };
if (!verify) await writeFile(`${source}/derivation.json`, JSON.stringify(derivation, null, 2) + '\n');
console.log(`${verify ? 'Verified byte-for-byte' : 'Built'} ${output}`);
