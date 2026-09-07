# Mobile whiteboard — native geometry and room study

Reviewed 2026-09-04 10:03 UTC. **Dev-only prototype; not a new production family, service or approved asset.**

## Outcome

The agreed physical model works as a stable, registered four-direction object in an actual two-employee GameMain room. The blank South face and the optional V3 planning face fit the frame without a differently colored inset, broken box edge, resampling seam or canvas shift. The diagram remains readable at native size: three linked boxes, two notes and a check mark. The North face is the structural powdercoat rear; it does not falsely show the hidden planning art.

The East and West views are genuinely thin edges. Their opposing trays, fixed-screen lighting and long ground-axis footprint are consistent with the same board, but the 4px edge has weak standalone identity: at a glance it looks like a narrow metal divider or post. This is an honest visibility limitation, not permission to rotate the wide South bitmap or show front notes through its back. South is the clearest default viewing orientation if this prop is later admitted.

The frame and supports are intentionally quiet code-native geometry. The caster blocks are still square and schematic, particularly at 4×; the current exports establish contact and dimensions rather than a final decorative wheel design. No writing pose or board action is implied by the planning insert.

**The integration boundary remains open:** the current canonical editor/factory has no noninteractive visual-orientation family profile. The prototype therefore adds its physical collider and occupied cells only to one disposable scene. It does not borrow an archive ID, pretend to be a service, mutate a catalogue, add persistence, or expose an action. This is the deliberate stopping point requested for this study, not proof of production editor readiness.

## Exact source and layer contract

The [measured contract](MOBILE_WHITEBOARD_CONTRACT.md) records all rectangles and visibility rules. In brief:

- Every layer uses **192×224**, pivot **(96,160)** and centered sprite offset **(0,−48)** at native 1× with nearest filtering. Nothing is rotated, mirrored, independently trimmed or stretched.
- The board is **88×56**, rise **80**, lower edge rise **24**, thickness **4**. N/S occupied floor is **96×32**; E/W is **32×96**.
- Native opaque union: N/S **(48,78,96,98)** in the registered canvas; E/W **(80,36,32,172)**. The tall side projection includes physical ground-axis width, not an invented 172px vertical rise.
- Seven registered layers: `GroundBase`, `RearSupports`, `FarTray`, `BoardFrame`, `FaceInsert`, `NearTray`, `NearSupports`. All retain the host floor-sort depth; whole actors retain physical-foot sorting.
- All 28 blank layer exports, four reconstructed whole views, four nearest 4× exports and the separate South planning whole are under [mobile-whiteboard-v1](../../game/tests/fixtures/furniture-calibration/mobile-whiteboard-v1/): **37 PNGs**. These are code-native prototype exports, not 37 generated images or approved runtime textures.
- The separate optional [V3 planning source](../../game/tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png) is copied byte-exactly into **(56,86,80,48)**. No other layer changes. It is rejected for N/E/W.
- Its measured **#F4F1ED** substrate matches the blank field. The supplied native RGB image is not falsely described as literal #F1F1F1. The source master, V1/V2 failures and all parent-owned prompt/builder history remain untouched. No ImageGen call was made in this task.
- The North rear reuses the existing [charcoal powdercoat material](../../game/tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png). Frame geometry and tiny tray marker bars are authored by the dev helper, not manufactured source provenance.

## Native evidence reviewed

All 61 checkpoints were reviewed at native pixel scale in four unscaled room-region contact sheets. These contain the entire actor/board vicinity, not scaled thumbnails. Full native room views were also inspected for all four base orientations, the South planning face, the narrow-edge crossing and the nearby actor pass. The optional planning face and all four registered blank exports were inspected at 4×. This is saved-image review plus deterministic motion evidence; it is not a claim that every movie frame was manually watched.

- [Actual N/E/S/W native comparison](../../game/tests/output/mobile-whiteboard/all-four-native.png)
- [North sequence](../../game/tests/output/mobile-whiteboard/north-review-contact.png), [East sequence](../../game/tests/output/mobile-whiteboard/east-review-contact.png), [South sequence](../../game/tests/output/mobile-whiteboard/south-review-contact.png), [West sequence](../../game/tests/output/mobile-whiteboard/west-review-contact.png). Read left-to-right in manifest order; each crop is 256×352 from native world rectangle (656,224). The South sheet has one additional planning frame.
- [South planning, actual room](../../game/tests/output/mobile-whiteboard/south-planning.png) and [nearest detail](../../game/tests/output/mobile-whiteboard/south-planning-4x.png). Board bounds approximately **(736,350)–(832,448)**; new diagram occupies **(744,358)–(824,406)**.
- [North crossing](../../game/tests/output/mobile-whiteboard/north-founder-walk-017.png), [East crossing](../../game/tests/output/mobile-whiteboard/east-founder-walk-017.png), [South crossing](../../game/tests/output/mobile-whiteboard/south-founder-walk-017.png), [West crossing](../../game/tests/output/mobile-whiteboard/west-founder-walk-017.png). Side board union approximately **(768,308)–(800,480)**.
- [Final manifest and source hashes](../../game/tests/output/mobile-whiteboard/manifest.json), [headless results](../../game/tests/output/mobile-whiteboard/results-headless.json), [actual movement recording](../../game/tests/output/mobile-whiteboard/mobile-whiteboard.avi).

