# Remaining library acceptance

Audit date: 2026-09-04 (America/Los_Angeles)

Audited catalogue SHA-256: `0df0a6b11f4b7acc49728ee6a571492d39da27df341404e2947ed57eb60612f0`

This is an acceptance audit of the existing 42-family / 168-facing catalogue,
not a request for more production bindings. The audited snapshot records 125
source originals and 67 planned, 55 native-review, 13 cleanup, one blocked and
32 runtime-integrated facings. Concurrent collaboration-candidate registration
may advance the snapshot after this report; it does not change the findings
below. Visual conclusions came from opening the native PNG sheets and actual
room captures. Pixel-count overlap was used only as supporting geometry in the
older reports, not as a proxy for artistic quality here.

## What remains besides making missing candidates

| Queue | Exact audited contents | Work that actually closes it |
| --- | --- | --- |
| 32 runtime-integrated | Eight complete families | Nothing for library acceptance; runtime expansion is a separate product decision. |
| 55 native-review | Thirteen complete four-facing candidate families, plus legal N/S and creative N | Make an evidence-backed family-level visual pass/cleanup decision, record the six visual scores and required-layer disposition, and supply truthful approved paths only for a pass. Validator-green evidence alone cannot make that decision. |
| 13 cleanup | Compact desk N/E/S/W, shared workbench N/E/S/W, legal W and engineer N/E/S/W | Re-scope the two bases before demanding new art; repair the genuine legal and engineering defects described below. |
| One blocked | Legal E | Produce a true East by manual/code-native repair. Its initial-plus-three generative attempt budget is exhausted and must not be reopened under another name. |
| 67 planned | Sixteen wholly missing families and creative E/S/W | These still need candidates. They are distinct from the existing acceptance backlog. |

The thirteen complete native-review families are `collaboration_cluster`,
`visitor_chair`, `mobile_whiteboard`, `rolling_storage_pedestal`,
`low_bookshelf`, `acoustic_divider`, `founder_strategy_kit`,
`mina_discovery_kit`, `product_prototype_kit`, `theo_campaign_kit`,
`growth_analytics_kit`, `finance_accounts_kit` and `customer_success_kit`.
The sixteen wholly missing families are `two_seat_sofa`, `lounge_armchair`,
`low_coffee_table`, `round_meeting_table`, `tall_storage_cabinet`,
`broadleaf_planter`, `task_floor_lamp`, `water_station`, `coat_bag_stand`,
`printer_scanner_station`, `recycling_sorter`, `server_cabinet`, `phone_booth`,
`desk_lamp_kit`, `cafe_table` and `resource_cart`.

Art-library completion means four accepted directional assets and all required
layers for every retained family. It does **not** require all 42 families to be
runtime-integrated. Workstation seats, actor poses, reservations and job
behavior belong to the later integration gate unless the art review itself
claims an active-use composition.

## Specialist role kits

### `lawyer_contract_kit`: genuine directional and layer gaps

North already reads clearly as a restrained binder/checklist/cup kit in the
[native room comparison](../../game/tests/output/lawyer-kit-north/frame2.png).
South's [native sheet](../../game/tests/fixtures/furniture-calibration/roles/lawyer-south-v2-paper-4x.png)
also preserves the opposite gross layout. Neither is family-complete: North was
reviewed only in an isolated `TownRoom`, South has no actual-room composition,
and both remain whole-image candidates while the required
`surface_decor_rear` and `surface_decor_front` layers are still planned.

East is truly absent. West is not merely waiting for review: the
[reclassified sheet](../../game/tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4-paper-4x.png)
still shows the wrong tab edge/upright page grammar, an unproven cup turn and a
taller binder than the directional contract. Its evidence is only a 2D desktop
preflight. The [direction review](LAWYER_DIRECTION_IDENTITY_REVIEW.md) and
[exhausted East attempt log](LAWYER_EAST_ATTEMPT_REVIEW.md) correctly retain
those limits.

Acceptance work, in order:

1. Manually or code-natively author the true East and correct West; do not spend
   another generative retry.
2. Reuse the existing N/S component exports where possible, then export all
   four facings as explicit rear/front layers on the `desk` canvas and pivot.
3. Run one common actual-`GameMain` review for tabletop support, monitor/mouse
   clearance, actor occlusion and direction identity. An active legal-reading
   pose is not required for this art-only kit and must not be implied.

### `creative_design_kit`: one viable passive facing, three missing facings

The [isolated North tools](../../game/tests/fixtures/furniture-calibration/roles/creative-north-v1-paper-4x.png)
are recognizable: the tablet is the dominant cue, with smaller camera and
swatch accents. The actual-room sheets show an important qualitative result:
the tablet disappears behind the actors when
[centered](../../game/tests/output/creative-north-composition/centered-idle-frame0.png),
while the [parked-left composition](../../game/tests/output/creative-north-composition/parked_left-idle-frame0.png)
keeps the role cue visible and coherent with the monitor. That North arrangement
is credible as passive/resting equipment, not as evidence of drawing.

