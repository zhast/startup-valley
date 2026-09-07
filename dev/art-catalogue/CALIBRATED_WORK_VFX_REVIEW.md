# Calibrated work cues and requested names

September 4, 2026, 08:35 UTC. **Developer-only presentation mechanism accepted for the tested fixture; no production-facing or complete workstation art approval.** No pixels were generated, repainted, mirrored, scaled or re-exported.

## Proven defect and correction

The [first quiet North thinking capture](../../game/tests/output/calibrated-thinking/reviewed/after-north-idle-0.png) puts Mina's bulb around `(336,209)` directly on the monitor, with the same problem for Theo around `(784,209)`. The fixed body-relative cue followed the newly supported seated body correctly, but that position was inappropriate for this assembly. Moving the body or monitor would conceal the presentation bug by disturbing their separate calibration.

The [actual calibration fixture](../../game/tools/calibrated_workstation_fixture.gd) now supplies an optional `work_vfx_anchor_by_character` in its owner-scoped `thinking` and `typing` pose definitions. The anchor is relative to the workstation's existing prop pivot. Its full 24×24 frame ends at least four pixels above both:

- The union of the actual native desk, chair and computer layer ink.
- The earliest head ink in all six source cells, at both endpoints of that employee's seated correction.

This is a derived, explicit fixture attachment, not a global direction constant or a new production furniture profile. `attach_work_vfx_above_assembly=false` reproduces the original cue origin without removing quiet seated thinking. [CharacterArt](../../game/character_art.gd) rejects missing/extra actors, malformed arrays, non-integer/non-finite/out-of-range coordinates, and attachments to unsupported pose names. Nothing is added to the immutable legacy registry.

| Gaze | Anchor from prop pivot, Mina and Theo | Full cue rectangle in ordinary Mina test scene |
| --- | --- | --- |
| North | `(0,-89)` | `(324,171,24,24)` |
| East | `(-20,-96)` | `(304,164,24,24)` |
| South | `(0,-116)` | `(324,144,24,24)` |
| West | `(20,-96)` | `(344,164,24,24)` |

Both employees happen to resolve to the same per-facing anchor because their furniture bounds or earliest source-head extent dominate. These remain per-character measurements, not an assumption that their bodies match.

[EmployeeAvatar](../../game/actors/employee_avatar.gd) uses the attachment only for an admitted, stationary, live thinking/typing presentation at its assigned desk. The cue stays fixed while the body follows the existing 140ms seated interpolation. Walking, failure, completion, unsupported actions and all legacy production poses retain the original body-relative cue path. The original four-frame `PolishArt.WORLD_VFX` regions and real event meanings are unchanged; no second cue or progress indicator is added.

## Names must remain discoverable

Reserving the new cue in the existing callout layout uncovered a second problem: North's chair, desk and cue blocked all eight actor-relative nameplate candidates. The [intermediate diagnostic](../../game/tests/output/calibrated-work-vfx/before-nameplate-fallback-north.png) has no overlapping labels only because both requested names are missing. That was not accepted as a successful fix.

[GameMain](../../game/world/main.gd) now:

1. Includes only **visible, explicitly admitted calibrated work cues** in its label/prompt obstacles. Hidden or suppressed cues return an empty rectangle; legacy cues never add an obstacle.
2. For a requested hover/proximity name with no ordinary candidate, tries the perimeter of that calibrated employee's complete assembly. Every candidate still checks the full paper and authored pointer against the real actor, other furniture, cues, earlier labels, HUD, rail, drawer and modal obstacles.
3. Keeps normal placement first and leaves all unrequested and legacy name placement unchanged. A genuinely blocked/modal viewport can still suppress a callout; this fallback never paints through UI.

