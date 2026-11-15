# Development handoff — 2026-11-15

## Current scope and permission

The owner authorizes implementation, art repairs, integrated Godot tests, local
exports, and frequent tested commits/pushes directly to `main`. Do not wait for
the owner to return for routine decisions. Website/public-hosting work is
**deferred**. Use integrated Godot and automated worker/export checks; no
computer-use session is required. The existing in-game project preview stays.

The next bounded project is in [DEMO_GOAL_PLAN.md](DEMO_GOAL_PLAN.md), including
the accepted `/goal` prompt. The owner activated this goal on 2026-11-15.
Current status: active; worker progression, Godot world/UI, and integrated QA
are assigned to separate agents. Root coordinates integration and Git pushes.

### Active goal checkpoints

- Confirmed remote `main`: `6966203176a7adabccd49d3d929a924ed477629c`
  (initial polish, compact-room QA, active plan, offline unlocks and packaging).
  Local history was aligned after verifying identical complete Git trees.
- Local `4c0b134` + `982e43a`: durable courtyard/location/market brief,
  offline release unlocks, save revision checks and interrupted-travel recovery.
  The complete worker suite passes 156 tests with 2 opt-in skips; offline
  evaluation passes 8/8. The contract follow-up fixes an omission discovered
  by the full suite; publish the coherent pair together.
- Godot world/UI integration and actual-input journey tests are in progress.
  Do not confuse the saved worker slice with a completed visual demonstration.

## Saved implementation

- Compact starter studio for new companies, with garden scenery, two desks,
  safe layout identity/migration, and expansion when the company grows. Old
  saves retain their layout. The garden is not yet a playable outdoor area.
- Portrait-led Mina introduction, explicit role, short dialogue, free invitation
  and direct entry into a first project with Founder and Mina assigned.
- Four-step story goal with a compact progress display and a direct action.
- Precise pointer/interaction feedback, seated project workers, sidebar layering
  repairs, fictional TownSquare branding and an in-game project-site preview.
- Seven reviewed runtime image repairs: alternating side-walk poses, Mina's
  seated blink and the front of the coffee machine. Source prompts, transforms,
  original style profile and hash-bound reviews live in the art catalogue.
- Facing-specific seated chair depth fix and a distinct Creative portrait.
  See [the chair decision](decisions/2026-11-15-seated-chair-depth.md).

The main implementation checkpoint is local commit `e0f926e`, followed by plan
and QA-evidence commits. `b24058b` saves the final compact-office evidence and
Godot resource IDs. GitHub publication recreates commits through the connector,
so remote commit IDs can differ while their complete Git trees match. Confirm
current local/remote state using the commands below rather than assuming these
historical IDs identify the branch tip.

## Current build and evidence

The latest normal release export was built at
`2026-11-15T22:54:04.023Z`, with the release asset review gate enabled. It includes
the compact office, new opening/goal, art fixes, chair back and portrait repair.
New source checkpoints after that export include offline teammate unlocks
(`e8a34fe`) and verified ZIP packaging with full-payload identities (`9ee6e0b`).
These newer changes are committed but await the next normal release export.
`dist/` is generated and ignored; rebuild it rather than committing it.

The final pre-deferral browser session completed invite → first project →
33/67/100% development → release, earning $1,568 and 13 reputation, with goal
4/4 and no observed JavaScript/Godot errors. Mina's seated blink was clean and
59 drawer frames showed no changing rail-portrait pixels. That session closed
when testing switched to integrated Godot. Exact hashes, screenshots and
limitations: [compact acceptance](web/compact-final-playtest.md) and
[structured evidence](web/compact-final-evidence.json).

Integrated verification performed during these increments includes:

- Offline harness: 145 passing, 2 existing opt-in skips.
- Web tooling: 48 passing; asset tests: 16 passing.
- Packaging checkpoint: all 53 root tooling/asset tests pass, including five
  new identity/packaging checks and ZIP round-trip verification. The first
  sandboxed run could not bind the loopback fixture server; the authorized
  rerun with loopback access passed. No browser UI was used.
- Asset release gate: 804 runtime PNGs, 7 reviewed changes, no errors/warnings.
- Story progression: 57 headless / 64 rendered checks; starter office: 32.
- Seated-chair composition: 234 headless / 282 rendered checks across 48 poses;
  transition coverage and negative controls detect the former ordering defect.
- Office architecture, furnishing projection, daylight, portrait identity and
  story conversation tests also passed in the corresponding increments.

See [verification](web/verification.md), [story progression](web/story-progression.md),
[room/reference audit](web/gameplay-reference-audit.md), and the tracked chair
capture logs. This list records previous results, not a claim that every suite
was rerun after this documentation-only checkpoint.

Coverage limits: the updated permanent browser playtest passes syntax checking
but was not rerun in full on this exact export. Fresh export reload/furnishing,
physical touch devices and cross-browser behavior are not newly verified.
Integrated full-journey/restart acceptance in the goal plan is still future
work. No anonymous public demo URL is verified. The former hosting work is
preserved as an [inactive example](web/public-demo.md), not an installed workflow.

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

1. Confirm the coherent worker pair has reached remote `main`; the offline
   unlock audit and durable courtyard simulation are implemented and tested.
2. Complete contextual movement/interaction hints and the post-release next
   objective, deriving progress from saved state and preventing duplicate rewards.
3. Implement one small courtyard story opportunity with a safe return, bounded
   to the existing simulation. Preserve the compact room and expansion logic.
4. Add actual Godot scene + production-worker clean-save and restart journeys;
   exercise keyboard/pointer/viewport behavior and render changed visual states.
5. Run affected regressions, normal release validation and package the demo.
   Record exact evidence and remaining limits; commit/push each passing increment.
