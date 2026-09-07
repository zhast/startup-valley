# Lawyer toolkit: direction identity and reclassified west candidate

2026-09-04. **Source/native review only; west is partially correct and requires cleanup. East remains missing/cleanup with its original retry allowance exhausted. No runtime approval.**

## Why there was no new west generation

The ImageGen skill/reference workflow was read and the north identity source and native east/south candidates inspected before dispatch. This exposed a wrong direction instruction in the original east prompt. The coordinator stopped the proposed west call and explicitly authorized reusing the misdirected east source instead. **Zero new ImageGen calls occurred in this task.** No retry was reset or charged to a renamed direction.

The retained [source named `lawyer-kit-east-v4.png`](../../game/assets/source/overnight-20260904/roles/lawyer-kit-east-v4.png) is still at its original path. Its original prompts remain unchanged: [initial request](../../game/assets/source/overnight-20260904/roles/lawyer-kit-east-v1.md), [rectangular-top correction](../../game/assets/source/overnight-20260904/roles/lawyer-kit-east-v2.md), [top/stack proportion correction](../../game/assets/source/overnight-20260904/roles/lawyer-kit-east-v3.md), [alpha extraction](../../game/assets/source/overnight-20260904/roles/lawyer-kit-east-v4.md). That history is **one initial call plus three targeted retries, exhausted**. The final retained source is genuine-alpha **1672×941 RGBA**, SHA-256 `2433507ee40add344a53bcb931cc12b2fc5cc66d711dd46e589ef4512a8c0335`.

Existing `lawyer-east-v4-*` PNGs and the root's [east-labeled room captures](../../game/tests/output/lawyer-kit-east/manifest.json) are preserved. They are **mislabeled-direction diagnostic evidence**, not proof of an east-facing toolkit. The new `lawyer-west-reclassified-v4-*` name describes the interpretation/export; it does not claim a newly generated west source or a fully correct west view.

## Physical identity, not filename inference

North is the identity reference: the user sits below the desk looking up; binder spines lie along the left/west edge; the flat open folder has blank cover left, checklist right and tabs on its outer right edge. The same objects are physically turned while screen X/Y floor axes and upper-left lighting stay fixed.

| Operator gaze / position | Expected folder leaves | Expected outer tabs | Binder spine edge |
| --- | --- | --- | --- |
| N / below | Blank left, checklist right | Right/east | Left/west |
| E / left | Blank top, checklist bottom | Bottom/south | Far/north |
| S / above | Checklist left, blank right | Left/west | Right/east |
| W / right | Checklist top, blank bottom | Top/north | Near/south |

This follows physical floor-coordinate quarter turns, not a bitmap operation. For N→W, a local top-plane point `(x,y)` maps to `(y,-x)`: the north source's right-hand checklist becomes the upper leaf, and its left-hand binder spine becomes the near/south spine. Vertical stack height still projects **downward**; it never rotates sideways with the floor footprint. None of these mathematical mappings was applied to raster pixels in this task.

The original east request explicitly asked for checklist top/blank bottom. That describes the **west leaf order**, and the final source also shows blue labeled spines on the near/south edge. Reclassifying those two features is justified. Treating the entire sheet as a correct west drawing is not.

### Remaining visible identity mismatches

- **Folder tabs:** final source tabs still emerge from the checklist's right edge, not the physically rotated outer top edge. The native west candidate has the same right-edge chartreuse marks. The horizontal hinge and leaf order alone are insufficient direction acceptance.
- **Page marks:** the checkbox column and horizontal line bars remain screen-upright, rather than turning with the page toward the west-side reader. These are abstract marks, not legible legal text, but they do not establish rigid object identity across views.
- **Pen cup:** north and the reclassified candidate both retain blue-left, charcoal-middle, yellow-pencil-right ordering, with upright shafts. Upright shafts and fixed light are correct; a true quarter-turned arrangement/depth order is **unproven**. Do not declare a west cup simply because its filename changed. Native north is 7×12; the candidate is 6×12 after preserving height with uniform scaling.
- **Binder:** near/south spines fit W; the top is a narrow screen-aligned rectangle. Uniform export is **12×32**, not the intended 12×30. The top is approximately 12×20, with approximately 12px of downward stack thickness instead of the target10. Keep the measured difference visible; do not squeeze height independently or hide it with a socket shift.
- **Folder size:** actual complete export is **19×27**, not the approximate19×26 target. It fits the current desk interior without cropping or nonuniform scaling.

