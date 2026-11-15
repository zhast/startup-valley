# Porting order and acceptance

Run the commands below from the repository root. Its AGENTS.md and architecture documents govern game changes. The web-delivery scripts are delivery groundwork; gameplay has not been ported.

## 1. Establish a native baseline

Use the pinned **Godot 4.7.2** and **Node 22.19+**. Build and test the harness using the repository's commands:

```sh
cd harness
npm ci
npm run build
npm test
npm run eval:offline
```

Then run the Godot import, validator, tests, and playable build listed in AGENTS.md. Some visual fixtures require restoring sparse-checkout exclusions. Do not run paid-provider checks or read credentials for the offline core.

The locked harness install, build, 134 passing tests (2 Godot-only skips), and 8/8 offline fixtures have now been verified. The matching Godot CLI is being prepared separately. See the [verification record](verification.md) for current results; native success does not establish browser compatibility.

## 2. Isolate platform adapters

Follow the [browser runtime plan](browser-runtime-plan.md). Preserve TypeScript stores, SQL migrations, protocol contracts, transactions, and request deduplication. Separate Node filesystem/process/SQLite construction from shared rules. Bundle authored JSON and schemas. Run native tests after each extraction.

## 3. Prove browser-worker persistence

Implement a dedicated Worker with SQLite WASM and explicit storage ownership. Run a representative offline command sequence with the existing rules and verify committed state after reload. Test denied storage, crashes, migrations, and second-tab contention. Storage failure must not silently discard the player's save.

## 4. Connect the Godot web client

Keep native stdio in WorkerClient. Add a web transport through JavaScriptBridge using the same envelopes. Preserve event handling and durable save acknowledgments. The current five-second autosave must reach the browser database. Optional provider/keychain features need explicit unavailable behavior initially.

## 5. Configure a real web export

Add a Web preset in the matching editor and install matching templates. `templates/export_presets.web.cfg` is reference material, not an active preset. Preserve existing platform presets. CLI exports use the preset's name. [Godot exporting guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)

| Setting | Initial value |
| --- | --- |
| Preset / platform | Web / Web |
| Renderer | Existing Compatibility configuration |
| Thread and extension support | Off |
| PWA | Off until update/recovery behavior is designed |
| Non-resource include filter | `data/*.json` |
| Release filename | `index.html` |
| Custom shell | Select the supplied `res://web/shell.html` |

Keep the referenced character concept PNG and its .import sidecar. Exclude source-art archives and generated captures. Verify the PCK contains JSON read through FileAccess.

After browser-runtime integration, from the repository root:

```sh
node scripts/doctor.mjs
node scripts/export-web.mjs
node scripts/validate-web.mjs
node scripts/serve.mjs
```

Exports stage under `.build/` and replace `dist/` only after structural checks. A killed export can leave `export.lock`; confirm no export is running before removing a stale lock. Printed recovery-backup paths must be preserved until restored. Structural checks do not establish functional browser compatibility.

## 6. Play and deploy

- Compare state after identical native/browser gameplay sequences.
- Check movement, collision, anchors, layering, camera motion, menus, text, and transitions.
- Test focus, audio gestures, resizing, and fullscreen.
- Save, reload, close, reopen, and confirm progress. Test storage denial and older saves.
- Hide the tab and verify intended pause/catch-up behavior.
- Test Chrome/Edge, Firefox, and Safari; add real mobile devices if targeted.
- Compare consecutive releases and verify both updated assets and retained saves.
- Record cold-load bytes/time, frame pacing, and memory on the weakest target.

Deploy the complete output to HTTPS static hosting with correct WASM/JS/PCK MIME types and real missing-file errors. Enable host-managed compression and atomic releases. The generated `_headers` convention is not universal: verify actual responses on the selected host. Keep a stable origin and database identity.

No remote deployment is part of this scaffold. Automated checks cover web-delivery tooling and shell lifecycle. Desktop/mobile shell checks passed, but the game's browser runtime, persistence, and gameplay still require implementation and testing.
