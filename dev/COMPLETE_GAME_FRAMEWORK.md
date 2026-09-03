# Complete-game framework pass

> Live follow-up: the [initial 3 September playtest](LIVE_PLAYTEST_2026-09-03.md)
> exposed startup, evaluator-evidence, and UI/state defects missed by deterministic
> tests. They were fixed in production and followed by two paid chapter replays
> without overrides. The [fixes and acceptance report](LIVE_PLAYTEST_FIXES.md)
> is the current readiness assessment, including evidence and remaining limits.

## Scope and authority

Implemented for the founder/Mina/Theo desktop chapter. Godot owns presentation,
input and cached views; the TypeScript worker remains authoritative for durable
company state, work, evaluation, money and artifacts. No live ads, legal filing,
payment, publishing, new provider, unrestricted tools, or production dependency
was added. Mina's durable employee ID remains `mira` for save compatibility.

## Play loop

1. New Company starts founder-only. Continue restores the saved company.
2. Hire Mina free from Journey. Day 1: website (`site/index.html`, `site/styles.css`).
3. Evaluate the delivery. Passing means every criterion >= 2 and mean >= 2.5.
   Explicit completion awards $600/10 reputation, once. Theo becomes available
   for $300. Revision copies prior files into tool-enforced read-only `handoffs/`.
4. Day 2: Theo's advertising plan (`ads/campaign-plan.md`, `ads/creative.md`)
   awards $1,200/15 reputation. This does not launch ads.
5. Day 3: Mina's incorporation readiness/checklist planning files cost $500,
   award 20 reputation, and complete chapter one. This does not incorporate a business.

Full-reward route ends with $1,000 cash, $1,800 gross earnings, and 45 reputation.
Override awards half the monetary reward, no reputation, and the normal unlock;
the filing fee still applies. Even the all-override route remains affordable.
Ads unlock no earlier than Day 2 and incorporation no earlier than Day 3.

Work hours are 08:00–17:30 with lunch 12:30–13:30. One real second advances one
business minute while exploring (9.5 minutes per complete office day). Menus
pause time, founder movement and employee travel/wandering. AI keeps running.
End Day may be chosen early; the 30-minute target is approximate, not a forced
wait. At closing the clock stops and Journey shows the day's wrap-up. Active
work must finish or be cancelled; queued work survives into the next morning.

## Controls and physical world

- Click walkable ground: reserved AStar route and immediate destination marker.
- WASD/arrows cancel a route. Blocked ground gives a red invalid marker.
- Click employee: approach a valid cell, then Chat. The rail remains a shortcut.
- Founder desk/J: Journey and End Day. Archive: Studio. Console: Activity.
  Employee desks: Assign or Activity while work is open.
- Escape closes the reader/connection/drawer before opening pause. Settings
  contains sound controls, fullscreen, AI connection, Journey and title screen.
  The rail's Settings button opens this same menu; before AI is connected, it
  remains a direct Connect shortcut.
- The logical JSON supplies validated floor regions; blocked cells generate
  static wall collision. Props rebuild navigation. Both actor types use the
  shared grid; occupancy, reservations and mild separation prevent shared feet.
- Founder collision is a foot circle, matching the navigation footprint.
  Desk collision leaves the rear chair lane clear. Labels render above furniture
  with centralized overlap suppression; speech and prompts participate too.
- Existing sprites and notebook assets remain native/nearest-filtered. Original
  synthesized hover/click/step/drawer/reward/notification/ambient cues add no
  external asset licensing or production dependency.

## Persistence and protocol

Migration 006 adds company state, employment/hire day, milestone-linked jobs,
evaluation records/usage, idempotent financial transactions and day summaries.
Existing employee rows default to hired; only newly seeded rows are candidates.
Game-day AI spend includes jobs, chat and evaluator attempts, including failed
parse attempts that consumed tokens. Day summaries retain their own spend.

New methods: `hiring.complete`, `milestone.evaluate`, `milestone.complete`,
`milestone.override`, `day.end`, `game.save`, `game.new`. `milestone.complete`
is the explicit passing-review action (the plan described the button but omitted
that method from its interface list). JobSpec adds optional `milestoneId` and
`revisionOfJobId`; ordinary jobs are unchanged. Requests are schema-validated;
the Journey projection has its own JSON Schema.

Rewards and hires use SQLite transactions plus unique transaction keys. End Day
uses a persisted per-day summary as its replay key. Same-ID protocol retries
share one in-flight result; mismatched ID reuse is rejected. Terminal/recovered
jobs resolve abandoned approvals so they cannot permanently block End Day.

Player feet, movement onboarding hint, audio preferences and employee attention
are autosaved every five seconds, after company actions, and on window close
(acknowledgment awaited for up to two seconds). Clock minutes are persisted as
they change. Abrupt termination can lose up to one autosave interval of player
position; it cannot duplicate rewards or hiring charges.