The [north review](LAWYER_NORTH_KIT_REVIEW.md) and north source remain the identity basis; the old east source is not promoted to a new ground truth. The existing south candidate has the intended opposite leaf order, outer-left tabs and right binder spine; its common room comparison/acceptance belongs to the coordinator.

## Exact source-preserving west export

Builder: [build_lawyer_west_kit.sh](../tools/build_lawyer_west_kit.sh). All source crops, point scaling and palette treatment match the existing east builder. Only registered placement changes; **no rotation, mirroring, stretching, repainting or source mutation**.

| Component | Original source crop `[x,y,w,h]` | Uniform normalization | New full-canvas ink `[x,y,w,h]` | Opaque pixels |
| --- | --- | --- | --- | ---: |
| Binders | `[178,148,227,610]` | Width12, resulting height32 | `[86,70,12,32]` | 382 |
| Folder | `[645,170,409,586]` | Width19, resulting height27 | `[83,147,19,27]` | 493 |
| Pen cup | `[1325,337,170,346]` | Height12, resulting width6 | `[103,74,6,12]` | 67 |

Each PNG is a full **192×224** canvas with fixed pivot **(96,160)**. For centered sprite use, offset is `(0,-48)`; no crop recenters an individual object. Output files:

- [Binders](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4-binders.png)
- [Folder](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4-folder.png)
- [Pen cup](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4-pen_cup.png)
- [Native union](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4.png)
- [Native pixels on paper, 4×](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4-paper-4x.png)

The shared [16-swatch role palette](role-material-palette.svg) is applied with the original alpha mask explicitly restored and compared. The union uses15 opaque colors plus transparent, **942 opaque / 42,066 transparent / zero partial-alpha pixels**, with zero RGB beneath transparency. All three cropped object buffers are byte-identical to their old east-export counterparts; reclassification has not silently redrawn an object. The original east files stay unchanged.

### Provisional west sockets

The west desktop's actual inset wood is local `(-14,-78,28,92)` or canvas `(82,82,28,92)`. Proposed object contact rectangles are:

- Binders: canvas `(86,82,12,20)`, local `(-10,-78,12,20)`. This explicitly assumes the measured12px stack elevation; the complete body extends above the desk surface.
- Flat folder: canvas `(83,147,19,27)`, local `(-13,-13,19,27)`. Every visible pixel lies within the wood; the lower edge reaches its inner boundary y174, not the outer rim y176.
- Cup base: canvas `(103,83,6,3)`, local `(7,-77,6,3)`; its upright body starts at canvas y74.

These contacts are disjoint and lie inside the actual wood. Whole candidate ink bounds do not overlap the current west computer monitor, keyboard or mouse bounds. This is a **2D placement preflight**, not physical-contact approval, a guarantee of hand clearance, or a new drinking/document-use animation. Root owns the common in-room actor/occlusion review.

## Verification and disposition

Commands:

```sh
bash dev/tools/build_lawyer_west_kit.sh
godot --headless --path game --script res://tests/test_lawyer_direction_identity.gd
```

[Focused test](../../game/tests/test_lawyer_direction_identity.gd): **43 checks, zero failures**. [Saved results](../../game/tests/output/lawyer-direction-identity/results.json) include source hash, real dimensions, direction reinterpretation, original exhausted-call count, zero new generations, proposed contacts and all limitations. The tests check full-canvas registration, binary/empty alpha, shared palette, exact old-object reuse, exact union reconstruction, nonoverlap and inset-wood fit. They deliberately do not assert that this candidate is artistically correct. Two successive builds produced identical SHA-256 hashes for all **five** exported PNGs; metadata is stripped from the 4× evidence too. Native and 4× outputs were visually inspected; no renderer or real worker was started.

Disposition: **reuse staged source under an explicit W cleanup label; E remains missing/cleanup and exhausted.** Folder tabs/page marks, cup direction identity and binder thickness still prevent a four-direction approval. Do not count E and reclassified W as two successfully authored directional deliverables. No catalogue, production metadata, worker contract, save or credential was changed.
