# Terrazzo V3 — quieter border, still a visible repeated texture

Reviewed 2026-09-04 at native1280×720. **Keep the production wood floor.** The unified-base V3 reduces V2's broad pale margin, but repeated diagonal scratch/stitch-shaped clusters still make the128px plate structure noticeable. It is an improved border treatment, not a finished floor replacement. All technical checks pass; the visual repeat category does not.

## Native evidence

All nine individual room images below were inspected at native size, along with the V3 actual-room repeat crop and the existing nearest4× native material. These are disposable actual `GameMain` instances, not a composited room mockup.

| Fixed scene | Production wood | Frozen V2 | Unified V3 |
| --- | --- | --- | --- |
| Founder-only office | [Native](../../game/tests/output/terrazzo-v3-review/baseline-hires-0-office.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v2-hires-0-office.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v3-unified-hires-0-office.png) |
| Mature office | [Native](../../game/tests/output/terrazzo-v3-review/baseline-hires-4-office.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v2-hires-4-office.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v3-unified-hires-4-office.png) |
| Mature office with Chat | [Native](../../game/tests/output/terrazzo-v3-review/baseline-hires-4-chat.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v2-hires-4-chat.png) | [Native](../../game/tests/output/terrazzo-v3-review/terrazzo-v3-unified-hires-4-chat.png) |

[Native repeat detail from the actual room](../../game/tests/output/terrazzo-v3-review/terrazzo-v3-unified-repeat-native.png), cropped at `(416,192,384,256)`, retains the rendered pixels exactly. The separate [4× native tile](../../game/tests/fixtures/material-concepts/terrazzo-v3/cream-terrazzo-floor-v3-unified-base-4x.png) shows the long diagonal chains clearly. Three half-size overview sheets are navigation aids, not readability evidence.

### Findings

| Severity | Native evidence / coordinates | Observation | Disposition |
| --- | --- | --- | --- |
| P1 | V3 founder-only, open area `x384–768,y192–448`; crop crosses boundaries at `x512/640,y256/384` | The broad V2 blank moat is less conspicuous, but repeated curved/diagonal strings of gray pixels give a scratched or stitched surface. Recurring density pockets still reveal the plate. This does not read as evenly scattered little stone chips. | **Visual repeat failure; no runtime approval.** Do not hide it by zooming out, weakening edge tests or changing room geometry. |
| P2 | V3 mature office, center aisle `x416–704,y288–480` | Furniture does not conceal the repeat in the large central floor. Despite fewer non-base pixels than V2, elongated marks are more directional and draw attention; raw fleck percentage is not a measure of calmness. | A further source edit would need shorter irregular chip shapes as well as even perimeter density. Palette-only changes do not fix their spatial arrangement. |
| Pass, bounded | All three Chat images, drawer `x784–1151`; body paper `x820–1100,y210–560` | Warm paper remains separate from the cooler bright floor, with a strong wooden boundary. Body text, controls and portraits remain readable. Tested opaque Chat/HUD/rail regions are byte-identical across materials. | No UI recoloring or typography change is justified by this floor study. |
| Pass with existing limitation | Mature V3, Mina body `x356–381,y526–592`, Theo `x740–766,y526–592`, founder `x548–575,y558–626`; nameplates below/left | Dark body contours remain clear. Cream footwear and parchment have less value separation from the bright floor than from wood, but existing outlines/shadows/card edges keep them readable in these fixed poses. No new clipping was found. | Keep existing character/UI art. This is a static front-idle review, not a new motion or seated-shadow acceptance. |

Material rubric, adapting direction consistency to **repeat consistency**: pixel coherence **2**, perspective **3**, actor/material readability **2**, native registration/layers **3**, repeat consistency **1**, placement **3**. Mean **2.33**, with one category below2: **not accepted**. No N/E/S/W floor views or furniture-direction claim is implied.

## Source and measured normalization

