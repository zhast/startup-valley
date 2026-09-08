# Durable furnishing implementation

Completed and accepted: September 8, 2026. Implementation, restart/recovery,
regressions and scoped visual acceptance are complete. The implementation goal
was kept local; a subsequent explicit user request authorizes commits and push.

Publication includes selected PNGs, manifests and logs through
`dev/tools/publish_art_evidence.mjs`. Raw AVI movies, transport JSONL, disposable
databases and caches remain local and untracked. Movie links below therefore
refer to local recordings; their retained probe reports contain frame counts
and hashes. Reproduction commands can recreate recordings on another checkout.

## Scope and baseline

Implement worker-owned durable furnishing and the accepted Mina/Theo role kits,
plus three to five accepted starter decoration families. Preserve the existing
three-day chapter, approved art, native four-way geometry and worker boundaries.
The worktree began clean on `main`, tracking `origin/main`. No commits or pushes
were made during the implementation goal. No paid provider jobs or personal
saves were used.

The preceding art objective is complete. Its 42-family catalogue was a reusable
library, not already a playable inventory. Before this pass, Renovate committed
only to a local override map and bootstrap reapplied legacy desk coordinates.
This pass replaces that path with authoritative durable restoration. Undo's
history remains visit-local; its resulting layout now commits to SQLite.

## Checkpoints

1. **Implemented and tested:** inventory/layout contracts, worker transactions, migration,
   last-valid recovery, idempotency, and focused provider-free persistence tests.
2. **Implemented and tested:** accepted role/decor registration, storage-aware placement,
   shared geometry and safe hire growth.
3. **Implemented and tested:** worker-confirmed Renovate UI, preview/ownership/feedback and Undo.
4. **Verified and reviewed:** actual JSONL chapter/restart and fault coverage; real-input UI,
   native/scaled screenshots and motion review.
5. **Accepted:** full existing worker/Godot/catalogue/static/motion regression,
   requirement-by-requirement final acceptance and concise handoff.

## Working decisions

- SQLite owns inventory and committed layout; Godot owns temporary previews.
- Starter decorations have one free copy each; no new economic system.
- Mina/Theo kits follow their existing hires exactly once, including migration.
- Required stations cannot be stored. A failed mutation retains committed art
  and inventory; save success is shown only after acknowledgement.
- Authored pixel art is reused, never runtime-rotated or scaled to fake a view.
- Verification uses disposable companies and distinguishes deterministic worker
  execution from paid provider results. No claims of human playtesting.
- Selected starter families: `broadleaf_planter`, `task_floor_lamp`, and
  `rolling_storage_pedestal`, initially stored. The kits are
  `mina_discovery_kit` and `theo_campaign_kit`. All five use exact accepted source
  PNG copies; the installer verifies 84 native files without modifying pixels.
- Committed state is `{version, revision, inventory, placements, recovery}`.
  An owned optional item's absence from the placement map means storage.
  `furnishing.update` carries an operation ID, expected revision, full placement
  map and live actor cells. Retry freezes the complete payload. Bootstrap
  reconciles an uncertain save rather than fabricating a successful response.
- Renovate keeps its normal world entry and now includes native-size previews,
  owned/stored counts, Store, Cancel and explicit Retry. World input and all
  mutation controls are blocked during save acknowledgement. Future office
  stages are checked before showing a valid preview.

## Player-facing behavior

Open **Settings → Renovate office**. Choose an owned furnishing from the picker
or click its visible artwork. Use Move/Place (M), Rotate (R), the facing picker,
and a world click to place. Arrow keys move a preview by one cell and Enter
confirms. Store returns optional decorations to storage; essential stations
stay available. Escape cancels the preview, then closes Renovate. Undo (U or
Ctrl/Cmd+Z) reverses this visit's last acknowledged edit and saves that inverse.

The native-size preview includes the actual layers used in the room. Ownership
metadata distinguishes one stored copy from one placed copy. Green/red preview
art is paired with readable validity/error text. Pending edits disable controls
and cannot be closed or double-submitted. Success appears only after the worker
acknowledges. A failed save restores the committed room and offers Retry; a
disconnect reconciles through bootstrap. If someone has moved since a failed
attempt, Retry asks for a fresh placement instead of replaying old actor state.

