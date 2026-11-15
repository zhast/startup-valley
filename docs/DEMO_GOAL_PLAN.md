# Startup Valley: playable demo goal

## Finish line

Deliver a coherent, original, 10–15 minute playable Godot demo inspired by
Stardew Valley's character-led presentation and Game Dev Tycoon's small-studio
growth. A new player can learn movement and interaction, meet Mina, make and
release a first project, and discover one meaningful next opportunity without
outside instructions. Verify that journey through the integrated Godot game,
and retain a reproducible, validated release export.

Website work and public hosting are deferred. A public URL is not a completion
requirement. Do not use computer-use tools, manual browser journeys or browser
UI automation for this goal; use engine-driven Godot tests and automated
worker/export checks. Native renders and frame captures produced by the Godot
test scripts are valid visual evidence.

This is a bounded demo, not an instruction to build an entire life simulator.
Do not claim completion from code or a screenshot alone. The integrated game
must pass the acceptance journey below. The owner activated this plan as a
goal on 2026-11-15; current progress is recorded in `DEMO_HANDOFF.md`.

## Starting point — verify, do not rebuild

The current work already provides:

- Godot 4.7.2/GDScript web export and a shared offline TypeScript/SQLite worker.
- A compact starter studio for new saves, a garden surround, and safe expansion
  into the original office. Existing saves retain their original layout.
- A closer Mina portrait, explicit product-designer role, short dialogue,
  one-click hiring and a four-milestone first-release flow.
- Current-goal action, precise cursors, hover highlights, automatic project team
  assignment, seated workers, repaired side-walk poses and seated eye pixels.
- An existing native in-game website preview and recorded chair/character
  composition rules. Preserve that completed feature; further website work is
  outside this goal.
- An original-art style profile, retained generation provenance and hash-bound
  runtime asset reviews.

Before starting, inspect `git status`, recent commits, `AGENTS.md`,
`docs/DECISIONS.md`, the latest integrated test report and the durable handoff.
Preserve completed fixes and unrelated work. Older browser reports may provide
historical context; they do not require new browser testing. Verify whether
recent local commits have reached `origin/main`; finish pending Git pushes
rather than creating another branch or PR.

## Work packages, in priority order

### 1. Complete a playable opening tutorial

Use the smallest number of contextual hints needed:

1. **Arrive:** show the cozy office immediately. One short hint teaches click or
   WASD movement; a nearby highlighted object teaches interaction.
2. **Meet Mina:** prominent portrait, name, role, at most two short lines, one
   clear invitation. No contracts, API setup or employee-management form.
3. **Make something:** Mina leads to a visual choice of an unlocked project.
   Start with useful defaults; optional pricing/marketing stays behind disclosure.
4. **See progress:** the characters visibly work/rest in appropriate positions;
   each day has a readable outcome and one obvious next action.
5. **Celebrate:** reveal the actual released product, review and earnings, then
   point to a specific next opportunity. Do not strand the player at “now what?”

Tutorial steps must resume correctly after reload and must not replay earned
rewards. Derive hints from saved game state where possible; put any new durable
state in the worker. Support closing hints and reopening the current objective.

### 2. Make the interface understandable at a glance

- One current objective with a short verb-led title, compact progress display and
  a direct action. No clipped sentences, duplicate “Next” panels or required
  instructions hidden only in tooltips.
- Use portraits, item/project illustrations and concise status feedback before
  explanatory paragraphs. Keep the world visible during dialogue.
- Audit every opening screen through Godot viewport tests at 1280×720,
  1440×900 and 1024×576. Inject touch events in a Godot viewport at 844×390;
  if the full desktop layout is unusable, provide an intentional touch layout
  or clear supported-orientation treatment, never tiny clipped UI. Record
  simulated coverage honestly; it is not proof of testing a physical device.
- Preserve focus, Escape/back, pointer precision and disabled/loading states.

### 3. Give the studio a reason to connect to its surroundings

Keep the compact office as home. Add one small, complete outdoor courtyard or
town-edge visit after the first release, with a safe return path, one character
and one meaningful project opportunity. Make it a short story beat tied to the
existing simulation, not a second economy or a decorative fake exit.

