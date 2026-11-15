import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const html = await readFile(new URL('../game/web/shell.html', import.meta.url), 'utf8');
const source = html.match(/<script>\s*([\s\S]*?)<\/script>/)?.[1];
assert.ok(source, 'Shell must contain its startup script');

function deferred() {
  let resolve, reject;
  const promise = new Promise((accept, fail) => { resolve = accept; reject = fail; });
  return { promise, resolve, reject };
}

// Small event/DOM adapter, deliberately not a browser renderer. It tests the
// actual exported startup script's transitions and focus behavior.
function harness({ config = {}, missingEngine = false, missingWorker = false, workerStart = async () => {}, wasm = true, webgl = true, startGame } = {}) {
  const elements = new Map();
  let focused = null, reloads = 0;
  const instances = [], errors = [];
  class Element {
    constructor(id = '') {
      this.id = id;
      this.events = new Map();
      this.attributes = new Map();
      const tag = html.match(new RegExp(`<[^>]+id="${id}"[^>]*>`))?.[0] ?? '';
      this.hidden = /\shidden(?:\s|>)/.test(tag);
      this.disabled = /\sdisabled(?:\s|>)/.test(tag);
      this.tabIndex = Number(tag.match(/tabindex="(-?\d+)"/)?.[1] ?? -1);
      this.textContent = '';
      const classes = new Set();
      this.classList = { add: name => classes.add(name), remove: name => classes.delete(name), contains: name => classes.has(name) };
    }
    addEventListener(type, callback, options = {}) {
      const list = this.events.get(type) ?? [];
      list.push({ callback, once: options.once });
      this.events.set(type, list);
    }
    async emit(type) {
      if (type === 'click' && this.disabled) return;
      for (const event of [...(this.events.get(type) ?? [])]) {
        if (event.once) this.events.set(type, this.events.get(type).filter(item => item !== event));
        await event.callback();
      }
    }
    setAttribute(name, value) { this.attributes.set(name, String(value)); }
    removeAttribute(name) { this.attributes.delete(name); delete this[name]; }
    focus() { focused = this.id; }
  }
  const document = new Element('document');
  document.body = new Element('body');
  document.getElementById = id => {
    if (!elements.has(id)) elements.set(id, new Element(id));
    return elements.get(id);
  };
  document.fullscreenEnabled = true;
  document.documentElement = new Element('html');
  document.documentElement.requestFullscreen = async () => { document.fullscreenElement = document.documentElement; };
  document.exitFullscreen = async () => { document.fullscreenElement = null; };
  class Engine {
    static isWebGLAvailable(version) { assert.equal(version, 2); return webgl; }
    constructor(configuration) { this.config = configuration; instances.push(this); }
    startGame(options) { this.options = options; return startGame ? startGame(options) : Promise.resolve(); }
  }
  const globals = {
    document,
    location: { reload: () => { reloads++; } },
    console: { error: (...args) => errors.push(args) },
    WebAssembly: wasm ? {} : undefined,
  };
  if (!missingWorker) globals.StartupValleyWorker = { start: workerStart, stop: async () => {}, onError: () => {} };
  if (!missingEngine) globals.Engine = Engine;
  vm.runInNewContext(source.replace('$GODOT_CONFIG', JSON.stringify(config)), globals, { filename: 'godot-shell.js' });
  return { document, instances, errors, get: id => document.getElementById(id), get focused() { return focused; }, get reloads() { return reloads; } };
}

test('preview remains non-playable even without a downloaded engine', async () => {
  const shell = harness({ config: { __preview: true }, missingEngine: true, wasm: false });
  assert.equal(shell.get('start').disabled, true);
  assert.equal(shell.get('start').textContent, 'Awaiting Godot project');
  assert.equal(shell.get('preview-note').hidden, false);
  assert.equal(shell.get('reload').hidden, true);
  await shell.get('start').emit('click');
  assert.equal(shell.instances.length, 0);
});

test('missing runtime or unsupported browser offers a focused recovery action', async () => {
  for (const options of [{ missingEngine: true }, { missingWorker: true }, { wasm: false }, { webgl: false }]) {
    const shell = harness(options);
    assert.equal(shell.get('reload').hidden, false);
    assert.equal(shell.get('canvas').hidden, true);
    assert.equal(shell.focused, 'reload');
    assert.equal(shell.get('status').attributes.get('role'), 'alert');
    assert.equal(shell.instances.length, 0);
    await shell.get('reload').emit('click');
    assert.equal(shell.reloads, 1);
  }
});

