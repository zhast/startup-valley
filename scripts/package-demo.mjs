import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { access, cp, mkdir, mkdtemp, readFile, rename, rm, writeFile } from 'node:fs/promises';
import { basename, resolve } from 'node:path';
import { loadConfig, isMain } from './lib/config.mjs';
import { identifyBuild } from './lib/build-identity.mjs';
import { validateExport } from './validate-web.mjs';

const execute = promisify(execFile);
const PNG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

export async function packageDemo({ root, screenshots, notes } = {}) {
  const config = await loadConfig(root);
  if (!Array.isArray(screenshots) || screenshots.length < 3) throw new Error('Provide at least three current Godot screenshots with --screenshot.');
  const notesPath = notes || resolve(config.root, 'docs/DEMO_CONTROLS.md');
  const notesText = await readFile(notesPath, 'utf8');
  if (!notesText.trim()) throw new Error('Demo controls and limitations notes are empty.');
  await validateExport(config.dist);
  for (const required of ['web/bridge.js', 'web/worker.js']) await access(resolve(config.dist, required));
  const metadata = JSON.parse(await readFile(resolve(config.dist, 'build-info.json'), 'utf8'));
  if (metadata.assetReview !== 'release') throw new Error('Only a release-reviewed export may be packaged.');
  const identity = await identifyBuild(config.dist);
  if (metadata.buildId !== identity.buildId || JSON.stringify(metadata.payloadFiles) !== JSON.stringify(identity.payloadFiles)) {
    throw new Error('Export identity is missing or differs from its files. Rebuild the complete release before packaging.');
  }
  const images = [];
  for (const path of screenshots) {
    const bytes = await readFile(path);
    // The in-app browser returns JPEG captures; preserve the original bytes.
    const png = bytes.subarray(0, PNG.length).equals(PNG);
    const jpeg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
    if (!png && !jpeg) throw new Error(`Screenshot is not PNG or JPEG: ${basename(path)}`);
    images.push({ source: path, bytes });
  }
  const releases = resolve(config.root, '.build/releases');
  await mkdir(releases, { recursive: true });
  const temporary = await mkdtemp(resolve(releases, '.package-'));
  try {
    const stage = resolve(temporary, 'demo');
    await mkdir(resolve(stage, 'screenshots'), { recursive: true });
    await cp(config.dist, resolve(stage, 'game'), { recursive: true });
    await writeFile(resolve(stage, 'README.md'), notesText);
    for (let i = 0; i < images.length; i++) {
      await writeFile(resolve(stage, 'screenshots', `${String(i + 1).padStart(2, '0')}-${basename(images[i].source)}`), images[i].bytes);
    }
    const packagedIdentity = await identifyBuild(resolve(stage, 'game'));
    if (packagedIdentity.buildId !== identity.buildId) throw new Error('Export changed while packaging; retry after the build finishes.');
    const packageIdentity = await identifyBuild(stage);
    await writeFile(resolve(stage, 'manifest.json'), JSON.stringify({
      buildId: identity.buildId,
      builtAt: metadata.builtAt,
      engine: metadata.engine,
      verification: 'Export structure, payload hashes and ZIP integrity checked. Gameplay evidence is recorded separately in the acceptance report.',
      packageId: packageIdentity.buildId,
      files: packageIdentity.payloadFiles,
    }, null, 2) + '\n');
    const temporaryZip = resolve(temporary, 'demo.zip');
    // Both tools receive fixed arguments and explicit paths; no shell is used.
    try {
      await execute(process.env.ZIP_BIN || 'zip', ['-q', '-r', '-X', temporaryZip, '.'], { cwd: stage });
      await execute(process.env.UNZIP_BIN || 'unzip', ['-tq', temporaryZip]);
    } catch (error) {
      throw new Error(`Could not create and verify the ZIP (zip and unzip are required): ${error.message}`);
    }
    const filename = `startup-valley-${identity.buildId}.zip`;
    const path = resolve(releases, filename);
    const bytes = await readFile(temporaryZip);
    const sha256 = createHash('sha256').update(bytes).digest('hex');
    await rename(temporaryZip, path);
    await writeFile(`${path}.sha256`, `${sha256}  ${filename}\n`);
    console.log(`Packaged ${path}\nSHA256 ${sha256}`);
    return { path, sha256, bytes: bytes.length, buildId: identity.buildId };
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
}

if (isMain(import.meta.url)) {
  try {
    const options = { screenshots: [] };
    const args = process.argv.slice(2);
    while (args.length) {
      const key = args.shift();
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error('Usage: npm run package:demo -- --screenshot path.png-or-jpg (at least 3) [--notes path.md]');
      if (key === '--screenshot') options.screenshots.push(resolve(value));
      else if (key === '--notes') options.notes = resolve(value);
      else throw new Error(`Unknown option: ${key}`);
    }
    await packageDemo(options);
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
