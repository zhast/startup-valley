# Completion acceptance matrix

September 6, 2026. **Accepted: the finite art-completion objective is complete.**
The revised [goal](../OVERNIGHT_ART_GOAL.md) has no deadline or instruction to
exhaust credit. All work remains local; no commits, pushes, paid worker jobs,
personal-save changes, credential changes or production dependencies were added.

| Required outcome | Evidence / current disposition |
| --- | --- |
| Seven active furniture families have actual N/E/S/W production art and geometry | Accepted in [production checkpoint](PRODUCTION_AND_LIBRARY_CHECKPOINT_20260906.md); shared desk/chair/computer count as three atomic catalogue families, not three additional world systems. |
| Fixed camera, correct anchors, walls, collision, approach, rotation and Undo | Actual production tests for each active family plus layout, migration, editor, modular-office, architecture and surface picking. Latest consolidated headless checkpoint below. |
| Founder/Mina/Theo movement, workstation contact and state/leave transitions | [Four-facing workstation](FOUR_FACING_WORKSTATION_PRODUCTION_REVIEW.md), [collaboration production](../COLLABORATION_PRODUCTION_REVIEW.md), locomotion and grounded-shadow regressions. Both supported employees exercise directional poses; passive-library actors remain scale/contact probes. |
| Complete finite 42-family / 168-view catalogue | Accepted: all42 families /168 views,36 runtime-integrated and132 approved passive views. No planned, blocked, staged or cleanup family directions remain. [Final native batches and rejected versions](PASSIVE_ACCEPTANCE_20260906.md). |
| Distinct profession-specific toolkits on real compatible hosts | Ten approved four-facing passive role sets include founder, product/research, growth/ads, legal, creative, engineering, finance and support. [Acceptance](PASSIVE_ACCEPTANCE_20260906.md). This creates no employee backend or live service. |
| Approved architecture, notebook UI, typography C and color roles preserved | Dedicated UI tests, 27 native statics, two motion suites and three window sizes pass on the final implementation. Reconnect rail state and caption fit are corrected and natively reviewed; no skin replacement. |
| Optional materials/UI/portraits reviewed without replacing approved defaults | [Terrazzo v4](TERRAZZO_V4_REVIEW.md) is an explicitly staged bright-floor alternative; wood remains default. [Portrait framing](SPECIALIST_PORTRAIT_CROP_REVIEW.md), [engineering/finance](ADDITIONAL_PORTRAITS_REVIEW.md) and [support portrait](CUSTOMER_SUPPORT_PORTRAIT_REVIEW.md) remain isolated concepts, not a rail or roster migration. Failed studies and source masters remain retained. |
| Catalogue, provenance, dimensions, hashes, statuses and gallery agree | Catalogue validator 30,626 checks plus 107 self-tests pass, including required-layer lifecycle agreement. All 127 original PNG masters remain indexed. Deterministic editable art is separately attributed, never counted as ImageGen masters. Generated Markdown and HTML are current; builder 56 self-tests and explicit freshness check pass. |
| Actual game / accessible viewer input and rendered evidence | Final actual-game capture and 30 real-browser checks pass. The browser proves exact source/served hashes, all per-view lifecycle values and header totals, native/4× images, real links/input, focus and responsive width. Root inspected all eight final browser PNGs. [Frozen browser evidence](BROWSER_REVIEW_20260906.md). |

## Current regression evidence

`game/tests/output/art-completion-20260906-final-fit/headless-results.json` records
33 clean invocations: import, project validation and31 listed current-production
regression entry points. Every invocation exits0 without `ERROR` or `SCRIPT ERROR`.
Production source/art hashes are unchanged before/after. `run_all.gd` is a smoke
test, not falsely described as every project test.

The same final checkpoint's `render-results.json` contains seven clean invocations:
27 isolated1280×720 statics; world2322frames/six scenarios and UI1128frames/six
scenarios at30FPS; both movie probes and motion-manifest validation; and442
window checks across native1280×720, integer2×2560×1440 and1600×1000 letterbox.
Root inspected all27 native statics. Independent reviewers inspected all12
motion contact sheets with relevant native keyframes, and18 window full/detail
images. This is not a claim that every AVI frame was watched manually.
The letterbox PNG captures the1600×900 content; its manifest records50px top
and bottom margins, rather than pretending the PNG proves OS window bars.

The final reconnect repair adds an explicit pending state shared by the rail
and connection page. The rail says disabled secondary `Linking…`; the main
surface retains `Reconnecting…` and Back to game. A failed attempt restores
Reconnect; success restores Settings and clears stale diagnostic copy. Its 24
real-input assertions prove one dispatch for double-click, no disabled rail
activation, usable Back to game, restored Settings and measured text/style
content fit. The first `art-completion-20260906-final` run passed functional
checks but failed root visual review: `Connecting…` clipped in the narrow rail.
That evidence is retained. Only the short caption changed; no font shrink or
rail enlargement. Root inspected the corrected final-fit native keyframe.

Byte comparison against the independently reviewed `check2` set proves all
27 static PNGs, all 24 world motion PNGs, 38 of 39 UI motion PNGs and all 18
window PNGs unchanged. The only different PNG is the corrected reconnect
checkpoint. The six UI contact sheets do not happen to sample that exact
moment; its dedicated native keyframe and required semantic marker do. Both
full movies were newly recorded, not copied from the older run.

The prior `art-completion-20260906-check1` is deliberately retained as a failed
run. `test_directional_input.gd` spawned at `(464,464)`, now inside the enlarged
accepted collaboration cluster. Six movement expectations failed because
physics resolved the actor out of that obstacle, despite correct input mappings.
The fixture now starts at the clear central aisle `(640,624)`, explicitly proves
the origin, directional corridor and click target are safe, and retains real
input events, route cancellation, direction checks and chat-focus blocking.
It passes80 checks; neither game collision nor the input map was relaxed.

The new repeatable [runner](../tools/run_art_completion_regression.mjs) requires
a unique checkpoint name and refuses to overwrite its evidence manifest.
Its headless and renderer phases are separate to coordinate one native window.
It rejects nonzero exits and Godot error text, records exact commands/logs and
guards current production files. Historical prototype scripts are not treated
as mandatory production gates.

## Explicit scope limits, not concealed completion claims

- Passive catalogue approval is reusable artwork with demonstrated host/room
  placement, not automatic production availability or a new gameplay service.
- Seven active families are integrated; optional role/decor items remain in the
  browsable library until separately chosen for gameplay.
- Renovation is session-local. This art objective does not change the worker's
  persistence schema or imply layout persistence after restarting.
- Existing material and specialist portrait alternatives remain optional review
  specimens. No unchosen full UI skin, future hire or legal/ads action is added.
- Existing window review covers controlled native, integer2× and letterboxed
  sizes. Do not describe that as actual OS fullscreen testing.
- Native visual acceptance is bounded by the documented0–3 rubric, not a claim
  that every possible layout, hardware configuration or frame is defect-free.
- Before distributing a release, define and test an export allowlist (F52).
  No distributable package or actual OS-fullscreen certification is claimed.

## Final acceptance decision

Root and an independent read-only audit found no remaining required art,
actor-contact, placement, catalogue or UI item. The final two gates—fresh
hash-bound browser acceptance and native reconnect/caption verification—are
now closed. The 42-family backlog is complete, with 36 integrated atomic views
and 132 approved reusable passive views; optional concepts are not counted as
accepted runtime assets. Historical failures and scope limits remain visible.
