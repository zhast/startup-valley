# Passive lighting and entry furniture — final native art-library review

Date: September 6, 2026\
Families: `task_floor_lamp`, `desk_lamp_kit`, `coat_bag_stand`\
Final reviewed revisions: `task-floor-lamp-v2`, `desk-lamp-kit-v2`, `coat-bag-stand-v3`\
Disposition: **all three reviewed revisions pass the bounded passive art-library gate; none is runtime-admitted or default-placed**.

## Outcome

The accepted revisions are deterministic editable code-native RGBA fixtures. North,
East, South, and West are authored directly in screen space with fixed
screen-upper-left material light. No finished bitmap is rotated, mirrored, flipped,
scaled, or sampled to stand in for another facing. Every required layer uses integer
pixels, binary alpha, zero hidden RGB, and contains no text, logo, fabricated metric,
baked actor, or active service state.

- `task-floor-lamp-v2` is a one-cell articulated floor lamp on a `128×256`
  canvas with pivot `[64,208]`. Its compact solid contact shadow replaces v1's
  visually busy dither halo.
- `desk-lamp-kit-v2` is a zero-collision two-layer overlay on the accepted
  workstation's `192×224` canvas and `[96,160]` pivot. The complete shade,
  arm, and support use z-offset `+2`, above the accepted desk top/front at `+1`
  and below the lamp base/lip at `+4`.
- `coat-bag-stand-v3` is a one-cell entry stand on `128×256` / `[64,208]`.
  It retains v2's real hook-to-collar hanger, bag-to-shelf contact, and compact
  shadow, while replacing v2's rearranged frontal art with one buttoned front,
  one button-free rear, and two genuinely narrow side projections.

The optional `ambient_overlay` for both lamps remains planned and absent. Art
approval does not create a powered state. The coat stand's directional contact
record remains passive placement metadata: no service, action, reservation,
employee, pose, worker responsibility, persistence, or new hire is implemented.

## Preserved rejected history

All rejected fixtures and evidence remain byte-addressable; none is relabeled as the
approved revision.

- Floor-lamp v1 passed functional checks but its broad dither floor field was too
  busy at native room scale. V2 changes only the contact treatment.
- Desk-lamp v1 placed its rear support/shade at z-offset zero. On the accepted South
  desk, the tabletop hid the green shade and left disconnected base/head fragments.
  V2 uses strict `+2/+4` host layering and proves the whole shade after composition.
- Coat-stand v1 had no visible hanger between hook and coat and left the bag floating
  above its shelf.
- Coat-stand v2 repaired both physical support defects, but failed directional art
  review. North and South both exposed substantially the same V-collar/button face;
  East and West retained almost frontal garment, rack, and shelf widths. V2 is
  preserved as a physically supported but directionally rejected intermediate.
- Coat-stand v3 is the only proposed coat art. North is the buttoned front; South
  has a horizontal rear yoke, center-back pleat, rear hem, and no buttons. East and
  West expose opposing narrow sides.

## Geometry and ordered layers

The two base objects use one exact occupied cell `[[0,0]]`,
`floor_shadow/-8`, `rear_structure/-4`, and `front_structure/+5`.
Each has a centered sprite offset `[0,-80]` and one common floor pivot across
all layers and directions. The desk kit uses no floor cells and centered offset
`[0,-48]`, with reusable `surface_decor_rear/+2` and
`surface_decor_front/+4` layers.

The coat v3 projection contract is measured from authored geometry rather than
inferred from unequal hashes:

| Facing | Physical face | Coat px | Bag px | Shelf width | Crossbar span |
| --- | --- | ---: | ---: | ---: | ---: |
| North | front | 27×72 | 24×31 | 52 | 48 |
| East | left side | 15×70 | 12×29 | 31 | 25 |
| South | rear | 28×73 | 25×33 | 53 | 49 |
| West | right side | 15×69 | 12×29 | 31 | 26 |

The side coat and bag keep essentially the same height as front/rear while reducing
width to at most 60%; side shelves and crossbars reduce to at most 65% and 60%.
That proves foreshortening of the same physical assembly instead of uniform
miniaturization. Focused assertions also require buttons only on North, no front
buckle on the South bag, a continuous opaque hanger path, and substantial contiguous
bag/shelf contact in every facing.

