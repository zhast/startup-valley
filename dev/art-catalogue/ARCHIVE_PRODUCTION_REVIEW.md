# Archive v1: production integration and normal-room acceptance

2026-09-04, final focused capture at approximately 09:06 UTC. **The archive alone now uses four approved production service profiles.** This follows the coordinator's independent native/4× approval of the [assembly](ARCHIVE_ASSEMBLY_REVIEW.md), the [canonical service/headroom proof](CANONICAL_SERVICE_INTEGRATION.md), and the normal-office verification below. It does not approve workstation candidates or any other furniture family.

## Actual change and retained behavior

- [Runtime exports](../../game/assets/runtime/office/archive-v1/README.md): 24 PNGs, four views × five registered layers plus a whole reference. Every file and imported RGBA byte matches the corresponding frozen `modular-archive-v1` fixture export. All canvases remain **192×288**, floor pivot **(96,224)**, Sprite offset **(0,-80)**; no independent crop, scaling, rotation, mirroring or repaint.
- [Production catalogue](../../game/data/furniture_catalog.json): only `artifact_archive` gains real `runtime_ready` N/E/S/W profiles with `review.art` and `review.geometry` true. Production loads them without a calibration owner/permit. They declare standing-service side, opposite arrival gaze, and the mandatory **48×80** approach envelope. There is no work cell, chair, pose registry or fake pose approval.
- The normal archive is still **South at grid (4,13)** and still unlocks with the first hire. South occupied cells, three-cell clearance and service point are unchanged. `office_layout.json` is unchanged. The previous `artifact-archive.png` and original flat catalogue fields remain recoverably intact.
- The other six active families remain South-only. Their existing art and workstation pose gates are not relaxed. The exact-copy [installation script](../tools/install_archive_runtime.sh) neither alters JSON nor touches source masters.

The five runtime layers keep identical ground depth and stable Carcass → Top → Front → Plinth → Insert order. North/South have a **96×32** footprint; East/West have **32×96**. Rise is **64px**, with the same fixed screen-axis camera and upper-left lighting.

## Actual game, input and migration proof

The [production fixture](../../game/tools/archive_production_fixture.gd) loads the actual GameMain, normal architecture, catalogue, roster positions, actors, navigation and UI. It replaces the leaf worker transport before scene ready, does not load personal bootstrap/settings/save state, and does not inject candidate furniture or approval metadata. The optional toolbar is developer-only; the five plain office-stage screenshots contain no toolbar.

The [focused test](../../game/tests/test_archive_production.gd) covers:

1. All five normal office stages (0–4 hires), preserving original unlock behavior. Stages 3–4 show the existing two real employees plus the authored later furniture unlocks, not invented employee hires.
2. All four views at the normal bay in stages 1 and 4. Real `R` and mouse events exercise the existing preview/commit path; the founder walks away before a footprint-changing turn.
3. Actual archive click → shared AStar route → exact service socket → opposite facing → existing Studio tab. Every founder physics tick is checked against walls, furniture and live actors. No endpoint teleport or fabricated immediate arrival is used.
4. Studio paper clicks do not leak into world movement; the real close target dismisses it. Tests await the actual drawer tween before further hit-testing, rather than assuming a number of wall-clock frames.
5. Roster/growth reconciliation preserves the selected archive facing and founder position. The guarded developer layout export is loaded into a fresh normal model and validated across all five stages, with no calibration admission. This is **layout export/reload**, not a claim of a new SQLite save/restart test.
6. All reviewed runtime pixels match the source union in the unoccupied room captures. Imported transparent padding remains exact; no import alpha-border filling is allowed.

The earlier service suite separately proves malformed/mixed/cross-owner profile rejection, occupied rotations, unavailable or newly blocked sockets, real invalid-click feedback, and conservative standing headroom at walls/corners. Those rules are not bypassed by production approval.

## Native visual review

