# Mina North: native mount/dismount art contract

2026-09-04. **Reference capture and proposed art contract only. No new image, pose, production capability or animation was added.** This is one Mina/North study, not a contract automatically approved for Theo or other facings.

## What the live transition actually does

The [reference capture](../../game/tools/capture_mina_north_mount_reference.gd) uses the actual calibrated GameMain, EmployeeAvatar, CharacterArt, AStar path, Sit/Leave buttons and current 140ms seat preview. It does not teleport Mina to the desk, substitute a synthetic pose or interpolate pixels. The source frame and physical/rendered positions are recorded for every selected state in the [manifest](../../game/tests/output/mina-north-mount-reference/manifest.json).

Use the [native assembly contact](../../game/tests/output/mina-north-mount-reference/assembly-contact-native.png), read six columns per row in manifest order. [Fixed-physical-foot actor contact](../../game/tests/output/mina-north-mount-reference/registered-contact-native.png) removes furniture occlusion without changing a source pixel. [Standing versus seated identity at 4×](../../game/tests/output/mina-north-mount-reference/identity-standing-seated-4x.png) places the original North idle cells side by side at the same scale.

Three concrete problems remain:

1. **There is no bending or mounting source animation.** At arrival the source changes immediately to seated idle A; the exact same cell/hash moves through Y offsets **0, −3, −9, −16, −20, −20**. Its head rises from world **y236 to y216**. Hips/legs are initially exposed beneath the chair back, then vanish as the unchanged silhouette rises. This is a five-step translation, not five authored poses.
2. **The endpoint has an identity/proportion mismatch.** Both existing standing and seated sources were normalized to a 68px opaque height. The seated source has a visibly lengthened rear hair/back mass, compressed legs, and loses the visible satchel silhouette. In [the identity pair](../../game/tests/output/mina-north-mount-reference/identity-standing-seated-4x.png), this is already apparent before furniture or runtime offsets. Transition frames alone cannot guarantee a coherent endpoint. The standing locomotion reference is the identity/scale authority; old North seated is only a contact/intent reference.
3. **Leaving changes pose, facing and occlusion before standing up.** The real Leave button immediately selects a front-facing walking source at the old **−20Y** visual offset, with physical feet still **(336,304)**. Depth jumps from **292 behind chair293** to **304 in front of it**. The next four ticks advance physical feet to **y318.667** while the visual offset returns to zero. [Leave boundary at 4×](../../game/tests/output/mina-north-mount-reference/05-leave-pose-boundary-assembly-4x.png) therefore looks like Mina standing on/in the chair. No rise or turn is authored.

The source-aware discrete depth lock still prevents the earlier *interpolated-Z* defect. It cannot choose a believable pose boundary by itself. These findings supplement, rather than invalidate, the previous [canonical integration](CANONICAL_WORKSTATION_INTEGRATION.md) and [North socket study](NORTH_MONITOR_SOCKET_REVIEW.md), which already kept mounting/support unapproved.

## Frozen geometry for the next art trial

All dimensions below are measured current candidate geometry, not a final anatomical approval.

| Element | Desk-local coordinates | This fixture's world coordinates |
|---|---|---|
| Desk floor pivot D | (0,0) | (336,272) |
| Blocked floor footprint | (−48,−16,96,32) | x288–383, y256–287 |
| Tabletop | (−48,−48,96,32) | x288–383, y224–255 |
| Reserved physical work foot P | (0,+32) | (336,304) |
| Whole chair floor pivot C | (0,+20), or P−12Y | (336,292) |
| Current seated actor render pivot | (0,+12), or P−20Y | (336,284) |
| Keyboard outline | (−17,−29,31,11) | x319–349, y243–253 |
| Monitor base support rows | (−7,−46,14,3) | x329–342, y226–228 |
| Inferred chair seat line | y+4, or C−16Y | y276 |

Chair source is [chair-north-v1](../../game/tests/fixtures/furniture-calibration/chair-north-v1.png), native **96×160**, pivot **(48,112)**. The North seat line is inferred from a side-family view; the opaque backrest hides it. **An exposed-seat/registered chair partition remains a separate acceptance gate.** Do not claim that a generated person's knees prove a chair surface which is not visible.

Current depth recipe is desk rear D−1/front D+1, monitor/keys D+2, seated actor D+20, whole chair D+21. This is a recorded baseline, not permission to swap a whole standing person behind the chair at the start of every new animation.

## Minimum useful authored set

Start with **seven new keyposes**, plus the exact existing North standing idle for reference: one 4×2 working sheet, native **192×160** with **48×80** cells. The native standing/front/side locomotion frames remain reusable endpoints; do not regenerate a complete walking atlas.

