# Development handoff — 2026-11-15

## Current scope and status

The owner activated [DEMO_GOAL_PLAN.md](DEMO_GOAL_PLAN.md). Status: **active**;
implementation is present, final frozen-source integrated acceptance and demo
packaging remain. Continue without routine approvals. The owner authorizes
parallel agents, fixes, art work, integrated Godot tests, local exports, and
frequent tested commits/pushes directly to `main`. Website/public hosting is
**deferred**. The owner now authorizes actual web playtesting inside Codex's
in-app browser, without OS-level control or other browser profiles. QA should
serve the same `dist` on a separate localhost origin (planned port 5181) to
avoid modifying the owner's existing 5177 save. Native testing remains required.

Latest confirmed remote checkpoint: `d881da406d76f68b1a6c32f4c70ebeb2f00e27d6`,
the exact tree of local `0f32486`: compact centered Mina dialogue, reward
projection and retained visual audit. Previous local `46c2e0b` (earned furnishing
grants) is also pushed; local `3cd6e71` contains the completed blink repair.
Verify
Git state before resuming; connector-created remote commits can have different
IDs with identical full Git trees. Do not overwrite someone else's new work.

**Latest owner constraint:** No windowed Godot demos or captures. All agents
stopped them; the process inventory confirmed only headless Godot remains.
Use headless engine checks and the existing Codex in-app browser tab without
bringing this chat to the foreground. Keep other browser profiles/OS control out.

Current work owners: asset-quality handles the shared cute wooden workstation
and collaboration chairs; story-progression handles standalone furniture scale,
earned grants and save-preserving registration migration; shell-quality handles
shared modular office/courtyard terrain. Root owns visual-QA documentation,
WorkerClient integration, publication and in-app browser verification. Hold
normal exports while these raster/map reviews are pending. Retain new `.gd.uid`
files. See [VISUAL_QA.md](VISUAL_QA.md) for the current review loop and tool choice.

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
- Repaired walk poses, Mina seated eye pixels, south coffee front, chair depth and Creative
  portrait. Seven approved runtime image changes retain source/provenance and
  hash-bound reviews. New courtyard work adds no runtime PNGs.
- **Completed:** Mina and Founder standing eyelids are repaired; idle blinks
  last 120ms every four seconds, staggered by actor. The final byte-stable native
  timing run passed 196 checks, with 90 samples; focused blink checks passed105.
  These changes are committed, pushed and in the current normal web export.
  See `ASSET_STATUS.md` for exact generated/code-only scope.
- New owner report: chairs, desks and phone booths feel inconsistently scaled.
  A separate agent is measuring their painted bounds, anchors and proportions
  in native scenes; preserve pending map evidence but do not approve it yet.
- Precise interaction feedback, visitor/sign hover, native story Settings,
  no AI setup in the default story, clean cursor teardown and safe arrival
  placement even when furniture crowds preferred spots.
- Deliberate minimum-window guidance (1024×576), with injected-touch checks.
- A release packager that verifies payload identity and archive integrity,
  includes controls/screenshots and writes an SHA256 sidecar.

## Playable build

`http://127.0.0.1:5177/` serves build **b5d7da90f647ea26**, built at
**2026-11-15T23:19:52.930Z**, including production through `3cd6e71`.
The release asset gate passed. HTTP200 responses and exact SHA256 comparisons
confirmed the served HTML, WASM, PCK and browser worker match this build.
The standing-blink/timing fixes are included. The later compact dialogue,
earned furniture grants and in-progress world/furniture work are not yet in it.
QA origin `http://127.0.0.1:5181/` currently serves the same dist; the root agent
has verified WebGL startup, movement and the Mina invitation in the in-app
browser. Full release/reload browser acceptance remains pending.

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
- Root tooling/asset/package/map suite: **65 passing**, including adapter,
  stale-review and combined CLI initialization regressions. Web TypeScript/Vite build
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
  The Theo hover label overlap is fixed; its native regression passes **57
  checks**. Final acceptance waits for the standing-blink/timing repair.

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

Keep `--headless`; windowed runs are disallowed by the owner's latest request.
Use the existing in-app browser for current rendered evidence. Add actual-scene/worker integration for
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

1. Finish and save modular terrain, furniture and projection work, then
   run three clean complete headless journeys against frozen committed source at the
   planned sizes/modes. Include exact save/restart comparisons, courtyard edge
   position, Theo's brief, return and starting its real matching project.
2. Finish focused small-screen/touch and actual New Company reset checks.
   Review current in-app browser screenshots/animation evidence; fix confirmed defects.
3. Save `docs/web/demo-acceptance.md`, structured results, logs and a concise
   selection of current browser captures. Distinguish preliminary/final evidence.
4. Refresh the normal export if production changes. Package it with
   `npm run package:demo -- --screenshot ... --screenshot ... --screenshot ...`,
   retain its ZIP/hash/manifest and verify the served build matches.
5. Complete the newly requested shared-world map framework: modular approved
   props, consistent style/grid/camera, registered maps and hash-bound engine/browser
   review evidence. Integrate its validated gate and document future generation.
6. Commit and push each passing increment. Verify local/remote trees, update
   this handoff and mark the goal complete only after required acceptance passes.
