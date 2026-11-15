import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, rm, symlink } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { identifyBuild } from '../scripts/lib/build-identity.mjs';
import { packageDemo } from '../scripts/package-demo.mjs';

async function fixture(t) {
  const root = await mkdtemp(resolve(tmpdir(), 'startup-demo-package-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  await mkdir(resolve(root, 'game'));
  await mkdir(resolve(root, 'dist/web'), { recursive: true });
  await writeFile(resolve(root, 'godot-web.config.json'), JSON.stringify({ projectDir: 'game', preset: 'Web', port: 5173, godotVersion: '4.7.2' }));
  const files = {
    'index.html': '<script src="index.js"></script>', 'index.js': '// fixture',
    'index.wasm': Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]), 'index.pck': 'GDPCfixture',
    'web/worker.js': '// worker', 'web/bridge.js': '// bridge',
  };
  for (const [name, bytes] of Object.entries(files)) await writeFile(resolve(root, 'dist', name), bytes);
  const identity = await identifyBuild(resolve(root, 'dist'));
  await writeFile(resolve(root, 'dist/build-info.json'), JSON.stringify({ assetReview: 'release', ...identity }));
  const png = resolve(root, 'capture.png'), notes = resolve(root, 'notes.md');
  await writeFile(png, Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=', 'base64'));
  await writeFile(notes, 'Fixture controls');
  return { root, screenshots: [png, png, png], notes };
}

test('build identity covers worker changes and is unaffected by metadata', async t => {
  const options = await fixture(t), dist = resolve(options.root, 'dist');
  const initial = await identifyBuild(dist);
  await writeFile(resolve(dist, 'build-info.json'), 'metadata changed');
  assert.deepEqual(await identifyBuild(dist), initial);
  await writeFile(resolve(dist, 'web/worker.js'), '// different worker');
  assert.notEqual((await identifyBuild(dist)).buildId, initial.buildId);
});

test('build identity refuses symlinks rather than packaging outside files', async t => {
  const options = await fixture(t);
  await symlink(options.notes, resolve(options.root, 'dist/leak.md'));
  await assert.rejects(identifyBuild(resolve(options.root, 'dist')), /symlink/);
});

test('packaging rejects preview and modified release payloads', async t => {
  const options = await fixture(t), dist = resolve(options.root, 'dist');
  const identity = await identifyBuild(dist);
  await writeFile(resolve(dist, 'build-info.json'), JSON.stringify({ assetReview: 'preview', ...identity }));
  await assert.rejects(packageDemo(options), /release-reviewed/);
  await writeFile(resolve(dist, 'build-info.json'), JSON.stringify({ assetReview: 'release', ...identity }));
  await writeFile(resolve(dist, 'web/bridge.js'), '// changed after export');
  await assert.rejects(packageDemo(options), /identity/);
});

test('packaging requires current screenshot files and a complete worker bundle', async t => {
  const options = await fixture(t);
  await assert.rejects(packageDemo({ ...options, screenshots: [] }), /at least three/);
  await writeFile(options.screenshots[0], 'not an image');
  await assert.rejects(packageDemo(options), /not PNG/);
  await rm(resolve(options.root, 'dist/web/worker.js'));
  await assert.rejects(packageDemo(options), /ENOENT/);
});

test('release ZIP preserves the playable files, screenshots and matching manifest', async t => {
  const options = await fixture(t);
  const execute = promisify(execFile);
  const result = await packageDemo(options);
  const { stdout } = await execute(process.env.UNZIP_BIN || 'unzip', ['-p', result.path, 'manifest.json']);
  const manifest = JSON.parse(stdout);
  assert.equal(manifest.buildId, result.buildId);
  assert.equal(manifest.files.filter(file => file.path.startsWith('screenshots/')).length, 3);
  assert.equal((await execute(process.env.UNZIP_BIN || 'unzip', ['-p', result.path, 'game/web/worker.js'])).stdout, '// worker');
  assert.match(await readFile(`${result.path}.sha256`, 'utf8'), new RegExp(`^${result.sha256}  startup-valley-`));
});
