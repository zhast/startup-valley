# Startup Valley: public demo goal

## Finish line

Deliver a coherent, original, 10–15 minute browser demo inspired by Stardew
Valley's character-led presentation and Game Dev Tycoon's small-studio growth.
A new player can learn movement and interaction, meet Mina, make and release a
first project, and discover one meaningful next opportunity without outside
instructions. Publish a stable public HTTPS URL that a demo reviewer can open
without an account, API key, installation or developer tools.

This is a bounded demo, not an instruction to build an entire life simulator.
Do not claim completion from code or a local screenshot alone. The final hosted
build must pass the acceptance journey below.

## Starting point — verify, do not rebuild

The current work already provides:

- Godot 4.7.2/GDScript web export and a shared offline TypeScript/SQLite worker.
- A compact starter studio for new saves, a garden surround, and safe expansion
  into the original office. Existing saves retain their original layout.
- A closer Mina portrait, explicit product-designer role, short dialogue,
  one-click hiring and a four-milestone first-release flow.
- Current-goal action, precise cursors, hover highlights, automatic project team
  assignment, seated workers, repaired side-walk poses and seated eye pixels.
- Native in-game website preview and recorded chair/character composition rules.
- An original-art style profile, retained generation provenance and hash-bound
  runtime asset reviews.

Before starting, inspect `git status`, recent commits, `AGENTS.md`,
`docs/DECISIONS.md`, and the latest browser report. Preserve completed fixes and
unrelated work. Verify whether recent local commits have reached `origin/main`;
finish any pending publication rather than creating another branch or PR.

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
- Audit every opening screen at 1280×720, 1440×900 and 1024×576. Check landscape
  touch at 844×390; if the full desktop layout is unusable, provide an intentional
  touch layout or clear supported-orientation treatment, never tiny clipped UI.
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

### 5. Publish and package the demo

Use the available supported hosting path, with Sites static hosting or GitHub
Pages as candidates after checking current capabilities. Keep publishing
reproducible in the repo. Large WASM/PCK assets, MIME types, content encoding,
worker URLs and any required headers must work on the actual host.

Publish the game, not only a landing page. The canonical URL must remain stable
across updates and work anonymously in a fresh browser. Keep game saves local;
do not introduce provider credentials, a mandatory account or a gameplay server.
Expose a build identifier. Retain an export ZIP, a short controls/demo summary,
three current screenshots and a known-limitations note for submission. Do not
submit to an external event or message anyone unless separately instructed.

## Parallel work and checkpoints

The owner explicitly authorizes implementation, fixes, matching asset
generation, tests, direct commits and pushes to `main`, and publication of a
public playable demo. Proceed with ordinary reversible decisions without asking
for approval. Do not send messages or submit an event application. If a platform
enforces a user-only step, seek a supported alternative before reporting the
specific remaining prerequisite; this authorization does not bypass platform
access controls.

Use the available sub-agent capacity with explicit, nonoverlapping ownership:

- **Gameplay/tutorial:** worker progression, opening hints and post-release beat.
- **World/art:** courtyard/office composition, animation and asset contracts.
- **QA/deployment:** browser journeys, save regressions and public-host checks.
- **Root:** integration, conflict resolution, review, small commits and publishing.

Reuse existing agents where useful. Do not have multiple agents edit the same
central file without a handoff. Save each meaningful passing increment directly
to `main` and publish it; PRs are optional. Refresh the playable build at each
major checkpoint. Checkpoint in the report after opening, world beat and final
hosted acceptance. Do not replace finished work merely to match a new plan.

## Required acceptance evidence

1. Run the repository's relevant tooling, schema, offline harness and Godot
   tests. Include the asset release gate, seating composition, portrait,
   navigation, tutorial and migration tests. Run the offline evaluation suite.
2. Export a release build and complete the entire demo in the actual browser,
   three times from clean saves. Use normal UI controls for the player journey;
   do not seed completion or bypass gameplay to claim a pass.
3. Reload after arrival, hiring, project start, mid-development, release and
   outdoor return. Confirm exact progress, location and inventory restoration,
   no duplicate reward and no stuck character or modal.
4. Load an older full-office save, perform a compact-to-expanded transition, and
   verify furniture preservation, safe character positions and stale-edit
   rejection. Check tab ownership and recovery from a closed worker/tab.
5. Test on Chrome and another available browser engine. Report actual coverage;
   an unavailable browser is not a passing test. Cover the viewport sizes above,
   pointer/keyboard and landscape touch where supported.
6. Inspect native-size screenshots and short frame sequences for every changed
   visual state. Reject clipped text, wrong identities, missing chair parts,
   sliding legs, flashing face pixels and sidebar paint-through.
7. Repeat the complete opening-to-next-opportunity journey on the public URL in
   a fresh unauthenticated browser. Check network failures, missing assets,
   console/runtime errors, audio activation and persistence on that origin.
8. Write `docs/web/demo-acceptance.md` with commit/build IDs, public URL, commands,
   browser versions, viewports, journey results, screenshots and real remaining
   limitations. Separate native fixtures, local browser results and hosted proof.

Completion requires all core journey, save-integrity and public-playability
checks to pass with no unresolved blocker. Fix observed failures and rerun the
affected checks; do not repeatedly run unrelated passing suites. If a host or
credential constraint truly prevents publication, finish and retain the tested
export, identify the exact blocked action and report the smallest user action
needed. Never present a private or localhost URL as the public deliverable.

## Ready-to-paste goal

```text
/goal Deliver and publicly publish the playable Startup Valley demo defined in docs/DEMO_GOAL_PLAN.md. Read the current repository state, AGENTS.md and docs/DECISIONS.md first; preserve completed fixes and resume from the latest verified checkpoint. Build a clear, visual opening tutorial through Mina, the first project and release, plus one meaningful next opportunity outside the office. Keep the original Stardew-inspired art direction and Game Dev Tycoon-style progression, with no mandatory APIs or accounts. Use parallel sub-agents with separate file ownership. I explicitly authorize implementation, asset generation, tests, direct commits and pushes to main, and public demo deployment; do not pause for routine approvals. Refresh the playable build after tested major changes. Log design decisions and keep the asset review gates. Thoroughly test the real UI, animation/layering, save/reload/migration, supported viewport sizes and a second available browser engine. Finish only when the public HTTPS game works anonymously and the complete hosted demo journey passes, with an acceptance report, export ZIP and submission screenshots. Fix failures and continue; if an external prerequisite is genuinely blocking, retain all verified work and report the precise blocker and required action. Do not submit the demo to an event or send messages on my behalf.
```

This file prepares the next goal; creating the file does not activate goal mode.
The goal is outcome-based rather than a promise to finish at a particular hour.