## Deterministic structural evidence

- Exporter: **112 checks, 0 failures**.
- Final alpha/anchor/reconstruction/collision/host/support/direction gate:
  **412 checks, 0 failures**.
- All final PNGs rebuild byte-exact from
  `game/tools/passive_lighting_entry_geometry.gd`.
- Every required layer is nonempty on the common canvas, uses binary alpha with
  zero hidden RGB, and reconstructs the whole in declared depth order.
- Every facing is byte-distinct, and opposing wholes reject finished-bitmap mirror
  substitution.
- The floor lamp retains one exact collision cell and `1,800–1,839` opaque whole
  pixels. The desk lamp contributes zero collision, clears all twelve accepted
  direction-by-device checks, and uses `189–329` opaque whole pixels.
- Coat v3 uses `4,632 / 3,081 / 4,846 / 3,104` opaque pixels in N/E/S/W;
  the deliberately narrower side counts follow the measured physical projections.

The first v2 structural draft failed **8 of 389** checks: its hanger shoulders left a
two-pixel neck gap, and one assertion demanded nearly full bag-width shelf contact
despite an intentional lateral offset. The neck was physically closed and the
contact rule was corrected to require exact vertical contact plus substantial
contiguous overlap. Those failures remain part of the record. The later coat v2
directional rejection was visual, not hidden by those green structural counters.

Evidence:

- `game/tests/fixtures/furniture-calibration/task-floor-lamp-v2/manifest.json`
- `game/tests/fixtures/furniture-calibration/desk-lamp-kit-v2/manifest.json`
- `game/tests/fixtures/furniture-calibration/coat-bag-stand-v3/manifest.json`
- each final output directory's `structural-results.json`,
  `candidate-contact-sheet-native.png`, `candidate-contact-sheet-4x.png`, and
  `candidate-layers-native.png`;
- rejected coat v2 remains under
  `game/tests/fixtures/furniture-calibration/coat-bag-stand-v2/` and
  `game/tests/output/coat-bag-stand-v2/`.

## Actual GameMain evidence

Each accepted family was captured in a fresh native macOS Godot process at
`1280×720`, one family per process. This avoids sharing a GameMain teardown
boundary and gives each family an independent completion footer and byte guard.

- `task_floor_lamp`: **188 process checks, 0 failures** (**183** family-local).
- `desk_lamp_kit`: **72 process checks, 0 failures** (**67** family-local).
- `coat_bag_stand` v3: **188 process checks, 0 failures** (**183** family-local).

For both base families, actual `GameMain` and production `TownRoom` use a
disposable owner-scoped duplicate catalogue/layout containing only the candidate.
`[12,13]` is a common safe pivot in N/E/S/W. Each view builds one exact
`32×32` collision shape, blocks its AStar cell, retains an adjacent walkable
contact, rejects a real two-axis corner atomically, and exposes visible alpha-aware
picking on every layer without inventing an action. Every opaque source pixel
matches the pre-actor room composition with zero mismatch.

The founder is only an existing route, scale, gaze, and depth probe. He reaches the
exact contact without entering collision. North/South take the intended whole-object
front/behind relation; East/West place him between rear and front layers. Collision
and navigation remain stable.

Natural actor intersection is measured rather than manufactured:

| Family | North | East | South | West | Wrong-depth |
| --- | ---: | ---: | ---: | ---: | ---: |
| task floor lamp v2 | 768 | 14 | 368 | 4 | 0 all |
| coat/bag stand v3 | 979 | 7 | 884 | 24 | 0 all |

For the desk kit, ordinary production `mira-workstation` supplies the accepted
`workstations-v2:{direction}` host capability. The fixture attaches only the
exact v2 rear/front overlays. Mina keeps the accepted seated contact/gaze and the
workstation retains three collision shapes. Both layers make a visible contribution
in every facing. The host-composed support centerline is fully visible: North
`19/19`, East `10/10`, South `21/21`, West `14/14`. Exact whole-source
shade matching has zero mismatches across North `129`, East `136`, South
`129`, and West `92` opaque shade-region pixels.

