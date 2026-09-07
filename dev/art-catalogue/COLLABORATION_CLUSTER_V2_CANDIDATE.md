# Collaboration cluster v2 — actual GameMain candidate review

Date: September 4, 2026\
Family: `collaboration-cluster-v2`\
Disposition: **the dedicated four-facing multi-actor gate passes; retain as a native-review candidate only**. It is now indexed in the dev planning catalogue as `native_review_required`; it is not production-approved, runtime-registered, or default-layout activated.

## Candidate and boundary

The candidate is a deterministic code-native table-and-four-chair assembly with independently authored North/East/South/West screen-axis profiles. Each profile owns ten collision cells, four clear collaboration sockets, direction-specific component layers, and exact code-owned neutral seated capabilities for Mina (`mira`) and Theo. No finished bitmap is rotated, mirrored, flipped, or scaled.

The review fixture injects those profiles only into a disposable in-memory `OfficeLayout` inside the actual `GameMain` scene. The checked-in production catalogue and default layout remain byte-exact, production continues to resolve `collaboration-table-v1`, and no worker or personal save is used. The shared production v1 standing-service behavior is not replaced by this result.

## Evidence

- [Native actual-room detail contact sheet](../../game/tests/output/collaboration-cluster-v2-actual-room/actual-room-contact-sheet-native.png)
- [2× nearest-neighbor detail inspection](../../game/tests/output/collaboration-cluster-v2-actual-room/actual-room-contact-sheet-2x.png)
- [Native 1280×720 full-room panels](../../game/tests/output/collaboration-cluster-v2-actual-room/full-room-contact-sheet-native-panels.png)
- [Empty-assembly control sheet](../../game/tests/output/collaboration-cluster-v2-actual-room/actual-room-empty-contact-sheet-native.png)
- [Native actual-room result](../../game/tests/output/collaboration-cluster-v2-actual-room/actual-room-results.json)
- [Headless actual-GameMain result](../../game/tests/output/collaboration-cluster-v2-actual-room/headless-results.json)
- [Native component contact sheet](../../game/tests/output/collaboration-cluster-v2/component-contact-sheet-native.png)

The component exporter passes **317 checks / 0 failures**. It verifies deterministic, unscaled, unmirrored direction-specific layers and the existing candidate assembly outputs.

The headless actual-`GameMain` test passes **526 checks / 0 failures**. A deterministic common pivot at grid **(12,14)** validates N/E/S/W at every applicable unlock stage. For each facing the real `TownRoom` creates exactly ten 32×32 collision shapes, navigation blocks the same ten authored cells, all four sockets remain clear and reachable, and Mina and Theo route concurrently from their normal spawn side of the room to the first two deterministic sockets. Both hold distinct endpoint reservations, arrive exactly on their socket centers, and remain at least **115.38 px** apart. Across all four runs there are zero unsafe-footprint samples and zero reservation conflicts.

The native macOS actual-room pass adds pixel and renderer assertions and passes **586 checks / 0 failures**. It captures an untouched **1280×720** `GameMain` frame for every facing plus exact registered 256×272 details. Mina and Theo use inward N/E/S/W gaze as authored, the code-owned `collaboration-cluster-v2:{facing}` capability, native split seated sources, integer anchors, grounded shadows, and strict chair/body/table depth ordering. Isolated actor controls find **zero shared actor pixels** in every direction. Both actors visibly contact or occlude the furniture in every view: Mina/Theo contact pixels are N **1463/584**, E **833/304**, S **534/1615**, and W **240/1112**.

The test exposed and corrected two candidate-path defects:

- Cached workstation depth-lock metadata was overwriting an active collaboration seat one frame after arrival. The collaboration branch now retains its own verified prop-relative depth; the ordinary workstation path is unchanged.
- A rear East/West actor sat completely behind the long tabletop. Only those rear side-facing sockets now split the lower body behind the top and the upper body at z=2, above the tabletop at z=0 but behind its front edge at z=3. The horizontal and near-seat depth contracts remain unchanged.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_collaboration_cluster.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_collaboration_cluster_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_collaboration_cluster_v2.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp code-native pixels, true alpha, nearest filtering, integer placement, and no transformed finished raster. |
| Perspective | 2 | The four screen-axis projections and inward gaze read correctly; the E/W rear-seat upper-body reveal is coherent but spatially tighter against the long tabletop than the horizontal views. |
| Silhouette/readability | 3 | The table, four service sockets/chairs, and two occupied diagonal seats remain immediately legible at native size. |
| Layering/anchors | 3 | Strict shadow/lower/upper and chair/table sandwiches pass in all eight actor placements, and isolated captures prove contact without actor overlap. |
| Direction consistency | 3 | N/E/S/W retain one assembly identity while independently changing table axis, chair positions, seat gaze, props, and occlusion. |
| Placement | 3 | One common actual-room pivot passes every unlock stage; real routes, reservations, clearance, reachability, collision, and arrival remain stable. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Remaining limitations

This proves the present Mina/Theo pair in the first two of four authored sockets. It reuses the already reviewed neutral seated frames and does not claim conversation gestures, meeting animation, new interactions, or behavior for a larger roster. Production activation still requires a separate explicit production-catalogue/runtime/default-layout decision. Dev planning-catalogue registration does not authorize one.