New Company validates a fresh database before checkpointing and moving the old
SQLite file and `company-project/` into a unique timestamped backup. Failed
replacement rolls back without deleting either company's files. Credentials
stay in the OS keychain. To recover manually, stop the game/worker and restore
both the backed-up SQLite file and `company-project/` together. Never restore
only one half of that pair into a live process.

`ArtifactMilestoneAdapter` is the current completion-evidence boundary. Future
service-backed adapters can change evidence acquisition without replacing the
employee UI, bounded work-order lifecycle, evaluator, or reward ledger.

## Verification and evidence

Run from repository root (capture commands require a renderer):

```sh
cd harness && npm test && npm run eval:offline
# Return to repository root before the Godot commands.
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_complete_game.gd
godot --headless --path game --script res://tests/test_ui_flow_regressions.gd
godot --fixed-fps 60 --path game --script res://tests/test_complete_game.gd
godot --fixed-fps 60 --path game --script res://tools/capture_visual_review.gd
godot --fixed-fps 30 --path game --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
godot --fixed-fps 30 --path game --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
godot --headless --path game --script res://tools/validate_polish_audit.gd
```

The complete-game test sends real mouse-motion/button and key events through a
fixed 1280×720 SubViewport's normal GUI/unhandled-input pipeline. This avoids
native macOS focus/Retina flakiness without calling button handlers directly.
Movement action state is mirrored through InputMap because SubViewport event
injection does not update the global Input singleton; GUI events dispatch once.
It checks routes, cancellation, wall rejection, UI click isolation, rapid rail
switches, pause, modal focus, Escape, all stations, two-employee reservations,
first hire, evaluation/override/completion actions, and window/fullscreen layout.
Legacy handler tests remain complementary unit coverage.

Worker coverage includes a full deterministic three-day journey, repeated rewards
and hiring, failed evaluator parsing/retry, revisions, reduced-reward override,
missing artifacts, old-save migration, queue/active closing behavior, recovered
approval release, player restore, real stdio New Company backup/replay, and
read-only handoff normalization. The existing crash lifecycle and eight offline
tool-evaluation fixtures also remain in the suite.

Evidence is regenerated under ignored `game/tests/output/`: 27 isolated existing
static captures, the two six-scenario motion movies with keyframes/manifests,
and `complete-game/` title, onboarding, settings, Journey review/revision/ready,
chapter completion, day summary, error, 1600×900 and fullscreen images.

Issues found and corrected by this pass:

| Evidence/check | Defect | Correction |
| --- | --- | --- |
| Station clicks | Archive/console required unavailable hires 3/4 | Archive unlocks with Mina; console with Theo |
| Archive approach | Founder stopped 3 px short at bottom wall | Replaced tall body collider with foot circle |
| Work-state movie | Mina typed beside her desk | Walkable chair lane and grid-aligned seat anchor |
| World labels | Desk front hid parts of name/status plaques | Separate high world-label layer + overlap suppression |
| UI movie | First button press read absent tween metadata | Guarded metadata lookup; one interrupted tween |
| Crash + End Day | Orphan approval could block day advance forever | Terminal/recovery approval resolution |
| Day accounting | Today's spend repeated previous game days | Persisted game-day cost attribution |
| Native input replay | Window focus/retina caused inconsistent tests | Real event replay in fixed logical SubViewport |
| Two-person schedule movie | A shared lunch destination could trap the second employee | Approach-aware seat choice, reservation-aware paths and stalled-route replanning |

Final local verification: 50/50 worker tests (with `GODOT_BINARY` set for the
real-worker startup test), 8/8 offline fixtures, project validation, legacy
gameplay/UI tests, real-input gameplay tests, and UI-flow regressions pass.
Both motion audits capture all six scenarios and their evidence validator passes
(world: 1,713 frames at 30 FPS; UI: 495 frames at 30 FPS). These automated checks
are provider-free; the separately authorized paid replays are documented above.

## Remaining validation boundary

The evaluator uses a separate no-tools/no-extension in-memory Pi session with
bounded input, <=750 output tokens and a 3,000-token acceptance cap. It reads
registered files through the existing guarded artifact path, compacts complete
documents, and explicitly marks any sampled sections. It does not review rendered
websites or executed code. Missing required artifacts fail closed.
Provider/parsing/budget errors retain work and permit retry without rewards.

Deterministic evaluator injection covers lifecycle, schema, costs and transactions;
the paid replays additionally exercised website → evaluate → revision, all three
milestones, approvals, cancellation, and restart. This bounded evidence does not
guarantee model judgment on every future artifact. Automated captures and sampled
motion checks likewise cannot prove zero visual defects on every display or
replace a new player's unscripted 30-minute playtest.