Audit the current offline unlock path first: no next teammate, project or room
upgrade may require completing an optional API-backed legacy work order. Bridge
or replace any such gate in the authoritative worker and migrate saves safely.
Do not add a large town, seasons, combat, farming, multiplayer or an open-ended
quest system to this demo.

### 4. Finish the visual and animation audit

- Check all four walk directions and all supported chair/desk facings, empty and
  occupied, including seat entry, idle, blink, work, exit and interrupted routes.
- Check Mina, Theo and Creative retain their own identities in portraits and in
  the world. Verify depth around desks, chair backs, coffee equipment and walls.
- Use the existing original style board and asset workflow. Generate a new image
  with OpenAI image models only where it materially improves a deficient asset.
  Retain prompts, generation source, transforms and current in-game evidence.
- Record reusable decisions in `docs/DECISIONS.md` and the relevant detailed
  contract. Add a targeted regression for each confirmed systemic visual defect.

### 5. Package the tested demo and a durable handoff

Keep the existing release-export pipeline reproducible. Run its automated
resource, asset, worker-bundle and export checks, including WASM/PCK presence,
resource paths and required loader/configuration settings. Refresh the playable
local build after verified major changes and expose its build identifier.
Retain an export ZIP, a short controls/demo summary, three current Godot-rendered
screenshots and a known-limitations note. No new website or public deployment
is needed, and an export check must not be described as a hosted-browser test.

Keep game saves local; do not introduce provider credentials, a mandatory
account or a gameplay server. Preserve the source and enough reproducible
commands for another agent or the owner to resume without reconstructing the
conversation. Public hosting can be a separately requested future task. Do not
submit to an external event or message anyone.

## Parallel work and checkpoints

The owner explicitly authorizes implementation, fixes, matching asset
generation, tests, direct commits and pushes to `main`, and local release
exports. The owner may not return during this work. Proceed with ordinary
reversible decisions without routine approval requests, record assumptions,
and continue independent work when one path is blocked. This does not authorize
computer use, website/public-hosting work, external messages or event submissions.
Authorization does not bypass platform access controls. If a required Git push
is unavailable, retain local commits, finish all independent work and record the
exact failed action and recovery command in the handoff.

Use the available sub-agent capacity with explicit, nonoverlapping ownership:

- **Gameplay/tutorial:** worker progression, opening hints and post-release beat.
- **World/art:** courtyard/office composition, animation and asset contracts.
- **QA/integration:** integrated Godot journeys, save regressions and automated
  worker/export checks; no computer-use or browser UI automation.
- **Root:** integration, conflict resolution, review, tested commits, Git pushes
  and the durable handoff.

Reuse existing agents where useful. Do not have multiple agents edit the same
central file without a handoff. Save each meaningful passing increment directly
to `main` and push the checkpoint promptly; PRs are optional. Do not hold all
progress for one final commit. Refresh the playable build at each major
checkpoint. Update `docs/DEMO_HANDOFF.md` after the opening, world beat and final
acceptance, and before any interruption. Include:

- Current local commit, last confirmed pushed commit and build identifier.
- Completed changes, exact validation commands/results and evidence paths.
- Open defects, remaining work, assumptions and the next concrete command.
- Any source/build mismatch, blocked action or unpushed work, clearly labeled.

The handoff must let another agent continue without the owner answering a
question. Do not replace finished work merely to match a new plan.

## Required acceptance evidence

1. Run the repository's relevant tooling, schema, offline harness and Godot
   tests. Include the asset release gate, seating composition, portrait,
   navigation, tutorial and migration tests. Run the offline evaluation suite.
2. Complete the entire demo three times from clean saves using engine-driven
   input in the actual Godot scenes and production worker integration. Exercise
   the same UI actions as a player; do not seed completed milestones, grant
   rewards directly or bypass gameplay to claim a pass. Test helpers may launch,
   resize, send input, capture frames and observe state, without replacing the
   production simulation. Establish bounded waits and fail on runtime errors.
