// Provider-free verification of an already-recorded furnishing lifecycle movie.
// PNG keyframes remain lossless; the AVI is decoded to verify its real frame count.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const directory = path.resolve(root, process.argv[2] ?? '');
const ffprobe = process.argv[3] ?? 'ffprobe';
if (!directory.startsWith(path.join(root, 'game/tests/output/'))) throw new Error('Pass one existing game/tests/output checkpoint directory');
const output = path.join(directory, 'verification.json');
if (fs.existsSync(output)) throw new Error('Preserve prior verification; choose a new capture checkpoint');
const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'manifest.json'), 'utf8'));
const failures = [];
let checks = 0;
const check = (value, label) => { checks++; if (!value) failures.push(label); };
const fromResource = source => {
  if (!source.startsWith('res://') || source.includes('..')) throw new Error(`Invalid evidence resource: ${source}`);
  return path.join(root, 'game', source.slice(6));
};
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const size = file => {
  const bytes = fs.readFileSync(file);
  if (bytes.subarray(1, 4).toString() !== 'PNG') throw new Error(`Not PNG: ${file}`);
  return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
};
check(manifest.worker_disabled && manifest.failures.length === 0, 'Native fixture was provider-free and passed');
// Godot removes some engine flags before OS.get_cmdline_args(); older captures
// therefore leave movie_path empty. Bind the conventional same-folder AVI here
// by decoded frame range and its full content hash, without rewriting evidence.
const movie = manifest.movie_path ? fromResource(manifest.movie_path) : path.join(directory, 'world.avi');
check(path.dirname(movie) === directory, 'Movie belongs to the same evidence checkpoint');
const probe = spawnSync(ffprobe, ['-v', 'error', '-select_streams', 'v:0', '-count_frames', '-show_entries', 'stream=width,height,r_frame_rate,nb_frames,nb_read_frames,duration', '-show_entries', 'format=duration,size', '-of', 'json', movie], {encoding: 'utf8'});
if (probe.status !== 0) throw new Error(probe.stderr || 'ffprobe failed');
const decoded = JSON.parse(probe.stdout);
const stream = decoded.streams[0];
const frames = Number(stream.nb_read_frames);
check(stream.width === 1280 && stream.height === 720 && stream.r_frame_rate === '30/1', 'Movie has native composition and fixed 30 FPS');
check(frames === Number(stream.nb_frames) && frames > 0, 'AVI header agrees with actual decoded frames');
check(frames === manifest.engine_process_frames + 1, 'Final engine marker is the last zero-based movie frame');
check(JSON.stringify(manifest.source_hashes_before) === JSON.stringify(manifest.source_hashes_after), 'Capture source hashes remained unchanged');
for (const [source, expected] of Object.entries(manifest.source_hashes_after)) check(hash(fromResource(source)) === expected, `Current source matches captured ${source}`);
check(manifest.captures.length === 73 && manifest.scenarios.length === 8, 'All expected native stills and eight lifecycles exist');
let previous = -1;
for (const capture of manifest.captures) {
  const file = fromResource(capture.path);
  check(path.dirname(file) === directory && hash(file) === capture.sha256, `${capture.label}: native PNG provenance`);
  check(JSON.stringify(size(file)) === '[1280,720]', `${capture.label}: native PNG dimensions`);
  check(capture.engine_process_frame > previous && capture.engine_process_frame < frames, `${capture.label}: ordered marker within decoded movie`);
  previous = capture.engine_process_frame;
}
for (const side of ['north', 'east', 'south', 'west']) for (const owner of ['mira', 'theo']) {
  const name = `${side}-${owner}`;
  const scenario = manifest.scenarios.find(item => item.name === name);
  check(Boolean(scenario), `${name}: lifecycle exists`);
  if (!scenario) continue;
  check(scenario.actual_end_state === 'SITTING' && scenario.expected_end_state === 'SITTING', `${name}: returned to sitting`);
  check(JSON.stringify(scenario.actual_position) === JSON.stringify(scenario.expected_position), `${name}: exact expected destination`);
  const samples = manifest.captures.filter(item => item.label.startsWith(`${name}-`));
  check(samples.length === 9 && new Set(samples.map(item => item.sha256)).size >= 3, `${name}: nine markers include distinct images`);
  for (const state of manifest.sequence) check(samples.some(item => item.label === `${name}-${state}`), `${name}: ${state} marker exists`);
  check(samples.every(item => item.engine_process_frame >= scenario.first_engine_frame && item.engine_process_frame <= scenario.last_engine_frame), `${name}: markers belong to scenario range`);
}
check(JSON.stringify(size(fromResource(manifest.contact_sheet))) === '[1728,1792]', 'Native host contact sheet contains all 72 lifecycle samples');
const movieHash = crypto.createHash('sha256');
for await (const chunk of fs.createReadStream(movie)) movieHash.update(chunk);
const result = {ok: failures.length === 0, checks, failures, fixture_scope: 'Provider-free native art/behavior evidence; not worker durability or interactive performance certification', manifest_sha256: hash(path.join(directory, 'manifest.json')), movie_path: path.relative(root, movie), movie_sha256: movieHash.digest('hex'), source_count: Object.keys(manifest.source_hashes_before).length, decoded, scenarios: manifest.scenarios.map(item => item.name)};
fs.writeFileSync(output, `${JSON.stringify(result, null, 2)}\n`, {flag: 'wx'});
console.log(JSON.stringify(result, null, 2));
if (failures.length) process.exitCode = 1;
