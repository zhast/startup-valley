# Legal toolkit: actual GameMain composition review

2026-09-04. **Staged only. The separately captured corrected alternative resolves the three north/south placement defects below; west remains a direction-identity cleanup candidate; east is unavailable. No runtime approval.**

## Scope and actual pipeline

This review uses the ordinary `GameMain`, `TownRoom`, `OfficeLayout`, employee navigation, scoped `CharacterArt` registry, native desk/chair layers and seated depth lock through [legal_role_fixture.gd](../../game/tools/legal_role_fixture.gd). The fixture subclasses the existing [calibrated workstation fixture](../../game/tools/calibrated_workstation_fixture.gd); it does not draw a substitute office or paste a finished assembly over the game.

Each of N/S/W begins with a fresh two-employee scene. Mina and Theo walk through the existing navigation path and finish the existing seat transition before capture. Their logical workstation cells, per-character visual sockets, registered upper/lower source partitions, desk geometry and computer poses are unchanged. Actual desks are at world pivots `(336,272)` and `(784,272)`. Day/time, room and team rail remain visible. Only the development placement toolbar and employee availability/effect callouts are hidden consistently for this composition study.

North uses the preferred brand exports from [the north review](LAWYER_NORTH_KIT_REVIEW.md). South preserves the final binder source Y106 from [the south review](LAWYER_SOUTH_KIT_REVIEW.md), and moves the complete original mouse +45 X from canvas69 to114. West uses the explicitly reclassified source and registered positions from [the direction-identity review](LAWYER_DIRECTION_IDENTITY_REVIEW.md). There is no legal east texture and the harness makes no east claim.

The employee poses are **two existing seated idles plus four existing computer-typing frames**, not an authored legal-document interaction. The role objects are resting decoration. There is no legal backend, provider call, worker transport, credential access or save access. A `NullWorker` replaces the transport before `GameMain._ready`; each fixture unregisters its scoped pose capability on teardown. None of the source or native-export images changed.

## Evidence and results

- [Capture and measurement harness](../../game/tools/capture_legal_role_composition.gd); [focused test entry](../../game/tests/test_legal_role_composition.gd).
- [Rendered manifest](../../game/tests/output/legal-role-composition/manifest.json): **1,019 invariant checks, zero failures**, nine separately recorded art/placement findings, 36 actor/frame observations and 57 PNGs.
- [Final headless measurements](../../game/tests/output/legal-role-composition/results-headless.json): **944 invariant checks, zero failures**, same nine findings. A final measurement-only extension additionally separates upper/lower actor overlap and searches a local north clearance correction; it does not alter the scene or existing PNG pixels.
- [Movie](../../game/tests/output/legal-role-composition/legal-role.avi): `ffprobe` confirms **60 frames, 30 FPS, 1280×720**. This short recording contains the six selected poses per direction, not an uninterrupted navigation or complete work-state movie.
- PNG inventory: **18 normal-room captures**, **36 nearest-neighbor 4× actor crops**, **three native-pixel paired contact sheets**. The contact sheets contain every frame for both employees, ordered frame0/1/2 across the first row and frame3/4/5 across the second; each frame has Mina then Theo.
- Native inspection covered all three paired six-frame contact sheets, the three full-room frame2 captures, and both employees' frame2 4× crops for all three views. That is all 36 actor poses at native size plus six enlarged detail checks. This is not a claim to have watched every movie frame.
- Source/component tests check full192×224 registration, binary alpha, source hashes, original component union byte equality, component silhouette separation, actual render offsets, real inset-wood support rectangles, live source-frame selection and exact upper/lower reassembly. Route and seat-endpoint assertions also pass. `git diff --check` passes.

Native evidence:

