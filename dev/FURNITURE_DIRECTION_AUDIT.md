# Directional furniture and camera audit

## Final acceptance — September 6, 2026

**Complete: 42 families / 168 reviewed N/E/S/W views.** Seven active furniture
systems are integrated into normal gameplay (36 atomic catalogue views); the
remaining 132 views are approved reusable passive furniture and role toolkits,
not new employees or services. All 127 original PNG masters, including failed
attempts, remain indexed and retained.

Final verification passes: 33 headless invocations, 27 static captures, both
30-FPS motion suites, 442 window checks, 30 real-browser checks, 30,626 catalogue
checks plus 107 self-tests, and 56 HTML-builder self-tests. The last reconnect
rail ambiguity and clipped caption are corrected and natively reviewed.
See the [catalogue](art-catalogue/index.html) and [acceptance evidence and limits](art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md).

No hard deadline or credit-exhaustion target. Everything is local and
uncommitted; no pushes, paid worker jobs, personal-save or credential changes.
Optional portraits/materials remain review concepts. Renovation is session-local;
release packaging and OS-fullscreen certification are not claimed.
All sections below are preserved historical checkpoints, not an unfinished queue.

## Historical checkpoint — September 6, 20:26 UTC

**136 accepted slots: 36 runtime-integrated and 100 approved library views.**
42 families / 168 directions / 127 retained original masters; 32 slots remain
planned. Utility v2 and the compact closed booth v3 pass native review. Lounge
v2 remains held for incorrect North/rear geometry; the desk lamp still needs
its full South shade restored above the host. Failed versions remain preserved.
See [current owners, evidence and remaining scope](art-catalogue/LIBRARY_CHECKPOINT_20260906_2026.md).
The goal is completion-driven: no hard deadline and no credit-exhaustion target.

## Historical production addendum — 2026-09-06 19:29 UTC

The seven active furniture families now pass their reviewed four-facing
production gates, including collaboration-cluster-v2:36exact layers, ten
occupied cells/facing, four sockets and two-employee seated lifecycle. Its
574headless/1056native checks verify occupied rotation rejection, pause,
entry/exit and vacant rotate/Undo; no unsafe samples or reservation conflicts.
The maximum continuous rendered step is4.47px. Default South is now `[12,14]`.

Legal v2 and compact/shared v2 bare bases have separate passive-library
acceptance. Static review also found two stale crowded callout probes that
produced PNGs without the intended UI; these fixtures now use clear floor and
assert actual prompt/speech visibility. No production avoidance rule weakened.
Full evidence, current counts and remaining42-family scope are in
[the current checkpoint](art-catalogue/PRODUCTION_AND_LIBRARY_CHECKPOINT_20260906.md).

## Historical production addendum — 2026-09-04 20:30 UTC

All seven active runtime families now declare N/E/S/W profiles. Explicit art
acceptance remains narrower than runtime registration: 32 catalogue slots are
runtime-integrated, including the archive, coffee-station-v1, shared workstation
base components, corrected research bench, decision console, and shared prototype-bench base. Coffee's
four service sockets are reachable geometry only and `interaction_enabled:
false` prevents any surface action. Collaboration retains its separately
documented multi-seat planning-contract gap.

Audit date: September 3–4, 2026. Scope: actual Startup Valley runtime, current native office captures, placement/renderer code, source exports and future art catalogue. This is an art/placement pass, not a new worker architecture or hiring backend.

## Bottom line

At the initial audit we had **seven active furniture families and one supported facing each**. As of09:12UTC the **archive has four reviewed production views**, while the other six remain South-only. This is one completed family, not a complete four-direction library. Current desks deliberately show monitor backs: the employee sits north and looks south. That is not in itself a backwards-desk bug. The broader inconsistency is different top-plane depth, detail density and contact treatment between separately generated props. Four-way support requires new art, actor poses, geometry, depth ordering and input/editor behavior together.

The modular room is already active; retired whole-room backdrops and old workstation masters are not evidence of what is being drawn. Do not rebuild the room around another baked full-scene bitmap.

## Evidence baseline

