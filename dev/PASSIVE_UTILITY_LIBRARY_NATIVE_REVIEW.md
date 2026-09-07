# Passive utility library — deterministic native review

Date: September 6, 2026

Families: `tall_storage_cabinet`, `server_cabinet`, `recycling_sorter`

Candidate revisions: `tall-storage-cabinet-v1`, `server-cabinet-v1`, `recycling-sorter-v1`

Disposition: **rejected after native visual inspection**. The three v1 sets pass their mechanical export, alpha, collision, routing and layer-host checks, but each body reads as a flat frontal rectangle with only a thin top trim. The physical 2×1 / 1×2 footprint is not exposed as a raised top plane, so the perspective minimum fails and no v1 passive-library approval is valid. This review, the v1 source, PNGs, manifests and actual-room captures remain preserved as non-production failure history. A separate v2 must provide a footprint-derived top plane and a coherent camera-front elevation before approval can be reconsidered.

## Reviewed identities

- `tall_storage_cabinet` is a closed warm-oak supply cabinet. South exposes the full paired doors, upper closed compartment and handles; North exposes the braced rear; East and West are true narrow physical profiles with the appropriate door edge. No shelf contents are exposed.
- `server_cabinet` is compact charcoal equipment furniture, visually separate from both office storage and workstation art. South exposes stacked ventilated rack faces and a static unlit indicator strip; North exposes two rear fan housings and a cable spine; East and West expose independent side-vent profiles. No readable metric, status claim, logo or device execution appears.
- `recycling_sorter` is a low three-stream unit. The three streams use blue, green and grey plus distinct aperture shapes; there is no label, text or recycling-service claim. South exposes the three front doors, North the closed rear with color bars, and East/West true narrow profiles with the physical stream order changing as the viewpoint changes.

Every view is independently authored in typed GDScript on fixed screen axes. No complete raster is rotated, mirrored, flipped, scaled or reused as another facing. The retained reviewed oak and powdercoat material tiles are sampled as construction materials, not transformed furniture views. New bitmap generation was unnecessary, so ImageGen was not invoked and no source-attempt counter or billing path was created. The source catalogue contained only planned/missing variants and no prior source attempts; the proposed registrations retain those exact records as history.

## Dimensions and geometry

The planned canvas and pivot contracts remain unchanged:

| Family | Canvas | Floor pivot | Sprite offset | Planned maximum-rise envelope | Measured opaque rise |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tall supply cabinet | 160×288 | (80,224) | (0,-80) | 160 px | 112 px |
| Server cabinet | 160×288 | (80,224) | (0,-80) | 160 px | 96 px |
| Recycling sorter | 160×176 | (80,112) | (0,-24) | 48 px | 48 px |

The two tall-family 160 px values were planning envelopes rather than a requirement to fill the canvas. The measured 112 px supply cabinet and 96 px server cabinet are deliberate, less wall-dominating silhouettes that remain inside the original protected envelope. The sorter's measured 48 px matches its planned low profile. All original 2×1 / 1×2 fixed-pivot occupied masks, one-cell approach clearances, service-side labels and approach-gaze metadata are retained as future geometry semantics; this review does not implement those service interactions.

Each facing has full-canvas, nonempty `floor_shadow`, `rear_structure` and `front_structure` layers. Ordered composition reconstructs the whole byte-exactly. Every layer and whole has binary alpha, zero hidden RGB, integer registration and at least 16 px of protected transparent canvas padding. Floor shadow and collision planes rotate about the unchanged pivot. Actual TownRoom creates exactly two 32×32 collision shapes per facing, blocks those cells in navigation, finds a safe common pivot at cell (12,13), and rejects a real two-wall corner at (1,3) for every family and direction. Those valid mechanical facts do not repair the missing raised top plane.

## Evidence

Tall storage:

- [Native isolated sheet](../game/tests/output/tall-storage-cabinet/candidate-contact-sheet-native.png)
- [4× isolated sheet](../game/tests/output/tall-storage-cabinet/candidate-contact-sheet-4x.png)
- [Native actual-room base sheet](../game/tests/output/tall-storage-cabinet/actual-room-base-contact-sheet-native.png)
- [4× actual-room approach sheet](../game/tests/output/tall-storage-cabinet/actual-room-approach-contact-sheet-4x.png)
- [Manifest](../game/tests/fixtures/furniture-calibration/tall-storage-cabinet-v1/manifest.json)
- [Structural result](../game/tests/output/tall-storage-cabinet/structural-results.json)
- [Actual-room result](../game/tests/output/tall-storage-cabinet/actual-room-results.json)

