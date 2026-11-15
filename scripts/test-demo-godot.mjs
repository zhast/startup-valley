import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, readFile, writeFile, readdir, lstat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Every milestone is reached by input in the real game. Files read below are
// observations; the launcher never seeds or modifies the game's SQLite state.
const repository = fileURLToPath(new URL('..', import.meta.url));
const configuration = JSON.parse(await readFile(join(repository, 'godot-web.config.json'), 'utf8'));
function git(args) {
  try { return execFileSync(process.env.GIT_BIN || 'git', args, { cwd: repository, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim(); }
  catch { return null; }
}
const source = { commit: git(['rev-parse', 'HEAD']), dirty: git(['status', '--porcelain']), node: process.version, startedAt: new Date().toISOString() };
async function runtimeFingerprint() {
  const files = [];
  const excluded = ['game/.godot', 'game/tests', 'game/tools', 'game/assets/source', 'game/web/templates'];
  async function visit(path) {
    if (excluded.some(prefix => path === prefix || path.startsWith(`${prefix}/`))) return;
    const absolute = join(repository, path);
    const stat = await lstat(absolute);
    assert.ok(!stat.isSymbolicLink(), `Runtime fingerprint refuses symlinks: ${path}`);
    if (stat.isDirectory()) {
      for (const child of (await readdir(absolute)).sort()) await visit(`${path}/${child}`);
    } else if (stat.isFile()) {
      const content = await readFile(absolute);
      files.push({ path, bytes: content.length, sha256: createHash('sha256').update(content).digest('hex') });
    }
  }
  for (const path of ['game', 'harness/src', 'harness/dist', 'harness/migrations', 'contracts', 'web/src',
    'harness/package.json', 'harness/package-lock.json', 'web/package.json', 'web/package-lock.json', 'godot-web.config.json']) await visit(path);
  files.sort((a, b) => a.path.localeCompare(b.path));
  return { sha256: createHash('sha256').update(JSON.stringify(files)).digest('hex'), files };
}
const options = Object.fromEntries(process.argv.slice(2).map(value => {
  const [key, ...rest] = value.replace(/^--/, '').split('=');
  return [key, rest.join('=') || true];
}));
const godot = process.env.GODOT_BINARY;
assert.ok(godot, 'Set GODOT_BINARY to Godot 4.7.2');
const output = options.output ? resolve(String(options.output)) : await mkdtemp(join(tmpdir(), 'startup-valley-demo-'));
await mkdir(output, { recursive: true });
const runtimeBefore = await runtimeFingerprint();
await writeFile(join(output, 'runtime-manifest.json'), JSON.stringify(runtimeBefore, null, 2));
const phases = String(options.phases || 'arrival,hire,start,mid,release,visit,outdoor,restored').split(',');
const runs = Number(options.runs || 3);
assert.ok(Number.isInteger(runs) && runs >= 1 && runs <= 10, '--runs must be 1..10');
const sizes = options.size ? [String(options.size).split('x').map(Number)] : [[1280, 720], [1440, 900], [1024, 576]];
const inputOverride = options.input ? String(options.input) : null;
assert.ok(!inputOverride || ['pointer', 'keyboard', 'touch'].includes(inputOverride));
const summaries = [];
const environment = { ...process.env };
for (const name of ['OPENAI_API_KEY', 'OPENROUTER_API_KEY', 'XAI_API_KEY', 'GROK_API_KEY', 'STARTUP_VALLEY_NO_WORKER']) delete environment[name];
try {
  for (let run = 1; run <= runs; run++) {
    const runRoot = join(output, `run-${run}`);
    const data = join(runRoot, 'save');
    await mkdir(runRoot, { recursive: true });
    await mkdir(data); // Refuse reused data: every reported journey starts clean.
    const [width, height] = sizes[(run - 1) % sizes.length];
    const input = inputOverride || (run === 2 ? 'keyboard' : 'pointer');
    let previous;
    const runPhases = options['reset-check'] && run === runs ? [...phases, 'reset', 'reset_restored'] : phases;
    for (const phase of runPhases) {
      console.log(`Godot demo ${run}/${runs}: ${phase}, ${width}×${height}, ${input}`);
      const args = [...(options.render ? [] : ['--headless']), '--path', join(repository, 'game'), '--script', 'res://tests/test_demo_journey.gd', '--log-file', join(runRoot, `${phase}-engine.log`)];
      const env = { ...environment, STARTUP_VALLEY_NODE: process.execPath, STARTUP_VALLEY_DATA_DIR: data,
        STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: '1', STARTUP_VALLEY_FAKE_PROVIDER: '0', STARTUP_VALLEY_DEMO_PHASE: phase,
        STARTUP_VALLEY_DEMO_OUTPUT: runRoot, STARTUP_VALLEY_DEMO_RUN: String(run), STARTUP_VALLEY_DEMO_INPUT: input,
        STARTUP_VALLEY_DEMO_WIDTH: String(width), STARTUP_VALLEY_DEMO_HEIGHT: String(height), STARTUP_VALLEY_DEMO_EXPECTED: previous || '' };
      const child = spawn(godot, args, { env, stdio: ['ignore', 'pipe', 'pipe'] });
      let text = '';
      for (const stream of [child.stdout, child.stderr]) stream.on('data', chunk => {
        text += chunk;
        // Godot can keep its loop alive after a script fails to instantiate.
        // Stop immediately rather than waste the whole bounded phase timeout.
        if (/SCRIPT ERROR|ERROR:/u.test(text)) child.kill('SIGTERM');
      });
      const code = await new Promise((accept, reject) => {
        const timer = setTimeout(() => { child.kill('SIGTERM'); reject(new Error(`Phase timeout: ${phase}`)); }, 60_000);
        child.once('error', error => { clearTimeout(timer); reject(error); });
        child.once('exit', value => { clearTimeout(timer); accept(value); });
      });
      await writeFile(join(runRoot, `${phase}.log`), text);
      assert.equal(code, 0, `${phase} failed\n${text}`);
      assert.doesNotMatch(text, /SCRIPT ERROR|ERROR:/u, `${phase} runtime error`);
      const resultPath = join(runRoot, `${phase}.json`);
      const result = JSON.parse(await readFile(resultPath, 'utf8'));
      assert.deepEqual(result.failures, [], phase);
      assert.equal(`${result.engine.major}.${result.engine.minor}.${result.engine.patch}`, configuration.godotVersion, 'Test the pinned engine version');
      assert.ok(Number.isInteger(result.workerPid) && result.workerPid > 0, 'A real production worker process was running');
      const alive = () => {
        try { process.kill(result.workerPid, 0); return true; }
        catch (error) { if (error.code === 'ESRCH') return false; throw error; }
      };
      const exitDeadline = Date.now() + 3000;
      while (alive() && Date.now() < exitDeadline) await new Promise(resolve => setTimeout(resolve, 50));
      assert.equal(alive(), false, 'Graceful game shutdown leaves no tested worker process alive');
      summaries.push({ run, phase, width, height, input, checks: result.checks, captures: result.captures, snapshot: result.snapshot });
      previous = resultPath;
    }
  }
  const sourceAfter = { commit: git(['rev-parse', 'HEAD']), dirty: git(['status', '--porcelain']) };
  const sourceUnchanged = source.commit !== null && source.commit === sourceAfter.commit && source.dirty === sourceAfter.dirty;
  const runtimeAfter = await runtimeFingerprint();
  const runtimeUnchanged = runtimeBefore.sha256 === runtimeAfter.sha256;
  await writeFile(join(output, 'result.json'), JSON.stringify({ ok: runtimeUnchanged, source, sourceAfter, sourceUnchanged,
    runtimeBefore: runtimeBefore.sha256, runtimeAfter: runtimeAfter.sha256, runtimeUnchanged, summaries }, null, 2));
  assert.ok(runtimeUnchanged, 'Production runtime content changed during the run; repeat affected acceptance on frozen content');
  if (!sourceUnchanged) console.warn('Git metadata changed; the recorded runtime-content fingerprint stayed identical.');
  console.log(`PASS: ${summaries.length} actual Godot phases. Evidence: ${output}`);
} catch (error) {
  await writeFile(join(output, 'result.json'), JSON.stringify({ ok: false, source, error: error.stack, summaries }, null, 2));
  console.error(`Evidence: ${output}`);
  throw error;
}
