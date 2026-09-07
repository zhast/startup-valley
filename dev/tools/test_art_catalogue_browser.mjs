// DEV ONLY: real browser inputs against the local read-only catalogue server.
// Use bundled Playwright and a fresh ephemeral headless browser, never a user's
// profile. No installation, external connection, worker or save access.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';

const require = createRequire(import.meta.url);
const [modulePath, executablePath, baseUrl = 'http://127.0.0.1:8876', outputArg = 'game/tests/output/art-catalogue-browser'] = process.argv.slice(2);
assert(modulePath && executablePath, 'Pass bundled Playwright module and browser executable; do not install a dependency.');
assert.equal(new URL(baseUrl).hostname, '127.0.0.1', 'Only the local dev server is in scope.');
const { chromium } = require(modulePath);
const output = resolve(outputArg);
const catalogueBytes = await readFile('dev/art-catalogue/furniture.json');
const catalogue = JSON.parse(catalogueBytes);
const htmlBytes = await readFile('dev/art-catalogue/index.html');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const catalogueSha256 = digest(catalogueBytes);
const htmlSha256 = digest(htmlBytes);
const views = catalogue.families.flatMap(family => family.variants.map(view => ({
  id: `${family.id}-${view.facing}`, status: view.status,
  bucket: ['approved', 'runtime_integrated'].includes(view.status) ? 'accepted'
    : view.deliverable_availability === 'missing' ? 'missing' : 'staged',
})));
const counts = Object.fromEntries(['accepted', 'staged', 'missing'].map(bucket =>
  [bucket, views.filter(view => view.bucket === bucket).length]));
const lifecycleCounts = Object.fromEntries([...new Set(views.map(view => view.status))]
  .map(status => [status, views.filter(view => view.status === status).length]));