| Cell | Pose | Essential visual change |
|---|---|---|
| 0 | Existing North standing idle reference | Reuse the actual native cell when integrating; generated approximation is never the authoritative endpoint. |
| 1 | Pre-sit brace | Small weight shift and hand reach toward the unseen chair arms; knees still support standing weight. Show a coherent route into the chair, not passage through its back. |
| 2 | Half-lowered | Knees visibly bend, hips move toward the seat, torso leans slightly forward; preserve head/body scale. |
| 3 | Supported seated endpoint | Compact seated anatomy matching standing Mina's identity; thighs/hips and relaxed arms visible in actor-only art. This must be rechecked against the current keyboard and chair before replacing the old endpoint. |
| 4 | Rise preparation | Lean forward from that exact seated identity; hands brace, feet become weight-bearing. Not an unchanged seated bitmap moved downward. |
| 5 | Nearly upright, still North | Hips clear the seat before the body returns to its standing silhouette. |
| 6 | Rear-to-left three-quarter turn | An actual intermediate orientation after standing clears the chair. |
| 7 | Left-to-front three-quarter turn | Connects to existing front locomotion for the demonstrated Southward exit; not automatically applicable to another exit direction. |

This is a minimum *trial*, not a promise that seven drawings guarantee smooth movement. If pre-sit requires a lateral chair-entry step, author its body pose and declare the small visual socket separately. Do not move a collision foot into blocked desk cells. Keep the chair as separate art. A later pull-out/pull-in chair motion may be justified, but is not silently baked into this character sheet.

### Registration, anatomy and export rules

- Every native cell is **48×80**, fixed source pivot **(24,72)**. The pivot is a registration reference, **not a command that every crouched/seated sole must touch row71**. Keep at least one transparent border pixel and preserve the standing cell's eight bottom padding rows where it applies.
- One global scale determined from standing Mina's body/head, one shared palette, one common crop grid and one fixed origin for the entire sequence. **Never resize each pose to 68px height, independently bottom-align each crouch, or head-center every animation frame.** Those operations erase authored motion and can create the existing taller-looking seated body.
- Genuine alpha; no floor, chair, tools, table, cast shadow, colored matte, checkerboard or baked guide. Max 48 colors after deterministic normalization. Binary alpha and nearest sampling at runtime. Retain the original master, prompt, crop metadata and failed trials.
- Current P−20Y is a candidate correction for the old source, not an immutable target for new anatomy. For a newly drawn hip row `h` and measured chair seat line `s` relative P, the required render offset is **`offset_y = s + 72 − h`**. With today's inferred `s=−28`, that is `44−h`; old `h≈64` produces −20. An anatomically compact `h≈52` would imply approximately −8. This is an example to test, **not a preapproved replacement socket**.
- Resolve the endpoint's supported hip, keyboard/wrist reach, head proportion and chair depth together. Reject a pose whose identity can only be repaired by whole-body stretching or hiding its hips. Source landmark masks should be manually reviewed semantic evidence, not treated as proven anatomy merely because skin-color pixels intersect a rectangle.
- Work poses must not silently remove Mina's satchel/strap. Retain what should be visible or explicitly model a later bag-removal/storage action; this task does neither. Long hair may be naturally occluded by a chair, not lengthened in the source to fill its backrest.

## Required future playback behavior

The new drawings need a separate reviewed pose timeline; **do not feed them into the current seated-idle loop and call the 140ms translation complete**. A proposed starting cadence is mount around 240–320ms and rise/turn around 300–400ms, with immediate input feedback. These are world-action trial timings, not a change to the existing 80–180ms preview API or UI transition timings.

Keep the physical work foot and its reservation fixed while a supported mount/stand pose owns the chair. Release actual walking only after the feet and body clear it; then use existing pathing. Pose/layer changes should occur at authored support/clearance frames. Do not ease Z through solid furniture, teleport the person, or let a route move underneath a still-seated image. Pause must freeze the visual timeline; interruption should finish a safe rise or reverse a proven partial mount from its actual frame. Business cancellation/worker events should remain immediate and unchanged.

For this first trial, gate on **North arrival and Southward departure only**. Other departure headings, Theo, all other workstation facings, research/approval/delivery and chair animation are subsequent coverage, not implied by this sheet.

## Ready-to-run ImageGen brief and references

Use [the complete prompt](prompts/mina-north-mount-v1.md). Root should read the ImageGen skill and view each reference before calling the built-in generator. No image request was started here.

Suggested reference order:

