# Development handoff — 2026-11-15

## Current scope and status

The owner activated [DEMO_GOAL_PLAN.md](DEMO_GOAL_PLAN.md). Status: **active**;
implementation is present, final frozen-source integrated acceptance and demo
packaging remain. Continue without routine approvals. The owner authorizes
parallel agents, fixes, art work, integrated Godot tests, local exports, and
frequent tested commits/pushes directly to `main`. Website/public hosting is
**deferred**. Do not use computer-use or browser UI automation for this goal.

Current local production checkpoint: `b0aff46` (following `deaf300`). Confirmed
remote checkpoint: `9ce236dbd469fd3e1b555659465199902fe203ec`, which includes the
opening/courtyard implementation, cursor/settings/arrival fixes and initial
test harness. Verify
Git state before resuming; connector-created remote commits can have different
IDs with identical full Git trees. Do not overwrite someone else's new work.

The QA agent owns ongoing test-only edits in `game/tests/test_demo_journey.gd`
and `scripts/test-demo-godot.mjs`. Production is frozen unless a confirmed defect
requires a fix. Newly imported test `.gd.uid` files should be retained.

## Implemented and saved

- Compact starter studio, safe expansion and older-save layout preservation.
- Visible Mina arrival, clear movement hint, short portrait-led introduction,
  free invitation and a first project automatically staffed by Founder/Mina.
- One direct objective, first-release progress and a separate three-step market
  chapter. Actual releases unlock Theo after one and Creative after three.
- A small navigable courtyard with Theo, a shared existing-art furniture cluster,
  a Market Day Kit opportunity and a safe return. The worker owns the location,
  accepted brief, product link and idempotent travel/acceptance transactions.
- Matching worker/Godot bounds, delayed-save protection, older-save migration,
  canceled-project replacement and interrupted-transaction recovery.
- Repaired walk poses, Mina blink, coffee machine, chair depth and Creative
  portrait. Seven approved runtime image changes retain source/provenance and
  hash-bound reviews. New courtyard work adds no runtime PNGs.
- Precise interaction feedback, visitor/sign hover, native story Settings,
  no AI setup in the default story, clean cursor teardown and safe arrival
  placement even when furniture crowds preferred spots.
- Deliberate minimum-window guidance (1024×576), with injected-touch checks.
- A release packager that verifies payload identity and archive integrity,
  includes controls/screenshots and writes an SHA256 sidecar.

## Playable build

The normal export was refreshed immediately after the owner's localhost report.
`http://127.0.0.1:5177/` now serves build **ae82cfc908ec417a**, built at
**2026-11-15T23:08:21.226Z**, including production through `b0aff46`.
The release asset gate passed. HTTP200 responses and exact SHA256 comparisons
confirmed the served HTML, WASM, PCK and browser worker match this build.
PCK: 29,119,440 bytes; engine WASM: 39,514,754 bytes.

Refresh the browser page to load a newly exported build. Source commits alone
do not change an already-running game. Rebuild and verify localhost promptly
after each passing major source checkpoint; do not hold the preview until all
final acceptance testing is complete. `dist/` is ignored generated output and
can be reproduced; do not commit it.

## Verification and remaining limits

- Full authoritative worker suite: **157 passing, 2 existing opt-in skips**.
  Logs: `/private/tmp/courtyard-harness-tests.log` and
  `/private/tmp/courtyard-build.log`. The pre-bounds-only-change offline
  evaluation passed **8/8**, log `/private/tmp/courtyard-offline-eval.log`.
- Root tooling/asset/package suite: **53 passing**. Web TypeScript/Vite build
  passes. The built worker contains the new story routes and no provider
  endpoints, Pi SDK, native filesystem or keychain imports.
- Release asset gate: **804 PNGs, 7 approved changes, no errors/warnings**.
- Focused Godot story, starter-room, workstation, walk, seating and explicit
  legacy-mode `run_all` tests pass. Native cursor lifecycle: **9 checks**;
  arrival placement in compact/full/crowded layouts: **54 checks**.
