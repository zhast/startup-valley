# Persistent HUD picking — independent bounded review

2026-09-04. **Confirmed and corrected; before evidence remains frozen.**
The parent changed only the ClockPanel and DeliveryMemo parent mouse filters
to STOP. This independent task owns the isolated probe/evidence, not the
production change. No artwork, geometry, worker or lifecycle change.

## Focused after verification

The later after snapshot passes **60 headless assertions** and **72 native
assertions**, zero failures. All six surfaces now own GUI hover/click, suppress
the hidden employee highlight, create no world action/route, and preserve an
already-running route when clicked. Earned still exposes its revenue tooltip.
The real View button opens Theo's Activity tab and dismisses his delivery memo.
After closing that drawer, the hidden memo no longer intercepts Mina's visible
body, and unobscured floor still receives a real click-to-walk.

All six complete HUD crops are byte-identical before/after: clock
(371,8,408,68) or memo(24,18,310,84). Only input ownership changes; whole-screen
equality is not asserted because hover state, route feedback and office ambient
frames can differ. Time and memo-blank after PNGs were inspected at native size.
The world-only picker still correctly reports the underlying Mina internally;
the GUI boundary now prevents that lower surface becoming an action.

[After native record](../../game/tests/output/clock-world-occlusion-after/native.json),
[after headless record](../../game/tests/output/clock-world-occlusion-after/headless.json),
[after Time](../../game/tests/output/clock-world-occlusion-after/time-hidden-employee.png),
[after memo](../../game/tests/output/clock-world-occlusion-after/memo-blank-hidden-employee.png).
The output contains six after PNGs, separate from all six original before PNGs.

Focused provider-free regression snapshot after these two filter changes:

- Station hover: 288 checks, zero failures.
- Visible-surface picking: 32,230 checks, zero failures.
- Reader/HUD: 203 checks, zero failures.
- World UI presentation: 468 checks, zero failures.
- UI foundation: 196 checks, zero failures.
- Existing run_all and complete-game real-input suites: passed.

These are later focused headless regressions plus the six native HUD cases,
not a claim that the earlier full static/motion checkpoint was rerun. No
additional failure was found. The original read-only scope/limits below still
apply.

~~~sh
godot --headless --path game --fixed-fps 30 --script res://tools/probe_clock_world_occlusion.gd -- --after
godot --path game --fixed-fps 30 --script res://tools/probe_clock_world_occlusion.gd -- --after
~~~

## Original finding and before proof

P1: the opaque persistent clock and active delivery memo do not consistently
own pointer input. Day/Time labels and the clock parent are IGNORE; the memo
parent, heading and detail are IGNORE. Consequently GameMain sees no hovered
GUI control, highlights an employee hidden behind the HUD, and routes a real
click through the paper to that employee. Earned already uses a STOP label
for its tooltip, so the adjacent part of the same clock behaves differently.

This is not a generic complaint about intentionally noninteractive floating
world labels or station-hover paper. Those should remain noninteractive.
It concerns opaque screen-fixed HUD surfaces above the playable world.

| Real mouse point | Visible HUD surface | Actual before result |
|---|---|---|
| (448,44) | Day column | Hidden Mina highlighted;18-point employee route |
| (560,44) | Time column | Hidden Mina highlighted;15-point employee route |
| (704,44) | Earned value | GUI owns hover/click;no route or hidden highlight |
| (176,44) | Active delivery heading area | Hidden Mina highlighted;27-point employee route |
| (166,60) | Delivery detail area | Same hidden employee route |
| (164,84) | Blank delivery paper | Same hidden employee route |

Mina's feet are at x448/560/704/176, y112 as appropriate. The ordinary room
navigation confirms these are legal top-floor positions. The fixture uses
ordinary unsplit production body art; no actor/profile source is changed.
The rendered Day, Time and Earned test pixels exactly equal the opaque ledger
source pixel, proving the click is on visible paper, not on an exposed body.
The native memo views likewise show only paper at the tested locations.

Source: [ClockPanel scene](../../game/ui/clock_panel.tscn), its
[child filter setup](../../game/ui/clock_panel.gd),
[DeliveryMemo construction](../../game/ui/founder_hud.gd),
and [GameMain hover/unhandled input](../../game/world/main.gd).
The world-only alpha picker is doing its stated job; the missing boundary is
GUI ownership before world input.

## Before proof

[Isolated probe](../../game/tools/probe_clock_world_occlusion.gd) installs the
existing null worker before GameMain enters the tree. It injects real motion
and mouse down/up, records GUI hover, current hidden-body highlight, pending
interaction and route count. Each case starts from a fresh scene. The delivery
memo enters through its normal160ms entrance; only its later timeout is held
for stable diagnostic input. No worker process, saved company or provider call
is used.

- 24 headless setup/evidence checks, 0 probe failures.
- 30 native setup/capture checks, 0 probe failures; 6 native 1280×720 PNGs.
- Those are successful reproduction checks, **not passing behavior assertions**:
 five cases record the bug, and Earned is the correctly blocked control case.
- Headless and native dispatch results agree.

Immutable evidence:
[headless record](../../game/tests/output/clock-world-occlusion-before/headless.json),
[native record](../../game/tests/output/clock-world-occlusion-before/native.json),
[Day](../../game/tests/output/clock-world-occlusion-before/day-hidden-employee.png),
[Time](../../game/tests/output/clock-world-occlusion-before/time-hidden-employee.png),
[Earned](../../game/tests/output/clock-world-occlusion-before/earned-hidden-employee.png),
[memo heading](../../game/tests/output/clock-world-occlusion-before/memo-heading-hidden-employee.png),
[memo detail](../../game/tests/output/clock-world-occlusion-before/memo-detail-hidden-employee.png),
[memo blank](../../game/tests/output/clock-world-occlusion-before/memo-blank-hidden-employee.png).
Time and memo-blank were independently inspected at native scale; the recorded
pixel/source check supports the clock obstruction in all three clock cases.

## Other inspected scope, no additional concrete issue found

The read-only trace covered VisibleSurface.painted/depth/in_front/top,
PlayerAvatar.body_surface_at, employee full/split body exposure and cleanup,
TownRoom.surface_at, ordinary prop rebuild, roster removal, and the existing
station-hover UI boundary. Existing tests already cover hidden/zero-alpha
founders, inherited zero-alpha modulation, transparent body holes, shadow-only
pixels, equal-depth sibling order, body departure/split cleanup, foreground
station masking, real rail/composer clicks and a STOP button over a station.

No new stale-node issue was found in normal lifecycle paths: prop rebuild and
roster removal detach nodes before queue_free; removed employee IDs are erased
before later picking. Retained split Sprite2Ds are hidden, so painted rejects
them. The helper's is_instance_valid and visible-in-tree gate protects removed
sprites; callbacks do not await midway through surface iteration. This does
not promise safety for arbitrary external free() calls that bypass the owning
roster, cross-canvas/Y-sort extensions, shaders, or every UI state.

## Original narrow recommendation

Make only ClockPanel's full panel and the active DeliveryMemo parent STOP.
Keep child decorative labels IGNORE, existing Earned tooltip controls STOP,
the View button actionable, and floating world prompts/hover papers IGNORE.
Do not add furniture bounds, scale artwork, change world picking, or create a
HUD-specific gameplay action.

Verify all six before cases become no world hover/no route; existing route
should also remain unchanged when clicking these surfaces. Verify View still
opens the corresponding delivery, Earned tooltip remains reachable, a hidden
memo releases its old area, and ordinary free floor clicks still work.
The parent implemented this correction; the focused after evidence above
verifies it without changing the original before record.