- Native captures: `game/tests/output/ui-material-audit-after/office-hires-2.png` and `office-hires-4.png` (1280×720).
- Runtime inventory: `game/data/furniture_catalog.json`; placements: `game/data/office_layout.json`.
- Active workstation: `game/assets/runtime/office/south-workstation.png`, two registered 128×112 layer cells. Research uses the registered `research-bench-v1/` layers.
- Initial standalone props: coffee142×94, archive136×90, approval132×88, prototype140×140; scenes use runtime scale1.0. Archive now uses registered192×288 layers from `runtime/office/archive-v1`; its original136×90 source remains preserved, not active. The collaboration table uses registered `collaboration-cluster-v2/` layers.
- Retired/not rendered: old office shell, campus, and background plates. The unused standalone workstation, research, furniture-sheet, and collaboration plates were removed from `runtime/office/`.

## Historical discovery ledger

The rows below retain each defect and its original checkpoint disposition;
words such as blocked, prototype or missing in these dated discoveries are not
the current catalogue lifecycle. Use the current checkpoint above and the
[completion acceptance matrix](art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md)
for final evidence. In particular, F28/F33/F37/F38 preserve failed raster
methods; later independently authored geometry/art or reviewed production
state transitions resolve their usable-deliverable requirements without
erasing failures or resetting generation retry counters.