East, South and West are missing, and the required rear/front layers are still
planned. Complete independent directional art, preserve the parked-tool
identity, export the two required layers, and perform a common actual-room
contact/occlusion review. A stylus-use animation is needed only before claiming
active drawing or runtime behavior; it should not block passive art-library
acceptance. See the [North source review](CREATIVE_NORTH_REVIEW.md) and
[composition decision](CREATIVE_NORTH_COMPOSITION_REVIEW.md).

### `engineer_build_kit`: existing mats do not satisfy the family contract

All four records are `source_only`, not native exports, and the catalogue host
is the 192x320 `prototype_bench`. The current review instead mounts opaque
32x20 / 20x32 plates on the ordinary calibrated workstation and removes its
computer peripherals. It therefore proves a desk-side study, not the declared
host, canvas, pivot or rear/front layer contract.

The [four-facing native sheet](../../game/tests/output/engineer-mat-composition/all-four-native.png)
also exposes real art issues: East/West read like upright control panels and
their boards are visibly larger than the North/South counterparts; several
probe tips lose their directional cue. North becomes a credible parked kit when
[moved left](../../game/tests/output/resting-north-engineer/centered-resting-native.png).
South retains a real actor-shadow-over-mat defect; the shadow-hidden capture is
diagnostic evidence, not a fix.

Acceptance work, in order:

1. Normalize one physical board/breadboard/probe scale and flat-surface visual
   grammar across independently authored N/E/S/W views.
2. Export required rear/front layers on the accepted `prototype_bench` host and
   review support, occlusion and the South shadow policy in actual `GameMain`.
3. Keep `ambient_overlay` optional. A probe-use pose is a future active-use gate,
   not a passive role-kit art blocker.

The underlying evidence is the [four-facing mat review](ENGINEER_MAT_COMPOSITION_REVIEW.md)
and [parked-North review](RESTING_NORTH_ENGINEER_REVIEW.md).

## Compact and shared desk scoring needs a scope correction

Both candidates are furniture **bases**. Their declared deliverables are only
`floor_shadow`, `rear_structure` and `front_structure`; chairs, computers and
role kits have separate owners. Their actual-room suites already prove collision,
wall/corner refusal, visible-surface picking and approach routing.

| Family | Out-of-scope reason currently depressing the 2.17 score | Genuine base-art question visible in the sheets |
| --- | --- | --- |
| `compact_desk` | Silhouette was marked down because an empty surface lacks future role identity; placement was marked down for missing chair/device/role overlays and seated lifecycle. None is part of the base asset. | The ordered-dither shadow, deliberately boxy side elevations and subtle N/S or E/W distinction still need an art-direction decision. The [isolated sheet](../../game/tests/output/compact-desk/candidate-contact-sheet-4x.png) and [accepted-desk comparison](../../game/tests/output/compact-desk/accepted-shared-vs-compact-native.png) nevertheless show an immediately readable, genuinely smaller desk. |
| `shared_workbench` | Placement was marked down for absent paired attachments and two-actor lifecycle; generic “role identity” is not a base requirement. | N/S visibly read as a long two-bay surface with a center cable well. The [isolated sheet](../../game/tests/output/shared-workbench/candidate-contact-sheet-4x.png) shows that E/W become austere end-on planks and the side shadow is visually dominant; whether the sparse top/cable cues are enough is a real art decision. |

Do not automatically promote either family, but do not keep `cleanup_required`
solely for separately owned assemblies. Re-score each base against its own
brief, using the existing [compact](../COMPACT_DESK_NATIVE_REVIEW.md) and
[shared-workbench](../SHARED_WORKBENCH_NATIVE_REVIEW.md) actual-room evidence.
If art direction accepts the shadows and side grammar, record the exact exports
as native-review candidates and move chair/device/role and seated/two-actor
lifecycle checks to a compatibility/runtime track. If art direction rejects
those pixels, retain cleanup with that specific visual defect as the blocker.

## Next implementation priorities

1. **Drain the acceptance queue.** Give each complete four-facing native family
   an agent visual pass/cleanup decision backed by opened native evidence. On
   pass, verify every required layer, common
   host/anchor, actual-room evidence and score threshold before adding approved
   paths. Normalize stale family/layer rollups only as part of that decision.
2. **Finish legal by repair, not more generation.** East and West are the only
   hard directional blocker; then layer and review N/E/S/W together.
3. **Rebuild engineer against its real host.** This is a host/layer/art-contract
   task, not a request for an engineer animation.
4. **Complete creative E/S/W around the accepted passive North composition.**
   Keep active drawing explicitly out of the art-only claim.
5. **Re-review compact/shared as bases.** Separate any chosen shadow/side-art
   cleanup from later workstation assembly and lifecycle work.
6. **Only then continue the 67 planned facings.** New candidates do not resolve
   the existing 55-facing review backlog or the role-kit contract gaps above.

The governing lifecycle and score rules are in the catalogue
[README](README.md#status-and-evidence-rules): approval requires real visual
review, complete required layers and a mean of at least 2.5 with no category
below 2; runtime integration remains a separate adapter and test decision.
