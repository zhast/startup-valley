# Locomotion crop-bleed repair

Reviewed 2026-09-04 06:27 UTC. **Implemented, native-inspected and regression-tested.** This is a deterministic re-export of existing founder/Mina/Theo masters, not newly generated art. It does not approve any staged directional seated pose or desk/chair contact.

## Proven defect and source cause

The old `dev/tools/build_polish_assets.sh` trimmed the entire source image, divided the resulting height into four equal quarters, then trimmed each extracted cell. Generated source rows are not necessarily equally spaced. Mina's cropped source is 1066×950, but its true occupied row bands are:

| Direction | Alpha band, top inclusive / bottom exclusive | Old quarter boundary problem |
| --- | --- | --- |
| Front | [0,238) | First cut at 237 can remove the last source-pixel row |
| Back | [256,487) | Cut at 475 removes up to 12 source pixels of boots |
| Left/west | [505,718) | Receives those back-view boot fragments; cut at 712 removes up to 6 pixels of its own boots |
| Right/east | [735,950) | Receives the left-view boot fragments |

The fragments are already baked into the PNG; this was not texture filtering, Godot region coordinates or floating-point world placement. All six west and all six east cells were affected. Example native Mina west idle cell 0 had detached components `(18,4,7,3)` and `(26,4,8,3)` above its main `(11,13,25,59)` body. East idle cell 0 had a `(17,4,10,1)` strip above its `(11,11,25,61)` body. Cropping away the visible islands alone would not restore the clipped boots or correct the undersized body.

All 72 runtime locomotion cells were inspected for alpha components and bounds. Founder and Theo did not have detached row bleed: their accidental equal-quarter cuts happened to lie in gutters. They still shared the fragile exporter and inconsistent directional body envelope.

## Measured export

`dev/tools/build_locomotion_assets.sh` now owns only the three locomotion sheets. The broad polish exporter delegates these three calls to it; all work, seated, furniture, effects, architecture and UI export paths are unchanged.

The dedicated exporter:

1. Retains the existing exterior matte interpretation of the original RGB masters. No source files are overwritten.
2. Measures the transparent row gaps and each row's six horizontal pose bands. It refuses anything except four isolated rows and six isolated poses per row; it never substitutes equal cells.
3. Checks measured row bands against the reviewed source geometry below. Changed masters require renewed review rather than silently changing crop topology.
4. Uses a fixed full-row vertical crop and a common uniform scale per direction to a 68px body envelope. No limb stretching or frame-specific fit scale is applied.
5. Uses one shared 48-color palette per actor, binary alpha and head-center registration at x24. Export cells remain 48×80 with the foot plane at y72. Original walking foot lift is bounded to one pixel instead of trimming every frame to a new baseline.
6. Refuses content wider than the existing 44px envelope, edge clipping and any detached opaque component. It replaces runtime files only after all three sheets pass those checks.

Measured row bands as `(top,height)` after prepared-source trim:

| Source master under `game/assets/source/polish/` | Prepared dimensions | Row bands |
| --- | --- | --- |
| `founder-locomotion-master.png` | 1120×918 | (0,219), (240,213), (477,208), (709,209) |
| `mira-locomotion-master.png` | 1066×950 | (0,238), (256,231), (505,213), (735,215) |
| `theo-locomotion-master.png` | 1060×901 | (0,215), (235,212), (469,206), (692,209) |

Horizontal pose bands are measured independently in each row, preserving asymmetric arm/foot reach. The command reports all 72 source crop rectangles and integer head offsets.

## Intentional visible differences

- Mina's west/east body is now 68px tall, not the defective 59px/61px main component. Complete boots are restored from the original master.
- Founder and Theo's profile rows are normalized to the same physical-height envelope as their front view. All 72 bodies are 66–68px high; the two-pixel total range reflects the unchanged source pose silhouettes, not arbitrary runtime scaling.
- Head-region top is y4 or y5; integer head center is x24 in every cell. Odd-width silhouettes can have a half-pixel geometric center difference, but there is no fractional render transform.
- Last opaque foot row is y70 or y71. Logical foot origin, actor navigation, collision, reservations, sprite transform and all runtime frame indices are unchanged.
- Shared palettes and registration intentionally change some existing pixels. Old screenshots are **pre-fix evidence**, not a byte-identical baseline to enforce.
- No seated/work sprite, shadow, portrait master, actor protocol, job state or art-capability registry changed. Existing small face crops continue to reference the corrected native front row.

## Native evidence

All evidence below is under `game/tests/output/locomotion-export/`:

- `founder-before.png`, `mira-before.png`, `theo-before.png`: copies of the actual runtime sheets before repair.
- `all-native.png`: all 72 corrected frames together, 864×320, inspected without rescaling.
- `founder-native.png`, `mira-native.png`, `theo-native.png`: individual 288×320 exports.
- `founder-4x.png`, `mira-4x.png`, `theo-4x.png`: nearest-neighbor pale-background inspection sheets. All three actors and every frame were inspected at native scale and 4×.
- `four-desks-standing-before.png` and `four-desks-standing-after.png`: actual 1280×720 office showroom captures, preserving the same scene and approach positions.
- `results-headless.json`: per-frame opaque/head bounds, component counts, palette/alpha results and assertion count.

The rendered after image was inspected at 1280×720. The west-view reference at logical foot `(976,304)` no longer has disconnected brown pixels above the bun; the east-view reference at `(400,304)` is also clean. The south and north references retain complete silhouettes. The showroom's desks remain staged candidates: this standing reference is not a seated hand/table or chair-layer acceptance test.

## Verification

| Check | Result |
| --- | --- |
| `bash dev/tools/build_locomotion_assets.sh --check` | Passed: actual source gutters, 72 isolated cells, all three generated files byte-identical to runtime; no runtime writes in check mode |
| Godot headless import | Passed, exit 0 |
| `test_locomotion_export.gd` | **545 checks, 0 failures** |
| `test_workstation_facing.gd` | **249 checks, 0 failures** |
| `test_graphics_regressions.gd` headless | Passed; rendered-only branches are covered separately only where stated |
| `tests/run_all.gd` headless | Passed |
| `tools/validate_project.gd` | Passed |
| `tools/capture_furniture_rotations.gd` rendered | Exit 0; three captures saved and standing result inspected |
| Shell syntax / `git diff --check` | Passed |

The pixel regression checks actual imported production pixels against exported PNG content, not just dimensions. It checks exactly one 8-connected silhouette in every cell, binary alpha, shared palette, distinct frames, native dimensions, padding, body-height envelope and head/foot stability. An in-memory diagnostic fixture inserts detached above-bun pixels and proves the detector rejects them. The original test's temporary `up` vs runtime `back` naming mismatch was corrected in the new test only; no production API or existing test assumption was changed.

Final runtime SHA-256 values:

- Founder: `b71e8de36d7f1628b47795a223b344dc12da49ab5b6caf39070d51f2f6e7e2dc`
- Mina: `bf59c1b6c0f6e0162bcf4a8100740ec7082af598c9dcb05b4a2d000d6c178889`
- Theo: `2c68e0313f47a29a3b025b77fbe4dad4fc3cca8688382591e04787a8ec23cb2d`

No ImageGen call was used for this repair. No worker, credential, saved company, backend dependency, commit or push was involved. Broader motion and final production office captures remain with the main goal's integration review.