| ID | Severity | Evidence / affected state | Correction | Disposition |
|---|---|---|---|---|
| F01 | P0 | `furniture_catalog.json`: all seven `facings` lists contain only south. | Catalogue N/E/S/W separately; authored art and validated metadata required before exposing each direction. | Generate new art + code |
| F02 | P0 | `office_layout.gd:153`: facing is recorded but the same cells/profile are translated. | Resolve one complete per-facing profile for geometry, bounds, work/interaction points and art; legacy south unchanged. | Code-only |
| F03 | P0 | `town_room.gd:156`, editor `:361`: fixed texture and layer assumptions ignore facing. | Shared canonical render-layer descriptors used in game and ghost/editor. No bitmap rotation/mirroring. | Code-only |
| F04 | P0 | `town_room.gd:87`: roster reconciliation writes south. | Preserve an existing valid facing; coordinate-only legacy worker records must not overwrite local authored orientation. | Code-only |
| F05 | P0 | `character_art.gd:72`, `employee_avatar.gd:593`: seated, typing, research, thinking and approval lack directional lookup. Locomotion and delivery already have four directions. | Reuse walking/delivery; author work directions and pass work-facing, anchor and pose capability from the resolved workstation. | Reuse + generate poses + code |
| F06 | P0 | `main.gd:299`, `employee_avatar.gd:355`, editor `:483`: only positions reach actors; catalog `seat_z_offset` is an editor guide rather than applied actor depth. | Make seated depth/anchor explicit and verify far/near/side occlusion in motion; preserve current valid south seating. | Code-only + pose/layer review |
| F07 | P1 | Current office captures: archive/coffee are relatively frontal, prototype and collaboration show more top plane. | Calibrate an empty desk/chair specimen against room axes and 48×80 characters before batching. Compare measured top surface and vertical rise, not unsupported claims about an exact Stardew camera angle. | Normalize or regenerate selectively |
| F08 | P1 | `ASSET_SPEC.md` calls origin ground contact; desk bounds extend to Y+16, research +8, standalone props approximately +2. | Distinguish footprint/sort anchor, seat point and opaque-bottom offset; certify all explicitly. Do not alter current coordinates merely to match imprecise prose. | Documentation + code validation |
| F09 | P1 | `build_polish_assets.sh:65,86`: research layers trimmed/centered independently; source row contains overlapping full bench drawings. | Registered complementary layers sharing one complete canvas and anchor, tested as a composite with actor. Existing south workstation already uses a registered split. | Normalize/re-export or generate research layers |
| F10 | P1 | `office_layout_editor.gd:198,496`: picker exists; no keyboard rotation, ghost uses fixed render assumptions. | Add direction cycling only through accepted facings, immediate invalid feedback, undo/export/reload and blocked-rotation rollback tests. | Code-only |
| F11 | P1 | `town_room.gd:203`: bounds/Y hit tests with hardcoded desk/archive/approval action list. | Resolve facing-specific hit/interaction geometry; specialist decor remains decorative until an explicit interface adapter exists. | Code-only |
| F12 | P1 | `office_ambient_overlay.gd:7`: scene-local attachments; no furniture-shadow contract. | Authored per-direction attachment/contact metadata; small separate ambient/shadow assets, not floor baked into furniture. | Code + small new art |
| F13 | P1 | `validate_project.gd:210`, `test_office_layout.gd:56`: south-only safety assertions. | Replace with complete authored-facing validation, retaining rejection of missing/unreviewed directions. Never just remove the safety test. | Code-only |
| F14 | P1 | All founder/Mina/Theo desks use the same family/art. | Shared calibrated bases + role-specific overlays, distinct silhouettes/tools and coherent lighting; future specialist sets stay staged, not fake hired employees. | Generate modular toolkits |
| F15 | P0 | Native four-view calibration looked plausible by alpha bounds but actual N/S tabletop depths were27/29 instead of32, rises41/37 instead of32; E/W rises34. | Validate surface plane and vertical rise independently of whole silhouette. Exact native geometry plus separate generated material tiles is now a tested dev alternative. | Code-native geometry + normalize materials; whole-prop candidates remain cleanup-required |
| F16 | P0 | `four-desks-standing-approach.png`: detached brown pixels above Mina's left-facing head. Old locomotion exporter cut unequal source rows into equal quarters. | Measured alpha gutters, common per-row scale and full native foot/head registration. Three locomotion exports rebuilt; original masters untouched. | **Fixed and tested**; see `LOCOMOTION_EXPORT_REVIEW.md` |
| F17 | P0 | East/west supported typing attempts bring knees and shoes visibly onto the tabletop when the complete actor draws in front. Moving the full body behind hides hands. | Source-preserving upper/lower work-pose layers with exact reconstruction, plus separately owned chair near-arm pixels. Native E/W studies and actual dev GameMain composition remove this defect without repainting characters. | Implemented through canonical dev pipeline; final art/runtime gates remain |
| F18 | P1 | First north kit shift hid most of the display behind the seated head; moving the whole kit displaced keyboard contact. | Separate registered monitor, keyboard and mouse objects. Move the monitor alone to a supported back-of-top socket. Native obstruction falls to3–4% Mina/0% Theo in the selected study. | Reuse/extract existing pixels + explicit component sockets |
| F19 | P1 | Shared chair/actor pivots conceal different hip heights across Mina/Theo/directions. Initial W normalization forced a32px five-spoke caster span and made the seat/back too tall. | Measure seat/back height first; test per-character visual correction without moving navigation feet. Uniform-height W alternative matches E seat within1px with a27px projected caster span. | Mechanical normalization + explicit anatomy/seat review |
| F20 | P1 | New supported sockets jump8–20px between standing and sitting endpoints. | Default-off dev140ms smoothstep transition, snapped rendering/hit/callout/shadow origin, interrupt/duplicate-event/pause tests. Actual canonical captures now exercise it. | Tested code mechanism; sliding mount and briefly exposed north feet still need authored transition review |
| F21 | P0 | Canonical south sit-down interpolates actor depth through chair layers, painting blue chair pixels through Mina's chest. | Optional validated seated depth lock switches layer ownership immediately while retaining integer XY easing. Before/after native motion proof in `CANONICAL_WORKSTATION_INTEGRATION.md`. | Fixed for admitted dev workstations; legacy depth unchanged |
| F22 | P0 | Rotating or undoing an occupied desk can block current actor feet and trigger a safety-position pop. | Validate newly occupied cells against live founder/employee foot envelopes before preview/commit/undo. Reject until actors leave; preserve history and coordinates. | Fixed and tested through actual editor input; migration safety unchanged |
| F23 | P0 | Invalid editor preview becomes an opaque colored padded rectangle although source alpha is correct. | Retain preview textures strongly through rendering instead of freeing local Texture2D while the canvas still holds its RID. | Fixed; native corner pixels match room |
| F24 | P1 | Canceling a rotation preview leaves an uncommitted facing selected for the next edit. | Restore committed facing on cancellation. | Fixed with rotation/cancel tests |
| F25 | P1 | Calibrated thinking falls back to unrelated standing art in a seated assembly. | Explicitly reuse that employee's admitted seated idle frames only for stationary thinking; restore ordinary paths on job/state/owner loss. | Quiet seated thinking implemented; no new gestures or tool behavior claimed |
| F26 | P1 | Work cue at a body-relative offset overlaps north monitor; avoiding it suppresses requested hover names. | Desk-pivot cue anchors clear full assembly and source heads; reserve cue bounds and use a checked whole-assembly label fallback only for admitted calibration. | Native all-four/nearby proof; wall/corner and legacy terminal cues remain separate gates |
| F27 | P1 | Legal N folder hides mouse10pixels; S mouse/cup touch top/front wood rim. | Fixture-only N folder−4Y, S mouse+1Y and cup−1Y, no source repaint. | Corrected native alternative passes1,196 rendered checks; W identity/E absence remain |
| F28 | P0 | Original legal E prompt specified W leaf order. Reclassifying it cannot invent a correct E view. | Preserve four failed E attempts and partial W reclassification; no bitmap rotation or retry-counter reset. | E blocked; W tabs/page/pen identity needs new authorized art, not position shifts |
| F29 | P1 | Centered creative tablet is90–98% hidden behind the actual seated employee. | Resting-left tablet with separate camera/swatches; remove keyboard/mouse rather than burying them beneath a tablet. | Native alternative clears actor pixels; no stylus-use animation yet |
| F30 | P0 | Explicit directional profiles assume every rotated prop has a seated work pose, even archives. | Separate standing-service profiles, side/opposite approach gaze, native actor headroom, geometry/render/interaction gates and scoped dev admission. | Fixed; archive productionNESW passes1,967headless/2,255rendered checks without calibration permits or fake poses |
| F31 | P0 | Navigation's nearest-free fallback can arrive beside an occupied service socket then open Studio from the wrong side. | Explicit services require both exact route endpoint and actual arrival at authored socket; reject or cancel otherwise. | Fixed with actual path/input/blocked-socket proof; legacy interactions unchanged |
| F32 | P1 | A geometrically legal archive near north wall leaves the standing visitor's head on wainscot. | Validate conservative native48×80 visitor envelope against room architecture at the service socket. Move fixture inward one row; never hide or relocate actor to fake clearance. | Fixed explicit-service headroom gate; natural body occlusion behind tall cabinet retained |
| F33 | P1 | Coffee E/W generated whole machines ignore deep top proportions and repeatedly return opaque checkerboards. | Initial+three targeted attempts retained for each view; stop retries. Exact geometry plus genuinely rectangular interior face crops is a tested alternative; accessories stay missing. | Whole-machine/alpha failure. Espresso-only volume passes geometry but readability1 blocks approval; no full E/W kit claim |
| F34 | P2 | Legacy Mina typing cue crowds nameplate pointer in frozen world job-middle capture; fallback wording title-cases `To Seat`. | Reserve actually painted 24 px event cells plus 4 px clearance; omit hidden/expired cues. Uppercase only first letter, preserving internal AI. | Fixed: 468 headless / 480 rendered world-UI checks and fresh AFTER native motion inspection confirm clearance and sentence case. |
| F35 | P1 | Specialist legal portrait face is small; current rail66×74 opening crops64×80 plates. | Source-preserving4:5 head/shoulders crops, native64×80 opaque portraits and unchanged palette. Explicit future rail/header/avatar contract. | B preferred for both after native review; not new employees or a production rail change |
| F36 | P1 | New floor candidates fail exact wrap; walnut hides dark silhouettes and cork is too busy. | Preserve baseline floor. Refine staged terrazzo edges and validate moving feet/shadows before optional activation. | ActualGameMain64headless/167rendered study complete; all three remain unapproved concepts |
| F37 | P1 | Engineer mat tools partly vanish at native 32×20; side-view boards grow physically; North is mostly hidden by the employee. | N2/S2 improve source readability/direction, but component dimensions and probe tips need correction. Test a resting-side placement separately from active tool use. | Actual-room review complete; all four remain unapproved. See `ENGINEER_MAT_COMPOSITION_REVIEW.md`. |
| F38 | P0 | Mina North mounting slides one seated pose vertically; departure immediately switches to front walking above the chair. Endpoint proportions differ from locomotion. | Preserve the measured contract and require original compatible mount/stand key poses. | Initial + three targeted generations exhausted with opaque checkerboards/anatomy defects. No cutout or animation activation; see `MINA_NORTH_MOUNT_CONTRACT.md`. |
| F39 | P1 | Calibrated South work shadows draw onto the desktop; physical-foot grounding leaves side-facing shadows beside the visual chair. | Default-off admitted shadow policy sorts below all own layers; the follow-up uses visual seat X and physical floor Y. | Fixed for explicitly admitted dev workstations: follow-up 21,057 headless / 10,833 rendered checks, source alpha preserved. No production desk opts in. See `GROUNDED_SHADOW_X_FOLLOW_REVIEW.md`. |
| F40 | P1 | Motion inventory hardcodes old layer names and omits the new archive. | Collect and validate every declared render layer, region, anchor and native transform. | Fixed: 11 negative/positive checks, 17 exact furniture layers present, zero flags in fresh AFTER motion audit. |
| F41 | P2 | Terrazzo V2 has sparse repeated bands; V3 replaces them with repeated scratch chains. | Preserve sources and exact global palette variants; reject visually obvious repetition even when opposite edge pixels match. | V2 movement and V3 native room reviews complete. Both have exact-edge candidates but fail visual repeat coherence. Default wood stays unchanged. |
| F42 | P2 | Role-specific archive front details disappear in rear/side views. | Record common N/E/W reuse honestly; do not imply a unique legal/creative service identifier from decorative fronts alone. | Native legal/creative fronts fit without seams; staged variants, not new hires or interactions. |
| F43 | P1 | Real click at monitor (336,234) selects hidden Mina; bare floor (210,466) selects transparent founder-desk padding. | Pick actual opaque actor/prop surfaces by their rendered depth; exclude shadows and status cues. | Fixed: real clicks route correctly, native before/after desk/body crop is exact; 32,230 headless / 32,269 rendered checks and seven targeted legacy suites pass. `VISIBLE_SURFACE_PICKING_REVIEW.md`. |
| F44 | P1 | Archive, founder desk and approval console lack the employee-style hover discovery prompt. | Reuse existing callout components with meaningful Studio / Company Journey / Activity labels and obstacle-aware placement. | Fixed: 288 headless / 299 rendered checks, 11 native scenes; root viewed crowded archive and pending approval. `STATION_HOVER_REVIEW.md`. |
| F45 | P2 | Lunch uses a cross-legged work pose on the floor below empty lounge furniture. | Use honest directional standing break idle until authored relaxed poses and supported lounge sockets exist. | Fixed: 2,238 headless / 2,254 rendered checks; unchanged schedules, feet and job/delivery priority. Old diagnostic evidence retained. `LUNCH_STANDING_IMPLEMENTATION.md`. |
| F46 | P1 | Mobile whiteboard planning placeholder used an untested 192 px rise; real side views need thin-edge geometry. | Measured 80 px rise, 88×56 board, 4 px thickness; full registered four-view construction and actual room depth proof. | Dev prototype passes 1,628 headless / 1,972 rendered checks. Side identity/casters and canonical passive-prop integration remain open; `MOBILE_WHITEBOARD_REVIEW.md`. |
| F47 | P2 | Catalogue 4× zoom initially opens on transparent registered padding, hiding the object. | Center the enlarged viewport on measured opaque bounds without trimming the native asset. | Fixed and rechecked in the actual browser; 45 builder self-tests. Separate local Markdown navigation restriction disclosed in `HTML_CATALOGUE_REVIEW.md`. |
| F48 | P1 | Furniture profiles assume every explicit shared prop is an actionable service, preventing honest passive whiteboard/pedestal placement. | Add an explicitly noninteractive, physical decorative profile and generic registered-layer factory, preserving art/geometry gates and existing workstation/service behavior. | Implemented and reviewed:850fixed-FPS headless/935native checks,31PNGs/384frames; dev whiteboard/pedestal only. No production family or fake action admitted. `PASSIVE_FURNITURE_INTEGRATION_REVIEW.md`. |
| F49 | P1 | Opaque founder hair can visually hide a desk/employee while real clicks still select the hidden object. | Include the founder body in the same alpha/depth comparison as passive furniture, without creating a self action. | Fixed: 27 headless / 33 native checks, three actual input cases; ordinary ground-click handling preserved. `FOUNDER_OCCLUSION_REVIEW.md`. |
| F50 | P1 | Real keyboard testing found Left/Right mapped to Insert/Pause; action-level movement tests had missed this. | Correct only the two physical key codes; test actual parsed WASD/arrows, release, click-route cancellation, Chat focus, and absence of Insert/Pause movement. | Fixed: unchanged focused test goes from56checks/10failures to56headless/56native with0failures. Later than the frozen combined checkpoint. See `PASSIVE_SHOWROOM_ENTRY_REVIEW.md`. |
| F51 | P1 | Real clicks on opaque Day/Time or delivery-memo paper highlight and route toward Mina hidden beneath; Earned alone blocks correctly. | Give ClockPanel and active DeliveryMemo parent surfaces GUI pointer ownership, preserving child tooltip/View controls and noninteractive world callouts. | Fixed:60headless/72native assertions, six pixel-identical HUD crops and seven focused suites pass. Real View/tooltip, existing routes and hidden-memo release preserved. See `PERSISTENT_HUD_PICKING_REVIEW.md`. |
| F52 | P2 | No export preset/filter exists. Source masters and test outputs have `.gdignore`; imported dev fixtures/showrooms have no release exclusion policy. | Before release, define and verify an explicit export allowlist/exclusion policy without breaking dev captures. | Prospective packaging gap only; no export was performed and no shipped leak is claimed. Catalogue/build scripts are outside `res://game`. |
| F53 | P2 | Low-bookshelf insert generation requested88×24 but returned2140×735; forced width88 would produce30rows. | Reject strict target; use full-source proportional70×24 decor centered in unchanged88×24bay, with explicit9pxgutters and no crop/stretch/keying. | Bounded staged shelf review2.5:86export/136headless/328native checks,24actor routes,108PNGs/1533frames. E=W equivalent closed ends; plain finish/tiny book detail remain. `LOW_BOOKSHELF_REVIEW.md`. |
| F54 | P2 | Old dev workstation viewer opens deferred Connect AI over Theo's desk despite an isolated null transport; suspected toolbar overlap was not reproduced in8states. | New wrapper closes that deferred drawer once after startup without changing credentials, old fixture, production or later user-opened panels. | Fixed in `play_workstation_showroom.gd`:29headless/37native checks,8AFTERPNGs427frames. Root reviewed clear initial native view; before evidence retained in `WORKSTATION_VIEWER_HANDOFF_REVIEW.md`. |
| F55 | P1 admission gate, resolved | Historical prototype seating depth-lock, grounded shadow/X-follow, seated-thinking and cue attachments were calibration-only. Separate material passes could not certify a whole desk. | Complete native South/West/East/North assemblies, then admit explicit reviewed production capabilities. | Resolved through `art-catalogue/FOUR_FACING_WORKSTATION_PRODUCTION_REVIEW.md` and `COLLABORATION_PRODUCTION_REVIEW.md`: all four production directions now pass contact/state/leave and occupied-seat protection. Old `NEXT_DESK_ACCEPTANCE.md` describes the prerequisite/history, not a currently closed gate. |

