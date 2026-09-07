# Compact desk and shared workbench — base-only review

Date: 2026-09-06\
Reviewed revisions: historical `compact-desk-v1` / `shared-workbench-v1`, then shadow-only `compact-desk-v2` / `shared-workbench-v2`\
Scope: reusable bare furniture bases only\
Verdict: **both v2 bundles meet the base-library visual threshold; neither is a complete workstation or production registration**

## Why the old 2.17 scores were too broad

The v1 reviews correctly established four screen-space drawings, native anchors,
collision, walls, navigation, layer reconstruction and passive visible-surface
picking. Their visual scoring then charged the bases for missing chairs, devices,
role tools, seated actors and work lifecycles. Those are explicitly separate
owners in each base's overlay contract and are not required pixels in the base's
three deliverable layers:

- `floor_shadow`
- `rear_structure`
- `front_structure`

An empty tabletop does not need role identity. A passive base also does not need
to prove seated animation or job behavior before its furniture pixels can be
reviewed. Those gates still apply to any future *assembled workstation*.

## The genuine defect and bounded repair

The old ordered-dither floor shadow was a real base-art defect. At native size it
read as a suspended wire basket or mesh between the legs, and the East/West
workbench version became a visually dominant long checker wedge. This was not an
attachment problem.

The v2 review keeps every rear/front structure pixel, canvas, pivot, sprite
offset, footprint, clearance cell, collision rule and overlay owner byte-exact.
Only `floor_shadow` changes. A fixed upper-left light now produces three tiny
screen-down/right contact marks at each authored structure-ink foot/support. The
marks are binary-alpha, remain inside the declared floor footprint and do not
form a broad lattice.

Measured opaque shadow reduction:

| Family | North | East | South | West |
|---|---:|---:|---:|---:|
| Compact desk | 344 → 32 | 344 → 32 | 344 → 32 | 344 → 26 |
| Shared workbench | 932 → 60 | 2,332 → 36 | 932 → 60 | 2,332 → 80 |

The different end-on workbench counts follow its independently authored visible
supports; they are not rotated or mirrored copies.

Evidence:

- [Compact v1/v2 nearest comparison](../../game/tests/output/base-furniture-review-2026-09-06/compact_desk-before-after-4x.png)
- [Workbench v1/v2 nearest comparison](../../game/tests/output/base-furniture-review-2026-09-06/shared_workbench-before-after-4x.png)
- [Compact v2 in the real room](../../game/tests/output/base-furniture-review-2026-09-06/compact_desk-actual-room-base-native.png)
- [Compact with native actor scale](../../game/tests/output/base-furniture-review-2026-09-06/compact_desk-actual-room-actor-native.png)
- [Workbench v2 in the real room](../../game/tests/output/base-furniture-review-2026-09-06/shared_workbench-actual-room-base-native.png)
- [Workbench with native actor scale](../../game/tests/output/base-furniture-review-2026-09-06/shared_workbench-actual-room-actor-native.png)
- [Machine-readable export facts](../../game/tests/output/base-furniture-review-2026-09-06/export-results.json)
- [Machine-readable actual-room facts](../../game/tests/output/base-furniture-review-2026-09-06/actual-room-results.json)

The historical v1 fixture directories, reports and screenshots are unchanged and
remain the BEFORE evidence.

## Perspective, width and layer findings

### Compact desk

- The 64×30 North/South top and 30×64 East/West top are consistent with the
  declared 2×1 / 1×2 floor mask. A 30px visible top inside a 32px cell is a
  plausible outlined/inset construction, not a demonstrated width error.
- The side elevations are deliberately boxy, but their legs, front/rear edge and
  upper-left highlight remain readable at 100%. No warped rotation or floating
  contact was found.
- North/South and East/West differences are subtle because this is an unadorned
  base. Their apron, cable bar, light edge and asymmetric pivot registration are
  still independently authored. Stronger role direction must come from optional
  equipment rather than being baked into the generic base.
- Rear/front ownership and prop-relative depth show no defect. The unchanged v1
  tests prove every layer owns visible pixels and reconstructs exactly; the v2
  test proves both structure layers are byte-identical.

### Shared workbench

- The 154×32 North/South top and 28×154 East/West top are consistent with the
  5×1 / 1×5 floor mask. The 28px side width is austere but is not a projection or
  collision mismatch.