const errors = [], requests = [], evidence = [];
let checks = 0;
const check = (ok, message) => { checks++; assert(ok, message); };
const browser = await chromium.launch({ executablePath, headless: true });
await mkdir(output, { recursive: true });
try {
  check(htmlBytes.toString().includes(`SHA-256 <code>${catalogueSha256}</code>`),
    'Gallery embeds the exact current catalogue hash; rebuild stale HTML before review');
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  await context.route('**/*', route => {
    const url = route.request().url();
    requests.push(url);
    return new URL(url).origin === new URL(baseUrl).origin ? route.continue() : route.abort();
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(String(error)));
  const shot = async name => {
    const path = resolve(output, name + '.png');
    await page.screenshot({ path, animations: 'disabled' });
    evidence.push(path);
  };
  const visibleIds = () => page.locator('.family:visible').evaluateAll(nodes => nodes.map(n => n.dataset.familyId));
  const typeSearch = async text => {
    await page.locator('#search').click();
    await page.keyboard.press('Meta+A');
    await page.keyboard.type(text);
  };
  const reset = async () => page.locator('#reset').click();
  const response = await page.goto(baseUrl + '/dev/art-catalogue/index.html', { waitUntil: 'networkidle' });
  check(response?.ok() && digest(await response.body()) === htmlSha256,
    'Local server delivers the exact frozen HTML bytes');
  check((await visibleIds()).length === 42, 'All42 family cards initially visible');
  check(await page.locator('.family .direction').count() === 168, 'All168 directional slots exist');
  const rendered = await page.locator('.family .direction').evaluateAll(nodes => nodes.map(node => ({
    id: node.id, status: node.querySelector('.state-exact').textContent.trim().replaceAll(' ', '_'),
    bucket: node.dataset.bucket,
  })));
  check(JSON.stringify(rendered) === JSON.stringify(views),
    'Every rendered direction has the exact catalogue lifecycle and acceptance bucket');
  const stats = await page.locator('.stats .stat strong').allTextContents();
  check(JSON.stringify(stats.map(Number)) === JSON.stringify([catalogue.families.length, views.length,
    counts.accepted, counts.staged, counts.missing, catalogue.source_inventory.original_png_count]),
    'Visible header totals match actual accepted, staged, missing and original counts');
  await shot('1280-header');
  await typeSearch('cafe');
  check(JSON.stringify(await visibleIds()) === JSON.stringify(['cafe_table']), 'Real typing filters the cafe family');
  const cafe = page.locator('#family-cafe_table');
  await cafe.scrollIntoViewIfNeeded();
  check(await cafe.locator('.direction.accepted').count() === 4, 'Cafe has four accepted library views');
  check((await cafe.innerText()).includes('Approved library'), 'Library acceptance is visibly distinct from runtime');
  const preview = cafe.locator('.native-preview').first();
  await preview.scrollIntoViewIfNeeded();
  const native = await preview.locator('img').evaluate(async image => {
    await image.decode();
    return { loaded: image.complete && image.naturalWidth > 0, width: image.width, height: image.height, nativeWidth: Number(image.dataset.nativeWidth), nativeHeight: Number(image.dataset.nativeHeight), rendering: getComputedStyle(image).imageRendering };
  });
  check(native.loaded && native.width === native.nativeWidth && native.height === native.nativeHeight, 'Loaded preview is native1x, not runtime-scaled');
  check(['pixelated', 'crisp-edges'].includes(native.rendering), 'Preview uses nearest-style sampling');
  await shot('1280-cafe-native');
  const zoom = preview.locator('[data-preview-zoom]');
  await zoom.click();
  check(await zoom.getAttribute('aria-pressed') === 'true', 'Mouse click activates zoom');
  const enlarged = await preview.locator('img').evaluate(image => ({ width: image.width, height: image.height }));
  check(enlarged.width === native.width * 4 && enlarged.height === native.height * 4, 'Exact4x enlargement');
  const extent = await preview.locator('.preview-scroll').evaluate(node => ({ x: node.scrollLeft, y: node.scrollTop, maxX: node.scrollWidth - node.clientWidth, maxY: node.scrollHeight - node.clientHeight }));
  check(extent.x >= 0 && extent.y >= 0 && extent.x <= extent.maxX && extent.y <= extent.maxY, 'Centered artwork stays inside actual scroll extent');
  await shot('1280-cafe-four-times');
  await zoom.press('Enter');
  check(await zoom.getAttribute('aria-pressed') === 'false', 'Keyboard Enter restores native size');
  await preview.getByRole('link', { name: 'Open PNG', exact: true }).click();
  await page.waitForURL('**/north-whole.png');
  const opened = await page.locator('img').evaluate(async image => { await image.decode(); return [image.naturalWidth, image.naturalHeight]; });
  check(opened[0] === native.nativeWidth && opened[1] === native.nativeHeight, 'Actual Open PNG link loads exact native artifact');
  await page.goBack({ waitUntil: 'networkidle' });
  await reset();
  await page.locator('#status').click();
  // macOS headless native select menus ignore synthetic arrow navigation;
  // real keyboard type-ahead selects the visible Staged option reliably.
  await page.keyboard.press('s');
  await page.keyboard.press('Enter');
  check(await page.locator('#status').inputValue() === 'staged', 'Native select keyboard input chooses staged');
  const stagedExpected = catalogue.families.filter(f => f.variants.some(v => ['generated_unreviewed', 'cleanup_required', 'native_review_required'].includes(v.status))).map(f => f.id);
  check(JSON.stringify(await visibleIds()) === JSON.stringify(stagedExpected), 'Staged filter matches actual catalogue lifecycle');
  await shot('1280-staged');
  await reset();
  await typeSearch('definitely-no-such-furniture-427');
  check((await visibleIds()).length === 0 && await page.locator('#no-results').isVisible(), 'No-match state is clear');
  await shot('1280-no-results');
  await reset();
  await page.locator('#search').click();
  await page.keyboard.press('Tab');
  check(await page.locator('#status').evaluate(node => node === document.activeElement), 'Tab moves from search to status');
  check(await page.locator('#status').evaluate(node => parseFloat(getComputedStyle(node).outlineWidth) >= 3), 'Keyboard focus is visibly outlined');
  await shot('1280-keyboard-focus');
  await typeSearch('creative');
  check((await visibleIds()).includes('creative_design_kit'), 'Role search exposes creative toolkit');
  const host = page.locator('#family-creative_design_kit a[href="#family-desk"]').first();
  await host.click();
  check((await visibleIds()).length === 42 && await page.locator('#family-desk').isVisible(), 'Host link clears restrictive filter and reaches desk');
  check(new URL(page.url()).hash === '#family-desk', 'Host link targets exact family anchor');
  for (const width of [1280, 960]) {
    await page.setViewportSize({ width, height: 720 });
    await typeSearch('cafe');
    await cafe.scrollIntoViewIfNeeded();
    const layout = await page.evaluate(() => ({ width: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth }));
    check(layout.scroll <= layout.width, width + 'px page has no horizontal body overflow');
    await shot(width + '-responsive-cafe');
  }
  check(errors.length === 0, 'No page script exceptions');
  check(requests.every(url => new URL(url).origin === new URL(baseUrl).origin), 'No external requests');
  check(digest(await readFile('dev/art-catalogue/furniture.json')) === catalogueSha256,
    'Catalogue bytes remain unchanged throughout review');
  check(digest(await readFile('dev/art-catalogue/index.html')) === htmlSha256,
    'HTML bytes remain unchanged throughout review');
  const summary = { checks, errors, browserVersion: browser.version(), isolatedProfile: true, workerStarted: false, personalSaveAccess: false, catalogueSha256, htmlSha256, counts, lifecycleCounts, evidence, localRequestCount: requests.length, status: 'passed' };
  await writeFile(resolve(output, 'results.json'), JSON.stringify(summary, null, 2) + '\n');
  console.log(JSON.stringify(summary, null, 2));
} catch (error) {
  await writeFile(resolve(output, 'failure.json'), JSON.stringify({ checks, errors, failure: String(error), evidence, status: 'failed' }, null, 2) + '\n');
  throw error;
} finally {
  await browser.close();
}