No furniture-wall overlap was visible in the two initial baseline captures. Archive now has separate all-four normal-room and wall/headroom proof; other unapproved families do not inherit it. Collaboration's apparent native-viewer rectangle was checked and is transparent, not a demonstrated opaque-matte bug. Remaining legacy scale mismatches are baked into source art/export rather than live prop downscaling.

## Final disposition map for the original findings

| Findings | Current disposition and evidence |
| --- | --- |
| F01–F06, F08, F10, F13, F17–F21, F25–F26, F38–F39, F55 | Reviewed four-facing normal-game workstation capabilities, pose/contact/depth transitions and editor guards replace the prototype-only state. [Production workstation review](art-catalogue/FOUR_FACING_WORKSTATION_PRODUCTION_REVIEW.md), [collaboration lifecycle](COLLABORATION_PRODUCTION_REVIEW.md), and final layout/migration/editor/pose/shadow regressions. Bespoke sit/stand drawings remain optional; actual transitions must not clip. |
| F07, F09, F12, F15, F30–F33 | All seven active families have separately reviewed camera-space views, registered layers and geometry. [Seven-family production checkpoint](art-catalogue/PRODUCTION_AND_LIBRARY_CHECKPOINT_20260906.md), individual coffee/research/archive/prototype/approval reviews and current catalogue evidence retain rejected sources rather than claiming their methods succeeded. |
| F11, F22–F24, F43, F48–F51, F54 | Surface/depth picking, HUD pointer ownership, real arrow/WASD input, passive prop support, preview lifetime, occupied rotation/Undo and isolated viewer startup are fixed and regression-covered. [Final test matrix](art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md) includes current ordinary-game entry points; historical targeted native evidence remains linked in the discovery rows. |
| F14, F27–F29, F37, F42 | Ten complete profession toolkits now have approved passive NESW host compositions. [Final library acceptance](art-catalogue/PASSIVE_ACCEPTANCE_20260906.md). Failed legal/engineering raster requests remain failed history; independent code-native replacements have explicit provenance. Optional archive facade studies reuse equivalent common sides honestly, without new services. |
| F16 | Corrected three locomotion atlases remain in production; final locomotion and real directional-input tests pass. |
| F34, F44 | World cue/callout clearance and station discovery prompts are fixed; final world-UI469 checks and27 isolated statics cover readable priority and stale-state handling. |
| F35–F36, F41 | Optional portraits and material alternatives have explicit review dispositions. Failed/staged terrazzo, walnut and cork studies do not replace approved wood; specialist portraits do not invent hires. This is review completion, not approval of every experiment. |
| F40 | Motion inventory validates declared current registered render layers and atlas regions. Final world/UI manifests and evidence validator pass. |
| F45 | Current collaboration sockets use admitted seated lunch/return transitions; directional standing remains the honest fallback. Dedicated collaboration and lunch regressions pass for both employees. |
| F46, F53 | Whiteboard and bookshelf join the approved passive directional library with actual room/contact review. No new service or default placement is implied. |
| F47 | Catalogue zoom centers actual ink bounds. Real-browser checks prove native/4× images, links, focus, filters and width; final replay also binds exact source and served HTML hashes. |
| F52 | Retained nonblocking pre-release packaging task: define an export allowlist before shipping. This local art goal performs no release/export and does not claim that a distributable package is ready. |