1. [Standing/old-seated identity pair, 4×](../../game/tests/output/mina-north-mount-reference/identity-standing-seated-4x.png): left is identity/scale authority; right documents the proportions to improve, not a required duplicate.
2. [Mina locomotion](../../game/assets/runtime/characters/mira-locomotion.png): authoritative outfit, bag, standing/back/side/front silhouette and pixel scale.
3. [Current supported assembly crop](../../game/tests/output/mina-north-mount-reference/04-idle-a-assembly-4x.png): geometry/context only; do not draw the chair, desk or monitor into the new cells.
4. [North chair](../../game/tests/fixtures/furniture-calibration/chair-north-v1.png): contextual backrest/arm geometry only, seat still unproven.

## Deterministic acceptance strategy

1. **Source gate:** true alpha, exact native cell grid after one global normalization, transparent borders, unchanged master hashes, no clipped/missing limb, no per-frame scaling. Record actual head/shoulder/hip/knee/sole and palm bounds per pose; review them at native and 4×. Existing standing endpoint must remain byte-identical when reused.
2. **Endpoint gate first:** render corrected seated body alone, with a transparent-chair diagnostic, then fully layered. Verify actual seat support, clothing identity and keyboard contact. Do not spend effort on smooth transitions to a failed endpoint. Keep baseline P−20 and tested alternatives as separately labeled candidates.
3. **Frame-by-frame assembly gate:** use the same real fixture and input route as this reference. Capture every authored state and every actual render tick near entry/exit, including last walking → first brace, first fully supported seat, seated loop boundary, first rise and return to locomotion. Inspect face/feet/hips/chair edges; compare support/layer ownership at each boundary, not just endpoint hashes.
4. **State/input gate:** assert physical foot/reservation remains stable during mounting/rising, no blocked cells, one actor body, deterministic source/depth selection, integer transforms, interruption/reentry/pause without source pop, occupied-rotation rejection, normal walking cancellation once safely clear, and teardown/independent scene isolation.
5. **Perceptual gate:** visually score pixel coherence, projection, silhouette, layering/anchor, identity/direction and placement. Every category ≥2 and mean≥2.5; a distinct source hash is not a passing animation score. Root independently reviews actual native clips/contact frames before any production admission.

## Captured evidence and limits

- [Headless alias](../../game/tests/test_mina_north_mount_reference.gd): **781 checks, zero failures**.
- Final rendered run: **920 checks, zero failures**, **22 selected states**, **169 actual actor physics ticks**, **117 PNGs** (22 × room/native crop/4× crop/exact48×80 source/registered actor =110, plus seven contacts/identity images).
- [Movie](../../game/tests/output/mina-north-mount-reference/mount-reference.avi): `ffprobe` confirms **1280×720, 30 FPS, 175 frames, 5.833 seconds**. Its actual path frames were recorded; the native assembly/source contacts and critical boundary 4× crops were inspected rather than claiming full video playback.
- Source-only references are exact original PNG region bytes. Existing locomotion's import changes some RGB under **zero alpha**; the harness reports those counts and independently proves identical alpha and every visible imported pixel. No alpha-border import or production file was changed to make the reference pass.
- A **96×112** transparent diagnostic canvas with physical pivot **(48,96)** shows the actual source translation without clipping; this is not a proposed runtime actor cell. Its inverse translation is checked byte-for-byte.
- Fixture registry teardown, no worker/process/bootstrap, unchanged actor/art/catalogue/room hashes and native scale are asserted. No paid job, save, image generation, production art admission or new mount logic occurred.

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_mina_north_mount_reference.gd
godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/mina-north-mount-reference/mount-reference.avi \
  --script res://tools/capture_mina_north_mount_reference.gd
```

## Subsequent ImageGen trial outcome — 2026-09-04

The coordinator subsequently submitted the initial mount request and **three targeted retries**. All four preserved masters, `game/assets/source/overnight-20260904/characters/mina-north-mount-v1.png` through `v4.png`, are RGB images with painted backgrounds rather than genuine alpha. The initial sheet also had a cross-legged seated cell and the wrong screen turn direction; later prompts targeted those errors, with v4 narrowed to a single seated endpoint. The actual source/prompt history is retained; none is a native export or approved endpoint.

**This asset's initial-plus-three attempt bound is exhausted.** Do not reset it by renaming the same request, infer a transparent cutout, manually paint away the checkerboard, or generate additional trials without new direction. There is no accepted native mount sheet, supported replacement endpoint or playback timeline from this batch. The source-preserving reference capture and contract above remain useful prior evidence, not proof that the failed generated art was integrated.
