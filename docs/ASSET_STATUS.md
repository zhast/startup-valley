# Asset audit status — November 15, 2026

The standing-eye, blink-timing and modest furniture repairs have passed their
component reviews. Shared modular terrain and the connected courtyard fence
are now visually approved for build `d23a483542544696`, using actual in-app
Godot frames and independent geometry/image review.
This page distinguishes generated pixels, runtime composition fixes
and open findings. A reviewed PNG does not prove every animation using it is
correct. See [the generation and review workflow](ASSET_WORKFLOW.md).

## Current findings and repair status

| Finding | Evidence and action | Status |
| --- | --- | --- |
| Mina's standing blink painted pale bars through her bangs while her pupils stayed open | Corrected front/left/right closed-eye regions, preserving open eyes, body, alpha and walks. [Current review](../dev/art-catalogue/runtime-reviews/mira-standing-blink-v3.json). | Native review passed |
| Founder's front closed eyes read as dark blocks | Replaced the thick closed-eye blocks with registered thin eyelids. [Current review](../dev/art-catalogue/runtime-reviews/founder-standing-blink-v3.json). Theo's existing one-pixel eyelids required no new pixels. | Native review passed |
| Blinks looked like prolonged face flicker | Replaced the 667ms/50%-duty loop with a 120ms closure every 4 seconds, offset by character. Blocked input no longer freezes Founder with closed eyes. | Native timing checks passed |
| Full visual consistency of future maps | Shared-world manifests and a map gate require matching camera, scale, material treatment, modular props and actual-engine review. Starter, full-office and courtyard reviews now bind current browser frames; future changes still require admission. | Current three maps approved; no blanket approval of future maps |
| Chairs felt corporate and inconsistent | Six warm wooden chair layers are shared by workstations and collaboration tables; existing actor/seat anchors and depth retained. | Component review passed; current office composition inspected in browser |
| Café furniture and phone booth felt out of scale | Three generated replacements have measured contact/height contracts and a save-preserving registration migration. | Component review and real headless save/recovery passed |
| Estate-like background, repeated hedge rows and porous courtyard boundary | Shared 32px lawn/paving, sparse planting and native connected wooden fence replace the rejected compositions. A registered two-cell opening aligns with the existing Studio return. | Current terrain/fence visually approved; navigation unchanged |

## Reported furniture consistency issue

The [furniture audit](FURNITURE_SCALE_AUDIT.md) confirmed mixed ground
registration and an oversized booth with an inadequate one-cell footprint.
The café chair/table and booth now have reviewed generated replacements,
same-scale actor evidence, measured floor/seat/table/opening landmarks and
enforced hash-bound scale contracts. Existing saves retain their inventory;
only newly conflicting placements are stored. Real legacy save checks preserved
all valid placements and exact player positions.

The [wooden-chair decision](decisions/2026-11-15-wooden-chair-family.md) records
the six shared workstation modules and original seat/hand anchors. Static48-pose,
motion, seat transition and collaboration checks pass. The last windowed
collaboration run was stopped at the owner's request; final integrated visual
acceptance uses the existing in-app browser, not another native window.
Current starter/full-office browser frames are included in the approved map
reviews; they do not replace the separate all-facing animation tests.

## Approved shared yard

The [shared-yard decision](decisions/2026-11-15-shared-yard-and-connected-fence.md)
records native 32px modules, generated and reused source pixels, and the
registered two-cell Studio opening. The final runtime fingerprint is
`5e8afa18aa826a0883d0af6506aa47c96e9d405c7766fe86befe7d474c882ebd`.
The parent inspected build `d23a483542544696` in the background in-app browser;
an independent agent checked its front/northwest images and exact seven-file
delta from the clean-journey runtime. Floor, paving, props, interactions,
navigation and worker state remain unchanged by the fence addition.

[Current frames](web/assets/world-final/capture-manifest.json) bind the starter
studio, full office, courtyard front/northwest and Mina invitation. The
[independent review](web/assets/yard-fence-v1/independent-review/README.md)
records 752 fence checks, 17 map tests and 9 component route checks, plus a
separate geometric probe. All 75 root tooling tests passed and the map release
gate passed at admission. The full `assets:check -- --godot` run and final
normal-export/package verification remain separate completion steps.

