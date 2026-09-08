#!/usr/bin/env node
// Dev-only publishing inventory. Never stages Git files or starts the game/worker.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parsePngHeader, validateCatalogue } from './validate_art_catalogue.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const OUTPUT_ROOT = 'game/tests/output';
const CATALOGUE = 'dev/art-catalogue/furniture.json';
const HTML = 'dev/art-catalogue/index.html';
const MANIFEST = 'dev/art-catalogue/publish-evidence.json';
const RETAIN_ROOTS = [
  'game/tests/output/art-completion-20260906-final-fit',
  'game/tests/output/art-catalogue-browser-final-20260906-v2',
  'game/tests/output/furnishing-runtime',
  'game/tests/output/furnishing-runtime-motion-20260908-check1',
  'game/tests/output/furnishing-mature-ui-20260908-check1',
  'game/tests/output/furnishing-worker-ui-2026-09-08T19-40-37-904Z-izIYHV',
  'game/tests/output/art-completion-furnishing-20260908-final3',
  'game/tests/output/furnishing-window-poll-20260908-check2',
  'game/tests/output/art-completion-furnishing-push-20260908',
];
// Keep the evidence actually cited by the furnishing handoff, without collecting
// every failed/repeated render or the disposable worker's raw transport stream.
const RETAIN_FILES = [
  'game/tests/output/art-completion-furnishing-20260908-final2/headless-results.json',
  'game/tests/output/art-completion-furnishing-20260908-final/furnishing-parity/godot-results.json',
  'game/tests/output/furnishing-parity/godot-results.json',
  'game/tests/output/furnishing-runtime/decor-manifest.json',
  'game/tests/output/polish-ui-pointer-isolated-20260908-4/polish-audit/ui/manifest.json',
  'game/tests/output/polish-ui-pointer-isolated-20260908-5/polish-audit/ui/manifest.json',
];
const ALLOWED = new Set(['.png', '.json', '.log']);
const SKIP_DIRECTORIES = new Set(['.git', '.godot', 'node_modules', '.startup-valley-data']);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const relative = absolute => path.relative(ROOT, absolute).split(path.sep).join('/');
const under = (value, directory) => value === directory || value.startsWith(`${directory}/`);
const allowed = value => path.basename(value) === '.gdignore' || ALLOWED.has(path.extname(value));

// Check every path component: even an in-repository symlink is forbidden here.
function safePath(absolute, { directory = false } = {}) {
  const rel = relative(absolute);
  assert(rel && rel !== '..' && !rel.startsWith('../') && !path.isAbsolute(rel),
    'Publishing references must stay inside the repository');
  let current = ROOT;
  for (const part of rel.split('/')) {
    current = path.join(current, part);
    assert(!fs.lstatSync(current).isSymbolicLink(), `Symlink is not publishing evidence: ${rel}`);
  }
  const facts = fs.statSync(absolute);
  assert(directory ? facts.isDirectory() : facts.isFile(), `Wrong reference kind: ${rel}`);
  assert.equal(fs.realpathSync(absolute), absolute, `Reference resolved outside its literal path: ${rel}`);
  return absolute;
}

function repositoryReference(value) {
  assert(typeof value === 'string' && value && !value.includes('\0'), 'Invalid catalogue path');
  const normalized = value.startsWith('res://') ? `game/${value.slice(6)}` : value;
  assert(!path.isAbsolute(normalized) && !/^[a-z][a-z\d+.-]*:/i.test(normalized),
    'Catalogue references must be repository relative');
  return safePath(path.resolve(ROOT, normalized));
}