Root supplied [V3 source](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v3.png), [exact prompt](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v3.md), and [builder](../tools/build_terrazzo_v3.sh). V3 is the existing series' second targeted retry after its initial request; this review made **zero ImageGen calls**. Original source SHA-256 is `c40cbd6a45cd85bce682b1c1747918e4f6baedb18667a63539739efa6057f089`.

The builder preserves its12-color-budget native export(**11 colors actually used**), the existing material-palette remap(8 used colors), and the separate **7-color unified-base candidate**. All are opaque128×128 plates. The last operation globally maps only `#E3DCCF → #EAE4D7`: exactly **13,084 pixels change, zero other changes**. Every fleck pixel is preserved; no border was selectively painted. Three stdout-only rebuilds byte-match all three retained files, without rewriting them.

| Native candidate | Colors | Opposite-edge mismatches X/Y | Non-base pixels, top8 rows | Non-base pixels,112×112 interior |
| --- | ---: | ---: | ---: | ---: |
| Frozen normalized V2 |11|0/0|7.03%|15.94%|
| Unified V3 |7|0/0|5.96%|11.47%|

Both density measurements count pixels other than `#EAE4D7`; they are descriptive, not pass thresholds. V3's top margin remains about half as dense as its interior. Exact edge agreement proves absence of a one-pixel color discontinuity, not a visually unobtrusive repeat.

V3 candidate SHA-256: `ab19a213b712f31cf687f853bd6305a8e72c62098963fd2b52219359797f8989`. Frozen V2 remains `13d436fdb317409d10dc4d68a9f1e4008a836d43fb271c3433ab7b5f597fd089`; production wood remains `6202478639de33fe7f8b548b49a20dddff6b69b59300300bcc89cfa064f2d0bd`.

## Verification and scope

- [Headless result](../../game/tests/output/terrazzo-v3-review/results-headless.json): **52 checks, zero failures**.
- [Rendered manifest](../../game/tests/output/terrazzo-v3-review/manifest.json): **111 checks, zero failures; 1,843,017 actual pixel comparisons; nine states /15 PNGs**(nine native rooms, three native repeat crops, three nearest overviews).
- All three imported128×128 RGBA buffers exactly match native files; lossless import, no mipmaps, architecture nearest-filtered at1×. Actual aisle samples across32px cells and128px plates match the source image.
- Only the disposable instance's `OfficeArchitecture.floor_art` changes. Layout, navigation, actor positions, collision and prop count remain identical. Nonfloor architecture, sampled HUD/rail ink and opaque Chat body/paper are byte-identical to the same-state baseline.
- Stage4 means the mature furniture layout with founder/Mina/Theo, not new hires or backend roles. Actors are frozen in consistent front-idle poses. **No movie, real-input, movement, fullscreen or universal gameplay claim** is made.
- Source/default hashes, V2 exports, V3 inputs and actual production JSON/architecture remain unchanged. Original V1/V2 helpers and evidence were not edited or overwritten. No production default, catalogue entry, provider, worker process, actual credential or personal save was accessed or changed. Credential-ready is only the old fixture's local UI projection.

New dev-only [capture helper](../../game/tools/capture_terrazzo_v3_review.gd) and [focused entry point](../../game/tests/test_terrazzo_v3_review.gd) reuse the existing isolated GameMain setup without extending its old output directory.

```sh
godot --headless --fixed-fps 30 --path game --script res://tests/test_terrazzo_v3_review.gd
godot --fixed-fps 30 --path game --script res://tests/test_terrazzo_v3_review.gd
```

## Recommendation

Keep wood as the shipped floor. **One final tightly scoped source retry could be worthwhile for an optional bright-office theme**, but it should not delay directional actor/furniture work. If attempted, change the scratches into tiny irregular stone-chip clusters and carry the same density through the interior to the single-pixel seam; avoid a border moat, long diagonal chains and central composition. Then repeat this small native empty/mature/Chat comparison. Do not launch another broad material batch, reset the original retry allowance, or treat0/0edges as approval. No further image request was made by this review.
