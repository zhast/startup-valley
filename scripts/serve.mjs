import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { access, readFile, realpath, stat } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
import { pipeline } from 'node:stream/promises';
import { loadConfig, isMain, isWithin } from './lib/config.mjs';

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.ico': 'image/x-icon', '.webp': 'image/webp',
};

export function renderPreview(template) {
  return template.replaceAll('$GODOT_PROJECT_NAME', 'Startup Valley')
    .replaceAll('$GODOT_HEAD_INCLUDE', '')
    .replaceAll('$GODOT_URL', '__preview__/engine.js')
    .replaceAll('$GODOT_CONFIG', JSON.stringify({ __preview: true }));
}

async function readPreviewShell(config) {
  if (config.projectPath) {
    try { return await readFile(resolve(config.projectPath, 'web/shell.html'), 'utf8'); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  return readFile(resolve(config.root, 'game/web/shell.html'), 'utf8');
}

export function createPreviewServer(config) {
  return createServer(async (request, response) => {
    const send = (status, body, type = 'text/plain; charset=utf-8') => {
      response.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
      response.end(request.method === 'HEAD' ? undefined : body);
    };
    try {
      if (!['GET', 'HEAD'].includes(request.method)) { response.setHeader('Allow', 'GET, HEAD'); return send(405, 'Method not allowed'); }
      let path;
      try { path = decodeURIComponent(new URL(request.url, 'http://localhost').pathname); }
      catch { return send(400, 'Invalid URL'); }
      if (path.includes('\0') || path.includes('\\') || path.split('/').some(part => part.startsWith('.'))) return send(404, 'Not found');
      let hasExport = true;
      try { await access(resolve(config.dist, 'index.html')); } catch { hasExport = false; }
      if (!hasExport) {
        if (path === '/' || path === '/index.html') {
          const template = await readPreviewShell(config);
          return send(200, renderPreview(template), MIME['.html']);
        }
        if (path === '/__preview__/engine.js') return send(200, '/* Shell preview only: no engine or game has been imported. */', MIME['.js']);
        return send(404, 'No web export yet. Run the doctor and export commands.');
      }
      const target = resolve(config.dist, '.' + (path.endsWith('/') ? `${path}index.html` : path));
      if (!isWithin(config.dist, target)) return send(404, 'Not found');
      let canonical;
      try { canonical = await realpath(target); } catch { return send(404, 'Not found'); }
      if (!isWithin(await realpath(config.dist), canonical)) return send(404, 'Not found');
      const info = await stat(canonical);
      if (!info.isFile()) return send(404, 'Not found');
      response.writeHead(200, { 'Content-Type': MIME[extname(canonical)] ?? 'application/octet-stream', 'Content-Length': info.size, 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
      if (request.method === 'HEAD') return response.end();
      await pipeline(createReadStream(canonical), response);
    } catch (error) {
      if (!response.headersSent) send(500, 'Preview server error; see the terminal.');
      else response.destroy();
      console.error(error.message);
    }
  });
}

if (isMain(import.meta.url)) {
  try {
    const config = await loadConfig();
    const server = createPreviewServer(config);
    server.on('error', error => { console.error(error.message); process.exitCode = 1; });
    server.listen(config.port, '127.0.0.1', () => console.log(`Local: http://127.0.0.1:${config.port}\nServes dist when an export exists; otherwise shows the clearly marked shell preview.\nCtrl+C to stop.`));
    for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => { server.close(); server.closeAllConnections(); });
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