Direct actor/desk-lamp intersection is honestly North `0`, East `2`, South
`0`, West `0`: the valid lamp occupies clear tabletop edge space and was not
moved to inflate a counter.

Every native process starts no worker, accesses no save, creates no service, and
leaves `game/data/furniture_catalog.json`, `game/data/office_layout.json`, and
`dev/art-catalogue/furniture.json` byte-exact during its run.

Evidence:

- each accepted output directory's `actual-room-results.json`;
- each `actual-room-actor-contact-sheet-native.png` and
  `actual-room-actor-contact-sheet-4x.png`;
- base-family `actual-room-base-contact-sheet-native.png`;
- desk `actual-room-host-baseline-native.png` and
  `actual-room-lamp-contact-sheet-native.png`;
- each `actual-gamemain-contact-sheet-native.png`, containing four unscaled
  `1280×720` panels.

## Preserved invalid native runs

The first v1 combined attempt was invalid despite a zero-failure footer. After 374
assertions, its desk coroutine read a nonexistent direct `profile_kind` key from a
production workstation dictionary. The record is
`game/tests/output/desk-lamp-kit/actual-room-initial-harness-failure.json`.

The corrected v1 combined process wrote one family and then stalled before the next.
It was terminated after roughly 180 seconds; partial batch results were not admitted.
The record is
`game/tests/output/task-floor-lamp/actual-room-second-batch-stall.json`. The
capture tool now requires one explicit family per process.

The first v2 native invocation ran before Godot imported the new PNG paths. Admission
failed at **13 checks, 5 failures**, no candidate rendered, and the failure remains at
`game/tests/output/task-floor-lamp-v2/actual-room-initial-import-failure.json`.
A normal import preceded every accepted final run.

## Main-agent native visual scores (0–3)

| Family / revision | Pixel | Perspective | Silhouette | Layers | Direction | Placement | Mean / minimum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| task floor lamp v2 | 3 | 2 | 3 | 3 | 3 | 3 | **2.83 / 2** |
| desk lamp kit v2 | 3 | 2 | 2 | 3 | 3 | 3 | **2.67 / 2** |
| coat/bag stand v3 | 3 | 2 | 3 | 3 | 3 | 3 | **2.83 / 2** |

Floor-lamp perspective scores 2 because the compact, readable screen-axis projection
remains stylized. Desk perspective and side silhouette score 2 because the host-edge
device is necessarily subtle at native room scale. Coat perspective scores 2 because
the orthographic rack remains graphic, while its front/rear/side physical identity is
now coherent. Every family meets the passive-library threshold of mean at least 2.5
and no criterion below 2.

## Proposal and boundary

Schema-valid per-family passive art-library approval proposals:

- `dev/art-catalogue/task-floor-lamp-v2-registration.json`
- `dev/art-catalogue/desk-lamp-kit-v2-registration.json`
- `dev/art-catalogue/coat-bag-stand-v3-registration.json`

These proposals approve only the reviewed art library. They deliberately keep
`current_runtime_registration`, runtime art/evidence, production binding, and
default layout null. No runtime catalogue, default layout, shared catalogue,
worker/contracts, provider, save, actor behavior, service, or powered-light system
was modified by this candidate task.

## Rerun

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_passive_lighting_entry.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_passive_lighting_entry.gd
STARTUP_VALLEY_NO_WORKER=1 STARTUP_VALLEY_PASSIVE_CAPTURE_FAMILY=task_floor_lamp /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --script res://tools/capture_passive_lighting_entry.gd
STARTUP_VALLEY_NO_WORKER=1 STARTUP_VALLEY_PASSIVE_CAPTURE_FAMILY=desk_lamp_kit /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --script res://tools/capture_passive_lighting_entry.gd
STARTUP_VALLEY_NO_WORKER=1 STARTUP_VALLEY_PASSIVE_CAPTURE_FAMILY=coat_bag_stand /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --script res://tools/capture_passive_lighting_entry.gd
```
