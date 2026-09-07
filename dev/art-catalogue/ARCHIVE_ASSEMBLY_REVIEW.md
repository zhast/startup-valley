# Archive: four service sides, native assembly and export

2026-09-04. **Four independently authored visible faces assembled and reviewed; staged only, no production replacement.** Prefer the quiet charcoal powdercoat top. The separate canonical GameMain/navigation/editor integration is not replaced by this showroom's sprite paths.

## What was assembled

The exact code-native archive preserves its96×32 floor footprint and64px rise. East/west exchange floor axes to32×96; vertical rise remains64px. The camera, screen axes and upper-left edge lighting never rotate. Five registered layers—Carcass, Top, Front, Plinth, Insert—share one floor anchor and draw in that order at the same depth. The optional Insert layer receives one independently generated visible-face texture; it does not paint the South front onto a side or rear.

The new [typed finish API](../../game/tools/modular_cabinet_geometry.gd) explicitly distinguishes `CameraFace.REAR`, `LOCKER_END`, `SERVICE_FRONT` and `DISPLAY_END`. `set_camera_face_finish(kind, texture)` rejects the wrong declared face, wrong native dimensions and non-archive families. `set_service_insert` remains strictly South-only. The original five-child geometry and every default bare raster remain unchanged; rendering proves byte identity against all four prior bare exports.

`set_top_finish(TopFinish.POWDERCOAT, texture)` tiles the supplied isotropic32×32 material without rotation or scaling and applies fixed-screen charcoal edge lights. Calling `set_top_finish(TopFinish.OAK)` restores the exact previous axis-specific oak tile and edge rectangles. Invalid inputs leave the current appearance intact. Default construction is still the existing oak/bare cabinet.

| Service side | Visible camera face | Floor / raised top, local pixels | Face socket, local pixels | Source registration |
| --- | --- | --- | --- | --- |
| North | Rear, not accessible doors | Floor`(-48,-16,96,32)` / top`(-48,-80,96,32)` | `(-44,-44,88,56)` | `(52,180)` on192×288 |
| East | Original South viewer-left / locker end | Floor`(-16,-48,32,96)` / top`(-16,-112,32,96)` | `(-12,-12,24,56)` | `(84,212)` on192×288 |
| South | Service front: lockers, files and display | Floor`(-48,-16,96,32)` / top`(-48,-80,96,32)` | `(-44,-44,88,56)` | `(52,180)` on192×288 |
| West | Original South viewer-right / display end | Floor`(-16,-48,32,96)` / top`(-16,-112,32,96)` | `(-12,-12,24,56)` | `(84,212)` on192×288 |

Every export keeps canvas192×288 and pivot`(96,224)`, centered-sprite offset`(0,-80)`. Complete opaque bounds are N/S`(-48,-80,96,96)` and E/W`(-16,-112,32,160)`; the last opaque row is immediately before floor contact Y+16 or+48. Transparent canvas padding is not collision or wall clearance.

Service cells are N`(0,-1)`, E`(1,0)`, S`(0,1)`, W`(-1,0)` in32px cells, with a three-cell approach strip on that service side. Arrival gaze is the opposite cardinal direction. This assembly metadata contains no invented chair, work cell, seated pose, or worker-gaze semantics.

## Sources and native fidelity

The coordinator supplied four distinct generated panels, each from one initial ImageGen call and zero retries; no new image call or semantic pixel edit occurred in this assembly task. Masters and prompts remain under `game/assets/source/overnight-20260904/kits/`. The [South source/export review](ARCHIVE_FRONT_REVIEW.md) records its actual rather than requested compartment geometry. Builders remain:

- [South insert export](../tools/build_archive_south_insert.sh).
- [North and two distinct end exports](../tools/build_archive_other_faces.sh).
- [Isotropic charcoal material export](../tools/build_powdercoat_material.sh).

Native panel files under `game/tests/fixtures/furniture-calibration/kits/` are:

- `archive-service-north-back-v1.png`:88×56, fully opaque ink88×56.
- `archive-service-east-locker-end-v1.png`:24×56, actual ink24×50 at`(0,3)`.
- `archive-service-south-insert-v1.png`:88×56, actual ink88×54 at`(0,1)`.
- `archive-service-west-display-end-v1.png`:24×56, actual ink24×50 at`(0,3)`.

Each `-registered.png` partner is verified byte-for-byte against its native face blitted to the shared canvas. The rendered Insert layer is also byte-exact to that registered source. The end faces retain their real three-pixel padding instead of being stretched to56px. Parent charcoal fills the otherwise transparent rows. Binary alpha, empty RGB beneath transparency and unchanged original file SHA-256 checks pass. The powdercoat tile is opaque32×32 with three colors; structural edge colors remain separately authored geometry.

## Native preference and observed behavior

[All four service sides, both top finishes](../../game/tests/output/archive-assembly/all-four-materials.png) use the same geometry and native source sizes. **Powdercoat is preferred.** Its quiet charcoal roof belongs to the metal archive, allowing the South lockers/documents/displays to be the focal point. Oak is coherent with other office furniture but its long East/West roof becomes a bright orange stripe and dominates the cabinet. The oak alternative remains in evidence; it is not overwritten or relabeled as a failure.

The North back has a recessed panel/vent, East has the solid locker end, South exposes the storage/display face, and West has the dark glazed/display end. Side panels remain mostly dark at native scale, but the family volume and matte/glass distinction are clear when compared together. These are plausible distinct views, not proof of a fully specified mechanical cabinet with every fastener tracked in3D.