- North: [room](../../game/tests/output/legal-role-composition/north-frame2.png), [all six / both employees](../../game/tests/output/legal-role-composition/north-all-six-native.png), [Mina 4×](../../game/tests/output/legal-role-composition/north-mira-frame2-4x.png), [Theo 4×](../../game/tests/output/legal-role-composition/north-theo-frame2-4x.png).
- South: [room](../../game/tests/output/legal-role-composition/south-frame2.png), [all six / both employees](../../game/tests/output/legal-role-composition/south-all-six-native.png), [Mina 4×](../../game/tests/output/legal-role-composition/south-mira-frame2-4x.png), [Theo 4×](../../game/tests/output/legal-role-composition/south-theo-frame2-4x.png).
- West: [room](../../game/tests/output/legal-role-composition/west-frame2.png), [all six / both employees](../../game/tests/output/legal-role-composition/west-all-six-native.png), [Mina 4×](../../game/tests/output/legal-role-composition/west-mira-frame2-4x.png), [Theo 4×](../../game/tests/output/legal-role-composition/west-theo-frame2-4x.png).

An earlier native attempt encountered a concurrent development registry error before any `GameMain` scene could initialize. The owning agent fixed a `StringName` dictionary key generated by dot assignment to the explicit String key accepted by the strict registry. The final successful batch replaced that failed movie/contact output. The earlier three-frame failed run is not acceptance evidence.

## Visible findings and smallest next corrections

Coordinates below are on the common192×224 canvas, pivot `(96,160)`, with positive Y downward. For Mina's room coordinates, add `(240,112)`; for Theo add `(688,112)`.

### N1 — North folder partially covers the mouse

The folder's opaque projection overlaps the actual mouse by **10 pixels** before actors are added. This is visible as the mouse joining/disappearing into the lower-left corner of the blue folder in the native and 4× captures. The original folder bounds are `(114,118,26,19)`; the canonical mouse after its normal +4 Y attachment is `(112,133,6,8)`. No role part overlaps either actor's source pixels across all six frames.

**Propose folder translation `(0,-4)` only; leave mouse, keyboard, monitor and actor unchanged.** The candidate folder bounds become `(114,114,26,19)`, inside the true inset wood `(50,114,92,28)`. The read-only search checks at least one empty opaque pixel between the moved folder/mouse and other static kit/device objects, not merely zero overlapping bounding boxes. The four-pixel move is the minimum total Manhattan movement found within folder X±2/Y±4 and mouse X±6/Y±5; it is not an unbounded optimization or ergonomic approval. This candidate has not been rendered or applied by this review. Native recheck is required before accepting it.

### S1 — South mouse top and cup base touch the inset rim

The requested +45 X mouse move successfully separates it from the folder, but its resulting complete silhouette `(114,113,5,8)` begins **one pixel above** true inset wood Y114. Its room position is `(354,225)` for Mina. **Propose mouse translation `(0,+1)`** in addition to the existing +45 X, retaining the original source and its proportions.

The pen cup's complete silhouette is `(126,131,7,12)` and proposed base contact `(126,140,7,3)`, extending one pixel beyond inset wood's exclusive end Y142. Its bottom visually touches the front rail. **Propose whole cup `(0,-1)`**, leaving the binder's required Y106 untouched. This preserves every source pixel. Both small corrections need the same six-frame/native checks after application; these are not approvals based only on arithmetic.

South has no opaque role/device or role/actor intersection in the current measured frames. The rear monitor naturally hides the keyboard and hands. That is consistent occlusion for this direction, but it does not demonstrate document handling or specific typing contact.

### W1 — Correctly hidden lower body is not a hand collision

The conservative whole-body projection alarm reports folder overlap for both employees. Splitting the counts by the actual owned source regions shows:

| Actor | Folder overlap with lower source, frames0–5 | Folder overlap with upper source, all frames |
| --- | --- | --- |
| Mina | 36,36,40,53,53,53 pixels | **0** |
| Theo | 84,83,87,88,68,94 pixels | **0** |

These are lower-body pixels already behind the tabletop in the canonical layered renderer. All binder/cup actor counts are zero. Native captures show the folder below the hands, with face, forearm and keyboard unobscured by legal objects. **Do not move an actor or folder to eliminate this harmless full-source projection count.** It is not an accidental double-painted lap or a new hand collision.

The folder still reaches the inner front boundary; its full bounds `(83,147,19,27)` fit actual west wood `(82,82,28,92)`, not padded image bounds. Existing contact anchors for the raised binder/cup are inferred 2D support rectangles, not an independently authored physical model.

### W2 — Direction identity still prevents approval

