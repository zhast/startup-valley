# Startup Valley repository audit

Audited November 15, 2026 against [`zhast/startup-valley`](https://github.com/zhast/startup-valley/tree/c4d1829df5ce2924ef68964bf16b7c1c369e0e46), commit `c4d1829df5ce2924ef68964bf16b7c1c369e0e46` (verified from the local clone). This document belongs to the web-port scaffold; it does not replace the repository's instructions or architecture documentation.

**The existing game has not yet been ported to a playable browser runtime.** Its Godot presentation is reusable, but a static export alone cannot run its authoritative Node/SQLite simulation.

## Confirmed architecture

| Area | Repository evidence | Consequence for the web port |
| --- | --- | --- |
| Engine | Godot **4.7.2**, standard build; typed GDScript. [Version policy](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/docs/UPGRADING.md#L3-L16) | Pin 4.7.2 and matching export templates; do not bundle an engine upgrade into the port. |
| Entry and renderer | `game/project.godot` launches `res://world/main.tscn`, uses Compatibility, and defines a 1280×720 viewport with `canvas_items` stretching. [Project settings](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/project.godot#L6-L27) | Retain the current scene, dimensions, and art behavior for the first browser comparison. |
| Runtime boundary | Godot renders read-only projections; Node/TypeScript and SQLite own simulation and persistence. [Architecture](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/docs/GAME_ARCHITECTURE.md#L5-L17) | Preserve one authoritative implementation of the rules. Do not rewrite them in GDScript. |
| Native transport | `WorkerClient.start()` locates `../harness/dist/main.js` and launches Node with `OS.execute_with_pipe`. [Worker startup](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/worker_client.gd#L58-L83) | A browser transport and compatible persistence adapter are required; this is the primary blocker. |
| Offline core | Products, reviews, and sales are deterministic worker operations; providers are optional chapter features. [Tycoon boundary](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/docs/GAME_ARCHITECTURE.md#L31-L39) | Keep ordinary play provider-free. Do not make an API key or remote service a prerequisite. |
| Project rules | The repository requires the worker boundary and prohibits an unauthenticated HTTP listener. [Agent instructions](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/AGENTS.md) | Define an explicit web adaptation rather than exposing the native worker casually over HTTP. |

No existing `export_presets.cfg`, C# source, or `.gdextension` file was found in the audited tree. The dependency guide also states that the Godot client has no native extensions or asset-store plugins. This reduces rendering-port work but does not remove the Node dependency.

## Assets and export inputs

The world uses a **32px logical grid**; layout validation enforces that size. Characters use **48×80 cells at scale 1**, with a shared **(24,72) foot anchor**. Preserve these conventions, current UIDs, and `.png.import`/other import-setting sidecars. Regenerate `.godot/` caches instead of copying them. [Layout validation](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/world/office_layout.gd#L142-L150) · [Character atlas conventions](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/assets/runtime/characters/README.md#L3-L20)

`OfficeLayout` reads raw JSON with `FileAccess`: `data/office_layout.json`, `data/furniture_catalog.json`, and `data/furnishing_catalog.json`. Include `data/*.json` explicitly in the Web export and verify the files in the resulting PCK; scene dependency traversal alone is insufficient evidence of inclusion. [Paths](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/world/office_layout.gd#L6-L8) · [JSON reader](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/world/office_layout.gd#L182-L184)

The largest font, `NotoSansCJKsc-Regular.otf`, is approximately 16.4MB and is explicitly preloaded with other language fallbacks. Retain it initially; any subsetting/removal needs text-coverage tests. [Font loading](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/ui/game_fonts.gd#L25-L35)

## Repository size and sparse checkout

The [Git tree](https://api.github.com/repos/zhast/startup-valley/git/trees/c4d1829df5ce2924ef68964bf16b7c1c369e0e46?recursive=1) contains **9,929 tracked files totaling 1,071,030,789 bytes**. These are uncompressed blob sizes, not measured download or web-build sizes.

| Tracked group | Bytes | Initial checkout policy |
| --- | ---: | --- |
| `game/tests/output/` | 787,021,831 | Omit generated visual evidence; retain its `.gdignore` when practical. |
| `game/assets/source/` | 158,043,636 | Omit source masters initially; retain its `.gdignore`. Restore for asset regeneration. |
| `game/assets/concepts/` | 68,690,072 | Omit except the required character sheet and sidecar below. |
| `game/assets/fonts/` | 26,442,525 | Keep. |
| `game/assets/runtime/` | 8,408,707 | Keep. |

Inspection of all non-test/tool GDScript, scenes, and four `game/data/` JSON files found no runtime references into the omitted source or test-output directories. The important exception within concepts is the direct preload in [`game/character_art.gd:4`](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/character_art.gd#L4). Keep both:

```text
game/assets/concepts/office-town-characters-sheet.png
game/assets/concepts/office-town-characters-sheet.png.import
```

These exclusions leave approximately **60MB of tracked file content**, before Git metadata. This is a runtime-focused sparse checkout, not deletion from the repository. Developer art tools and visual fixtures may require restoring omitted files. [Source-master policy](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/assets/source/README.md#L3-L6)

## Required next work

1. Preserve the existing JSON request/response contracts while designing the browser worker transport and adapting Node-only storage/runtime dependencies. Keep the native stdio implementation working.
2. Keep optional provider/keychain features outside the initial browser gameplay slice. Do not import native credential modules into a browser bundle.
3. Add the Web export preset and exact asset filters, then verify the real scene with the matching Godot editor.
4. Verify save acknowledgments, reopen behavior, and background-tab handling. The current client requests saves every five seconds after state loads; it does not itself own the database. [Autosave call](https://github.com/zhast/startup-valley/blob/c4d1829df5ce2924ef68964bf16b7c1c369e0e46/game/world/main.gd#L125-L128)
5. Run existing native/offline tests and a representative browser gameplay loop before calling the port complete. Loading-screen and HTTP tests validate only the surrounding scaffold.

This audit made no source changes to the cloned repository and ran no provider calls.
