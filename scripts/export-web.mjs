import { mkdir, mkdtemp, rename, rm, writeFile, access, cp } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { loadConfig, isMain } from './lib/config.mjs';
import { diagnose, printDiagnosis } from './doctor.mjs';
import { validateExport } from './validate-web.mjs';
import { validateAssets } from './validate-assets.mjs';

export function run(bin, args, cwd, label = 'Godot') {
  return new Promise((accept, reject) => {
    const child = spawn(bin, args, { cwd, stdio: 'inherit', shell: false });
    child.once('error', reject);
    child.once('exit', (code, signal) => code === 0 ? accept() : reject(new Error(`${label} exited with ${signal ?? code}. The previous dist build was preserved.`)));
  });
}

export async function publishDirectory(staging, destination, backup) {
  let hadPrevious = false;
  try { await access(destination); hadPrevious = true; } catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (hadPrevious) await rename(destination, backup);
  try { await rename(staging, destination); }
  catch (error) {
    if (hadPrevious) {
      try { await rename(backup, destination); }
      catch { throw new Error(`Could not restore the previous build automatically. It is preserved at ${backup}. Original error: ${error.message}`); }
    }
    throw error;
  }
  if (hadPrevious) await rm(backup, { recursive: true, force: true });
}

export async function exportWeb({ assetPreview = false } = {}) {
  const config = await loadConfig();
  if (assetPreview) config.dist = resolve(config.root, '.build/asset-preview');
  const buildRoot = resolve(config.root, '.build');
  await mkdir(buildRoot, { recursive: true });
  const lockPath = resolve(buildRoot, 'export.lock');
  try { await mkdir(lockPath); }
  catch (error) { if (error.code === 'EEXIST') throw new Error('An export is already running. If a prior process was killed, remove .build/export.lock after checking it is no longer running.'); throw error; }
  let temporary;
  try {
    const diagnosis = await diagnose(config);
    printDiagnosis(diagnosis);
    if (diagnosis.errors.length) throw new Error('Resolve the items above, then export again.');
    temporary = await mkdtemp(resolve(buildRoot, 'export-'));
    const staging = resolve(temporary, 'output');
    await mkdir(staging);
    await run(process.env.NPM_BIN || 'npm', ['run', 'build'], resolve(config.root, 'web'), 'Browser runtime build');
    await run(diagnosis.engine.bin, ['--headless', '--path', config.projectPath, '--import'], config.root);
    const assets = validateAssets({ root: config.root, allowUnreviewed: assetPreview });
    if (!assets.ok) throw new Error(`Runtime asset gate failed:\n${assets.errors.join('\n')}`);
    for (const warning of assets.warnings) console.warn(`Asset review: ${warning}`);
    await run(diagnosis.engine.bin, ['--headless', '--path', config.projectPath, '--export-release', config.preset, resolve(staging, 'index.html')], config.root);
    await cp(resolve(config.root, 'web/dist'), resolve(staging, 'web'), { recursive: true });
    await access(resolve(staging, 'web/bridge.js'));
    await access(resolve(staging, 'web/worker.js'));
    const report = await validateExport(staging);
    // Godot uses stable file names. Revalidate all of them so releases cannot mix
    // an old loader with a new WASM/PCK. Deploy the entire directory atomically.
    await writeFile(resolve(staging, '_headers'), '/*\n  Cache-Control: no-cache\n  X-Content-Type-Options: nosniff\n\n/*.wasm\n  Content-Type: application/wasm\n');
    await writeFile(resolve(staging, 'build-info.json'), JSON.stringify({ engine: diagnosis.engine.output, preset: config.preset, builtAt: new Date().toISOString(), assetReview: assets.mode, ...report }, null, 2) + '\n');
    await publishDirectory(staging, config.dist, resolve(temporary, 'previous'));
    console.log(`Web export ready at ${config.dist}. Serve it with node scripts/serve.mjs${assetPreview ? ' --asset-preview' : ''}.`);
  } finally {
    try {
      if (temporary) {
        let hasRecoveryBackup = false;
        try { await access(resolve(temporary, 'previous')); hasRecoveryBackup = true; }
        catch (error) { if (error.code !== 'ENOENT') throw error; }
        if (!hasRecoveryBackup) await rm(temporary, { recursive: true, force: true });
      }
    } finally {
      // A cleanup failure must not leave a lock that blocks every later build.
      await rm(lockPath, { recursive: true, force: true });
    }
  }
}

if (isMain(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args.some(arg => arg !== '--asset-preview')) throw new Error('Supported option: --asset-preview');
    await exportWeb({ assetPreview: args.includes('--asset-preview') });
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
