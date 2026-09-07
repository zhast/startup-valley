// Provider-free, sequential regression checkpoint. No production/source edits.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn} from 'node:child_process';
const repo = path.resolve(import.meta.dirname, '../..');
const godot = '/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot';
const name = 'regression-checkpoint-runtime-closeout';
const outputBase = path.join(repo, 'game/tests/output');
const output = path.join(outputBase, name);
const resource = `res://tests/output/${name}`;
const env = {...process.env, STARTUP_VALLEY_NO_WORKER: '1', STARTUP_VALLEY_AUDIT_OUTPUT_ROOT: resource};
fs.mkdirSync(path.join(output, 'logs'), {recursive: true});
const sha = data => crypto.createHash('sha256').update(data).digest('hex');
function walk(dir, out = []) {
  for (const item of fs.readdirSync(dir, {withFileTypes: true})) {
    const full = path.join(dir, item.name);
    if (full === output || item.name === '.godot') continue;
    if (item.isDirectory()) walk(full, out);
    else if (item.isFile()) out.push(full);
  }
  return out;
}
function sourceHashes() {
  const files = walk(path.join(repo, 'game')).filter(file => !file.startsWith(outputBase + '/') && /\.(gd|tscn|json|godot)$/.test(file));
  return Object.fromEntries(files.sort().map(file => [path.relative(repo, file), sha(fs.readFileSync(file))]));
}
const result = {started: new Date().toISOString(), providerFree: true, sourceBefore: sourceHashes(), runs: [], failures: []};
function writeResult() {fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify(result, null, 2) + '\n');}
async function run(label, args, binary = godot) {
  const started = Date.now();
  const log = path.join(output, 'logs', label + '.log');
  const stream = fs.createWriteStream(log);
  let captured = '';
  const child = spawn(binary, args, {cwd: repo, env});
  for (const pipe of [child.stdout, child.stderr]) pipe.on('data', data => {stream.write(data); captured += data;});
  const code = await new Promise((resolve, reject) => {child.on('error', reject); child.on('close', resolve);});
  await new Promise(resolve => stream.end(resolve));
  const summary = captured.split('\n').filter(line => /checks|passed|failures|captured:|complete|validation|frames/.test(line) && line.length < 300).slice(-8);
  const entry = {label, code, seconds: (Date.now() - started) / 1000, command: [binary, ...args], log: path.relative(repo, log), summary};
  result.runs.push(entry);
  if (code !== 0 || /SCRIPT ERROR:/.test(captured)) result.failures.push(label);
  writeResult();
  console.log(label + ': exit ' + code + ' ' + summary.join(' | '));
  if (code !== 0 || /SCRIPT ERROR:/.test(captured)) throw new Error('Checkpoint stopped: ' + label);
}
// Existing focused tests have fixed JSON output names. Preserve their exact old
// reports, copy newly written reports here, then restore the originals.
function isHeadlessReport(file) {
  const relative = path.relative(outputBase, file);
  return /(?:^|\/)(?:headless|.*-headless)\.json$/.test(relative) || /^(?:office-layout|office-migration)\/.*\.json$/.test(relative);
}
const savedReports = new Map(walk(outputBase).filter(isHeadlessReport).map(file => [file, fs.readFileSync(file)]));
function preserveHeadlessReports() {
  let copied = 0;
  for (const file of walk(outputBase).filter(isHeadlessReport)) {
    const data = fs.readFileSync(file);
    const old = savedReports.get(file);
    if (old && old.equals(data)) continue;
    const destination = path.join(output, 'headless', path.relative(outputBase, file));
    fs.mkdirSync(path.dirname(destination), {recursive: true});
    fs.writeFileSync(destination, data);
    copied++;
    if (old) fs.writeFileSync(file, old);
    // New diagnostic exports have no previous report to restore; retain them.
  }
  result.headlessReportsCopied = copied;
  result.previousReportBytesRestored = [...savedReports].every(([file, data]) => fs.existsSync(file) && fs.readFileSync(file).equals(data));
}
const suites = [
	'test_audit_output_scope',
  'run_all', 'test_complete_game', 'test_ui_flow_regressions', 'test_graphics_regressions',
  'test_office_layout', 'test_office_migration', 'test_office_architecture', 'test_office_layout_editor',
  'test_furniture_directions', 'test_workstation_facing', 'test_world_ui_presentation', 'test_window_presentation',
  'test_polish_inventory_layers', 'test_grounded_shadow_x_follow', 'test_station_hover', 'test_lunch_standing',
  'test_founder_occlusion', 'test_passive_furniture', 'test_service_furniture', 'test_archive_production',
  'test_modular_office',
];
try {
  await run('import', ['--headless', '--path', 'game', '--import']);
  await run('validate_project', ['--headless', '--path', 'game', '--script', 'res://tools/validate_project.gd']);
  try {
    for (const suite of suites) {
      const fps = ['test_archive_production', 'test_passive_furniture', 'test_service_furniture'].includes(suite) ? '30' : '60';
      await run(suite, ['--headless', '--path', 'game', '--fixed-fps', fps, '--script', `res://tests/${suite}.gd`]);
    }
  } finally {preserveHeadlessReports();}
  await run('static', ['--path', 'game', '--fixed-fps', '60', '--script', 'res://tools/capture_visual_review.gd']);
  fs.mkdirSync(path.join(output, 'polish-audit'), {recursive: true});
  for (const suite of ['world', 'ui']) {
    await run('motion-' + suite, ['--path', 'game', '--fixed-fps', '30', '--write-movie', `${resource}/polish-audit/${suite}.avi`, '--script', 'res://tools/capture_polish_audit.gd', '--', '--suite=' + suite]);
    await run('ffprobe-' + suite, ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height,nb_frames,r_frame_rate,duration', '-of', 'json', path.join(output, 'polish-audit', suite + '.avi')], '/opt/homebrew/bin/ffprobe');
  }
  await run('validate_polish', ['--headless', '--path', 'game', '--script', 'res://tools/validate_polish_audit.gd']);
} catch (error) {
  result.error = String(error);
  process.exitCode = 1;
} finally {
  result.finished = new Date().toISOString();
  result.sourceAfter = sourceHashes();
  result.changedExistingSources = Object.keys(result.sourceBefore).filter(file => result.sourceBefore[file] !== result.sourceAfter[file]);
  if (result.changedExistingSources.length) {result.failures.push('source snapshot changed'); process.exitCode = 1;}
  writeResult();
}
