// Dev-only final-art regression. Unique evidence directory, no provider or save.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn} from 'node:child_process';

const repo = path.resolve(import.meta.dirname, '../..');
const [name, phase = 'headless'] = process.argv.slice(2);
if (!/^art-completion-[a-z0-9-]+$/.test(name ?? '') || !['headless', 'render'].includes(phase)) {
  throw new Error('Usage: node dev/tools/run_art_completion_regression.mjs art-completion-<unique-name> headless|render');
}
const output = path.join(repo, 'game/tests/output', name);
const manifest = path.join(output, `${phase}-results.json`);
if (fs.existsSync(manifest)) throw new Error('Retain prior results; choose a new checkpoint name.');
const resource = `res://tests/output/${name}`;
const godot = '/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot';
const env = {...process.env, STARTUP_VALLEY_NO_WORKER: '1', STARTUP_VALLEY_AUDIT_OUTPUT_ROOT: resource};
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function productionHashes(folder = path.join(repo, 'game'), result = {}) {
  for (const item of fs.readdirSync(folder, {withFileTypes: true})) {
    if (['.godot', 'tests', 'tools', 'source'].includes(item.name)) continue;
    const file = path.join(folder, item.name);
    if (item.isDirectory()) productionHashes(file, result);
    else if (/\.(gd|tscn|json|godot|png|ttf|otf)$/.test(file)) result[path.relative(repo, file)] = hash(file);
  }
  return result;
}
fs.mkdirSync(path.join(output, 'logs'), {recursive: true});
const result = {started: new Date().toISOString(), phase, workerDisabled: true,
  scope: 'Current production and listed regression dependencies; not every historical candidate script.',
  productionBefore: productionHashes(), runs: [], failures: []};
const write = () => fs.writeFileSync(manifest, JSON.stringify(result, null, 2) + '\n');
async function run(label, args, binary = godot) {
  const started = Date.now();
  const log = path.join(output, 'logs', `${phase}-${label}.log`);
  const stream = fs.createWriteStream(log, {flags: 'wx'});
  const child = spawn(binary, args, {cwd: repo, env});
  let text = '';
  for (const pipe of [child.stdout, child.stderr]) pipe.on('data', bytes => {stream.write(bytes); text += bytes;});
  const code = await new Promise((resolve, reject) => {child.on('error', reject); child.on('close', resolve);});
  await new Promise(resolve => stream.end(resolve));
  const errors = text.split('\n').filter(line => /(?:SCRIPT ERROR:|^ERROR:)/.test(line));
  const summary = text.split('\n').filter(line => /passed|checks|failures|complete|validation|frames|captured:/.test(line) && line.length < 350).slice(-8);
  result.runs.push({label, code, seconds: (Date.now() - started) / 1000,
    command: [binary, ...args], log: path.relative(repo, log), errors, summary});
  if (code !== 0 || errors.length) result.failures.push(label);
  write();
  console.log(`${label}: exit ${code}; ${summary.join(' | ')}`);
  if (code !== 0 || errors.length) throw new Error('Stopped at failed or error-emitting invocation: ' + label);
}
const suites = [
  'run_all', 'test_complete_game', 'test_graphics_regressions',
  'test_office_layout', 'test_office_migration', 'test_modular_office',
  'test_office_layout_editor', 'test_office_architecture', 'test_furniture_directions',
  'test_reviewed_workstation_production', 'test_archive_production',
  'test_approval_console_production', 'test_prototype_bench_production',
  'test_coffee_station_production', 'test_research_bench_production',
  'test_collaboration_production', 'test_lunch_standing',
  'test_ui_flow_regressions', 'test_ui_drawer_redesign', 'test_ui_company_redesign',
  'test_connection_retry_guard',
  'test_reader_hud_redesign', 'test_world_ui_presentation',
  'test_window_presentation', 'test_click_feedback_presentation',
  'test_locomotion_export', 'test_grounded_shadow_x_follow', 'test_grounded_work_shadow',
  'test_directional_input', 'test_visible_surface_picking', 'test_audit_output_scope',
];
try {
  if (phase === 'headless') {
    await run('import', ['--headless', '--path', 'game', '--import']);
    await run('validate_project', ['--headless', '--path', 'game', '--script', 'res://tools/validate_project.gd']);
    for (const suite of suites) await run(suite, ['--headless', '--path', 'game', '--fixed-fps', '60', '--script', `res://tests/${suite}.gd`]);
  } else {
    await run('static', ['--path', 'game', '--fixed-fps', '60', '--script', 'res://tools/capture_visual_review.gd']);
    fs.mkdirSync(path.join(output, 'polish-audit'), {recursive: true});
    for (const suite of ['world', 'ui']) {
      await run('motion-' + suite, ['--path', 'game', '--fixed-fps', '30', '--write-movie', `${resource}/polish-audit/${suite}.avi`, '--script', 'res://tools/capture_polish_audit.gd', '--', '--suite=' + suite]);
      await run('ffprobe-' + suite, ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height,nb_frames,r_frame_rate,duration', '-of', 'json', path.join(output, 'polish-audit', suite + '.avi')], '/opt/homebrew/bin/ffprobe');
    }
    await run('validate_polish', ['--headless', '--path', 'game', '--script', 'res://tools/validate_polish_audit.gd']);
    await run('windows', ['--path', 'game', '--script', 'res://tools/capture_runtime_window_review.gd']);
  }
} catch (error) {
  result.error = String(error);
  process.exitCode = 1;
} finally {
  result.finished = new Date().toISOString();
  result.productionAfter = productionHashes();
  result.productionChanged = [...new Set([...Object.keys(result.productionBefore), ...Object.keys(result.productionAfter)])]
    .filter(file => result.productionBefore[file] !== result.productionAfter[file]);
  if (result.productionChanged.length) {result.failures.push('production changed'); process.exitCode = 1;}
  write();
}
