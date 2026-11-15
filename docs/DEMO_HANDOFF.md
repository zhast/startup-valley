# Development handoff — 2026-11-15

## Current scope and status

The owner activated [DEMO_GOAL_PLAN.md](DEMO_GOAL_PLAN.md). The bounded demo's
required implementation and acceptance checks are complete:
the offline opening, first release, courtyard opportunity, reload, current
world visual approval, release gates, normal-build startup and package
integrity have passed. The admitted build is served locally and its runtime
source is published. See [demo acceptance](web/demo-acceptance.md) for exact
evidence and limitations. No owner action or routine approval is required.
Continue without routine approvals. The owner authorizes parallel agents,
fixes, asset work, local exports and frequent tested commits/pushes directly to
`main`. Website/public hosting is **deferred**, not a completion requirement.

Published source checkpoint: local `87e6bf8` corresponds to remote
`a581b9c0bc3022b2ecd268e3e95dfb7a45fa7d87`, with verified tree
`ae045213571618a52828841ba59415f800422fff`. This includes modest furniture,
save-preserving registration migration, shared wooden chairs, approved modular
terrain/connected fence and the later-hire welcome-copy fix. Connector-created
commits can have different IDs with identical full trees. Verify current Git
state before resuming; this document is a checkpoint, not a live branch query.

**Owner constraint:** Do not open windowed Godot demos or capture tests. Use
`--headless` for engine checks and the existing Codex in-app browser, kept in
the background, for current visual/play checks. Do not bring this chat forward,
use OS-level control or switch to another browser profile. Historical native
captures remain component evidence for their recorded source only.

This report and the retained acceptance evidence form the final checkpoint.
The connected-fence yard and all three map reviews are approved. The three
clean headless journeys passed with the later-hire copy fix before the fence
change; an independent seven-file delta audit and current browser play cover
that visual addition. No further runtime changes are planned for this
acceptance. See [VISUAL_QA.md](VISUAL_QA.md).

## Implemented and saved

- A compact starter studio, safe expansion and older-save layout preservation.
- Mina's visible arrival, movement hint, compact portrait invitation and a
  first project automatically staffed by Founder/Mina. The current objective
  provides one direct next action; deeper management is secondary.
- An offline project loop: plan, work across days, release, earn cash, fans
  and reputation. Releases unlock Theo after one and Creative after three;
  optional provider/API work does not gate this loop.
- A bounded courtyard with Theo's Market Day Kit opportunity and safe return.
  The worker owns location, accepted brief, linked product and idempotent
  travel/acceptance. Save/restart, stale requests, cancellation/replacement
  and interrupted transactions have dedicated coverage.
- Modest starter furnishing grants and additive earned improvements. Existing
  owners retain inventory/IDs. New café furniture and call nook use measured
  shared-scale contracts; the registration migration preserves valid layouts
  and safely stores only newly conflicting placements.
- Six shared wooden workstation/collaboration chair layers, preserving the
  tested seated actor anchors and depth behavior. Standalone furniture and
  chair component evidence is retained; current world approval is separate.
- Repaired walk poses, standing/seated eye pixels, 120ms staggered blinks,
  coffee front and Creative portrait. Exact repaired scope and still-open
  issues are in [ASSET_STATUS.md](ASSET_STATUS.md).
- Canonical arrival-Mina collision mapping at the worker boundary, with the
  local retry snapshot unchanged. Earned inventory projects before action
  completion; release summaries show newly granted furnishing names.
- Shared style/scale/map admission gates, registered sources and hash-bound
  reviews. All three current map compositions and two new atlases are approved;
  this is not blanket approval of legacy art or future maps. Frozen legacy
  baselines were not refreshed to pass them.
- A demo packager with payload/archive identity checks. It accepts original
  in-app-browser JPEG captures as well as PNGs,
  preserving their bytes; its focused build-identity suite passes 5/5.

## Build and browser evidence