The [final North names](../../game/tests/output/calibrated-work-vfx/north-thinking-labels.png) appear below the chairs: Mina's complete paper/pointer bounds are `(270,310,132,63)` and Theo's are `(718,310,132,63)`. The [nearby two-desk scene](../../game/tests/output/calibrated-work-vfx/nearby-north-thinking-labels.png), with desk pivots only 128px apart, keeps Mina below at the same bounds and places Theo to the right at `(514,227,141,54)`. Both remain visible, inside the viewport, and disjoint from each other and both workstations. [Typing](../../game/tests/output/calibrated-work-vfx/nearby-north-typing-labels.png) preserves those placements and changes only the actual event cue/status.

## Repeatable evidence and verification

Run from the repository root; the fixture replaces the worker leaf before scene readiness and never creates a transport or personal save:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_calibrated_work_vfx.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/calibrated-work-vfx/work-vfx.avi --script res://tests/test_calibrated_work_vfx.gd -- --motion
```

- [Focused suite](../../game/tests/test_calibrated_work_vfx.gd): **20,031 headless / 20,301 rendered checks, zero failures**. [Headless results](../../game/tests/output/calibrated-work-vfx/results-headless.json), [rendered manifest](../../game/tests/output/calibrated-work-vfx/manifest.json).
- **90 current 1280×720 captures**, plus the separately preserved one-image rejected nameplate diagnostic. The manifest records source cue regions, actual source-body bounds, visible label bounds, event/state, attachment and capture paths. It advances **265 motion ticks** across four facings and the nearby North case.
- [Movie](../../game/tests/output/calibrated-work-vfx/work-vfx.avi): **370 encoded frames at 30FPS, 12.333333 seconds**, independently checked with ffprobe. Capture/setup frames account for the difference from simulation ticks. Playback is not claimed as watched.
- Tests cover all four event-atlas phases for thinking and typing, both actors and all four facings, every sampled seat interpolation step, highlighted/selected states, one cue sprite only, exact native sampling, no head/monitor/furniture intersection, 4px minimum clearance, playfield/HUD/rail bounds, and complete label/pointer visibility.
- An actual employee drawer is opened; GameMain propagates its pause to actors. Repeated incoming typing/completion events continue to update the cue without moving physical feet/body, restarting seat interpolation or creating more tweens. The open drawer remains an obstacle. Failure immediately releases the scoped label obstacle and restores the existing terminal cue origin. Registry teardown revokes the attachment.
- The nearby scenario uses a validated canonical room placement and a real job-start route, not a teleported seated actor. Its longer route gets 300 deterministic ticks rather than the ordinary 150; the initial shorter test timing failed before arrival and was corrected without changing locomotion.
- Affected regressions pass: quiet thinking **8,519/0**, canonical workstation **6,684/0**, directional capability **249/0**, generic seat transition **4,671/0**, world UI **422/0**, gameplay smoke and project validation. No worker contracts or dependencies changed, so no paid or backend evaluation was run.

Native inspection covered the four ordinary thinking-label scenes, a typing scene in every facing, North/South interpolation, selected/failure reset, and the final North/nearby thinking and typing scenes. The North bulb is visibly separated from the monitor; East/West cues stay above the complete desk, and South cues clear both bodies. Requested names are no longer hidden to achieve an overlap pass.

## Explicit limits

- This does not approve the underlying four-direction furniture art, inferred North seat contact, hand/keyboard contact, mount/turn animation or missing research/approval/delivery poses. The [quiet-thinking review](CALIBRATED_THINKING_REVIEW.md) and all original evidence remain unchanged.
- The scope is stationary live thinking/typing. Existing moving and terminal cues deliberately keep their prior positioning; for example, North failure smoke can still cross the monitor during the old standing/reset presentation. It is not claimed fixed by this work.
- Native review covers the ordinary and nearby fixture placements, not every wall/corner or arbitrary UI-scale combination. A future runtime admission pass must test those placements and decide how cues should behave if a workstation's top attachment approaches the HUD or viewport edge.
- Ordinary body-relative name placement remains unchanged outside the admitted calibration scope. The larger perimeter fallback is for requested names, not a new always-on card or additional attention signal.
- No production asset registry, JSONL schema, worker event semantics, files, saves, catalogue checkpoint or existing source art were changed. The renderer was released after the final run.
