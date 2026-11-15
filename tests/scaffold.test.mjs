import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { once } from 'node:events';
import { ROOT, selectPreset, loadConfig } from '../scripts/lib/config.mjs';
import { inspectProject, inspectEngine } from '../scripts/doctor.mjs';
import { validateExport } from '../scripts/validate-web.mjs';
import { publishDirectory } from '../scripts/export-web.mjs';
import { createPreviewServer, renderPreview } from '../scripts/serve.mjs';

const preset = await readFile(resolve(ROOT, 'templates/export_presets.web.cfg'), 'utf8');
const project = '[application]\nrun/main_scene="res://main.tscn"\nconfig/features=PackedStringArray("4.4", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"';
const config = { preset: 'Web', godotVersion: '4.4.1' };

async function temporary(t) {
  const root = await mkdtemp(resolve(tmpdir(), 'startup-valley-test-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  return root;
}

async function fixture(root) {
  await mkdir(root, { recursive: true });
  await writeFile(resolve(root, 'index.html'), '<script src="index.js"></script>');
  await writeFile(resolve(root, 'index.js'), '/* fixture, not a playable game */');
  await writeFile(resolve(root, 'index.wasm'), Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]));
  await writeFile(resolve(root, 'index.pck'), Buffer.from('GDPCfixture'));
}

async function serve(t, root, config = {}) {
  const server = createPreviewServer({ root, dist: resolve(root, 'dist'), ...config });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => { server.closeAllConnections(); return new Promise(accept => server.close(accept)); });
  return `http://127.0.0.1:${server.address().port}`;
}

test('finds the Web preset without mistaking an existing desktop preset', () => {
  const text = '[preset.0]\nname="Desktop"\nplatform="Windows Desktop"\n' + preset.replaceAll('preset.0', 'preset.2');
  assert.equal(selectPreset(text, 'Web').platform, '"Web"');
  assert.equal(inspectProject(project, text, config).errors.length, 0);
});

test('doctor rejects unsupported rendering, threads, extensions, PWA and C#', () => {
  const altered = preset.replaceAll('=false', '=true');
  const result = inspectProject(project.replace('"gl_compatibility"', '"forward_plus"').replace('"4.4"', '"4.4", "C#"'), altered, config);
  assert.equal(result.errors.length, 5);
});

test('web renderer override can preserve the native renderer', () => {
  const native = project.replace('renderer/rendering_method="gl_compatibility"', 'renderer/rendering_method="forward_plus"\nrenderer/rendering_method.web="gl_compatibility"');
  assert.equal(inspectProject(native, preset, config).errors.length, 0);
});

test('doctor rejects an explicitly empty main scene', () => {
  const result = inspectProject(project.replace('"res://main.tscn"', '""'), preset, config);
  assert.ok(result.errors.some(error => error.includes('main scene')));
});

test('doctor prevents accidental engine migrations and rejects pre-4.3 exports', () => {
  assert.equal(inspectEngine('4.4.1.stable.official.hash', '4.4', '4.4.1').errors.length, 0);
  assert.ok(inspectEngine('4.7.stable.official.hash', '4.4', null).errors.some(x => x.includes('unintended migration')));
  assert.ok(inspectEngine('4.2.2.stable.official.hash', '4.2', null).errors.some(x => x.includes('4.3+')));
  assert.ok(inspectEngine('4.4.1.stable.mono.hash', '4.4', null).errors.length);
});

test('config rejects project paths outside the checkout', async t => {
  const root = await temporary(t);
  await writeFile(resolve(root, 'godot-web.config.json'), JSON.stringify({ ...config, projectDir: '../outside', port: 5173 }));
  await assert.rejects(loadConfig(root), /subdirectory/);
});

test('config keeps source projects out of replaceable build directories', async t => {
  const root = await temporary(t);
  for (const projectDir of ['dist', 'dist/game', '.build', '.build/game']) {
    await writeFile(resolve(root, 'godot-web.config.json'), JSON.stringify({ ...config, projectDir, port: 5173 }));
    await assert.rejects(loadConfig(root), /replaceable generated output/);
  }
  await writeFile(resolve(root, 'godot-web.config.json'), JSON.stringify({ ...config, projectDir: 'startup-valley/game', port: 5173 }));
  assert.equal((await loadConfig(root)).projectPath, resolve(root, 'startup-valley/game'));
});

test('config rejects source symlinks escaping the workspace or entering build output', async t => {
  const root = await temporary(t), outside = await temporary(t);
  await mkdir(resolve(root, 'dist'));
  await symlink(outside, resolve(root, 'external-project'));
  await symlink(resolve(root, 'dist'), resolve(root, 'output-project'));
  for (const projectDir of ['external-project', 'output-project']) {
    await writeFile(resolve(root, 'godot-web.config.json'), JSON.stringify({ ...config, projectDir, port: 5173 }));
    await assert.rejects(loadConfig(root), /resolves/);
  }
});