| Build | Recorded status |
| --- | --- |
| Normal `http://127.0.0.1:5177/` — `d23a483542544696` | Admitted release, built `2026-11-15T23:47:31.703Z` with Godot `4.7.2.stable.official.ed1daf0bf`. Same gameplay payload as the visually approved candidate. All 16 HTTP payloads match SHA256, totaling 71,041,780 bytes. |
| Final-build browser loop — `d23a483542544696` | Fresh reset, Mina compact invitation, Fitness/Course project, three days at 33/67/100%, Day4 release, courtyard Theo acceptance and return. Reload restored Day4, displayed $1.6k earned, Mina and accepted Market Day Kit in the starter office. |
| Earlier candidates `c44018e9a5d119bf`, `01f5a4ee41e4e3a0` | Historical release/reload/Theo hire/expansion/next-project evidence. Their yard was not approved; current final-world evidence supersedes that composition. |

See [current acceptance](web/demo-acceptance.md), the
[served-release hashes](web/assets/world-final/served-release.json) and the
[earlier playtest record](web/in-app-playtest.md). The observed final release
scored **9/10**, gained **13 fans**
and showed **$1,568** launch earnings plus three named furnishing rewards.
These are observed playthrough results, not promises that every project yields
the same outcome. One Mina panel open/Escape-close was also inspected; the
closed frame showed no residual paint and the browser warning/error list was
empty. This does not certify every transition or animation frame.

Use a disposable candidate origin so QA does not reset the owner's normal
5177 save. Refresh the page after an export; committing source does not replace
an already-running browser game. Verify `build-info.json` and served payloads
before reporting a normal-preview update. `dist/` is ignored generated output.
The normal preview now contains these improvements. Startup on the actual
normal release served at disposable origin 5181 passed: Continue → Meet Mina
opened the compact portrait invitation. The browser warning/error record is
empty. The owner’s existing 5177 save was not reset for QA. See the
[normal-release frame](web/assets/world-final/normal-release-invitation-d23a4835.jpg)
and [browser record](web/assets/world-final/browser-errors.json).

The completed local package is
[startup-valley-d23a483542544696.zip](../.build/releases/startup-valley-d23a483542544696.zip)
(39,510,491 bytes, four screenshots). `packageDemo` and `unzip -tq` passed.
SHA256: `cb604fcb3530796d05bffac932ca3a216115f2a26df915de217f6d889071cd1a`.
The [packager log](web/assets/world-final/package.log) and
[checksum sidecar](../.build/releases/startup-valley-d23a483542544696.zip.sha256)
are retained. Generated `.build/` artifacts are local outputs, not public hosting.

## Retained functional verification

[Headless evidence](web/assets/final-headless/README.md) now separates two
runtime inventories rather than combining them into one current-build claim:

| Scope | Checks / phases | Runtime |
| --- | --- | --- |
| Three clean journeys, including the later-hire copy fix | **914 / 26** | `f06f9176745b08fd17ed36b2302f6251789249e8e23ad17e6c549a67092ac3f9` |
| Earlier small-size/touch guard, seeded legacy migration and seeded UI expansion | **109 / 5** (16 + 29 + 64 checks) | `4b0a5102524cad47cd1e809bfa79e614d5516b1b441919a0f1aa63b5b85bbc3e` |

Each group used production GameMain and the real offline worker, and its
runtime stayed byte-identical during its accepted run. The inventories and
one-file copy delta are retained with the summary. These are **pre-fence**
results. The [independent fence review](web/assets/yard-fence-v1/independent-review/README.md)
records the exact seven-file change to final runtime
`5e8afa18aa826a0883d0af6506aa47c96e9d405c7766fe86befe7d474c882ebd`:
170 selected worker/web/protocol/navigation/actor files are unchanged, as are
the existing courtyard floor, paving, props and interactions. Final fence
coverage is 752 checks, 17 map tests and 9 actual component routes. This is a
scoped delta audit, not three additional full journeys on the final runtime.
The prior 1,023-check combined total must not be described as 1,023 checks on
the copy-fix or final fence runtime.

