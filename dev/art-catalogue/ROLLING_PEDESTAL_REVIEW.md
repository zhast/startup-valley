# Rolling storage pedestal — four-view native study

2026-09-04 10:17 UTC. **Dev-only candidate, not production admission or a working storage UI.**

## Result

The small pedestal reads as desk-height side storage next to the actual 48×80 actors. The two cream drawers, dark handles, center divider and tiny blue label tab remain distinct at native size. The source's subtle inset edge plus the geometry's 2px charcoal rim look intentional together: no shifted double border, cut-off pull or one-pixel gap was found. No retry of the supplied front is requested by this review.

North is a quiet structural rear. East and West show separately constructed dark side panels with the front-edge seam on the appropriate side, not drawer fronts pasted on every face. Those seams are deliberately subtle at 1×; the side/rear views do not convey a particular role. The stepped casters are readable contact points, but their detail remains simple calibration geometry. The wider side-view wheelbase follows the rotated mount positions inside the same occupied cell; rear caster fragments beside the narrower body are real visible overhang, not floating duplicated drawer handles.

The object stays in contact with the floor through the observed paths, and the cabinet correctly covers a founder walking behind it. Actors crossing in front remain above it. Nothing scales, mirrors, rotates a source bitmap, moves to make an image fit, or clips a frame to the room boundary.

This is **not under-desk storage**: its 32px top rise matches the desk top and no overlapping placement has been enabled. The 48px catalogue rise remains historical proposal data, not a runtime dimension. There is still no canonical selectable pedestal family, storage action or persistence. Those require a separately scoped framework decision.

### Bounded review recommendation

| Category | Score | Scope |
|---|---:|---|
| Pixel coherence | 3 | Native opaque insert, binary-alpha registered layers, no resampling in-room. |
| Perspective | 3 | Body, top and caster mounts exchange floor axes while rise/light stay fixed. |
| Silhouette/readability | 2 | Two drawers clear in South; small caster detail and side seams remain restrained. |
| Layering/anchors | 3 | Shared canvas/pivot, exact layer reconstruction, real actor depth evidence. |
| Direction consistency | 2 | Same physical shell; only South exposes its drawer identity. |
| Placement | 2 | One-cell collision/nav and conservative wall/headroom checks pass in a disposable room; canonical editor admission is not implemented. |

Mean **2.5** for the bounded art/geometry study. This is a recommendation for independent review, not a status change or substitute for missing canonical editor tests.

## Assets and construction

See the [measured contract](ROLLING_PEDESTAL_CONTRACT.md) for exact rectangles and service-side semantics.

- Parent-supplied original: [pedestal-south-front-v1.png](../../game/assets/source/overnight-20260904/kits/pedestal-south-front-v1.png), **1254×1254 RGB**, with adjacent prompt. One initial generation; no retries or generation calls by this task.
- Mechanical builder: [build_pedestal_front.sh](../tools/build_pedestal_front.sh).
- Native insert: [drawer-front.png](../../game/tests/fixtures/furniture-calibration/pedestal-v1/drawer-front.png), **24×24 RGB, 10 colors**. Exact registered South destination **(36,78,24,24)**.
- Canvas **96×144**, pivot **(48,96)**, centered offset **(0,−24)**, nearest 1×. Body floor **28×24 N/S**, **24×28 E/W**, rise **32**, underside rise **4**. One occupied **32×32** cell.
- Four caster mounts rotate physically from **(±11,±13)** to **(±13,±11)**. The source-preserving render origin remains fixed; visible contact ends at host y14 N/S or y12 E/W. Transparent bottom padding is not a floor anchor.
- Exact whole ink bounds in the registered canvas: **(34,52,28,58) N/S**; **(32,50,32,58) E/W**.
- Six layers per view in order: `CasterRear`, `CasterFront`, `Carcass`, `Top`, `NearFace`, `FaceInsert`. All use the same host floor depth. The body naturally hides caster upper sections.
- [pedestal-v1 exports](../../game/tests/fixtures/furniture-calibration/pedestal-v1/) contain **24 registered layer PNGs + four whole views + four nearest details**, separate from the supplied front: **32 prototype exports**, not 32 generated images.
- North/side/top finishes reuse the existing [charcoal powdercoat source](../../game/tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png) with code-native seams, rim and fasteners. No new generated rear/side artwork is claimed. Supplying the South insert to another facing is explicitly rejected.

## Native evidence

