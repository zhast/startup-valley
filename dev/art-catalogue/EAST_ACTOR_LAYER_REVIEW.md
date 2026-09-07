# East actor and chair layers — source-preserving development study

**The layer mechanism works; the assembly is not runtime approved.** Existing source pixels can be split without seams or duplication, and proper layer order removes the knees/shoes-over-table defect. The short v2 keyboard, exact seated Y attachment and final hip-cut choice remain separate gates. The previous whole-body baseline at `supported-east-assembly/` is unchanged.

## Reproduction and final results

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_east_actor_layers.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/east-actor-layers/east-layers.avi --script res://tools/capture_east_actor_layers.gd
```

- Final headless: **330 checks,0 failures**.
- Final actual Godot renderer: **1,272 checks,0 failures**, exited0; renderer released.
- `game/tests/output/east-actor-layers/manifest.json`:36 actor/frame/cut observations, source/region counts and20 capture paths.
- Final evidence: **14 native1280×720 captures and6 nearest4× details**. All six native animation frames were inspected, alongside guide/support and both whole-chair controls. Both actors' cut52 details were inspected at4×; the other cut details preserve the same source/positions and are available for comparison.
- Movie `east-layers.avi`: verified1280×720 at30FPS, **227 actual frames**, including warm-up/stills and180 frames of idle/typing. It is not a sit/stand transition or input/pathfinding test.
- `git diff --check` passed for the new helper/harness. No production script, registry, source PNG, worker, save, provider call, commit or push was changed.

## Exact actor-region contract

The study inherits the frozen east assembly fixture, holding physical work offset(−32,0) and provisional chair/body render offset(+12,0). Mina uses `mira-east-seated-v3.png`; Theo uses `theo-east-seated-v4.png`. No actor scaling, pose repaint, mirroring or generation occurs.

For each original48×80 cell with pivot(24,72), candidate cut rows are50,52,55:

- Upper region `[frame*48,0,48,cut]`, placed at the original full-cell origin `render_foot−(24,72)`.
- Lower region `[frame*48,cut,48,80−cut]`, placed at that **same full-cell origin plus(0,cut)**.
- Both use nearest filtering, scale1 and uncentered native region sprites. The lower region is not trimmed and centered independently.

The36 combinations (two actors×six frames×three cuts) reconstruct **138,240 tested source pixels**, including alpha padding, with identical RGBA bytes. This counts repeated source frames under different cuts, not138,240 unique artwork pixels. Frame2's actual whole-sprite versus two-region renderer reunion compares six128×160 assembly crops: **122,880 rendered pixels match exactly**. `reunion-original.png` and `reunion-split.png` are the controls. Deterministic source-data hashes are unchanged after every render; the manifest hashes SHA-256 of hex-encoded decoded pixel bytes, not compressed PNG file hashes.

## Exact chair-region contract

`game/tools/calibration_chair_layers.gd` exposes a dev-only `partition("east")` result with canvas(96,160), pivot(48,112), disjoint `rear`/`front` rectangle lists and the actualE2 source path. Unknown facings return an empty result; west is not inferred by mirroring.

Three visibly supported rectangles own the existing near arm:

| Region | Source rectangle `[x,y,w,h]` | Evidence for boundary |
| --- | --- | --- |
| Horizontal padded bar | `[44,88,14,4]` | Alpha spans arex46–55 atrow88,x44–57 at89/90,x45–56 at91; clear space separates it from left backrest |
| Connector | `[48,92,4,1]` | Actual detached arm/stem spanx48–51 atrow92 |
| Vertical support | `[48,93,3,9]` | Visible gray/charcoal stemx48–50 throughrow101 |

The continuous dark underside atrow102 has ambiguous seat/support ownership; it stays **entirely rear**. No imagined hidden cushion, repaired contour or invented alpha mask is introduced. Rear rectangles are the exact full-canvas complement of those three front rectangles. Every original pixel, including transparent padding, belongs to exactly one rectangle. Front owns **81 opaque pixels**, rear **659**, totaling the original740.

The helper's `layer(texture,regions,foot,depth)` creates native source-region sprites at their original canvas coordinates. It does not generate new PNG layers. Source reunion compares all **15,360 chair-canvas pixels** byte-for-byte. Actual whole-chair versus region rendering compares another **122,880 rendered pixels** across the six fixed crops, with zero differences; see `chair-reunion-original.png` and `chair-reunion-split.png`.

“Front” means in front of the seated lower body, **not above everything**. The final study's depth order relative to desk origin is:

| Content | Relative depth |
| --- | --- |
| Chair rear/seat/base |−5 |
| Lower actor |−4 |
| Existing near-arm bar/stem |−3 |
| Tabletop rear layer |−1 |
| Desk apron/legs |+1 |
| Upper actor/hands |+2 |
| Side monitor |+3 |

This lets the near arm appear over lower-body pixels outside the tabletop while the tabletop occludes it where the chair is pulled underneath. Hands remain above it. The existing whole-chair-behind and whole-chair-above-lower controls remain captured, so the source partition is not confused with merely moving the whole chair.

## Native result and cut tradeoff

`native-frame2.png` now hides the impossible knees/shoes that the old baseline showed on the wood at the rightmost stations. The monitor retains the correct thin left-facing edge and zero head overlap. The full registered scene gives clean continuous pixel sampling; the reconstruction controls prove the two actor pieces cannot introduce a source seam when reunited.

| Actor/cut | Lower-source pixels behind top, frame2 | Upper lap-region pixels still above top, frame2 | Conservative hand-region samples below cut |
| --- | --- | --- | --- |
| Mina50 |227 |0 |3 atframe2;3–6 across all frames |
| Mina52 |202 |25 |0 in every frame |
| Mina55 |163 |64 |0 in every frame |
| Theo50 |238 |0 |0 in every frame |
| Theo52 |215 |23 |0 in every frame |
| Theo55 |179 |59 |0 in every frame |

These are source-region/geometry measurements, not hand/body semantic masks. In particular, the conservative hand box includes a tan/cuff/lap boundary at Mina row50; the original visual landmark review put her main hand band at43–49 with roughly1px ambiguity. Consequently cut50 is **not declared universally safe**, nor are its3–6 sampled pixels asserted to be definitively severed fingertips. Cut52 is the safer common comparison because it retains that entire conservative region, but leaves a small two-row upper-lap strip. Cut55 leaves a more conspicuous thigh overhang. Character-specific cuts may ultimately be better than forcing one common value.

The chair partition removes the incorrect whole-chair-through-hips band introduced by naively putting all chair pixels above the new lower actor. It does not resolve the original small anatomical support differences: estimated Mina hip/underside remains1–3px above the chair plane and Theo2–4px. Do not approve a shared Y socket merely because chair and actor use the same file pivot. The next corrected assembly can test deliberate per-character Y offsets while preserving logical feet.

## Iteration record and remaining limits

The first split preflight assumed every candidate cut preserved all conservative hand samples and correctly exposed six Mina/cut50 exceptions. The final checks retain those exceptions as explicit risky-candidate measurements while requiring safe cuts52/55 to preserve the whole sampled region. The first renderer also caught verbose diagnostic text crowding the paper; captions were shortened and their natural text width is now checked against the intended material insets, not only expanded panel bounds.

The early layer attempt lowered actor legs behind the unchanged whole chair, producing an unrelated gray near-arm/seat band. The separate whole-chair control and exact source rectangle partition address that confound; the prior whole-body baseline was not overwritten. Final rendered evidence supersedes intermediate split captures within this new study directory.

This report proves the source-preserving mechanism and exposes current assembly tradeoffs. It does not approve the v2 short keyboard, claim completed sit/stand motion, validate walls/collision/input, or enable any new production facing. Root's later true-alpha computerE4 source and a corrected supported assembly are separate work and must keep this v2 evidence intact.