No front texture leaks into North/East/West. No face seam, arbitrary runtime scale, rotated lighting or overlapping wall bitmap was observed in the native checks. Front actors correctly cover the visible cabinet. Behind it, the64px rise legitimately hides much of a person; at the nearest North service point, **1,021 of1,315 Mina pixels** and **1,046 of1,467 Theo pixels** are hidden. That is correct opaque depth, not a special whole-object sort exception. No new door-opening or cabinet-use character animation is implied.

### Wall/corner layout lesson

[Nearest geometric corners](../../game/tests/output/archive-assembly/wall-corners-empty.png) keep complete opaque cabinet ink and service cells inside the actual room floor. The tested host pivots are N`(80,176)`, E`(1072,208)`, S`(1072,624)`, W`(80,592)`. Explicit too-close alternatives are rejected for wall-crossing artwork or inaccessible service clearance.

A physically valid North approach at the nearest cabinet position would project the character's head onto the top wainscot. The [service-corner presentation](../../game/tests/output/archive-assembly/wall-corners-service.png) therefore moves only that North cabinet one grid row inward to`(80,208)`. Its service foot is then`(80,176)` and the visible head remains below the wall. This is a real composition constraint beyond foot-cell validity, not permission to hide the actor or alter its sprite. Production/editor placement policy should distinguish legal geometry from desirable character headroom.

## Verification and durable evidence

- [Capture/export harness](../../game/tools/capture_archive_assembly.gd) and [focused test entry](../../game/tests/test_archive_assembly.gd).
- [Final headless results](../../game/tests/output/archive-assembly/results-headless.json): **120 checks, zero failures**.
- Existing modular cabinet test: **344 checks, zero failures**. Existing South-front test: **19 checks, zero failures**.
- [Final native manifest](../../game/tests/output/archive-assembly/manifest.json): **5,810 checks, zero failures**, **95 PNGs**, **2,532 depth observations**, **3,308,913 opaque actor pixels** compared to the expected ordered cabinet/actor source colors, with zero mismatches.
- [Movie](../../game/tests/output/archive-assembly/archive-assembly.avi): `ffprobe` confirms **390 frames at30 FPS,1280×720**. The recorder includes one additional initialization/teardown frame beyond the389 explicitly awaited frames.
- PNG inventory: **23 normal-room scenes**, **24 nearest-neighbor4× crops**, **48 registered layer/whole comparisons** (six per side per finish). These are separate from the24 staged powdercoat export files.
- Native inspection covered all23 room scenes, plus the four unoccupied powdercoat4× views. The95-file inventory does not imply every enlarged crop or every movie frame was individually watched. Each step of both deterministic sprite walkarounds nevertheless receives exact opaque-depth and physical-foot checks.
- `git diff --check` passes. No worker, save, credential, provider, source-image or production-catalogue mutation occurred.

The sprite walkaround uses existing native locomotion frames on an explicit four-sided path. It proves sampling, depth and visible registration while moving; **it is not a substitute for actual player input, AStar navigation, Studio dispatch or editor rotation validation**. The separate [canonical service-profile integration](CANONICAL_SERVICE_INTEGRATION.md), with evidence under `game/tests/output/calibrated-service/`, owns those tests and remains an explicit additional gate. Follow that report for its final deterministic counts and actual input/headroom evidence; the earlier4,456-check timing-dependent first batch is not its final result. This assembly review does not confer production art approval on the separate integration.

Useful native evidence:

- [Mina service](../../game/tests/output/archive-assembly/mira-service.png), [Theo service](../../game/tests/output/archive-assembly/theo-service.png).
- [Mina rear](../../game/tests/output/archive-assembly/mira-rear.png), [Theo front](../../game/tests/output/archive-assembly/theo-front.png).
- [Mina walk](../../game/tests/output/archive-assembly/mira-walk-edge2.png), [Theo walk](../../game/tests/output/archive-assembly/theo-walk-edge0.png).
- [North4×](../../game/tests/output/archive-assembly/all-four-materials-north-powdercoat-4x.png), [East4×](../../game/tests/output/archive-assembly/all-four-materials-east-powdercoat-4x.png), [South4×](../../game/tests/output/archive-assembly/all-four-materials-south-powdercoat-4x.png), [West4×](../../game/tests/output/archive-assembly/all-four-materials-west-powdercoat-4x.png).

## Staged export and integration contract

[Export manifest](../../game/tests/fixtures/furniture-calibration/modular-archive-v1/manifest.json) supplies four recipes and24 PNGs under `game/tests/fixtures/furniture-calibration/modular-archive-v1/`: `{north,east,south,west}-{carcass,top,front,plinth,insert,whole}.png`. All five composable layers use full192×288 regions, offset`(0,-80)`, zero per-layer depth offset and stable author order. Their ordered alpha union exactly matches the corresponding whole. Whole images are evidence/convenience exports, not a mandate to discard modular layers.

The **same-depth order is important**: solid cabinets should not be spread into depth offsets that move a back actor in front of the entire cabinet. Typed camera-face selection is separate from service interaction; no archive pose registry is required or faked. These files are staged calibration assets and the manifest retains `runtime_approved:false`.

Bounded visual scores for this assembly are pixel coherence3, perspective3, silhouette/readability2, layering/anchor3, direction consistency2 and placement2: mean2.5 with no category below2. This is a **staged visual pass**, not automatic runtime acceptance. The remaining family gate is the separate real GameMain/navigation/editor/Studio test and an explicit production integration decision. Door/use animation, final room placement and display-end identity refinement remain optional further polish rather than claims already implemented.

Reproduce:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_archive_assembly.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/archive-assembly/archive-assembly.avi \
  --script res://tools/capture_archive_assembly.gd
```