Server cabinet:

- [Native isolated sheet](../game/tests/output/server-cabinet/candidate-contact-sheet-native.png)
- [4× isolated sheet](../game/tests/output/server-cabinet/candidate-contact-sheet-4x.png)
- [Native actual-room base sheet](../game/tests/output/server-cabinet/actual-room-base-contact-sheet-native.png)
- [4× actual-room approach sheet](../game/tests/output/server-cabinet/actual-room-approach-contact-sheet-4x.png)
- [Manifest](../game/tests/fixtures/furniture-calibration/server-cabinet-v1/manifest.json)
- [Structural result](../game/tests/output/server-cabinet/structural-results.json)
- [Actual-room result](../game/tests/output/server-cabinet/actual-room-results.json)

Recycling sorter:

- [Native isolated sheet](../game/tests/output/recycling-sorter/candidate-contact-sheet-native.png)
- [4× isolated sheet](../game/tests/output/recycling-sorter/candidate-contact-sheet-4x.png)
- [Native actual-room base sheet](../game/tests/output/recycling-sorter/actual-room-base-contact-sheet-native.png)
- [4× actual-room approach sheet](../game/tests/output/recycling-sorter/actual-room-approach-contact-sheet-4x.png)
- [Manifest](../game/tests/fixtures/furniture-calibration/recycling-sorter-v1/manifest.json)
- [Structural result](../game/tests/output/recycling-sorter/structural-results.json)
- [Actual-room result](../game/tests/output/recycling-sorter/actual-room-results.json)

The provider-free batch exporter passes **120 / 0** and the acceptance-safe structural suite passes **552 / 0**. Per family, the structural result records **177 / 0**. The native actual-GameMain/TownRoom run at 1280×720 passes **576 / 0**, with **190 / 0** recorded for each family. It proves real collision/navigation, alpha-aware picking for all three layers, safe route completion, exact gaze, wall/corner safety and the intended depth class in all four directions. No worker starts and no save is accessed; production furniture data, default layout and the shared art catalogue stay byte-exact during each exporter/capture run.

The existing founder is only a scale, route and layer-depth probe. Measured actor/prop intersection is recorded rather than used as an arbitrary threshold:

| Family | North | East | South | West |
| --- | ---: | ---: | ---: | ---: |
| Tall supply cabinet | 1,508 px, prop in front | 0 px | 1,221 px, actor in front | 0 px |
| Server cabinet | 1,104 px, prop in front | 0 px | 1,221 px, actor in front | 0 px |
| Recycling sorter | 0 px | 0 px | 1,199 px, actor in front | 0 px |

Zero side overlap is the truthful result of approaching a narrow side from the adjacent cell, not a defect or a manufactured acceptance condition. Native and 4× inspection shows coherent actor scale and the expected rear/actor/front ordering. This does not create a storage, server or recycling role, actor pose, service action, backend, transaction or hire.

## Native visual scores (0–3)

All three families receive the same bounded score after separate native and 4× inspection:

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, restrained material palettes, binary alpha and no matte contamination. |
| Perspective | 1 | Width changes by direction, but a 2–4 px trim is not the footprint-depth top plane required for a raised fixed-camera object. |
| Silhouette/readability | 2 | Each family is immediately distinct at native size; fine hinges, vents, rack cues and stream apertures necessarily remain abstract. |
| Layering/anchors | 2 | Three visible layers reconstruct and actor z-order works, but the layer geometry does not express top-plane versus front-elevation depth. |
| Direction consistency | 3 | Front, rear and both independently authored side profiles describe one coherent physical object under fixed upper-left light. |
| Placement | 3 | Original masks rotate exactly; real routes, collision, visible-surface picking and wall/corner rejection pass. |

Mean **2.33 / 3**, minimum **1 / 3** for each family: the passive-library gate fails.

## Reproduction and boundary

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_passive_utility_library.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_passive_utility_library.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_passive_utility_library.gd
```

The exporter and structural suite deliberately allow a later declared passive-library state while continuing to enforce the stable canvas, pivot, masks and absence of runtime paths. The preserved v1 proposed-family records are explicitly rejected. This review does not edit `furniture.json`, production data, runtime assets, the default layout, worker, contracts or saves.
