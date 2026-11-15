# Development decisions

Record consequential changes here with their reason and verification. Update an
entry when a decision changes rather than leaving competing instructions.

## 2026-11-15 — A cozy, offline studio story

**Decision:** Keep the authoritative offline tycoon in the worker, while Godot
presents characters, short conversations and a clear first-release journey.
Real providers are optional legacy functionality, not prerequisites for play.
Use the fictional TownSquare name in player-facing content; keep old internal
IDs only where needed to read existing saves.

**Reason:** The owner wants a story and achievement game with the approachability
of Stardew Valley and the studio-growth loop of Game Dev Tycoon.

**Evidence:** [Story progression](web/story-progression.md),
[reference comparison](web/gameplay-reference-audit.md), and the offline harness
suite, including legacy-name/save compatibility.

## 2026-11-15 — Teach by playing one short chapter

**Decision:** The opening teaches meeting Mina, choosing an idea, developing it
over days and releasing it. Present one current objective and one direct action,
with four visible milestones. Derive progress from saved gameplay state; do not
add a second tutorial-completion database. Introduce optional management through
disclosures after the core action is clear.

**Reason:** A clipped paragraph that tells the player to find another menu is
neither guidance nor a useful status display. Character introductions must show
who a person is and what they do before describing systems.

**Evidence:** [Stardew visual audit](web/stardew-visual-audit.md),
`test_story_conversation.gd`, `test_story_progression.gd`, and the actual-browser
playtest. Published reference screenshots are distinguished from local testing.

## 2026-11-15 — Small beginnings, safe expansion

**Decision:** New companies start in a compact studio with an entrance alcove and
a visible garden surround. Existing companies retain their original layout.
Persist the layout identity, and migrate furniture transactionally when the team
needs the larger office. The garden is scenery until actual outdoor gameplay is
implemented.

**Reason:** The full-screen rectangular office felt empty and confining. Moving
walls without versioning would strand saved furniture and break navigation.

**Evidence:** [Room and gameplay audit](web/gameplay-reference-audit.md),
`compact-office.test.ts`, `test_starter_office.gd`, and migration 017.

## 2026-11-15 — Review art in the game

**Decision:** Use one original style profile and reference board, retained
generation prompts/sources, explicit camera/anchor/layer contracts, and
hash-bound visual reviews. Geometry checks alone do not approve art. Keep
character identity, walk poses and furniture occlusion visible in acceptance
captures. Record discovered layering rules alongside their regression tests.

**Reason:** Individually plausible assets can still be inconsistent or wrong
when composed. Prevent regressions with verifiable source and runtime evidence,
while acknowledging that visual review still requires judgment.

**Evidence:** [Asset workflow](ASSET_WORKFLOW.md),
[browser acceptance](web/playtest-polish.md), and
`dev/art-catalogue/style-profile.json`.

## 2026-11-15 — Preserve facing-specific chair occlusion

**Decision:** Place the north seated lower body behind the chair back while
retaining the head in front. Preserve the other three facing orders, sprite
cuts, navigation anchors and all existing images.

**Reason:** The north-facing lap obscured a correctly drawn backrest. Raising
the whole chair instead introduced an empty-chair/desktop overlap defect.

**Evidence:** [Depth decision, actual room captures and negative-control
regression](decisions/2026-11-15-seated-chair-depth.md).

## 2026-11-15 — Small direct-to-main checkpoints

**Decision:** Commit tested major increments directly to `main` and refresh the
local web build. Pull requests are optional isolation tools, not an approval
gate for this single-owner project.

**Reason:** The owner needs to play each meaningful change promptly. Report when
source is committed but a new playable export or browser verification is pending.

## 2026-11-15 — Preserve progress without waiting for the owner

**Decision:** Push each tested checkpoint to `main` promptly and maintain a
durable [handoff](DEMO_HANDOFF.md). Preserve useful work, test evidence and next
steps in the repository. Local commits and successful remote pushes must be
reported separately. Ordinary authorized work does not need further approval.

