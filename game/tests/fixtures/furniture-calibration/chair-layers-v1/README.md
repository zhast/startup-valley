# East/west chair layers v1 — exact source extraction

Development fixtures only. These four PNGs split existing, independently authored chair images using the calibrated source-region helpers. They do not redraw hidden cushion pixels, resize a chair, mirror another direction, change alpha, approve a runtime facing or modify north/south chairs.

Every layer retains **96×160 pixels / floor pivot (48,112)**. Files named `front` contain the **near arm only**, not a whole foreground chair. The [manifest](manifest.json) includes source hashes, source-region ownership, opaque bounds/counts and canonical-style descriptors.

| Source / export | Opaque bounds `[x,y,w,h]` | Opaque pixels |
| --- | --- | ---: |
| [East source](../chair-east-v2.png) | [32,72,32,56] | 740 |
| [East rear](east-rear.png) | [32,72,32,56] | 659 |
| [East near arm](east-front.png) | [44,88,14,14] | 81 |
| [West height56 source](../chair-west-v2-height56.png) | [35,72,29,56] | 660 |
| [West rear](west-rear.png) | [35,72,29,56] | 574 |
| [West near arm](west-front.png) | [39,89,13,14] | 86 |

## Exact ownership and source provenance

- East comes from `calibration_chair_layers.gd`: bar `[44,88,14,4]`, connector `[48,92,4,1]`, stem `[48,93,3,9]`. The continuous underside at row102 remains rear. See [east layer review](../../../../../dev/art-catalogue/EAST_ACTOR_LAYER_REVIEW.md).
- West comes from the separate `calibration_west_chair_layers.gd`: bar `[39,89,13,4]`, stem `[44,93,4,10]`. Row103 remains rear. This is measured west art, not reflected east coordinates. See [west supported layer review](../../../../../dev/art-catalogue/WEST_SUPPORTED_LAYERS_REVIEW.md).
- In both cases rear rectangles are the full-canvas complement of the near-arm rectangles. Every one of 15,360 source pixels, **including transparent padding**, has exactly one owner. No source pixel is shared, dropped, shifted or repainted.

The exporter uses CPU `Image.blit_rect` at each rectangle's original coordinates. Each output is initialized with zero RGBA; original bytes are copied without filtering or semantic modification. Rear plus near-arm reconstructs the entire original decoded image exactly. The sources already have binary alpha and zero invisible RGB; the exporter does not manufacture or clean their alpha.

The four new `.png.import` sidecars preserve lossless pixels, disable mipmaps, and set `process/fix_alpha_border=false`. This avoids Godot's normal invisible-RGB border fill and makes imported texture buffers byte-identical to the PNGs. Existing source and production import files stay unchanged. Keep these sidecars with the fixtures when re-exporting.

## Canonical rendering descriptors

The manifest uses the existing `render_layers` field shape:

```json
{
  "name": "ChairNearArm",
  "art": "res://tests/fixtures/furniture-calibration/chair-layers-v1/east-front.png",
  "region": [0, 0, 96, 160],
  "offset": [0, -32],
  "z_offset": -3,
  "content_bounds": [44, 88, 14, 14]
}
```

Rear uses `ChairRear` and `z_offset: -5`. Centered `offset [0,-32] − canvas/2 [48,80]` gives the required full-canvas origin `[-48,-112]`. Both use the same integer origin; there are no odd-sized independently centered crop sprites, half-pixel placement, scale/flip/rotation fields or fabricated native bounds.

Depth is the **reviewed dev assembly depth relative to the desk anchor**: chair rear −5, lower actor −4, near arm −3, desk top −1. The static reference chair foot is east `(+12,0)` or west `(−12,0)` from the logical work foot, recorded separately from the PNG pivot. These are visual recipe references, not physical work-cell changes or a complete placement/seat approval. A later dev-playable integration must preserve this distinction and independently test approach, sit/stand, collisions and actor layer order.

## Reproduce and verify

From the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game \
  --script res://tools/export_chair_layers.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game \
  --script res://tests/test_chair_layer_export.gd
```

- CPU exporter: **34 checks, zero failures**.
- Focused headless tests: **94 checks, zero failures**, including source ownership, import bytes/settings, exact source reunion, native/4× contact-sheet pixels and existing canonical layer-reader compatibility.
- Negative controls reject overlapping regions, missing regions and out-of-canvas regions. One initial test used a conditional untyped array where Godot required `Array[Rect2i]`; the test now explicitly assigns the typed array. No source artwork changed to satisfy that check.
- Two exports produced identical SHA-256 hashes for all four PNG files.
- Independent Node/ImageMagick decoding compared **122,880 RGBA bytes** across both source reunions with zero opaque overlap/differences and verified standard decoded-byte hashes.
- Godot import, project validation and `git diff --check` passed. No graphical renderer, worker process, provider, save, production metadata, registry, commit or push was used.

Native evidence is [source / rear / arm / reunion](../../../output/chair-layer-export/source-rear-arm-reunion-native.png), 384×320: east above west, four unchanged 96×160 columns. The [4× proof](../../../output/chair-layer-export/source-rear-arm-reunion-4x.png) is 1536×1280 with nearest replication. Both were inspected; the reunion retains the original silhouette, lighting, cushion, feet and source defects. Isolated rear has the expected arm-region gap; it is not meant to be shown without the complementary near-arm/actor assembly. [Test results](../../../output/chair-layer-export/results-headless.json) record the final check count.

This exports a proven source partition. It is not new-art approval, a new chair design, completed animation, or runtime-facing enablement.