The final reconnect-label repair and final evidence reconciliation are recorded
in the [acceptance matrix](art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md).

## Existing systems to preserve

Collision and navigation already derive from occupied cells. Placement checks include walls, circulation, clearance, furniture bounds, reachable work/interaction cells and stages 0–4. Transactional placement, undo/export and route replanning are reusable. Feeding these systems correctly resolved directional data is preferable to replacing them.

## Four-direction art contract

For workstations, facing means seated employee gaze toward the worksurface. South = employee north of desk, looking downscreen. For service objects, explicitly define approach/service side; never infer it from a filename. E/W logical footprints exchange axes, but actual raster views are separately drawn with fixed screen-space lighting.

Each enabled direction needs native canvas, scale 1, actual alpha, explicit sort/footprint origin, pixel bounds, occupied/clearance cells, reachable work and interaction cells, registered layer regions/offsets/depth, work-pose compatibility, hit bounds and optional decor/ambient attachments. Opaque-bottom need not equal sort origin, but the difference must be explicit and tested. No arbitrary mirror/rotation of finished raster art.

Pass gates: all functional placement tests pass; visual categories (pixel coherence, perspective, readability, layering/anchors, direction consistency, placement) each ≥2/3 and mean ≥2.5. Generated source art is not runtime-ready by default.

