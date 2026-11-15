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
