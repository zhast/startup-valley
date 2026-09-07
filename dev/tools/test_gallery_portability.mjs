// Dev-only: Markdown should render on GitHub and from a relocated checkout.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {galleryMarkdown, validateCatalogue} from './validate_art_catalogue.mjs';

const root = path.resolve(import.meta.dirname, '../..');
const bytes = fs.readFileSync(path.join(root, 'dev/art-catalogue/furniture.json'));
const catalogue = JSON.parse(bytes);
const validation = validateCatalogue(catalogue);
assert(validation.ok, validation.errors.join('\n'));
const gallery = galleryMarkdown(catalogue, validation, bytes);
assert.equal(gallery, fs.readFileSync(path.join(root, 'dev/art-catalogue/GALLERY.md'), 'utf8'), 'Generated Markdown gallery is stale');
const images = [...gallery.matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)];
assert.equal(images.length, 175, 'All168 views and seven legacy references have preview links');
for (const [, target] of images) {
  assert(!target.startsWith('/') && !target.includes('/Users/') && !target.includes(':'), 'Image embeds must be repository relative');
  assert(fs.statSync(path.resolve(root, 'dev/art-catalogue', decodeURIComponent(target))).isFile(), 'Image target exists in this checkout');
}
assert(!gallery.includes('Code-native provenance: undefined'), 'Construction method is rendered when note is absent');
assert(!gallery.split('\n').some(line => /[ \t]+$/.test(line)), 'Generated lines have no accidental trailing whitespace');
console.log(`Markdown gallery portability: ${images.length} local previews, fresh bytes and complete provenance passed`);
