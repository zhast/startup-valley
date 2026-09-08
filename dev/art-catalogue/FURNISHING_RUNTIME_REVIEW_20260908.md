# Furnishing runtime art review — September 8, 2026

Accepted for the bounded furnishing slice: three starter decorations and the
existing Mina/Theo desk kits. This promotes exact previously approved pixels,
not a new generation, employee role, service action, economy, or pose capability.

## Selection and layer rules

| Catalogue family | Player binding | Native canvas / floor pivot | Integration |
| --- | --- | --- | --- |
| `broadleaf_planter` | One starter item, initially stored | 128×224 / (64,176) | One floor cell; independent shadow/rear/front layers |
| `task_floor_lamp` | One starter item, initially stored | 128×256 / (64,208) | One floor cell; no fake powered/light interaction |
| `rolling_storage_pedestal` | One starter item, initially stored | 96×144 / (48,96) | One floor cell; six native layers; decorative, not artifact storage |
| `mina_discovery_kit` | Granted with existing `mira` hire | 192×224 / (96,160) | Rear/front overlays on Mina's existing desk only |
| `theo_campaign_kit` | Granted with existing `theo` hire | 192×224 / (96,160) | Rear/front overlays on Theo's existing desk only |

These compact pieces give the first office foliage, reading light, side storage,
and distinct product/growth desk identities without overwhelming the picker.
Every facing keeps its authored orientation, binary-alpha pixels, shared pivot,
scale one, unmirrored texture, and native depth. Role kits add no floor collision.
The planter canopy and tall lamp reserve their real artwork envelope as well as
their floor cell; neither can silently extend into walls or another prop.

`game/data/furnishing_catalog.json` is the canonical supplemental registration
read by both processes. Its `source_copies` lists 84 byte-identical accepted layer
and preview PNG copies. `dev/tools/install_furnishing_library.mjs` verifies those
copies and current data without regenerating anything. The original catalogue
preserves previous passive acceptance and rejected ImageGen attempts as history.

## Current evidence

Selected PNGs, JSON manifests and logs are retained by the publishing inventory.
Raw AVI files are local-only; reproduce them with the commands below. Their
decoded verification reports remain portable, including exact movie hashes.

- [Source-bound native motion manifest](../../game/tests/output/furnishing-runtime-motion-20260908-check1/manifest.json),
  [local world movie](../../game/tests/output/furnishing-runtime-motion-20260908-check1/world.avi),
  and [decoded verification](../../game/tests/output/furnishing-runtime-motion-20260908-check1/verification.json):
  25,709 lifecycle checks, zero failures, 73 native PNGs, eight complete facing/
  employee scenarios, and 6,355 deterministic actor-physics steps. All 98 source
  and accepted-image hashes are equal before/after. The separate verifier passes
  437 checks: exact source/PNG hashes, expected labels, distinct sampled states,
  chronological markers, and every final seated state and position.
  Actual decoded AVI count is **6,359 frames at 30 FPS, 211.966667 seconds**,
  1280×720, ending on zero-based engine marker 6,358. Godot's console render
  counter reports 6,215 with explicit capture draws; the decoded count is the
  acceptance value. Godot strips the engine movie argument from script arguments,
  so the initial manifest's movie path is empty; `verification.json` explicitly
  binds its same-checkpoint `world.avi` filename, decoded range and full SHA-256
  without rewriting the captured manifest.
- [Mature Renovate UI manifest](../../game/tests/output/furnishing-mature-ui-20260908-check1/mature-ui-manifest.json):
  28 checks, zero failures, three native 1280×720 captures, source hashes stable.
  The real pointer opens the 11-item picker; its last row and bottom border fit
  within the viewport. Open controls, the full dropdown, and Mina's native tool
  preview were all inspected. This is an explicitly worker-disabled visual/input
  fixture, not durability evidence; its Reconnect rail control is expected.
- [Fresh 72-state workstation contact](../../game/tests/output/furnishing-runtime-motion-20260908-check1/role-lifecycle-contact-native.png),
  [eight decoded typing frames](../../game/tests/output/furnishing-runtime-motion-20260908-check1/movie-typing-contact.png),
  and [12 decoded route samples](../../game/tests/output/furnishing-runtime-motion-20260908-check1/movie-north-mina-route-contact.png)
  were inspected, as were all eight full native typing PNGs. Route samples show
  approach, seating, departure to research, return for approval and delivery;
  layered desk/kit/actor contact remains coherent in each authored facing.
  These are sampled motion observations, not a claim every movie frame was
  watched. The original successful still checkpoint below is preserved.
- [Production lifecycle manifest](../../game/tests/output/furnishing-runtime/manifest.json):
  12,934 checks, zero failures, 73 native 1280×720 captures. Both employees run
  approach, thinking, typing, research, approval, delivery, failed rest, lunch,
  and return in every desk facing through the existing actor event/navigation
  paths. The worker is disabled; these are deterministic art/behavior fixtures,
  not evidence of paid provider work or SQLite durability.