Mina's product/research overlays and Theo's campaign overlays automatically
follow their existing hires, including already-hired employees in old saves.
The role kit is part of its employee's workstation, not a second inventory item
or interchangeable profession. The three free decorations begin in storage.
No furniture purchase, new specialist, price, charge or reputation gate was added.

## Authority, migration and failure semantics

- [Migration 007](../harness/migrations/007_furnishing.sql) adds inventory, a
  versioned layout/last-valid snapshot, revision and operation receipts.
- [FurnishingStore](../harness/src/furnishing.ts) grants stable inventory IDs
  exactly once. Hire grants participate in the existing hiring transaction, so
  an error rolls back both the hire charge and new stations/tools.
- [The schema](../contracts/furnishing.schema.json) validates bootstrap state
  and `furnishing.update`. The update contains `operationId`, `expectedRevision`,
  the complete placement map, and live actor cells with optional exact positions.
  Clients cannot grant inventory or submit custom footprints/unknown fields.
- Layout, last-valid snapshot, revision, operation receipt, employee desk cells,
  and the founder's exact current position commit atomically. Other saved player
  fields survive. There is no separate best-effort position save between edits.
- Retrying an operation requires the same fingerprint and returns the latest
  authoritative state. A stale new operation cannot overwrite a newer revision.
  An interrupted transaction commits all its state or none of it.
- Existing valid employee desk locations are migrated together before fallback,
  including swapped Mina/Theo desks. The worker does not erase old jobs, company
  finances, progression, artifacts or player state. Invalid/incompatible layout
  data falls back to the last valid layout, or safe authored stations with decor
  stored, and returns an understandable recovery message.
- Future required stations reserve their authored space during placement. Hire
  growth therefore adds stations without evicting player decorations. These
  reservations are not invisible actor collision in today's room.
- New Company uses the existing recoverable timestamped database/project backup
  and starts with fresh founder ownership plus three stored decorations.

[OfficeLayout](../game/world/office_layout.gd) and the worker read the same
authored JSON profiles. They validate native visual bounds as well as occupied
cells, clearances, architecture, seats, service access and connected routes.
Godot additionally rejects sub-cell actor-foot collisions. The room is rebuilt
and navigation recalculated only after a full snapshot validates; invalid
snapshots retain previous art, collision, inventory and revision. Legacy desk
coordinates cannot overwrite a bound furnishing layout.

## Bugs caught and corrected during implementation

1. The first preview panel covered the coffee station's real click target.
   It was moved to the upper-right and hides during placement. The unchanged
   original click assertion passes.
2. Sequential migration could reject an otherwise valid pair of swapped desks.
   The migration now validates all saved employee locations jointly first.
3. Saving a layout without the exact founder position could put furniture over
   the founder's stale autosave cell on restart. Position now shares the same
   SQLite transaction, including crash rollback and exact fractional positions.
4. Future station reservations incorrectly rejected a founder standing in space
   that is still empty today. Structural reservations and live actor reachability
   are now distinct checks.
5. JSON float coordinates did not compare equal to integer preview dictionaries,
   so a committed lost acknowledgement could appear unsaved. Semantic grid/facing
   equality now reconciles it once and creates exactly one Undo entry.
6. An old operation receipt returning a newer layout could invent an Undo step.
   Correlation now requires matching placements, not just an operation ID.
7. Escape canceled placement but left “Valid position — click to place” visible.
   Cancel now explicitly says that the saved room is unchanged.
8. Leaving a failed edit, moving the founder, and retrying later could replay the
   old exact position. Retry now rejects changed actor snapshots and asks for a
   new edit; an unchanged retry preserves its original immutable payload.

Verification defects were also corrected, without disguising them as game
fixes: native popup tests must use `Input.parse_input_event` (not viewport-only
dispatch that bypasses global held-button state), and a pending screenshot must
wait a process frame before forcing the draw. It also asserts that saving is
still pending after capture. External native pointer events could interfere
with simulated press/release sequences; native capture windows now become
unfocusable and mouse-passthrough in their deferred run, after engine window
initialization. GUI events use normal hit-testing, correct button masks and
explicit release events, with no action retries or handler shortcuts. Native
window-flag assertions are correctly conditional in headless tests; production
interaction assertions still run in both modes. Older evidence is retained,
not overwritten.