- North/South clearly show a long two-bay surface, three supports and a center
  cable well. East/West remain visually similar to a long narrow counter when
  bare. That ambiguity is a real polish limit, scored at 2, but it is not a
  broken base silhouette or a reason to bake two devices/chairs into shared art.
- The previous dominant side shadow was the principal end-on defect and is gone
  in v2. Native room scenes show quiet contact marks without a mesh, stripe or
  false extra component.
- Rear/front depth, five collision cells, three clear standing/bay viewpoints
  and passive surface picking remain valid. No layer ordering defect was found.

## Base-only visual scores

The governing threshold is every category at least 2 and a mean of at least 2.5.

### `compact-desk-v2`

| Gate | Score / 3 | Base-only finding |
|---|---:|---|
| Pixel coherence | 3 | Crisp native oak/charcoal pixels, clean binary alpha and quiet contact marks; the checker-mesh artifact is removed. |
| Perspective | 2 | Physically consistent top/footprint dimensions; intentionally simple boxy side elevation remains a polish limit. |
| Silhouette/readability | 3 | Immediately reads as a genuinely smaller two-cell desk without requiring role equipment. |
| Layering/anchors | 3 | Exact full-canvas floor/rear/front reconstruction, shared pivot and byte-identical structure pass. |
| Direction consistency | 2 | Four valid independent views share materials/light, though opposing bare views are intentionally subtle. |
| Placement | 3 | Four native real-room views and actor-scale contacts pass; preserved v1 wall/corner/collision/navigation/picking evidence covers unchanged geometry. |

Mean: **2.67 / 3 — pass for reusable base-library art.**

### `shared-workbench-v2`

| Gate | Score / 3 | Base-only finding |
|---|---:|---|
| Pixel coherence | 3 | Crisp native materials and binary alpha; the 932–2,332px checker shadow is replaced by sparse contact marks. |
| Perspective | 2 | Long-axis geometry and 32px footprint logic are consistent; end-on surfaces remain visually austere. |
| Silhouette/readability | 2 | N/S clearly read as a two-bay bench; E/W can still resemble a narrow counter until optional devices are attached. |
| Layering/anchors | 3 | Exact floor/rear/front reconstruction, full-canvas registration and unchanged structure pass. |
| Direction consistency | 2 | Four independently authored material/light views pass; bare opposite views remain subtle. |
| Placement | 3 | Four native real-room views and actor-scale contacts pass; preserved v1 five-cell collision, dual-bay route, wall and picking evidence covers unchanged geometry. |

Mean: **2.50 / 3 — minimum pass for reusable base-library art.**

No catalogue status was changed by this review. “Pass” means the exact v2 base
bundle can legitimately be considered for the base-art library; it does not mean
runtime/default-room admission.

## What still requires separate work

The following are not defects in either accepted base-art scope:

1. Compact chair fit, device/role placement, seated/typing poses and mount/leave
   transitions before `compact_desk` can act as a workstation assembly.
2. Two compatible chairs, two devices, two role overlays, two-actor reservation
   and shared work lifecycle before `shared_workbench` can act as a workstation.
3. Production catalogue/default-layout decisions, normal office composition and
   migration compatibility for either family.
4. Optional shared-workbench side-language polish if art direction wants stronger
   end-cap or cross-brace recognition without attachments. It is not required to
   validate the current bare base, but the score records the ambiguity.

The v1 bundles should not be promoted because their shadow remains visibly
misleading. The v2 bundles are the only base-only pass candidates from this
review.

## Reproducible verification

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_base_furniture_review_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_compact_desk.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_shared_workbench.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_base_furniture_review_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_base_furniture_review_v2.gd
```

Final focused results:

- v2 export/rebuild: **138 checks, 0 failures**.
- preserved compact v1 structure/admission regression: **259 checks, 0 failures**.
- preserved workbench v1 structure/admission regression: **292 checks, 0 failures**.
- v2 scope/asset/admission test: **161 checks, 0 failures**.
- v2 actual `GameMain` / `TownRoom` native capture: **173 checks, 0 failures**, 38 saved images.

The exporter and native capture hash-check production furniture data, default
layout and the shared art catalogue. No worker, personal save, provider call,
runtime asset, production registration or default layout was used or changed.
