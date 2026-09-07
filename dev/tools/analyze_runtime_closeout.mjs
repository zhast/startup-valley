// Read-only source/image comparison, writes only this checkpoint's analysis.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const repo = path.resolve(import.meta.dirname, '../..');
const folder = 'game/tests/output/regression-checkpoint-runtime-closeout';
const current = path.join(repo, folder);
const prior = path.join(repo, 'game/tests/output/regression-checkpoint-after-archive');
const raw = JSON.parse(fs.readFileSync(path.join(current, 'results.json')));
const comparisons = [];
for (const section of ['visual-review', 'polish-audit/world', 'polish-audit/ui']) {
  for (const name of fs.readdirSync(path.join(current, section)).filter(name => name.endsWith('.png') && !name.endsWith('contact-sheet.png'))) {
    const result = spawnSync('/opt/homebrew/bin/magick', ['compare', '-metric', 'AE', path.join(prior, section, name), path.join(current, section, name), 'null:'], {encoding: 'utf8'});
    if (![0, 1].includes(result.status)) throw new Error(result.stderr);
    comparisons.push({file: section + '/' + name, differentPixels: Number.parseInt(result.stderr, 10)});
  }
}
const counts = raw.runs.map(run => {
  const text = fs.readFileSync(path.join(repo, run.log), 'utf8');
  const match = text.match(/(?:\b|: )(\d+) checks/);
  const jsonMatch = text.match(/"checks":\s*(\d+)/);
  return {name: run.label, exitCode: run.code, checks: match ? Number(match[1]) : jsonMatch ? Number(jsonMatch[1]) : null};
});
const excluded = raw.changedExistingSources.filter(name => name === 'game/tools/capture_desk_finish_v2.gd').map(name => ({name, before: raw.sourceBefore[name], after: raw.sourceAfter[name], reason: 'Independent staged desk-finish capture tool; not production, any executed suite, nor a referenced checkpoint dependency. Root explicitly approved this narrow exclusion after retaining the raw source-guard warning.'}));
const analysis = {
  rawResultsRetained: true,
  godotAndValidatorProcessesPassed: raw.runs.every(run => run.code === 0),
  sourceGuardRawExitWasNonzero: raw.failures.includes('source snapshot changed'),
  excludedUnrelatedSourceChanges: excluded,
  unexpectedSourceChanges: raw.changedExistingSources.filter(name => !excluded.some(item => item.name === name)),
  comparisons,
  counts,
  countedChecks: counts.reduce((sum, item) => sum + (item.checks ?? 0), 0),
  limitations: [
    'Raw aggregate runner exited 1 solely for the separately documented unrelated dev-source change; its original results were not rewritten as exit 0.',
    'Passive native replay was concurrent and not a checkpoint test: its935/1 manifest was accidentally restored to an older version by an overly broad report backup, then recovered exactly. It is preserved separately as concurrent-passive-replay/manifest.json. Future runner backup now targets only headless report/export paths.',
    'This snapshot precedes the company agent\'s later test-only actual-line toolbar-bound correction and final standalone native passive replay.',
    'New runtime inventory is limited to assets/runtime; staged source/material work after catalogue113 is excluded.',
  ],
};
fs.writeFileSync(path.join(current, 'analysis.json'), JSON.stringify(analysis, null, 2) + '\n');
console.log(JSON.stringify({counts, countedChecks: analysis.countedChecks, images: comparisons.length, identical: comparisons.filter(item => item.differentPixels === 0).length, changed: comparisons.filter(item => item.differentPixels > 0), unexpectedSourceChanges: analysis.unexpectedSourceChanges}, null, 2));
