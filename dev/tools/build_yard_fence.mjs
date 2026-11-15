import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
const require = createRequire(import.meta.url);
const sharp = require(process.env.SHARP_MODULE || 'sharp');
const source = 'game/assets/source/yard-fence-v1';
const output = `${source}/candidate-atlas.png`;
const image = await sharp(`${source}/generated-kit.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const specifications = [
  { id: 'post', size: [10, 24], at: [3, 8], region: [0, 0, 16, 32], pivot: [8, 32] },
  { id: 'horizontal', size: [32, 16], at: [16, 12], region: [16, 0, 32, 32], pivot: [0, 32] },
  { id: 'vertical', size: [4, 32], at: [54, 18], region: [48, 0, 16, 64], pivot: [8, 32] },
];
const layers = [], crops = [];
for (let i = 0; i < specifications.length; i++) {
  const spec = specifications[i];
  let left = image.info.width, top = image.info.height, right = -1, bottom = -1;
  for (let y = 0; y < image.info.height; y++) for (let x = Math.floor(i * image.info.width / 3); x < Math.floor((i + 1) * image.info.width / 3); x++) {
    if (image.data[(y * image.info.width + x) * 4 + 3] < 128) continue;
    left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
  }
  assert.ok(right >= left && bottom >= top, `Missing generated component: ${spec.id}`);
  const crop = { left, top, width: right - left + 1, height: bottom - top + 1 };
  const normalized = await sharp(`${source}/generated-kit.png`).extract(crop).resize(...spec.size, { kernel: 'nearest', fit: 'fill' }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  for (let p = 3; p < normalized.data.length; p += 4) normalized.data[p] = normalized.data[p] >= 128 ? 255 : 0;
  layers.push({ input: await sharp(normalized.data, { raw: normalized.info }).png().toBuffer(), left: spec.at[0], top: spec.at[1] });
  crops.push({ ...spec, crop });
}
const bytes = await sharp({ create: { width: 64, height: 64, channels: 4, background: '#00000000' } }).composite(layers).png({ compressionLevel: 9 }).toBuffer();
if (process.argv.includes('--verify')) assert.deepEqual(bytes, await readFile(output), 'Candidate differs from retained generated source');
else await writeFile(output, bytes);
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const files = {};
for (const p of [`${source}/generated-kit.png`, `${source}/prompt.txt`, 'dev/art-catalogue/style-profile.json', 'dev/art-catalogue/style-reference-board.png', 'docs/web/assets/task-chair-v3/normalized-four-views.png', 'dev/tools/build_yard_fence.mjs', output]) files[p] = hash(await readFile(p));
if (!process.argv.includes('--verify')) await writeFile(`${source}/derivation.json`, JSON.stringify({ tool: 'built-in image_gen', generation_id: 'exec-0fafe280-0668-454a-bf30-cc892f6181cb', style_profile: 'startup-valley-cozy-pixel-v1', operations: 'Per-component alpha bounds, explicit nearest resize, binary alpha at128, fixed atlas placement. No raster rotation, repainting or runtime scaling.', crops, files }, null, 2) + '\n');
console.log(`${process.argv.includes('--verify') ? 'Verified' : 'Built'} ${output}`);