The old monolithic garden, vertical hedge stamps, porous boundary and sealed
fence frames remain rejected historical evidence. Neither a passed gate nor
these current static frames certify every future scene or character animation.

## Generated art already integrated

The first seven runtime PNGs contain accepted generated corrections. The newer standing
eye pass revises two of those existing character sheets; it does not replace
their identities or bodies. These are bounded overlays, not seven entirely
regenerated assets. The furniture pass adds three standalone replacement PNGs
and revises six shared chair modules: these character/furniture repairs cover
sixteen unique runtime PNGs. Two additional reviewed atlases supply modular
terrain and fence art. Original generation outputs, prompts, transforms and
hash-bound reviews are retained in the repository. The final byte-stable
native eye playback passes 196 checks; the broader pose review covers all four
characters and supported facings. See [blink evidence](web/assets/blink-polish-v3/README.md).

| Original problem | Generated change | Review / visual evidence |
| --- | --- | --- |
| Side-walk legs appeared stuck | Founder lower-body walk overlay; now also corrected front eyelids | [Current combined review](../dev/art-catalogue/runtime-reviews/founder-standing-blink-v3.json), [walking frames](web/assets/playtest-polish-founder-walk.png) |
| Same side-walk issue | Mina lower-body walk overlay; now also corrected standing eyelids | [Current combined review](../dev/art-catalogue/runtime-reviews/mira-standing-blink-v3.json), [walking frames](web/assets/playtest-polish-Mina-walk.png) |
| Same side-walk issue | Theo lower-body walk overlay | [Review](../dev/art-catalogue/runtime-reviews/theo-side-walk-v2.json), [rendered frames](web/assets/playtest-polish-theo-contact.png) |
| Same side-walk issue | Creative lower-body walk overlay | [Review](../dev/art-catalogue/runtime-reviews/creative-side-walk-v2.json), [rendered frames](web/assets/playtest-polish-creative-contact.png) |
| Pale marks through Mina's seated bangs | Seated closed-eye overlay; 86 changed pixels | [Review](../dev/art-catalogue/runtime-reviews/mira-seated-blink-v2.json), [rendered frames](web/assets/playtest-polish-Mina-blink.png). Standing eyes and timing now have their own verified repair above. |
| Coffee machine front was hard to recognize | South-facing espresso panel; recomposed panel and whole-machine PNGs | [Review](../dev/art-catalogue/runtime-reviews/coffee-south-front-v2.json), [native detail](web/assets/coffee-front-review/south-front-detail.png). Other facings were not regenerated. |
| Corporate chair silhouette and mismatched café/booth proportions | Six shared wooden chair modules and three calibrated standalone furniture sprites | [Chair review](../dev/art-catalogue/runtime-reviews/task-chair-v3.json), [standalone review](../dev/art-catalogue/runtime-reviews/furniture-scale-v1.json) |

![Regenerated walking frames](web/assets/playtest-polish-founder-walk.png)

![Coffee front in the actual room](web/assets/coffee-front-review/south-front-detail.png)

## Fixed through code or placement

| Finding | Change |
| --- | --- |
| Chair back disappeared behind north-facing seated characters | Facing-specific lower-body/chair/head depth composition. [Decision and evidence](decisions/2026-11-15-seated-chair-depth.md). |
| Creative used the wrong portrait | Correct character crop/selection; no new generated PNG. |
| Mina arrival could overlap furniture | Navigation and painted-bounds placement checks, deterministic clear-floor search, and a safe portrait-introduction fallback. |
| Theo hover paper covered his name/face | Derive callout bounds from the actual rendered target, protect the actor/nameplate and other world UI; 57 native regression checks passed. |
| Cursor lifecycle and stale hover feedback | Clear native cursor ownership and hover state at the relevant transitions; no generated cursor artwork in this change. |

The frozen inventory contains 804 legacy runtime PNGs. That count is **not**
804 artistic approvals. Defects can still exist in unchanged legacy images.
Keep this list current when a reported issue is reproduced, repaired and
verified, and retain the evidence for the exact accepted scope.