The reclassified west view has suitable checklist-top/blank-bottom leaf order and near/south binder spines, but its **outer tabs still point right**, its page marks remain screen-upright, and pen ordering/depth remains unproven. The binder is12×32 rather than12×30 and folder19×27 rather than the approximate19×26 target. These mismatches are visible in the west 4× images. Translation cannot fix them. Preserve the existing cleanup classification and the exhausted original east retry history; do not claim the reclassification delivered both east and west art.

### N2 — Hidden RGB is not a visible matte

All north brand layers have binary transparency but retain charcoal RGB beneath alpha0: binders42,571 pixels, folder42,558, cup42,937. The original component union is byte-exact and there is **no visible opaque background/checkerboard** in the native room. This is normalization bookkeeping, not the source of the mouse overlap. Do not erase/repaint alpha or claim a visible rendering failure from invisible RGB alone.

## Contact/occlusion assessment

Scores describe this bounded evidence only: 0 missing/broken,1 visible defect,2 plausible with stated limitations,3 clear in tested frames. They are not runtime approval or a claim that the entire base workstation is finished.

| View | Inset support | Static-object clearance | Essential actor clearance | Direction identity | Disposition |
| --- | ---: | ---: | ---: | ---: | --- |
| North | 2 | **1** | 3 | 2 | Render proposed folder−4Y; resting decor only |
| South | **1** | 3 | 3 | 2 | Render mouse+1Y/cup−1Y; rear monitor intentionally obscures hands |
| West | 2 | 3 | 3 | **1** | Keep cleanup label; no body shift needed; identity cannot be repaired by placement |

All-six native contact sheets show no new legal-part shimmer or frame-dependent legal overlay. The canonical character source variations and prior workstation limitations remain; this task did not redraw poses, prove a document-use animation, or approve seat transitions. The plain Connect control visible at the bottom of the development rail is existing unrelated UI and was not redesigned here.

## Reproduction

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_legal_role_composition.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/legal-role-composition/legal-role.avi \
  --script res://tools/capture_legal_role_composition.gd
```

No production catalogue/profile was enabled, no source export changed, and no new image call occurred. Next work should apply the three narrow N/S **fixture-only placement alternatives**, recapture them, and retain W/E art gates. Passing the invariant suite must not promote any of the nine recorded art findings to success.

## 08:29–08:36 UTC addendum — corrected clearance alternative

The proposed three translations are now an explicit, default-off fixture option,
`use_corrected_clearance`. The capture flag `--clearance-corrected` writes into a
separate [clearance-corrected evidence directory](../../game/tests/output/legal-role-composition/clearance-corrected/),
preserving every original source, export and baseline screenshot. It moves only
the north folder−4Y, south mouse an additional+1Y, and south cup−1Y. Canonical
render-layer offsets and measured visual bounds include those translations;
actors, navigation cells, work sockets, desk layers and computer frame ownership
are unchanged. West is deliberately unchanged.

- **1,103 headless / 1,196 rendered checks, zero failures**, with explicit inset
  support, static-device clearance and essential upper-body clearance assertions.
- **57 PNGs and 69 encoded frames at30FPS,1280×720**, independently checked with
  `ffprobe`. The extra frames settle fresh fixture state and dismiss the deferred
  development connection overlay before capture; they are not new work animation.
- Root inspected the complete north and south native six-frame/two-actor sheets
  and north Mina/south Theo frame2 at4×. The north mouse now has a clear boundary
  below the folder; south mouse and cup are inside the wood rather than touching
  the upper or lower rim. No character or legal-object frame-dependent collision
  appears in those sampled poses.
- The remaining six recorded notes are the three invisible north RGB-padding
  records, two intentionally occluded west lower-body projections, and the one
  west identity defect. They are **not six newly failed functional checks**.
  North/south static placement and essential actor clearance now score3 within
  this tested resting/typing composition. Directional-role and base-workstation
  limitations still prevent family/runtime approval.

Reproduce by appending `-- --clearance-corrected` to the test or capture command;
write the movie to `res://tests/output/legal-role-composition/clearance-corrected/legal-role.avi`.
This resolves N1/S1 with placement, not another generated asset. W2 and the absent
east view still require authored art; a new legal employee animation is not implied.