- [Host lifecycle contact sheet](../../game/tests/output/furnishing-runtime/role-lifecycle-contact-native.png):
  nine columns in that state order; rows are north Mina/Theo, east Mina/Theo,
  south Mina/Theo, west Mina/Theo. Crops intentionally remain on the workstation
  when the actor leaves it; full captures contain the destination and actor.
- [Decor directions](../../game/tests/output/furnishing-runtime/decor-manifest.json):
  38 checks, zero failures, all three decorations visible in each of four native
  production-room captures.
- `test_furnishing_projection.gd`: 162 passing checks for native layer mapping,
  storage/placement/all facings, immutable old-layout fallback, essential station
  preservation, legacy-coordinate immunity, and occupied workstation rejection.
- [Worker/Godot parity](../../game/tests/output/furnishing-parity/godot-results.json):
  all 1,068 candidates agree, including future hire layouts, real visual bounds,
  clearance, work/service points, and architecture. Expected results are produced
  by the real worker geometry implementation, not copied Godot answers.

Catalogue truth now contains 56 runtime-integrated atomic directions and 112
accepted passive directions (42 families / 168 total). Historical passive review
is preserved for the five promoted families; other profession kits remain a
library, not new employees. Registration verification passes for all 84 exact
native copies. The current catalogue validator passes 32,525 checks and 111
self-tests, with the 175-preview Markdown gallery current. The HTML builder
passes 56 self-tests and its explicit freshness check. Strict legacy production
tests now admit exactly the three reviewed decor kinds: directional projection
448 checks, archive production 3,300 checks; unreviewed views still fail.

## Visual decision and limits

The native lifecycle contact sheet, decorated full room, all four full-room decor
views, east Mina typing, west Theo typing, north Mina failure, and south Theo lunch
were inspected. Role identity remains visible on the desk surfaces; monitors,
characters, tools and chair layers retain their established depth ordering. The
full frames confirm that cropped labels at contact-sheet edges are crop limits,
not in-game clipping. All three decorations fit the floor without doubled walls,
footprint overlap, floating pivots or arbitrary scaling. Lamp silhouette changes
read clearly; the planter's subtle directional change and pedestal's austere
closed views retain their previous art limitations.

Conservative six-category scores in the existing order (pixel coherence,
perspective, silhouette, layering/anchor, direction consistency, placement):
planter **3/2/3/3/2/3**, lamp **3/2/3/3/3/3**, pedestal **3/3/2/3/2/2**,
Mina and Theo kits each **3/2/3/3/3/3**. No category is below 2 and each mean is
at least 2.5. Native original art is unchanged from the accepted library.

This review does not claim every full capture or every animated frame was
manually watched. Persistence, real-input UI, complete chapter/restart, scaling,
and broader regression acceptance remain in [the implementation log](../FURNISHING_IMPLEMENTATION.md).

The first native capture waited on `frame_post_draw` after its window stopped
drawing in the background. Its interrupted files are retained separately in
`furnishing-runtime-render-wait-interrupted`; the temporary headless diagnostic
in that folder is not native acceptance evidence. The final capture uses the
established explicit `RenderingServer.force_draw(false)` audit approach. The
same complete lifecycle independently passed 12,788 provider-free headless checks.

## Reproduction

```sh
node dev/tools/install_furnishing_library.mjs
node harness/test/fixtures/furnishing-parity.mjs game/tests/output/furnishing-parity/cases.json
godot --headless --path game --script res://tests/test_furnishing_projection.gd
godot --headless --path game --script res://tests/test_furnishing_parity.gd
godot --path game --fixed-fps 30 --script res://tools/capture_furnishing_runtime.gd
godot --path game --fixed-fps 30 --script res://tools/capture_furnishing_runtime.gd -- --decor-only
```

For a new source-bound motion checkpoint, choose a never-used output name:

```sh
mkdir game/tests/output/furnishing-runtime-motion-review-next
STARTUP_VALLEY_AUDIT_OUTPUT_ROOT=res://tests/output/furnishing-runtime-motion-review-next godot --path game --fixed-fps 30 --write-movie res://tests/output/furnishing-runtime-motion-review-next/world.avi --script res://tools/capture_furnishing_runtime.gd
node dev/tools/verify_furnishing_runtime_capture.mjs game/tests/output/furnishing-runtime-motion-review-next
```

`ffprobe` must be on PATH or supplied as the verifier's second argument. The
verifier decodes the movie and refuses to replace an existing verification file.
Use a different fresh output root with `-- --mature-ui` for the mature-menu
supplement; never mix simultaneous native captures or change sources mid-run.
