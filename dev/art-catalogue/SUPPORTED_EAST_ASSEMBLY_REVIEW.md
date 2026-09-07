# Supported east assembly — frozen failure baseline

**No candidate is approved.** The study establishes useful hand reach at a12px chair/body pull-in, but also exposes the decisive whole-body layering defect: knees and shoes appear on the tabletop. The short keyboard and whole-chair depth remain separate failures. No production direction, actor pose, socket, navigation or save was changed.

## Reproduction and evidence

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_supported_east_assembly.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/supported-east-assembly/supported-east.avi --script res://tools/capture_supported_east_assembly.gd
```

- Headless: **217 checks,0 failures**.
- Actual Godot renderer: **803 checks,0 failures**; process exited0 and renderer was released.
- `game/tests/output/supported-east-assembly/manifest.json`: exact36 pose/offset observations, source list and16 evidence images.
- Movie: `supported-east.avi`, verified1280×720,30FPS, **275 actual frames**. This includes capture warm-up and a240-frame endpoint/typing sequence. Its deliberate hard sit/stand endpoints are diagnostic jumps, not completed transition animation.
- All10 native captures were inspected: standing endpoint; native frames0–5; guide, exposed-support and whole-chair-front comparisons at frame2. All six nearest4× frame2 details were also inspected.
- The803 checks establish fixture geometry, input-art identity, native scale, label bounds and source-pixel measurements. They do **not** mean the visibly faulty assembly passed art acceptance.

## Actual geometry versus unapproved placement

The real catalogue still exposes only south. Its actual32px grid and horizontal3-cell occupied mask are read at runtime. Exchanging the logical axes gives the proposed east mask `[(0,−1),(0,0),(0,1)]`; the nearest west cell outside this mask is `(-1,0)`, hence physical work-foot offset **(−32,0)**. The earlier modular prototype's(−24,0) seat marker is explicitly rejected as off-grid. No bitmap is rotated by this logical operation.

The fixture uses exact east tabletop `Rect(−16,−80,32,96)` and floor footprint `Rect(−16,−48,32,96)`:32px elevation,48px near floor contact. The reserved32×32 work cell touches the west footprint edge without intersecting it. All chair/body offsets are render-only, atX0,+8,+12 andY0. Logical feet do not move. These are locally grid-correct assembly comparisons at deliberately spread showroom origins, not six approved catalogue placements or a room-navigation test.

Sources are `modular_desk_geometry.gd`, separately authored32×32 soft horizontal/vertical oak materials, `chair-east-v2.png`, `mira-east-seated-v3.png`, `theo-east-seated-v4.png`, and the registered `computer-east-v2` monitor/keyboard/mouse components. The worker and GameMain are absent. The existing approved room supplies only architecture/floor; its props are hidden in this isolated fixture.

The keyboard's actual10×20 outline is preserved at host-local(−15,−42); its interior sample is8×18. It remains west of the side monitor. A physical family match would be approximately11×31 based on the actual north31×11 keyboard, so its short length is not quietly accepted by fitting hands to it.

## Contact and support observations

Hand figures are actual skin-color pixels inside a reviewed hand-region rectangle, not an authored semantic hand collider or proof that every finger touches a key. Values below cover typing frames2/3/4/5.

| Actor | Chair/body X shift | Samples over short keybed by typing frame | Hip band relative to observed chair top | Interpretation |
| --- | --- | --- | --- | --- |
| Mina |0 |0/28,0/29,0/29,0/30 |−3..−1px | All sampled hands outside tabletop; no useful contact |
| Mina |+8 |8/28,9/29,8/29,7/30 |−3..−1px | Some reach;10–11 sampled pixels remain outside top |
| Mina |+12 |18/28,18/29,18/29,18/30 |−3..−1px | All sampled hands over top; useful contact candidate only |
| Theo |0 |0/12,0/12,0/14,0/18 |−4..−2px | All sampled hands outside tabletop |
| Theo |+8 |0/12,3/12,3/14,5/18 |−4..−2px | Incomplete/inconsistent reach;7–11 samples outside top |
| Theo |+12 |11/12,10/12,12/14,12/18 |−4..−2px | All sampled hands over top; useful contact candidate only |

Observed chair support band is around native chairx40–60,y96–97, relative to pivot(48,112). Mina's estimated hip/underside rows53–55 and Theo's52–54 are preserved, not normalized to a single invented socket. The near-underseat appearance in `support-frame2.png` is promising, but the small character-specific vertical differences are anatomical estimates, not validated attachment metadata. Horizontal translation cannot change them.

All36 pose/offset combinations retain zero head pixels hidden by the side monitor. Monitor direction and head readability are an improvement over the north rear-head obstruction. This does not establish keyboard/device family proportions.

## Concrete native failures

1. **Lower-body occlusion fails (P0 code/layer contract).** In `native-frame2.png`, the right-hand Mina example shows white legs/brown shoes aroundx908–918,y269–287 on top of the wood; Theo's shoes similarly occupyx905–921,y521–535. Nearest details `native-frame2-mira-x12-4x.png` and `native-frame2-theo-x12-4x.png` make the impossible depth unmistakable. The whole actor currently sits in front of the tabletop. Changing the whole actor behind it would also hide its hands; the next study must preserve source pixels but split upper/lower rendering around the actual hip region.
2. **Whole-chair ordering cannot be accepted (P0 layers).** `chair-front-frame2.png` compares the entire chair above the body. Depending on frame, it covers191–197 opaque Mina pixels and147–168 Theo pixels; its armrest/backrest/seat are not independently depth-owned. Baseline whole-chair-behind also hides the prospective near armrest behind the body. Neither ordering is an authored reusable chair-layer solution.
3. **Endpoint jump is unimplemented (P1 animation).** `standing-endpoint.png` retains physical feet at the work cell; seated examples jump0/8/12px toward the desk. Even the0 shift swaps standing to seated anatomy instantly. The diagnostic movie does not disguise this as a polished pull-in/stand-up path.
4. **Keyboard mismatch remains (P1 art).** The short, busy native keys are visible beside the hands. Keep this marked as a failed component proportion, not an accepted small keyboard variant.

Caption headroom and footing were measured before every native capture. Header is atY100, assembly anchorsY288/536, captionsY352/600, and footerY660. None overlaps the measured native art bounds or leaves the1280×720 viewport. These labels are diagnostic only, not proposed game UI.

## Disposition and next gate

Preserve this baseline unchanged. Next is a separate source-preserving upper/lower actor crop study atX+12, comparing hip cuts50–55 across both actors and all six frames. Recombination must exactly reproduce every original48×80 source frame, and the lower body must be occluded by the actual tabletop without chopping hands or making a seam. Then independently validate chair layer ownership and the actual keyboard proportions. None of those later successes should rewrite this baseline into an apparent pass.

Initial development preflight compared JSON float arrays directly with integer arrays and reported a false mismatch. It was corrected to compare explicit grid vectors before final runs. No production geometry changed. `git diff --check` passed for the new harness. No renderer remains active from this task.
