import { readFile, realpath } from 'node:fs/promises';
import { dirname, resolve, relative, isAbsolute, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

export async function loadConfig(root = ROOT) {
  const value = JSON.parse(await readFile(resolve(root, 'godot-web.config.json'), 'utf8'));
  if (typeof value.projectDir !== 'string' || !value.projectDir.trim()) throw new Error('projectDir must be a nonempty path.');
  if (typeof value.preset !== 'string' || !value.preset.trim()) throw new Error('preset must be a nonempty name.');
  if (!Number.isInteger(value.port) || value.port < 1 || value.port > 65535) throw new Error('port must be 1–65535.');
  if (value.godotVersion !== null && (typeof value.godotVersion !== 'string' || !/^4\.\d+\.\d+$/.test(value.godotVersion))) {
    throw new Error('godotVersion must be null or an exact stable version such as 4.4.1.');
  }
  const projectPath = resolve(root, value.projectDir);
  if (projectPath === root || !isWithin(root, projectPath)) throw new Error('Keep the Godot project in a subdirectory of this scaffold.');
  const dist = resolve(root, 'dist');
  const buildRoot = resolve(root, '.build');
  if (isWithin(dist, projectPath) || isWithin(buildRoot, projectPath)) {
    throw new Error('Keep projectDir outside dist/ and .build/; those directories contain replaceable generated output.');
  }
  try {
    const [canonicalRoot, canonicalProject] = await Promise.all([realpath(root), realpath(projectPath)]);
    if (canonicalProject === canonicalRoot || !isWithin(canonicalRoot, canonicalProject)) {
      throw new Error('projectDir resolves outside its workspace subdirectory. Godot imports write project caches, so choose a project inside this workspace.');
    }
    if (isWithin(resolve(canonicalRoot, 'dist'), canonicalProject) || isWithin(resolve(canonicalRoot, '.build'), canonicalProject)) {
      throw new Error('projectDir resolves into replaceable generated output. Keep source outside dist/ and .build/.');
    }
  } catch (error) {
    // Missing projects are handled by the doctor and are expected before porting.
    if (error.code !== 'ENOENT') throw error;
  }
  return { ...value, root, projectPath, dist };
}

export function isWithin(root, path) {
  const rel = relative(root, path);
  return !rel.startsWith('..' + sep) && rel !== '..' && !isAbsolute(rel);
}

// Only reads sections and scalar settings used by this scaffold. It is not a
// replacement for Godot's ConfigFile parser and never rewrites project files.
export function sections(text) {
  const result = new Map();
  let section;
  for (const line of text.split(/\r?\n/)) {
    const header = line.match(/^\s*\[([^\]]+)\]\s*$/);
    if (header) { section = {}; result.set(header[1], section); continue; }
    const entry = line.match(/^\s*([^;#=]+?)\s*=\s*(.*?)\s*$/);
    if (entry && section) section[entry[1]] = entry[2];
  }
  return result;
}

export function unquote(value = '') {
  try { return JSON.parse(value); } catch { return value; }
}

export function selectPreset(text, name) {
  const data = sections(text);
  for (const [key, value] of data) {
    if (/^preset\.\d+$/.test(key) && unquote(value.name) === name) {
      return { ...value, options: data.get(`${key}.options`) ?? {} };
    }
  }
  return null;
}

export function parseVersion(value) {
  const match = value.match(/^(\d+)\.(\d+)(?:\.(\d+))?/);
  return match ? { major: +match[1], minor: +match[2], patch: +(match[3] ?? 0), exact: `${match[1]}.${match[2]}.${match[3] ?? '0'}` } : null;
}

export function isMain(url) {
  return Boolean(process.argv[1]) && fileURLToPath(url) === resolve(process.argv[1]);
}
