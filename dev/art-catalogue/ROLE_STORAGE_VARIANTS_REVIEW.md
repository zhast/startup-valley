# Legal and creative storage fronts — isolated native-room study

Reviewed 2026-09-04 09:36 UTC. **Dev-only, unapproved role variants.** The already approved common archive remains unchanged in production. This study adds two source-derived South inserts, not eight independently drawn cabinets and not new employee functionality.

## Outcome

Both fronts register cleanly inside the existing powdercoat archive shell. At 1280×720, the legal front reads as locked filing and bound documents; the creative front reads as rolls, books/portfolio, brushes and small supply drawers. Neither leaks outside its frame or touches adjacent furniture. The slightly heavier inner borders are visible at 4× but form a consistent inset, not a shifted double outline or one-pixel seam.

The legal front is quieter and brighter, with two large cream doors. The creative front is warmer and denser, with stronger brown dividers and drawer grain. It still reads at native scale, but the individual brush tips are fine detail, not a reliable gameplay identifier. The common control and two new fronts use the same shell, placement, camera and native sampling.

**North, East and West are deliberately identical between the two role variants.** They reuse the approved common rear, locker end and display end because only the otherwise-hidden South face changed. This is physically consistent, but role identity is lost from those directions. It is acceptable for passive decor; it would not be sufficient as the sole indicator for distinct clickable legal/creative services. No invented side labels, mirrored art or new service behavior were added to conceal that limitation.

### Review recommendation, not runtime approval

| Category | Score | Evidence/limit |
|---|---:|---|
| Pixel coherence | 3 | Exact native source pixels, palette-normalized inserts, no alpha bleed or resampling in the room. |
| Perspective | 3 | A planar front replacement on unchanged, reviewed fixed-camera cabinet geometry. |
| Silhouette/readability | 2 | Legal files and creative supplies separate in South; small creative tools remain fine detail. |
| Layers/anchors | 3 | Same full canvas and floor pivot; no outer-boundary or frame seam. |
| Direction consistency | 2 | Physically consistent common shell reuse; role identity is absent in N/E/W. |
| Placement | 3 | Actual R/commit succeeds in all four directions at the normal bay; unchanged geometry validates across hire stages 1–4. |

Mean **2.67**, with no category below 2, for this bounded visual-decor study. These are review recommendations for the parent’s independent decision, not catalogue approval. The fixture marks every role-facing profile `calibration_candidate` with both art/geometry reviews false, and removes its scoped admission on exit.

## Exact assets and registration

- Preserved masters: [`legal-storage-front-v1.png`](../../game/assets/source/overnight-20260904/kits/legal-storage-front-v1.png) and [`creative-storage-front-v1.png`](../../game/assets/source/overnight-20260904/kits/creative-storage-front-v1.png), with adjacent original prompts. One generation per source, provided by the parent; this study made no ImageGen calls.
- Mechanical builder: [`build_role_storage_fronts.sh`](../tools/build_role_storage_fronts.sh). Uniform point fit into 88×56, centered padding, existing archive palette remap; no independent-axis stretch, camera transform, silhouette painting or source replacement.
- Native fronts: [`legal-front.png`](../../game/tests/fixtures/furniture-calibration/role-storage-v1/legal-front.png), **88×56 RGB, 19 colors**; [`creative-front.png`](../../game/tests/fixtures/furniture-calibration/role-storage-v1/creative-front.png), **88×56 RGB, 20 colors**. The legal book’s source burgundy is remapped to the common warm brown.
- Registered layers: [`legal-south-insert.png`](../../game/tests/fixtures/furniture-calibration/role-storage-v1/legal-south-insert.png) and [`creative-south-insert.png`](../../game/tests/fixtures/furniture-calibration/role-storage-v1/creative-south-insert.png), each **192×288 RGBA**, with the sole opaque rectangle **(52,180,88,56)**. The transparent exterior is not an opaque checkerboard/matte.
- Native floor pivot **(96,224)**; centered Sprite offset **(0,−80)**; every layer retains region **(0,0,192,288)** and prop-relative depth **0**. Floor footprint remains 96×32 N/S or 32×96 E/W, with rise 64. These are standing-service profiles, not chairs or work poses.
- The two registered insert imports use `process/fix_alpha_border=false`. Godot’s decoded RGBA bytes equal the registered PNG bytes, including zero-alpha padding. The PNGs and masters were not modified by that import adjustment.
- The other four South layers, and all five N/E/W layers, directly reference [`runtime/office/archive-v1`](../../game/assets/runtime/office/archive-v1/). No duplicate common source drawing is claimed.

