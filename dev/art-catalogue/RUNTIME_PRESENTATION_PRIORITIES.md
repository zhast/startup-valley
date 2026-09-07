# Current runtime presentation: bounded next priorities

2026-09-04, approximately09:56 UTC. Read-only review of the frozen [AFTER checkpoint](REGRESSION_CHECKPOINT_AFTER_ARCHIVE.md) and current source. No new renderer, broad test, asset, gameplay mutation or production edit. Three findings are worth prioritizing; padding the list to five would overstate the evidence.

The frozen capture uses the first default-off grounded-shadow implementation. Later X-follow code is not present in that snapshot, but no production profile enables either option. Cue/nameplate clearance, sentence case, approved archive activation and crop-bleed fixes are excluded, as are already-documented staged desk/mount problems.

## 1. P1 — Click picking is not consistent with the visible surface

**Code-only. Evidence: exact source path plus screenshot geometry; not a newly executed click test.**

- In [employee-idle-cycle-middle.png](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/world/employee-idle-cycle-middle.png), Mina's visible monitor occupies approximately `(317,220,39,29)`. Pixel **`(336,234)`** visibly belongs to the monitor, but lies inside Mina's whole48×84 actor hit rectangle. [GameMain `_interaction_at`](../../game/world/main.gd#L595) checks employees first and immediately returns one before considering furniture. It does not compare the actor's alpha or visible depth against the desk. The source-derived result is Chat selection from a visually desk-owned pixel instead of the desk's Assign/Activity interaction.
- In [office-hires-4.png](../../game/tests/output/regression-checkpoint-after-archive/visual-review/office-hires-4.png), **`(210,466)`** is bare floor beside the founder desk's chair. The desk's catalog bounds are `(208,464,128,112)` in world space. [TownRoom `interaction_at`](../../game/world/town_room.gd#L257) accepts that whole rectangle; [OfficeLayout](../../game/world/office_layout.gd#L235) defaults hit bounds to visual bounds. Transparent padding therefore behaves like clickable furniture and can steal click-to-walk.

**Next bounded fix:** resolve visible actor/prop candidates using their actual native layer alpha and depth, then apply an explicit small accessibility margin rather than treating transparent source-cell padding as an object. Preserve the current action destinations and worker methods. Add real mouse tests at both points, plus visible face/desk clicks and empty-floor neighbors; ensure a seated employee remains easy to select through the rail. This is a picking/UI change, not permission to alter collision or chair geometry.

## 2. P1 — Useful stations have almost no discoverable hover feedback

**Code-only using existing callout/icon assets. Evidence: current source confirms absence; screenshots establish the affected visible surfaces. No hovered-frame capture was present in this frozen subset.**

The archive at **`(96,352,96,96)`**, founder desk around **`(220,473,104,103)`**, and approval console around **`(892,352,104,84)`** in [ui-founder-hud.png](../../game/tests/output/regression-checkpoint-after-archive/visual-review/ui-founder-hud.png) are usable stations, but their appearance gives no action label or stable hover highlight. [GameMain lines127–137](../../game/world/main.gd#L127) resolves a prop hover, then updates only employee highlighting and the OS pointer shape. [FounderHud `update_interaction`](../../game/ui/founder_hud.gd#L153) only accepts employees, so its authored pointer/keycap family never identifies the archive or founder desk.

**Next bounded fix:** one small existing-style station callout on hover/focus—“Studio,” “Company Journey,” or “Activity”—and immediate subtle outline/pressed feedback. Use the real prop's visible bounds from priority1; reserve callout space with the existing world-label solver. Do not add permanent labels to every decorative object, make coffee/research clickable without implemented actions, or generate another broad UI batch. Native acceptance should include mouse movement, one rendered-frame feedback, drawer occlusion and overlapping employee/prop candidates.

## 3. P2 — Lunch uses a floor-sitting work pose in front of the lounge

**New pose/attachment art or a deliberately simpler presentation; not a clipping/collision failure. Visually evidenced.**

[schedule-cycle-middle.png](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/world/schedule-cycle-middle.png) shows Mina and Theo at approximately **`(320,410,31,54)`** and **`(351,411,34,53)`**, sitting cross-legged on the floor below three empty beanbags `(272,364)` through `(397,418)`. The office looks as though employees missed the furniture. This is actual schedule presentation, not a staged rotated-workstation fixture.

[EmployeeAvatar lines374–375](../../game/actors/employee_avatar.gd#L374) sends lunch to the shared lounge interaction position; [TownRoom](../../game/world/town_room.gd#L337) returns the generic collaboration interaction cell. [EmployeeAvatar lines819–821](../../game/actors/employee_avatar.gd#L819) then chooses work-pose row0 and a seated shadow, with no lounge seat/relaxed-break pose mapping.

**Next bounded choice:** either an honest standing-break idle near the lounge using existing standing art, or a separately authored relaxed seated/coffee-break pose and supported lounge sockets. The former is a narrow code-only coherence fix; the latter requires new art plus collision/reservation/contact review. Do not slide the current cross-legged sprite onto a beanbag and call it a validated seated animation. Keep the lunch schedule/worker state unchanged.

## Checked, but not proven defects

- Native architecture/props: no new wall intrusion is visible in the reviewed stage4 and depth samples. Coffee begins near `(84,120)` and research near `(884,124)`, below the wall/floor line aroundy96; the production archive is clean. Existing different prop perspectives/detail density are known replacement work, not new discoveries.
- Ambient attachments deserve a **targeted four-frame check**, not an assumed fix: coffee center `(164,142)`, research scan center `(944,146)`, prototype center `(944,520)` follow `coffee_station.tscn:15`, `research_table.gd:18`, and `prototype_bench.tscn:14`. `OfficeAmbientOverlay._process()` advances independently at5FPS. The frozen stills do not prove a floating overlay, incorrect source alpha, or a pause bug; some ambient movement during a paused UI can be intentional. Do not regenerate or reposition these on the strength of that hypothesis alone.
- No new production floor-shadow/depth defect was established beyond previously documented staged workstation behavior. The new grounded policies are explicitly default-off.

## Suggested order

Do visible-surface picking first, then station hover feedback using the same resolved target. Make the lunch presentation decision separately because it may need original art. These are smaller, higher-confidence improvements than another general furniture generation pass. All coordinates above are native1280×720 screenshot pixels; behavior claims are labeled as screenshot observation versus source-derived inference.

Reviewed native files: stage4, founder HUD, world speech, employee-idle middle, job-state middle, schedule middle, and depth/occlusion middle/end. This was a bounded current-runtime review, not a review of every historical source or a claim that untested behavior is clean.