test('validates the full export and catches HTML served as WASM', async t => {
  const root = await temporary(t);
  await fixture(root);
  assert.equal((await validateExport(root)).files.length, 4);
  await writeFile(resolve(root, 'index.wasm'), '<!DOCTYPE html>');
  await assert.rejects(validateExport(root), /not a WebAssembly/);
});

test('validator rejects truncated and unsupported WebAssembly headers', async t => {
  const root = await temporary(t);
  await fixture(root);
  for (const header of [[0, 97, 115, 109], [0, 97, 115, 109, 2, 0, 0, 0]]) {
    await writeFile(resolve(root, 'index.wasm'), Buffer.from(header));
    await assert.rejects(validateExport(root), /complete version-1 header/);
  }
});

test('rejects incomplete exports, raw templates, and stale PWA output', async t => {
  const root = await temporary(t);
  await fixture(root);
  await writeFile(resolve(root, 'index.html'), '<script src="index.js">$GODOT_CONFIG</script>');
  await assert.rejects(validateExport(root), /unresolved/);
  await fixture(root);
  await writeFile(resolve(root, 'index.service.worker.js'), '// stale');
  await assert.rejects(validateExport(root), /PWA/);
  await rm(resolve(root, 'index.pck'));
  await assert.rejects(validateExport(root), /Missing index.pck/);
});

test('a failed replacement restores the previous complete build', async t => {
  const root = await temporary(t);
  const old = resolve(root, 'dist');
  await mkdir(old);
  await writeFile(resolve(old, 'keep.txt'), 'previous working build');
  await assert.rejects(publishDirectory(resolve(root, 'missing'), old, resolve(root, 'backup')));
  assert.equal(await readFile(resolve(old, 'keep.txt'), 'utf8'), 'previous working build');
});

test('a successful replacement publishes the new complete build and removes the backup', async t => {
  const root = await temporary(t);
  const old = resolve(root, 'dist'), staging = resolve(root, 'staging'), backup = resolve(root, 'backup');
  await mkdir(old);
  await mkdir(staging);
  await writeFile(resolve(old, 'old.txt'), 'old');
  await writeFile(resolve(staging, 'new.txt'), 'new');
  await publishDirectory(staging, old, backup);
  assert.equal(await readFile(resolve(old, 'new.txt'), 'utf8'), 'new');
  await assert.rejects(readFile(resolve(old, 'old.txt')), { code: 'ENOENT' });
  await assert.rejects(readFile(resolve(backup, 'old.txt')), { code: 'ENOENT' });
});

test('preview replaces every required template placeholder and labels itself', async () => {
  const html = renderPreview(await readFile(resolve(ROOT, 'game/web/shell.html'), 'utf8'));
  assert.doesNotMatch(html, /\$GODOT_[A-Z_]+/);
  assert.match(html, /"__preview":true/);
  assert.match(html, /game not connected/);
});

test('server returns WASM MIME, HEAD headers, real missing-file 404s, and no source leaks', async t => {
  const root = await temporary(t);
  await fixture(resolve(root, 'dist'));
  await writeFile(resolve(root, 'secret.txt'), 'not public');
  await symlink(resolve(root, 'secret.txt'), resolve(root, 'dist/leak.txt'));
  const base = await serve(t, root);
  const wasm = await fetch(`${base}/index.wasm`);
  assert.equal(wasm.headers.get('content-type'), 'application/wasm');
  assert.equal(wasm.headers.get('cache-control'), 'no-cache');
  const head = await fetch(`${base}/index.wasm`, { method: 'HEAD' });
  assert.equal(head.headers.get('content-length'), '8');
  assert.equal(await head.text(), '');
  for (const path of ['missing.wasm', '.env', '%2e%2e%2fsecret.txt', 'leak.txt']) assert.equal((await fetch(`${base}/${path}`)).status, 404);
  assert.equal((await fetch(base, { method: 'POST' })).status, 405);
});

test('server shows shell preview until a real export is present', async t => {
  const root = await temporary(t);
  await mkdir(resolve(root, 'game/web'), { recursive: true });
  await writeFile(resolve(root, 'game/web/shell.html'), await readFile(resolve(ROOT, 'game/web/shell.html')));
  const base = await serve(t, root);
  assert.match(await (await fetch(base)).text(), /"__preview":true/);
  assert.equal((await fetch(`${base}/index.wasm`)).status, 404);
  await fixture(resolve(root, 'dist'));
  assert.equal(await (await fetch(base)).text(), '<script src="index.js"></script>');
});

test('preview prefers the incoming project shell and falls back before it is present', async t => {
  const root = await temporary(t), projectPath = resolve(root, 'startup-valley/game');
  await mkdir(resolve(root, 'game/web'), { recursive: true });
  await writeFile(resolve(root, 'game/web/shell.html'), 'fallback $GODOT_CONFIG');
  const base = await serve(t, root, { projectPath });
  assert.equal(await (await fetch(base)).text(), 'fallback {"__preview":true}');
  await mkdir(resolve(projectPath, 'web'), { recursive: true });
  await writeFile(resolve(projectPath, 'web/shell.html'), 'project $GODOT_CONFIG');
  assert.equal(await (await fetch(base)).text(), 'project {"__preview":true}');
});
