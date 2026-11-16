# Post-review reliability fixes

Scope: follow-up to main `d2513947e7e316154b00448738cc3ca360ec5724`.
No art, map, hosting, provider, or credential changes.

## Changes and evidence

- `web/src/sqlite-adapter.ts`: marker create/writable/write/close failures
  previously left a recovery marker while allowing gameplay to continue. On
  reopening, the older backup replaced that progress. All marker setup is now
  guarded, cleanup is required before continuing, and failed cleanup or restore
  invalidates the database wrapper, including prepared statements. The stored
  save and backup remain available for recovery on reopening.
- `web/test/sqlite-adapter.test.mjs`: ten failure-injection tests of the actual
  transpiled adapter cover the four setup stages, cleanup failure at those
  stages and after replacement, writer abort failure, reopen and preservation
  of later progress. These are adapter unit tests with a mocked OPFS pool, not
  claims of hardware/storage-quota testing.
- `harness/src/story.ts`, `tycoon.ts`, `database-core.ts`: the product callback
  now runs on pivot as well as start. Pivoting into the requested pair links the
  brief; pivoting away relinquishes it and advances revision. A completed brief
  remains linked to its original product.
- `harness/test/courtyard-story.test.ts`: added regression checks pivot-away,
  stale revision rejection, pivot-in, transaction rollback/retry, release,
  persistence on reopen and completed-link preservation.

Historical orphaned released products are not retroactively linked. There is
no reliable stored evidence that the player intended them for the brief.

## Validation

Validation results are recorded in the final checkpoint below. Earlier demo
acceptance and screenshots are historical and do not certify this patch.

- Harness TypeScript build: passed.
- Harness suite using `node --import tsx --test --test-concurrency=1 test/*.test.ts`:
  169 passed, 2 skipped, 0 failed. The equivalent serial command avoids tsx's
  sandbox-blocked IPC launcher. Initial concurrent execution exhausted resources
  (a build was killed and a bootstrap test timed out); serial rerun passed.
- Offline evaluator: 8/8 fixtures passed; no paid provider calls.
- Browser TypeScript/Vite worker and bridge build: passed.
- Reset adapter regression tests: 10/10 passed.
- Root Node suite: 75/75 passed.
- Asset and map release validators: passed without errors or warnings.
- `git diff --check`: passed.
- Official Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`), downloaded editor
  SHA256 verified against official release: serial headless import,
  `validate_project.gd`, and `tests/run_all.gd` passed. Matching official web
  templates were verified. Initial concurrent import was killed under resource
  contention; the serial pinned-version checks passed.
- Full playable web release export with official 4.7.2 and matching templates:
  passed, including asset/map/export validation. Initial export exhausted the
  temporary filesystem; moving the redundant isolated review clone to a larger
  workspace freed space, and a clean retry succeeded without source changes.
- Exported browser gameplay: not verified in this environment. Chromium launch
  was blocked by its process-singleton socket permission before any page or
  game interaction, including the alternate approved execution attempt. This
  is a test-environment limitation, not a claimed game failure or gameplay pass.

The resulting `dist/` is a local ignored build, not a public deployment. No
hosting, release upload, or user installation was performed. The prior demo
journey evidence remains historical; perform a fresh exported browser journey
on an environment that permits browser startup before claiming end-to-end
acceptance of this checkpoint.