3. Restart the integrated game after arrival, hiring, project start,
   mid-development, release and outdoor return. Confirm exact progress,
   location and inventory restoration, no duplicate reward and no stuck
   character or modal. Use disposable test save directories.
4. Load an older full-office save, perform a compact-to-expanded transition,
   and verify furniture preservation, safe character positions and stale-edit
   rejection. Test interrupted worker recovery and competing/stale writes
   through the automated harness. Validate shared worker behavior and export
   configuration without claiming browser-tab or hosted-origin coverage.
5. Run Godot viewport/input tests at the sizes above with keyboard, pointer and
   injected touch events. Verify focus, Escape/back, clear loading/disabled
   states and that every required action is visible and reachable. Record the
   engine version, renderer and actual input coverage; do not claim unavailable
   browser engines or physical devices were tested.
6. Inspect native-size screenshots and short frame sequences produced by Godot
   scripts for every changed visual state. Reject clipped text, wrong identities,
   missing chair parts, sliding legs, flashing face pixels and sidebar
   paint-through. Retain current captures with their tested commit/build.
7. Export a release build with the normal asset gate enabled. Run automated
   export validation and worker-bundle checks, retain the ZIP and verify its
   expected files. Report the distinction between integrated Godot gameplay
   proof and static/export validation. Public-host, browser-origin persistence
   and cross-browser acceptance are deferred with public publishing.
8. Write `docs/web/demo-acceptance.md` with commit/build IDs, exact commands,
   Godot/worker versions, viewports, journey results, screenshots and real
   remaining limitations. Update `docs/DEMO_HANDOFF.md` with final local/pushed
   commit IDs, artifact locations and any remaining follow-up.

Completion requires all core journey, save-integrity, visual and release-export
checks above to pass with no unresolved blocker. Fix observed failures and
rerun affected checks; do not repeatedly run unrelated passing suites. Do not
pause for a public host, a manual browser session or the owner's return. If an
external prerequisite prevents a required push or check, finish independent
work, preserve tested local commits/artifacts and document the precise blocker
without calling the blocked check complete. A stable public URL may be added
in a separately requested publishing phase; it is not this goal's finish line.

## Ready-to-paste goal

```text
/goal Deliver the playable Startup Valley demo defined in docs/DEMO_GOAL_PLAN.md, verified through the integrated Godot game and packaged as a validated release export. Read the current repository state, AGENTS.md, docs/DECISIONS.md and docs/DEMO_HANDOFF.md if present; preserve completed fixes and resume from the latest verified checkpoint. Build a clear, visual opening tutorial through Mina, the first project and release, plus one meaningful next opportunity outside the office. Keep the original Stardew-inspired art direction and Game Dev Tycoon-style progression, with no mandatory APIs or accounts. Use parallel sub-agents with separate file ownership. I explicitly authorize implementation, matching asset generation, tests, frequent tested direct commits and pushes to main, and local release exports. I may not return during the work: do not wait for routine approvals; make reasonable reversible decisions and record assumptions. Do not use computer-use tools, manual browser journeys or browser UI automation. Ignore website work and public hosting for this goal; no public URL is required. Thoroughly test the actual Godot scenes with engine-driven player input and the production worker, including the complete clean-save journey, animation/layering, save/restart/migration, supported viewport sizes and injected touch input. Run automated worker, offline evaluation, asset-gate and release-export checks; do not bypass gameplay or claim browser/hosted coverage from native tests. Refresh the playable build after tested major changes, push checkpoints promptly, and keep docs/DEMO_HANDOFF.md current with commit/push/build IDs, commands, evidence, remaining defects and the next concrete step. Finish only when the bounded demo journey and required integrity/visual/export checks pass, with an acceptance report, export ZIP, controls summary and current screenshots. Fix failures and continue independent work; if an external prerequisite genuinely blocks a required push or check, retain verified local commits/artifacts and document the exact failed action and recovery steps without claiming it passed. Do not submit the demo to an event or send messages on my behalf.
```

The owner has activated this plan through the goal prompt. Editing this file
alone does not activate another goal. Completion is outcome-based rather than
a promise to finish at a particular hour.
