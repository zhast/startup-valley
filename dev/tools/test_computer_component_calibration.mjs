#!/usr/bin/env node
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const directory = path.join(root, 'game/tests/fixtures/furniture-calibration/kits');
const width = 192, height = 224, pixels = width * height;
const regions = {monitor: [0, 0, 192, 127], keyboard: [79, 127, 31, 11], mouse: [112, 129, 6, 8]};
const bounds = {monitor: [80, 97, 33, 30], keyboard: [79, 127, 31, 11], mouse: [112, 129, 6, 8]};
let checks = 0;
const check = (condition, message) => { checks++; assert.ok(condition, message); };
const rgba = file => {
  const png = readFileSync(file);
  check(png.subarray(1, 4).toString() === 'PNG', `${file}: PNG`);
  check(png.readUInt32BE(16) === width && png.readUInt32BE(20) === height, `${file}: registered192x224`);
  const data = execFileSync('magick', [file, '-depth', '8', 'RGBA:-']);
  check(data.length === pixels * 4, `${file}: complete RGBA decode`);
  return data;
};
const inside = (x, y, r) => x >= r[0] && y >= r[1] && x < r[0] + r[2] && y < r[1] + r[3];
const alphaBounds = data => {
  let left = width, top = height, right = -1, bottom = -1, opaque = 0;
  for (let p = 0; p < pixels; p++) if (data[p * 4 + 3]) {
    const x = p % width, y = Math.floor(p / width);
    left = Math.min(left, x); top = Math.min(top, y); right = Math.max(right, x); bottom = Math.max(bottom, y); opaque++;
  }
  return {bounds: [left, top, right - left + 1, bottom - top + 1], opaque};
};
const source = rgba(path.join(directory, 'computer-north-v2.png'));
let validAlpha = true, hiddenRgb = false, unmapped = 0, overlap = 0;
for (let p = 0; p < pixels; p++) {
  const alpha = source[p * 4 + 3];
  if (alpha !== 0 && alpha !== 255) validAlpha = false;
  if (!alpha && source.subarray(p * 4, p * 4 + 3).some(Boolean)) hiddenRgb = true;
  if (!alpha) continue;
  const owners = Object.values(regions).filter(r => inside(p % width, Math.floor(p / width), r));
  if (!owners.length) unmapped++;
  if (owners.length > 1) overlap++;
}
check(validAlpha, 'source has binary alpha; extraction cannot silently threshold it');
check(!hiddenRgb, 'source transparent RGB is zero, so transparent padding loses no hidden pixels');
check(unmapped === 0, 'every visible source pixel has a component region');
check(overlap === 0, 'no source pixel belongs to two regions');
const sourceHash = createHash('sha256').update(source).digest('hex');
if (process.argv.includes('--source-only')) {
  console.log(JSON.stringify({ok: true, mode: 'source-only', checks, rgbaSha256: sourceHash, source: alphaBounds(source)}, null, 2));
  process.exit(0);
}
const union = Buffer.alloc(source.length);
const measurements = {};
for (const [name, region] of Object.entries(regions)) {
  const data = rgba(path.join(directory, `computer-north-v2-${name}.png`));
  let changedPixels = 0, outsidePixels = 0, duplicatePixels = 0;
  for (let p = 0; p < pixels; p++) {
    const index = p * 4, expected = inside(p % width, Math.floor(p / width), region) ? source.subarray(index, index + 4) : Buffer.alloc(4);
    if (!data.subarray(index, index + 4).equals(expected)) changedPixels++;
    if (data[index + 3] && !inside(p % width, Math.floor(p / width), region)) outsidePixels++;
    if (data[index + 3]) {
      if (union[index + 3]) duplicatePixels++;
      data.copy(union, index, index, index + 4);
    }
  }
  check(changedPixels === 0, `${name}: every RGBA byte equals the corresponding untouched source region`);
  check(outsidePixels === 0, `${name}: all padding outside atlas region is transparent`);
  check(duplicatePixels === 0, `${name}: nonoverlapping registered union`);
  measurements[name] = alphaBounds(data);
  check(JSON.stringify(measurements[name].bounds) === JSON.stringify(bounds[name]), `${name}: measured full object bounds; no crop truncation`);
}
check(union.equals(source), 'three registered components reproduce every original RGBA byte');
const recombined = rgba(path.join(root, 'game/tests/output/computer-components/recombined.png'));
check(recombined.equals(source), 'ImageMagick composited evidence also decodes byte-identically to original');
const clippedDiagnostic = Buffer.from(union);
clippedDiagnostic.fill(0, (127 * width + 80) * 4, (127 * width + 80) * 4 + 4);
check(!clippedDiagnostic.equals(source), 'negative control detects one lost keyboard-top pixel');
const shiftedDiagnostic = Buffer.from(union);
source.copy(shiftedDiagnostic, (138 * width + 80) * 4, (127 * width + 80) * 4, (127 * width + 80) * 4 + 4);
check(!shiftedDiagnostic.equals(source), 'negative control detects component position drift');
let southMeasurement = null;
if (process.argv.includes('--with-south')) {
  const south = rgba(path.join(directory, 'computer-south-v3.png'));
  southMeasurement = alphaBounds(south);
  check(JSON.stringify(southMeasurement.bounds) === JSON.stringify([80, 109, 32, 31]), 'south: exact uniform native bounds');
  check(southMeasurement.bounds[1] + southMeasurement.bounds[3] === 140, 'south: unchanged stand contact boundary140');
  check(southMeasurement.bounds[0] + southMeasurement.bounds[2] / 2 === 96, 'south: monitor center aligned with shared floor-pivotx96');
  const alphaValues = new Set();
  let hidden = false;
  for (let p = 0; p < pixels; p++) {
    alphaValues.add(south[p * 4 + 3]);
    if (!south[p * 4 + 3] && south.subarray(p * 4, p * 4 + 3).some(Boolean)) hidden = true;
  }
  check(alphaValues.size === 2 && alphaValues.has(0) && alphaValues.has(255), 'south: binary generated-alpha normalization');
  check(!hidden, 'south: transparent padding has no hidden matte RGB');
  const rowBounds = y => {
    const xs = [];
    for (let x = 0; x < width; x++) if (south[(y * width + x) * 4 + 3]) xs.push(x);
    return xs.length ? [Math.min(...xs), Math.max(...xs)] : null;
  };
  check(JSON.stringify(rowBounds(110)) === '[80,111]', 'south: full32px monitor body width');
  check(JSON.stringify(rowBounds(133)) === '[81,110]', 'south: last rounded body-outline row133');
  check(JSON.stringify(rowBounds(134)) === '[93,98]', 'south: exposed stand begins134, separating25px body height from31px whole height');
  check(JSON.stringify(rowBounds(139)) === '[90,101]' && rowBounds(140) === null, 'south: whole T-stand retained without contact clipping');
}
console.log(JSON.stringify({ok: true, checks, comparedPixels: pixels, comparedRgbaBytes: source.length,
  floorAnchor: [96, 160], regions, measurements, rgbaSha256: sourceHash,
  recombinedRgbaSha256: createHash('sha256').update(recombined).digest('hex'), southMeasurement}, null, 2));