[All four mature-office views](../../game/tests/output/archive-production/all-four-native.png) are an **unscaled** 2×2 arrangement, N/E above S/W. Individual 1280×720 views and their nearest 4× crops are listed in the [manifest](../../game/tests/output/archive-production/manifest.json).

Reviewed at native scale: all five normal office stages, all eight stage-1/stage-4 directional views, all eight Studio arrivals, and selected North approach/West departure midpoint frames. Also inspected all four stage-4 nearest-neighbor crops. No archive/wall overlap, layer seam, unintended scaling or observed archive-related UI overlap remains in those images. The South face reads as storage/display; the East locker end and West glazed end remain intentionally quieter.

The coordinator's bounded visual scores remain **3/3/2/3/2/2, mean 2.5**, with no category below 2. Important nonblocking limits remain explicit:

- The tall North cabinet naturally hides almost the entire founder at the rear service socket; visible hair stays on the floor area, not the wall. No false front-of-cabinet depth or actor relocation was added.
- East/West end details are dark at native size. Optional identification/contrast polish is not part of this promotion.
- There is no opening-door, reaching or archive-use animation and no new Studio backend functionality. Standing arrival reuses existing locomotion idle poses.
- This batch is native 1280×720. It does not replace the coordinator's broader static/motion/scale regression, nor prove every possible future room arrangement or schedule. The movie was recorded and sampled stills inspected; all 2,000 frames were not individually watched.

### Preserved diagnostic failures

The optional development toolbar initially covered employee labels at their unchanged normal spawn row. The first batch remains under `archive-production/before-editor-callout-obstacle/`. A second attempt correctly included its bounds but did so before the newly added container settled; three South-view overlap assertions caught that timing error. That batch remains under `before-editor-layout-settle/`.

The final dev fixture resolves the **actual settled toolbar bounds immediately before capture** using the existing world-callout placement solver. Labels move beside actors; no actor, production UI geometry or room placement is changed. The toolbar now honestly says **Production archive review**, not inherited “Calibration only.” A separate fast-headless tween timing failure was fixed by awaiting the real tween; the final fixed-30 test does not simulate close success by calling a handler.

## Verification, source snapshot and reproduction

- Final fixed-30 headless: **1,967 checks, zero failures** ([results](../../game/tests/output/archive-production/results-headless.json)).
- Final rendered: **2,255 checks, zero failures**, **87 PNGs**, **18 actual movement paths**, **1,590 founder physics ticks**. Each path has start/middle/end: **54 samples with 54 distinct image hashes**. The derived four-view sheet is additional, not counted among the 87.
- [Movie](../../game/tests/output/archive-production/archive-production.avi): independently confirmed with `ffprobe`, **1280×720, 30 FPS, 2,000 frames, 66.667 seconds**.
- The manifest records SHA-256 for main, employee/player avatars, OfficeLayout, TownRoom, production catalogue, fixture and test, and checks none changed during the run. It includes the coordinator's frozen cue-obstacle/sentence-case patch: main `3e605ca86b31…`, EmployeeAvatar `5e0e114e768b…`, catalogue `962d47f9fd38…`.
- After archive activation, the direction **429/0**, layout **830/0**, editor **140/0**, migration **2,468/0**, modular office **7,436/0**, service **1,574/0**, project validation, gameplay `run_all`, and complete-game tests passed. Assertions changed only where the archive is now a real standing-service family; other legacy South safety assertions remain.
- Import and exact-copy script syntax passed. `git diff --check` passed. The earlier broad BEFORE regression is preserved at `game/tests/output/regression-checkpoint-0849/`; broader AFTER verification is coordinated separately rather than implied by this focused report.

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_archive_production.gd
godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/archive-production/archive-production.avi \
  --script res://tests/test_archive_production.gd -- --motion
```

No worker contracts, provider calls, credentials, personal saves, paid services, commits or pushes were involved. Source masters, failed image attempts, calibration recipes and earlier evidence remain unchanged. The machine catalogue/ledger promotion is a separate coordinator-owned follow-up; this report does not silently rewrite their historical statuses.
