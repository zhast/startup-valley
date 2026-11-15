import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Deliberately drive the exported Godot canvas. Diagnostics only observe real
// responses; this test never calls the worker protocol or injects game state.
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || new URL('../../web/node_modules/playwright-core/index.mjs', import.meta.url).href);
const baseURL = process.env.BASE_URL || 'http://127.0.0.1:5177';
assert.ok(['127.0.0.1', 'localhost', '[::1]'].includes(new URL(baseURL).hostname), 'Use a disposable localhost build');
const artifacts = process.env.ARTIFACT_DIR || await mkdtemp(join(tmpdir(), 'startup-valley-playtest-'));
await mkdir(artifacts, { recursive: true });
const chrome = ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/usr/bin/google-chrome'].find(existsSync);
const executablePath = process.env.CHROME_PATH || process.env.BROWSER_EXECUTABLE || chrome;
const browser = await chromium.launch({ executablePath, headless: true });
const context = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
const page = await context.newPage();
const errors = [];
const consoleLog = [];
const checkpoints = [];
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => {
  consoleLog.push({ type: message.type(), text: message.text() });
  if (message.type() === 'error') errors.push(message.text());
});
const settle = () => page.waitForTimeout(300);
const diagnostics = () => page.evaluate(() => window.StartupValleyWorker.diagnostics());
async function capture(name) {
  await page.screenshot({ path: join(artifacts, `${name}.png`) });
  checkpoints.push(name);
  console.log(name);
}
async function key(value) { await page.keyboard.press(value); await settle(); }
async function click(x, y) {
  // Logical Godot coordinates, with the 16:9 viewport letterboxed by the shell.
  const rect = await page.locator('#canvas').boundingBox();
  const scale = Math.min(rect.width / 1280, rect.height / 720);
  await page.mouse.click(rect.x + (rect.width - 1280 * scale) / 2 + x * scale,
    rect.y + (rect.height - 720 * scale) / 2 + y * scale);
  await settle();
}
async function cursorAt(name, x, y, expectedHotspot) {
  const rect = await page.locator('#canvas').boundingBox();
  const scale = Math.min(rect.width / 1280, rect.height / 720);
  await page.mouse.move(rect.x + (rect.width - 1280 * scale) / 2 + x * scale,
    rect.y + (rect.height - 720 * scale) / 2 + y * scale);
  await settle();
  const cursor = await page.locator('#canvas').evaluate(async canvas => {
    const css = getComputedStyle(canvas).cursor;
    const match = css.match(/url\(["']?(.*?)["']?\)\s*(\d+)\s+(\d+)/);
    if (!match) return { css };
    const image = new Image();
    image.src = match[1];
    await image.decode();
    const bitmap = document.createElement('canvas');
    bitmap.width = image.width;
    bitmap.height = image.height;
    const context = bitmap.getContext('2d');
    context.drawImage(image, 0, 0);
    const hotspot = [Number(match[2]), Number(match[3])];
    return { css, hotspot, width: image.width, height: image.height,
      alpha: context.getImageData(...hotspot, 1, 1).data[3], png: bitmap.toDataURL() };
  });
  assert.deepEqual(cursor.hotspot, expectedHotspot, `${name} uses the intended hardware cursor hotspot`);
  assert.equal(cursor.width, 32);
  assert.equal(cursor.height, 32);
  assert.equal(cursor.alpha, 255, 'The actual cursor hotspot touches opaque artwork');
  await writeFile(join(artifacts, `${name}-cursor.png`), Buffer.from(cursor.png.split(',')[1], 'base64'));
  const { png, ...summary } = cursor;
  return summary;
}
async function response(method, action) {
  const previous = (await diagnostics()).lastResponses[method]?.id;
  await action();
  await page.waitForFunction(({ method, previous }) => {
    const value = window.StartupValleyWorker.diagnostics().lastResponses[method];
    return value && value.id !== previous;
  }, { method, previous }, { timeout: 20_000 });
  const envelope = (await diagnostics()).lastResponses[method];
  assert.equal(envelope.ok, true, `${method}: ${JSON.stringify(envelope)}`);
  await settle();
  return envelope.result;
}
async function enter() {
  await page.getByRole('button', { name: 'Enter the valley' }).click();
  await page.waitForFunction(() => window.StartupValleyWorker?.diagnostics().lastResponses.bootstrap?.ok, null, { timeout: 60_000 });
  await page.locator('#cover').waitFor({ state: 'hidden' });
  await settle();
  return (await diagnostics()).lastResponses.bootstrap.result;
}

try {
  await page.goto(baseURL);
  const fresh = await enter();
  assert.equal(fresh.employees.length, 0);
  assert.equal(fresh.journey.company.cashCents, 0);
  assert.equal((await diagnostics()).storage, 'opfs-sahpool');
  await capture('01-title');
  await key('Enter'); // Start company, then the focused free hire action.
  await capture('02-hire');
  const hired = await response('hiring.complete', () => key('Enter'));
  assert.ok(hired.employees.some(employee => employee.id === 'mira'));
  const founderGrid = hired.furnishing.placements['founder-workstation'].grid;
  // Target the tabletop art relative to its saved placement, not an old room.
  const founderDesk = [(founderGrid[0] + 0.5) * 32 + 28, (founderGrid[1] + 0.5) * 32 - 34];
  await capture('03-hired');
  await key('Enter'); // Let's find our first idea opens planning directly.
  await capture('04-product');
  const started = await response('tycoon.start', () => key('Enter'));
  assert.equal(started.journey.tycoon.developing.typeId, 'course');
  assert.deepEqual(started.journey.tycoon.developing.staffIds, ['founder', 'mira'], 'Mina joins the first project by default');
  await capture('05-developing');
  await click(455, 518); // The secondary action previews the in-game website.
  await capture('05a-website-preview');
  await key('Enter'); // Back to our project.
  await click(966, 201); // Close progress and return to the office.
  await click(1217, 155);
  await capture('05b-Mina-conversation');
  await click(966, 501); // See our project returns to saved progress.
  let lastDay;
  for (let day = 1; day <= 3; day++) {
    lastDay = await response('day.end', () => key('Enter'));
    assert.equal(lastDay.clock.day, day + 1);
    await capture(`06-day-${day}-saved`);
    await key('Enter'); // Begin next day.
    await click(943, 94); // The persistent story goal opens current progress.
  }
  assert.equal(lastDay.journey.tycoon.developing.ready, true);
  await capture('07-ready');
  const released = await response('tycoon.release', () => key('Enter'));
  assert.ok(released.journey.company.cashCents > 0, 'The real release earns game cash');
  assert.ok(released.journey.tycoon.history.length > 0);
  await capture('08-release-sales');
  await key('Enter'); // Back to office.
  const cursors = {
    floor: await cursorAt('floor', 816, 592, [0, 0]),
    desk: await cursorAt('desk', ...founderDesk, [10, 0]),
  };
  await capture('08b-desk-hover');
  await click(816, 592); // Move across the compact room's bottom walkway.
  await page.waitForTimeout(2000);
  await capture('09-office-movement');
  await key('Escape');
  await capture('10-settings');
  await click(790, 189); // Renovate office; no unsupported Connect button.
  await capture('11-renovate');
  await click(...founderDesk); // Select the painted tabletop.
  await key('m');
  await key('ArrowDown');
  await capture('12-furniture-preview');
  const furnishing = await response('furnishing.update', () => key('Enter'));
  await capture('13-furniture-saved');
  await key('Escape');
  // Observe a real autosave before reload, rather than assume a timer fired.
  await response('game.save', async () => {});
  const beforeReload = await diagnostics();
  await page.reload();
  const restored = await enter();
  assert.equal(restored.journey.company.cashCents, released.journey.company.cashCents);
  assert.equal(restored.journey.company.reputation, released.journey.company.reputation);
  assert.equal(restored.journey.tycoon.history[0].id, released.journey.tycoon.history[0].id);
  assert.deepEqual(restored.furnishing.placements['founder-workstation'].grid, [founderGrid[0], founderGrid[1] + 1]);
  assert.equal(restored.furnishing.revision, hired.furnishing.revision + 1);
  assert.ok(restored.journey.player.x > 600, 'Movement and its save survive reload');
  assert.ok(restored.employees.some(employee => employee.id === 'mira'));
  await capture('14-reloaded');

  const second = await context.newPage();
  await second.goto(baseURL);
  await second.getByRole('button', { name: 'Enter the valley' }).click();
  await second.getByRole('button', { name: 'Reload game' }).waitFor({ state: 'visible', timeout: 15_000 });
  const lockMessage = await second.locator('#status').innerText();
  assert.match(lockMessage, /another.*tab|already.*open|one.*tab/i);
  await second.screenshot({ path: join(artifacts, '15-second-tab-protected.png') });
  await second.close();
  assert.equal((await diagnostics()).state, 'ready', 'Second tab cannot interrupt the active game');
  assert.deepEqual(errors, [], 'No JavaScript or Godot errors in the active game');
  const methods = [...new Set([...Object.keys(beforeReload.lastResponses), ...Object.keys((await diagnostics()).lastResponses)])];
  assert.ok(!methods.some(method =>
    (method.startsWith('credential.') && method !== 'credential.status') ||
    method.startsWith('job.') || method === 'chat.send' || method === 'milestone.evaluate'
  ), 'No provider work or credential operations beyond status');
  await writeFile(join(artifacts, 'result.json'), JSON.stringify({
    ok: true, checkpoints, consoleLog, errors, released: released.journey.company,
    restored: { company: restored.journey.company, player: restored.journey.player, furnishing: restored.furnishing },
    methods, furnishing, lockMessage, cursors,
  }, null, 2));
  console.log(`PASS: real Godot canvas gameplay, OPFS reload and second-tab protection. Evidence: ${artifacts}`);
} catch (error) {
  await page.screenshot({ path: join(artifacts, 'failure.png') }).catch(() => {});
  await writeFile(join(artifacts, 'failure.json'), JSON.stringify({ error: error.stack, consoleLog, errors, checkpoints, diagnostics: await diagnostics().catch(() => null) }, null, 2));
  console.error(`Playtest failed. Evidence: ${artifacts}`);
  throw error;
} finally {
  await context.close();
  await browser.close();
}
