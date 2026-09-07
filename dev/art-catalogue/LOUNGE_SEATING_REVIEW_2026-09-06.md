# Lounge seating — passive native-art review

Date: **2026-09-06**\
Scope: **one two-seat sofa and one lounge armchair as bare passive art-library
objects only**. This review does not add a seat socket, Sit action, reservation,
actor pose, break behavior, worker authority, persistence, production catalogue
binding, or default-room placement.

## Disposition

The `two_seat_sofa` v3 and `lounge_armchair` v3 pass the bounded passive
art-library proposal gate. They are visually distinct from the ergonomic task
chair: the sofa is a blue-gray three-by-two upholstered body with two readable
cushion divisions; the armchair is a rust two-by-two club/wing silhouette. Both
use short wooden supports and small down-right contact marks, with no caster,
gas-lift, broad dither mat, baked actor, tool, cup, or text.

| Family | Pixel | Perspective | Silhouette | Layers / anchors | Direction | Placement | Mean | Proposed result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Two-seat sofa v3 | 3 | 2 | 2 | 3 | 2 | 3 | **2.50** | Pass as passive art-library object |
| Lounge armchair v3 | 3 | 2 | 2 | 3 | 2 | 3 | **2.50** | Pass as passive art-library object |

The score-2 limits are visible. Both objects use deliberately simple, flat
code-native upholstery, so their side silhouettes communicate less material
depth than the South faces. A sofa oriented on the screen Y axis combines
its 96px floor depth with a 60px elevation in the fixed screen-aligned
orthographic projection, so E/W reads much taller and narrower than N/S. It is
physically consistent and retains the side back, arm, seat and lower base, but
the sofa's side silhouette is less immediately legible than its two-seat face.
The armchair has the same projection constraint at a smaller 64px depth and
52px rise. The rear/front identity is now real, but the elongated sides and
simple upholstery keep both direction-consistency scores at 2. No score is
raised merely because an invariant test passed.

## Rejected v1 and v2 history

The first isolated v1 drawings remain at
[`lounge-seating/`](../../game/tests/output/lounge-seating/), with exact layers
under `two-seat-sofa-v1` and `lounge-armchair-v1`. N/S feet were visibly
detached from the upholstered bodies by roughly 8–14 transparent rows, and the
tiny contact marks were separate alpha islands. That is rejected construction,
not an acceptable floating-shadow style.

The support-only v2 study remains at
[`lounge-seating-v2/`](../../game/tests/output/lounge-seating-v2/) with exact
layers under `two-seat-sofa-v2` and `lounge-armchair-v2`. It restored a compact
lower upholstered base and joined short supports/contact marks. However, v2
still used the same seat/back/arm geometry for North and South, changing mainly
color and one seam. Its claimed North rear was therefore a recolored front.
Its E/W top edge also sat only about 6px above the far floor coordinate despite
a declared 60px sofa rise. The otherwise clean
[`lounge-seating-v2-room-review/`](../../game/tests/output/lounge-seating-v2-room-review/)
is preserved as rejected directional evidence.

V3 makes the substantive corrections in
`game/tools/lounge_seating_geometry.gd`:

- North has a narrow raised backrest top and opaque near rear shell; it no
  longer exposes the South seat inset.
- South retains the readable seat, cushion, arms and front lower base.
- E/W are independently authored on the fixed screen axes. Their used top is
  exactly `floor.position.y - rise`, and the full physical floor depth is
  carried through the raised back/seat projection.
- Far supports are behind the upholstery, near supports remain in the front
  layer, and all structure/contact pixels form one eight-connected silhouette.

No finished composite was rotated, mirrored, flipped, stretched, or scaled to
make another direction.

## Geometry and deterministic exports

| Family | Canvas / pivot | Sprite offset | Footprint | Declared rise | Layers |
|---|---|---|---|---:|---|
| `two_seat_sofa` | 192×224 / [96,144] | [0,-32] | N/S 3×2; E/W 2×3 | 60px | `floor_shadow`, `rear_structure`, `front_structure` |
| `lounge_armchair` | 160×208 / [80,128] | [0,-24] | 2×2 | 52px | `floor_shadow`, `rear_structure`, `front_structure` |

The exporter passed **144 checks / 0 failures**. Every layer is binary-alpha,
has no hidden RGB, stays on its registered native canvas/pivot, and reconstructs
the whole in declared order. The focused structural/admission suite passed
**293 / 0** after import. It verifies exact exports, masks, protected padding,
one connected support silhouette, the E/W floor-relative rise, owner-scoped
decorative admission/revocation, wall/corner rejection, absence of invented
interaction/seat/service fields, and no production-catalogue leakage.

## Native actual-room evidence

The final disposable `GameMain` evidence is
[`lounge-seating-v3-final/`](../../game/tests/output/lounge-seating-v3-final/):
**287 checks / 0 failures, 68 PNGs**, 1280×720, worker disabled, no save or
personal bootstrap state. It covers all four directions, native crops,
nearest-neighbor 4× details, exact layer transforms/collision shapes, no action,
wall/corner rejection, paths around both South footprints, and standing actor
depth/scale samples.

Useful inspection anchors:

- [North room](../../game/tests/output/lounge-seating-v3-final/lounge-pair-north-room.png)
  shows two opaque rear shells with no false front-seat inset.
- [South room](../../game/tests/output/lounge-seating-v3-final/lounge-pair-south-room.png)
  shows the readable sofa cushions and armchair seat.
- [East room](../../game/tests/output/lounge-seating-v3-final/lounge-pair-east-room.png)
  and [West room](../../game/tests/output/lounge-seating-v3-final/lounge-pair-west-room.png)
  show the taller, floor-depth-plus-rise side projection at native scale.
- [East sofa behind at 4×](../../game/tests/output/lounge-seating-v3-final/two_seat_sofa-east-founder-behind-4x.png)
  and [West armchair front at 4×](../../game/tests/output/lounge-seating-v3-final/lounge_armchair-west-mira-front-4x.png)
  exercise real actor/prop surface ordering.

V3 naturally produces 333–1,250 opaque actor/prop overlap pixels in fourteen
front/rear samples with zero wrong-depth pixels. The two North-behind samples
are truthful safe-clearance cases with zero overlap: moving the actor down 12px
inside the same nominal cell was explicitly rejected by
`position_is_safe`, so the final evidence does not manufacture an occlusion.
North front, South front/rear and E/W front/rear supply the actual depth proof.
The preserved first v3 run at
[`lounge-seating-v3-room-review/`](../../game/tests/output/lounge-seating-v3-room-review/)
reported **287 / 4** only because it carried v2's stale overlap classification;
the pixels and geometry were unchanged for the final classification rerun.

## Acceptance boundary

The companion
[`lounge-seating-registration.json`](lounge-seating-registration.json) proposes
complete art-library records with exact layer/composite hashes. Runtime paths
remain null. Existing founder/Mina sprites are standing scale and occlusion
probes only; this review does not approve sitting in either object, two-person
occupancy, pose transitions, reservations, arrivals, actions, or gameplay.
