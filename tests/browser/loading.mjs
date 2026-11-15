import assert from 'node:assert/strict';
import { mkdtemp, cp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { createRequire } from 'node:module';
import { once } from 'node:events';
const { chromium } = createRequire(new URL('../../web/package.json', import.meta.url))('playwright-core');
import { createPreviewServer } from '../../scripts/serve.mjs';

const repo = resolve(import.meta.dirname, '../..');
const root = await mkdtemp(join(tmpdir(), 'startup-valley-shell-edges-'));
const dist = join(root, 'dist');
await cp(join(repo, 'dist'), dist, { recursive: true });
const server = createPreviewServer({ root: repo, dist, projectPath: join(repo, 'game') });
const handler = server.listeners('request')[0];
server.removeAllListeners('request');
const prefix = '/nested/games/startup-valley';
server.on('request', (req, res) => {
  if (!req.url.startsWith(prefix + '/')) { res.writeHead(404).end(); return; }
  req.url = req.url.slice(prefix.length);
  handler(req, res);
});
server.listen(0, '127.0.0.1');
await once(server, 'listening');
const origin = `http://127.0.0.1:${server.address().port}`;
const url = `${origin}${prefix}/index.html?nested-test=1`;
const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || (process.platform === 'darwin' ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : '/usr/bin/google-chrome'), headless: true });
const results = [];
console.log(JSON.stringify({ artifactRoot: root, url, build: JSON.parse(await readFile(join(dist, 'build-info.json'), 'utf8')) }));
async function run(name, setup, expect) {
  if (process.env.LOADING_CASE && process.env.LOADING_CASE !== name) return;
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  const requests = [];
  await context.route('**/*', async route => {
    requests.push(route.request().url());
    if (!route.request().url().startsWith(origin)) return route.abort();
    if (setup && await setup(route)) return;
    return route.continue();
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  try {
    await page.goto(url);
    await page.locator('#start').click();
    if (expect === 'running') {
      await page.waitForFunction(() => document.body.classList.contains('playing'), null, { timeout: 30_000 });
      await page.waitForFunction(() => window.StartupValleyWorker?.diagnostics().lastResponses.bootstrap?.ok === true);
      assert.equal(await page.locator('#cover').isVisible(), false);
      const other = await context.newPage();
      await other.goto(url);
      await other.locator('#start').click();
      await other.waitForFunction(() => document.querySelector('#status').getAttribute('role') === 'alert');
      const secondStatus = await other.locator('#status').innerText();
      assert.match(secondStatus, /already open in another tab/);
      await other.close();
      await page.screenshot({ path: join(root, `${name}.png`) });
      const diagnostics = await page.evaluate(() => window.StartupValleyWorker.diagnostics());
      results.push({ name, pass: true, secondStatus, state: diagnostics.state, bootstrap: diagnostics.lastResponses.bootstrap.ok, errors, paths: [...new Set(requests.map(x => new URL(x).pathname))] });
    } else {
      await page.waitForFunction(() => document.querySelector('#status').getAttribute('role') === 'alert', null, { timeout: 30_000 });
      const status = await page.locator('#status').innerText();
      assert.match(status, expect);
      assert.equal(await page.locator('#reload').isVisible(), true);
      assert.equal(await page.locator('#canvas').isVisible(), false);
      assert.equal(await page.evaluate(() => document.activeElement.id), 'reload');
      await page.screenshot({ path: join(root, `${name}.png`) });
      results.push({ name, pass: true, status, errors });
    }
  } catch (error) {
    await page.screenshot({ path: join(root, `${name}-failure.png`) }).catch(() => {});
    results.push({ name, pass: false, error: error.message, status: await page.locator('#status').innerText().catch(() => ''), errors });
  } finally { await context.close(); }
  console.log(JSON.stringify(results.at(-1)));
}
const patchWorker = prefix => async route => {
  if (!new URL(route.request().url()).pathname.endsWith('/web/worker.js')) return false;
  const response = await route.fetch();
  await route.fulfill({ response, body: `${prefix}\n${await response.text()}` });
  return true;
};
const block = expression => async route => {
  if (!expression.test(new URL(route.request().url()).pathname)) return false;
  await route.abort('failed'); return true;
};

async function lateEngineCompletion() {
  const name = 'late-engine-completion';
  if (process.env.LOADING_CASE && process.env.LOADING_CASE !== name) return;
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  let releaseDownload;
  let sawDownload;
  const held = new Promise(resolve => { sawDownload = resolve; });
  const release = new Promise(resolve => { releaseDownload = resolve; });
  // Godot creates a fresh prototype inside each constructor. Wrap the actual
  // instance, rather than its public constructor's unused prototype.
  await context.addInitScript(() => {
    window.__engineLifecycle = { initializations: 0, initialized: 0, starts: 0, completions: 0, exits: 0, quitRequests: 0, rejections: [] };
    window.__observeEngine = engine => {
      window.__engineRuntimeActive = () => Boolean(engine.rtenv);
      const init = engine.init;
      const start = engine.start;
      const requestQuit = engine.requestQuit;
      const onExit = engine.config.onExit;
      engine.config.onExit = (...args) => {
        window.__engineLifecycle.exits++;
        return onExit?.(...args);
      };
      engine.init = async function (...args) {
        window.__engineLifecycle.initializations++;
        const result = await Reflect.apply(init, this, args);
        window.__engineLifecycle.initialized++;
        return result;
      };
      engine.requestQuit = function (...args) {
        window.__engineLifecycle.quitRequests++;
        return Reflect.apply(requestQuit, this, args);
      };
      engine.start = async function (...args) {
        window.__engineLifecycle.starts++;
        try {
          const result = await Reflect.apply(start, this, args);
          window.__engineLifecycle.completions++;
          return result;
        } catch (error) {
          window.__engineLifecycle.rejections.push(String(error));
          throw error;
        }
      };
      return engine;
    };
  });
  await context.route('**/*', async route => {
    if (!route.request().url().startsWith(origin)) return route.abort();
    const path = new URL(route.request().url()).pathname;
    if (path.endsWith('/index.html')) {
      const response = await route.fetch();
      const html = await response.text();
      const initialization = 'await Promise.all([engine.init(config.executable), engine.preloadFile(pack, pack)]);';
      assert.ok(html.includes(initialization), 'Observe the actual shell engine before initialization');
      return route.fulfill({ response, body: html.replace(initialization, `window.__observeEngine(engine); ${initialization}`) });
    }
    if (path.endsWith('/index.wasm')) {
      sawDownload();
      await release;
    }
    return route.continue();
  });
  try {
    await page.goto(url);
    // The observer delegates every call to the shipped Godot loader; it does
    // not fabricate successful startup or exit.
    await page.locator('#start').click();
    let downloadTimer;
    try {
      await Promise.race([held, new Promise((_, reject) => { downloadTimer = setTimeout(() => reject(new Error('Godot never requested its WASM download')), 15_000); })]);
    } finally { clearTimeout(downloadTimer); }
    assert.equal(await page.evaluate(() => window.__engineLifecycle.initializations), 1);
    assert.equal(await page.evaluate(() => window.__engineLifecycle.completions), 0);
    assert.equal(await page.evaluate(() => window.StartupValleyWorker.diagnostics().state), 'ready');
    // Exercise the same immediate failure path as a rejected internal fetch,
    // without waiting for the 90-second stalled-download watchdog.
    await page.evaluate(() => window.dispatchEvent(new ErrorEvent('error', {
      error: new Error('Test interruption while Godot WASM is held'),
      message: 'Test interruption while Godot WASM is held', cancelable: true,
    })));
    await page.locator('#reload').waitFor({ state: 'visible' });
    const failureStatus = await page.locator('#status').innerText();
    assert.match(failureStatus, /game files could not finish loading/i);
    await page.waitForFunction(() => window.StartupValleyWorker.diagnostics().state === 'idle');
    releaseDownload();
    await page.waitForFunction(() => window.__engineLifecycle.initialized === 1, null, { timeout: 30_000 });
    await page.waitForFunction(async () => {
      const state = window.StartupValleyWorker.diagnostics().state;
      const locks = await navigator.locks.query();
      return state !== 'ready' && state !== 'starting' && state !== 'stopping'
        && !locks.held.some(lock => lock.name === 'startup-valley-save-owner');
    }, null, { timeout: 10_000 });
    assert.equal(await page.locator('#status').innerText(), failureStatus, 'Late initialization preserves the original error');
    assert.equal(await page.locator('#reload').isVisible(), true);
    assert.equal(await page.locator('#canvas').isVisible(), false);
    assert.equal(await page.evaluate(() => document.body.classList.contains('playing')), false);
    assert.equal(await page.evaluate(() => document.activeElement.id), 'reload');
    const lifecycle = await page.evaluate(() => window.__engineLifecycle);
    assert.equal(lifecycle.starts, 0, 'A cancelled download must never start game scripts');
    assert.equal(lifecycle.completions, 0);
    assert.equal(lifecycle.exits, 0, 'No game started that would need to exit');
    assert.deepEqual(lifecycle.rejections, [], 'The actual held engine initialized successfully');
    assert.deepEqual(errors, [], 'Cancelled initialization must not race audio startup');
    const state = await page.evaluate(() => window.StartupValleyWorker.diagnostics().state);
    await page.screenshot({ path: join(root, `${name}.png`) });
    results.push({ name, pass: true, status: failureStatus, state, lifecycle, errors });
  } catch (error) {
    await page.screenshot({ path: join(root, `${name}-failure.png`) }).catch(() => {});
    results.push({ name, pass: false, error: error.message, status: await page.locator('#status').innerText().catch(() => ''), lifecycle: await page.evaluate(() => ({ ...window.__engineLifecycle, runtimeActive: window.__engineRuntimeActive?.(), worker: window.StartupValleyWorker.diagnostics() })).catch(() => null), errors });
  } finally {
    releaseDownload();
    await context.close();
  }
  console.log(JSON.stringify(results.at(-1)));
}
try {
  await run('nested-real-game', null, 'running');
  await run('unsupported-opfs', patchWorker('Object.defineProperty(navigator.storage,"getDirectory",{value:undefined});'), /Persistent game saves require HTTPS.*Origin Private File System/s);
  await run('denied-opfs', patchWorker('Object.defineProperty(navigator.storage,"getDirectory",{value:async()=>{throw new DOMException("Persistent storage access was denied", "NotAllowedError")}});'), /could not be opened.*denied/is);
  await run('worker-network-failure', block(/\/web\/worker\.js$/), /game worker stopped.*could not load runtime/is);
  await run('sqlite-wasm-network-failure', block(/\/web\/assets\/sqlite3-.*\.wasm$/), /could not be opened/i);
  await run('godot-wasm-network-failure', block(/\/index\.wasm$/), /game files could not finish loading/i);
  await lateEngineCompletion();
  await writeFile(join(root, 'results.json'), JSON.stringify(results, null, 2));
} finally { await browser.close(); server.close(); server.closeAllConnections(); }
console.log(JSON.stringify({ complete: true, passed: results.filter(x => x.pass).length, total: results.length, root }));
process.exitCode = results.length === 0 || results.some(x => !x.pass) ? 1 : 0;
