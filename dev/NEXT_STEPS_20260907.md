# Recommended next steps after the directional art pass

September 7, 2026 UTC. Recommendations, not a new implementation authorization.

## Where the game actually stands

The three-day founder → Mina → website → Theo → ads → incorporation journey
already exists. Hiring, bounded work, approval, evaluation, revision, override,
rewards, Studio, day changes and recovery are not a new missing framework to
rebuild. The completed art objective adds seven integrated furniture systems
with four-facing profiles and a 42-family / 168-view reviewed catalogue.

The important distinction is **available art versus playable systems**. There
are 132 accepted passive library views and ten role toolkits, but they are not
automatically furniture inventory, new hires or live Whop capabilities. Renovate
currently keeps layout only within the session and Undo only within that visit.

Evidence:

- [Art acceptance and limits](art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md).
- [Paid journey playtest findings](LIVE_PLAYTEST_FIXES.md).
- [Session-local Renovate](../game/ui/office_renovation.gd).
- [Current artifact milestone adapter](../harness/src/milestone-adapter.ts).

Pre-push provider-free verification on this checkpoint: worker build and tests
pass (49 passed, one optional Godot integration test skipped); offline evaluator
passes all eight fixtures. This is not a fresh paid provider replay.

## Recommended order

| Priority | Work | Why now | Acceptance gate |
| --- | --- | --- | --- |
| 1, parallel | Uncoached internal playtests and a repeatable internal build | Validate comprehension and fun on the actual final art, not just fixture correctness | New players complete the core loop without a walkthrough; the same build runs outside the developer checkout |
| 2 | Durable furnishing and Mina/Theo role-kit integration | Converts the completed art library into a player-owned office | Move, rotate, decorate, save and restart with identical valid placement and distinct employee desks |
| 3 | Better delivery inspection and revision comparison | Real work must be satisfying and understandable after it completes | Visually inspect a website, find files, compare a revision and trace Studio provenance |
| 4 | Earned office identity and post-chapter choices | Connect useful work to visible rewards and reasons to return | Players understand what unlocked, why it matters and what to do after chapter one |
| 5 | One complete new specialist | Prove extensibility without multiplying unfinished systems | A single new hire has a distinct deliverable, complete interaction/lifecycle and restart coverage |
| 6 | One narrowly scoped Whop adapter | Validate real product value only after the game flow is understandable | Draft/preview first; explicit external confirmation, receipt and retry safety before live consequences |

## 1. Test the integrated product, not another asset sheet

Have three to five Whop teammates play independently, without coaching. Record
their screen with consent and collect manual observation notes; a new analytics
SDK is unnecessary for this first round. Keep model/provider and game version
fixed so observations are comparable. Use disposable companies, not personal
saves; any new paid job run needs explicit authorization.

Observe whether they can discover Journey, hire Mina, distinguish conversation
from starting work, understand pauses and work hours, inspect a result, handle a
revision, promote to Studio, end a day and resume after restart. Track hesitation,
repeated clicks, missing feedback, text clipping, confusion about fictional
company cash versus real AI spend, and periods with nothing interesting to do.

Accept when those essential paths are understandable without a walkthrough,
every observed blocker has a reproducible report, and the next work list is
ranked by player impact rather than cosmetic preference. A small qualitative
test is directional evidence, not a retention or statistical-success claim.

Run the existing provider-free regression suite alongside this. Record real
pointer/keyboard input, rapid selection, disabled controls, Escape/focus,
worker-disconnected recovery, window resizing and long-copy scenarios. Profile
frame-time/input latency on target hardware: the desired click response is one
rendered frame and ordinary transitions remain around 80–180 ms. Fixed-30-FPS
audit movies do not by themselves prove interactive frame-rate performance.

### Internal delivery and automation, in parallel

There is no checked-in CI workflow or Godot export preset today. Add a pinned,
provider-free CI baseline: worker build/tests, offline evaluation, Godot import
and gameplay/layout/input checks, catalogue validity/freshness and a bounded
visual smoke set. Keep paid provider runs opt-in and separate.

Define an explicit runtime export allowlist before sharing an app package.
Bundle or reliably locate the worker/Node runtime; exclude source masters,
developer scripts, passive fixtures, audit companies and evidence. Test a clean
machine/account, keychain onboarding, app restart, fonts/licenses, backup and
upgrade migration. Inspect actual OS fullscreen, Retina and supported window
sizes; existing controlled-size capture evidence is not fullscreen certification.