**Reason:** The owner may not return and the current computer/session may be
interrupted. A dirty working tree or an unpushed commit is not an off-machine
backup.

**Scope update:** Website and public-hosting work are deferred. The prepared
deployment workflow is retained only as an inactive example. Use integrated
Godot tests, rendered engine captures and automated worker/export validation;
no computer-use session is required. Prior browser evidence remains useful,
but does not claim future browser coverage.

## 2026-11-15 — Bind demo packages to the complete exported payload

**Decision:** A normal export records an identity and SHA256 for every payload
file, including the worker and its SQLite WASM. Packaging refuses a preview
build, missing runtime, changed payload or symbolic link; it includes controls,
three current captures, a manifest and an integrity-tested ZIP with a checksum.

**Reason:** A stale loader or worker can be as damaging as a stale game pack.
File integrity does not establish gameplay quality, so manifests point to the
separate acceptance report instead of claiming a playtest passed.

**Evidence:** `tests/build-identity.test.mjs` covers payload drift, metadata
stability, rejected inputs and a ZIP round trip. All 53 root tooling tests pass.

## 2026-11-15 — Grow through offline releases and one neighboring story

**Decision:** Actual releases unlock Theo after one shipped project and Creative
after three, while preserving earlier optional chapter unlocks for old saves.
The first release opens a bounded courtyard visit where Theo offers a Market
Day Kit. Accepting the brief unlocks its existing research topic; development
and earnings use the ordinary product simulation. No conversation invents cash.

**Persistence:** The worker owns location, saved return point, accepted brief
and linked product. Travel and acceptance use revision checks and durable
operation receipts in one transaction. Delayed saves cannot overwrite a newer
location. Cancellation permits a replacement project; New Company clears the
old story and its receipts. The renderer must share the worker's geometry
contract so every legal movement can be saved.

**Evidence:** `offline-progression.test.ts`, `courtyard-story.test.ts`, and the
real process-interruption fixture. The complete worker suite passes 156 tests
with 2 pre-existing opt-in skips; offline evaluation passes 8/8. Integrated
Godot journey acceptance remains in progress at this checkpoint.

## 2026-11-15 — Keep the playable preview alongside source checkpoints

**Decision:** A major passing source checkpoint also triggers a normal release
export and verification of the files served on localhost. Do not wait for all
final acceptance to finish before refreshing the preview. Report the build ID
and distinguish available-to-try from fully accepted.

**Reason:** The owner correctly observed that committing source did not update
the running localhost game. Build `ae82cfc908ec417a` was exported and its served
HTML, WASM, PCK and worker were verified byte-for-byte to resolve the stale view.

## 2026-11-15 — Protect rendered targets and scope asset approvals honestly

**Decision:** Hover callouts derive their bounds from the rendered actor/sign,
including its nameplate, not its navigation approach point. Their complete
painted bounds must clear the target and protected world content. The targeted
native regression passes 57 checks and reproduces the former Theo overlap as
a negative control.

**Asset audit:** The user's repeated blink report exposed a gap in the earlier
review: the seated Mina correction did not touch her standing closed-eye cell.
That cell still shows pale bang marks while the pupils remain open. A second
issue holds idle blinks closed for about 667 ms at a 50% duty cycle. Both are
reopened in `ASSET_STATUS.md`; existing raster approval is not evidence that
every pose or its runtime timing is correct.

## 2026-11-15 — Make future maps belong to one visual world

**Decision:** Maps share the existing original-art profile, 32px grid, fixed
elevated camera, native scale, material ramps and modular catalogue props.
Map admission reads actual authored geometry through explicit adapters and
binds narrow composition sources/art to current native review evidence.
New or changed maps cannot use a legacy snapshot as an approval.

**Limit:** Mechanical geometry, provenance and reference checks do not judge
beauty. Existing snapshots remain explicitly unreviewed until inspected in
Godot. Deficient shared assets are repaired in their source workflow, rather
than independently patched or resized in each map. See `MAP_WORKFLOW.md`.