The final full asset gate passes: **809 runtime PNGs validated, 18 reviewed
artifacts**, three reviewed maps, and **7,259 engine checks** with zero test
failures. The legacy snapshot is not 809 artistic approvals. All **75 root
web/tooling tests** pass; normal export validation and served-payload identity
also pass. Logs are retained in [world-final](web/assets/world-final/assets-headless.log)
and [tooling.log](web/assets/world-final/tooling.log). The asset log includes
the known macOS certificate diagnostic; it is not claimed to be empty.

The clean journeys cover arrival, hire, first project, development, release,
courtyard edge save/reload, Theo's opportunity, return and a matching next
project. The third also tests actual New Company/reset and restart. Dialog
keyboard coverage is not keyboard-only world traversal. Injected touch is not
physical-phone evidence. Logical rendering remains 1280×720 with tested size
transforms and the intentional minimum-size guard. This headless evidence
cannot approve rendered pixels.

Additional focused evidence:

- Later-hire wording: **248 headless dialogue checks**, zero failures. The
  welcome uses saved release history, keeps its bounds and opens planning by
  actual pointer input. Report: `/private/tmp/startup-valley-late-hire-dialogue/result.json`.
- Real worker renovation/recovery: four headless phases, nine durable layout
  mutations, stable source and worker shutdown. Retained report:
  [headless worker UI](web/assets/furniture-scale-v1/headless-worker-ui.json).
- Actual copied older databases retained valid placements, ownership and
  player positions through registration migration:
  [legacy save checks](web/assets/furniture-scale-v1/legacy-save-migration.json).
- Furniture worker increment: 168 passing tests and two opt-in skips in
  [the retained harness log](web/assets/world-final/prior-harness.log); provider-free evaluation
  8/8 in [the retained offline log](web/assets/world-final/prior-offline-eval.log). These are named
  checkpoint logs, not an assertion that every later edit was in that run.

No public-host, cross-browser, physical-phone, complete accessibility or
performance acceptance is claimed. Earlier [compact browser acceptance](web/compact-final-playtest.md)
and native screenshots are historical. Public hosting remains an
[inactive example](web/public-demo.md).

## Resume and verify

Inspect the shared tree and remote before changing it:

```sh
git status --short
git log -8 --oneline
git fetch origin main
git log --oneline origin/main..HEAD
git diff --stat origin/main HEAD
```

Do not overwrite a dirty tree or another agent's work. Save tested increments
promptly and distinguish local commits from confirmed remote publication.
After pushing, verify the remote tip/tree and update this checkpoint.

Portable checks use Godot 4.7.2 and Node 22.19+:

```sh
npm run assets:check
npm run maps:check
npm run test:web
npm --prefix harness run check
npm --prefix harness test
npm --prefix harness run eval:offline
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --import
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_story_dialogue_layout.gd
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_starter_office.gd
STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1 godot --headless --path game --script res://tests/test_seated_chair_composition.gd
npm run build:web
npm run validate:web
```

The current release passes admission. Future map/art changes require a new
review; do not bypass the gate or refresh frozen baselines. Use the
exact headless journey commands in the retained evidence README, fresh output
directories and disposable saves; **do not add `--render`**. Do not run paid
provider evaluations or inspect credentials for offline tests.

On this Mac, system Git/Python may invoke an unaccepted Xcode license. The
fallback Git is
`/Users/openai/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/fallback/git`.
Node is in that runtime's `dependencies/node/bin/node`; the npm wrapper is
`/private/tmp/startup-valley-tools-SHWkqO/bin/npm`. Godot is
`/private/tmp/startup-valley-godot-4.7.2/Godot.app/Contents/MacOS/Godot`.
These temporary paths can disappear. Normal Git push authentication was
unavailable; the connected GitHub app can publish this repository. Never save
its credentials in source.

## Final checkpoint

The final evidence is committed with this handoff; use the current Git log
for its commit ID and compare full trees when publishing through the connector.
No further demo implementation, repeated passing checks or owner setup is
required. Public hosting and website polish remain deferred; no mandatory
owner follow-up is left. The ZIP can be rebuilt with the commands and current
screenshots in the acceptance report if the local generated artifact is lost.