The native sheets show founder movement behind the board, Mina passing in front of the base, and Theo navigating around the blocked base toward the north side. They use the actual actor sources and existing movement methods, not captured characters composited onto a static room. The founder route is dispatched by real mouse motion and button down/up events; employee routes use their existing `walk_to` behavior. The fixed scene contains no new board UI prompt, hit target or generated fake writing animation.

## Verification and limits

| Check | Result |
|---|---|
| Final focused headless suite | **1,628 checks, 0 failures** |
| Final native rendered suite | **1,972 checks, 0 failures** |
| Native opaque actor-pixel comparisons | **242,954**, no mismatches |
| Existing movement/collision steps | **700**, all physical feet remain safe and bodies pixel-snapped |
| Native checkpoints | **61**; **96 harness PNGs** plus four native review contacts = **100 evidence PNGs** |
| Movie metadata independently checked | **1280×720, 30 FPS, 872 frames, 29.066667 seconds** |

The pixel test composes each real source cell, board and nearer actor by their actual floor depth. At the exact crossing checkpoint, the board correctly hides **301 founder pixels in each N/S view** and **204 in each E/W view**. Mina/Theo screen-space overlap is also modeled rather than skipped. The check is about opaque source pixels at saved checkpoints, not a universal guarantee about every UI, shadow or intervening movie pixel.

The geometry suite asserts binary alpha, zero hidden RGBA padding, exact occupied masks, full-canvas layer registration, distinct tray locations, fixed upper-left light, exact PNG reopen/reconstruction and exact optional insert ownership. The far North tray is present but fully hidden by the rear panel, verified by byte-identical whole output when that tray is removed.

Board ink and a conservative 48×80 visitor envelope are separately tested against actual room floor/architecture. At x112, proposed upper-left placements first fit at **y208 for N/S** and **y240 for E/W**; one row nearer the top wall fails, as does left-wall overhang. These are geometry tests, **not canonical editor preview/rotation tests**. The rendered prototype remains at (784,432); a rendered near-wall placement batch was not part of this bounded run.

Every fresh scene uses the null transport before entering the tree; no worker process or pipe starts. No worker bootstrap is loaded, and production JSON/floor/material/insert hashes remain unchanged across the run. A separate ordinary scene proves the extra navigation obstacle and synthetic prop do not leak after teardown. Production archive changes already present from earlier accepted work were not authored by this task.

### Preserved diagnostic findings

1. The initial founder target (880,368) fell inside the existing approval console's actual hit bounds. The real click correctly selected that station, so the intended free-ground path assertion failed. The **dev target** was moved to (848,368), and the fixture now asserts that no pending station interaction was created. This was a fixture-target mistake, not a production input fix.
2. The first native batch reported four six-pixel mismatches where Theo's nearer head covers Mina's shoes. The initial expected-image model considered only board occlusion. It now includes all three source actors and floor depths without ignoring those pixels. The failed first batch remains at [mobile-whiteboard-initial](../../game/tests/output/mobile-whiteboard-initial/). No actor or source art was changed to make it pass.
3. Saved checkpoints initially bracketed the 4px side edge. A precise crossing checkpoint was added, and each direction now must contain actual opaque board/actor occlusion. This strengthened coverage rather than inferring depth correctness from empty overlap.

## Reproduction and next decision

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_mobile_whiteboard.gd -- \
  --planning=res://tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png

godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/mobile-whiteboard/mobile-whiteboard.avi \
  --script res://tests/test_mobile_whiteboard.gd -- \
  --planning=res://tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png
```

Implementation: [geometry helper](../../game/tools/mobile_whiteboard_geometry.gd), [isolated capture](../../game/tools/capture_mobile_whiteboard.gd), [focused test alias](../../game/tests/test_mobile_whiteboard.gd).

The next decision is whether to accept this physical model and the simple frame aesthetic, then explicitly scope a noninteractive prop profile/factory path. If a more authored caster silhouette is wanted, it should preserve these proven registration/contact dimensions. Do not regenerate the entire room, redraw invisible side notes, claim a service exists, or mark this prototype production-ready based on passing geometry counts alone.