## 2026-11-15 — Calibrate furniture together with the same actors

**Finding:** A native side-by-side audit confirms mixed ground registration
and seat/enclosure proportions across office furniture. Unit sprite scale
does not prove consistent authored dimensions. The current style board uses
different inspection zooms and therefore cannot serve as a scale chart.

**Decision:** Define seat, desktop, doorway and foot-contact landmarks against
the unchanged actor and 32px grid. Distinguish vertical rise from projected
floor depth. Future generation uses both the style board and a same-scale
native calibration reference. Repair source families rather than adding
per-map scaling. A larger booth collision footprint requires a save-preserving
placement migration, not a reset of owned furniture.

**Evidence and pending work:** `FURNITURE_SCALE_AUDIT.md` retains the native
lineup and measured geometry. Its 39 mechanical checks pass while visual
quality is explicitly marked corrections-required. Café chair/table, booth
and occupied office-chair repairs remain open; map visual approval waits.

## 2026-11-15 — Short blinks and correctly registered eyelids

**Decision:** Idle eyelids close for 120ms every four seconds, with different
character phases. Movement retains its independent gait timing. Input-blocked
Founder continues the blink clock instead of freezing with closed eyes.
Generated overlays correct Mina's three visible standing facings and Founder's
front closed-eye frame; Theo and Creative did not need new raster pixels.

**Evidence:** Final byte-stable native input/playback passes 196 checks;
targeted blink/pixel/actor checks pass 105. The full pose inspection and exact
provenance live in `docs/web/assets/blink-polish-v3/` and its runtime reviews.
Only 112 Mina and 46 Founder pixels changed; open eyes, bodies, walks and alpha
remain unchanged. The blink regression is now in the required asset gate.

## 2026-11-15 — Browser testing without system-level computer access

**Owner clarification:** Actual web playtesting is now authorized inside
Codex's in-app browser. Keep the native Godot tests; add browser checks on a
separate localhost origin so the owner's 5177 save is untouched. Do not use
OS-level computer control or other browser profiles. Public hosting remains
deferred. Record the exact browser build and distinguish its coverage from
native, physical-device and cross-browser acceptance.

## 2026-11-15 — Content-sized character dialogue and concrete visual checks

**Decision:** Center the invitation on the full canvas and let its portrait,
short introduction and single action determine a compact card. Keep one shared
safe rectangle and Container layout. The card is now680×256 instead of860×344;
the portrait frame is144×160. Preserve direct reward feedback in the release
summary, only for newly granted furnishings.

**Evidence:** [Compact invitation](web/compact-invitation.md) retains actual
before/after scenes and three viewport checks. Native250 and headless241 layout
assertions pass. Worker projection checks guarantee inventory arrives before
the summary is presented. [Visual QA](VISUAL_QA.md) records researched tooling,
same-scale measurements, screenshot limits and the review loop.

## 2026-11-15 — Keep background testing non-disruptive

**Owner instruction:** Stop windowed Godot demos; this chat runs in the
background while other chats are in use. All agents stopped native windows.
Use headless Godot and the existing Codex in-app browser for current visual
evidence, without activating other browser profiles or controlling the OS.
Earlier native captures remain historical evidence, not proof of a later build.

## 2026-11-15 — Preserve the arrival visitor in furniture validation

**Finding:** Before Mina is hired, navigation reserves her position as
`arrival-mina`, while the worker protocol accepts her canonical ID `mira`.
Passing the local alias rejected otherwise valid renovation saves.

**Decision:** Deep-copy and canonicalize that ID at the WorkerClient transport
boundary, keeping exact grid/position protection and the original frozen local
snapshot for retry/movement checks. Do not remove the visitor from collision
validation. The headless actual-worker renovation test now passes the formerly
rejected save operations; focused projection checks also cover immutability.
