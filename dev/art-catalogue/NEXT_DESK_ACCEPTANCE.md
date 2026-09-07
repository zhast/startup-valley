# Next desk acceptance: finish one direction, not another broad asset batch

2026-09-04. Read-only synthesis of current source and frozen native reviews.
No new capture, generation, registry change or production admission.

**Recommended order: new South assembly → West → East → North.** Preserve the
existing playable legacy South until its replacement actually passes. A clean
six-frame endpoint is necessary but is not sufficient to enable a direction.

## What is gated today

- [OfficeLayout](../../game/world/office_layout.gd#L309) requires an explicitly
  declared facing, complete independent geometry/layers, `runtime_ready`, and
  true `art`, `geometry`, `poses` review flags. Desk capability checks require
  **both Mina and Theo** to have that direction's seated and typing frames
  ([lines374–383](../../game/world/office_layout.gd#L374)). Mina-only East
  approval cannot currently make the shared desk direction ready.
- [CharacterArt's production registry](../../game/character_art.gd#L21) contains
  only `legacy-office-v1`, South. Calibration registration is editor-only,
  actual-texture validated and live-owner scoped
  ([lines44–91](../../game/character_art.gd#L44)); it is not a production loader.
- Important integration work remains: seated depth lock, grounded shadow/X
  follow, seated-thinking reuse and calibrated cue attachments currently have
  explicit **calibration-only** gates. Simply changing JSON review flags would
  either reject the profile or lose those presentation behaviors. Plan an
  explicit reviewed production capability path, retaining absent-field legacy
  behavior—not removal of editor/owner guards. See
  [OfficeLayout359–371](../../game/world/office_layout.gd#L359),
  [EmployeeAvatar139–170](../../game/actors/employee_avatar.gd#L139), and
  [CharacterArt155–164](../../game/character_art.gd#L155).

These are deliberate closed gates, not a discovered shipped safety leak. The
seated/typing admission check does **not** certify all other job states; the
following explicit acceptance matrix must cover them before promotion.

## Per-facing decision

| Direction | Keep this exact current recipe | Blocking decision or correction | Optional polish, not a reason to regenerate everything |
|---|---|---|---|
| **South first** | Physical work foot `(0,-32)`; chair `+4Y`; both actors `+12Y`; cut50; upper/lower/monitor depths from the canonical fixture. | Re-score the complete current assembly, with supported shadow and state transitions. The old isolated endpoint scored2.33; later finish/material scores do not retroactively approve it. Verify support and all terminal/standing transitions without tabletop legs or chair-through-body frames. | Rear monitor naturally hides hands/keys. Do not put hands in front of it just to advertise typing. Dedicated bend/sit drawings are optional if a simpler reviewed transition is genuinely clear and non-clipping. |
| **West second** | Work foot`(+32,0)`, chair`(-12,0)`, Mina`(-12,+4)`/cut50; Theo`(-12,+8)` with registered atlas and cuts`48,48,47,47,47,48`. | Keep source-aware cuts: do not reapply the baked Theo Y registration or revert to fixed48 after translation. Review the keyboard's head-adjacent placement and full entry/exit with grounded X-follow shadow. | Remaining exposed one-pixel sole/cushion phase variation is documented minor source variation, not the old green lap stripe. Decide its acceptability visually rather than claiming it absent. |
| **East third** | Work foot`(-32,0)`; chair`(+12,0)`; Mina`(+12,+3)`, Theo`(+12,+4)`; cut52; E4 keys/mouse`+6X`, fixed monitor. | Theo's key reach remains borderline: frame2's contour is adjacent, not on the keybed; frames1–3 have no sampled skin-tip/keybed overlap. Resolve/explicitly review plausible contact for both employees. Cut52 also leaves a small upper-lap strip; decide from the actual native image, not whole-hand overlap percentages. | The earlier whole knees/shoes-over-table and whole-chair paint-through are already fixed. Do not redo them or move keys back under the face. +8X is rejected; +4X is only a crowded reach control. |
| **North last** | Work foot`(0,+32)`; chair`-12Y`; Mina`-20Y`, Theo`-16Y`; monitor`-10Y`; keys/mouse`+4Y`. | Actual seat plane remains inferred behind a whole backrest; verify an exposed seat/registered chair partition. Mina's source identity/back/leg proportions and missing satchel detail remain endpoint problems. Actual leave swaps to a standing/front source while still at`-20Y`, putting her on/in the chair; this is a visible pose/depth boundary failure, not just a missing cosmetic tween. Hand contact remains incompletely demonstrated. | The old severe monitor obstruction is already corrected (Mina3–4%, Theo0% sampled lit-screen occlusion). Do not redo that fix. A universal uniform rescale is not justified: standing and seated upper head envelopes already match25×24. |

Executable recipe authority: [calibrated fixture](../../game/tools/calibrated_workstation_fixture.gd#L180).
Evidence: [South source layers](SOUTH_ACTOR_LAYER_REVIEW.md),
[West layers](WEST_SUPPORTED_LAYERS_REVIEW.md) plus
[later Theo registration](THEO_WEST_REGISTRATION_REVIEW.md),
[East keyboard](EAST_KEYBOARD_PLACEMENT_REVIEW.md),
[corrected North monitor](NORTH_MONITOR_SOCKET_REVIEW.md),
[actual North mount boundaries](MINA_NORTH_MOUNT_CONTRACT.md), and
[rejected rescale shortcut](MINA_NORTH_RESCALE_FEASIBILITY.md).

## Minimum next-run acceptance, one direction at a time

1. Freeze one exact material/finish recipe and its source hashes. Quiet grain
   and finish-v2 are useful candidates, but their separate review is not a
   complete workstation score. Preserve native48×80 bodies, full registered
   furniture canvases, binary alpha, exact source-part union, fixed floor pivot,
   unchanged device proportions and integer sampling.
2. Reuse the existing actual-GameMain fixture: both employees, two idle plus
   four typing frames, loop boundaries, exposed support and assembled native
   views. Score the whole direction: no category below2, mean≥2.5. Do not
   average independent material or geometry reports to manufacture a pass.
3. Exercise real approach, every transition tick, pause/reentry, leave and
   failure/cancellation/delivery. Test thinking, approval, research departure,
   lunch and restored work with honest supported/standing behavior. New
   specialist poses are unnecessary; safe and readable state coverage is not.
4. Retain physical-foot navigation/reservations; no blocked-cell crossings,
   hidden position repair, duplicate layer pixels or easing Z through a chair.
   Apply the proven grounded shadow policy: floor Y, seated snapped X, below
   all own furniture. Restore ordinary body/shadow/cue state on pose loss.
5. Reuse focused tests: `test_furniture_directions`, `test_workstation_facing`,
   `test_calibrated_workstation`, `test_seat_transition`, `test_calibrated_thinking`,
   `test_calibrated_work_vfx`, and `test_grounded_shadow_x_follow`. Then real
   alpha/depth picking, founder occlusion, station hover, occupied R/Undo,
   wall/corner/all0–4 office stages, import/validation and gameplay suites.
   Existing proofs are baselines; rerun only affected scope while iterating.
6. Only after native independent review, add the bounded production pose/art
   path and that one facing. Test with no calibration owner and in a non-editor
   export-capable environment; fail closed on missing art/poses. Preserve old
   South saves/defaults and unapproved directions. Production export policy
   itself remains a separate documented release gap.

Fancy chair pull-in, bespoke turns, tiny wheel/metal details and matching every
wood mark are optional polish. Unsupported hips, lost identity, actual
chair/body intersections, detached hands/shadows and wrong state-layer ownership
are not. The North mount original plus three retries already failed alpha and
exhausted that bounded request; do not rename it to reset retries. No new image
request is recommended before the South/West acceptance path is exercised.
