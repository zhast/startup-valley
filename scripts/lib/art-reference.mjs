// Shared immutable art-reference and repository-path rules for image/map gates.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
export const STYLE_PATH = 'dev/art-catalogue/style-profile.json';
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const HASH = /^[a-f0-9]{64}$/;
const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));

export function styleReference(root, application = 'not_recorded') {
  const profile = json(localFile(root, STYLE_PATH));
  return {
    id: profile.id, path: STYLE_PATH, sha256: sha256(fs.readFileSync(localFile(root, STYLE_PATH))),
    application, reference_board: profile.board,
    references: profile.references.map(({ id, path, sha256 }) => ({ id, path, sha256 }))
  };
}

export function validateStyleProfile(root) {
  const errors = [];
  try {
    const profile = json(localFile(root, STYLE_PATH));
    if (profile.id !== 'startup-valley-cozy-pixel-v1' || profile.camera_profile !== 'office-square-grid-v1') errors.push('canonical style/camera profile id mismatch');
    if (!same(profile.rules?.grid_px, [32, 32]) || !same(profile.rules?.character_cell_px, [48, 80]) || !same(profile.rules?.character_foot_anchor_px, [24, 72]) || profile.rules?.runtime_scale !== 1 || profile.rules?.sampling !== 'nearest') errors.push('canonical style geometry drift');
    if (!Array.isArray(profile.references) || profile.references.length < 1) errors.push('canonical style references missing');
    for (const record of [...(profile.references ?? []), profile.board, profile.prompt_template]) {
      if (!record || !HASH.test(record.sha256 ?? '') || sha256(fs.readFileSync(localFile(root, record.path))) !== record.sha256) errors.push(`canonical style reference hash mismatch: ${record?.path}`);
    }
  } catch (error) { errors.push(`canonical style profile: ${error.message}`); }
  return { ok: errors.length === 0, errors };
}

export function localFile(root, name) {
  if (typeof name !== 'string' || !name || name.includes('\\') || name.includes('\0') || path.isAbsolute(name)) throw new Error('Expected a repository-relative file path');
  const full = path.resolve(root, name);
  const inside = (base, value) => { const rel = path.relative(base, value); return rel && rel !== '..' && !rel.startsWith(`..${path.sep}`) && !path.isAbsolute(rel); };
  if (!inside(root, full) || !inside(fs.realpathSync(root), fs.realpathSync(full)) || !fs.statSync(full).isFile()) throw new Error(`Not a regular repository file: ${name}`);
  return full;
}