test('loads once, preserves exported config, isolates input until ready, and handles progress', async () => {
  const completion = deferred();
  const config = { executable: 'index', mainPack: 'index.pck', persistentPaths: ['/userfs'] };
  const shell = harness({ config, startGame: () => completion.promise });
  assert.equal(shell.instances.length, 0, 'must wait for a player gesture');
  const clicked = shell.get('start').emit('click');
  await new Promise(resolve => setImmediate(resolve));
  const instance = shell.instances[0];
  assert.equal(JSON.stringify(instance.config), JSON.stringify(config));
  assert.equal(shell.get('start').disabled, true);
  assert.equal(shell.get('canvas').inert, true);
  assert.equal(shell.get('canvas').tabIndex, -1);
  await shell.get('start').emit('click');
  assert.equal(shell.instances.length, 1);

  instance.options.onProgress(20, 100);
  assert.equal(shell.get('status').textContent, 'Loading 20%');
  assert.equal(shell.get('progress').max, 100);
  instance.options.onProgress(20, 0);
  assert.equal(shell.get('status').textContent, 'Loading game files…');
  assert.equal(Object.hasOwn(shell.get('progress'), 'value'), false);
  assert.equal(Object.hasOwn(shell.get('progress'), 'max'), false);
  instance.options.onProgress(150, 100);
  assert.equal(shell.get('status').textContent, 'Loading 100%');

  completion.resolve();
  await clicked;
  assert.equal(shell.get('cover').hidden, true);
  assert.equal(shell.get('canvas').inert, false);
  assert.equal(shell.get('canvas').tabIndex, 0);
  assert.equal(shell.focused, 'canvas');
  assert.equal(shell.document.body.classList.contains('playing'), true);
  instance.options.onProgress(1, 100);
  assert.equal(shell.get('status').textContent, 'Loading 100%', 'late progress must not change stopped loading UI');

  instance.options.onExit();
  assert.equal(shell.get('cover').hidden, false);
  assert.equal(shell.get('canvas').hidden, true);
  assert.equal(shell.get('fullscreen').hidden, true);
  assert.equal(shell.document.body.classList.contains('playing'), false);
  assert.equal(shell.focused, 'reload');
});

test('a persistent-storage startup failure never launches Godot or pretends to load a company', async () => {
  const shell = harness({ workerStart: async () => { throw new Error('Save already open in another tab.'); } });
  await shell.get('start').emit('click');
  assert.equal(shell.instances.length, 0);
  assert.equal(shell.get('reload').hidden, false);
  assert.equal(shell.get('canvas').hidden, true);
  assert.match(shell.get('status').textContent, /already open in another tab/);
});

test('a rejected startup exposes recovery and does not leave a focusable canvas', async () => {
  const shell = harness({ startGame: async () => { throw new Error('download failed'); } });
  await shell.get('start').emit('click');
  assert.equal(shell.get('cover').hidden, false);
  assert.equal(shell.get('progress').hidden, true);
  assert.equal(shell.get('canvas').tabIndex, -1);
  assert.equal(shell.focused, 'reload');
  assert.match(shell.get('status').textContent, /could not start/);
  assert.equal(shell.errors.length, 1);
});

test('an exit during initialization cannot be overwritten by the resolved startup promise', async () => {
  const shell = harness({ startGame: async options => { options.onExit(); } });
  await shell.get('start').emit('click');
  assert.equal(shell.get('cover').hidden, false);
  assert.equal(shell.get('canvas').hidden, true);
  assert.equal(shell.get('reload').hidden, false);
  assert.equal(shell.focused, 'reload');
  assert.match(shell.get('status').textContent, /game has closed/);
  shell.instances[0].options.onProgress(10, 100);
  assert.match(shell.get('status').textContent, /game has closed/);
});

test('fullscreen rejection preserves play and returns keyboard focus to the game', async () => {
  const shell = harness();
  await shell.get('start').emit('click');
  shell.document.documentElement.requestFullscreen = async () => { throw new Error('denied'); };
  await shell.get('fullscreen').emit('click');
  assert.equal(shell.get('game-notice').hidden, false);
  assert.equal(shell.get('cover').hidden, true);
  assert.equal(shell.focused, 'canvas');
  shell.document.documentElement.requestFullscreen = async () => { shell.document.fullscreenElement = {}; };
  await shell.get('fullscreen').emit('click');
  await shell.document.emit('fullscreenchange');
  assert.equal(shell.get('game-notice').hidden, true);
  assert.equal(shell.get('fullscreen').textContent, 'Exit full screen');
});
