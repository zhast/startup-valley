# Quiet call booth — v3 bounded passive acceptance; v1/v2 remain rejected

September 6, 2026. Revision `phone-booth-v1`. This is independently authored
editable code-native art, not a generated source and not a production change.
The main agent has inspected native isolated and actual-room four-view sheets.
Independent review now confirms a **v1 visual failure**: perspective1,
silhouette2, pixel3, layers3, direction2, placement3, mean2.33. The large cream
roof is framed like another upright panel, so the booth reads as stacked
cabinet panels despite its valid floor geometry. V1 is cleanup-required, not
approved. Its exact builder and capture are preserved as
`phone_booth_v1_geometry.gd` and `capture_phone_booth_v1.gd`.

The second `phone-booth-v2` candidate also failed independent isolated review:
its plain chamfered beige cap still reads as a separate stacked panel despite
99 passing export checks. It was not replayed in the room. Its exact builder
and capture are preserved as `phone_booth_v2_geometry.gd` and
`capture_phone_booth_v2.gd`, and its outputs remain at `phone-booth-v2`.

The current builder produces **v3**, with an explicitly smaller physical2×2
footprint (64px top plane),120px vertical rise, same256×416canvas/pivot, a
muted cap matching the shell and continuous full-width roof/body junction.
This is not a compressed bitmap over the former3×3collision mask. Its original
1783/0 export and1895/0 clean actual GameMain replay prove the revised mask,
continuous full-width junction, four blocked physical cells, wall rejection,
native scale/depth and safe founder external approach. An acceptance-safe
historical/current-mask assertion later adds four checks:1787/0 headless, with
no source-pixel change. The updated harness preserves the original nine-cell
contract as explicit history while requiring the current four-cell mask exactly
after library admission.

Root and an independent agent inspected isolated/native-room four-view sheets
and enlarged evidence. **Accept v3 as closed passive library art only**, scores
pixel3/perspective2/silhouette2/layers3/direction2/placement3 = **2.5**,minimum2.
The physical cap/body join and scale now work. South glazing and the shallow
interior shelf provide the clearest booth identity; opaque North/East/West
remain cabinet-like, so this is intentionally a borderline pass, not a
premium/iconic silhouette claim. No entry, interior pose, calling, service,
new employee, runtime binding or default placement is authorized by this review.

V3 evidence lives under `game/tests/output/phone-booth-v3/`: native and4×
actual-room contact sheets, full1280×720 South frame and all four direction
frames. Exact files are under `game/tests/fixtures/furniture-calibration/phone-booth-v3/`.
V1's entire rejected catalogue record is preserved as
`dev/art-catalogue/phone-booth-v1-rejected-registration.json`. V2 source,
manifest and isolated evidence also remain intact.

## Preserved v1/v2 contract (not the v3 compact candidate)

The original 256×416 canvas, `(128,304)` floor pivot, nine-cell rotating 3×3
footprint and cardinal doorway approaches are preserved. The solid closed
booth has a 112 px vertical elevation above its floor plane; the 96 px deep
roof follows the same screen-axis floor projection as the approved furniture.
The registered whole is 88×209 visible pixels within the larger alpha canvas.
Its 192 px planned maximum-rise envelope is retained as historical geometry.

Five exact native layers keep the floor contact, interior/shelf, glazing,
rear shell/roof and front shell reusable. Glazing contains binary clear pixels
and small edge/reflection marks, not a checkerboard or translucent matte.
South reveals the glazed doorway and shelf. North shows the opaque rear; East
and West show acoustic sides and narrow door edges. Interior and glass are
intentionally hidden by the corresponding opaque shell in those views.

This is a **closed passive furnishing**. The nine-cell footprint is solid;
there is no enter-booth action, interior navigation, new pose, phone service,
employee role, provider, worker, database or save behavior.

## Iteration and verification

- First internal canopy drawing looked like stacked upright panels. It was
  replaced before approval by an explicit pale roof plane with shallow seams
  and a small direction-specific vent. No source bitmap was edited.
- Export/structural gate: **99 checks / 0 failures**. It verifies original
  canvas/pivot/masks/approach, true alpha, protected margins, five nonempty
  layers, exact reconstruction, distinct views and no mirrored whole.
- Initial native fixture printed **229 / 0** but emitted an initialization
  error: its provisional spawn overlapped the reserved aisle. This is **not**
  treated as a clean native pass. The fixture now finds and validates a common
  safe pivot before asking TownRoom to construct anything.
- Corrected v1 actual GameMain/TownRoom run: **231 checks / 0 failures**, no
  initialization error. Four-way commits, exact native layer transforms/depth,
  nine blocked navigation cells, wall/corner rejection with exact rollback,
  founder path safety to each external doorway viewpoint, 1280×720 captures
  and owner-permit revocation pass. Production files remain byte-exact.
  The per-direction `actual-room-results.json` snapshot is written earlier and
  records227 checks; the final `results.json` checkpoint records230 before its
  own file-open assertion, and the terminal total231 includes that assertion.
  These are different checkpoints, not three separate complete test runs.

## Evidence

- [Native candidate sheet](../../game/tests/output/phone-booth/candidate-contact-sheet-native.png)
- [Native actual-room sheet](../../game/tests/output/phone-booth/actual-room-contact-sheet-native.png)
- [Nearest 4× room sheet](../../game/tests/output/phone-booth/actual-room-contact-sheet-4x.png)
- [Full South game frame](../../game/tests/output/phone-booth/actual-room-south.png)
- [Exact manifest](../../game/tests/fixtures/furniture-calibration/phone-booth-v1/manifest.json)
- [Native results](../../game/tests/output/phone-booth/results.json)
- [Per-direction observations](../../game/tests/output/phone-booth/actual-room-results.json)

The founder can be naturally occluded behind the tall closed shell; this is
not entry into the booth. The present scope proves external approach and
layer ordering only. Visual approval must address the roof/front-plane
readability and restrained material detail at native size before catalogue
approval. Do not infer a production-ready interactive booth from these tests.

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_phone_booth.gd -- --export-only
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_phone_booth.gd
```