## First-generation review

`calibration/desk-south-v1-rejected.png` is a generated source candidate, **not integrated**. It follows screen axes but returned 1341×1173 RGB with an opaque painted checkerboard instead of the requested alpha/native-grid enlargement. It requires a targeted background/pixel-grid correction and native-size review before use. This is exactly why the overnight queue includes inspection between batches.

## Historical implementation snapshot — superseded by the current checkpoint

The paragraph below records an earlier partial promotion, not current readiness.
All seven active families, including collaboration-cluster-v2, now have reviewed
production NESW capabilities. The former collaboration gap andF55 admission gate
are closed; optional gestures/future-role behavior are not implied. Current
verification is in `art-catalogue/COMPLETION_ACCEPTANCE_MATRIX.md`.

Backward-compatible facing resolution, canonical render layers, actor work-pose gates, editor rotation/rollback and shifted visual hit targeting are implemented and regression-tested; legacy South seated pixels remain unchanged in the last independent comparison. Locomotion crop bleed is fixed in runtime exports. Source-preserving E/W body/chair layers, seat transitions, quiet thinking and editor conflict checks use actual dev GameMain/navigation paths, not isolated sprite showrooms. They are not blanket profession-specific workstation-art approval. **Archive and coffee now each have four accepted production views**; coffee adds no interaction, while archive retains its standing-service action. Corrected research and the other shared base promotions are listed in the current truth audit; the collaboration gap remains explicit. The frozen AFTER checkpoint still describes its own earlier 26-suite snapshot; later promotions and shadow refinements have separate evidence. See `art-catalogue/RUN_LOG.md` for current results. Planned slots and passing arithmetic are not approved pictures.
