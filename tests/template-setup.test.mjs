import test from 'node:test';
import assert from 'node:assert/strict';
import { crc32 } from 'node:zlib';
import { parseEntries, verifyTemplateZip, zipDirectory } from '../scripts/setup-web-templates.mjs';

function zip(files) {
  const payload = [], central = [];
  let offset = 0;
  for (const [filename, data] of files) {
    const name = Buffer.from(filename), bytes = Buffer.from(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50); local.writeUInt32LE(crc32(bytes), 14);
    local.writeUInt32LE(bytes.length, 18); local.writeUInt32LE(bytes.length, 22); local.writeUInt16LE(name.length, 26);
    payload.push(local, name, bytes);
    const entry = Buffer.alloc(46);
    entry.writeUInt32LE(0x02014b50); entry.writeUInt32LE(crc32(bytes), 16);
    entry.writeUInt32LE(bytes.length, 20); entry.writeUInt32LE(bytes.length, 24); entry.writeUInt16LE(name.length, 28); entry.writeUInt32LE(offset, 42);
    central.push(entry, name);
    offset += local.length + name.length + bytes.length;
  }
  const directory = Buffer.concat(central), end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50); end.writeUInt16LE(files.length, 8); end.writeUInt16LE(files.length, 10);
  end.writeUInt32LE(directory.length, 12); end.writeUInt32LE(offset, 16);
  return Buffer.concat([...payload, directory, end]);
}

const minimum = [['godot.js', 'runtime'], ['godot.wasm', Buffer.from([0, 97, 115, 109, 1, 0, 0, 0])], ['godot.html', '<canvas></canvas>']];

test('verifies every inner template member before use', () => {
  assert.doesNotThrow(() => verifyTemplateZip(zip(minimum)));
  const corrupted = zip(minimum);
  corrupted[30 + 'godot.js'.length] ^= 1;
  assert.throws(() => verifyTemplateZip(corrupted), /integrity check/);
});

test('rejects templates without the required WebAssembly and shell files', () => {
  assert.throws(() => verifyTemplateZip(zip(minimum.slice(0, 2))), /godot.html/);
  assert.throws(() => verifyTemplateZip(zip([minimum[0], ['godot.wasm', '<html>'], minimum[2]])), /WebAssembly/);
});

test('rejects truncated and duplicate ZIP directories', () => {
  const duplicated = zip([...minimum, minimum[0]]);
  const directory = zipDirectory(duplicated);
  assert.throws(() => parseEntries(directory.data, directory.count), /uniqueness/);
  assert.throws(() => zipDirectory(duplicated.subarray(0, duplicated.length - 1)), /missing/);
});

test('locates a remote ZIP directory from its tail without fetching the archive body', () => {
  const archive = zip(minimum), start = archive.length - 22;
  const directory = zipDirectory(archive.subarray(start), archive.length, start);
  assert.equal(directory.count, 3);
  assert.equal(directory.data, null);
  assert.ok(directory.offset < start);
});
