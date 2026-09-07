# Passive tables — native base-art review

Date: **2026-09-06**\
Scope: **three reusable passive table bases only**. This review does not add
chairs, cups, devices, service cells, seated poses, work behavior, worker
authority, persistence, a runtime catalogue binding, or a default-room
placement.

## Disposition

The low coffee table, cafe table, and round meeting table pass the bounded
passive art-library gate. They are deliberately different pieces rather than
scaled copies: the low table is a two-cell, 20px-rise four-legged lounge
surface; the cafe table is a two-by-two, 44px-rise chamfered square on a compact
central pedestal; and the meeting table is a three-by-three, 52px-rise oval
surface on a wider pedestal foot.

| Family | Pixel | Perspective | Silhouette | Layers / anchors | Direction | Placement | Mean | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Low coffee table | 3 | 2 | 3 | 3 | 3 | 3 | **2.83** | Pass as passive base art |
| Cafe table v2 | 3 | 3 | 3 | 3 | 2 | 3 | **2.83** | Pass after support-contact correction |
| Round meeting table | 3 | 3 | 3 | 3 | 2 | 3 | **2.83** | Pass as passive base art |

The score-2 limits are visible and intentional. The low table's long-axis view
is necessarily board-like at native size, although its top plane, low rise and
four separated supports remain legible. The cafe table is square and the
meeting table rotationally symmetric, so their four registered views have
little directional identity; adding fake front details would be less truthful.

## Authored geometry and materials

All layers are deterministic native screen-axis drawings from
`game/tools/passive_table_geometry.gd`. They reuse the accepted 32px quiet-oak
material tile and the existing charcoal/metal palette. No complete raster was
rotated, mirrored, stretched, or generated for this batch.

| Family | Canvas / pivot | Sprite offset | Footprint | Rise | View relationship |
|---|---|---|---|---:|---|
| `low_coffee_table` | 160×160 / [80,96] | [0,-16] | N/S 2×1; E/W 1×2 | 20px | N=S and E=W geometry, redrawn/registered on the fixed screen axes |
| `cafe_table` | 160×240 / [80,160] | [0,-40] | 2×2 | 44px | One physically square form, translated to the four fixed-pivot masks |
| `round_meeting_table` | 224×288 / [112,176] | [0,-32] | 3×3 | 52px | One rotationally symmetric form; all four registered composites are exactly equal |

Each view has `floor_shadow`, `rear_structure`, and `front_structure` on the
same native canvas and floor anchor. Shadows are small support-local contact
marks rather than a broad checker/dither mat. Upper-left highlights and
lower-right shade remain screen-fixed across directions. The registered layer
union reproduces each whole exactly, uses binary alpha, and contains no hidden
RGB outside alpha.

The first cafe export (`cafe-table-v1`) is preserved as rejected visual
history. Its post ended at local `center.y + 6` while its pedestal foot began
at `center.y + 13`, producing a clearly floating seven-pixel gap at 4× even
though collision and layer-reunion checks passed. `cafe-table-v2` changes no
top, foot, mask, pivot, material, or other family: it extends the same post
into the existing base with a one-pixel overlap. The focused and export suites
now assert every centerline alpha pixel from tabletop through base in all four
registered views.

## Native and actual-room evidence

The final actual `GameMain` batch is recorded in
[actual-room-results.json](../../game/tests/output/passive-tables-v2/actual-room-results.json):
**371 checks, 0 failures, 100 PNGs**, 1280×720, worker disabled and no save
access. It includes all four directions, native crops, nearest-neighbor 4×
details, founder/Mina/Theo in front of and behind each candidate, wall/corner
rejection, collision masks, interaction absence and one real path around each
South table.

Useful native inspection anchors:

- [all three South](../../game/tests/output/passive-tables-v2/all-tables-south-room.png)
  and [all three East](../../game/tests/output/passive-tables-v2/all-tables-east-room.png)
  establish distinct scale and footprint in the production room.
- [low table with founder behind at 4×](../../game/tests/output/passive-tables-v2/low_coffee_table-north-founder-behind-4x.png)
  preserves the low surface and separate legs.
- [corrected cafe table with Mina behind at 4×](../../game/tests/output/passive-tables-v2/cafe_table-north-mira-behind-4x.png)
  shows the square top hiding only the physically rear actor region.
- [meeting table with Theo behind at 4×](../../game/tests/output/passive-tables-v2/round_meeting_table-north-theo-behind-4x.png)
  shows the larger group surface and central pedestal without baked seating.

The first rendered batch reported **347 checks and 4 failures** solely because
the low-table `behind` probe sat at the center of a physically safe cell where
the short table and actor happened to have zero opaque-pixel overlap. The art,
collision and depth ordering did not fail. The final fixture retains that
historical result in this review, moves only the diagnostic actor by +4px
inside the same safe cell, explicitly proves the physical position remains
safe, and then measures 60–62 overlapping pixels with zero wrong-depth pixels.
No table pixel or geometry record changed for that correction.

That corrected v1 fixture subsequently reached **371/0**, but its passing
functional result did not excuse the cafe table's visually floating post. The
native review above therefore supersedes only the cafe art with v2; low and
round remain their exact v1 exports.

Separately, the v1 cafe evidence remains at
[`passive-tables/`](../../game/tests/output/passive-tables/); its visible gap is
not overwritten or relabeled as accepted.

The corrected structural exporter passed **446/0** and the focused headless
suite passed **628/0**. `validate_project.gd` also passes. These counts support the measured
geometry; the visual scores above come from native inspection, not from the
counts.

## Acceptance boundary

The companion
[passive-tables-registration.json](passive-tables-registration.json) proposes
three complete art-library family objects with exact layer/composite hashes.
Every runtime path remains null and the candidates are not added to the shared
catalogue or office layout by this task. Cafe and meeting-table actor probes are
scale/occlusion evidence only; they do not approve a seat count, chair socket,
arrival gaze, meal action, meeting action, or seated animation.
