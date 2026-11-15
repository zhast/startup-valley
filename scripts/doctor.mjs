import { access, readFile, readdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { loadConfig, isMain, sections, selectPreset, unquote, parseVersion } from './lib/config.mjs';

export function inspectProject(projectText, presetText, config) {
  const errors = [];
  const warnings = [];
  const project = sections(projectText);
  const application = project.get('application') ?? {};
  const renderer = project.get('rendering') ?? {};
  const features = application['config/features'] ?? '';
  const projectVersion = features.match(/"(4\.\d+)"/)?.[1];
  if (!unquote(application['run/main_scene'])) errors.push('Choose the playable main scene in Godot.');
  const renderingMethod = unquote(renderer['renderer/rendering_method.web'] ?? renderer['renderer/rendering_method']);
  if (renderingMethod !== 'gl_compatibility') errors.push('Set the web rendering method to gl_compatibility (Compatibility) in Godot.');
  if (features.includes('C#')) errors.push('This project declares C#. Godot 4 C# cannot currently use the standard web export.');
  const preset = selectPreset(presetText, config.preset);
  if (!preset) errors.push(`Create an export preset named "${config.preset}" in Godot.`);
  else {
    if (unquote(preset.platform) !== 'Web') errors.push(`"${config.preset}" must use the Web platform.`);
    for (const key of ['variant/thread_support', 'variant/extensions_support']) {
      if (preset.options[key] !== 'false') errors.push(`Set ${key}=false explicitly for this single-threaded scaffold.`);
    }
    if (preset.options['progressive_web_app/enabled'] !== 'false') errors.push('Set progressive_web_app/enabled=false initially; offline caching needs a separate update strategy.');
    if (preset.options['html/export_icon'] === 'true') warnings.push('Check exported icons on both light and dark browser tabs.');
    if (unquote(preset.options['html/custom_html_shell']) !== 'res://web/shell.html') warnings.push('To use the supplied loading screen, set Custom HTML Shell to res://web/shell.html.');
  }
  if (!config.godotVersion) warnings.push('Set godotVersion to your current editor patch version before establishing CI. No upgrade is required by this scaffold.');
  if (!projectVersion && !config.godotVersion) errors.push('Could not infer the editor version. Set godotVersion in godot-web.config.json before importing/exporting.');
  return { errors, warnings, projectVersion, preset };
}

export function inspectEngine(output, projectVersion, pinnedVersion) {
  const version = parseVersion(output.trim());
  const errors = [];
  if (!version || version.major !== 4 || version.minor < 3) errors.push('This scaffold requires Godot 4.3+ for single-threaded web export. Keep older projects unchanged until a deliberate upgrade is tested.');
  if (version && projectVersion && `${version.major}.${version.minor}` !== projectVersion) errors.push(`Project uses Godot ${projectVersion}; the executable is ${version.exact}. Use the matching editor to avoid an unintended migration.`);
  if (version && pinnedVersion && version.exact !== pinnedVersion) errors.push(`Pinned Godot ${pinnedVersion}; found ${version.exact}.`);
  if (/dev|alpha|beta|rc|mono/i.test(output)) errors.push('Use the matching stable standard (non-.NET) Godot editor for this export.');
  return { version, errors };
}

function findGodot() {
  const candidates = process.env.GODOT_BIN ? [process.env.GODOT_BIN] : ['godot', 'godot4', '/Applications/Godot.app/Contents/MacOS/Godot'];
  for (const bin of candidates) {
    const result = spawnSync(bin, ['--version'], { encoding: 'utf8', timeout: 15000, windowsHide: true });
    if (!result.error && result.status === 0) return { bin, output: result.stdout.trim() };
  }
  return null;
}

async function findExtensions(root, result = []) {
  for (const entry of await readdir(root, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;
    const path = resolve(root, entry.name);
    if (entry.isDirectory()) await findExtensions(path, result);
    else if (entry.isFile() && /\.(cs|gdextension)$/.test(entry.name)) result.push(path);
  }
  return result;
}

export async function diagnose(config) {
  config ??= await loadConfig();
  const errors = [], warnings = [];
  let inspection;
  try {
    await access(resolve(config.projectPath, 'project.godot'));
    let presetText = '';
    try { presetText = await readFile(resolve(config.projectPath, 'export_presets.cfg'), 'utf8'); } catch { /* reported by inspectProject */ }
    inspection = inspectProject(await readFile(resolve(config.projectPath, 'project.godot'), 'utf8'), presetText, config);
    errors.push(...inspection.errors); warnings.push(...inspection.warnings);
    const extensions = await findExtensions(config.projectPath);
    if (extensions.length) warnings.push(`Review ${extensions.length} C# or GDExtension file(s) for runtime use before exporting; editor-only addons may be harmless.`);
  } catch (error) {
    errors.push(error.code === 'ENOENT' ? `No project.godot in ${config.projectPath}. Bring the existing project here with its relative paths intact.` : error.message);
  }
  const engine = findGodot();
  if (!engine) errors.push('Godot was not found. Install the same stable editor and matching export templates, then set GODOT_BIN if needed.');
  else errors.push(...inspectEngine(engine.output, inspection?.projectVersion, config.godotVersion).errors);
  return { config, engine, errors, warnings };
}

export function printDiagnosis(result) {
  console.log(`Godot web project: ${result.config.projectPath}`);
  if (result.engine) console.log(`Editor: ${result.engine.output}`);
  for (const warning of result.warnings) console.log(`NOTE  ${warning}`);
  for (const error of result.errors) console.error(`NEEDS  ${error}`);
  if (!result.errors.length) console.log('Project configuration is ready for an export attempt. Godot will verify the export templates and resources.');
}

if (isMain(import.meta.url)) {
  try { const result = await diagnose(); printDiagnosis(result); process.exitCode = result.errors.length ? 1 : 0; }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
