# Engineer North: resting-side composition

2026-09-04, approximately09:51 UTC. **Preferred North resting-equipment composition; staged only.** No new image generation, source alteration, actor mechanic, employee/backend or production activation. The original centered engineer and both grounded-shadow studies remain frozen.

## Result

Moving the existing N2 mat28px left materially improves its readability. Across Mina and Theo's six original seated/typing frames, **605–637 of640 pixels remain visible (94.5–99.5%)**, versus **133–169 (20.8–26.4%)** when centered beneath the employee. The circuit board and breadboard are fully visible at their original native dimensions throughout all captured poses and approach/leave samples.

[Centered versus resting, native](../../game/tests/output/resting-north-engineer/centered-resting-native.png) — left pair centered, right pair resting; top seated frame0, bottom typing stress frame2. [Nearest4× comparison](../../game/tests/output/resting-north-engineer/centered-resting-4x.png). [Actual room](../../game/tests/output/resting-north-engineer/frame0.png). [All six poses](../../game/tests/output/resting-north-engineer/frame-all-native.png).

This is equipment parked next to the employee, **not a probing gesture or active engineer work station**. The two seated idles are scale references; four existing typing frames deliberately stress occlusion and remain semantically incompatible with operating these tools.

## Exact geometry and preservation

- Existing source: `engineer-mat-v1/north-v2.png`, native32×20,640 opaque pixels,18 colors. Its full source rectangle is preserved, with no crop, rescaling, reflection, rotation, recoloring or alpha extraction.
- Original mat bounds relative to the fixed desk pivot: `(-16,-42,32,20)`. Resting bounds: **`(-44,-42,32,20)`**; only X changes by−28.
- The exact desk top is `(-48,-48,96,32)`. Its true wood interior after the2px rim is `(-46,-46,92,28)`. The new mat leaves **2px left,4px top,58px right,4px bottom** inside that wood. One further pixel left fails the required two-pixel inset.
- Actual room bounds: Mina `(292,230,32,20)` and Theo `(740,230,32,20)`. Both maintain the original logical work cells, chair anchors, standing/seated body sockets and all pose/depth layers.
- The fixture retains the already-reviewed scoped `grounded_work_shadow` plus X-follow policy. No shadow movement is introduced by this placement change.
- Tests compare the full profile dictionaries: only the North `EngineerMat.offset` differs. E/S/W profiles, artwork, geometry and actor metadata remain identical. Existing visual/hit bounds remain correct because the plate stays inside the measured desk silhouette; collision and navigation are untouched.

## Native measurements

| Employee | Centered projected body overlap | Resting body overlap | Resting visible mat |
|---|---:|---:|---:|
| Mina, six frames |478–507px |3–16px |624–637/640 |
| Theo, six frames |471–502px |14–35px |605–626/640 |

The original hand/body artwork is unchanged. Small remaining occlusion is at the mat's right edge, especially Theo's hair/right-probe area; this is not presented as a completely unobstructed tool set. The board annotation `(10,8,11,6)` and breadboard annotation `(10,1,12,5)` are the same explicit visual measurements from the original review, not automatic segmentation or newly extracted objects. **4,788 rendered region pixels** across nineteen scenes match the original board/breadboard colors exactly, proving those details stay visible without resizing.

**24,320 mat/depth pixels** match the actual original source, actor and furniture compositing. **337,920 before/after scene pixels** are compared across twelve160×176 workstation crops: all changes are inside the union of original/new mat rectangles, with **zero unrelated body, chair, shadow or furniture changes**. The six centered X-follow frame-image hashes and both referenced source/native mat hashes remain unchanged.

## Real approach, departure and review

The actual GameMain dev fixture walks both actors through their existing navigation and seat interpolation, then returns them home. The movie records **149 continuous frames /298 actual physics ticks**, including every enter/leave interpolation frame;24 per-actor transition/endpoint records are stored in the manifest. Path safety, exact physical destinations, scoped shadow coordinates/depth, and a mid-transition pause are asserted.

[Complete enter samples](../../game/tests/output/resting-north-engineer/enter-all-native.png), [complete leave samples](../../game/tests/output/resting-north-engineer/leave-all-native.png), [returned home](../../game/tests/output/resting-north-engineer/returned-home.png). The final leave contact crops are empty because the actors have actually moved home elsewhere in the room; the full screenshot shows their real endpoint.

Reviewed the native centered/resting comparison, all-six pose sheet, both full transition sheets, actual room and returned-home screenshots, plus Mina typing frame2 and Theo typing frame3 at4×. The plate has an intentional visible rim gap, the green board and pale breadboard read beside the employee instead of disappearing beneath hair, and it remains stable during entry/departure. No source pixel or actor alignment was changed to make this result.

## Disposition and limits

Use this as the **preferred North resting-kit recipe** for future integration. It resolves the centered North composition problem without regeneration. It does not approve the complete engineer set: E/W boards remain physically larger than N/S, some probe-tip directions remain ambiguous, and the side plates can read as upright panels. Existing standing-to-seated pose interpolation still lacks authored bend/sit frames. Those frozen [engineer findings](ENGINEER_MAT_COMPOSITION_REVIEW.md) remain open; do not enable or claim a four-direction working engineer station based on this placement study.

Review score0–3: pixel coherence2, perspective2, silhouette/readability3, layering/anchors3, cross-view identity1, placement3; mean2.33. The complete set does **not** meet runtime acceptance. The North-only placement improvement is recommended, while source/direction and active-use art remain gated.

## Verification and paths

Final focused headless: **1,631 checks,0 failures**. Final native: **2,250 checks,0 failures,62 PNGs** =19 actual room scenes,38 nearest4× crops,five native/comparison sheets. `ffprobe` confirms **175 movie frames at30FPS,1280×720**:149 route frames,21 still holds,five setup frames. No hidden-shadow readback is needed in this study.

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_resting_north_engineer.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/resting-north-engineer/resting-north.avi --script res://tools/capture_resting_north_engineer.gd
```

[Headless results](../../game/tests/output/resting-north-engineer/results-headless.json), [native manifest](../../game/tests/output/resting-north-engineer/manifest.json), [movie](../../game/tests/output/resting-north-engineer/resting-north.avi). Renderer exited0 and was released to the V3 floor study. `git diff --check` passes. The fixture's NullWorker blocks real transport/bootstrap/save access; no paid calls or personal state mutations occur.

Only new files: `game/tools/resting_north_engineer_fixture.gd`, `game/tools/capture_resting_north_engineer.gd`, `game/tests/test_resting_north_engineer.gd`, and this review. All shared production code and original evidence are untouched.