All 57 actor/prop checkpoints were inspected in unscaled 256×352 native vicinity sheets, in manifest order. South's full real room and exact label-relayout frame were inspected at 1280×720; the registered views and actual South assembly were inspected at 4×. This is native saved-image review, not a claim of manually watching every movie frame.

- [All four actual-room native views, N/E/S/W](../../game/tests/output/rolling-pedestal/all-four-native.png)
- [South room](../../game/tests/output/rolling-pedestal/south-room.png) / [actual 4× detail](../../game/tests/output/rolling-pedestal/south-room-4x.png)
- [North motion vicinity](../../game/tests/output/rolling-pedestal/north-review-contact.png), [East](../../game/tests/output/rolling-pedestal/east-review-contact.png), [South](../../game/tests/output/rolling-pedestal/south-review-contact.png), [West](../../game/tests/output/rolling-pedestal/west-review-contact.png)
- [Exact narrow-body crossing](../../game/tests/output/rolling-pedestal/east-founder-walk-017.png)
- [Normal live label placement at the initial failed position](../../game/tests/output/rolling-pedestal/south-live-label-relayout.png)
- [Manifest/source hashes](../../game/tests/output/rolling-pedestal/manifest.json), [headless results](../../game/tests/output/rolling-pedestal/results-headless.json), [movement recording](../../game/tests/output/rolling-pedestal/rolling-pedestal.avi)

In the full room the South object occupies approximately **(770,388)–(798,446)**, with the actual generated face confined to **(772,414)–(796,438)**. East/West whole bounds are **(768,386)–(800,444)**. The camera-facing panel becomes narrower, but the padded sprite and floor pivot do not move.

## Verification and explicit limits

- **1,450 focused headless checks / 0 failures.**
- **1,768 focused native-render checks / 0 failures.**
- **225,602 opaque actor-pixel comparisons** against the real source actor/prop/other-actor depth model; no mismatches at saved checkpoints. The exact founder crossing includes **167 pixels hidden by N/S** and **175 by E/W**.
- **628 actual movement steps** remain outside the new occupied cell and other actors, with integer-snapped body transforms. The founder route uses real mouse motion and press/release events. Employee routes use existing `walk_to`; each completes at its target with at least three distinct source gait frames.
- **57 actual native checkpoints, 90 harness PNGs plus four native review contacts = 94 evidence PNGs.** Movie independently checked with ffprobe: **1280×720, 30 FPS, 792 frames, 26.4 seconds**.
- Exact top/body/mount/visitor geometry, independent opposite gaze, full-canvas binary alpha with zero hidden padding, fixed upper-left light, source-only insert ownership and byte-exact PNG reconstruction are asserted.
- Board/actor-style visual safety is measured independently of occupied floor. At x112, first proposed safe architecture/headroom rows are **N208, E176, S144, W176**; one row nearer the top wall and left-wall overhang fail. These are pure geometry checks, not a rendered near-wall or canonical editor acceptance batch.
- Initial full-UI room checkpoints are retained. Geometry motion suppresses only employee nameplates in the disposable fixture; it does not change production UI or actor art. A separate checkpoint re-enables the normal production label-placement pass at the former failed position and proves every visible label avoids all actor envelopes.
- Null transport is installed before the scene enters the tree; no process/pipe starts or worker bootstrap loads. Input does not trigger a station action. The extra collider/navigation mask exists only in the disposable scene; a fresh ordinary scene proves no family/navigation leak. Production JSON, default floor and staged source hashes remain unchanged.

### Initial capture issue retained

The [first batch](../../game/tests/output/rolling-pedestal-initial/) contains eight failed actor-pixel assertions: Mina's stale nameplate covered Theo during her manually stepped route. The inherited capture froze GameMain, so its normal `_update_label_visibility` pass did not run while the actor moved. This was a **diagnostic timing error**, not evidence of a new production label bug. At the same position, calling the real production placement method moves Mina's label safely to her left; six actor-envelope assertions and the full-UI screenshot verify it. No source art or production placement code was changed to pass the test.

## Reproduction

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_rolling_pedestal.gd

godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/rolling-pedestal/rolling-pedestal.avi \
  --script res://tests/test_rolling_pedestal.gd
```

New dev files only: [geometry](../../game/tools/rolling_pedestal_geometry.gd), [actual-room capture](../../game/tools/capture_rolling_pedestal.gd), [test alias](../../game/tests/test_rolling_pedestal.gd), this report and the contract. No existing whiteboard/archive evidence, source master, shared worker/UI/actor behavior, catalogue, save or production family was edited by this study.