## Evidence and verification scope

The final checkpoint below supersedes the earlier implementation runs. The
first headless archive test correctly exposed an outdated South-only whitelist;
its exact new-three-decor allowlist was updated. Original geometry, art and
interaction assertions were retained, not relaxed.

The first whole-product renderer checkpoint
`art-completion-furnishing-20260908-final` is retained as **failed**, not accepted:
three viewport-only simulated clicks did not activate the rail/draft actions.
All 27 stills and 24 world-motion PNGs matched the approved baseline, but five
UI-motion PNGs visibly missed their intended state. The motion harness now
isolates native input and maintains global Input state with real press/release
events. It retains all frame waits and original dispatch assertions.

The replacement `art-completion-furnishing-20260908-final2` headless run also
passes all 33 invocations, but its renderer remains **failed**: an intermittent
native click on delivery Preview did not dispatch, cascading into reader checks.
Native pointer/held-button tracing exposed the external input interference
described above. Two consecutive isolated UI captures subsequently passed all
159 checks each and decoded to 1,128 frames at the original timing. These are
`polish-ui-pointer-isolated-20260908-4` and `-5` under `game/tests/output`.

The final `art-completion-furnishing-20260908-final3` renderer passes its first
six gates: 27 static captures, world and UI movies, both movie probes, and motion
validation. Its full result remains **failed** because the window-review phase
originally injected a GUI cursor while production world hover polls the actual
OS cursor. It is not relabeled green. The accepted replacement window run is
`furnishing-window-poll-20260908-check2`, with 451 checks and zero failures.

This is an explicit composite acceptance: the six successful `final3` gates
plus the successful standalone window gate, against unchanged production
hashes. All 108 corresponding PNGs are byte-identical to the approved
`art-completion-20260906-final-fit` baseline: 27 static, 24 world-motion,
39 UI-motion and 18 window images. No changed visual baseline was accepted.