## 2. Make the office durable and personal

Add versioned, worker-owned furniture inventory and layout state in SQLite,
bootstrap restoration, transactional updates and migration from the existing
default layout. Keep the Godot scene a projection. New Company must reset the
new state through the existing recoverable backup workflow.

Preserve the existing placement rules: fixed-camera authored facing, footprint,
clearance, wall/corner checks, service/seat access, live-actor rejection and
navigation replanning. A corrupt or incompatible stored layout should restore
the last valid room and explain recovery, not strand the founder or an employee.

Integrate Mina's product/research kit and Theo's growth/campaign kit first, plus
a small useful selection such as a plant, lamp, whiteboard, storage and lounge
piece. Do not expose all 42 families at once. Add a readable placement picker
with previews, owned/unlocked state, place/store/remove and intentional empty
states. Continue using separate host, role, character and occlusion layers.

Acceptance: place and rotate in all supported directions; quit/reopen and get
the same room; begin work and complete its interaction without collisions or
contact defects. Test duplicate commands, invalid geometry, failed saves,
restart mid-update, migration and New Company. Never charge twice or lose the
last valid layout. Saving should have visible success/failure feedback.

## 3. Make the result of work tangible

Add a deliberately constrained local website preview beside the existing
source/document view. It should present desktop/mobile layouts without
unrestricted scripts, publishing or arbitrary file access. Determine the safe
preview mechanism before adding execution privileges or production dependencies.

Group delivery files into a clear result, retain job/employee provenance, and
show what changed between revisions. Make Keep with job versus Add to Studio
easy to understand. A ready artifact should be discoverable from Activity,
the delivery notification and Studio without several competing banners.

The evaluator currently reviews guarded HTML/CSS text, not the rendered page.
Keep this distinction explicit; a future visual rubric should be a separate,
bounded evaluation capability with visible cost and retry behavior, not silently
represented as already present.

Acceptance: players can see the produced website, find its sources, compare a
revision and trace promoted files back to the originating job. Failed preview
or evaluation never destroys a completed artifact or duplicates a reward.

## 4. Connect progress to office identity

Use the next playtest to choose a small number of meaningful unlocks: a role
kit, furniture item or office improvement tied to a useful deliverable. Keep
gross earned revenue, spendable fictional cash, reputation and real AI spend
clearly distinct. Avoid adding mandatory waiting simply to lengthen the chapter.

Give chapter completion a clear ending and a next choice: continue freeform
work, pursue a new company objective or recruit the one next specialist. Tune
work durations, reward cadence, day-end summaries and tutorial hints based on
observed confusion. Do not add farming/combat/romance mechanics merely to
increase the resemblance to another game.

Acceptance: the reward is visible, the player understands why it unlocked,
office changes survive restart, and chapter completion is not an unexplained
dead end. Fictional milestone completion must not imply an external service ran.

## 5. Add one specialist end to end

Choose creative or legal after identifying the strongest user need; do not add
both simultaneously. Include candidate/unlock, hire transaction, rail portrait,
four-facing room pose/contact, role kit, bounded assignment, deliverable rubric,
approval/failure/revision, delivery, progression and save/restart coverage.

Acceptance: the specialist produces a visibly different useful outcome, not
just a renamed employee with a different desk. Legal remains a planning service
unless actual filing/integration is separately designed and authorized. The
existing portrait studies are candidates to adapt/review, not already-installed
employee identities.

## 6. Pilot one Whop capability

Start with an adapter that returns a draft/preview or read-only result. Keep
the job lifecycle and game UI stable while the adapter translates a milestone
to a real service. Live ads, payments, publishing or incorporation require
explicit confirmation, clear real-world cost/consequences, idempotent operation
IDs, authoritative receipts and recovery from partial success.

Acceptance: the player can distinguish a local draft from a real external
action, retry without duplication, and inspect the actual service result.
Do not equate fictional company rewards with real Whop transactions. Keep
credentials, tools, persistence and provider logic in the worker.

## Best next implementation goal

**Durable furnishing + Mina/Theo role-kit integration, verified through a fresh
end-to-end chapter and restart.** Conduct unfamiliar-player research and build
automation in parallel; use the findings to choose the next product slice.

Defer further broad art batches, alternate whole-UI skins, additional room
themes, many simultaneous specialists, parallel agent concurrency and extra
platforms. The current bottleneck is turning the art and working AI foundation
into understandable, persistent and rewarding play—not asset quantity.
