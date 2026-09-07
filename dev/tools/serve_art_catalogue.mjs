// Development-only, read-only local review server. Never part of the worker.
import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { realpath, stat } from 'node:fs/promises';
import { dirname, extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = await realpath(resolve(dirname(fileURLToPath(import.meta.url)), '../..'));
const port = Number(process.argv[2] ?? 8765);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Use a local port between 1024 and 65535.');
const types = { '.html': 'text/html; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json', '.md': 'text/plain; charset=utf-8', '.gd': 'text/plain; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.webp': 'image/webp', '.avi': 'video/x-msvideo' };
const allowed = ['dev/', 'game/assets/', 'game/tests/', 'game/tools/', 'game/actors/', 'game/world/', 'game/ui/', 'game/data/'];
const server = createServer(async (request, response) => {
  try {
    if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405).end(); return; }
    let relative = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname).replace(/^\/+/, '');
    if (!relative) relative = 'dev/art-catalogue/index.html';
    if (relative.includes('\0') || relative.includes('\\') || relative.split('/').some(part => part.startsWith('.')) || !allowed.some(prefix => relative.startsWith(prefix))) { response.writeHead(403).end(); return; }
    const path = await realpath(resolve(projectRoot, relative));
    if (!path.startsWith(projectRoot + sep) || !types[extname(path)]) { response.writeHead(403).end(); return; }
    const info = await stat(path);
    if (!info.isFile()) { response.writeHead(404).end(); return; }
    response.writeHead(200, { 'Content-Type': types[extname(path)], 'Content-Length': info.size, 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    if (request.method === 'HEAD') response.end();
    else createReadStream(path).on('error', () => response.destroy()).pipe(response);
  } catch { if (!response.headersSent) response.writeHead(404); response.end(); }
});
server.listen(port, '127.0.0.1', () => console.log(`Art catalogue: http://127.0.0.1:${port}/dev/art-catalogue/index.html (read-only; stop with Ctrl-C)`));
