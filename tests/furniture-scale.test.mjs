import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { ROOT } from '../scripts/lib/art-reference.mjs';
import { SCALE_CONTRACT, validateFurnitureScale } from '../scripts/validate-furniture-scale.mjs';

const fresh = () => JSON.parse(fs.readFileSync(path.join(ROOT, SCALE_CONTRACT)));
test('current standalone furniture matches reviewed native registration and semantic heights', () => {
  assert.deepEqual(validateFurnitureScale().errors, []);
});
test('native ground pivot and contacts cannot drift away from collision', () => {
  const contract = fresh(); contract.families[0].ground_pivot[1] += 40;
  assert.match(validateFurnitureScale({ contract }).errors.join('\n'), /ground pivot|registered bounds/);
  const moved = fresh(); moved.families[0].contacts[0] = [70, 80];
  assert.match(validateFurnitureScale({ contract: moved }).errors.join('\n'), /contact leaves occupied/);
});
test('seat, desktop and doorway are checked relative to their own floor planes', () => {
  const contract = fresh();
  contract.families.find(x => x.seat).seat.back_y = -70;
  contract.families.find(x => x.tabletop).tabletop.front_floor_y = 200;
  contract.families.find(x => x.opening).opening.width = 90;
  const errors = validateFurnitureScale({ contract }).errors.join('\n');
  assert.match(errors, /seat_rise/); assert.match(errors, /tabletop_rise/); assert.match(errors, /opening_width/);
});
test('unreviewed artwork, profile edits and stale calibration cannot use previous admission', () => {
  const contract = fresh(); contract.families[0].art_sha256 = '0'.repeat(64); contract.families[1].profile_sha256 = '0'.repeat(64); contract.calibration.sha256 = '0'.repeat(64);
  const errors = validateFurnitureScale({ contract }).errors.join('\n');
  assert.match(errors, /artwork changed/); assert.match(errors, /profile changed/); assert.match(errors, /Scale reference changed/);
});
