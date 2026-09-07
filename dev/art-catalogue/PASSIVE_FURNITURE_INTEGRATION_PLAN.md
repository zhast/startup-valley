# Passive furniture — approved bounded integration plan

Approved by the parent on 2026-09-04. Implement a canonical **dev-only use** of explicit decorative profiles with the existing native layer, collision, navigation and editor pipeline. No production catalogue/layout, save, worker contract, actor behavior, main/HUD code, generated art or gameplay action changes.

## Scope and safeguards

1. Add `profile_kind: decorative` to OfficeLayout. Require explicit occupied/clearance cells, anchor, native visual bounds/layers and ambient attachment list. Optional hit bounds remain enclosed in visual bounds. Reject interaction, work, seat, service and pose fields rather than synthesizing zero cells. Only art/geometry approval gates apply.
2. Optional `standing_viewpoints` contain a clear cell and a conservative visual envelope enclosing `(-24,-72,48,80)`. They protect human viewing headroom only; no gaze, target, prompt, service action or worker operation results. Each belongs to explicit clearance. Empty viewpoints are valid for passive objects without a viewing requirement.
3. Exact merged candidate definitions may be admitted only on their own model by a live editor-scoped owner. Definition mutation, another owner/model, configuration replacement or teardown invalidates admission. Candidate status and false review values remain honest. No CharacterArt capability is borrowed.
4. Return decorative placements before generating action/work/seat fields. Preserve occupied cells, whole-art wall checks, clearance, visual overlaps and global floor/entrance reachability. Skip only target checks for targets that genuinely do not exist. Validate optional viewpoint headroom independently.
5. Preserve the existing seven PackedScene factory paths. A generic native-layer Node2D is available only for a validated explicit decorative placement, never as an arbitrary unknown-kind fallback. Use existing native sprite and collision application. Painted decorative surfaces occlude clicks without returning an interaction; no workstation visual metadata is exposed.
6. Keep editor preview/R/commit/undo/actor-conflict handling. Do not draw invented zero-cell interaction dots or routes, or describe a passive prop as a seat. The calibration fixture disables export; no layout/save writes.
7. A disposable GameMain fixture copies room/catalog data and adds only whiteboard and rolling-pedestal candidate families. Reuse frozen exports, adding one source-preserving registered whiteboard South planning insert if required. Native import settings must preserve decoded alpha/RGB. Teardown and a new ordinary scene prove no registry/model/navigation leakage.

## Verification

- Strict malformed/mixed profile, missing review/art, invalid transform, empty/duplicate cell and no-silent-fallback checks.
- Exact-definition/live-owner admission: authorization, mutation, wrong owner, owner death, model copy and cleanup.
- Both families and all four views in real room/editor: matching ghost/native rectangles, R input and click commit, undo, invalid wall/corner/overlap rollback, actor obstruction without teleport, real pathing around occupied cells.
- No interaction/work/seat/service keys in resolved passive data, no HUD/action target, no click-through to an obscured interactive station or actor; normal existing services remain available.
- Conservative viewpoint bounds cannot be missing, malformed or shrunk once a viewpoint is declared; no special action point is manufactured when viewpoints are empty.
- All 0–4 hire-stage layouts remain valid. Existing legacy South tests/pixel baseline remain applicable and are not waived. Parent runs combined regressions after shared source freeze.
- Rendered inspection at native 1280×720 and nearest detail, with current limitations of the reviewed furniture preserved. Tests are proportional; counts do not constitute visual approval.

## Ownership

This agent owns OfficeLayout, TownRoom, the developer office editor, and new passive fixture/tests/capture/helper files. Do not modify EmployeeAvatar, GameMain, FounderHUD or other agents' active work. Coordinate renderer after the reader's scale test. No commits or production admission in this task.

References: [whiteboard contract](MOBILE_WHITEBOARD_CONTRACT.md), [whiteboard review](MOBILE_WHITEBOARD_REVIEW.md), [pedestal contract](ROLLING_PEDESTAL_CONTRACT.md), [pedestal review](ROLLING_PEDESTAL_REVIEW.md).