- A real native worker bootstrap and graceful close now exit without leaked
  textures, RenderingServer or RID errors. See
  `/private/tmp/startup-valley-cursor-production.log`.
- One preliminary rendered journey now passes **382 checks across 10 native
  processes**, including the first release, courtyard edge save/restart, Theo,
  return, real next-project start and New Company reset. The focused small-size
  and injected-touch check passes **22 checks**. These probes repaired the test
  runner; **three final frozen-source journeys have not yet been recorded**.
  A Theo hover label overlap found during visual review is being fixed before
  final acceptance.

The deterministic native runner uses a direct SubViewport displayed in the
native window and forwards injected engine input into the real GameMain scene.
This lets production hover logic read injected pointer positions without
moving the operating-system cursor. The real offline worker remains unchanged.
Wait for stable UI transitions and retain strict gameplay/error assertions.

Earlier browser evidence is historical: [compact acceptance](web/compact-final-playtest.md)
and [structured evidence](web/compact-final-evidence.json). No new physical-phone,
cross-browser or public-host acceptance is claimed. Public hosting remains an
[inactive example](web/public-demo.md), not an installed workflow.

## Resume and verify

Start at the repository root:

```sh
git status --short
git log -8 --oneline
git fetch origin main
git log --oneline origin/main..HEAD
git diff --stat origin/main HEAD
```

Do not overwrite a dirty tree or someone else's new commits. Resolve differing
history only after inspecting it. Save completed work in small commits and push
promptly; distinguish a local commit from a confirmed remote update. After
publishing, verify the branch tip and source tree, then update this handoff at
the next meaningful checkpoint.

Portable verification commands (Godot 4.7.2, Node 22.19+):

```sh
npm run assets:check
npm run assets:test
npm run test:web
npm --prefix harness run check
npm --prefix harness test
npm --prefix harness run eval:offline
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --import
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_story_progression.gd
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_starter_office.gd
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_seated_chair_composition.gd
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_character_portraits.gd
npm run build:web
npm run validate:web
```

Remove `--headless` for required visual capture checks; inspect the resulting
images, not only exit codes. Add targeted actual-scene/worker integration for
new behavior. Do not run paid provider evaluations or read credentials for
these offline checks. Tests use disposable saves.

On the current Mac, the system Git/Python path invokes an unaccepted Xcode
license. Use the installed fallback Git rather than accepting a license:
`/Users/openai/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/fallback/git`.
Node is under the same runtime's `dependencies/node/bin/node`; the usable npm
wrapper is `/private/tmp/startup-valley-tools-SHWkqO/bin/npm`. Godot is
`/private/tmp/startup-valley-godot-4.7.2/Godot.app/Contents/MacOS/Godot`.
These temporary paths may disappear; the portable commands remain authoritative.
Normal Git push authentication was unavailable, but the connected GitHub app
could write this repository. Never persist its credentials in the repository.

## Next concrete work

1. Finish the preliminary native input probe, save its test-only fixes, then
   run three clean complete journeys against frozen committed source at the
   planned sizes/modes. Include exact save/restart comparisons, courtyard edge
   position, Theo's brief, return and starting its real matching project.
2. Finish focused small-screen/touch and actual New Company reset checks.
   Review current native screenshots/animation evidence; fix confirmed defects.
3. Save `docs/web/demo-acceptance.md`, structured results, logs and a concise
   selection of current native captures. Distinguish preliminary/final evidence.
4. Refresh the normal export if production changes. Package it with
   `npm run package:demo -- --screenshot ... --screenshot ... --screenshot ...`,
   retain its ZIP/hash/manifest and verify the served build matches.
5. Complete the newly requested shared-world map framework: modular approved
   props, consistent style/grid/camera, registered maps and hash-bound native
   review evidence. Integrate its validated gate and document future generation.
6. Commit and push each passing increment. Verify local/remote trees, update
   this handoff and mark the goal complete only after required acceptance passes.