export function collectEvidence() {
  safePath(ROOT + '/' + OUTPUT_ROOT, { directory: true });
  const catalogueBytes = fs.readFileSync(repositoryReference(CATALOGUE));
  const htmlBytes = fs.readFileSync(repositoryReference(HTML));
  const catalogue = JSON.parse(catalogueBytes);
  const selected = new Set();
  const checked = new Set();
  const queue = [];

  function retain(absolute) {
    const rel = relative(absolute);
    if (!under(rel, OUTPUT_ROOT) || !allowed(rel)) return;
    safePath(absolute);
    if (!selected.has(rel)) {
      selected.add(rel);
      if (rel.endsWith('.json')) queue.push(absolute);
    }
  }

  // Use the real validator's access paths, not a second approximation of its schema.
  const adapter = {
    file(value) {
      const absolute = repositoryReference(value);
      checked.add(relative(absolute));
      retain(absolute);
      return absolute;
    },
    png(value) { return parsePngHeader(fs.readFileSync(this.file(value))); },
    count() { return checked.size; },
  };
  const validation = validateCatalogue(catalogue, adapter);
  assert(validation.ok, `Catalogue validation failed:\n${validation.errors.join('\n')}`);

  // HTML links are deliberately local. Internal anchors do not identify evidence.
  for (const match of htmlBytes.toString().matchAll(/\b(?:href|src)="([^"]+)"/g)) {
    const raw = match[1].replaceAll('&amp;', '&');
    if (raw.startsWith('#')) continue;
    const value = decodeURIComponent(raw.split('#')[0]);
    assert(!path.isAbsolute(value) && !/^[a-z][a-z\d+.-]*:/i.test(value), 'Nonlocal catalogue URL');
    retain(safePath(path.resolve(ROOT, path.dirname(HTML), value)));
  }
  const directEvidenceFiles = selected.size;

  // JSON reports mix file references, commands and prose. Only existing allowed
  // evidence files are read; no command, external URL, database or movie is opened.
  function referencedValue(value, base) {
    if (typeof value !== 'string' || !value || value.length > 4096 || value.includes('\0')) return;
    let absolute;
    if (value.startsWith('res://')) absolute = path.resolve(ROOT, 'game', value.slice(6));
    else if (value.startsWith('game/') || value.startsWith('dev/')) absolute = path.resolve(ROOT, value);
    else if (path.isAbsolute(value)) {
      // Reports retain their original checkout location. Rebase only the known
      // evidence suffix; never inspect the historical absolute filesystem path.
      const marker = '/game/tests/output/';
      const suffix = value.indexOf(marker);
      if (suffix < 0) return;
      absolute = path.resolve(ROOT, value.slice(suffix + 1));
    }
    else {
      if (/^[a-z][a-z\d+.-]*:/i.test(value)) return;
      absolute = path.resolve(base, value);
    }
    const rel = relative(absolute);
    if (!under(rel, OUTPUT_ROOT) || !allowed(rel)) return;
    // Validate parents before touching the final file. Missing historical paths
    // are not followed; dangling or parent symlinks fail instead of disappearing.
    try { retain(absolute); } catch (error) { if (error.code === 'ENOENT') return; throw error; }
  }
  function strings(node, base) {
    if (typeof node === 'string') referencedValue(node, base);
    else if (node && typeof node === 'object') for (const value of Object.values(node)) strings(value, base);
  }
  function tree(directory) {
    safePath(directory, { directory: true });
    for (const item of fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
      const absolute = path.join(directory, item.name);
      if (item.isDirectory()) {
        if (!SKIP_DIRECTORIES.has(item.name)) tree(absolute);
      } else if (allowed(item.name)) retain(absolute);
    }
  }
  for (const directory of RETAIN_ROOTS) tree(path.resolve(ROOT, directory));
  for (const file of RETAIN_FILES) retain(repositoryReference(file));
  // These are already tracked import guards; keep them in the portable inventory.
  retain(repositoryReference('game/tests/output/.gdignore'));
  retain(repositoryReference('game/tests/output/polish-audit/.gdignore'));
  for (let index = 0; index < queue.length; index += 1) {
    const absolute = queue[index];
    strings(JSON.parse(fs.readFileSync(absolute)), path.dirname(absolute));
  }

  const files = [...selected].sort().map(value => {
    const bytes = fs.readFileSync(repositoryReference(value));
    return { path: value, bytes: bytes.length, sha256: hash(bytes) };
  });
  assert.equal(hash(fs.readFileSync(repositoryReference(CATALOGUE))), hash(catalogueBytes), 'Catalogue changed during inventory');
  assert.equal(hash(fs.readFileSync(repositoryReference(HTML))), hash(htmlBytes), 'HTML changed during inventory');
  return {
    schema_version: 1,
    purpose: 'Portable retained art evidence; no game state or raw movies',
    catalogue: { path: CATALOGUE, sha256: hash(catalogueBytes) },
    html: { path: HTML, sha256: hash(htmlBytes) },
    policy: {
      root: OUTPUT_ROOT,
      allowed_extensions: [...ALLOWED].sort(),
      allowed_exact_basename: '.gdignore',
      additional_complete_roots: RETAIN_ROOTS,
      additional_report_files: RETAIN_FILES,
      closure: 'Actual validator files, local HTML targets, recursive existing local JSON file references',
      excluded: ['raw movies', 'raw JSONL transport', 'SQLite databases and sidecars', 'caches', 'unreferenced historical captures'],
      symlinks: 'forbidden',
    },
    validation: { checks: validation.checks, catalogue_files: checked.size, direct_evidence_files: directEvidenceFiles },
    total_files: files.length,
    total_bytes: files.reduce((sum, item) => sum + item.bytes, 0),
    files,
  };
}

