# Upgrading dependencies

Startup Valley is intentionally easy to update: the Godot client is pure typed GDScript with no C#, native extensions, asset-store plugins, or hand-edited packed tile data; the worker uses exact npm versions and a committed lockfile; and the stdio boundary is covered by JSON Schemas and integration tests.

## Current compatibility floor

| Layer | Current version | Source of truth | Expected risk |
| --- | --- | --- | --- |
| Godot | 4.7.2 | `game/project.godot`, README, acceptance docs | Low for patch releases; review GDScript/API changes for minor or major releases |
| Node.js | 22.19+ | `harness/package.json` `engines` | Low while `node:sqlite` and child-process behavior remain compatible |
| Pi packages | 0.84.4 | `harness/package.json` and lockfile | Medium; the adapter directly uses session, runtime, credential, and custom-tool APIs |
| Other npm packages | Exact versions | `harness/package.json` and lockfile | Usually low; schema/keychain changes still require the full suite |

## Update one layer at a time

Do not combine a Godot upgrade with a Pi or Node upgrade. A dependency-only commit should change the relevant manifest/lockfile and any required compatibility edits, then pass every gate below before application work resumes.

### npm or Pi

1. From `harness/`, inspect proposed versions with `npm outdated`.
2. Update only the intended package with `npm install --save-exact <package>@<version>` so `package.json` and `package-lock.json` stay synchronized.
3. Run `npm run check && npm test`.
4. Run the Godot import and validation commands below to catch protocol drift.
5. For a Pi update, run `npm run live:openrouter` with the game-saved key and verify events, tool calls, usage, cost, and artifact creation.

Review Pi upgrades especially around `ModelRuntime`, `createAgentSession`, `DefaultResourceLoader`, `SessionManager`, custom tool definitions, event names, usage statistics, and abort/dispose behavior.

### Godot

1. Open a clean branch with the proposed standard Godot build.
2. Let Godot import the project; inspect changes to `game/project.godot` rather than accepting unrelated generated files.
3. Run the project validator and deterministic test.
4. Launch the game and visually check the 1280×720 office, long dropdown labels, artifact overlay, walking, typing, cancellation, and crash recovery.
5. Run one live Mina → Theo flow before merging a minor or major engine upgrade.

### Node.js

1. Change the `engines.node` floor only when the project intentionally drops the previous runtime.
2. Recreate dependencies with `npm ci` on the candidate Node version.
3. Run the complete automated suite and a worker crash/restart spot check.

## Required gates

```sh
cd harness && npm ci && npm run check && npm test
cd ..
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

For provider-facing changes, also run:

```sh
cd harness && npm run live:openrouter
```

Never place credentials in test fixtures or CI variables merely to make routine dependency updates pass. Keep the live provider gate as an explicit credentialed check.