## Native evidence inspected

All nine full-size room images were inspected: the approved common South control, then legal and creative South/West/North/East. Each shows the normal two-employee GameMain room, founder, Mina and Theo at their native scale, and the actual canonical developer editor. The drawer/worker is not substituted by a screenshot.

- [Common → legal → creative, unchanged native crops](../../game/tests/output/role-storage-variants/common-legal-creative-fronts-native.png)
- [All four views, legal top row / creative bottom row, N/E/S/W columns](../../game/tests/output/role-storage-variants/all-roles-views-native.png)
- [Legal South actual room](../../game/tests/output/role-storage-variants/legal-south-room.png) / [4× detail](../../game/tests/output/role-storage-variants/legal-south-4x.png)
- [Creative South actual room](../../game/tests/output/role-storage-variants/creative-south-room.png) / [4× detail](../../game/tests/output/role-storage-variants/creative-south-4x.png)
- [Legal N](../../game/tests/output/role-storage-variants/legal-north-room.png), [E](../../game/tests/output/role-storage-variants/legal-east-room.png), [W](../../game/tests/output/role-storage-variants/legal-west-room.png)
- [Creative N](../../game/tests/output/role-storage-variants/creative-north-room.png), [E](../../game/tests/output/role-storage-variants/creative-east-room.png), [W](../../game/tests/output/role-storage-variants/creative-west-room.png)
- [Common South actual room](../../game/tests/output/role-storage-variants/common-south-room.png)
- [Manifest and source hashes](../../game/tests/output/role-storage-variants/manifest.json), [short R/commit recording](../../game/tests/output/role-storage-variants/role-storage.avi)

The South cabinet occupies approximately **(96,352)–(192,448)** in the full native room. Its new content is confined to **(100,388)–(188,444)**. Both retain the common top and thin charcoal/gray frame. The role caption fits its developer toolbar; the other directions explicitly say unapproved study. The side-by-side sheets are unscaled crops from independent actual scenes, not simultaneous same-room variants or composited approval images.

## Verification

- Focused headless: **168 checks, zero failures**.
- Focused graphical: **216 checks, zero failures**; **9 actual-room views, 30 PNGs** including registered crops/details/contact sheets.
- **66,560 opaque cabinet pixels** compared against their exact ordered native layer composition in the actual room; no mismatches. Every reused N/E/W composite additionally equals the approved common whole-view RGBA bytes.
- Each role uses real `InputEventKey` R down/up plus mouse press/release through the editor to commit S→W→N→E. Actual final facing and successful commit are asserted, not just handler invocation.
- Native import alpha/size/equivalence, five-layer registration and depth, no false seat/pose fields, ordinary placement across stages 1–4, live-owner admission cleanup, independent normal-room non-leakage and preserved JSON/master/native hashes are asserted.
- Movie metadata independently checked with `ffprobe`: **1280×720, 30 FPS, 64 frames, 2.133333 seconds**. It records the short editor comparison sequence; it is not a new actor/pathing or furniture-arrival animation acceptance test.
- Builder syntax checked with `bash -n`; focused whitespace check clean. The initial 40 assertion failures were a test-only JSON float-versus-integer array comparison, fixed by parsing explicit `Rect2`/`Vector2i` geometry. No source, geometry or placement change was needed.

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_role_storage_variants.gd -- \
  --legal=res://tests/fixtures/furniture-calibration/role-storage-v1/legal-south-insert.png \
  --creative=res://tests/fixtures/furniture-calibration/role-storage-v1/creative-south-insert.png

godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/role-storage-variants/role-storage.avi \
  --script res://tests/test_role_storage_variants.gd -- \
  --legal=res://tests/fixtures/furniture-calibration/role-storage-v1/legal-south-insert.png \
  --creative=res://tests/fixtures/furniture-calibration/role-storage-v1/creative-south-insert.png
```

Implementation is confined to [`role_storage_fixture.gd`](../../game/tools/role_storage_fixture.gd), [`capture_role_storage_variants.gd`](../../game/tools/capture_role_storage_variants.gd), and the focused test alias. The fixture installs its null transport before GameMain enters the tree and proves no worker/personal bootstrap is loaded. Production JSON, runtime art, save data, hiring/backend behavior and broad production tests remain unchanged. Earlier approved archive [production input/navigation/migration evidence](ARCHIVE_PRODUCTION_REVIEW.md) is relevant to the reused geometry, but it was not rerun as part of this cosmetic comparison and must not be represented as new role-service coverage.