function main() {
  const args = process.argv.slice(2);
  const known = new Set(['--write-manifest', '--check', '--check-index', '--help']);
  assert(args.every(value => known.has(value)), 'Unknown argument; use --help');
  assert(!(args.includes('--write-manifest') && args.includes('--check')), 'Choose --write-manifest or --check, not both');
  if (args.includes('--help')) {
    console.log('Usage: node dev/tools/publish_art_evidence.mjs [--write-manifest | --check] [--check-index]\nDefault: read-only inventory. --write-manifest writes only dev/art-catalogue/publish-evidence.json. --check requires exact deterministic bytes. --check-index verifies selected paths exist in the Git index; it never stages anything.');
    return;
  }
  const manifest = collectEvidence();
  const bytes = JSON.stringify(manifest, null, 2) + '\n';
  if (args.includes('--write-manifest')) {
    const target = path.resolve(ROOT, MANIFEST);
    safePath(path.dirname(target), { directory: true });
    if (fs.existsSync(target) || (() => { try { fs.lstatSync(target); return true; } catch { return false; } })()) safePath(target);
    fs.writeFileSync(target, bytes);
  }
  if (args.includes('--check')) assert.equal(fs.readFileSync(repositoryReference(MANIFEST), 'utf8'), bytes, 'Publishing manifest is stale; rerun --write-manifest and review');
  if (args.includes('--check-index')) {
    const indexed = new Set(execFileSync('git', ['ls-files', '--cached', '-z', '--', OUTPUT_ROOT],
      { cwd: ROOT, maxBuffer: 20 * 1024 * 1024 }).toString().split('\0').filter(Boolean));
    const missing = manifest.files.filter(item => !indexed.has(item.path));
    assert.equal(missing.length, 0, `${missing.length} retained evidence files are absent from the Git index; first paths:\n${missing.slice(0, 20).map(item => item.path).join('\n')}`);
  }
  console.log(JSON.stringify({ mode: args.length ? args.join(' ') : 'dry-run', files: manifest.total_files,
    bytes: manifest.total_bytes, MiB: Number((manifest.total_bytes / 1048576).toFixed(3)),
    validator_checks: manifest.validation.checks, direct_evidence_files: manifest.validation.direct_evidence_files,
    manifest: MANIFEST, git_mutated: false }, null, 2));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(); } catch (error) {
    console.error(`Publishing inventory failed: ${error.message}`);
    process.exitCode = 1;
  }
}
