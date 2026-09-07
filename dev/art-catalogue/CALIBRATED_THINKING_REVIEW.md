# Calibrated quiet seated thinking

Developer-only mechanism and source-reuse checkpoint, September4,2026. **No new generated art, no production direction or complete workstation approval.** This report freezes the first unobscured thinking result; a subsequent cue-placement study should retain these images as its before evidence.

## Finding and narrow correction

The calibrated workstation supplied seated and typing regions, but no thinking capability. Real `job.started` / `tool.completed` therefore reached `WORKING` with the honest standing fallback. At the South work cell, the chair painted across both employees' torsos rather than supporting a seated person. See the [before South scene](../../game/tests/output/calibrated-thinking/reviewed/before-south-standing-thinking.png), particularly Mina around(322,184)–(352,226) and Theo around(770,178)–(800,226).

The original two seated-idle frames naturally read as resting quietly at a workstation. Their hands are settled rather than cycling through the four typing frames. Reusing these is sufficient for a **quiet seated-thinking presentation**, not evidence of new thinking gestures or active tools. The [after South scene](../../game/tests/output/calibrated-thinking/reviewed/after-south-idle-0.png) shows the same bodies supported in front of their chairs, with torso regions around(322,194)–(352,225) and(770,188)–(800,225). No chair, actor or desktop pixels were repainted or moved by this change.

## Explicit capability and state meaning

- The owner-scoped [calibration registry](../../game/tools/calibrated_workstation_fixture.gd) opts into `thinking` by duplicating the exact `seated` definition, adding `reuse_pose: seated` and `presentation: quiet_seated_thinking`. Setting `reuse_seated_idle_for_thinking=false` before adding the fixture reproduces the old behavior for A/B evidence.
- [CharacterArt](../../game/character_art.gd) validates identical texture, region, frame count and per-character upper/lower cuts. A typing strip, mismatched cut, missing provenance, recursive alias or different presentation is rejected. Existing strict String-key admission remains intact.
- [EmployeeAvatar](../../game/actors/employee_avatar.gd) uses this presentation only for live `WORKING` + `thinking`, stationary at the assigned desk, inside a surviving calibration registry. No state enum, worker event, job flag, reservation or physical navigation coordinate is reinterpreted.
- Quiet thinking advances only idle columns0–1 at1.5FPS. Actual typing still requires the existing typing state and uses columns2–5 at8FPS. The seated shadow and existing discrete layer depths apply while thinking; the140ms visual offset does not restart on thinking→typing→thinking.
- Moving, completion, failure, a lost live-job flag or fixture teardown removes the capability/body layers. Unsupported research, approval and delivery remain unsupported in this calibration set. Existing production South thinking continues to use `*-work.png`, row1/column4, with its original rendering behavior.
- A UI pause freezes physical movement and seat interpolation. Incoming real events still update presentation; gentle body/cue animation continues, matching the existing event-visual policy. This is not a change to worker timing or business-clock semantics.

## Reused native sources

Every listed source is unchanged; use columns0–1 in48×80 cells with the existing(24,72) foot anchor. North bodies stay whole. East cuts at52, South at50, West Mina at50 and Theo idle at48. Cuts are exactly those already used by the corresponding seated state.

| Facing | Mina native source | Theo native source |
| --- | --- | --- |
| North | [mira-north-seated-v2.png](../../game/tests/fixtures/furniture-calibration/characters/mira-north-seated-v2.png) | [theo-north-seated-v2.png](../../game/tests/fixtures/furniture-calibration/characters/theo-north-seated-v2.png) |
| East | [mira-east-seated-v3.png](../../game/tests/fixtures/furniture-calibration/characters/mira-east-seated-v3.png) | [theo-east-seated-v4.png](../../game/tests/fixtures/furniture-calibration/characters/theo-east-seated-v4.png) |
| South | [mira-seated.png](../../game/assets/runtime/characters/mira-seated.png) | [theo-seated.png](../../game/assets/runtime/characters/theo-seated.png) |
| West | [mira-west-seated-v2.png](../../game/tests/fixtures/furniture-calibration/characters/mira-west-seated-v2.png) | [theo-west-seated-v3-registered.png](../../game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered.png) |

## Verification and native evidence

Run from the repository root with the worker disabled:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_calibrated_thinking.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/calibrated-thinking/reviewed/quiet-thinking.avi --script res://tests/test_calibrated_thinking.gd -- --motion
```

The headless run creates the output directory; the test never launches a worker or accesses a personal save.

- New [thinking suite](../../game/tests/test_calibrated_thinking.gd): **8,519 headless /8,735 rendered checks, zero failures**. Reports: [headless](../../game/tests/output/calibrated-thinking/reviewed/results-headless.json), [rendered manifest](../../game/tests/output/calibrated-thinking/reviewed/manifest.json).
- Existing canonical fixture: **6,684 headless checks, zero failures**; the formerly standing-thinking assertions now require explicit seated-idle source reuse. Its earlier rendered `actor-safe-editor` output remains the before-reuse baseline, not a new render claim.
- Existing directional suite249/0, generic seat transitions4,671/0, gameplay smoke and project validation pass. No worker suite was needed because no contracts or worker code changed.
- The reviewed output contains **72 unique1280×720 screenshots**,16 motion sequences and312 explicitly advanced simulation ticks. The [movie](../../game/tests/output/calibrated-thinking/reviewed/quiet-thinking.avi) contains408 encoded frames at30FPS,13.6seconds, including capture/setup frames; independently checked with ffprobe. Playback is not claimed as watched.
- Native inspection covered both idle frames for both actors in all four facings, the South before/after contrast, and paused incoming typing/return-to-thinking. Per-frame tests prove the whole-body/source-layer buffers reunite exactly, preserve disjoint ownership and stay integer-aligned. Physical feet stay walkable, reservations unchanged, and duplicate events create no additional tweens.
- The first output in the parent `calibrated-thinking/` directory is **rejected diagnostic evidence**: deferred Connect AI opened over Theo. The corrected harness waits for that explicit fixture onboarding defer, closes it, and asserts no connection/drawer overlay in every reviewed capture. Only the `reviewed/` subdirectory is accepted as unobscured evidence here.

## Native review and remaining limits

| View | Reuse result | Remaining limitation |
| --- | --- | --- |
| South | Both actors' chair/torso collision is removed; idle and typing keep the same support and source cuts. | Monitor naturally hides hands; this does not certify hand contact or mounting animation. |
| North | Both actors remain in their previously studied supported whole-body assembly. | **Existing thinking cue overlaps the monitor display**, near(336,209)/(784,209), because the fixed−78px cue now correctly follows the supported body. Needs a scoped work-VFX attachment, not artwork movement. Hips remain hidden by the rear chair. |
| East | Quiet body retains exact52px source split; no new layer seam was observed. | Existing lap strip and Theo's key-edge reach remain; no active tool-contact approval. |
| West | Reused idle preserves the registered Theo source and its48px idle cuts. | Existing head-adjacent keyboard and one-pixel sole/cushion variation remain. |

This accepts the **bounded quiet-idle reuse and state/layer mechanism**, not all workplace actions or the complete four-direction furniture set. Dedicated mount/turn poses, unprovided work actions and the North cue-placement defect remain separate work. The frozen07:55 catalogue was not changed.
