# Visitor chair v2 — shadow-only passive-library review

Date: **2026-09-06**\
Revision: `visitor-chair-v2`\
Scope: **bare passive furniture art only**

## Disposition

`visitor-chair-v2` passes the bounded passive art-library gate. It is a
shadow-only correction of the rejected v1 presentation: the broad dithered
ellipse under the seat has been replaced with small down-right contact marks at
the four already-authored support points. The chair structure, projection,
canvas, floor anchor, sprite offset, collision cell, direction geometry and
optional contact socket remain byte-identical to v1.

This is not a runtime registration, default-room placement, seating action,
reservation lifecycle, actor-pose approval, worker change or save migration.
The production catalogue and layout remain unchanged.

## Before / after finding

The preserved [v1/v2 4× comparison](../../game/tests/output/visitor-chair-v2/v1-v2-before-after-4x.png)
shows the demonstrated defect directly. In v1, a large dithered field plus
solid interior formed a suspended basket between the legs. In v2, only the
authored leg-contact neighborhoods retain floor color. At native size these
read as restrained grounding marks rather than another object below the seat:

- [four bare native views](../../game/tests/output/visitor-chair-v2/actual-room-base-contact-sheet-native.png)
- [four seated views at nearest 4×](../../game/tests/output/visitor-chair-v2/actual-room-seated-contact-sheet-4x.png)
- [four unscaled 1280×720 `GameMain` views](../../game/tests/output/visitor-chair-v2/actual-gamemain-contact-sheet-native.png)

The v2 shadow layers contain **28, 30, 30 and 28** opaque pixels for North,
East, South and West respectively. Each is binary-alpha, carries zero hidden
RGB, remains inside the one-cell floor envelope, touches every authored support
neighborhood, and leaves visible contact pixels after the unchanged rear/front
structure is composed. V1's structure layers are not repainted or rewritten.

## Verification

- Export: **52 checks / 0 failures**.
- Focused structural/shadow regression: **105 checks / 0 failures**.
- Actual `GameMain` / `TownRoom` native capture: **221 checks / 0 failures**.

The focused gate proves that all eight v1 `seat_back` and `seat_front` images
remain byte-identical, only `floor_shadow` changes, all twelve v2 layers rebuild
the four wholes exactly, and no v2 identifier appears in production furniture
or default-layout data. The actual-room gate repeats one-cell collision,
near-wall/corner rejection, alpha picking, safe physical reservation and the
limited existing-Mina standing/seated depth probes in each direction. It starts
no worker and reads no save.

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp binary edges and tiny support-local contact marks replace the rejected dither/solid basket without altering the chair body. |
| Perspective | 2 | Fixed-camera rise and contact remain coherent; the broad orthogonal cushion planes are still intentionally simple. |
| Silhouette/readability | 3 | The low fixed guest seat remains immediately distinct from the caster task chair at native size. |
| Layering/anchors | 3 | Shared 96×144 canvas, pivot `(48,96)`, offset `(0,-24)`, byte-exact reconstruction and rear/actor/front depth all pass. |
| Direction consistency | 3 | Four independently authored chair structures and directional contact points retain fixed upper-left light; no finished view is mirrored or rotated. |
| Placement/contact | 3 | Four actual-room placements, wall/corner gates, one-cell collision and both limited contact probes pass. |

Mean **2.83 / 3**, minimum **2 / 3**: pass for the passive art library.

## Retained limitations

- The seat/back planes remain simple and keep perspective at 2/3.
- Existing Mina seated art is reused only as a scale/depth probe. It does not
  turn this chair into a functional seat or approve a visitor animation set.
- Contact marks are intentionally subtle. They ground the four supports but do
  not simulate a broad ambient or actor shadow.
- V1 evidence is retained as failure history; it must not be relabeled as the
  approved art revision.

Commands from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_visitor_chair_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_visitor_chair_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_visitor_chair_v2.gd
```