The window-only world-hover probe briefly positions the physical cursor at
each of three window sizes, waits for production hover polling, then restores
the previous cursor position and verifies restoration. It waits for physical
buttons to be released and never sends physical clicks. All other GUI input
remains isolated and injected. This exception is disclosed in the manifest;
it is necessary because root viewport mouse polling reads DisplayServer state
([Godot viewport implementation](https://raw.githubusercontent.com/godotengine/godot/master/scene/main/viewport.cpp)).
The first restoration check was too early for asynchronous OS motion; that
failed `check1` evidence is retained and superseded by `check2`, which waits two
frames before verifying restoration.

The tracked collaboration headless result changes exactly four post-cancel
status strings to “Placement canceled. Your saved room is unchanged.” This is
the intentional cancellation-copy fix above, explicitly reviewed; it is not an
unexplained golden-image replacement.

The two older Renovate-using art tests now use an explicitly named synchronous
transport double. Their original geometry/interaction assertions remain; they
do **not** prove persistence. The new worker/Godot integration test uses real
stdio, SQLite, disposable data and delayed/lost real acknowledgements instead.

### Acceptance matrix

| Required outcome | Implementation and evidence |
| --- | --- |
| Worker-owned versioned inventory/layout | Furnishing schema, migration 007, bootstrap, `furnishing.update`, real SQLite tests in `harness/test/furnishing.test.ts` and `furnishing-protocol.test.ts`. |
| Duplicates, stale updates, interrupted requests | Stable grants, expected revisions, immutable operation fingerprint/receipts; concurrent and duplicate JSONL tests; SIGKILL inside an open layout/position transaction followed by retry. |
| Existing saves and last-valid recovery | Version-six migration preserves old company state and valid desk swaps; malformed/version-incompatible layout tests verify safe recovery and explanation. |
| New Company backup/reset | Actual protocol test verifies the old database/project backup and fresh furnishing inventory using disposable data only. |
| Three decorations, Mina/Theo kits, no new economy | Exact 84-file promotion; three initially stored copies; hire and migration tests prove one role grant per employee and no duplicate charge. |
| Four-way geometry and safe growth | 1,068 cross-language candidates agree; projection tests check native layer/pivot/depth and all directions, storage, old-layout retention, seated-actor rejection and legacy-coordinate immunity. |
| Real UI through durable restart | Four actual Godot/worker launches exercise mouse/keyboard selection, four-facing placement, storage, Undo, desk movement, duplicate clicks, blocked UI/world input and one lost committed reply; SQLite is independently read and matches the restored room. |
| Readable pending/saved/failed/canceled feedback | Native/scaled captures, pending-controls assertions and `test_furnishing_feedback.gd` cover response correlation, stale state, failed save, immutable retry, moved actors and disconnected previews. |
| Work/schedules and role layering | New 30-FPS role lifecycle movie and native stills exercise both employees, all four facings, approach/think/type/research/approval/delivery/failure/lunch/return through production actor paths. |
| Existing chapter and worker recovery | The furnished three-day journey fixture completes milestones then boots actual JSONL, ends a day and restarts without reward duplication; adapter tests cover queue/start/approval/shutdown, and evaluator/revision/failure/override preserve furnishings. |
| Existing gameplay/UI/art unaffected | Consolidated headless and renderer regression results, worker suite, offline evaluator and catalogue freshness checks below. |

All rows are accepted within the stated verification scope. There are no
unresolved blocking implementation or visual defects in the inspected evidence.

### Final checkpoint

- Current worker suite: 62 passed, zero failed, zero skipped when `GODOT_BINARY`
  is provided. Both real Godot/worker integration tests run, not skip.
- Offline evaluator: 8/8 provider-free fixtures passed.
- Focused projection: 162 checks. Feedback correlation/retry: 24 checks.
- [Consolidated headless results](../game/tests/output/art-completion-furnishing-20260908-final2/headless-results.json):
  33 clean invocations, zero Godot errors, unchanged production hashes. This
  includes import, project validation and 31 named gameplay/layout/art/UI entry
  points; `run_all.gd` alone is not described as the whole test suite.
- [Current geometry parity](../game/tests/output/art-completion-furnishing-20260908-final/furnishing-parity/godot-results.json):
  1,068 candidates, zero disagreements (317 accepted / 751 rejected).
- [Real native worker/UI acceptance](../game/tests/output/furnishing-worker-ui-2026-09-08T19-40-37-904Z-izIYHV/acceptance.json):
  229 Godot checks, eight durable mutations, four fresh game launches and one
  automatic worker recovery. All spawned processes exited. All 28 state PNGs
  are byte-identical to the previously inspected native set; the 437-frame
  30-FPS AVI (14.567 seconds) was reviewed through sampled motion contacts,
  not watched frame-by-frame. Native 1280×720, integer 2560×1440 and 1600×1000
  letterbox include real pointer/keyboard checks. All 194 source hashes match
  before, after and at final review. The letterbox
  PNG is the 1600×900 content texture; its 50px outer bars are recorded in the
  manifest, not falsely presented as visible in that PNG.
- [Static and motion regression gates](../game/tests/output/art-completion-furnishing-20260908-final3/render-results.json):
  accept only the first six successful entries, not the failed final window
  entry. The world movie decodes to 2,322 frames and the UI movie to 1,128 frames,
  each at 30 FPS with six scenarios. All 90 static/motion PNGs match the approved
  baseline. All 552 production hashes remain current.
- [Replacement scaled-window gate](../game/tests/output/furnishing-window-poll-20260908-check2/runtime-window-review/manifest.json):
  451 checks, zero failures, three supported sizes and 18 baseline-identical
  PNGs. Real polled station cursor is `(128,400)` in every case; return to the
  original physical cursor position is asserted. The complete composite
  regression therefore has 108 unchanged comparison images.
- [Furnished role lifecycle recording](../game/tests/output/furnishing-runtime-motion-20260908-check1/verification.json):
  25,709 fixture checks, eight directional employee lifecycles, 73 native stills;
  437 independent verification checks. ffprobe decodes exactly 6,359 frames at
  30 FPS (211.967 seconds), with 98 unchanged source/art hashes. Use the decoded
  count, not Godot's lower console counter when forced draws are included.
- [Mature Renovate review](../game/tests/output/furnishing-mature-ui-20260908-check1/mature-ui-manifest.json):
  28 checks and three source-bound native captures. The 11-item dropdown and
  Mina kit preview fit at 1280×720. This worker-disabled fixture proves visual
  layout only, not durable ownership or saving.
- Current catalogue: 42 families / 168 views; 56 integrated and 112 still passive.
  Validator: 32,525 checks + 111 self-tests. Markdown gallery current; HTML
  freshness + 56 self-tests pass. Installer verifies 84 exact native copies;
  promotion verifier confirms exactly five families / 20 newly integrated views.
- Final independent review confirms current source/evidence hashes, the 108
  unchanged regression images, restored world hover, and no blocking new defect
  in inspected furnishing UI, role-layering and scaled-window samples.
- Pre-push checks repeat the worker suite (62/62, no skips), offline evaluator
  (8/8) and [all 33 headless invocations](../game/tests/output/art-completion-furnishing-push-20260908/headless-results.json).

### Visual handoff

- [Renovate controls and preview](../game/tests/output/furnishing-worker-ui-2026-09-08T19-40-37-904Z-izIYHV/edit-open.png)
- [Pending confirmation](../game/tests/output/furnishing-worker-ui-2026-09-08T19-40-37-904Z-izIYHV/edit-pending-confirmation.png)
- [Mature inventory picker](../game/tests/output/furnishing-mature-ui-20260908-check1/mature-renovate-dropdown.png)
- [Native role-lifecycle contact sheet](../game/tests/output/furnishing-runtime-motion-20260908-check1/role-lifecycle-contact-native.png)
- [Recorded real-worker furnishing flow — local movie](../game/tests/output/furnishing-worker-ui-2026-09-08T19-40-37-904Z-izIYHV/edit.avi)
- [All-facing role lifecycle — local movie](../game/tests/output/furnishing-runtime-motion-20260908-check1/world.avi)

### Reproduce

Run from the repository root with `godot` pointing to the installed Godot binary.
On this machine it is `/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot`.
No paid provider command is part of this sequence.

```sh
cd harness
npm run build
GODOT_BINARY=/path/to/godot npm test
npm run eval:offline
cd ..
node dev/tools/install_furnishing_library.mjs
node dev/tools/promote_furnishing_catalogue.mjs
node dev/tools/validate_art_catalogue.mjs --self-test --check-gallery
node dev/tools/build_art_catalogue_html.mjs --self-test --check
node harness/test/fixtures/furnishing-parity.mjs game/tests/output/furnishing-parity/cases.json
godot --headless --path game --script res://tests/test_furnishing_parity.gd
godot --headless --path game --script res://tests/test_furnishing_projection.gd
godot --headless --path game --script res://tests/test_furnishing_feedback.gd
node dev/tools/run_art_completion_regression.mjs art-completion-furnishing-local-check1 headless
node dev/tools/run_art_completion_regression.mjs art-completion-furnishing-local-check1 render
cd harness
GODOT_BINARY=/path/to/godot STARTUP_VALLEY_FURNISHING_RENDER=1 STARTUP_VALLEY_FURNISHING_MOVIE=1 ./node_modules/.bin/tsx --test test/furnishing-game.test.ts
```

Choose an unused checkpoint name when rerunning; the baseline runner refuses
to overwrite manifests and records production hashes before/after. Serialize native renderer commands. New role
movie commands and their exact retained manifests are in the
[runtime art review](art-catalogue/FURNISHING_RUNTIME_REVIEW_20260908.md).

## Explicit limits and later work

- This is a deterministic developer playtest, not an uncoached human playtest
  or a fresh paid provider run. The real-input furnishing flow uses actual
  production stdio/SQLite; the all-facing actor movie uses simulated events.
- Controlled native, integer 2× and letterboxed sizes are tested. This is not
  certification of actual OS fullscreen, all Retina displays, or interactive
  frame-time performance. Fixed-FPS movies are visual evidence, not benchmarks.
- Undo history ends with the Renovate visit. Its changes save durably, but there
  is no permanent undo ledger or inventory purchase system.
- Only three decor families and the two existing employee kits are activated.
  Other art remains a library; no specialists, office themes, broad UI redesign,
  generated assets or external Whop services were added.
- Layout corruption recovery does not promise arbitrary repair of manually
  tampered inventory/database rows. Existing backups remain the recovery path
  for unsupported database edits.
- No distributable export, CI service, dependency upgrade or personal-save
  migration was performed. Publication is limited to the later user-authorized
  commit/push follow-up; the implementation goal itself did not publish changes.
