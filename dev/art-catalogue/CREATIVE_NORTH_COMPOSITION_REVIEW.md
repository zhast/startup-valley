# Creative north: actual-room composition review

Status: **staged composition candidate, not runtime-approved**. This study uses only existing generated sources. No image-generation request, production registration, save access, worker call, or new character capability was added.

## Decision

Prefer **tablet + monitor, tablet resting on the left** for an idle creative workstation. It preserves the recognizable computer-workstation silhouette while keeping the tablet, camera, and color fan visible. The tablet replaces the keyboard and mouse; neither remains hidden beneath it.

Reject the centered tablet for occupied readability: Mina obscures 329–331 of its 338 opaque pixels, and Theo obscures 304–305. The centered unoccupied layout looked reasonable, demonstrating why a room/character composition review is necessary. This failed control is preserved in the evidence, not counted as an approved layout merely because its expected-failure assertions pass.

The tablet-only alternative is uncluttered, but the idle employee faces an empty center. It reads better as a resting/hobby station than as evidence of active drawing. **No captured pose is a stylus-use animation.**

## Exact composition

All values below are native screen pixels relative to the desk's floor pivot. The original 192×224 device canvases retain their `(96,160)` pivot; objects are translated without stretching, flipping, rotating, repainting, or changing alpha.

| Part | Preferred opaque bounds | Translation from original registered kit |
|---|---|---|
| Tablet + parked stylus | `Rect(-43,-40,24,15)` | `(-30,-7)` |
| Color swatch fan | `Rect(28,-30,12,12)` | `(66,2)` |
| Camera | `Rect(28,-43,12,12)` | `(0,-2)` |
| North monitor | `Rect(-16,-73,33,30)` | `(0,-10)` |

The exact soft modular north desk has tabletop `Rect(-48,-48,96,32)`. Its actual wood-fill interior is `top.grow(-2)`, or `Rect(-46,-46,92,28)`. Tablet, camera, and fan fit wholly inside that interior. The camera/fan have one empty bounding-box row between them. The monitor's tall silhouette extends above the tabletop, as intended; only its actual support rows must lie on the surface.

An initial parked composition put the swatches against the near rim despite passing a broad tabletop-bound check. Native and 4× review caught this. The final fixture moves both right-side objects two pixels upward and checks against the **painted wood interior**, excluding the shade/outer rail. It does not use the large transparent source canvas as a support bound.

The comparison uses the latest supported north scale sockets, unchanged by this study:

- Logical work feet: host `(0,32)`.
- Chair: 12 px north of logical feet, host `(0,20)`.
- Mina: 8 px north of chair, host `(0,12)`.
- Theo: 4 px north of chair, host `(0,16)`.
- Native 48×80 character frames, pivot `(24,72)`; only seated-idle frames 0 and 1 are shown.
- Existing north chair and per-character north sources remain provisional references, not a newly approved common socket or production direction.

## Measured clearance

The preferred tablet has **0/338 opaque-pixel overlap with either employee in both idle frames**. The camera and fan have zero overlap with each other, other opaque devices, the conservative wrist boxes, and actual arm ink. All device pairs have zero opaque intersections.

The parked tablet intersects the deliberately conservative wrist boxes by 22 pixels for Mina and 3 for Theo, but intersects zero actual arm ink. This is a clearance observation, **not proof of usable hand reach**: the tablet is resting left, and the idle arms do not perform a drawing gesture.

The tablet's parked stylus remains a small dark bar at this 24-pixel width. Camera controls and individual swatch details are necessarily reduced at 12 pixels. Their role silhouettes read at native size, but this review does not claim miniature labels or functional camera controls are legible.

## Evidence and verification

Harness: `game/tools/capture_creative_north_composition.gd`.

Commands from repository root, using `/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot`:

```sh
STARTUP_VALLEY_NO_WORKER=1 "$GODOT" --headless --path game --script res://tools/capture_creative_north_composition.gd
STARTUP_VALLEY_NO_WORKER=1 "$GODOT" --path game --fixed-fps 30 --script res://tools/capture_creative_north_composition.gd
```

The commands were run with the executable path resolved explicitly; `GODOT` above is a documentation shorthand.

- Headless: **352 checks, 0 failures** (`results-headless.json`).
- Rendered: **857 checks, 0 failures**, process exited 0 (`manifest.json`).
- **43 PNGs**: seven native 1280×720 views and 36 nearest-neighbor 4× crops (640×580).
- Source image hashes remain unchanged; all sprites and desk geometry stay at scale 1.
- Caption geometry and native viewport bounds are checked. No caption covers an actor or device.
- No movie was needed: this is an idle-endpoint composition study, not an invented interaction-animation demonstration.

Outputs live in `game/tests/output/creative-north-composition/`:

- `parked_left-idle-frame0.png` and `parked_left-idle-frame1.png`: preferred candidate, both actors and all three options.
- `parked_left-unoccupied.png`: visible object spacing and monitor support.
- `centered-idle-frame0.png`, `centered-idle-frame1.png`, and `centered-unoccupied.png`: retained failure comparison.
- `clearance-guides.png`: desk, wrist and object bounds.
- `parked_left-idle-frame{0,1}-{mira,theo}-option1-4x.png`: preferred candidate's per-actor endpoint detail.

Native review opened all seven final full-size images. Enlarged review opened the four preferred actor/idle details, the centered Mina failure control, the preferred unoccupied monitor composition, and the Mina tablet-only alternative. The remaining 29 crops were generated but were not individually opened; both endpoints and both actors are visible in the seven reviewed native views and covered by the deterministic geometry checks.

## Remaining gates

1. A genuine pen-reach/turn pose and matching interaction would be required before presenting this resting arrangement as active tablet work. Existing typing frames were intentionally not used.
2. North is the only authored toolkit view here. East/south/west are still separate art tasks; no view is inferred by mirroring this source.
3. The staged north chair/actor support convention, toolkit camera angle, and tiny stylus readability still require the broader furniture-family acceptance decision.
4. Runtime rotation profiles, catalogue approval, furniture placement, worker capabilities, and saves are unchanged.
